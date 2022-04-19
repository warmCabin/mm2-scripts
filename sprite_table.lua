--[[
	Draws a sprite table with sprite index, type, X, and Y pos.
    It also indicates which sprite corresponds to which sprite and optionally draws hitboxes.
    
    Use the following command line args to control this behavior:
      --draw-hitboxes
      --hide-table
      --decimal-pos : show positions in decimal instead of hex
]]
local EmuYFix = 0
local drawHitboxes = arg:find("--draw-hitboxes", 0, true)
local drawTable = not arg:find("--hide-table", 0, true)
local showHex = not arg:find("--decimal-pos", 0, true)

local TABLE_BACKGROUND_COLOR = "#13067FC0"
local TABLE_TEXT_COLOR = "FFFFFFC0"

local playerNames = {
    [0x23] = "Lemon",
    [0x24] = "Dust",
    [0x25] = "Meatball",
    [0x33] = "Bubble Lead",
    [0x34] = "Quick Boomerang",
    [0x36] = "Metal Blade",
    [0x39] = "Item 2",
    [0x3A] = "Item 3",
    [0x3C] = "Quick Boomerang (dead)",
    [0x3F] = "Splash",
}
setmetatable(playerNames, {__index = function(t, k) return string.format("$%02X", k) end})

local enemyNames = {
    [0x00] = "Shrimp A",
    [0x01] = "Shrimp B",
    [0x02] = "Anko fins?",
    [0x03] = "Metroid spawner", -- Mother Brain? Idk I've never played Metroid.
    [0x04] = "Metroid",
    [0x06] = "Poof",
    [0x08] = "Crab",
    [0x07] = "Crab spawner",
    [0x0A] = "Hermit crab",
    [0x0B] = "Hermit crab shell",
    [0x0C] = "Mama frog",
    [0x0D] = "Baby frog",
    [0x0E] = "Bubble",
    [0x0F] = "Anko",
    [0x10] = "Anko eye?",
    [0x12] = "Track platform",
    [0x13] = "Falling platform",
    [0x14] = "Quick laser manager",
    [0x15] = "Quick laser",
    [0x21] = "Telly spanwer", -- AKA "Terry comes out"
    [0x22] = "Telly",
    [0x23] = "Hothead",
    [0x25] = "Light switch 1 (off)",
    [0x26] = "Light switch 2 (on)",
    [0x27] = "Light switch 1 (on)",
    [0x28] = "Light switch 2 (off)",
    [0x2C] = "Prop-top",
    [0x2B] = "Prop-top spanwer",
    [0x2D] = "Crash wall (tall)",
    [0x2F] = "Door",
    [0x30] = "Crusher",
    [0x31] = "Blocky head",
    [0x32] = "Blocky body",
    [0x33] = "Blocky can",
    [0x35] = "Sniper Joe bullet",
    [0x3C] = "Kopipi",
    [0x3E] = "Cloud platform",
    [0x46] = "Springer",
    [0x47] = "Drill spawner",
    [0x48] = "Drill (up)",
    [0x49] = "Drill (down)",
    [0x4B] = "Shotman (left)",
    [0x4C] = "Shotman (right)",
    [0x4D] = "Shotman bullet",
    [0x4E] = "Sniper Armor",
    [0x4F] = "Sniper Joe",
    [0x50] = "Scworm dispenser",
    [0x51] = "Scworm",
    [0x53] = "Yoku block A",
    [0x54] = "Yoku block B",
    [0x55] = "Yoku block C",
    [0x57] = "Crash wall (short)",
    [0x58] = "Flame", -- Boss value. Reused?
    [0x59] = "Quick Man's boomerang", -- Boss value. Reused?
    [0x5A] = "Bubble bullet",
    [0x5B] = "Bubble Lead", -- Boss value
    [0x60] = "Meatball",
    [0x76] = "Large health drop",
    [0x77] = "Small health drop",
    [0x78] = "Large energy drop",
    [0x79] = "Small energy drop",
    [0x7A] = "E tank",
    [0x7B] = "Extra life",
}
setmetatable(enemyNames, {__index = function(t, k) return string.format("$%02X", k) end})

local bossNames = {
    [0x00] = "Heat Man",
    [0x01] = "Air Man",
    [0x02] = "Wood Man",
    [0x03] = "Bubble Man",
    [0x04] = "Quick Man",
    [0x05] = "Flash Man",
}
setmetatable(bossNames, {__index = function(t, k) return string.format("$%02X", k) end})

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

