
--[[
    A testing script I made to workshop a zip setup with cyghfer. This is a funny story:
    He kept failing the bottom zip in Metal maybe 50% of the time despite using the same setup as coolkid.
    Most of us just made god gamer jokes, but this shit was too consistent, so he convinved me to take a look.
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

--Only interested in tracking the 4 weapon-controllable ones ($0592 - $0595).
--$0596 affects one of the Crash Bomb explosion particles, but $0596 - $059F
--pretty much stay at 0 forever. Change NUM_HITBOXES to 16 if you're curious!
local NUM_HITBOXES = 4
local EmuYFix = 0

local function drawBox(x1,y1,x2,y2,c1,c2)
	gui.box(x1, y1+EmuYFix, x2, y2+EmuYFix, c1, c2)
end

local function drawText(x,y,t,c1,c2)
	gui.text(x, y+EmuYFix, t, c1, c2 )
end

--synaesthesia for hitbox sizes. Redder = bigger.
--format: fill color, outline color
local hitSizeColors = {
{"#00FF0040","green"},
{"#0000FF40","blue"},
{"#FFEF0040","#FFEF00"},
{"#FF7F0040","#FF7F00"},
{"#FF000040","red"}
}
setmetatable(hitSizeColors, {__index=function(t,k)
	return {"#FFFFFF40", "white"} --all glitchy out-of-bounds hitboxes are drawn white.
end})

--Written by finalfighter.
--Variables renamed by me for clarity.
--I also removed the delay scroll tracking and
--HP/sprite timer stuff, and added two lines to draw the
--hitbox types at $059X. It's a lightweight hitbox function!
local function drawSpriteInfo()

	-- local weapon = memory.readbyte(0xA9)
	-- if weapon ~= 8 then return end

	local scX = memory.readbyte(0x20)*256+memory.readbyte(0x1F)
	local scY = 0

	for i=2,8 do
		local x = memory.readbyte(0x0440+i)*256+memory.readbyte(0x0460+i) - scX
		local y = memory.readbyte(0x04A0+i)                               - scY

		local flags = memory.readbyte(0x0420+i)
		if flags>=0x80 then --sprite is alive
		
			if i<0x10 and i~=1 then --Rockman & projectiles
				local propIndex = memory.readbyte(0x0590+i)           --weapon hitbox type (0-4)
				local tmp = memory.readbyte(0xD4DC+propIndex)         --offset into property tables
				local hitSizeX = memory.readbyte(0xD4E1+tmp)-0xC  + 4 --read from property tables
				local hitSizeY = memory.readbyte(0xD581+tmp)-0x14 + 4
				local bg,ol = hitSizeColors[propIndex+1][1],hitSizeColors[propIndex+1][2]
				
				-- drawBox(x-hitSizeX, y-hitSizeY, x+hitSizeX, y+hitSizeY, bg, ol)
				drawText(x - 2, y - 2, 5 - i, "white", "black") -- slots 2, 3, 4? 5 - i
			else --regular entities
				local tmp = memory.readbyte(0x06E0+i)
				local hitSizeX = math.max(0, memory.readbyte(0xD501+tmp) - 4 )
				local hitSizeY = math.max(0, memory.readbyte(0xD5A1+tmp) - 4 )
				drawBox(x-hitSizeX, y-hitSizeY, x+hitSizeX, y+hitSizeY, "#FFFFFF40", "white")
			end
			
		end
	end
end

local function postFrame()
	
	drawSpriteInfo()
    
    local theSubpixel = memory.readbyte(0x04C3)
    -- drawText(5, 15, "the subpixel: "..theSubpixel)
    if (theSubpixel > 128) then
        drawText(5, 15, ":)")
    else
        drawText(5, 15, ":(")
    end
	-- drawText(5,15,str,"white","0000FF80")
	
end
emu.registerafter(postFrame)
