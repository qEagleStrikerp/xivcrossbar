local res = require('resources')
local storage = require('storage')
local action_manager = require('action_manager')
local mount_roulette = require('libs/mountroulette/mountroulette')

local player = {}

player.name = ''
player.main_job = ''
player.main_job_level = ''
player.sub_job = ''
player.sub_job_level = ''
player.server = ''

player.vitals = {}
player.vitals.mp = 0
player.vitals.tp = 0

player.sch_jp_spent = 0

player.hotbar = {}

player.hotbar_settings = {}
player.hotbar_settings.max = 1
player.hotbar_settings.active_hotbar = 1
player.hotbar_settings.active_environment = 'Field'

player.auto_create_xml = true

-- initialize player
function player:initialize(windower_player, server, theme_options, enchanted_items)
    self.name = windower_player.name
    self.main_job = windower_player.main_job
    self.main_job_level = windower_player.main_job_level
    self.sub_job = windower_player.sub_job
    self.sub_job_level = windower_player.sub_job_level
    self.server = server
    self.id = windower_player.id
    self.enchanted_items = enchanted_items

    self.hotbar_settings.max = theme_options.hotbar_number

    self.vitals.mp = windower_player.vitals.mp
    self.vitals.tp = windower_player.vitals.tp

    self.sch_jp_spent = windower_player.job_points.sch.jp_spent

    self.auto_create_xml = theme_options.AutoCreateXML

    storage:setup(self)
end

local unescape = function(str)
    return str:gsub('&apos;', '\''):gsub('quote', '"')
end

-- update player jobs
function player:update_jobs(main, sub)
    self.main_job = main
    self.sub_job = sub

    storage:update_filename(main, sub)
end

function player:get_id()
    return self.id
end

-- Updates the set of spells the player can currently cast. Does not take
-- MP, recast timers, or special ability requirements into account. Only
-- whether or not FFXI's job data says the spell is there.
function player:update_current_spells()
    local mainJobSpellList = T()
    if windower.ffxi.get_player()['main_job_id'] == 16 then
        mainJobSpellList = T(windower.ffxi.get_mjob_data().spells)
        -- Returns all values but 512
        :filter(function(id) return id ~= 512 end)
        -- Transforms them from IDs to lowercase English names
        :map(function(id) return res.spells[id].english:lower() end)
    end

    local subJobSpellList = T()
    if windower.ffxi.get_player()['sub_job_id'] == 16 then
        subJobSpellList = T(windower.ffxi.get_sjob_data().spells)
        -- Returns all values but 512
        :filter(function(id) return id ~= 512 end)
        -- Transforms them from IDs to lowercase English names
        :map(function(id) return res.spells[id].english:lower() end)
    end

    self.current_spells = {}
    for _, spellName in ipairs(subJobSpellList) do
        self.current_spells[spellName] = true
    end
    for _, spellName in ipairs(mainJobSpellList) do
        self.current_spells[spellName] = true
    end
end

-- Returns true if the player has the spell and (if BLU) the spell is set.
function player:has_spell(spellName)
    return self.current_spells[spellName] == true
end

