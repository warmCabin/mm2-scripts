--[[
	Draws health values over the heads of everything that SHOULD have one. That determination is made by checking the sprite
    flags and damage tables, plus a few hardcoded exceptions.
    
    Might make sense to absorb this functionality into ultimate_hitbox.
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
	return {"#FFFFFF40", "white"} -- The default hitbox color is white.
end})

if arg == "--hitboxes" then
    drawHitboxes = true
end

--[[
    Behaviors I don't like:
      Pipi eggs become tangible and display health only when dropped (idk, I kinda like this as is).
      Each picoblock (6A) shows its health during the merge sequence. Same sprite ID as standard vulnerable sprite.
      Crash walls have a health bar. I mean, that IS how they're implemented, but...
      
    Might need to make special override functions per sprite type or something. That would be neat!
]]

-- Enemies that are known to toggle their flags in a way that would confuse the normal rules.
local enemy_whitelist = {}
enemy_whitelist[0x3A] = false -- Pipi egg. Not sure about this one.

-- Cutscene objects in boss fights. We can't rely on our usual flags to tell us this.
local boss_blacklist = {}
boss_blacklist[0x74] = true -- Wily Machine after you kill him and when it spawns the alien.
boss_blacklist[0x78] = true -- Hologram shooty machine
boss_blacklist[0x79] = true -- Wily operating the hologram machine
boss_blacklist[0x7A] = true -- Wily jumping
boss_blacklist[0x7B] = true -- Wily begging for mercy

-- Initial hitbox reverse engineering work was done by finalfighter.
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
                
                if drawTypes then drawText(x, y, string.format("t=%02X,s=%02X,f=%02X", index, i, flags)) end
                if drawHealth and i == 0 then
				    drawText(x - 5, y - hitSizeY - 9, string.format("%02d", health))
                end
			else -- regular entities
				local tmp = memory.readbyte(0x06E0 + i)
				local hitSizeX = math.max(0, memory.readbyte(0xD501 + tmp) - 4 )
				local hitSizeY = math.max(0, memory.readbyte(0xD5A1 + tmp) - 4 )
                
				if drawHitboxes then
                    drawBox(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY, "#FFFFFF40", "white")
                end
                
                if drawTypes then drawText(x, y, string.format("t=%02X,s=%02X,f=%02X", index, i, flags)) end
                if shouldDrawHealth(i, flags, index) then
                    drawText(x - 5, y - hitSizeY - 9, health)
                end
			end
		end
	end
end

function shouldDrawHealth(slot, flags, spriteType)
    if not drawHealth then return false end
    
    if slot == 1 then
        -- Check for boss cutscene objects
        return not boss_blacklist[spriteType]
    else
        --[[
            Regular enemies.

            Of invisibility and hurtbox, just hurtbox should be active. Most invisible enemies are already intangible (e.g. spawners),
            but a few use it to sort of lurk off screen (e.g. Wood Man's monkeys), and I'd like to maintain that illusion with this HUD.
            
            Most invincible obstacle type enemies (e.g. crushers) don't actually use the invincibility flag; rather, the damage table says they take
            0 damage from all weapons. Meanwhile, the invincibility flag is mainly used by enemies with a "defense mode" (e.g. Mets), and I want those
            guys to have a persistent health bar. Therefore, the damage tables are the best indicator of whether something is permanently invincible,
            and that's what effectivelyInvincible checks.
            
            enemy_whitelist documents the exceptions that defy these rules. Although with the latest refined ruleset...there aren't any!
        ]]
        return enemy_whitelist[spriteType] or bit.band(flags, 0x022) == 2 and not effectivelyInvincible(spriteType)
    end
    
end

function effectivelyInvincible(spriteType)
    local dmgTable = reverseDamageTable(spriteType)
    
    for i = 0, 8 do
        if dmgTable[i] ~= 0 then return false end
    end
    
    return true
end

--[[    
    The damage tables for each weapon are laid out back to back, but it's not really a standardized 2D array type of thing.
    Each weapon has a callback with custom logic, so you have to check each one and see what data it's using.
    Btw, that's how Atomic Fire is able to use the Buster table for small/medium shots, and a unique table for the [big shots].
    
    Here's the address for each callback routine and the corresponding table it uses.
    
    damge callback ptrs: $E964, $E96E
    
    P: E64F -> E976
    H: E6A4 -> E9F2
    A: E70D -> EA6A
    W: E766 -> EAE2
    B: E7CC -> EB5A
    Q: E825 -> EBD2
    F: E964 (junk/padding, = to original ptr table. Time Stopper doesn't actually damage enemies. Would be a crazy undefined opcode.)
    M: E8FD -> ECC2
    C: E899 -> EC4A
    
    All of them are 0x78 long, except for P, which is 0x7C long, for some reason.
]]

local dmgTables = {0xE9F2, 0xEA6A, 0xEAE2, 0xEB5A, 0xEBD2, 0xFFFF, 0xECC2, 0xEC4A}
dmgTables[0] = 0xE976 -- Lua moment

function reverseDamageTable(spriteType)
    local ret = {}
    
    for i = 0, 8 do (function()
        -- Time Stopper doesn't have a damage table.
        if i == 6 then
            ret[i] = 0
            return -- continue
        end
        
        local baseDmgTable = dmgTables[i]
        ret[i] = memory.readbyte(baseDmgTable + spriteType)
    end)() end
    
    return ret
end

local function callback()
	drawSpriteInfo()
end
emu.registerbefore(callback)
