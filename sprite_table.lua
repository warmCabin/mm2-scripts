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

local function formatPos(pixel, subpixel)
    return showHex
        and string.format("%02X.%02X", pixel, subpixel)
        or string.format("%7.3f", pixel + subpixel / 256)
end

local function getCoords(tableIndex)
    return math.floor(tableIndex / 16) * 132, (tableIndex % 16) * 10 + 20
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
        local timer = memory.readbyte(0x04E0+i)
        
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
                        string.format("%02X: %02X (%s,%s)", i, index, formatPos(xPix, xSub), formatPos(yPix, ySub)), TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
                end
			else -- regular entities
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
                        string.format("%02X: %02X (%s,%s)", i, index, formatPos(xPix, xSub), formatPos(yPix, ySub)), TABLE_TEXT_COLOR, TABLE_BACKGROUND_COLOR)
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