-- load hotbar for current player and job combination
function player:load_hotbar()
    self:update_current_spells()
    self:reset_hotbar()
    local newly_created = false

    -- Load shared-icons table first so it's available during slot parsing
    -- when per-job XMLs are read below.
    self.shared_icons = {}
    if storage.shared_icons_file:exists() then
        self:load_shared_icons(storage.shared_icons_file)
    elseif self.auto_create_xml then
        self:create_shared_icons()
    end

    -- Load CustomActions catalog. 
    self.custom_actions = {}
    if storage.custom_actions_file:exists() then
        self:load_custom_actions(storage.custom_actions_file)
    elseif self.auto_create_xml then
        self:create_custom_actions()
    end

    -- if normal hotbar file exists, load it. If not, create a default hotbar
    if storage.file:exists() then
        windower.console.write('[XIVCrossbar] Load crossbar sets for ' .. storage.filename)
        self:load_from_file(storage.file)
    elseif self.auto_create_xml then
        newly_created = true
        self:create_default_hotbar()
    end

    -- if job default file exists, load it. If not, create a default version
    if storage.job_default_file:exists() then
        windower.console.write('[XIVCrossbar] Load cross-subjob fallback crossbar set for ' .. player.main_job)
        self:load_from_file(storage.job_default_file)
    elseif self.auto_create_xml then
        newly_created = true
        self:create_job_default_hotbar()
    end

    -- if all jobs file exists, load it. If not, create a default version
    if storage.all_jobs_file:exists() then
        windower.console.write('[XIVCrossbar] Load cross-job fallback crossbar set')
        self:load_from_file(storage.all_jobs_file)
    elseif self.auto_create_xml then
        newly_created = true
        self:create_all_jobs_default_hotbar()
    end

    -- if shared file exists, load it. If not, create an empty version
    if storage.shared_file:exists() then
        windower.console.write('[XIVCrossbar] Load shared crossbar set')
        self:load_from_file(storage.shared_file)
    elseif self.auto_create_xml then
        newly_created = true
        self:create_shared_hotbar()
    end

    if (newly_created) then
        player:store_new_hotbars()
    end
end

function kebab_casify(str)
    return str:lower():gsub(' ', '-'):gsub('\'', '')
end

-- Map on-disk slot names back to the integer form the rest of the code uses.
-- Old numeric-style names ('1'..'9') pass through unchanged for backward compat.
local slot_name_to_int = {
    ll = '1', ld = '2', lr = '3', lu = '4',
    rl = '5', rd = '6', rr = '7', ru = '8',
    zz = '9',
}

local function normalize_slot_id(raw)
    return slot_name_to_int[raw] or raw
end

-- Map on-disk hotbar names back to the integer form the rest of the code uses.
-- Old numeric-style names ('1'..'6') pass through unchanged for backward compat.
local hotbar_name_to_int = {
    l  = '1',
    r  = '2',
    rl = '3',
    lr = '4',
    ll = '5',
    rr = '6',
}

local function normalize_hotbar_id(raw)
    return hotbar_name_to_int[raw] or raw
end

-- load a hotbar from existing file
function player:load_from_file(storage_file)
    local contents = xml.read(storage_file)

    if contents.name ~= 'hotbar' then
        windower.console.write('XIVCROSSBAR: invalid hotbar on ' .. storage.filename)
        return
    end

    -- parse xml to hotbar
    for key, environment in ipairs(contents.children) do
        local environment_name = nil
        for key, hotbar in ipairs(environment.children) do     -- hotbar number
            if (hotbar.name == 'name') then
                for key, name in ipairs(hotbar.children) do
                    environment_name = name.value
                end
            end
        end
        if (environment_name == nil) then
            environment_name = key
        end
        for key, hotbar in ipairs(environment.children) do     -- hotbar number
            if (hotbar.name ~= 'name') then
                for key, slot in ipairs(hotbar.children) do       -- slot number
                    local new_action = {}

                    for key, tag in ipairs(slot.children) do   -- action
                        if tag.name == 'type' then
                            new_action.type = tag.children[1].value
                        elseif tag.name == 'action' then
                            new_action.action = unescape(tag.children[1].value)
                        elseif tag.name == 'target' then
                            if tag.children[1] == nil then
                                new_action.target = nil
                            else
                                new_action.target = tag.children[1].value
                            end

                        elseif tag.name == 'alias' then
                            new_action.alias = tag.children[1].value
                        elseif tag.name == 'icon' then
                            new_action.icon = tag.children[1].value
                        elseif tag.name == 'equip_slot' then
                            new_action.equip_slot = tag.children[1].value
                        elseif tag.name == 'warmup' then
                            new_action.warmup = tag.children[1].value
                        elseif tag.name == 'cooldown' then
                            new_action.cooldown = tag.children[1].value
                        elseif tag.name == 'usable' then
                            new_action.usable = tag.children[1].value
                        elseif tag.name == 'linked_action' then
                            if tag.children[1] ~= nil then
                                new_action.linked_action = tag.children[1].value
                            end
                        elseif tag.name == 'linked_type' then
                            if tag.children[1] ~= nil then
                                new_action.linked_type = tag.children[1].value
                            end
                        end
                    end

                    if (new_action.icon == nil and self.shared_icons ~= nil) then
                        if (new_action.action ~= nil and self.shared_icons[new_action.action] ~= nil) then
                            new_action.icon = self.shared_icons[new_action.action]
                        elseif (new_action.alias ~= nil and self.shared_icons[new_action.alias] ~= nil) then
                            new_action.icon = self.shared_icons[new_action.alias]
                        end
                    end

                    self:add_action(
                        action_manager:build(new_action.type, new_action.action, new_action.target, new_action.alias, new_action.icon, new_action.equip_slot, new_action.warmup, new_action.cooldown, new_action.usable, new_action.linked_action, new_action.linked_type),
                        environment_name,
                        normalize_hotbar_id(hotbar.name:gsub('hotbar_', '')),
                        normalize_slot_id(slot.name:gsub('slot_', ''))
                    )
                end
            end
        end
    end
