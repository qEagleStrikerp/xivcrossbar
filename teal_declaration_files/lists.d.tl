require("tables")

global record List<T> is {T}, IndexedTTable<T>
    append: function(self: List<T>, el: T): List<T>
    find: function(self: List<T>, T | function(el: T): boolean): integer, T

    --[[
    filter
    flat
    format
    insert
    it
    map
    remove
    tostring
    ]]
end

-- Due to technical limitations, Teal currently cannot accept "t: {T} | Set<T>" as a parameter type.
-- If you want to pass a Set<T> into L(), use a typecast: L(set as {T})
global L: function<T>(t: {T}): List<T>