
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

local shouldOverwrite = {} -- all false
local prevBg = {} -- all an index into the palette
local replacementBg = {} -- all 0
local count = {} -- all 0

local softPPUMask = 0
local prevSoftPPUMask = 0

for i=0,0xF do
	prevBg[i] = memory.readbyteppu(0x3F00+i)
	replacementBg[i] = 0
	count[i] = 0
end

-- we're going to need to apply a similar watch to all BG colors
local function overwriteBG(addr, size, val)

	update()

	for i=0,0xF do
		if shouldOverwrite[i] then
			memory.writebyteppu(0x3F00+i, replacementBg[i])
		end
	end

end
--memory.registerwrite(0x2007, update) -- PPUDATA writes
--memory.registerexec(0xCFED, update)  -- Beginning of NMI
--memory.registerexec(0xD0D3, update)  -- End of NMI
--memory.registerexec(0xD0FF, update)  -- Beginning of draw routine
memory.registerexec(0xD117, overwriteBG) -- end of draw routine

function update()
	
	--print(string.format("soft ppu mask: %02X", memory.readbyte(0xF8)))
	--print(string.format("ANDED: %02X", AND(memory.readbyte(0xF8), 0x1E)))
	
	if AND(softPPUMask, 0x1E)~=0x1E then
	print("setting all shouldOverwrite to flase")
		for i=0,0xF do
			shouldOverwrite[i] = false
			count[i] = EPILEPSY_THRESHOLD+1
			prevBg[i] = memory.readbyteppu(0x3F00+i)
		end
		return
	end
	
	for i=0,0xF do
		local bg = memory.readbyteppu(0x3F00+i)
	
		if bg==prevBg[i] then
			count[i] = count[i] + 1
		else
			count[i] = 1
			shouldOverwrite[i] = true
		end
	
		prevBg[i] = bg
	
		if count[i]==EPILEPSY_THRESHOLD then replacementBg[i] = bg end
		if count[i] >= EPILEPSY_THRESHOLD then shouldOverwrite[i] = false end
	end
	
end
--emu.registerafter(main)

function postFrame()

	prevSoftPPUMask = softPPUMask
	softPPUMask = memory.readbyte(0xF8)
	--print(string.format("soft ppu mask post frame: %02X", softPPUMask))
	--print(string.format("prev soft ppu mask post frame: %02X", prevSoftPPUMask))

end
emu.registerafter(postFrame)