end

-- create a default hotbar
function player:create_default_hotbar()
    windower.console.write('[XIVCrossbar] No hotbar found. Creating default for ' .. storage.filename)

    self.hotbar.default = {}
    self.hotbar.default['name'] = 'Default'
    self:setup_environment_hotbars('default')

    self.hotbar.basic = {}
    self.hotbar.basic['name'] = 'Basic'
    self:setup_environment_hotbars('basic')
end

-- create a fallback hotbar that applies to all subjobs of this job
function player:create_job_default_hotbar()
    windower.console.write('[XIVCrossbar] No cross-subjob fallback crossbar set found. Creating a default version')

    self.hotbar['job-default'] = {}
    self.hotbar['job-default']['name'] = 'Job Default'
    self:setup_environment_hotbars('job-default')
end

-- create a fallback hotbar that applies to all jobs on this character
function player:create_all_jobs_default_hotbar()
    windower.console.write('[XIVCrossbar] No cross-job fallback crossbar set found. Creating a default version')

    self.hotbar['all-jobs-default'] = {}
    self.hotbar['all-jobs-default']['name'] = 'All Jobs Default'
    self:setup_environment_hotbars('all-jobs-default')
end

-- create an empty shared hotbar that is selectable but does not participate in fallback layering
function player:create_shared_hotbar()
    windower.console.write('[XIVCrossbar] No shared crossbar set found. Creating an empty version')

    self.hotbar['shared'] = {}
    self.hotbar['shared']['name'] = 'Shared'
    self:setup_environment_hotbars('shared')
end

-- Parse SharedIcons.xml into player.shared_icons as a simple name→path table.
-- Entries with empty/missing name or icon are silently skipped.
function player:load_shared_icons(storage_file)
    self.shared_icons = {}
    local contents = xml.read(storage_file)
    if (contents == nil or contents.name ~= 'shared_icons') then
        windower.console.write('[XIVCrossbar] SharedIcons.xml malformed, skipping')
        return
    end

    for _, entry in ipairs(contents.children) do
        if (entry.name == 'entry') then
            local entry_name = nil
            local entry_icon = nil
            for _, tag in ipairs(entry.children) do
                if (tag.name == 'name' and tag.children[1] ~= nil) then
                    entry_name = tag.children[1].value
                elseif (tag.name == 'icon' and tag.children[1] ~= nil) then
                    entry_icon = tag.children[1].value
                end
            end
            if (entry_name ~= nil and entry_name ~= '' and entry_icon ~= nil and entry_icon ~= '') then
                self.shared_icons[entry_name] = entry_icon
            end
        end
    end
end

function player:save_shared_icons_file()
    if (storage.shared_icons_file == nil) then return end

    local keys = {}
    for name in pairs(self.shared_icons) do
        if (name ~= nil and name ~= '') then
            table.insert(keys, name)
        end
    end
    table.sort(keys)

    local lines = L{}
    lines:append('<shared_icons>')
    for _, name in ipairs(keys) do
        local icon = self.shared_icons[name]
        if (icon ~= nil and icon ~= '') then
            lines:append('    <entry>')
            lines:append('        <icon>' .. icon:xml_escape() .. '</icon>')
            lines:append('        <name>' .. name:xml_escape() .. '</name>')
            lines:append('    </entry>')
        end
    end
    lines:append('</shared_icons>')
    lines:append('')

    storage.shared_icons_file:write(table.concat(lines, '\n'))