local function formatPos(pixel, subpixel)
    return showHex
        and string.format("%02X.%02X", pixel, subpixel)
        or string.format("%7.3f", pixel + subpixel / 256)
end

local function getCoords(tableIndex)
    return math.floor(tableIndex / 16) * 132, (tableIndex % 16) * 10 + 20
end

local function getPlayerName(slot, id)
    if slot == 0 then
        return "Mega Man"
    else
        return playerNames[id]
    end
end

local function getEnemyName(slot, id)
    if slot == 1 then
        return bossNames[memory.readbyte(0xB3)]
    else
        return enemyNames[id]
    end
end

-- Written by finalfighter.
-- Variables renamed by me for clarity.
-- I also removed the delay scroll tracking and
-- HP/sprite timer stuff, and added the bit that draws health values.
local function drawSpriteInfo()

    if drawTable then 
        drawText(0, 10, "Player", TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
        drawText(132, 10, "Enemy", TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
    end
    
	local scX = memory.readbyte(0x20) * 256 + memory.readbyte(0x1F)
	local scY = 0
    
	for i=0, 0x1F do
        local xPix = memory.readbyte(0x0460 + i)
        local xSub = memory.readbyte(0x0480 + i)
        local yPix = memory.readbyte(0x04A0 + i)
        local ySub = memory.readbyte(0x04C0 + i)
		local flags = memory.readbyte(0x0420 + i)
        local index = memory.readbyte(0x0400 + i)
        local timer = memory.readbyte(0x04E0 + i)
        local health = memory.readbyte(0x06C0 + i)
        
        local drawX = memory.readbyte(0x0440 + i) * 256 + xPix - scX
		local drawY = yPix - scY
        
        local tableDrawX, tableDrawY = getCoords(i)
        
		if flags >= 0x80 then --sprite is alive
            
            -- Doesn't work when Mega Man is screen shifted.
			if i < 0x10 and i ~= 1 then -- Rockman & projectiles
				local propIndex = memory.readbyte(0x0590 + i)             --weapon hitbox type (0-4)
				local tmp = memory.readbyte(0xD4DC + propIndex)           --offset into property tables
				local hitSizeX = memory.readbyte(0xD4E1 + tmp) - 0xC  + 4 --read from property tables
				local hitSizeY = memory.readbyte(0xD581 + tmp) - 0x14 + 4
				local bg, ol = hitSizeColors[propIndex + 1][1], hitSizeColors[propIndex + 1][2]
				
				if drawHitboxes then
                    drawBox(drawX - hitSizeX, drawY - hitSizeY, drawX + hitSizeX, drawY + hitSizeY, bg, ol)
                end
                
				drawText(drawX - 5, drawY - hitSizeY - 9, string.format("%02X", i), "white", "#195106")
                
                if drawTable then
                    drawText(tableDrawX, tableDrawY,
                        -- string.format("%02X: %02X (%s,%s)", i, index, formatPos(xPix, xSub), formatPos(yPix, ySub)),
                        string.format("%02X: %s", i, getPlayerName(i, index)),
                        TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
                end
			else -- Enemies
				local tmp = memory.readbyte(0x06E0 + i)
				local hitSizeX = math.max(0, memory.readbyte(0xD501 + tmp) - 4 )
				local hitSizeY = math.max(0, memory.readbyte(0xD5A1 + tmp) - 4 )
                
				if drawHitboxes then
                    drawBox(drawX - hitSizeX, drawY - hitSizeY, drawX + hitSizeX, drawY + hitSizeY, "#FFFFFF40", "white")
                end
                
                drawText(drawX - 5, drawY - hitSizeY - 9, string.format("%02X", i), "white", "#195106")
                -- drawText(drawX - 5, drawY - hitSizeY - 9, string.format("%d", timer))
                if drawTable then
                    drawText(tableDrawX, tableDrawY,
                        string.format("%02X: %s", i, getEnemyName(i, index)),
                        -- string.format("%02X: %02X %02X %02X", i, index, health, flags),
                        -- string.format("%02X: %02X (%s,%s)", i, index, formatPos(xPix, xSub), formatPos(yPix, ySub)),
                        TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
                end
			end
		else 
            if drawTable then drawText(tableDrawX, tableDrawY, string.format("%02X:", i), TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR) end
        end
	end
end

local function postFrame()
	drawSpriteInfo()
end
emu.registerafter(postFrame)
