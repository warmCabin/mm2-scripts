--[[
    Draw the solid sprite collision override data to screen.
    mm2_fullmap draws the little blue squares, but it can only understand block-aligned masks (i.e. lower nyble = 0).
    Block-aligned masks are really the intended purpose of this system, but...you can get weird with it >:)
    
    Want disappearing ice blocks? Or crash walls that kill you?
    Pass the arg --force-tile-type then hold select + up or down to force a tile type!
    
    Tile types:
      0 = air
      1 = ground
      2 = ladder
      3 = spikes
      4 = water
      5 = right conveyor belt
      6 = left conveyor belt
      7 = ice
      8 = door scroll?
      
      This system is used by:
        - Yoku blocks: override 1 tile to 1 (solid)
        - Crash wall type 1: override 2 tiles to 1 (solid).
            These are forced to be 2-block aligned.
        - Crash wall type 2: override 4 tiles to 1 (solid).
            This is done to allow odd block-aligned walls. You need to make sure there is level
            directly above and below them or it will seem strange.
        - Frienders: override 2 tiles to 1 (solid) to create the barrier
            Interestingly, it makes two 2-tilers instead of one 4-tiler.
            This frees it from being only 4-tile aligned.
        - Doors: override 2 tiles to 8 (door jank)
            I don't really understand how this works. I think it's mainly to prevent you from
            walking backwards in the subsequent room.
            
      Surprisingly, this system is NOT used by:
       - Metal Man to update his conveyor belt.
       - the Wily machine to make the floor disappear after you defeat it
          
]]

local forcedTileType = 1

local prevJoy = {}
local shouldForceTileType = arg:find("%-%-force%-tile%-type")
local shouldDrawTable = arg:find("%-%-draw%-table")

local function forceTileType()
    local joy = joypad.get(1)
    if joy.select then
        if joy.up and not prevJoy.up then
            forcedTileType = forcedTileType + 1
        elseif joy.down and not prevJoy.down then
            forcedTileType = forcedTileType - 1
        end
    end
    prevJoy = joy

    gui.text(240, 220, string.format("%02X", forcedTileType))
    
    local numSolidSprites = memory.readbyte(0x55)
    for i = 0, numSolidSprites - 1 do
        local slot = memory.readbyte(0x56 + i)
        memory.writebyte(0x04F0 + slot, forcedTileType)
    end
end

local function main()

    -- It's a simple contract.
    if shouldForceTileType then forceTileType() end

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
        gui.text(screenNum * 256 + xPos - xScroll, yPos, string.format("%02X", slot))
        if shouldDrawTable then gui.text(10, i * 10 + 10, string.format("[%02X] %02X:%02X, %02X:%02X - %02X", slot, xMask, xPos, yMask, yPos, tileType)) end
    end
end
emu.registerafter(main)
