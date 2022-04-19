local count = 0

local hit = false

local function onCollisionCheck()
    -- Get parameters passed to routine
    local xPixel = memory.readbyte(0x8)
    local screenNum = memory.readbyte(0x9)
    local yPixel = memory.readbyte(0xA)
    local offscreen = memory.readbytesigned(0xB)
    
    -- Some logic if the target point is offscreen
    if offscreen < 0 then yPixel = 0 end
    if offscreen > 0 then return end
    
    local cameraPos = memory.readbyte(0x20) * 256 + memory.readbyte(0x1F)
    local drawX = screenNum * 256 + xPixel - cameraPos
    
    gui.box(drawX - 1, yPixel - 1, drawX + 1, yPixel + 1, "magenta")
    gui.pixel(drawX, yPixel, "blue")
end

-- This is the main entry point for the bg_collision_check routine.
memory.registerexec(0xCB9F, function()
    count = count + 1
    hit = true
    onCollisionCheck()
end)

-- 0xCBC0 is just after solid sprite overrides. Many places use this.
-- 0xCBBF is the RTS instruction for when an override is found.
memory.registerexec(0xCBBF, 2, function()
    if not hit then count = count + 1 end
    hit = false
    onCollisionCheck()
end)

emu.registerafter(function()
    gui.text(240, 220, count)
    count = 0
end)
