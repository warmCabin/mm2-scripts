local SOLID_SPRITE_TYPE_ADDRESS = 0x04FB
local solidSpriteType = 0

local prevSelect = false
local shouldForceTileType = true

print(rom.getfilename())

local charMap = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'}

local function toString(num, base, length)
    
    base = base or 10
    
    if not num or base < 2 or base > 16 then return end
    
    if num == 0 then return ("0"):rep(length) end
    
    if num < 0 then return "-"..toString(-num, base, length) end
    
    local ret = ""

    while num > 0 do
        ret = charMap[num % base + 1]..ret
        num = math.floor(num / base)
    end
    
    if length then ret = (("0"):rep(length - #ret))..ret end
    
    return ret
end

local function forceTileType()
    if joypad.get(1).select then
        if not prevSelect then
            solidSpriteType = solidSpriteType + 1
            prevSelect = true
        end
    else
        prevSelect = false
    end
    
    --memory.writebyte(SOLID_SPRITE_TYPE_ADDRESS, solidSpriteType)
    gui.text(10, 10, string.format("%02X", solidSpriteType))
    --gui.text(10, 20, string.format("%02X", memory.readbyte(0x40)))
    --gui.text(10, 30, string.format("%02X", memory.readbyte(0x37)))
end

local function main()
    local numSolidSprites = memory.readbyte(0x55)
    for i = 0, numSolidSprites - 1 do
        local slot = memory.readbyte(0x56 + i)
        local xMask = memory.readbyte(0x0610 + slot)
        local xPos = memory.readbyte(0x0650 + slot)
        local yMask = memory.readbyte(0x0630 + slot)
        local yPos = memory.readbyte(0x0670 + slot)
        local tileType = memory.readbyte(0x04F0 + slot)
        gui.text(10, i * 10 + 10, string.format("[%02X] %02X:%02X, %02X:%02X - %02X", slot, xMask, xPos, yMask, yPos, tileType))
    end
end
emu.registerafter(main)