end

function player:create_shared_icons()
    windower.console.write('[XIVCrossbar] No SharedIcons.xml found. Creating an empty template.')
    self.shared_icons = {}
    local template = {
        shared_icons = {
            entry = {
                name = '',
                icon = '',
            }
        }
    }
    storage.shared_icons_file:write(table.to_xml(template))
end

function player:load_custom_actions(storage_file)
    self.custom_actions = {}
    local contents = xml.read(storage_file)
    if (contents == nil or contents.name ~= 'custom_actions') then
        windower.console.write('[XIVCrossbar] CustomActions.xml malformed, skipping')
        return
    end

    for _, action_node in ipairs(contents.children) do
        if (action_node.name == 'action') then
            local record = {}
            for _, tag in ipairs(action_node.children) do
                if (tag.children[1] ~= nil) then
                    record[tag.name] = tag.children[1].value
                end
            end
            if (record.name ~= nil and record.name ~= '') then
                self.custom_actions[record.name] = record
            end
        end
    end
end

function player:save_custom_actions_file()
    if (storage.custom_actions_file == nil) then return end

    local keys = {}
    for name in pairs(self.custom_actions) do
        if (name ~= nil and name ~= '') then
            table.insert(keys, name)
        end
    end
    table.sort(keys)

    local lines = L{}
    lines:append('<custom_actions>')
    for _, name in ipairs(keys) do
        local rec = self.custom_actions[name]
        if (rec ~= nil) then
            lines:append('    <action>')
            lines:append('        <name>' .. name:xml_escape() .. '</name>')
            if (rec.alias ~= nil and rec.alias ~= '') then
                lines:append('        <alias>' .. rec.alias:xml_escape() .. '</alias>')
            end
            if (rec.command ~= nil and rec.command ~= '') then
                lines:append('        <command>' .. rec.command:xml_escape() .. '</command>')
            end
            if (rec.icon ~= nil and rec.icon ~= '') then
                lines:append('        <icon>' .. rec.icon:xml_escape() .. '</icon>')
            end
            if (rec.linked_action ~= nil and rec.linked_action ~= '') then
                lines:append('        <linked_action>' .. rec.linked_action:xml_escape() .. '</linked_action>')
            end
            if (rec.linked_type ~= nil and rec.linked_type ~= '') then
                lines:append('        <linked_type>' .. rec.linked_type:xml_escape() .. '</linked_type>')
            end
            lines:append('    </action>')
        end
    end
    lines:append('</custom_actions>')
    lines:append('')

    storage.custom_actions_file:write(table.concat(lines, '\n'))
end

function player:create_custom_actions()
    windower.console.write('[XIVCrossbar] No CustomActions.xml found. Creating an empty template.')
    self.custom_actions = {}
    local template = {
        custom_actions = {
            action = {
                name = '',
                command = '',
                alias = '',
                icon = '',
                linked_action = '',
                linked_type = '',
            }
        }
    }
    storage.custom_actions_file:write(table.to_xml(template))
end

function player:store_new_hotbars()
    local new_hotbar = {}
    new_hotbar.hotbar = self.hotbar

    storage:store_new_hotbar(new_hotbar)
end

-- reset player hotbar
function player:reset_hotbar()
    self.hotbar = {}

    self.hotbar_settings.active_hotbar = 1
end

function player:setup_environment_hotbars(environment)
    for h=1,self.hotbar_settings.max,1 do
        self.hotbar[environment]['hotbar_' .. h] = {}

        -- This is a hack to make sure all newly-created crossbars show up in the crossbar set selector
        self.hotbar[environment]['hotbar_' .. h]['slot_9'] = {}
    end
end

