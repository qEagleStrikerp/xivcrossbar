local type WindowerEvent = require("windower_events")
local type WindowerPlayer = require("windower_player")

global type Function = function(any...): any...

global record windower  
    -- str: Command to send. This function is used to send a command to Windower.
    -- This command is treated as if it were entered into the windower console, so no // prefix is necessary.
    send_command: function(str: string)

    -- event: string - Event name
    -- fn: function - Function to execute whenever the event is triggered
    -- Registers a function to execute whenever an event triggers.
    -- Returns the IDs of registered functions, which can be used to unregister them again (see unregister_event).
    register_event: function(event: WindowerEvent, fn: Function): {integer}

    -- Returns true if str matches pattern.
    -- str - Input string to match
    -- pattern - Pattern to match against
    -- Allowed tokens:
    -- ? matches any one character
    -- * matches arbitrary many characters
    -- | alternation, matches either the left of it or the right of it
    wc_match: function(str: string, pattern: string): boolean

    record ffxi
        -- Returns a list of IDs of all available key_items.
        get_key_items: function(): {integer}

        -- Returns a table containing player info.
        get_player: function(): WindowerPlayer
    end
end