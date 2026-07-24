local storage = {}

storage.filename = ''
storage.directory = ''
storage.file = nil

-- slot-name translation for XML files.
-- In-memory slots stay as slot_1..slot_9; on disk we use readable names that
-- describe the physical button: l/r = left-half (d-pad) / right-half (face),
-- followed by the direction/position letter.
local slot_int_to_name = {
    [1] = 'll', [2] = 'ld', [3] = 'lr', [4] = 'lu',
    [5] = 'rl', [6] = 'rd', [7] = 'rr', [8] = 'ru',
    [9] = 'zz', -- phantom slot used to keep empty hotbars serializable; sorted to the end
}

-- hotbar-name translation for XML files.
-- In-memory hotbars stay as hotbar_1..hotbar_6; on disk the name spells the
-- trigger sequence that activates the hotbar (L=left-trigger, R=right-trigger).
local hotbar_int_to_name = {
    [1] = 'l',  -- L only
    [2] = 'r',  -- R only
    [3] = 'rl', -- R then L
    [4] = 'lr', -- L then R
    [5] = 'll', -- L double-tap
    [6] = 'rr', -- R double-tap
}

-- return a shallow-copied environment table with hotbar and slot keys renamed for XML
local function translate_hotbar_for_write(env_table)
    local out = {}
    for key, value in pairs(env_table) do
        if type(value) == 'table' and key:sub(1, 7) == 'hotbar_' then
            local translated_hotbar = {}
            for slot_key, slot_val in pairs(value) do
                local num_str = slot_key:match('^slot_(%d+)$')
                local new_name = num_str and slot_int_to_name[tonumber(num_str)]
                if new_name then
                    translated_hotbar['slot_' .. new_name] = slot_val
                else
                    translated_hotbar[slot_key] = slot_val
                end
            end

            local hb_num_str = key:match('^hotbar_(%d+)$')
            local new_hotbar_name = hb_num_str and hotbar_int_to_name[tonumber(hb_num_str)]
            if new_hotbar_name then
                out['hotbar_' .. new_hotbar_name] = translated_hotbar
            else
                out[key] = translated_hotbar
            end
        else
            out[key] = value
        end
    end
    return out
end

-- setup storage for current player
function storage:setup(player)
    local sub_job = player.sub_job
    if (sub_job == nil) then
        sub_job = 'NOSUB'
    end
    self.filename = player.main_job .. '-' .. sub_job
    self.directory = player.server .. '/' .. player.name

    self.file = file.new('data/hotbar/' .. self.directory .. '/' .. self.filename .. '.xml')
    self.job_default_file = file.new('data/hotbar/' .. self.directory .. '/' .. player.main_job .. '-DEFAULT.xml')
    self.all_jobs_file = file.new('data/hotbar/' .. self.directory .. '/ALL-JOBS-DEFAULT.xml')
    self.shared_file = file.new('data/hotbar/' .. self.directory .. '/Shared.xml')
    self.shared_icons_file = file.new('data/hotbar/' .. self.directory .. '/SharedIcons.xml')
    self.custom_actions_file = file.new('data/hotbar/' .. self.directory .. '/CustomActions.xml')
end

function split_hotbar(hotbar_to_split)
    -- For the "normal" hotbar file: e.g. DRG-SAM.xml
    local job_sub_hotbar = {}
    job_sub_hotbar.hotbar = {}

    -- For the "job" hotbar file: e.g. DRG-DEFAULT.xml
    local job_hotbar = {}
    job_hotbar.hotbar = {}

    -- For the "character" hotbar file: e.g. ALL-JOBS-DEFAULT.xml
    local all_jobs_hotbar = {}
    all_jobs_hotbar.hotbar = {}

    -- For the shared hotbar file: Shared.xml
    local shared_hotbar = {}
    shared_hotbar.hotbar = {}

    for environment, hb in pairs(hotbar_to_split.hotbar) do
        local translated = translate_hotbar_for_write(hb)
        if (environment == 'shared') then
            shared_hotbar.hotbar[environment] = translated
        elseif (string.sub(environment, 1, 4) == 'all-') then
            all_jobs_hotbar.hotbar[environment] = translated
        elseif (string.sub(environment, 1, 4) == 'job-') then
            job_hotbar.hotbar[environment] = translated
        else
            job_sub_hotbar.hotbar[environment] = translated
        end
    end

    return job_sub_hotbar, job_hotbar, all_jobs_hotbar, shared_hotbar
end

-- store an hotbar in a new file
function storage:store_new_hotbar(new_hotbar)
    self.file:create()

    local job_sub_hotbar, job_hotbar, all_jobs_hotbar, shared_hotbar = split_hotbar(new_hotbar)

    self.file:write(table.to_xml(job_sub_hotbar))
    self.job_default_file:write(table.to_xml(job_hotbar))
    self.all_jobs_file:write(table.to_xml(all_jobs_hotbar))
    self.shared_file:write(table.to_xml(shared_hotbar))
end

-- update filename according to jobs
function storage:update_filename(main, sub)
    self.filename = main .. '-' .. sub
    self.file = file.new('data/hotbar/' .. self.directory .. '/' .. self.filename .. '.xml')
    self.job_default_file = file.new('data/hotbar/' .. self.directory .. '/' .. main .. '-DEFAULT.xml')
    self.all_jobs_file = file.new('data/hotbar/' .. self.directory .. '/ALL-JOBS-DEFAULT.xml')
    self.shared_file = file.new('data/hotbar/' .. self.directory .. '/Shared.xml')
    self.shared_icons_file = file.new('data/hotbar/' .. self.directory .. '/SharedIcons.xml')
    self.custom_actions_file = file.new('data/hotbar/' .. self.directory .. '/CustomActions.xml')
end

-- update file with hotbar
function storage:save_hotbar(new_hotbar)
    if not self.file:exists() then
        error('Hotbar file could not be found!')
        return
    end

    local job_sub_hotbar, job_hotbar, all_jobs_hotbar, shared_hotbar = split_hotbar(new_hotbar)

    self.file:write(table.to_xml(job_sub_hotbar))
    self.job_default_file:write(table.to_xml(job_hotbar))
    self.all_jobs_file:write(table.to_xml(all_jobs_hotbar))
    self.shared_file:write(table.to_xml(shared_hotbar))
end

return storage