-- set bar environment
function player:set_active_environment(environment)
    self.hotbar_settings.active_environment = kebab_casify(environment)
end

-- set bar environment
function player:is_valid_environment(environment)
    return self.hotbar[environment] ~= nil
end

function player:set_is_in_battle(in_battle)
    self.in_battle = in_battle
end

-- set bar environment to battle
function player:set_battle_environment(in_battle)
    local environment = 'Field'
    if in_battle then environment = 'Battle' end

    self.hotbar_settings.active_environment = environment
end

-- change active hotbar
function player:change_active_hotbar(new_hotbar)
    self.hotbar_settings.active_hotbar = new_hotbar

    if self.hotbar_settings.active_hotbar > self.hotbar_settings.max then
        self.hotbar_settings.active_hotbar = 1
    end
end

function player:get_crossbar_names()
    local names = L{}

    for name, hotbar in pairs(self.hotbar) do
        names:append(hotbar.name or name)
    end

    return names
end

-- add given action to a hotbar
function player:add_action(action, environment, hotbar, slot)
    if environment == nil or environment == '' then
        return
    end

    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    local env_key = kebab_casify(environment)
    if (env_key == nil) then
        return
    end

    if self.hotbar[env_key] == nil then
        self.hotbar[env_key] = {}
        self.hotbar[env_key]['name'] = environment
        self:setup_environment_hotbars(env_key)
    end

    if self.hotbar[env_key]['hotbar_' .. hotbar] == nil then
        windower.console.write('XIVCROSSBAR: invalid hotbar (hotbar number)')
        return
    end

    if self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] == nil then
        self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] = {}
    end

    self.hotbar[env_key]['hotbar_' .. hotbar]['slot_' .. slot] = action
end

function create_send_command_coroutine(command)
    return function()
        windower.send_command(command)
    end
end

function player:create_use_item_coroutine(item_name)
    local enchanted_items = self.enchanted_items
    return function()
        enchanted_items:use(item_name)
    end
end

