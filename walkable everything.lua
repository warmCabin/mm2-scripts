
local excludeIds = {
    0x12, -- Moving platform
    0x3E, -- Cloud platform
}

local function makePlatform(slot)
    local flags = memory.readbyte(0x0430 + slot)
    -- Bit 7 == Sprite is active
    if bit.band(flags, 0x80) == 0 then
        -- Moving platform data isn't zeroed out by the sprite init routine.
        memory.writebyte(0x0160 + slot, 0)
        return false
    end
    
    -- Bit 0 == Collides with Mega Man
    if bit.band(flags, 1) == 0 then return false end
    
    -- Exclude certain enemies from this silliness, namely sprites that are already platforms.
    local id = memory.readbyte(0x0410 + slot)
    for _, v in ipairs(excludeIds) do
        if v == id then return false end
    end
    
    -- Generate platform hitboxes based on sprite hitboxes.
    local x = memory.readbyte(0x0470 + slot)
    local y = memory.readbyte(0x04B0 + slot)
    
    local tmp = memory.readbyte(0x06F0 + slot)
    local hitSizeX = math.max(0, memory.readbyte(0xD501 + tmp) - 4)
    local hitSizeY = math.max(0, memory.readbyte(0xD5A1 + tmp) - 4)
    
    memory.writebyte(0x0160 + slot, hitSizeX + 6) -- Platform width
    memory.writebyte(0x0170 + slot, y - hitSizeY) -- Platform Y
    
    -- gui.box(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY)
     
    return true
end

local function main()
    for i = 0, 0xF do
        makePlatform(i)
    end
    makePlatform(-15) -- This is the boss's slot, but the moving platform physics code only checks from 0 to F.
end
emu.registerafter(main)
