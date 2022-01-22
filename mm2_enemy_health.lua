--[[
	Draws health values over the heads of everything that SHOULD have one. This script contains a big list of sprites
    that should be excluded, like health pickups, spawners, bullets, etc.
    
    A lot of these values are reused. For instance, enemy #23 == Hothead, item #23 == buster shot. Splitting the tables
    into enemies and items helped, but the bosses are just plain ornery. I'll need to check if we're in a boss room and
    what stage we're in and use a different in each case.
]]
local EmuYFix = 0
local drawHitboxes = false
local drawTypes = false
local drawHealth = true

local function drawBox(x1, y1, x2, y2, c1, c2)
	gui.box(x1, y1 + EmuYFix, x2, y2 + EmuYFix, c1, c2)
end

local function drawText(x, y, t, c1, c2)
	gui.text(x, y + EmuYFix, t, c1, c2)
end

-- Synaesthesia for hitbox sizes. Redder = bigger.
-- Format: fill color, outline color
local hitSizeColors = {
    {"#00FF0040","green"},
    {"#0000FF40","blue"},
    {"#FFEF0040","#FFEF00"},
    {"#FF7F0040","#FF7F00"},
    {"#FF000040","red"}
}
setmetatable(hitSizeColors, {__index=function(t,k)
	return {"#FFFFFF40", "white"} -- The default hitboxe color is white.
end})

