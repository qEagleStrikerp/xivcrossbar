local gamepad_converter = {}

function gamepad_converter:setup(button_layout)
    self.button_layout = button_layout
end

local TRIGGERS_TO_CROSSBAR = {
    ['L'] = 1,
    ['LEFT'] = 1,
    ['LEFTTRIGGER'] = 1,
    ['R'] = 2,
    ['RIGHT'] = 2,
    ['RIGHTTRIGGER'] = 2,
    ['RL'] = 3,
    ['RIGHTLEFT'] = 3,
    ['RIGHTLEFTTRIGGER'] = 3,
    ['LR'] = 4,
    ['LEFTRIGHT'] = 4,
    ['LEFTRIGHTTRIGGER'] = 4,
    ['LL'] = 5,
    ['LEFTLEFT'] = 5,
    ['LEFTLEFTTRIGGER'] = 5,
    ['RR'] = 6,
    ['RIGHTRIGHT'] = 6,
    ['RIGHTRIGHTTRIGGER'] = 6
}

function gamepad_converter:convert_to_crossbar(triggers)
    local triggers_as_number = tonumber(triggers)
    if (triggers_as_number ~= nil) then
        return triggers_as_number
    end

    return TRIGGERS_TO_CROSSBAR[triggers:upper()]
end

local NINTENDO_BUTTON_TO_PLACEMENT = {
    ['A']               = 'CIRCLE',
    ['ABUTTON']         = 'CIRCLE',
    ['B']               = 'CROSS',
    ['BBUTTON']         = 'CROSS',
    ['X']               = 'TRIANGLE',
    ['XBUTTON']         = 'TRIANGLE',
    ['Y']               = 'SQUARE',
    ['YBUTTON']         = 'SQUARE',
    ['UP']              = 'DPADUP',
    ['UPBUTTON']        = 'DPADUP',
    ['DUP']             = 'DPADUP',
    ['DUPBUTTON']       = 'DPADUP',
    ['DPADUP']          = 'DPADUP',
    ['DPADUPBUTTON']    = 'DPADUP',
    ['DOWN']            = 'DPADDOWN',
    ['DOWNBUTTON']      = 'DPADDOWN',
    ['DDOWN']           = 'DPADDOWN',
    ['DDOWNBUTTON']     = 'DPADDOWN',
    ['DPADDOWN']        = 'DPADDOWN',
    ['DPADDOWNBUTTON']  = 'DPADDOWN',
    ['LEFT']            = 'DPADLEFT',
    ['LEFTBUTTON']      = 'DPADLEFT',
    ['DLEFT']           = 'DPADLEFT',
    ['DLEFTBUTTON']     = 'DPADLEFT',
    ['DPADLEFT']        = 'DPADLEFT',
    ['DPADLEFTBUTTON']  = 'DPADLEFT',
    ['RIGHT']           = 'DPADRIGHT',
    ['RIGHTBUTTON']     = 'DPADRIGHT',
    ['DRIGHT']          = 'DPADRIGHT',
    ['DRIGHTBUTTON']    = 'DPADRIGHT',
    ['DPADRIGHT']       = 'DPADRIGHT',
    ['DPADRIGHTBUTTON'] = 'DPADRIGHT'
}

local XBOX_BUTTON_TO_PLACEMENT = {
    ['A']               = 'CROSS',
    ['ABUTTON']         = 'CROSS',
    ['B']               = 'CIRCLE',
    ['BBUTTON']         = 'CIRCLE',
    ['X']               = 'SQUARE',
    ['XBUTTON']         = 'SQUARE',
    ['Y']               = 'TRIANGLE',
    ['YBUTTON']         = 'TRIANGLE',
    ['UP']              = 'DPADUP',
    ['UPBUTTON']        = 'DPADUP',
    ['DUP']             = 'DPADUP',
    ['DUPBUTTON']       = 'DPADUP',
    ['DPADUP']          = 'DPADUP',
    ['DPADUPBUTTON']    = 'DPADUP',
    ['DOWN']            = 'DPADDOWN',
    ['DOWNBUTTON']      = 'DPADDOWN',
    ['DDOWN']           = 'DPADDOWN',
    ['DDOWNBUTTON']     = 'DPADDOWN',
    ['DPADDOWN']        = 'DPADDOWN',
    ['DPADDOWNBUTTON']  = 'DPADDOWN',
    ['LEFT']            = 'DPADLEFT',
    ['LEFTBUTTON']      = 'DPADLEFT',
    ['DLEFT']           = 'DPADLEFT',
    ['DLEFTBUTTON']     = 'DPADLEFT',
    ['DPADLEFT']        = 'DPADLEFT',
    ['DPADLEFTBUTTON']  = 'DPADLEFT',
    ['RIGHT']           = 'DPADRIGHT',
    ['RIGHTBUTTON']     = 'DPADRIGHT',
    ['DRIGHT']          = 'DPADRIGHT',
    ['DRIGHTBUTTON']    = 'DPADRIGHT',
    ['DPADRIGHT']       = 'DPADRIGHT',
    ['DPADRIGHTBUTTON'] = 'DPADRIGHT'
}

