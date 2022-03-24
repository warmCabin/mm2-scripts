--[[
  My attempt at making a canonical zip detector. A lot of ladder tech which we traditionally don't consider a zip gets picked up
  by this check, and I am NOT about to go and outlaw all the fun. So this needs some refinement.

  Let's define a zip as:
    When you are inside a block and you get pushed out by 16 pixels.
    There are a surprising number of borderline cases that don't meet this definition but still feel kinda cheesy.
    Plus the ladder stuff which DOES meet this definition but DOESN'T feel cheesy.
]]

local prev = {}
local cur = {
    x = memory.readbyte(0x0460),
    xSub = memory.readbyte(0x0480),
    y = memory.readbyte(0x04A0),
    ySub = memory.readbyte(0x04C0),
    screen = memory.readbyte(0x0440)
    -- gotta grab outofscreen flag
}

local function formatVelocity(v)
    return string.format("%02X.%02X", math.floor(v / 256), v % 256)
end

local function validState()
    local gameState = memory.readbyte(0x01FE)
    local animIndex = memory.readbyte(0x0400)
    
    return gameState ~= 103 and gameState ~= 247 and animIndex ~= 0x1A and gameState ~= 156 and gameState ~= 143
end

emu.registerafter(function()
    
    prev = cur
    cur = {
        x = memory.readbyte(0x0460),
        xSub = memory.readbyte(0x0480),
        y = memory.readbyte(0x04A0),
        ySub = memory.readbyte(0x04C0),
        screen = memory.readbyte(0x0440)
    }
    
    local deFactoX = math.abs((cur.screen * 65536 + cur.x * 256 + cur.xSub) - (prev.screen * 65536 + prev.x * 256 + prev.xSub))
    local deFactoY = math.abs((cur.y * 256 + cur.ySub) - (prev.y * 256 + prev.ySub))
    
    gui.text(10, 10, "de facto speed")
    gui.text(10, 20, "x: "..formatVelocity(deFactoX))
    gui.text(10, 30, "y: "..formatVelocity(deFactoY))
    
    if validState() then 
        if math.floor(deFactoX / 256) >= 16 then
            print(emu.framecount().." THAT'S A HORIZONTAL ZIP!")
        end
    
        if math.floor(deFactoY / 256) >= 16 then
            print(emu.framecount().." THAT'S A VERTICAL ZIP!")
        end
    end
end)
