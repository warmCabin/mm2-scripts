
local drawBefore = true
local doHitboxes = true
local doSolidSprites = true
local doBgCheck = false
local doDamageTransfer = false
local doHud = false
local doSlots = false

local platformLineMode = true
local drawIntangible = false
local quantumShots = false -- TODO: Use this to only draw hitboxes that will actually collide this frame. Not sure how this interacts with NMI/frameCount variable.

local HITBOX_OFFSET_TABLE = 0xD4DC
local HIT_SIZE_X_TABLE = 0xD4E1
local HIT_SIZE_Y_TABLE = 0xD581
local ENEMY_HIT_SIZE_X_TABLE = 0xD501 -- These two don't acually make sense. It's based on an old misunderstanding that I need to factor out.
local ENEMY_HIT_SIZE_Y_TABLE = 0xD5A1

local function getBaseRom()
    -- A random byte from the wait_for_next_frame routine,
    -- which happens to be the low byte of the read_controllers routine address.
    -- This is the first byte in bank F that diverges between Rockman 2 and Mega Man 2.
    local sentinel = memory.readbyte(0xC093)
    
    if sentinel == 0xD4 then
        return "rm2"
    elseif sentinel == 0xD7 then
        return "mm2"
    end
end

if getBaseRom() == "mm2" then
    -- Only +3. Can ya believe it?
    print("You are playing Mega Man 2.")
    HITBOX_OFFSET_TABLE = HITBOX_OFFSET_TABLE + 3
    HIT_SIZE_X_TABLE = HIT_SIZE_X_TABLE + 3
    HIT_SIZE_Y_TABLE = HIT_SIZE_Y_TABLE + 3
    ENEMY_HIT_SIZE_X_TABLE = ENEMY_HIT_SIZE_X_TABLE + 3
    ENEMY_HIT_SIZE_Y_TABLE = ENEMY_HIT_SIZE_Y_TABLE + 3
else
    print("You are playing Rockman 2.")
end


-- Sprite on sprite action

