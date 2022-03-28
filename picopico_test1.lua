--[[
    My first attempt at the Picopico override. It's a naive approach that creates one tile override per visible tile.
    There is only room for 16 sprite overrides before your start overwriting the sfx queue, so this does not work at all.
]]

local numSolidSprites = 0

local nextSlot = 0

-- D - F are used by the picpopicos themselves (1D - 1F in actual sprite number space).
-- Sprite slot 0 = Rockman, 1 = boss, 2 - 6 = projectiles. 7 - F are surely safe, maybe even 1. But those would be -16, and X is unsigned I think :/
local slots = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0xF0, 0xF1, 0xF2, 0x12}
local xPos  = {0x20, 0xD0, 0x20, 0xD0, 0x20, 0xD0, 0x50, 0x60, 0xB0, 0xA0, 0x20, 0xD0, 0x20, 0xD0, 0xA0, 0x90, 0x30, 0x40, 0x20, 0xD0, 0x60, 0x50, 0xC0, 0xB0, 0x20, 0xD0, 0x40, 0x30}
local yPos  = {0x50, 0x50, 0x80, 0x80, 0xB0, 0xB0, 0x20, 0xC0, 0x20, 0xC0, 0x70, 0x70, 0x30, 0x30, 0X20, 0xC0, 0x20, 0xC0, 0xA0, 0xA0, 0x20, 0xC0, 0x20, 0xC0, 0x90, 0x90, 0x20, 0xC0}

-- Realistically, we can ignore anything above Y = $60. Yes, you can bonk your head on some things with Item 1, but it saves 10 object slots
-- and doesn't affect the actual challenge at all.
-- But the logic becomes a bit more tricky. The data would have to look like: numSlots, [slot, x, y]+

--[[
    Good slots:
      F0
      F1
      F2 - 
      F3 - death and crash!
      F4 - death and crash!
      F5 - death and crash!
      F6 - death and crash!
      F7 - death and crash!
      F8 - death and crash!
      FA - death and crash!
      FB - death and crash!
      FC - death and crash!
      FD - death and crash!
      FE - death and crash!
      
      Actually, all of these might be good. I was overflowing the collision override buffer into the sfx queue (and possible other important variables)
      when I tested these.
      
      0D - prolonged weirdo explosion
      0E - " "
      0F - " "
      10 - funny restart
      11 - " " (weirdly)
      12 - death and crash!
      
]]

local function mouseCheck()
    memory.writebyte(0x4B, 1)
    local inp = input.get()
    gui.text(10, 10, string.format("%02X, %02X", inp.xmouse, inp.ymouse))
    computeBlockMask(inp.xmouse, inp.ymouse)
end
gui.register(mouseCheck)

function computeBlockMask(x, y)
    gui.text(10, 20, string.format("0xF0, 0xF0, %02X, %02X", bit.band(x, 0xF0), bit.band(y, 0xF0)))
end

local function writeSolidSprite(arg)
    
end

local function createOverrides()

    local bossHealth = memory.readbyte(0x06C1)
    numSolidSprites = math.min((28 - bossHealth) + 2, 28)
    
    local color = "white"
    if numSolidSprites > 16 then
        numSolidSprites = 16
        color = "red"
    end
    
    gui.text(10, 30, numSolidSprites, color)
    memory.writebyte(0x55, numSolidSprites) -- Theoretically we need to wait until the thing spawns.
    
    gui.text(10, 40, string.format("%02X %02X", slots[numSolidSprites - 1], slots[numSolidSprites]))

    -- While the sprite slots have room for 32 things, the array at 0x56 has room for only 16 before we start bumping into sfx data.
    -- We need to either move this into a place with 28 free bytes (making sure any code that writes to this buffer is updated),
    -- or cram these overrides into 16 object slots.
    
    -- If we optimize to do full rows and ignore those above Y - $60, we can cram it into 12 :)
    -- If I was working with the designers in '88 and we planned to ship this feature, we could possibly have made the dudes always spawn from opposite ends.
    
    -- Another idea: Each override command writes to specific addresses, allowing us to merge existing overrides.
    for i = 0, numSolidSprites - 1 do
        local slot = slots[i + 1]
        local x = xPos[i + 1]
        local xMask = 0xF0
        local y = yPos[i + 1]
        local yMask = 0xF0
        local tileType = 0 -- air
        
        memory.writebyte(0x56 + i, slot) -- i would be 28 at most, so no wraparound.
        memory.writebyte(0x0610 + slot, xMask) -- need to verify that the 6502 doesn't wrap around on these big boy addresses.
        memory.writebyte(0x0650 + slot, x)
        memory.writebyte(0x0630 + slot, yMask)
        memory.writebyte(0x0670 + slot, y)
        memory.writebyte(0x04F0 + slot, tileType)
    end
end

-- This is right when the bg_collision_check routine is called.
-- The actual mod code would set all this up during the sprite update logic.
memory.registerexec(0xCB9F, createOverrides)

local prevJoy = {}

local function main()
    local joy = joypad.get(1)
    if joy.select then
        if joy.up and not prevJoy.up then
            nextSlot = nextSlot + 1
        elseif joy.down and not prevJoy.down then
            nextSlot = nextSlot - 1
        end
    end
    prevJoy = joy
    slots[#slots] = nextSlot
    gui.text(10, 50, string.format("nextSlot: %02X", nextSlot))
end
emu.registerafter(main)
