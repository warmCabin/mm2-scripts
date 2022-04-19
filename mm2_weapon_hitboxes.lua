
--[[
	This script draws hitboxes and displays a few variables to help you track the mysterious behavior
	of the "lenient Crash Bomb."
	Huge thanks to stalwarTTurtle for noticing and investigating this, and drawing everyone's curiosity
	in the Discord server!
	
	He noticed that, in the Boobeam fight, certain Crash Bomb placements were inconsistent. From one savestate,
	he could easily shoot the middle door without jumping (a lenient Crash Bomb). From another, the explosion
	simply wouldn't hit it, no matter how many bombs he shot (a strict Crash Bomb). He discovered that shooting
	Quick Boomerangs made your Crash Bombs strict, and that shooting a Leaf Shield made your Crash Bombs lenient.
	SUPER lenient, in fact; leading to placements he called "outlandish."
	Crash Bombs aren't controlled by RNG. I suggested that it might be the Item 1 or Item 3 seeds, a set of pesky
	variables that all weapons reuse without clearing. But those values have no effect on Crash Bombs whatsoever. 
	So what on Earth is going on!?
	
	Turns out I wasn't too far off the mark. There's a different set of variables we need to track, here.
	
	The variables of note are $0592 - $0595. Polari is the one who noticed they were changing.
	Thanks to finalfighter's hitbox code, I was able to determine their function.
	It turns out that, from $0590-$059F, there is a value for each sprite that I like to call
	the hitbox property index (note that these only apply to Mega Man and his projectiles; the other
	sprites function completely differently, for some reason). The hitbox property index serves as
	an index into a table, which serves as an index into ANOTHER table, which contains hitbox size
	and presumably a lot of other cool stuff that I don't understand. How finalfighter figured this out
	in the first place is beyond me...maybe he worked at Capcom in the 80's :p
	
	Sprite indexes 2-5 are reserved for projectiles. They are assigned indexes on the range
	[2,max projectiles+1], from highest to lowest. Leaf Shield and Quick Boomerang are the only
	weapons capable of altering index 5.
	
	The property index in $0592 - $0595 is set whenever a weapon is fired. The value is on
	the range [0,4]. 1 is smallest, 4 is biggest, 0 corresponds to Mega Man's hitbox size.
	Item 3 is the exception. It improperly uses $0592 as a timer of some sort when it reaches the top
	of a wall, which causes the hitbox code to read data out of bounds and produce essentially random
	hitboxes. Item collisions seem to be handled indepently of these hitbox values, though, so this bug
	does not manifest in gameplay in any way.
	
	Crash Bombs (the actual projectiles that stick to walls) have a property index of 2,
	which is set as expected. But the explosion particles are a different story. They read from $0593 - $0596
	for their hitbox sizes, but they DO NOT WRITE to this range! This means they use whatever hitbox
	sizes happened to already be there! This bug is the root cause of the lenient Crash Bomb.
	Unfortunately, Item 3 cannot be abused to make massive Crash Bomb hitboxes, since the erroneous timer
	value is always overwritten by 2 :/
	
	Crash Bomb explosions consist of 5 particles. The first remains in place at the exact location where
	the bomb exploded; the other 4 move around in a preset pattern. The stationary particle will always
	have a hitbox size of 2, so it seems like the other 4 are fair game for manipulation! However, that's not
	quite the case. Since there are 5 particles at play here, one of them is going to use $5096. $5096 is
	initialized to 0 when the game boots, and afaik, cannot be altered in any way. Bummer :(
	
	As stalwarTTurtle showed, we can still see some meaningful differences with the 3 hitboxes we CAN manipulate.
	He recommends firing a Leaf Shield before you step into the fight, as a safety strat.
	
	---------------------
	
	The numbers along the top of the screen correspond to the property indexes discussed above ($0592 - $0595).
	Watch how they behave as you fire different weapons. Mega Man and projectile hitboxes are drawn with colors
	corresponding to their sizes. Synaesthesia ftw!
]]

-- Only interested in tracking the 4 weapon-controllable ones ($0592 - $0595).
-- $0596 affects one of the Crash Bomb explosion particles, but $0596 - $059F
-- pretty much stay at 0 forever. Change NUM_HITBOXES to 16 if you're curious!
local NUM_HITBOXES = 4

-- Synaesthesia for hitbox sizes. Redder = bigger.
-- format: fill color, outline color
-- TODO: Instead of hit size colors, could color it based on collision flags. Also, only render on correct frames?
local hitSizeColors = {
{"#00FF0040","green"},
{"#0000FF40","blue"},
{"#FFEF0040","#FFEF00"},
{"#FF7F0040","#FF7F00"},
{"#FF000040","red"}
}
setmetatable(hitSizeColors, {__index=function(t,k)
	return {"#FFFFFF40", "white"} -- All glitchy out-of-bounds hitboxes are drawn white.
end})

-- Originally written by finalfighter.
-- Variables renamed by me for clarity.
-- I also removed the delay scroll tracking and
-- added stuff for HP, sprite timers, and moving platforms.
-- It's a lightweight hitbox function!
local function drawSpriteInfo()
	local cameraPos = memory.readbyte(0x20)*256+memory.readbyte(0x1F)

	for i = 0, 0x1F do
        local x = memory.readbyte(0x0460 + i)
		local y = memory.readbyte(0x04A0 + i)
        local screenNum = memory.readbyte(0x0440 + i)
        local drawX = screenNum * 256 + x - cameraPos

		local flags = memory.readbyte(0x0420 + i)
		if flags >= 0x80 then -- Sprite is alive
			if i < 0x10 and i ~= 1 then -- Rockman & projectiles
				local propIndex = memory.readbyte(0x0590 + i)             -- weapon hitbox type (0-4)
				local tmp = memory.readbyte(0xD4DC + propIndex)           -- offset into property tables
				local hitSizeX = memory.readbyte(0xD4E1 + tmp) - 0xC  + 4 -- read from property tables
				local hitSizeY = memory.readbyte(0xD581 + tmp) - 0x14 + 4
				local bg, ol = hitSizeColors[propIndex + 1][1], hitSizeColors[propIndex + 1][2]
				gui.box(drawX - hitSizeX, y - hitSizeY, drawX + hitSizeX, y + hitSizeY, bg, ol)
				-- gui.text(x - 2, y - 2, memory.readbyte(0x0590 + i))
			else -- Enemies
				local tmp = memory.readbyte(0x06E0 + i)
				local hitSizeX = math.max(0, memory.readbyte(0xD501 + tmp) - 4 )
				local hitSizeY = math.max(0, memory.readbyte(0xD5A1 + tmp) - 4 )
				gui.box(drawX - hitSizeX, y - hitSizeY, drawX + hitSizeX, y + hitSizeY, "#FFFFFF40", "white")
                
                local platformSizeX = memory.readbyte(0x0150 + i)
                local platformY = memory.readbyte(0x0160 + i)
                if platformSizeX > 0 then
                    -- This enemy is a platform
                    gui.line(drawX - platformSizeX, platformY, drawX + platformSizeX, platformY, "red")
                    local mmx = memory.readbyte(0x0440) * 256 + memory.readbyte(0x0460) - cameraPos
                    local mmy = memory.readbyte(0x04A0)
                    
                    -- Draw Mega Man's detection point
                    gui.line(mmx, mmy + 12, mmx, mmy)
                    gui.box(mmx - 1, mmy + 12 - 1, mmx + 1, mmy + 12 + 1, "magenta")
                    gui.pixel(mmx, mmy + 12, "blue")
                end
			end
		end
	end
end

local function postFrame()
	
	local hitboxTypes = {}
	for i = 1, NUM_HITBOXES do hitboxTypes[i] = memory.readbyte(0x592 + i - 1) end
	
	local str = ""
	for i = 1, #hitboxTypes do
		str = str..hitboxTypes[i]..(i == NUM_HITBOXES and "" or " ")
	end
	
	drawSpriteInfo()
	
	--drawText(5,15,str,"white","0000FF80")
	
end
emu.registerafter(postFrame)