local function drawHitboxes(start, finish)
    start, finish = start or 0, finish or 0x1F

	local cameraPos = memory.readbyte(0x20)*256+memory.readbyte(0x1F)

    -- Slots A - F aren't checked by the collision routines, so theoretically we can skip them.
    -- There's also the issue that sprites can technically have collision flags set without calling the collision routine, but that's doubtful.
	for i = start, finish do
        local x = memory.readbyte(0x0460 + i)
		local y = memory.readbyte(0x04A0 + i)
        local screenNum = memory.readbyte(0x0440 + i)
        
        local drawX = screenNum * 256 + x - cameraPos
        local hitSizeX, hitSizeY
        local platformSizeX, platformY
        local bg, ol

        local id = memory.readbyte(0x0400 + i)
		local flags = memory.readbyte(0x0420 + i)
        
        --[[
            There are 5 player hitbox types and 32 enemy hitbox types. Rather than storing width and height for each, there is a 5x32 delta matrix
            for each axis that tells you how close together two sprites must be for a collision to count. For example, if I shoot a lemon (projectile type 1)
            and it checks for collisions with a Met (collision type 50), we don't know that the lemon is 7x7 and the Met is 15x15. Instead, we index into the 
            delta matrixes and find that these two sprites' centers must be closer than 12 pixels horizontally and 12 pixels vertically for a collision to count.
            It's weird and I don't like it, but that's how it is.
            
            Finalfighter's original code (which this was copied from long ago) handles this quite elegantly. It adds some constants to the stored delta values
            to come up with reasonable looking absolute box sizes. I'm not sure whether you could solve a system of equations to determine these values emperically,
            or whether you have to take some artistic license.
        ]]
        
		if bit.band(flags, 0x80) ~= 0 then -- Sprite is alive
			if i < 0x10 and i ~= 1 then -- Rockman & projectiles
				local hitboxType = memory.readbyte(0x0590 + i)
				local hitboxOffset = memory.readbyte(HITBOX_OFFSET_TABLE + hitboxType) -- Could just do hitboxType << 5
				hitSizeX = memory.readbyte(HIT_SIZE_X_TABLE + hitboxOffset) - 0xC  + 4
				hitSizeY = memory.readbyte(HIT_SIZE_Y_TABLE + hitboxOffset) - 0x14 + 4
                platformSizeX = memory.readbyte(0x05A0 + i - 2) -- There are just 3 of these, not 1 per sprite slot.
                platformY = memory.readbyte(0x05A3 + i - 2)
			else -- Enemies
				local hitboxType = memory.readbyte(0x06E0 + i)
				--hitSizeX = math.max(0, memory.readbyte(0xD501 + hitboxType) - 4 )
				--hitSizeY = math.max(0, memory.readbyte(0xD5A1 + hitboxType) - 4 )
                -- TODO: finalfighter is using 32 bytes down from the actual base of the table. Fix this to use the actual base and a different subtrahend.
                -- Yes, really. Subtrahend. X would always be 2 more (except box type 15), and Y would always be 4 more, so...
                hitSizeX = memory.readbyte(ENEMY_HIT_SIZE_X_TABLE + hitboxType) - 4
				hitSizeY = memory.readbyte(ENEMY_HIT_SIZE_Y_TABLE + hitboxType) - 4
                platformSizeX = memory.readbyte(0x0150 + i)
                platformY = memory.readbyte(0x0160 + i)
			end
            
            -- TODO: In game, these checks don't care if the sprite is alive.
            --   This can be observed when a pipi despawns one of those Bubble platforms.
            --   They also incorrectly use sprite Y instead of platform Y at one point ($0E:8D39), so there's an extra line to be drawn.
            --   ("Incorrectly," or is this intended behavior to get a range of valid pop-up values?)
            --   Again we face the question. Should this script support glitches, or regular cases only?
            if platformSizeX > 0 and shouldDrawPlatform(i) then
                -- This enemy is a platform

                local mmx = memory.readbyte(0x0440) * 256 + memory.readbyte(0x0460) - cameraPos
                local mmy = memory.readbyte(0x04A0)
                
                if platformLineMode then -- Intuitive collision line
                    gui.line(drawX - platformSizeX + 1 + 7, platformY, drawX + platformSizeX - 1 - 7, platformY, "red")
                    
                    if shouldDrawBox(0, 0) then
                        -- Draw fake detection line
                        gui.line(mmx, mmy + 12, mmx, mmy)
                        gui.line(mmx -7, mmy + 12, mmx + 7, mmy + 12, "green")
                    end
                else -- What the game actually does.
                    gui.line(drawX - platformSizeX + 1, platformY, drawX + platformSizeX - 1, platformY, "red")
                    
                    if shouldDrawBox(0, 0) then
                        -- Draw Mega Man's detection point
                        gui.line(mmx, mmy + 12, mmx, mmy)
                        gui.box(mmx - 1, mmy + 12 - 1, mmx + 1, mmy + 12 + 1, "magenta")
                        gui.pixel(mmx, mmy + 12, "blue")
                    end
                end
            end
            
            local collisionFlags = bit.band(flags, 3)
            
            if shouldDrawBox(i, collisionFlags) then
                local bg, ol
                
                if i > 1 and i < 0x10 then
                    -- Bit 1 (value 2) is used by Mega Man's projectiles to indicate that they need a special update routine, as opposed to standard physics.
                    -- For our purposes, we can ignore this.
                    collisionFlags = bit.band(collisionFlags, 1)
                end
                
                if collisionFlags == 1 then -- Hitbox only
                    bg, ol = "#FF000040", "red"
                elseif collisionFlags == 2 then -- Hurtbox only (this is a somewhat rare case)
                    bg, ol = "#00FF0040", "green"
                elseif collisionFlags == 3 then -- both
                    bg, ol = "#0000FF40", "blue"
                else -- neither
                    bg, ol = "#FFFFFF40", "white"
                end

                --print(string.format("%02X: %d x %d", i, hitSizeX, hitSizeY))
                gui.box(drawX - hitSizeX, y - hitSizeY, drawX + hitSizeX, y + hitSizeY, bg, ol)
                
                -- Draw an inner border if invincible. I was considering an alternate palette of "#FFEF0040","#FFEF00".
                -- Could just replace the regular border color.
                if bit.band(flags, 0x8) ~= 0 then
                    gui.box(drawX - hitSizeX + 1, y - hitSizeY + 1, drawX + hitSizeX - 1, y + hitSizeY - 1, "clear", "white")
                end
                
                -- Draw an inner border for special sprites. All sprites >= this magic number get special callbacks and
                -- do not deal damage. It would be highly unusual for these sprites to have a hurtbox.
                if id >= 0x76 then
                    gui.box(drawX - hitSizeX + 1, y - hitSizeY + 1, drawX + hitSizeX - 1, y + hitSizeY - 1, "clear", "#FFEF00") 
                    -- gui.box(drawX - hitSizeX + 1, y - hitSizeY + 1, drawX + hitSizeX - 1, y + hitSizeY - 1, "clear", "#E0B0FF") 
                end
            end
            
            if doSlots then
                if i < 0x10 then
                    gui.text(math.min(drawX, 240), y, string.format("%02X", i))
                else
                    -- gui.text(math.min(drawX, 240), y, string.format("%02X: %02X", i, memory.readbyte(0xF0 + i))) -- levelID
                    gui.text(math.min(drawX, 240), y, string.format("%02X: %02X", i, id)) -- sprite ID
                end
            end
		end
	end
