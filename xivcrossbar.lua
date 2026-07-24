-- Addon description
_addon.name = 'XIVCrossbar' -- based on Edeon's XIV Hotbar
_addon.author = 'Aliekber, Aeliya, GrayFox2510'
_addon.version = '0.3'
_addon.language = 'english'
_addon.commands = {'xivcrossbar', 'xb', 'xcb'}

-- Libs
res = require 'resources'
config = require('config')
file = require('files')
texts = require('texts')
images = require('images')
tables = require('tables')
resources = require('resources')
xml = require('libs/xml2')   -- TODO: REMOVE

-- User settings
local defaults = require('defaults')
local settings = config.load(defaults)
config.save(settings)

-- Load theme options according to settings
local theme = require('theme')
local theme_options = theme.apply(settings)
local buttonmapping = require('buttonmapping')
local resource_generator = require('resource_generator')
resource_generator.generate_outdated_resources()

-- Addon Dependencies
local action_manager = require('action_manager')
local keyboard = require('keyboard_mapper')
local gamepad = require('gamepad')
local player = require('player')
local ui = require('ui')
local env_chooser = require('environment_chooser')
local action_binder = require('action_binder')
local enchanted_items = require('enchanted_items')
local xivcrossbar = require('variables')
local skillchains = require('libs/skillchain/skillchains')
local consumables = require('consumables')
local gamepad_mapper = require('gamepad_mapper')
local gamepad_converter = require('gamepad_converter')
local function_key_bindings = require('function_key_bindings')

-----------------------------
-- Main
-----------------------------

local gamepad_state = {}
gamepad_state.left_trigger = false
gamepad_state.left_trigger_doublepress = false
gamepad_state.right_trigger = false
gamepad_state.right_trigger_doublepress = false
gamepad_state.active_bar = 0
local shift_pressed = false
local ui_dirty = false
local left_trigger_lifted_during_doublepress_window = false
local right_trigger_lifted_during_doublepress_window = false
local is_left_doublepress_window_open = false
local is_right_doublepress_window_open = false

local function close_left_doublepress_window()
    is_left_doublepress_window_open = false
    left_trigger_lifted_during_doublepress_window = false
end

local function close_right_doublepress_window()
    is_right_doublepress_window_open = false
    right_trigger_lifted_during_doublepress_window = false
end

-- command to set a crossbar action in action_binder
function set_hotkey(hotbar, slot, action_type, action, target, command, icon, linked_action, linked_type, explicit_alias)
    local environment = player.hotbar_settings.active_environment

    -- Custom-action bindings provide their own alias/linked metadata from the
    -- CustomActions.xml catalog, so the legacy name-based special cases below
    -- (which exist for the Attack / Ranged Attack / Assist / Last Synth
    -- categories) must not run — otherwise a custom action named "Attack"
    -- would get stomped. explicit_alias being non-nil is the signal that
    -- the caller knows exactly what it wants.
    local is_custom_action = (explicit_alias ~= nil or linked_action ~= nil or linked_type ~= nil)

    local alias = explicit_alias
    if (not is_custom_action) then
        if (action == 'Ranged Attack') then
            action = 'ra'
            alias = 'Ranged Attack'
            icon = 'ranged'
        elseif (action == 'Attack') then
            action = 'a'
            alias = 'Attack'
            icon = 'attack'
        elseif (action_type == 'assist') then
            action_type = 'ct'
            alias = action
            action = action:lower()
            icon = 'assist'
        elseif (action == 'Last Synth') then
            action = 'lastsynth'
            alias = 'Last Synth'
            icon = 'synth'
        end
    end

    if (command ~= nil) then
        -- If no explicit alias was provided, fall back to the human-readable
        -- action name being replaced by the raw command (existing behavior).
        if (alias == nil) then alias = action end
        action = command
    end

    local new_action = action_manager:build(action_type, action, target, alias, icon, nil, nil, nil, nil, linked_action, linked_type)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

-- command to set a crossbar action in action_binder
function delete_hotkey(hotbar, slot)
    local environment = player.hotbar_settings.active_environment

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

function get_crossbar_sets()
    return player:get_crossbar_names()
end

-- Change Icon callback: replaces the icon of an already-bound slot, persists
-- the hotbar XML, and reloads so the new icon shows immediately. Wired into
-- action_binder.lua's :setup().
--   hotbar_num: 1-6 (which trigger combo: L/R/RL/LR/LL/RR)
--   slot_num: 1-8 (which face button or d-pad direction)
-- Operates on the currently-active environment.
function change_slot_icon(hotbar_num, slot_num, icon)
    if (hotbar_num == nil or slot_num == nil) then return end

    local environment = player.hotbar_settings.active_environment
    local updated = player:set_slot_icon(environment, hotbar_num, slot_num, icon)
    if (not updated) then
        windower.add_to_chat(123, '[XIVCrossbar] Change Icon: no action bound at the selected slot.')
        return
    end

    player:save_hotbar()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)
end

