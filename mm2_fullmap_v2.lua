-- BLOCK TYPES
WALL = 0x40
LADDER = 0x80   -- also water and right conveyor belts
FATAL = 0xC0 -- also ice and left conveyor belts

-- OTHER INFO
TILE_SIZE = 16
NUM_ROWS = 15
NUM_COLS = 16
MACRO_COLS = 8
MACRO_ROWS = 8
TSA_COLS_PER_MACRO = 2
TSA_ROWS_PER_MACRO = 2
NUM_SPRITES = 32
SCREEN_WIDTH = 256
MINI_TILE_SIZE = 16
PLAYING = 178
BOSS_RUSH = 100
LAGGING = 171
LAGGING2 = 149
HEALTH_REFILL = 119
PAUSED = 128
DEAD = 156
MENU = 197
READY = 82

-- RAM ADDRESSES
SCROLL_X = 0x001F
SCROLL_Y = 0x0022
CURRENT_STAGE = 0x002A -- STAGE SELECT = 1,2,3... clockwise starting at bubble man
GAME_STATE = 0x01FE
MEGAMAN_ID = 0x0400
MEGAMAN_ID2 = 0x0420 -- TODO: flags, actually
CURRENT_SCREEN = 0x0440
MEGAMAN_X = 0x0460
MEGAMAN_Y = 0x04A0
SPRITE_OVERRIDES_LENGTH = 0x55
SPRITE_OVERRIDES = 0x56
SPRITE_X_MASKS = 0x0610
SPRITE_Y_MASKS = 0x0630
SPRITE_OVERRIDE_X = 0x0650
SPRITE_OVERRIDE_Y = 0x0670
SPRITE_OVERRIDE_VALUE = 0x04F0
STAGE_TILE_TYPES = 0xCC44

-- ROM ADDRESSES
TSA_PROPERTIES_START = 0x10
TSA_PROPERTIES_SIZE = 0x500
MAP_START = 0x510
MAP_SIZE = 0x4000

-- SCRIPT CONFIG
-- TODO: The stage header actually tells us whether it's ladder, spikes, water, etc. So we can use more colors here.
WALL_COLOR = "#0000FF77"
FATAL_COLOR = "#FF000077"
LADDER_COLOR = "#00FF0077"

local tile_colors = {
    "#0000FF77", -- Ground
    "#00FF0077", -- Ladder
    "#FF000077", -- Spikes
    "#5d8aa877", -- Water
    "#cc000077", -- Right conveyor
    "#ffbf0077", -- Left Conveyor,
    "#f0f8ff77", -- Ice
}

function getBlockAt(stage, screen, x, y)
    local stage_start = stage * MAP_SIZE + MAP_START
    local screen_start = stage_start + MACRO_COLS * MACRO_ROWS * screen
    local address = screen_start + x * MACRO_ROWS + y
    return rom.readbyte(address)
end

function getTSAArrayFromBlock(stage, block)
    local stage_start = stage * MAP_SIZE + TSA_PROPERTIES_START
    local address = stage_start + block * TSA_COLS_PER_MACRO * TSA_ROWS_PER_MACRO
    return {rom.readbyte(address), rom.readbyte(address + 1), rom.readbyte(address + 2), rom.readbyte(address + 3)} 
end

function getTSAFromBlock(stage, block, x, y)
    local TSAArray = getTSAArrayFromBlock(stage, block)
    return TSAArray[x * TSA_ROWS_PER_MACRO + y + 1]
end

function getBgOverride(screen, x, y)
    local x_pixel = x * 16
    local y_pixel = y * 16
    local num_solid_sprites = memory.readbyte(SPRITE_OVERRIDES_LENGTH)
    for i = 0, num_solid_sprites - 1 do
        local sprite_offset = memory.readbyte(SPRITE_OVERRIDES + i)
        local collision_mask_x = memory.readbyte(SPRITE_X_MASKS + sprite_offset)
        local sprite_x = memory.readbyte(SPRITE_OVERRIDE_X + sprite_offset)
        local collision_mask_y = memory.readbyte(SPRITE_Y_MASKS + sprite_offset)
        local sprite_y = memory.readbyte(SPRITE_OVERRIDE_Y + sprite_offset)
        
        -- Vanilla game uses F0 (1 block) and C0 (4 blocks) for these masks.
        -- But this script ought to support anything that's a whole number of blocks! i.e. lower nyble == 0.
        if bit.band(collision_mask_x, 0xF0) ~= collision_mask_x or bit.band(collision_mask_y, 0xF0) ~= collision_mask_y then 
            gui.text(10, 10, string.format("sprite #%02X is non block-aligned! (%02X, %02X)", sprite_offset, collision_mask_x, collision_mask_y))
            return
        end
        
        if bit.band(x_pixel, collision_mask_x) == sprite_x and bit.band(y_pixel, collision_mask_y) == sprite_y then
            return memory.readbyte(SPRITE_OVERRIDE_VALUE + sprite_offset)
        end
    end
