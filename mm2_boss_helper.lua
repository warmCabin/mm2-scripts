
--[[

	This script helps you analayze your boss fights. Just set HEALTH_ADDRESS and BOSS_MAX_HEALTH below.
	They are currently setup for Rockman 2--they should work for Mega Man 2 as well.
    Also works for Rockman 1!
	The code assumes your boss starts with a positive health value, which decreases to 0 when he dies.
	If this is not the case, it should be fairly simple to modify the code to suit your individual case.
	
	Instructions:
		- Go to the first actionable frame of the boss fight you want analyzed
		- Click Run
		- Let the emulator go until the boss dies
		- Check output in script window
		
	The output will list the delay between hits. If there were lag frames, it will tell you how many in parentheses.
	
]]

local HEALTH_ADDRESS = 0x06C1
local BOSS_MAX_HEALTH = 28

local bossHealth
local prevHealth = BOSS_MAX_HEALTH
local hitFrame = emu.framecount()
local total = 0
local totalLag = 0
local hitLag = emu.lagcount()
local hitCount = 0

local function update()

	bossHealth = memory.readbyte(HEALTH_ADDRESS)
	if bossHealth < prevHealth then
	
		prevHealth = bossHealth
		local diff = emu.framecount()-hitFrame
		local lagDiff = emu.lagcount()-hitLag
		total = total + diff
		totalLag = totalLag + lagDiff
		hitCount = hitCount + 1
		
		if lagDiff==0 then
			print(string.format("%2d: %d [%d]",hitCount,diff,total))
		else
			print(string.format("%2d: %d (%d+%d) [%d]",hitCount,diff,diff-lagDiff,lagDiff,total))
		end
		
		hitFrame = emu.framecount()
		hitLag = emu.lagcount()
		
	end
	
	if bossHealth==0 and prevHealth>=0 then
		print(killMsg[math.random(#killMsg)])
		if totalLag==0 then
			print("Total delay: "..total)
		else
			print(string.format("Total delay: %d (%d+%d)",total,total-totalLag,totalLag))
		end
		prevHealth = -1
	end

end
emu.registerafter(update)

killMsg = {"WASTED","GOT EM!","DEAD.","REKT.","NICELY DONE!","KO!","COOL.","DESTROYED.","WELL THAT WAS FAST.","GREAT JOB!","OK!","NO WAY!","...WHAT JUST HAPPENED?","HE DIDN'T STAND A CHANCE!","WHOA, SLOW DOWN, THERE!","STELLAR FIGHT!","AND THAT'S THE BATTLE!","YOU ARE SUPER PLAYER!"}