-- Global Icon Set callback: writes a SharedIcons.xml entry pairing an action
-- name with an icon path. After save, the SharedIcons fallback layer applies
-- the new icon to every slot in every job that matches the name (by alias or
-- action text). Wired into action_binder.lua's :setup().
function save_global_icon(name, icon)
    if (name == nil or name == '' or icon == nil or icon == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Global Icon Set: missing name or icon.')
        return
    end

    player.shared_icons[name] = icon
    player:save_shared_icons_file()
    reload_hotbar()
    set_active_environment(player.hotbar_settings.active_environment)

    windower.add_to_chat(123, '[XIVCrossbar] Global icon set: "' .. name .. '" -> ' .. icon)
end

-- Create Custom Action callback: persists a CustomActions.xml entry from a
-- record built up during the binder's create-flow. The record is the same
-- shape we read back via load_custom_actions: {name, alias, command, icon,
-- linked_action, linked_type}.
function save_custom_action(record)
    if (record == nil or record.name == nil or record.name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Create Custom Action: missing name.')
        return
    end
    -- Update in-memory catalog and persist.
    player.custom_actions[record.name] = {
        command       = record.command,
        alias         = record.alias,
        icon          = record.icon,
        linked_action = record.linked_action,
        linked_type   = record.linked_type,
    }
    player:save_custom_actions_file()
    -- No reload needed for the catalog itself — the binder's existing
    -- "Custom Action" selector pulls from player.custom_actions in real time.
    windower.add_to_chat(123, '[XIVCrossbar] Custom action saved: "' .. record.name .. '"')
end

-- Edit Custom Action callback: persists changes to an existing entry,
-- handling rename by removing the old key before writing the new one. The
-- binder has already chat-warned the user about orphaned slot bindings if
-- the name changed.
function update_custom_action(original_name, record)
    if (record == nil or record.name == nil or record.name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Edit Custom Action: missing name.')
        return
    end
    if (original_name ~= nil and original_name ~= record.name) then
        player.custom_actions[original_name] = nil
    end
    player.custom_actions[record.name] = {
        command       = record.command,
        alias         = record.alias,
        icon          = record.icon,
        linked_action = record.linked_action,
        linked_type   = record.linked_type,
    }
    player:save_custom_actions_file()
    windower.add_to_chat(123, '[XIVCrossbar] Custom action updated: "' .. record.name .. '"')
end

-- Delete Custom Action callback: removes an entry from the catalog and
-- rewrites CustomActions.xml. Slots that reference the deleted name are
-- left as-is; user is responsible for cleaning those up.
function delete_custom_action(name)
    if (name == nil or name == '') then
        windower.add_to_chat(123, '[XIVCrossbar] Delete Custom Action: missing name.')
        return
    end
    if (player.custom_actions == nil or player.custom_actions[name] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] Delete Custom Action: entry "' .. name .. '" not found.')
        return
    end
    player.custom_actions[name] = nil
    player:save_custom_actions_file()
    windower.add_to_chat(123, '[XIVCrossbar] Custom action deleted: "' .. name .. '". Existing slot bindings referencing it will not be auto-removed.')
end

function start_controller_wrappers()
    -- windower.send_command('run addons/xivcrossbar/ffxi_directinput.ahk')
    -- windower.send_command('run addons/xivcrossbar/ffxi_input_diagnostic.ahk')
    windower.send_command('run addons/xivcrossbar/ffxi_xinput.ahk')
end

-- initialize addon
function initialize()
    local windower_player = windower.ffxi.get_player()
    local server = resources.servers[windower.ffxi.get_info().server].en
    if (server == nil) then
        server = 'UnknownServer'
    end

    if windower_player == nil then return end

    if (buttonmapping.validate()) then
        theme_options.button_layout = buttonmapping.button_layout
        action_binder:setup(buttonmapping, set_hotkey, delete_hotkey, theme_options, get_crossbar_sets, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - 450, change_slot_icon, save_global_icon, save_custom_action, update_custom_action, delete_custom_action)
    else
        theme_options.button_layout = 'nintendo'
        local temp_buttonmapping = {}
        theme_options.confirm_button = 'a'
        theme_options.cancel_button = 'b'
        theme_options.mainmanu_button = 'y'
        theme_options.activewindow_button = 'x'
        gamepad_mapper:setup(buttonmapping, start_controller_wrappers, theme_options, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - 450)
        gamepad_mapper:show(true)
        action_binder:setup(temp_buttonmapping, set_hotkey, delete_hotkey, theme_options, get_crossbar_sets, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - 450, change_slot_icon, save_global_icon, save_custom_action, update_custom_action, delete_custom_action)
    end

    player:initialize(windower_player, server, theme_options, enchanted_items)
    player:load_hotbar()
    ui:setup(theme_options, enchanted_items)
    action_binder:set_ui_offset_callback(function(x, y)
        ui:update_offsets(x, y)
        if (settings.Style.OffsetX ~= x) then
            settings.Style.OffsetX = x
        end
        if (settings.Style.OffsetY ~= y) then
            settings.Style.OffsetY = y
        end
        config.save(settings)
    end)

    local default_active_environment = env_chooser:get_default_active_environment(player.hotbar)
    set_active_environment(default_active_environment)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)

    consumables:setup()
    env_chooser:setup(theme_options)
    gamepad_converter:setup(theme_options.button_layout)

    local current_status = windower.ffxi.get_player().status
    aa_set_engaged(current_status == 1 or current_status == 3)

    xivcrossbar.ready = true
    xivcrossbar.initialized = true
end

-- trigger hotbar action
function trigger_action(slot)
    player:execute_action(slot)

    if (player.pending_env_switch ~= nil) then
        local target = player.pending_env_switch
        player.pending_env_switch = nil
        set_active_environment(target)
    end

    ui:trigger_feedback(player.hotbar_settings.active_hotbar, slot)
end

-- set battle environment
function set_battle_environment(in_battle)
    player:set_battle_environment(in_battle)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- set battle environment
function set_active_environment(environment_name)
    player:set_active_environment(environment_name)
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- check validity of an environment
function is_valid_environment(environment_name)
    return player:is_valid_environment(environment_name)
end

-- reload hotbar
function reload_hotbar()
    player:load_hotbar()
    ui:load_player_hotbar(player.hotbar, player.vitals, player.hotbar_settings.active_environment, gamepad_state)
end

-- change active hotbar
function change_active_hotbar(new_hotbar)
    player:change_active_hotbar(new_hotbar)
end

-----------------------------
-- Addon Commands
-----------------------------

-- command to switch to a specific crossbar
function switch_crossbars_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: crossbar <crossbar_set>')
        return
    end

    local environment = args[1]:lower()

    if (is_valid_environment(environment)) then
        set_active_environment(environment)
    else
        print('XIVCROSSBAR: "' .. environment .. '" is not a valid crossbar set.')
    end
end

-- command to set an action in a hotbar
function set_action_command(args)
    if not args[5] then
        print('XIVCROSSBAR: Invalid arguments: set <mode> <hotbar> <slot> <action_type> <action> <target (optional)> <alias (optional)> <icon (optional)>')
        return
    end

    local environment = args[1]:lower()

    if (args[2] == nil) then
        if (is_valid_environment(args[2])) then
            set_active_environment(args[2])
        else
            print('XIVCROSSBAR: "' .. args[2] .. '" is not a valid crossbar set.')
        end
    end

    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local action_type = args[4]:lower()
    local action = args[5]
    local target = args[6] or nil
    local alias = args[7] or nil
    local icon = args[8] or nil

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    if target ~= nil then target = target:lower() end

    local new_action = action_manager:build(action_type, action, target, alias, icon)
    player:add_action(new_action, environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to delete an action from an hotbar
function delete_action_command(args)
    if not args[3] then
        print('XIVCROSSBAR: Invalid arguments: del <mode> <hotbar> <slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0

    if hotbar < 1 or hotbar > theme_options.hotbar_number then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:remove_action(environment, hotbar, slot)
    player:save_hotbar()
    reload_hotbar()
end

-- command to copy an action to another slot
function copy_action_command(args, is_moving)
    local command = 'copy'
    if is_moving then command = 'move' end

    if not args[6] then
        print('XIVCROSSBAR: Invalid arguments: ' .. command .. ' <mode> <hotbar> <slot> <to_mode> <to_hotbar> <to_slot>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local to_environment = args[4]:lower()
    local to_hotbar = gamepad_converter:convert_to_crossbar(args[5]) or 0
    local to_slot = gamepad_converter:convert_to_slot(args[6]) or 0

    if hotbar < 1 or hotbar > 3 or to_hotbar < 1 or to_hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 or to_slot < 1 or to_slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:copy_action(environment, hotbar, slot, to_environment, to_hotbar, to_slot, is_moving)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action alias
function update_alias_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: alias <mode> <hotbar> <slot> <alias>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local alias = args[4]

    if hotbar < 1 or hotbar > 7 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_alias(environment, hotbar, slot, alias)
    player:save_hotbar()
    reload_hotbar()
end

-- command to update action icon
function update_icon_command(args)
    if not args[4] then
        print('XIVCROSSBAR: Invalid arguments: icon <mode> <hotbar> <slot> <icon>')
        return
    end

    local environment = args[1]:lower()
    local hotbar = gamepad_converter:convert_to_crossbar(args[2]) or 0
    local slot = gamepad_converter:convert_to_slot(args[3]) or 0
    local icon = args[4]

    if hotbar < 1 or hotbar > 3 then
        print('XIVCROSSBAR: Invalid hotbar. Please use a number between 1 and ' .. theme_options.hotbar_number .. '.')
        return
    end

    if slot < 1 or slot > 8 then
        print('XIVCROSSBAR: Invalid slot. Please use a number between 1 and 8.')
        return
    end

    player:set_action_icon(environment, hotbar, slot, icon)
    player:save_hotbar()
    reload_hotbar()
end

-- Custom Action field-set chat command. Forms accepted:
--   //xivcrossbar ca <field> <value...>
--   //xivcrossbar custom <field> <value...>
-- Field token: a|alias, n|name, c|command. Value is everything after the
-- field token and is rejoined with spaces (Windower splits argv on spaces).
-- Only accepted while a Custom Action review screen is 
-- active; otherwise the binder reports the error to chat.
function custom_action_field_command(args)
    if (not args[1] or not args[2]) then
        windower.add_to_chat(123, '[XIVCrossbar] Usage: //xcb ca <a|n|c> <value>')
        return
    end

    local field_token = args[1]:lower()
    local field = nil
    if (field_token == 'a' or field_token == 'alias') then
        field = 'alias'
    elseif (field_token == 'n' or field_token == 'name') then
        field = 'name'
    elseif (field_token == 'c' or field_token == 'command') then
        field = 'command'
    else
        windower.add_to_chat(123, '[XIVCrossbar] Unknown field "' .. args[1] .. '". Use a|alias, n|name, or c|command.')
        return
    end

    -- Rejoin everything past the field token to preserve internal spaces.
    local parts = {}
    for i = 2, #args do
        parts[#parts + 1] = args[i]
    end
    local value = table.concat(parts, ' ')

    action_binder:on_custom_action_field_set(field, value)
end

-- command to update action icon
function new_environment_command(args)
    if not args[1] then
        print('XIVCROSSBAR: Invalid arguments: new <name>')
        return
    end

    local environment = args[1]
    local env_lower = environment:lower()

    if (env_lower == 'default' or env_lower == 'job-default' or env_lower == 'all-jobs-default') then
        print('XIVCROSSBAR: Crossbar set name "' .. environment .. '" is reserved. Unable to create.')
        return
    end

    player:create_new_environment(environment)
    player:save_hotbar()
    reload_hotbar()
    set_active_environment(environment)
end

-- Helpers for the rename / delete environment commands. Reserved keys are
-- the four pinned environments that the rest of the addon assumes always
-- exist; renaming or deleting any of them would break loading and many
-- fallback paths.
local PROTECTED_ENV_KEYS = {
    ['default'] = true,
    ['job-default'] = true,
    ['all-jobs-default'] = true,
    ['shared'] = true,
}

-- Count slots across all loaded environments whose type is 'switch' and
-- whose <action> equals the given kebab-cased env name. Used to warn the
-- user about bindings that will be left dangling by a rename or delete.
-- Only the currently-loaded job's hotbar files are scanned (other jobs'
-- per-job XMLs aren't in memory and aren't rewritten by this command).
local function count_switch_references(env_kebab)
    local count = 0
    if (player.hotbar == nil) then return 0 end
    for env_name, env in pairs(player.hotbar) do
        if (type(env) == 'table') then
            for key, hotbar in pairs(env) do
                if (type(hotbar) == 'table' and key:sub(1, 7) == 'hotbar_') then
                    for slot_key, slot in pairs(hotbar) do
                        if (type(slot) == 'table' and slot.type == 'switch' and slot.action == env_kebab) then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

-- Rename an existing crossbar set (environment) in the currently-loaded
-- job's hotbar files. Re-keys player.hotbar[<old>] to player.hotbar[<new>],
-- updates the env's `name` field, repoints the active-environment pointer
-- if needed, and warns about any switch-type slots that still reference
-- the old name.
function rename_environment_command(args)
    if (not args[1] or not args[2]) then
        windower.add_to_chat(123, '[XIVCrossbar] Usage: //xcb rename <old name> <new name>')
        return
    end

    -- Since there's no real way to identify multiple words for the old and new tokens,
    -- everything but the LAST word is considered as the "old" name, and only the very 
    -- LAST word is treated as the new name.
    -- ex: "//xivcrossbar rn Boss Setup Solo" would rename "Boss Setup" -> "Solo".
    local old_name = args[1]
    local new_name = args[2]
    if (#args > 2) then
        local parts = {}
        for i = 1, #args - 1 do parts[#parts + 1] = args[i] end
        old_name = table.concat(parts, ' ')
        new_name = args[#args]
    end

    local old_key = kebab_casify(old_name)
    local new_key = kebab_casify(new_name)

    if (PROTECTED_ENV_KEYS[old_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set "' .. old_name .. '" is reserved and cannot be renamed.')
        return
    end
    if (PROTECTED_ENV_KEYS[new_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set name "' .. new_name .. '" is reserved.')
        return
    end
    if (old_key == new_key) then
        windower.add_to_chat(123, '[XIVCrossbar] New name resolves to the same key as the old name. Nothing to do.')
        return
    end
    if (player.hotbar[old_key] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] No crossbar set named "' .. old_name .. '" found in the current job.')
        return
    end
    if (player.hotbar[new_key] ~= nil) then
        windower.add_to_chat(123, '[XIVCrossbar] A crossbar set named "' .. new_name .. '" already exists.')
        return
    end

    -- Move the env dict to the new key and update its display name field.
    local env = player.hotbar[old_key]
    env.name = new_name
    player.hotbar[new_key] = env
    player.hotbar[old_key] = nil

    -- If the renamed env was active, repoint the pointer.
    if (player.hotbar_settings.active_environment == old_key) then
        player.hotbar_settings.active_environment = new_key
    end

    -- Warn about orphaned switch-type bindings that still reference the
    -- old name — those will not be auto-rewritten.
    local orphan_count = count_switch_references(old_key)

    player:save_hotbar()
    reload_hotbar()

    windower.add_to_chat(123, '[XIVCrossbar] Crossbar set renamed: "' .. old_name .. '" -> "' .. new_name .. '".')
    if (orphan_count > 0) then
        windower.add_to_chat(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) still reference the old name and will no longer work until updated.')
    end
end

-- Delete an existing crossbar set (environment) in the currently-loaded
-- job. Removes the entire env including all of its slot bindings, falls
-- the active-environment pointer back to a safe default if necessary, and
-- warns about any switch-type slots that still reference the deleted name.
-- There is NO going back, which is why you have to type the whole thing, 
-- no aliases to avoid mistakes.
function delete_environment_command(args)
    if (not args[1]) then
        windower.add_to_chat(123, '[XIVCrossbar] Usage: //xcb deleteset <name>')
        return
    end

    -- Allow multi-word names by joining argv.
    local target_name = table.concat(args, ' ')
    local target_key = kebab_casify(target_name)

    if (PROTECTED_ENV_KEYS[target_key]) then
        windower.add_to_chat(123, '[XIVCrossbar] Crossbar set "' .. target_name .. '" is reserved and cannot be deleted.')
        return
    end
    if (player.hotbar[target_key] == nil) then
        windower.add_to_chat(123, '[XIVCrossbar] No crossbar set named "' .. target_name .. '" found in the current job.')
        return
    end

    -- Drop the env (and all its slot bindings) entirely.
    player.hotbar[target_key] = nil

    -- If the deleted env was active, switch to a safe fallback computed
    -- by env_chooser (same path as the addon's normal startup recovery).
    if (player.hotbar_settings.active_environment == target_key) then
        local fallback = env_chooser:get_default_active_environment(player.hotbar)
        set_active_environment(fallback)
    end

    -- Warn about orphaned switch-type bindings before saving so the count
    -- reflects the state seen by the user up to this moment.
    local orphan_count = count_switch_references(target_key)

    player:save_hotbar()
    reload_hotbar()

    windower.add_to_chat(123, '[XIVCrossbar] Crossbar set deleted: "' .. target_name .. '" (and all its slot bindings).')
    if (orphan_count > 0) then
        windower.add_to_chat(123, '[XIVCrossbar] Warning: ' .. orphan_count .. ' Quick XB Switch slot(s) referenced the deleted set and will no longer work.')
    end
end

-- command to rerun the setup dialog
function remap()
    gamepad_mapper:setup(buttonmapping, start_controller_wrappers, theme_options, 150, 150, windower.get_windower_settings().ui_x_res - 300, windower.get_windower_settings().ui_y_res - 450)
    gamepad_mapper:show(false)
end

function regenerate_resources()
    resource_generator.generate_all_resources()
end

-- command to display help for the user
function display_help_menu()
    local layout = theme_options.button_layout:lower()
    local minus_button = 'Minus'
    if (layout == 'playstation') then
        minus_button = 'Share'
    elseif (layout == 'xbox') then
        minus_button = 'Back'
    end
    local plus_button = 'Plus'
    if (layout == 'playstation') then
        plus_button = 'Options'
    elseif (layout == 'xbox') then
        plus_button = 'Start'
    end
    local left_trigger = 'L'
    if (layout == 'playstation') then
        left_trigger = 'L2'
    end
    local right_trigger = 'R'
    if (layout == 'playstation') then
        right_trigger = 'R2'
    end
    local buttons = 'A/B/X/Y'
    if (layout == 'playstation') then
        buttons = 'Face'
    end

    windower.send_command('echo ================ XIVCrossbar Help ================')
    windower.send_command('echo Command prefix: //xivcrossbar  -or-  //xb  -or-  //xcb')
    windower.send_command('echo --- Crossbar set management ---')
    windower.send_command('echo new <name>                      Create a new crossbar set')
    windower.send_command('echo rename <old> <new>              Rename an existing set (rn)')
    windower.send_command('echo deleteset <name>                Delete a set and all its bindings')
    windower.send_command('echo --- Slot binding management ---')
    windower.send_command('echo set <env> <hb> <slot> ...       Bind an action to a slot')
    windower.send_command('echo clear <env> <hb> <slot>         Clear (remove) a slot binding')
    windower.send_command('echo cp/copy <env> <hb> <slot> <dest hb> <dest slot>')
    windower.send_command('echo mv/move <env> <hb> <slot> <dest hb> <dest slot>')
    windower.send_command('echo icon/ic <env> <hb> <slot> <icon>')
    windower.send_command('echo alias/al/caption <env> <hb> <slot> <text>   Set slot caption')
    windower.send_command('echo --- Custom Actions ---')
    windower.send_command('echo ca/custom <a|n|c> <value>       Set field while a CA flow is active')
    windower.send_command('echo --- Other ---')
    windower.send_command('echo remap                           Rerun the gamepad setup utility')
    windower.send_command('echo regenerate                      Regenerate cached resource files')
    windower.send_command('echo reload                          Reload the active hotbar')
    windower.send_command('echo help / ?                        Show this help')
    windower.send_command('echo ================ Identifiers ================')
    windower.send_command('echo Hotbar (<hb>):  l, r, rl, lr, ll, rr   (or 1-6)')
    windower.send_command('echo Slot   (<slot>): ll, ld, lr, lu, rl, rd, rr, ru   (or 1-8)')
    windower.send_command('echo ================ Gamepad (' .. theme_options.button_layout .. ') ================')
    windower.send_command('echo ' .. plus_button .. ' + D-Pad (up/down): Switch between crossbar sets')
    windower.send_command('echo ' .. minus_button .. ': Open/close button bind utility')
    windower.send_command('echo ' .. left_trigger .. '/' .. right_trigger .. ' + D-Pad: Navigate button bind utility (when open)')
    windower.send_command('echo ' .. left_trigger .. '/' .. right_trigger .. ' + D-Pad or ' .. buttons .. ' Button: Execute bound action')
    windower.send_command('echo ===============================================')
end

-----------------------------
-- Bind Events
-----------------------------

-- ON LOAD
windower.register_event('load',function()
    if (buttonmapping.validate()) then
        start_controller_wrappers()
    end

    if windower.ffxi.get_info().logged_in then
        initialize()
    end
    skillchains.load()

    -- Unbind Ctrl + <F1 through F12> because they're going proxy the gamepad's triggers and buttons
    -- We use Ctrl instead of Alt because Alt gets stuck in a down state when Alt+Tabbing sometimes
    -- minus button
    windower.send_command('unbind ^f1')
    -- plus button
    windower.send_command('unbind ^f2')
    -- dpad up
    windower.send_command('unbind ^f3')
    -- dpad right
    windower.send_command('unbind ^f4')
    -- dpad down
    windower.send_command('unbind ^f5')
    -- dpad left
    windower.send_command('unbind ^f6')
    -- a button
    windower.send_command('unbind ^f7')
    -- b button
    windower.send_command('unbind ^f8')
    -- x button
    windower.send_command('unbind ^f9')
    -- y button
    windower.send_command('unbind ^f10')
    -- left trigger
    windower.send_command('unbind ^f11')
    -- right trigger
    windower.send_command('unbind ^f12')
end)

-- ON LOGIN
windower.register_event('login',function()
    initialize()
    skillchains.login()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    ui:hide()
    skillchains.logout()
    windower.send_command('lua u xivcrossbar')
end)

-- ON COMMAND
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}

    if command == 'reload' then
        return reload_hotbar()

    elseif command == 'bar' or command == 'crossbar' or command == 'hotbar' then
        switch_crossbars_command(args)
    elseif command == 'set' then
        set_action_command(args)
    elseif command == 'clear' then
        -- Renamed from "del" because you're just clearing the slot.
        -- And to avoid confusion with "deleteset" because of its
        -- destructive nature.
        delete_action_command(args)
    elseif command == 'deleteset' then
        -- Spelled out fully (no short alias) to avoid accidental triggering.
        -- This removes the whole crossbar set including every slot binding
        -- it contains.
        delete_environment_command(args)
    elseif command == 'rn' or command == 'rename' then
        rename_environment_command(args)
    elseif command == 'cp' or command == 'copy' then
        copy_action_command(args, false)
    elseif command == 'mv' or command == 'move' then
        copy_action_command(args, true)
    elseif command == 'ic' or command == 'icon' then
        update_icon_command(args)
    elseif command == 'al' or command == 'alias' or command == 'caption' then
        update_alias_command(args)
    elseif command == 'ca' or command == 'custom' then
        -- Custom Action field-set: Only used when creating/editing
        -- a custom action. Basically, when the action binder instructs you.
        custom_action_field_command(args)
    elseif command == 'n' or command == 'new' then
        new_environment_command(args)
    elseif command == 'remap' then
        remap()
    elseif command == 'regenerate' then
        regenerate_resources()
    elseif command == '?' or command == 'help' then
        display_help_menu()
    end
end)

local keys = {
    [2] = '1',
    [3] = '2',
    [4] = '3',
    [5] = '4',
    [6] = '5',
    [7] = '6',
    [8] = '7',
    [9] = '8',
    [10] = '9',
    [11] = '0',
    [12] = '-',
    [13] = '=',
    [26] = '[',
    [27] = ']',
    [39] = ';',
    [40] = '\'',
    [41] = '`',
    [43] = '\\',
    [51] = ',',
    [52] = '.',
    [53] = '/',
    [30] = 'A',
    [48] = 'B',
    [46] = 'C',
    [32] = 'D',
    [18] = 'E',
    [33] = 'F',
    [34] = 'G',
    [35] = 'H',
    [23] = 'I',
    [36] = 'J',
    [37] = 'K',
    [38] = 'L',
    [50] = 'M',
    [49] = 'N',
    [24] = 'O',
    [25] = 'P',
    [16] = 'Q',
    [19] = 'R',
    [31] = 'S',
    [20] = 'T',
    [22] = 'U',
    [47] = 'V',
    [17] = 'W',
    [45] = 'X',
    [21] = 'Y',
    [44] = 'Z'
}

-- ON KEY
windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    local left_trigger_just_pressed = pressed and gamepad.is_left_trigger(dik) and not gamepad_state.left_trigger
    local right_trigger_just_pressed = pressed and gamepad.is_right_trigger(dik) and not gamepad_state.right_trigger
    local left_trigger_just_released = (not pressed) and gamepad.is_left_trigger(dik) and gamepad_state.left_trigger
    local right_trigger_just_released = (not pressed) and gamepad.is_right_trigger(dik) and gamepad_state.right_trigger

    ui_dirty = left_trigger_just_pressed or right_trigger_just_pressed or left_trigger_just_released or right_trigger_just_released

    if (gamepad.is_left_trigger(dik)) then
        gamepad_state.left_trigger = pressed
    elseif (gamepad.is_right_trigger(dik)) then
        gamepad_state.right_trigger = pressed
    elseif (dik == keyboard.ctrl) then
        gamepad_state.capturing = pressed
    elseif (dik == keyboard.shift) then
        shift_pressed = pressed
    elseif (gamepad.is_minus(dik)) then
        gamepad_state.minus_button = pressed
    elseif (gamepad.is_plus(dik)) then
        gamepad_state.plus_button = pressed
    end

    local only_left_trigger_just_pressed = left_trigger_just_pressed and not gamepad_state.right_trigger
    if (not is_left_doublepress_window_open and only_left_trigger_just_pressed) then
        is_left_doublepress_window_open = true
        is_right_doublepress_window_open = false
        coroutine.schedule(close_left_doublepress_window, 0.5)
    end
    local only_right_trigger_just_pressed = right_trigger_just_pressed and not gamepad_state.left_trigger
    if (not is_right_doublepress_window_open and only_right_trigger_just_pressed) then
        is_right_doublepress_window_open = true
        is_left_doublepress_window_open = false
        coroutine.schedule(close_right_doublepress_window, 0.5)
    end

    local only_left_trigger_just_released = left_trigger_just_released and not gamepad_state.right_trigger
    if (is_left_doublepress_window_open and only_left_trigger_just_released) then
        left_trigger_lifted_during_doublepress_window = true
    end
    local only_right_trigger_just_released = right_trigger_just_released and not gamepad_state.left_trigger
    if (is_right_doublepress_window_open and only_right_trigger_just_released) then
        right_trigger_lifted_during_doublepress_window = true
    end

    if (only_left_trigger_just_pressed and is_left_doublepress_window_open and left_trigger_lifted_during_doublepress_window) then
        gamepad_state.left_trigger_doublepress = true
        is_left_doublepress_window_open = false
    end
    if (only_right_trigger_just_pressed and is_right_doublepress_window_open and right_trigger_lifted_during_doublepress_window) then
        gamepad_state.right_trigger_doublepress = true
        is_right_doublepress_window_open = false
    end

    if (left_trigger_just_released and gamepad_state.left_trigger_doublepress) then
        gamepad_state.left_trigger_doublepress = false
    end
    if (right_trigger_just_released and gamepad_state.right_trigger_doublepress) then
        gamepad_state.right_trigger_doublepress = false
    end

    -- windower.send_command('@input /echo '..dik)

    -- If the user presses Ctrl+F1 through Ctrl+F10 and neither trigger is down, then activate their bound command
    local no_triggers_pressed = not gamepad_state.left_trigger and not gamepad_state.right_trigger
    local no_menu_buttons_pressed = not gamepad_state.minus_button and not gamepad_state.plus_button
    if (gamepad_state.capturing and no_triggers_pressed and no_menu_buttons_pressed and dik >= keyboard.f1 and dik <= keyboard.f8 and pressed) then
        local function_key = (dik - keyboard.f1) + 1
        local natural_binding_key = 'CtrlF' .. function_key .. 'Command'
        local command = function_key_bindings[natural_binding_key]
        windower.send_command(command)
    end

    if (env_chooser.capturing and keys[dik] ~= nil) then
        if (pressed) then
            if (shift_pressed) then
                env_chooser:send_key(keys[dik])
            else
                env_chooser:send_key(keys[dik]:lower())
            end
        end
        return true
    elseif (env_chooser.capturing and dik == keyboard.backspace and pressed) then
        env_chooser:send_backspace()
    elseif (env_chooser.capturing and dik == keyboard.esc and pressed) then
        local next_environment = env_chooser:get_next_environment(player.hotbar, player.hotbar_settings.active_environment)
        set_active_environment(next_environment)
        env_chooser:send_escape()
    elseif (env_chooser.capturing and dik == keyboard.enter and pressed) then
        if (env_chooser:validate_new_set_name()) then
            new_environment_command(L{env_chooser:get_new_set_name()})
            env_chooser:clear()
        else
            windower.send_command('input /echo [XIVCrossbar] Crossbar set name "' .. env_chooser:get_new_set_name() .. '" is reserved. Unable to create.')
        end
        return true
    end

    if (gamepad_state.capturing and gamepad_state.left_trigger and not gamepad_state.right_trigger) then
        if (gamepad_state.left_trigger_doublepress and theme_options.hotbar_number >= 5) then
            change_active_hotbar(5)
            gamepad_state.active_bar = 5
        else
            change_active_hotbar(1)
            gamepad_state.active_bar = 1
        end
    elseif (gamepad_state.capturing and gamepad_state.right_trigger and not gamepad_state.left_trigger) then
        if (gamepad_state.right_trigger_doublepress and theme_options.hotbar_number >= 6) then
            change_active_hotbar(6)
            gamepad_state.active_bar = 6
        else
            change_active_hotbar(2)
            gamepad_state.active_bar = 2
        end
    elseif (gamepad_state.capturing and gamepad_state.right_trigger and gamepad_state.left_trigger) then
        if (theme_options.hotbar_number > 3) then
            if (left_trigger_just_pressed) then
                -- R -> L = bar 3
                change_active_hotbar(3)
                gamepad_state.active_bar = 3
            elseif (right_trigger_just_pressed) then
                -- L -> R = bar 4
                change_active_hotbar(4)
                gamepad_state.active_bar = 4
            end
        else
            change_active_hotbar(3)
            gamepad_state.active_bar = 3
        end
    else
        gamepad_state.active_bar = 0
    end

    if (not gamepad_mapper.is_showing and gamepad_state.capturing and gamepad.is_minus(dik) and pressed) then
        if (action_binder.is_hidden) then
            action_binder:show()
            ui:hide_button_hints()
            env_chooser:temp_hide_default_sets_tooltip()
        else
            action_binder:hide()
            action_binder:reset_state()
            ui:maybe_show_button_hints()
            env_chooser:maybe_unhide_default_sets_tooltip()
        end
        return true
    end

    if (gamepad_mapper.is_showing) then
        if (gamepad.is_face_button_or_dpad(dik)) then
            if (gamepad.is_button_b(dik)) then
                gamepad_mapper:button_b(pressed)
            elseif (gamepad.is_button_a(dik)) then
                gamepad_mapper:button_a(pressed)
            elseif (gamepad.is_button_x(dik)) then
                gamepad_mapper:button_x(pressed)
            elseif (gamepad.is_button_y(dik)) then
                gamepad_mapper:button_y(pressed)
            end
            return true
        end

        if (gamepad.is_left_trigger(dik)) then
            gamepad_mapper:trigger_left(pressed)
        elseif (gamepad.is_right_trigger(dik)) then
            gamepad_mapper:trigger_right(pressed)
        end
    elseif (not action_binder.is_hidden) then
        if (gamepad_state.capturing) then
            if (gamepad.is_face_button_or_dpad(dik)) then
                local action_binder_was_showing = not action_binder.is_hidden

                if (gamepad.is_dpad_left(dik)) then
                    action_binder:dpad_left(pressed)
                elseif (gamepad.is_dpad_down(dik)) then
                    action_binder:dpad_down(pressed)
                elseif (gamepad.is_dpad_right(dik)) then
                    action_binder:dpad_right(pressed)
                elseif (gamepad.is_dpad_up(dik)) then
                    action_binder:dpad_up(pressed)
                elseif (gamepad.is_button_b(dik)) then
                    action_binder:button_b(pressed)
                elseif (gamepad.is_button_a(dik)) then
                    action_binder:button_a(pressed)
                elseif (gamepad.is_button_x(dik)) then
                    action_binder:button_x(pressed)
                elseif (gamepad.is_button_y(dik)) then
                    action_binder:button_y(pressed)
                end
                if (action_binder_was_showing and action_binder.is_hidden) then
                    ui:maybe_show_button_hints()
                end
                return true
            end

            if (gamepad.is_left_trigger(dik)) then
                action_binder:trigger_left(pressed)
            elseif (gamepad.is_right_trigger(dik)) then
                action_binder:trigger_right(pressed)
            end
        end
    end

    if (env_chooser:is_showing() and pressed) then
        -- handle up and down arrows if the environment chooser is showing
        if gamepad_state.capturing and gamepad.is_dpad_down(dik) then
            local prev_environment = env_chooser:get_prev_environment(player.hotbar, player.hotbar_settings.active_environment)
            set_active_environment(prev_environment)
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
            return true
        elseif gamepad_state.capturing and gamepad.is_dpad_up(dik) then -- up dpad
            local next_environment = env_chooser:get_next_environment(player.hotbar, player.hotbar_settings.active_environment)
            set_active_environment(next_environment)
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
            return true
        end
    end

    local any_trigger_down = gamepad_state.left_trigger or gamepad_state.right_trigger
    if (gamepad_state.capturing and any_trigger_down and gamepad.is_face_button_or_dpad(dik)) then
        if (pressed) then
            if (gamepad.is_dpad_left(dik)) then
                trigger_action(1)
            elseif (gamepad.is_dpad_down(dik)) then
                trigger_action(2)
            elseif (gamepad.is_dpad_right(dik)) then
                trigger_action(3)
            elseif (gamepad.is_dpad_up(dik)) then
                trigger_action(4)
            elseif (gamepad.is_button_b(dik)) then
                trigger_action(5)
            elseif (gamepad.is_button_a(dik)) then
                trigger_action(6)
            elseif (gamepad.is_button_x(dik)) then
                trigger_action(7)
            elseif (gamepad.is_button_y(dik)) then
                trigger_action(8)
            end

            if (not (gamepad.is_plus(dik) or gamepad.is_minus(dik))) then
                return true
            end
        end
    end

    if (gamepad_state.capturing and gamepad.is_plus(dik)) then
        if (pressed) then
            local environments = env_chooser:get_player_environments(player.hotbar)
            env_chooser:show_player_environments(player.hotbar, player.hotbar_settings.active_environment)
        else
            env_chooser:hide_player_environments()
        end
    end
end)

local frame = 0

-- ON PRERENDER
windower.register_event('prerender',function()
    -- allow settings to skip rendering frames
    frame = (frame + 1)  % (theme_options.frame_skip + 1)
    if (frame > 0 and not ui_dirty) then
        return
    end

    skillchains.prerender()
    if xivcrossbar.ready == false then
        return
    end

    if ui.feedback.is_active then
        ui:show_feedback()
    end

    if ui.is_setup and xivcrossbar.hide_hotbars == false then
        local dim_default_slots = not action_binder.is_hidden        
        ui:check_recasts(player.hotbar, player.vitals, player.hotbar_settings.active_environment, player.current_spells, gamepad_state, skillchains, consumables, dim_default_slots, xivcrossbar.in_battle)
    end

    ui_dirty = false
end)

-- ON ACTIONS (filtered to Job Abilities)
windower.register_event('action', function(actor_id, category)
    -- Skip while initialize() hasn't run yet (e.g. addon loaded before
    -- the player is logged in). The login event will set ready=true once
    -- a character has been selected.
    if (not xivcrossbar.ready) then return end
    if (actor_id == player:get_id() and category == 6) then -- category 6 = Job Ability
        player:update_current_spells()
    end
end)

-- EVERY VANA'DIEL MINUTE
windower.register_event('time change', function(actor_id, category)
    if (not xivcrossbar.ready) then return end
    player:update_current_spells()
end)

-- ON MP CHANGE
windower.register_event('mp change', function(new, old)
    if (not xivcrossbar.ready) then return end
    player.vitals.mp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON TP CHANGE
windower.register_event('tp change', function(new, old)
    if (not xivcrossbar.ready) then return end
    player.vitals.tp = new
    ui:check_vitals(player.hotbar, player.vitals, player.hotbar_settings.active_environment)
end)

-- ON STATUS CHANGE
windower.register_event('status change', function(new_status_id)
    if (not xivcrossbar.ready) then return end
    -- hide/show bar in cutscenes
    if xivcrossbar.hide_hotbars == false and new_status_id == 4 then
        xivcrossbar.hide_hotbars = true
        ui:hide()
    elseif xivcrossbar.hide_hotbars and new_status_id ~= 4 then
        xivcrossbar.hide_hotbars = false
        ui:show(player.hotbar, player.hotbar_settings.active_environment)
    end

    -- Disabling this for now, but we might want it later
    -- -- alternate environment on battle
    if xivcrossbar.in_battle == false and (new_status_id == 1 or new_status_id == 3) then
        xivcrossbar.in_battle = true
        player:set_is_in_battle(true)
    --     set_battle_environment(true)
    elseif xivcrossbar.in_battle and new_status_id ~= 1 and new_status_id ~= 3 then
        xivcrossbar.in_battle = false
        player:set_is_in_battle(false)
    --     set_battle_environment(false)
    end

    -- Auto-attack swing timer: show bar only while engaged.
    aa_set_engaged(new_status_id == 1 or new_status_id == 3)
end)

-- Auto-attack swing timer: pause/unpause when disabling debuffs come and go.
-- Buff IDs: 2=Sleep, 6=Petrification, 10=Stun, 17=Terror, 19=Sleep II, 28=Charm.
local AA_PAUSING_BUFFS = {
    [2]  = 'sleep',
    [6]  = 'petrify',
    [10] = 'stun',
    [17] = 'terror',
    [19] = 'sleep2',
    [28] = 'charm',
}

windower.register_event('gain buff', function(buff_id)
    local src = AA_PAUSING_BUFFS[buff_id]
    if (src ~= nil) then
        aa_add_pause_source(src)
    end
end)

windower.register_event('lose buff', function(buff_id)
    local src = AA_PAUSING_BUFFS[buff_id]
    if (src ~= nil) then
        aa_remove_pause_source(src)
    end
end)

-- ON JOB CHANGE
windower.register_event('job change',function(main_job, main_job_level, sub_job, sub_job_level)
    -- skillchains has its own internal state and is fine pre-init, so it
    -- runs unconditionally. Everything below it depends on initialize().
    skillchains.job_change(main_job, main_job_level)
    if (not xivcrossbar.ready) then return end
    player:update_jobs(resources.jobs[main_job].ens, resources.jobs[sub_job].ens)
    local default_active_environment = env_chooser:get_default_active_environment(player.hotbar)
    player:set_active_environment(default_active_environment)
    reload_hotbar()
end)

local CATEGORY_MELEE = 1
local CATEGORY_WEAPONSKILL = 3
local CATEGORY_COMPLETED_SPELL = 4
local CATEGORY_JOB_ABILITY = 6
local SUMMONING_MAGIC = 38
local RELEASE = 90
local LIGHT_ARTS = 211
local DARK_ARTS = 212
local ADDENDUM_WHITE = 234
local ADDENDUM_BLACK = 235

local no_pet_environment = nil

windower.register_event('action', function(act)
    if (not xivcrossbar.ready) then return end
    -- Don't swap crossbars when someone *else* summons or uses Light/Dark Arts
    local windower_player = windower.ffxi.get_player()
    if (act.actor_id ~= windower_player.id) then
        return
    end

    if (act.category == CATEGORY_MELEE and act.actor_id == player.id) then
        aa_record_swing()
    end

    if (act.category == CATEGORY_WEAPONSKILL and act.actor_id == player.id) then
        aa_add_pause_source('ws')
        aa_clear_pause_after('ws', 2.0)
    end
    if (act.category == CATEGORY_JOB_ABILITY and act.actor_id == player.id) then
        aa_add_pause_source('ja')
        aa_clear_pause_after('ja', 2.0)
    end

    if (act.category == CATEGORY_JOB_ABILITY and act.actor_id == player.id) then
        gcd_start_time = os.clock()
        gcd_duration = 2.0
        gcd_kind = 'ja'
        gcd_active = true
    end

    if (act.category == CATEGORY_COMPLETED_SPELL) then
        local spell = resources.spells[act.param]
        if act.actor_id == player.id then
            gcd_start_time = os.clock()
            gcd_duration = theme_options.spell_lockout_duration or 3.0
            gcd_kind = 'spell'
            gcd_active = true
        end
        if (spell ~= nil and spell.skill == SUMMONING_MAGIC and is_valid_environment(spell.en:gsub(' ', ''):lower())) then
            no_pet_environment = player.hotbar_settings.active_environment
            set_active_environment(spell.en:gsub(' ', ''):lower())
        end
    elseif (act.category == CATEGORY_WEAPONSKILL) then
        if act.actor_id == player.id then
            gcd_start_time = os.clock()
            gcd_duration = 2.0
            gcd_kind = 'ws'
            gcd_active = true
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == RELEASE) then
        if (no_pet_environment ~= nil and is_valid_environment(no_pet_environment)) then
            set_active_environment(no_pet_environment)
            no_pet_environment = nil
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == LIGHT_ARTS) then
        if (is_valid_environment('lightarts')) then
            set_active_environment('lightarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == DARK_ARTS) then
        if (is_valid_environment('darkarts')) then
            set_active_environment('darkarts')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_WHITE) then
        if (is_valid_environment('addendumwhite')) then
            set_active_environment('addendumwhite')
        end
    elseif (act.category == CATEGORY_JOB_ABILITY and act.param == ADDENDUM_BLACK) then
        if (is_valid_environment('addendumblack')) then
            set_active_environment('addendumblack')
        end
    end
end)

windower.register_event('incoming chunk', function(id, data)
    skillchains.incoming_chunk(id, data)
end)

windower.register_event('zone change', function()
    skillchains.zone_change()
end)