end

function shouldDrawBox(slot, flags)
    if slot == 0 then return memory.readbyte(0xF9) == 0 end
    
    if drawIntangible then return true end
    
    if slot < 0x10 then
        return bit.band(flags, 1) ~= 0
    else
        return flags ~= 0
    end
end

-- Item 1, 2, and 3 negelect to clear platformY. Weapons with 4 projectiles will overflow
-- the platform width vars and interpret that as size.
-- The game's code skips weapon platform checks if the equipped weapon is not Item 1, 2, or 3,
-- so this never manifests in the actual game.
function shouldDrawPlatform(slot)
    -- Slots 10 - 1F can contain platforms
    if slot >= 0x10 then return true end
    
    -- Bosses use platform values for some other sinister purpose.
    -- Mega Man doesn't use it at all.
    if slot <= 1 then return false end
    
    -- Is Item 1, 2, or 3 equipped
    return memory.readbyte(0xA9) >= 9
end


-- Damage transfer
-- I'm debating whether or not this belongs here at all.
-- Should glitch visualizations go in their own scripts, with more elaborate and specific displays?
-- Should those scripts import this one?

--[[
    In the enemy collision code, it first checks for collisions with Mega Man, then collisions with his bullets.
    The X register is used to store sprite slot. But when Mega Man gets hit, the game spawns a little dust cloud over his head,
    and that uses the X register. That means that the X register is clobbered to wherever the dust cloud spawned, usually slot E.
    Since the collision code expects an enemy slot (10 - 1F), this logic not only goes wrong, it goes MAD. As it happens, what the
    game reads as the hitbox size for slot E is in fact used as the screen X position for the dust cloud, last time it was rendered.
    (the game is not going to update this value until it updates projetiles next frame). So as the code flows into the enemy/bullet
    collision check, it uses this value as a crazy out of bounds hitbox. The corrupted X register also means we're going to get the
    dust cloud's Y pos; however, the correct enemy X pos was already computed before the bug occurred.
      
    In summary:
    
      X coord:   correct enemy position  (precomputed before the bug)
      Y coord:   dust cloud Y pos        (equal to Mega Man's)
      Box size:  dust cloud pos          (out of bounds table index)
      
    This script draws dots at the bugged positions for each enemy (provided the enemy has both a hitbox and hurtbox active),
    plus a green line so you can tell who it belongs to. It also draws the glitchboxes. If you take damage with one of the dots
    inside one of the glitchboxes (and you get the right frame parity), that's a damage transfer.
    
    These hitbox sizes are fairly random, but generally you have to be fairly close to your projectile for it to work. Plus there's
    a 50/50 chance it won't work because of frame parity.
]]

local function drawDamageTransfer()

    local cameraPos = memory.readbyte(0x20)*256+memory.readbyte(0x1F)
    -- Almost always slot E, but a water splash might cause dust to get pushed further up.
    -- I have never seen anything else spawn up there, not even air bubbles or death meatballs.
    local dustSlot = getDustSlot()
    if not dustSlot then return end
    local madBoxOffset = memory.readbyte(0x06E0 + dustSlot)
    
    if doHud then
        gui.text(10, 10, string.format("%02X", madBoxOffset))
        -- Draw messages to show all possible box sizes and which ones are currently available.
        for hitboxType = 0, 4 do
            -- boxOffset will be 0, 0x20, 0x40, 0x60, or 0x80. So if madBoxOffset is at least 0x80, there will be overflows.
            local boxOffset = memory.readbyte(0xD4DC + hitboxType)
            local trueOffset = bit.band(boxOffset + madBoxOffset, 0xFF)
            local msg = string.format("%d: %02Xx%02X (%02X)", hitboxType, memory.readbyte(0xD4E1 + trueOffset), memory.readbyte(0xD581 + trueOffset), trueOffset)
            if containsType(hitboxType) then msg = msg.."*" end
            gui.text(10, 10 * (hitboxType + 2), msg)
        end
        
        local mmx = memory.readbyte(0x0440) * 256 + memory.readbyte(0x0460) - cameraPos
        gui.text(50, 10, string.format("%02X", mmx))
        
        -- Draw projectile slot hitbox sizes in a row
        for i = 0x0592, 0x0596 do
            gui.text(200 + 10 * (i - 0x0592), 10, memory.readbyte(i))
        end
    end

    -- Draw glitchboxes for all projectiles
	for i = 2, 9 do
        local x = memory.readbyte(0x0460 + i)
		local y = memory.readbyte(0x04A0 + i)
        local screenNum = memory.readbyte(0x0440 + i)
        
        local drawX = screenNum * 256 + x - cameraPos
        local hitSizeX, hitSizeY
        local bg, ol

		local flags = memory.readbyte(0x0420 + i)
        
		if bit.band(flags, 0x80) ~= 0 then -- Sprite is alive
            -- The mad box logic reads tables out of bounds and often overflows,
            -- so we can't treat these boxes quite the same as regular boxes.
            local hitboxType = memory.readbyte(0x0590 + i)             -- weapon hitbox type (0-4)
            local boxOffset = memory.readbyte(0xD4DC + hitboxType)     -- offset into delta matrixes
            local trueOffset = bit.band(boxOffset + madBoxOffset, 0xFF)
            
            hitSizeX = memory.readbyte(0xD4E1 + trueOffset)
            hitSizeY = memory.readbyte(0xD581 + trueOffset)
            
            local collisionFlags = bit.band(flags, 3)
            if shouldDrawBox(i, collisionFlags) then
                local bg, ol = "#FFFFFF40", "white"
                gui.box(drawX - hitSizeX, y - hitSizeY, drawX + hitSizeX, y + hitSizeY, bg, ol)
            end
            
           -- gui.text(math.min(drawX, 240), y, string.format("%02X", i))
		end
	end
    
    -- Skip drawing enemy dots if Mega Man is offscreen
    if memory.readbyte(0xF9) ~= 0 then return end
    
    -- Draw enemy dots
    for i = 0x10, 0x1F do
        local x = memory.readbyte(0x0460 + i)
		local y = memory.readbyte(0x04A0 + i)
        local madY = memory.readbyte(0x04A0) -- Use Mega Man Y
        local screenNum = memory.readbyte(0x0440 + i)
        local madScreenNum = memory.readbyte(0x0440)
        
        local drawX = screenNum * 256 + x - cameraPos
        local hitSizeX, hitSizeY = 6, 8
        local bg, ol

		local flags = memory.readbyte(0x0420 + i)
        
		if bit.band(flags, 0x83) == 0x83 then -- Sprite is alive, has active hitbox and hurtbox
            local bg, ol = "#FFFFFF40", "white"
            gui.line(drawX, y, drawX, madY, "green")
            gui.box(drawX - 1, madY - 1, drawX + 1, madY + 1, "red")
            gui.pixel(drawX, madY, "blue")
        end
    end

end

function containsType(t)
    for addr = 0x0592, 0x0596 do
        if memory.readbyte(addr) == t then return true end
    end
end

-- Scan slots E - 2 for an empty slot.
function getDustSlot()

    -- Hardcoded for now because this gets confused when the dust cloud currently exists and I am feeling lazy
    if true then return 0xE end

    for slot = 0xE, 2, -1 do
        local flags = memory.readbyte(0x0420 + slot)
        local id = memory.readbyte(0x0400 + i)
        if bit.band(flags, 0x80) == 0 or id == 0x24 then
            return slot
        end
    end
end


-- Solid sprites

local function drawSolidSprites()

    local cameraPos = 256 * memory.readbyte(0x20) + memory.readbyte(0x1F)
    
    -- Loop through overrides at 0x56. 0x55 = length.
    -- Each entry is a sprite slot. These slots contain standard sprite flags and IDs,
    -- but store override data where velocity and timer values usually go.
    local numSolidSprites = memory.readbyte(0x55)
    for i = 0, numSolidSprites - 1 do
        local slot = memory.readbyte(0x56 + i)
        local flags = memory.readbyte(0x0430 + slot)
        local xMask = memory.readbyte(0x0610 + slot)
        local xPos = memory.readbyte(0x0650 + slot)
        local yMask = memory.readbyte(0x0630 + slot)
        local yPos = memory.readbyte(0x0670 + slot)
        local tileType = memory.readbyte(0x04F0 + slot)
        local screenNum = memory.readbyte(0x0450 + slot) -- Not used in override logic, just drawing.
        
        local drawX = screenNum * 256 + xPos - cameraPos
        -- Inverting the mask is a convenient way to transform it into a box size!
        -- This will be totally wrong if the mask has leading zeroes or zeroes between the ones. e.g. 00111111 or 11011111
        -- Which will never happen in the real game, and...why would you want to do that in a hack?
        if bit.band(flags, 0x80) ~= 0 then
            gui.box(drawX, yPos, drawX + bit.band(bit.bnot(xMask), 0xFF), yPos + bit.band(bit.bnot(yMask), 0xFF))
        end
        --gui.text(drawX, yPos, string.format("%02X", slot))
    end
end

-- BG Collision checks

local bgDotQueue = {}

local function onCollisionCheck()
    -- Get parameters passed to routine
    local xPixel = memory.readbyte(0x8)
    local screenNum = memory.readbyte(0x9)
    local yPixel = memory.readbyte(0xA)
    local offscreen = memory.readbytesigned(0xB)
    
    -- Some logic if the target point is offscreen
    if offscreen < 0 then yPixel = 0 end
    if offscreen > 0 then return end
    
    local cameraPos = memory.readbyte(0x20) * 256 + memory.readbyte(0x1F)
    local drawX = screenNum * 256 + xPixel - cameraPos
    
    table.insert(bgDotQueue, {x = drawX, y = yPixel})
    -- gui.box(drawX - 1, yPixel - 1, drawX + 1, yPixel + 1, "magenta")
    -- gui.pixel(drawX, yPixel, "blue")
end

if doBgCheck then
    -- This is the main entry point for the bg_collision_check routine.
    memory.registerexec(0xCB9F, function()
        onCollisionCheck()
    end)

    -- 0xCBC0 is just after solid sprite overrides. Many places use this.
    memory.registerexec(0xCBC0, function()
        onCollisionCheck()
    end)
end

local function drawBgDots()
    for _, dot in ipairs(bgDotQueue) do
        gui.box(dot.x - 1, dot.y - 1, dot.x + 1, dot.y + 1, "magenta")
        gui.pixel(dot.x, dot.y, "blue")
    end
    bgDotQueue = {}
end


local function postFrame()
    if doSolidSprites then drawSolidSprites() end
	if doHitboxes then drawHitboxes() end
    if doDamageTransfer then drawDamageTransfer() end
    if doBgCheck then drawBgDots() end
end
if drawBefore then
    emu.registerbefore(postFrame)
else
    emu.registerafter(postFrame)
end