function player:execute_action(slot)
    local h = self.hotbar_settings.active_hotbar
    local env = self.hotbar_settings.active_environment

    local action = self.hotbar[env]['hotbar_' .. h]['slot_' .. slot]
    local is_missing = action == nil or action.action == nil

    if (is_missing and env ~= 'default' and env ~= 'job-default' and env ~= 'all-jobs-default' and self.hotbar['default'] and self.hotbar['default']['hotbar_' .. h] and
        self.hotbar['default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['default']['hotbar_' .. h]['slot_' .. slot]
    elseif (is_missing and env ~= 'job-default' and env ~= 'all-jobs-default' and self.hotbar['job-default'] and self.hotbar['job-default']['hotbar_' .. h] and
        self.hotbar['job-default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['job-default']['hotbar_' .. h]['slot_' .. slot]
    elseif (is_missing and env ~= 'all-jobs-default' and self.hotbar['all-jobs-default'] and self.hotbar['all-jobs-default']['hotbar_' .. h] and
        self.hotbar['all-jobs-default']['hotbar_' .. h]['slot_' .. slot]) then
        action = self.hotbar['all-jobs-default']['hotbar_' .. h]['slot_' .. slot]
    end

    local is_still_missing = action == nil or action.action == nil
    if (is_still_missing) then return end

    if action.type == 'switch' then
        local target_env = kebab_casify(action.action or '')
        if (not self:is_valid_environment(target_env)) then
            windower.add_to_chat(123, '[XIVCrossbar] Cannot switch - set "' .. tostring(action.action) .. '" not found in current job.')
            return
        end
        if (self.temp_switch_previous_env == nil) then
            self.temp_switch_previous_env = env
        end
        self.pending_env_switch = target_env
        return
    end

    self:dispatch_action(action)

    if (self.temp_switch_previous_env ~= nil) then
        self.pending_env_switch = self.temp_switch_previous_env
        self.temp_switch_previous_env = nil
    end
end

function player:dispatch_action(action)
    if action.type == 'ct' then
        local command = '/' .. action.action

        if  action.target ~= nil then
            command = command .. ' <' ..  action.target .. '>'
        end

        windower.send_command('input ' .. command)
        return
    end

    if action.type == 'ex' then
        windower.send_command(action.action)
        return
    end

    if action.type == 'enchanteditem' then
        local item = action.action
        local equip_slot = action.equip_slot
        local delay = 0.5
        if (action.warmup ~= nil) then
            delay = delay + action.warmup
        end
        local recast = action.cooldown

        if (equip_slot ~= nil) then
            windower.send_command('gs disable ' .. equip_slot)
            windower.send_command('input /equip '.. equip_slot .. ' "' .. item .. '"')
            self.enchanted_items:equip(item)
        end

        local use_item = create_send_command_coroutine('input /item "' .. item .. '" <' .. action.target .. '>')
        coroutine.schedule(use_item, delay)
        local mark_used_item = player:create_use_item_coroutine(item)
        coroutine.schedule(mark_used_item, delay)

        if (equip_slot ~= nil) then
            local reactivate_equip_slot = create_send_command_coroutine('gs enable ' .. equip_slot)
            coroutine.schedule(reactivate_equip_slot, delay + 2)
        end
        return
    end

    local target_string = ''
    if (action.target ~= nil) then
        target_string = '" <' .. action.target .. '>'
    end

    if action.type == 'mount' and action.action == 'Mount Roulette' then
        mount_roulette:ride_random_mount()
        return
    elseif (action.type == 'ta' and action.action == 'Switch Target' and action.alias == 'Switch Target') then
        if (self.in_battle) then
            windower.send_command('input /a ' .. target_string)
        else
            windower.send_command('input /ta ' .. target_string)
        end
        return
    end

    windower.send_command('input /' .. action.type .. ' "' .. action.action .. target_string)
end

-- remove action from slot
function player:remove_action(environment, hotbar, slot)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] = nil
end

-- update a slot's icon
function player:set_slot_icon(environment, hotbar, slot, icon)
    if (environment == nil) then return false end
    if (self.hotbar[environment] == nil) then return false end
    local hb = self.hotbar[environment]['hotbar_' .. hotbar]
    if (hb == nil) then return false end
    local action = hb['slot_' .. slot]
    if (action == nil or action.action == nil) then return false end
    action.icon = icon
    return true
end

-- copy action from one slot to another
function player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if to_environment == 'b' then to_environment = 'battle' elseif to_environment == 'f' then to_environment = 'field' end
    if slot == 10 then slot = 0 end
    if to_slot == 10 then to_slot = 0 end

    if self.hotbar[environment] == nil or self.hotbar[to_environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil or self.hotbar[to_environment]['hotbar_' .. to_hotbar] == nil then return end

    self.hotbar[to_environment]['hotbar_' .. to_hotbar]['slot_' .. to_slot] = self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot]

    if is_moving then self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] = nil end
end

-- update action alias
function player:set_action_alias(environment, hotbar, slot, alias)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot].alias = alias
end

-- update action icon
function player:set_action_icon(environment, hotbar, slot, icon)
    if environment == 'b' then environment = 'battle' elseif environment == 'f' then environment = 'field' end
    if slot == 10 then slot = 0 end

    if self.hotbar[environment] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar] == nil then return end
    if self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot] == nil then return end

    self.hotbar[environment]['hotbar_' .. hotbar]['slot_' .. slot].icon = icon
end

-- create a new environment for the existing hotbar
function player:create_new_environment(name)
    if (name ~= nil) then
        local new_environment = {}
        for h=1,self.hotbar_settings.max,1 do
            new_environment['name'] = name
            new_environment['hotbar_' .. h] = {}
            for i=1,8,1 do
                new_environment['hotbar_' .. h]['slot_' .. i] = {}
            end
        end

        self.hotbar[kebab_casify(name)] = new_environment
    else
        print('XIVCROSSBAR: Attempted to create crossbar set with no name. Unable to create.')
    end
end

-- save current hotbar
function player:save_hotbar()
    local new_hotbar = {}
    new_hotbar.hotbar = self.hotbar

    storage:save_hotbar(new_hotbar)
end

return player