--[[
    Helps you practice the Buster-only zip on Crash screen 1.
    
    When you jump onto the ladder from the side, your Y subpixel are more or less random, since it's based on when you jumped
    and how high. Subpixels reset when you stand on the floor, so it's possible to climb to the top of the ladder and get consistent
    subpixels. Are any of those viable?

    113, 114, 121, 122, 129, 130: can zip, but don't get far enough. If you pause on the pipe screen, it kills the zip.
    136: My original discovery. Highest pixel I can find. If you do it from the top, it's not a reliable window.
      Your subpixel might be too low so it's effectively frame perfect.
    143, 144: The fastest one. high 143, low 144. Like extremely low 144. Just do 143.
      If you jump from below, since subpixels are more or less random, you might still get a bad 143.XXX subpixel, but it's your best bet.
      If you do climb from the top, you get a solid 143.5, which is viable and the only 143 subpixel you'll get.
      Depending on how long you spend inching into place, it might be a good way to do it.
]]

-- TODO: hex is default.
-- TODO: Training mode et al. is a cyclic parameter that toggles when you press select (freee, nofreeze, training)

require "mm2_fullmap"
gui.register() -- Unregister the callback that mm2_fullmap registered...

local hex = arg == "--hex"
local trainingMode = false -- only show the indicator after you let go
local showPixel90 = true -- Show indicator for a less commonly used, but adjacent pixel to the standard setup

local prevJoy = {}
local prevInp = {}
local boxColor = "red"
local boolean doFreeze = true -- wait, wtf is this "local boolean" shit
local showMap = true
local mode = 0
local modeName = "Freeze"

local SFX_QUEUE_ADDR = 0x0580
local SFX_QUEUE_LEN_ADDR = 0x66

local function addSfxToQueue(sfx)
    local queueLen = memory.readbyte(SFX_QUEUE_LEN_ADDR)
    memory.writebyte(SFX_QUEUE_ADDR + queueLen, sfx)
    memory.writebyte(SFX_QUEUE_LEN_ADDR, queueLen + 1)
end

local function handleMode()
    if mode == 0 then
        doFreeze = true
        trainingMode = false
        modeName = "Freeze"
    elseif mode == 1 then
        doFreeze = false
        trainingMode = false
        modeName = "Nofreeze"
    elseif mode == 2 then
        doFreeze = false
        trainingMode = true
        modeName = "Training"
    end
end

handleMode()

local function main()
    
    local xPix = memory.readbyte(0x0460)
    local xSub = memory.readbyte(0x0480)
    local yPix = memory.readbyte(0x04A0)
    local ySub = memory.readbyte(0x04C0)
    local stageNum = memory.readbyte(0x2A)
    local screenNum = memory.readbyte(0x0440)
    local weapon = memory.readbyte(0xA9)
    local action = memory.readbyte(0x2C)
    local drawScreen = memory.readbyte(0x20)
    local joy = joypad.get(1)
    local inp = input.get()
    
    local textColor = "white"
    
    if joy.select and not prevJoy.select then
        mode = (mode + 1) % 3
        handleMode()
        -- addSfxToQueue(0x28)
        -- addSfxToQueue(0x2D)
        -- addSfxToQueue(0x2F)
        addSfxToQueue(0x30)
    end
    prevJoy = joy
    
    if inp.M and not prevInp.M then
        showMap = not showMap
        addSfxToQueue(0x30)
    end
    prevInp = inp
    
    -- Roughly speaking, the bottom 3/4 of pixel 8F and the top 1/4 of pixel 90 are viable.
    if yPix == 0x8F then
        if ySub >= 0x44 then
            textColor = "green"
        else
            textColor = "yellow"
        end
    elseif showPixel90 and yPix == 0x90 then
        if ySub <= 0x3F then
            textColor = "green"
        else
            textColor = "yellow"
        end
    end
    
    if not trainingMode then
        if hex then
            gui.text(10, 10, string.format("%02X.%02X, %02X.%02X", xPix, xSub, yPix, ySub), textColor)
        else
            gui.text(10, 10, string.format("%.3f, %.3f", xPix + xSub / 256, yPix + ySub / 256), textColor)
        end
    end
    
    if mode < 2 then gui.text(10, 20, modeName) end
    
    -- We are on the zip screen (Crash Man screen #1), not overzipped
    if stageNum == 7 and screenNum == 1 and drawScreen == 1 then
        -- Freeze game if configured
        if doFreeze then
            memory.writebyte(0xAA, 1)
        else
            memory.writebyte(0xAA, 0)
        end
        
        if action == 9 or action == 10 then
            boxColor = textColor
            if boxColor == "white" then boxColor = "red" end
            if not trainingMode then drawIndicator(xPix, yPix, boxColor) end
        else
            drawIndicator(xPix, yPix, boxColor)
        end
    else
        memory.writebyte(0xAA, 0)
    end
    
    
    
end

emu.registerafter(main)

gui.register(function()

    if not showMap then return end

    local stageNum = memory.readbyte(0x2A)
    local screenNum = memory.readbyte(0x0440)
    local drawScreen = memory.readbyte(0x20)
    local xScroll = memory.readbyte(0x1F)
    local mmx = memory.readbyte(0x0460)
    
    -- Only draw the map during overzip scenarios so as not to distract you.
    local cameraWorldX = drawScreen * 256 + xScroll
    local megaWorldX = screenNum * 256 + mmx -- I don't know what Mega World X is, but I want to go!
    
    -- gui.text(20, 50, string.format("%02X, %02X", drawScreen, screenNum))
    -- gui.text(20, 50, string.format("drawScreen=%02X, mmscreen=%02X, %02X, %02X", drawScreen, screenNum, cameraWorldX, megaWorldX))
    -- gui.text(20, 50, megaWorldX - cameraWorldX)

    if megaWorldX - cameraWorldX >= 256 then
        minimap() -- from mm2_fullmap
    end

end)


function drawIndicator(xPix, yPix, color)
    gui.box(xPix - 3, yPix - 23, xPix + 3, yPix - 17, color, "black")
    -- gui.box(xPix - 3, yPix + 26, xPix + 3, yPix + 20, boxDrawColor, "black")
end

print("== Controls ==")
print("Select: Cycle training mode")
print("M: Toggle overzip map")
