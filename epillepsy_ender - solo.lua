
--[[
	https://stackoverflow.com/questions/41954718/how-to-get-ppu-memory-from-fceux-in-lua
]]
function memory.writebyteppu(a,v)
    --memory.writebyte(0x2001,0x00) -- Turn off rendering
    memory.readbyte(0x2002) -- PPUSTATUS (reset address latch)
    memory.writebyte(0x2006,math.floor(a/0x100)) -- PPUADDR high byte
    memory.writebyte(0x2006,a % 0x100) -- PPUADDR low byte
    memory.writebyte(0x2007,v) -- PPUDATA
    --memory.writebyte(0x2001,0x1e) -- Turn on rendering
end

function memory.readbyteppu(a)
    --memory.writebyte(0x2001,0x00) -- Turn off rendering
    memory.readbyte(0x2002) -- PPUSTATUS (reset address latch)
    memory.writebyte(0x2006,math.floor(a/0x100)) -- PPUADDR high byte
    memory.writebyte(0x2006,a % 0x100) -- PPUADDR low byte
    if a < 0x3f00 then 
        dummy=memory.readbyte(0x2007) -- PPUDATA (discard contents of internal buffer if not reading palette area)
    end
    ret=memory.readbyte(0x2007) -- PPUDATA
    --memory.writebyte(0x2001,0x1e) -- Turn on rendering
    return ret
end

function memory.readbytesppu(a,l)
    --memory.writebyte(0x2001,0x00) -- Turn off rendering
    local ret
    local i
    ret=""
    for i=0,l-1 do
        memory.readbyte(0x2002) -- PPUSTATUS (reset address latch)
        memory.writebyte(0x2006,math.floor((a+i)/0x100)) -- PPUADDR high byte
        memory.writebyte(0x2006,(a+i) % 0x100) -- PPUADDR low byte
        if (a+i) < 0x3f00 then 
            dummy=memory.readbyte(0x2007) -- PPUDATA (discard contents of internal buffer if not reading palette area)
        end
        ret=ret..string.char(memory.readbyte(0x2007)) -- PPUDATA
    end
    --memory.writebyte(0x2001,0x1e) -- Turn on rendering
    return ret
end

local EPILEPSY_THRESHOLD = 9

local shouldOverwrite = false
local prevBg = memory.readbyteppu(0x3F00)
local replacementBg = 0
local count = 0

-- we're going to need to apply a similar watch to all BG colors
local function overwriteBG(addr, size, val)

	update()

	if shouldOverwrite then
		memory.writebyteppu(0x3F00, replacementBg)
	end

end
--memory.registerwrite(0x2007, update) -- PPUDATA writes
--memory.registerexec(0xCFED, update)  -- Beginning of NMI
--memory.registerexec(0xD0D3, update)  -- End of NMI
--memory.registerexec(0xD0FF, update)  -- Beginning of draw routine
memory.registerexec(0xD117, overwriteBG) -- end of draw routine

function update()
	
	local bg = memory.readbyteppu(0x3F00)
	
	if bg==prevBg then
		count = count + 1
	else
		count = 1
		shouldOverwrite = true
	end
	
	prevBg = bg
	
	if count==EPILEPSY_THRESHOLD then replacementBg = bg end
	if count >= EPILEPSY_THRESHOLD then shouldOverwrite = false end
	
end
--emu.registerafter(main)