end

function getTileAt(stage, screen, x, y)
    local override = getBgOverride(screen, x, y)
    if override then return override end
    
    local block_x = math.floor(x / TSA_COLS_PER_MACRO)
    local block_y = math.floor(y / TSA_ROWS_PER_MACRO)
    local block = getBlockAt(stage, screen, block_x, block_y)
    local TSA = getTSAFromBlock(stage, block, x % TSA_COLS_PER_MACRO, y % TSA_ROWS_PER_MACRO)
    local tile_type = bit.rshift(TSA, 6)
    if tile_type <= 1 then
        return tile_type
    else
        return memory.readbyte(STAGE_TILE_TYPES + 2 * stage + tile_type - 2)
    end
end

function isWall(TSA)
    return AND(TSA, 0xC0) == WALL
end

function isFatal(TSA)
    return AND(TSA, 0xC0) == FATAL
end

function isLadder(TSA)
    return AND(TSA, 0xC0) == LADDER
end

function isFree(TSA)
    return AND(TSA, 0xC0) == 0
end

-- TODO: Get the collision overrides used by yoku blocks and Crash walls.
function getScreenMap(stage, screen)
    local map = {}
    local i, j, x, y, tile
    for i = 1,NUM_ROWS do
        map[i] = {}
        for j = 1,NUM_COLS+1 do
            tile = getTileAt(stage, screen, j-1, i-1)
            map[i][j] = tile
        end
    end
    return map
end

local current_scroll_x = memory.readbyte(SCROLL_X)
local previous_scroll_x = current_scroll_x

-- TODO: Why is Mega Man's position used here at all? Just get 2 screens of map and offset it.
function getMap(stage, screen)
    local map1 = getScreenMap(stage, screen - 1)
    local map2 = getScreenMap(stage, screen)
    local map3 = getScreenMap(stage, screen + 1)
    
    local scrollx = previous_scroll_x
    local mmtilex = math.floor((scrollx+128)%256 / TILE_SIZE)
    local size1 = math.floor((NUM_COLS)/2) - mmtilex

    local map = {}
    for i = 1, NUM_ROWS do
        map[i] = {}
        if size1 > 0 then
            for j = 1, size1 do
                map[i][j] = map1[i][(NUM_COLS - size1) + j]
            end
            for j = 1,NUM_COLS-size1 + 1 do
                map[i][size1+j] = map2[i][j]
            end
        else
            for j = 1, NUM_COLS + size1 do
                map[i][j] = map2[i][j-size1]
            end
            for j = 1, -size1 + 1 do
                map[i][NUM_COLS + size1 + j] = map3[i][j]
            end
        end
        
    end
    return map
end

function validState()
    local state = memory.readbyte(GAME_STATE)
    return state==PLAYING or state==BOSS_RUSH or state==HEALTH_REFILL or state==LAGGING or state==LAGGING2
end

local toggle = true
local prevSelect = false

function minimap()

    -- if joypad.getdown(1).select then
        -- if not prevSelect then toggle = not toggle end
        -- prevSelect = true
    -- else
        -- prevSelect = false
    -- end

    -- Didn't I have some overzip check here at one point? Or did I simply do frame advance video editing?
    if not toggle or not validState() then return end
    
    local current_stage = memory.readbyte(CURRENT_STAGE)
    if current_stage >= 8 then
        current_stage = current_stage - 8
    end
    
    local current_screen = memory.readbyte(CURRENT_SCREEN)
    previous_scroll_x = current_scroll_x
    current_scroll_x = memory.readbyte(SCROLL_X)
    local scroll_x = previous_scroll_x
    local mmx = memory.readbyte(MEGAMAN_X)
    local mmDrawX = math.ceil(AND(mmx + 255 - scroll_x, 255))
    
    if mmDrawX > mmx and scroll_x < 128 then
        current_screen = current_screen - 1
    end
    
    local mmtilex = math.floor(mmx / TILE_SIZE) -- math.floor((scroll_x+128)%256 / TILE_SIZE)
    local map = getMap(current_stage, current_screen)
    local map_offset = scroll_x % 16
    local map_left = -16 - map_offset -- SCREEN_WIDTH - NUM_COLS * MINI_TILE_SIZE - 2 * MINI_TILE_SIZE
    local map_top = -16 -- MINI_TILE_SIZE * 2
    
    for i = 1, NUM_ROWS do
        for j = 1, NUM_COLS + 1 do
            local color =  tile_colors[map[i][j]]
            if color then
                gui.drawbox(
                    map_left + j*MINI_TILE_SIZE, map_top + i*MINI_TILE_SIZE,
                    map_left + j*MINI_TILE_SIZE + MINI_TILE_SIZE, map_top + i*MINI_TILE_SIZE + MINI_TILE_SIZE,
                    color, color)
            end
        end
    end
end
gui.register(minimap)
