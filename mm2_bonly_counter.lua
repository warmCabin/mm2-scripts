
--[[

	Overview
	
]]

local bPressCount = 0
local bHeld = false
local persistTimer = 0

local function update()

	if not emu.lagged() and memory.readbyte(0xA9)~=0 then
		if joypad.get(1).B then
			if not bHeld then
				bHeld = true
				bPressCount = bPressCount + 1
			end
			persistTimer = 30
		else
			bHeld = false
		end	
	end
		
	persistTimer = persistTimer - 1

end
emu.registerafter(update)

local function guiFunc()
	--[[if emu.framecount() ~= prevFrame then
		update()
	end ]]
	if persistTimer > 0 then
		gui.text(100,210,"Weapon use #"..bPressCount)
	end
	gui.text(10,10,"Weapon uses: "..bPressCount)
end
gui.register(guiFunc)
