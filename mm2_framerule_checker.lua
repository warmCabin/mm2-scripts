
--[[
	Frame rule checker for Mega Man 2/Rockman 2.
	There are 8-, 4-, and 16-frame rules to contend with, as well as a separate but related 5-frame underwater lag rule.
    This script prints your position in all 4.
	Pipes are the rules. Dashes mean you have to wait for the next pipe. The x is "you."
	For example, if you see: |--x----|, that means you're waiting 5 frames for the frame rule, and you could beat it by saving 3.
	
	For a detailed write up on the frame rules and what causes them, see: https://warmcabin.github.io/mm2/docs/mm2_framerules.pdf
    
    The appropriate rule will turn red when it's time to check it. I'll summarize these moments here:
	
	4-frame rule:
		The last frame of a boss's pose, i.e., the frame before he starts standing still to let his health bar fill.
	
	8-frame rule:
		The ~10 frames of loading lag after defeating a boss
	
	16-frame rule:
		Check the Wily boss's health ($06C1) in RAM watch. On the frame it reaches 0, gauge the frame rule.
        
    5-frame underwater rule:
        The first frame where the boss's health bar WOULD fill up. Put differently, the first multiple of 4 after the 4-frame sequence turned red.
	
]]

local prevHitCallback = false
local hitCallback = false
local checkFrame4 = 0
local checkFrame16 = 0

local prevBossHealth = 0
local bossHealth = 0

local prevEmuFrameCount = emu.framecount()

-- str[i] = chr
-- C wins every time
local function placeChar(str, chr, i)
	return str:sub(1, i-1).."x"..str:sub(i+1, str:len())
end

local function updateCheckFrame()

    bossHealth = memory.readbyte(0x06C1)
    local stageNum = memory.readbyte(0x2A)
    
    if hitCallback and not prevHitCallback then
        checkFrame4 = emu.framecount()
    end
    
    -- Only Mecha Dragon and Guts Tank cause this framerule.
    -- I could be cleverer with this check, but I don't feel like tracing the boss timer code right now.
    if (stageNum == 8 or stageNum == 10) and bossHealth == 0 and prevBossHealth ~= 0 then
        checkFrame16 = emu.framecount()
    end

    if not emu.lagged() then
        prevHitCallback = hitCallback
        hitCallback = false -- Will be overwritten by the exec callback
    end
    
    prevBossHealth = bossHealth
end

local function getRule5Color(frameCount)
    -- Check if actually underwater
    if memory.readbyte(0xFB) == 0 then return "white" end
    
    -- Determine first frame the health bar should fill up
    local diff = emu.framecount() - checkFrame4
    return (diff >= 0 and diff < 4 and frameCount % 4 == 0) and "red" or "white"
end

local function main()

    -- This check is time-sensitive, and gets very confused when you load savestates.
    -- So I just freeze things until time is flowing normally.
    if prevEmuFrameCount == emu.framecount() - 1 then
        updateCheckFrame()
    else
        prevBossHealth = 0
    end
	
    local gameState = memory.readbyte(0x01FE)
	local frameCount = memory.readbyte(0x1C) -- $1Cの謎
    local waterCount = memory.readbyte(0xFC)
	local m = frameCount % 16 + 1 -- +1 because of Lua's infernal 1-indexing
	
	local rule16 = placeChar("|---------------|", 'x', m)
	local rule8  = placeChar("|-------|-------|", 'x', m)
	local rule4  = placeChar("|---|---|---|---|", 'x', m)
    local rule5  = placeChar("|----|",  'x', waterCount + 1)
    
    local color4 = checkFrame4 == emu.framecount() and "red" or "white" -- Callback was hit
    local color8 = (gameState == 78 and emu.lagged()) and "red" or "white" -- Loading lag after boss fight
    local color16 = checkFrame16 == emu.framecount() and "red" or "white" -- Boss health hit 0
    local color5 = getRule5Color(frameCount) -- First framerule after checkFrame4
    
	gui.text(0, 10, rule16, color16)
	gui.text(0, 20, rule8, color8)
	gui.text(0, 30, rule4, color4)
    gui.text(0, 40, rule5, color5)
    
    if color4 == "red" then print(rule4) end
    if color8 == "red" then print(rule8) end
    if color16 == "red" then print(rule16) end
    if color5 == "red" then print(rule5) end
    
    prevEmuFrameCount = emu.framecount()
end
emu.registerafter(main)

local function frameruleCallback()
    hitCallback = true
end

local function wilyBossHealthFrameruleCallback()
    local stageNum = memory.readbyte(0x2A)
    
    -- Stage 10 == Wily 3. Guts Tank doesn't have this framerule.
    if stageNum ~= 10 then
        hitCallback = true
    end
end

-- This is EXTREMELY Mega Man 2 specific, sadly. I happen to know that it uses the MMC1 mode
-- that always maps F to $C000 - $FFFF and swaps 0 - E into $8000 - $BFFF. I also happen to know
-- that is uses $29 as an in-memory mirror for the current low-address bank number.
-- Could be onto something good here if we could read the mapper state.
-- FCEUX has an internal function that provides this information; should expose it to Lua.
local function getBank()
    local pc = memory.getregister("PC")
    
    if pc >= 0xC000 then
        return 0xF
    else
        return memory.readbyte(0x29)
    end
end

-- I plan to add this as an actual callback in FCEUX
local function bankDecorator(address, bank, callback)
    return function()
        if getBank() == bank then
            callback(address, bank)
        end
    end
end

local function registerAddressBanked(address, bank, callback)
    memory.registerexec(address, bankDecorator(address, bank, callback))
end

--[[
    These three addresses are the start of framerule-causing routines.
    They each look something like:
      LDA frame_count
      AND #3
      BNE +
      INC boss_health
    +:
      RTS
]]
registerAddressBanked(0x812F, 0xB, frameruleCallback) -- Boss health fill up
registerAddressBanked(0xA118, 0xB, wilyBossHealthFrameruleCallback) -- Wily boss health fill up
registerAddressBanked(0x9981, 0xD, frameruleCallback) -- Wily map screen timer
