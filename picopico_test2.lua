--[[
    Working version of the Picopico override.
    This version writes solid sprite data directly without actually spawning any sprites, which is not the correct
    way to use the system.
    
    Depending on your spot in the picopico spawning framerule, the blocks might take up sprite slots 1D - 1F.
    That means we have 13 guaranteed safe slots for overrides. So we need to have a skip-type override data,
    or a condition that changes the sprite slot to F0 if it's at least D. I confirmed that errant collisions can occur
    if you do allow the solid sprites to creep into slot 1D.
]]

-- In practice, since there is only one skipper, we could merge these values and put in dummy/duplicate data or something.
local numSolidSprites = 0
local oIndex = 0

-- Realistically, we can ignore anything above Y = $60. Yes, the ceiling remains solid, but it saves 8 object slots
-- and doesn't affect the actual challenge at all.
local overrideData = {1, 0x50, 1, 0x80, 1, 0xB0, 2, 0x60, 2, 0xA0, 1, 0x70, 0, 0, 2, 0x90, 2, 0x40, 1, 0xA0, 2, 0x50, 2, 0xB0, 1, 0x90, 2, 0x30}
                                                                        --  1, 0x30                                                                       
local debugMode = false                                                                        

local function mouseCheck()
    --memory.writebyte(0x4B, 1)
    local inp = input.get()
    if debugMode then gui.text(10, 10, string.format("%02X, %02X", inp.xmouse, inp.ymouse)) end
    computeBlockMask(inp.xmouse, inp.ymouse)
end
gui.register(mouseCheck)

function computeBlockMask(x, y)
    if debugMode then gui.text(10, 20, string.format("0xF0, 0xF0, %02X, %02X", bit.band(x, 0xF0), bit.band(y, 0xF0))) end
end

local function writeSolidSprite(arg)
    
end

local function getNextOverride()
    local oType = overrideData[oIndex * 2            + 1] -- FU Lua
    local oParam = overrideData[oIndex * 2 + 1       + 1]
    oIndex = oIndex + 1
    
    -- Type 0 == skip
    if oType == 0 then return end
    
    local xMask, xPos, yMask, yPos
    
    if oType == 1 then
        -- Row
        xMask = 0
        xPos = 0
        yMask = 0xF0
        yPos = oParam
    elseif oType == 2 then
        -- One block on the lower row. Very bespoke!
        xMask = 0xF0
        xPos = oParam
        yMask = 0xF0 -- Can be extracted from the branch to save codespace in the actual hack
        yPos = 0xC0  
    end
    
    local slot = numSolidSprites
    
    memory.writebyte(0x56 + slot, slot)
    memory.writebyte(0x0610 + slot, xMask)
    memory.writebyte(0x0650 + slot, xPos)
    memory.writebyte(0x0630 + slot, yMask)
    memory.writebyte(0x0670 + slot, yPos)
    memory.writebyte(0x04F0 + slot, 0) -- tile type
    
    numSolidSprites = numSolidSprites + 1
end

local prevBossHealth = 0
local prevSpawn = false

local function checkSpawn()
    for i = 0x1D, 0x1F do
        local flags = memory.readbyte(0x0420 + i)
        local id = memory.readbyte(0x0400 + i)
        if bit.band(flags, 0x88) == 0x88 and id == 0x6A then
            -- 80 = alive, 8 = invincible. 6A = picoblock id.
            -- The half blocks and full/assembled blocks are both id 6A in different states.
            -- We can check the invincibility flag to quickly determine which one.
            -- These guys use their timers to determine movement speed, I think.
            -- Boss timer ($B2) is used to store which block in the sequence we're on. Could be reused as oIndex.
            -- $04E1, the sprite slot 1 timer, is used to determine when to spawn the next block.
            if not prevSpawn then
                --print("One spawned!")
                prevSpawn = true
                return true
            else
                return false
            end
        end
    end
    prevSpawn = false
    return false
end

-- I'm not sure how well this God method would translate to the actual game code.
-- I suppose there must be a picopico runner routine, right?
-- I might need to spawn a bunch of dummy sprites to do the heavy lifting here.

-- Here's a totally wild alternate solution: What if we did an overzip meme? Each spawn sets everything's position to the next screen,
-- which has the collision info baked in.
local function createOverrides()

    local bossHealth = memory.readbyte(0x06C1)
    
    if bossHealth == 0 then
        oIndex = 0
        numSolidSprites = 0
    end

    if checkSpawn() then
        print("checkSpawn")
        getNextOverride()
    end
   
    if debugMode then gui.text(10, 30, numSolidSprites) end
    memory.writebyte(0x55, numSolidSprites) -- This must run every frame. The game overrides it with what it sees in the actual sprite data.
end

-- This is right when the bg_collision_check routine is called.
-- The actual mod code would set all this up during the sprite update logic.
memory.registerexec(0xCB9F, function()
    local status, err = pcall(createOverrides)
    if not status then
        print("Error! "..err)
        return
    end
end)

local prevJoy = {}

local function main()
    if bit.band(memory.readbyte(0x0420), 0x80) ~= 0x80 or memory.readbyte(0x2A) ~= 9 or memory.readbyte(0x06C1) == 0 then
        oIndex = 0
        numSolidSprites = 0
    end
end
emu.registerafter(main)
