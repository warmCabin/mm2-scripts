
--[[
    A testing script I made to workshop a zip setup with cyghfer. This is a funny story:
    He kept failing the bottom zip in Metal maybe 50% of the time despite using the same setup as coolkid.
    Most of us just made god gamer jokes, but this shit was too consistent, so he convinced me to take a look.
    Turns out that by placing Item 1s in a particular way at the beginning of the stage, and skipping the conveyor zip,
    CK got perfect subpixels for bottom zip every time. God gamer indeed! Meanwhile, cyghfer got the perfect subpixels
    but clobbered them by doing conveyor zip, proving that conveyor zip is indeed cursed. But he wanted to have his cake
    and eat it too, so on a livestream we came up with a couple setups whereby he could waste Item 1 and manipulate a good value.
    We evenutally settled on a viable one. That stream is lost to time, but you can probably see the setup in a cyghfer VOD somewhere.
    
    In particular, if an Item 1 ascends and poofs on the ceiling, it will have a top-quarter subpixel, which is perfect for the zip.
    This doesn't work if if its timer runs out and it poofs in the air. Only a ceiling poof will do.
    
    This script simply draws sprite slot numbers over your projectiles, but they're the "item1height" numbers instead of the
    actual indexes in memory. #1, #2, and #3 is a bit easier to keep track of then #4, #3, and #2, don't you think?
    It even draws a smiley face when you have a good subpixel for the zip!
]]

-- draw coordinate computation logic by finalfighter
local function drawSpriteInfo()
	local scX = memory.readbyte(0x20)*256+memory.readbyte(0x1F)
	local scY = 0

	for i = 2, 8 do
		local x = memory.readbyte(0x0440+i)*256+memory.readbyte(0x0460+i) - scX
		local y = memory.readbyte(0x04A0+i)                               - scY
		local flags = memory.readbyte(0x0420+i)
        
		if flags>=0x80 then -- sprite is alive
            gui.text(x - 2, y - 2, 5 - i, "white", "black") -- slots 2, 3, 4? 5 - i		
		end
	end
end

local function postFrame()
	
	drawSpriteInfo()
    
    local theSubpixel = memory.readbyte(0x04C3)
    -- drawText(5, 15, "the subpixel: "..theSubpixel)
    if (theSubpixel > 128) then
        gui.text(5, 15, ":)")
    else
        gui.text(5, 15, ":(")
    end
	
end
emu.registerafter(postFrame)
