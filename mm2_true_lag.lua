
--[[
	
	There are 3 types of lag frames in this game: loading lag, underwater lag, and true lag.
	
	True lag:
		Classic lag. The game is trying to do too much and can't keep up, so it ignores you for a frame.
		This type of lag causes the iconic slow motion effect.
		In Mega Man 2, the in-game frame counter (0x001C) does not increment, although this may not be the case
		for some other games.
		
	Underwater lag:
		To implement slower physics underwater, the devs decided to intentionally create lag frames.
		(Your velocity in RAM is actually the same as on land. And of course, you have a higher jump height.)
		These frames freeze time and ignore input just like true lag frames, but with one crucial difference:
		The in-game frame counter at 0x001C DOES increment. Since this counter is responsible for frame rules,
		it's important to know what's affecting it and what's not.
		
	Loading lag:
		When a level or menu screen has to load, the screen is blanked and controller input is ignored, so the
		processor is free to focus entirely on moving all that data. If rendering was not disabled, the screen
		would be a "glitchy" mess.
		Note that, in Mega Man 2, they accidentally enable rendering one frame before the load is done; that's
		why one frame of garbage is visible when a level loads.
		They certainly didn't have FCEUX in 1988, so I don't blame them for not noticing!
		Note that loads always take the same amount of time in this game. That is, loads are not affected by
		frame rules.
	
]]

local frameCount = 0
local prevCount = -1
local trueLag = 0
local rendering = true
local renderCount = 0

local prevCountEmu = -1

function update()

	local frameCount = memory.readbyte(0x001C)
	
	if rendering then
		renderCount = renderCount + 1
	else
		renderCount = 0
	end
	
	if frameCount == prevCount then
		--Rendering is mistakenly enabled one frame before the loads are done, but input is still ignored.
		--This results in a single false positive true lag frame every time a stage loads.
		--This check accounts for that.
		if renderCount > 1 then
			trueLag = trueLag + 1
		else
			--print("loading lag")
			--loadingLag++
		end
	end
	
	prevCount = frameCount
	gui.text(5,15,"True lag: "..trueLag)
	
	--reading PPUSTATUS during...whenever this callback happens...always returns 0.
	--You have to use the memory callback.
	--print(string.format("frame: 2001: %02X",memory.readbyte(0x20001)))
	
end
emu.registerafter(update)

function ppuStatusChange(addr,size,val)
	
    -- In old versions of FCEUX, the passed val was always nil for some reason. It was super lame.
    -- This is the cope.
	val = memory.readbyte(addr)
	
	if AND(val,0x18) ~= 0 then -- 0x10: render sprites | 0x08: render BG
		rendering = true
	else
		rendering = false
	end

end
memory.register(0x2001, 1, ppuStatusChange)

local function init()
	trueLag = 0
	prevCount = -1
	rendering = true
end

local function resetButton()
	init()
end
taseditor.registermanual(resetButton,"Reset True Lag")

function loadState()
	init()
end
savestate.registerload(loadState)