local GAMECUBE_BUTTON_TO_PLACEMENT = {
    ['A']               = 'CROSS',
    ['ABUTTON']         = 'CROSS',
    ['B']               = 'SQUARE',
    ['BBUTTON']         = 'SQUARE',
    ['X']               = 'CIRCLE',
    ['XBUTTON']         = 'CIRCLE',
    ['Y']               = 'TRIANGLE',
    ['YBUTTON']         = 'TRIANGLE',
    ['UP']              = 'DPADUP',
    ['UPBUTTON']        = 'DPADUP',
    ['DUP']             = 'DPADUP',
    ['DUPBUTTON']       = 'DPADUP',
    ['DPADUP']          = 'DPADUP',
    ['DPADUPBUTTON']    = 'DPADUP',
    ['DOWN']            = 'DPADDOWN',
    ['DOWNBUTTON']      = 'DPADDOWN',
    ['DDOWN']           = 'DPADDOWN',
    ['DDOWNBUTTON']     = 'DPADDOWN',
    ['DPADDOWN']        = 'DPADDOWN',
    ['DPADDOWNBUTTON']  = 'DPADDOWN',
    ['LEFT']            = 'DPADLEFT',
    ['LEFTBUTTON']      = 'DPADLEFT',
    ['DLEFT']           = 'DPADLEFT',
    ['DLEFTBUTTON']     = 'DPADLEFT',
    ['DPADLEFT']        = 'DPADLEFT',
    ['DPADLEFTBUTTON']  = 'DPADLEFT',
    ['RIGHT']           = 'DPADRIGHT',
    ['RIGHTBUTTON']     = 'DPADRIGHT',
    ['DRIGHT']          = 'DPADRIGHT',
    ['DRIGHTBUTTON']    = 'DPADRIGHT',
    ['DPADRIGHT']       = 'DPADRIGHT',
    ['DPADRIGHTBUTTON'] = 'DPADRIGHT'
}

local PLAYSTATION_BUTTON_TO_PLACEMENT = {
    ['CROSS']           = 'CROSS',
    ['CROSSBUTTON']     = 'CROSS',
    ['SQUARE']          = 'SQUARE',
    ['SQUAREBUTTON']    = 'SQUARE',
    ['CIRCLE']          = 'CIRCLE',
    ['CIRCLEBUTTON']    = 'CIRCLE',
    ['TRIANGLE']        = 'TRIANGLE',
    ['TRIANGLEBUTTON']  = 'TRIANGLE',
    ['UP']              = 'DPADUP',
    ['UPBUTTON']        = 'DPADUP',
    ['DUP']             = 'DPADUP',
    ['DUPBUTTON']       = 'DPADUP',
    ['DPADUP']          = 'DPADUP',
    ['DPADUPBUTTON']    = 'DPADUP',
    ['DOWN']            = 'DPADDOWN',
    ['DOWNBUTTON']      = 'DPADDOWN',
    ['DDOWN']           = 'DPADDOWN',
    ['DDOWNBUTTON']     = 'DPADDOWN',
    ['DPADDOWN']        = 'DPADDOWN',
    ['DPADDOWNBUTTON']  = 'DPADDOWN',
    ['LEFT']            = 'DPADLEFT',
    ['LEFTBUTTON']      = 'DPADLEFT',
    ['DLEFT']           = 'DPADLEFT',
    ['DLEFTBUTTON']     = 'DPADLEFT',
    ['DPADLEFT']        = 'DPADLEFT',
    ['DPADLEFTBUTTON']  = 'DPADLEFT',
    ['RIGHT']           = 'DPADRIGHT',
    ['RIGHTBUTTON']     = 'DPADRIGHT',
    ['DRIGHT']          = 'DPADRIGHT',
    ['DRIGHTBUTTON']    = 'DPADRIGHT',
    ['DPADRIGHT']       = 'DPADRIGHT',
    ['DPADRIGHTBUTTON'] = 'DPADRIGHT'
}

local PLACEMENT_TO_SLOT = {
    ['CROSS']           = 6,
    ['SQUARE']          = 5,
    ['CIRCLE']          = 7,
    ['TRIANGLE']        = 8,
    ['DPADUP']          = 4,
    ['DPADDOWN']        = 2,
    ['DPADLEFT']        = 1,
    ['DPADRIGHT']       = 3
}

-- Friendly slot-name aliases that match the on-disk XML slot identifiers
-- (see storage.lua's slot_int_to_name). First letter = cluster (l = d-pad,
-- r = face buttons), second letter = direction within the cluster. Lets
-- chat commands like //xivcrossbar al <env> <hotbar> rr <text> work without
-- requiring the user to remember the numeric slot index.
-- 'zz' is intentionally omitted: it's a serialization placeholder for empty
-- hotbars, not a real button.
local SLOT_NAME_TO_SLOT = {
    ['LL'] = 1, ['LD'] = 2, ['LR'] = 3, ['LU'] = 4,
    ['RL'] = 5, ['RD'] = 6, ['RR'] = 7, ['RU'] = 8,
}

function gamepad_converter:convert_to_slot(button)
    local slot_as_number = tonumber(button)
    if (slot_as_number ~= nil) then
        return slot_as_number
    end

    -- Friendly slot names (ll/ld/lr/lu/rl/rd/rr/ru) take priority over the
    -- per-layout controller-button names. Both are case-insensitive.
    local slot_from_name = SLOT_NAME_TO_SLOT[button:upper()]
    if (slot_from_name ~= nil) then
        return slot_from_name
    end

    local placement = nil
    if (self.button_layout == 'gamecube') then
        placement = GAMECUBE_BUTTON_TO_PLACEMENT[button:upper()]
    elseif (self.button_layout == 'playstation') then
        placement = PLAYSTATION_BUTTON_TO_PLACEMENT[button:upper()]
    elseif (self.button_layout == 'xbox') then
        placement = XBOX_BUTTON_TO_PLACEMENT[button:upper()]
    elseif (self.button_layout == 'nintendo') then
        placement = NINTENDO_BUTTON_TO_PLACEMENT[button:upper()]
    end

    if (placement == nil) then
        print('XIVCROSSBAR: Invalid arguments: ' .. button)
        return nil
    end

    return PLACEMENT_TO_SLOT[placement]
end

return gamepad_converter
