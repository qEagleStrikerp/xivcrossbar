local enum KeyItemCategory
    "Abyssea"
    "Active Effects"
    "Claim Slips"
    "Geas Fete"
    "Magical Maps"
    "Mog Garden"
    "Mounts"
    "Permanent Key Items"
    "Temporary Key Items"
    "Voidwatch"
end

local record KeyItemInformation
    id: integer
    en: string
    ja: string
    category: KeyItemCategory
end

local enum MountPrefix
    "/mount"
end

local record MountInformation
    id: integer
    en: string
    ja: string
    endesc: string
    icon_id: integer
    jadesc: string
    prefix: MountPrefix
end

local record Resources
    key_items: {integer:KeyItemInformation}
    mounts: {integer:MountInformation}
end

return Resources