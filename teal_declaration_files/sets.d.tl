require("tables")

global record Set<T> is TTable<T>
    add: function(self: Set<T>, el: T): Set<T>
    find: function(self: Set<T>, T | function(el: T): boolean): T
    
    --[[
    add
    clear
    diff
    filter
    flat
    format
    intersection
    it
    map
    remove
    sdiff
    sort -> List<T>
    ssubset
    subset
    tostring
    tovstring
    union
    ]]
end

-- Due to technical limitations, Teal currently cannot accept "t: {T} | List<T>" as a parameter type.
-- If you want to pass a List<T> into S(), use a typecast: S(list as {T})
global S: function<T>(t: {T}): Set<T>