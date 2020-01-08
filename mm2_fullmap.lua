-- BLOCK TYPES
WALL = 0x40
LADDER = 0x80	-- also water and right conveyor belts
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
MEGAMAN_ID2 = 0x0420
CURRENT_SCREEN = 0x0440
MEGAMAN_X = 0x0460
MEGAMAN_Y = 0x04A0

-- ROM ADDRESSES
TSA_PROPERTIES_START = 0x10
TSA_PROPERTIES_SIZE = 0x500
MAP_START = 0x510
MAP_SIZE = 0x4000

-- SCRIPT CONFIG
WALL_COLOR = "#0000FF77"
FATAL_COLOR = "#FF000077"
LADDER_COLOR = "#00FF0077"

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

function getTSAAt(stage, screen, x, y)
	local block_x = math.floor(x / TSA_COLS_PER_MACRO)
	local block_y = math.floor(y / TSA_ROWS_PER_MACRO)
	local block = getBlockAt(stage, screen, block_x, block_y)
	local TSA = getTSAFromBlock(stage, block, x % TSA_COLS_PER_MACRO, y % TSA_ROWS_PER_MACRO)
	return TSA
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

function getScreenMap(stage, screen)
	local map = {}
	local i, j, x, y, TSA
	for i = 1,NUM_ROWS do
		map[i] = {}
		for j = 1,NUM_COLS+1 do
			TSA = getTSAAt(stage, screen, j-1, i-1)
			map[i][j] = TSA
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
	for i = 1,NUM_ROWS do
		map[i] = {}
		if size1 > 0 then
			for j = 1,size1 do
				map[i][j] = map1[i][(NUM_COLS - size1) + j]
			end
            for j = 1,NUM_COLS-size1 + 1 do
				map[i][size1+j] = map2[i][j]
			end
		else
			for j = 1,NUM_COLS+size1 do
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
    return state==PLAYING or state==BOSS_RUSH or state==LAGGING or state==HEALTH_REFILL or state==LAGGING2
end

function minimap()
    if not validState() then return end
    
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
	local map_left = -16 - map_offset --SCREEN_WIDTH - NUM_COLS * MINI_TILE_SIZE - 2 * MINI_TILE_SIZE
	local map_top = -16 --MINI_TILE_SIZE * 2
    
	for i = 1,NUM_ROWS do
        for j = 1, NUM_COLS + 1 do
            local color
			if isWall(map[i][j]) then
                color = WALL_COLOR
			end
			if isFatal(map[i][j]) then
                color = FATAL_COLOR
			end
			if isLadder(map[i][j]) then
                color = LADDER_COLOR
			end
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
