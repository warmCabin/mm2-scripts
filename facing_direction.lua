local EmuYFix = 0
local drawBoxes = false

if arg == "-drawBoxes" then drawBoxes = true end

--These functions call gui.text and gui.box, automatically applying EmuYFix to the position
local function BOX(x1, y1, x2, y2, c1, c2)
	gui.box(x1, y1 + EmuYFix, x2, y2 + EmuYFix, c1, c2)
end

local function TEXT(x, y, t)
	gui.text(x, y + EmuYFix, t)
end

local function drawSpriteInfo()

	local scX = memory.readbyte(0x20) * 256 + memory.readbyte(0x1F)
	local scY = 0

	for i = 0, 0x1F do
		local x = memory.readbyte(0x0440 + i)*256 + memory.readbyte(0x0460 + i) - scX
		local y = memory.readbyte(0x04A0 + i)                                   - scY

		local flags = memory.readbyte(0x0420 + i)
		if flags >= 0x80 then --sprite is alive
			local index  = memory.readbyte(0x0400 + i)
			local hp     = memory.readbyte(0x06C0 + i)

			if i < 0x10 and i ~= 1 then --Rockman & projectiles
                if drawBoxes then
                    local tmp = memory.readbyte(0x0590 + i) --weapon hitbox type (0-4)
                    tmp = memory.readbyte(0xD4DC + tmp)     --offset into property tables
                    local hitSizeX = memory.readbyte(0xD4E1+tmp) - 0xC  + 4 --read from property tables
                    local hitSizeY = memory.readbyte(0xD581+tmp) - 0x14 + 4
                    BOX(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY, "clear", "red")
                end
                
                local str
                if AND(flags, 0x40) ~= 0 then
                    TEXT(x, y, "->")
                else
                    TEXT(x, y, "<-")
                end
			else --regular enemies
                if drawBoxes then
                    local tmp = memory.readbyte(0x06E0+i)
                    local hitSizeX = math.max(0, memory.readbyte(0xD501+tmp) - 4 )
                    local hitSizeY = math.max(0, memory.readbyte(0xD5A1+tmp) - 4 )
                    BOX(x - hitSizeX, y - hitSizeY, x + hitSizeX, y + hitSizeY, "clear", "green")
                end
                
                local str
                if AND(flags, 0x40) ~= 0 then
                    TEXT(x, y, "->")
                else
                    TEXT(x, y, "<-")
                end
			end
		end
	end
end
gui.register(drawSpriteInfo)