-- Values like health pickups and smoke puffs that should not have health bars.
-- It seems like bosses reuse sprite IDs among each other and even some normal enemies for their bullets and bodies.
-- This exclusion table might need to go stage by stage and check if you're in a boss fight...
-- Could use this existing one for general, outside gameplay.
local enemy_exclude = {}
enemy_exclude[0x7B] = true
enemy_exclude[0x21] = true
enemy_exclude[0x15] = true
enemy_exclude[0x7A] = true
enemy_exclude[0x78] = true -- ???/Hologram machine
enemy_exclude[0x26] = true
enemy_exclude[0x79] = true
enemy_exclude[0x76] = true
enemy_exclude[0x06] = true
enemy_exclude[0x25] = true
enemy_exclude[0x14] = true
enemy_exclude[0x28] = true
enemy_exclude[0x27] = true
enemy_exclude[0x2F] = true
enemy_exclude[0x59] = true
enemy_exclude[0x60] = true -- Bubble Man when health ticks up???
enemy_exclude[0x30] = true
enemy_exclude[0x52] = true -- ??? Heatman when charging?
enemy_exclude[0x47] = true
enemy_exclude[0x32] = true -- Telly body
enemy_exclude[0x33] = true -- Telly collapsing parts
enemy_exclude[0x5C] = true -- Metal Man's blades
enemy_exclude[0x13] = true -- Dropping platforms
enemy_exclude[0x0E] = true -- air bubble (not to be confused with Bubble Lead or Air Shooter)
enemy_exclude[0x10] = true -- Anko body
enemy_exclude[0x02] = true -- Shrimp spawner
enemy_exclude[0x03] = true -- Metroid spawner
enemy_exclude[0x07] = true -- Crab spawner
enemy_exclude[0x5A] = true -- Bubbleman's bullet
enemy_exclude[0x5B] = true -- Bubbleman's Bubble Lead
enemy_exclude[0x4D] = true -- Shotman shot
enemy_exclude[0x2B] = true -- Prop-top spawner
enemy_exclude[0x53] = true -- Yoku block - 1
enemy_exclude[0x54] = true -- Yoku block - 2
enemy_exclude[0x55] = true -- Yoku block - 3
enemy_exclude[0x58] = true -- Heatman's flame shot
enemy_exclude[0x40] = true -- Air Tiki
enemy_exclude[0x41] = true -- Air Tiki #2?
enemy_exclude[0x44] = true -- Air Tiki hor
enemy_exclude[0x3E] = true -- Lightning Lord cloud
-- enemy_exclude[0x37] = true -- Pipi spawner
enemy_exclude[0x42] = true -- Msyerious 1-frame apparition in Airman
enemy_exclude[0x43] = true -- Msyerious 1-frame apparition in Airman
enemy_exclude[0x5D] = true -- Airman's tornadoes
enemy_exclude[0x18] = true -- Rabbit projectile (It's not a carrot!)
enemy_exclude[0x1B] = true -- Friender fireball
enemy_exclude[0x2E] = true -- Friender body part
enemy_exclude[0x1A] = true -- Friender tail
enemy_exclude[0x1C] = true -- Friender face
enemy_exclude[0x1E] = true -- Rooster spawner
enemy_exclude[0x61] = true -- Woodman's Leaf Shield
enemy_exclude[0x62] = true -- Woodman's falling leaves
enemy_exclude[0x77] = true -- Small health pickup/Alien (wtf)
enemy_exclude[0x3F] = true -- Lightning bolt
enemy_exclude[0x35] = true -- Met/Sniper Joe bullet
enemy_exclude[0x56] = true -- Wily Machine body/Mysterious 1-frame apparition in Crashman's stage
enemy_exclude[0x5E] = true -- Crash Bomb
enemy_exclude[0x5F] = true -- Crash Bomb explosion
enemy_exclude[0x12] = true -- Moving platform (Crash/Wily 4)
enemy_exclude[0x63] = true -- Wily 1 moving blocks / Guts tank treads
enemy_exclude[0x64] = true -- Wily 1 moving block spawner
enemy_exclude[0x65] = true -- Mecha Dragon body
enemy_exclude[0x66] = true -- Mecha Dragon tail
enemy_exclude[0x69] = true -- Guts Tank fist
enemy_exclude[0x67] = true -- Guts tank arm
enemy_exclude[0x6E] = true -- Boobeam bullet
enemy_exclude[0x7C] = true -- Refight teleporter entrance
enemy_exclude[0x7D] = true -- Refight teleporter exit
enemy_exclude[0x7E] = true -- Refight teleporter to Wily Machine
enemy_exclude[0x6B] = true -- Wily Machine projectile
enemy_exclude[0x6C] = true -- Wily Machine debris
enemy_exclude[0x74] = true -- Wily Machine capsule (as he escapes)/Blood drop
enemy_exclude[0x72] = true -- Blood dropper - 1
enemy_exclude[0x73] = true -- Blood dropper - 2
enemy_exclude[0x70] = true -- Star
enemy_exclude[0x6F] = true -- Alien bullet
enemy_exclude[0x24] = true -- Changkey

-- Some IDs are reused between Mega Man/projectiles and enemies
local item_exclude = {}
item_exclude[0x23] = true -- Buster shots
item_exclude[0x24] = true -- Little damage accents
item_exclude[0x34] = true -- Quick boomerangs
item_exclude[0x36] = true -- Metal blades
item_exclude[0x3F] = true -- Water splash
item_exclude[0x25] = true -- Mega Man explosions
item_exclude[0x3C] = true -- Dinked Quick boomerang
item_exclude[0x3A] = true -- Item 3
item_exclude[0x33] = true -- Bubble Lead
item_exclude[0x38] = true -- Item 1
item_exclude[0x39] = true -- Item 2
item_exclude[0x30] = true -- Atomic fireball
item_exclude[0x37] = true -- Time Stopper manager
item_exclude[0x31] = true -- Air Shooter
item_exclude[0x3D] = true -- Dinked Air Shooter
item_exclude[0x35] = true -- Crash Bomb
item_exclude[0x2F] = true -- Crash Bomb explosion
item_exclude[0x32] = true -- Leaf Shield
item_exclude[0x74] = true -- Wily Capsule in Alien fight
item_exclude[0x79] = true -- Wily operating hologram machine
item_exclude[0x7C] = true -- Disco ball
item_exclude[0x3B] = true -- Dinked Leaf Shield

if arg == "-hitboxes" then
    drawHitboxes = true
end

local mem = {}
local readbyte = memory.readbyte

--[[
function memory.readbyte(addr)
    --print("hello")
    local ret = mem[addr] or readbyte(addr)
    mem[addr] = readbyte(addr)
    return ret
end --]]

-- Written by finalfighter.
-- Variables renamed by me for clarity.
-- I also removed the delay scroll tracking and
-- HP/sprite timer stuff, and added the bit that draws health values.
local function drawSpriteInfo()
	local scX = memory.readbyte(0x20) * 256 + memory.readbyte(0x1F)
	local scY = 0

	for i=0, 0x1F do
		local x = memory.readbyte(0x0440 + i) * 256 + memory.readbyte(0x0460 + i) - scX
		local y = memory.readbyte(0x04A0 + i) - scY
		local flags = memory.readbyte(0x0420 + i)
        local index = memory.readbyte(0x0400 + i)
        local timer = memory.readbyte(0x04E0 + i)
        local health = memory.readbyte(0x06C0 + i)
        
		if flags >= 0x80 then --sprite is alive
            
            -- Doesn't work when Mega Man is screen shifted.
			if i < 0x10 and i ~= 1 then -- Rockman & projectiles
				local propIndex = memory.readbyte(0x0590 + i)             --weapon hitbox type (0-4)
				local tmp = memory.readbyte(0xD4DC + propIndex)           --offset into property tables
				local hitSizeX = memory.readbyte(0xD4E1 + tmp) - 0xC  + 4 --read from property tables
				local hitSizeY = memory.readbyte(0xD581 + tmp) - 0x14 + 4
				local bg, ol = hitSizeColors[propIndex + 1][1], hitSizeColors[propIndex + 1][2]
				
				if drawHitboxes then
                    drawBox(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY, bg, ol)
                end
                
                if drawTypes then drawText(x, y, string.format("t=%02X", index)) end
                if drawHealth and not item_exclude[index] then
				    drawText(x - 5, y - hitSizeY - 9, string.format("%02d", health))
                end
			else -- regular entities
				local tmp = memory.readbyte(0x06E0 + i)
				local hitSizeX = math.max(0, memory.readbyte(0xD501 + tmp) - 4 )
				local hitSizeY = math.max(0, memory.readbyte(0xD5A1 + tmp) - 4 )
                
				if drawHitboxes then
                    drawBox(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY, "#FFFFFF40", "white")
                end
                
                if drawTypes then drawText(x, y, string.format("t=%02X", index)) end
                if drawHealth and not enemy_exclude[index] then
                    drawText(x - 5, y - hitSizeY - 9, health)
                end
			end
		end
	end
end

local function postFrame()
	drawSpriteInfo()
end
emu.registerafter(postFrame)
