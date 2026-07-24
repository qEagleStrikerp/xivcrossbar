local action_manager = {}

local CUSTOM_TYPE = 'ct'

-- build action
function action_manager:build(type, action, target, alias, icon, equip_slot, warmup, cooldown, usable, linked_action, linked_type)
    local new_action = {}

    new_action.type = type
    new_action.action = action

    if target ~= nil then
        new_action.target = target
    end

    if alias == nil then alias = action end
    new_action.alias = alias

    if icon ~= nil then
        new_action.icon = icon
    end

    if equip_slot ~= nil then
        new_action.equip_slot = equip_slot
    end

    if warmup ~= nil then
        new_action.warmup = warmup
    end

    if cooldown ~= nil then
        new_action.cooldown = cooldown
    end

    if usable ~= nil then
        new_action.usable = usable
    end

    -- linked_action / linked_type let an action (typically type='ex', like a
    -- gear-swap command) borrow metadata from a different spell/ability/WS
    -- for MP cost, recast timer, element indicator, etc. The action's own
    -- type/action decide what FIRES; linked_* decide what metadata is DISPLAYED.
    if linked_action ~= nil then
        new_action.linked_action = linked_action
    end

    if linked_type ~= nil then
        new_action.linked_type = linked_type
    end

    return new_action
end

-- build a custom action
function action_manager:build_custom(action, alias, icon, equip_slot, warmup, cooldown, usable)
    return self:build(CUSTOM_TYPE, action, nil, alias, icon, equip_slot, warmup, cooldown, usable)
end

return action_manager