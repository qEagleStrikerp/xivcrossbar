global interface TTable<T>
    --[[
    clear
    contains
    copy
    count
    empty
    equals
    extract
    length
    reassign
    ]]
end

global interface IndexedTTable<T> is TTable<T>
    --[[
    chunks
    concat
    extend
    first
    flatten
    last
    reverse
    sconcat
    slice
    splice
    sort
    unpack
    ]]
end

global interface KeyedTTable<K, V> is TTable<V>
    --[[
    amend
    containskey
    keyfind
    keyset
    rekey
    update
    ]]
end

global record Table<K, V> is KeyedTTable<K, V>
    find: function(self: Table<K, V>, V | function(el: V): boolean): K, V
    
    --[[
    find -> K, V
    ]]
end

-- The T{} function is only useful for wrapping Maps. If you want to pass an array instead,
-- use either List<T> or Set<T> by calling L{} or S{}, respectively.
global T: function<K, V>(t: {K:V}): Table<K, V>