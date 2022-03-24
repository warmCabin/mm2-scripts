--[[
    Draw the solid sprite collision override data to screen.
    mm2_fullmap draws the little blue squares, but it can only understand block-aligned masks (i.e. lower nyble = 0).
    Block-aligned masks are really the intended purpose of this system, but...you can get weird with it >:)
]]

local SOLID_SPRITE_TYPE_ADDRESS = 0x04FB
local solidSpriteType = 0

local prevSelect = false
local shouldForceTileType = true

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
    local xScroll = 256 * memory.readbyte(0x20) + memory.readbyte(0x1F)
    local numSolidSprites = memory.readbyte(0x55)
    for i = 0, numSolidSprites - 1 do
        local slot = memory.readbyte(0x56 + i)
        local xMask = memory.readbyte(0x0610 + slot)
        local xPos = memory.readbyte(0x0650 + slot)
        local yMask = memory.readbyte(0x0630 + slot)
        local yPos = memory.readbyte(0x0670 + slot)
        local tileType = memory.readbyte(0x04F0 + slot)
        local screenNum = memory.readbyte(0x0440 + slot + 16) -- Don't ask
        gui.text(10, i * 10 + 10, string.format("[%02X] %02X:%02X, %02X:%02X - %02X", slot, xMask, xPos, yMask, yPos, tileType))
        gui.text(screenNum * 256 + xPos - xScroll, yPos, string.format("%02X", slot))
    end
end
emu.registerafter(main)
