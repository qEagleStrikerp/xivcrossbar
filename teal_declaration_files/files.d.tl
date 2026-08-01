local record FileHandle
    -- Check if file exists. 
    exists: function(self: FileHandle): boolean

    -- Read from file and return string of the contents, and optionally an error message if the read failed.
    read: function(self: FileHandle): string, string
    
    -- Write to file. Overwrites everything within the file, if present.
    -- Returns a new FileHandle, and optionally an error message if the write failed.
    write: function(self: FileHandle, content: string, flush: boolean): FileHandle, string
end

local record Files    
    -- Create a new file object.
    new: function(path: string, create?: boolean): FileHandle
end

return Files