-- TODO: This looks hard to read, put some comments in there.
local kebab_casify = function(str)
    -- TODO: This guard will need to be changed once we port to Teal
    if type(str) == "number" then
        str = tostring(str)
    elseif type(str) ~= "string" then
        return ""
    end

    return str:lower()
        :gsub('?', 'QMARK')
        :gsub('/', '\n')
        :gsub(':', '')
        :gsub("'", '')
        :gsub('-', ' ')
        :gsub('%p', '')
        :gsub(' ', '-')
        :gsub('\n', '/')
        :gsub('QMARK', '?')
end

return kebab_casify
