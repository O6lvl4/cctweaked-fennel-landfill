-- エンダータートル整地システム（相対座標版）
local TARGET_Y = 63
local FILL_Y = 62

-- 開始座標（手動設定）
local START_X = -1786
local START_Y = 63
local START_Z = -143

-- 現在位置追跡
local pos = {
    x = START_X,
    y = START_Y, 
    z = START_Z,
    facing = 0  -- 0=北(-Z), 1=東(+X), 2=南(+Z), 3=西(-X)
}

-- シンプルログ
local function slog(msg)
    print(msg)
    if fs then
        local f = fs.open("log.txt", "a")
        if f then f.writeLine(msg); f.close() end
    end
end

-- 方向制御
local function turn_right()
    turtle.turnRight()
    pos.facing = (pos.facing + 1) % 4
end

local function turn_left() 
    turtle.turnLeft()
    pos.facing = (pos.facing - 1) % 4
    if pos.facing < 0 then pos.facing = 3 end
end

local function face_direction(target)
    while pos.facing ~= target do
        turn_right()
    end
end

-- 安全移動（強化版）
local function safe_forward()
    local attempts = 0
    while attempts < 10 and not turtle.forward() do
        -- ブロックを掘る
        turtle.dig()
        -- 上のブロックも掘る（背の高いブロック対策）
        turtle.digUp()
        -- 少し待つ
        os.sleep(0.1)
        attempts = attempts + 1
    end
    
    if attempts >= 10 then
        slog("Forward blocked after " .. attempts .. " attempts")
        return false
    end
    
    -- 位置更新
    if pos.facing == 0 then      -- 北 (-Z)
        pos.z = pos.z - 1
    elseif pos.facing == 1 then  -- 東 (+X)
        pos.x = pos.x + 1
    elseif pos.facing == 2 then  -- 南 (+Z)
        pos.z = pos.z + 1
    elseif pos.facing == 3 then  -- 西 (-X)
        pos.x = pos.x - 1
    end
    
    return true
end

local function safe_up()
    local attempts = 0
    while attempts < 10 and not turtle.up() do
        turtle.digUp()
        os.sleep(0.1)
        attempts = attempts + 1
    end
    if attempts >= 10 then
        slog("Up blocked after " .. attempts .. " attempts")
        return false
    end
    pos.y = pos.y + 1
    return true
end

local function safe_down()
    local attempts = 0
    while attempts < 10 and not turtle.down() do
        turtle.digDown()
        os.sleep(0.1)
        attempts = attempts + 1
    end
    if attempts >= 10 then
        slog("Down blocked after " .. attempts .. " attempts")
        return false
    end
    pos.y = pos.y - 1
    return true
end

-- 相対移動
local function move_to(tx, ty, tz)
    slog("Moving to: " .. tx .. "," .. ty .. "," .. tz)
    
    -- Y軸移動
    while pos.y < ty do
        if not safe_up() then return false end
        os.sleep(0.1)
    end
    while pos.y > ty do
        if not safe_down() then return false end
        os.sleep(0.1)
    end
    
    -- X軸移動
    while pos.x ~= tx do
        if pos.x < tx then
            face_direction(1)  -- 東
        else
            face_direction(3)  -- 西
        end
        if not safe_forward() then return false end
        os.sleep(0.1)
    end
    
    -- Z軸移動
    while pos.z ~= tz do
        if pos.z < tz then
            face_direction(2)  -- 南
        else
            face_direction(0)  -- 北
        end
        if not safe_forward() then return false end
        os.sleep(0.1)
    end
    
    slog("Arrived at: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
    return true
end

-- 土関連
local function has_dirt()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then 
            return true 
        end
    end
    return false
end

local function select_dirt()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then 
            return true 
        end
    end
    return false
end

-- 列処理（完全版）
local function process_col(x, z)
    slog("Processing: " .. x .. "," .. z)
    
    -- y=63に移動
    if not move_to(x, TARGET_Y, z) then
        slog("Move failed, skip")
        return false
    end
    
    -- y=62から開始して下向きに完全埋め立て
    local start_y = FILL_Y  -- y=62から開始
    
    -- y=62に移動
    while pos.y > start_y do
        if not safe_down() then
            slog("Cannot reach y=62")
            return false
        end
    end
    
    -- y=62から下に向かって全部埋める
    local current_y = start_y
    
    while current_y >= -64 do  -- bedrockまで
        slog("Checking y=" .. current_y)
        
        -- 現在位置（足元）のブロックをチェック
        local has_block_below, block_data = turtle.inspectDown()
        local is_solid = false
        
        if has_block_below and block_data then
            -- 液体でない固体ブロックかチェック
            if not (string.find(block_data.name, "water") or 
                   string.find(block_data.name, "lava") or
                   string.find(block_data.name, "air")) then
                is_solid = true
                slog("Solid block found below: " .. block_data.name .. " at y=" .. (current_y - 1))
            else
                slog("Liquid/air found below: " .. block_data.name .. " at y=" .. (current_y - 1))
            end
        else
            slog("Air found below at y=" .. (current_y - 1))
        end
        
        -- 足元が空気または液体の場合は土で埋める
        if not is_solid then
            if not has_dirt() then
                slog("No dirt left at y=" .. current_y)
                -- y=63に戻る
                while pos.y < TARGET_Y do
                    if not safe_up() then break end
                end
                return false
            end
            
            -- 土を選択して配置
            if select_dirt() then
                -- 足元の既存ブロックを除去してから土を配置
                turtle.digDown()
                os.sleep(0.1)
                if turtle.placeDown() then
                    slog("Dirt placed below at y=" .. (current_y - 1))
                else
                    slog("Failed to place dirt below at y=" .. (current_y - 1))
                end
            end
        else
            -- 固体ブロックが見つかった場合、この列の処理終了
            slog("Solid ground found, stopping column at y=" .. (current_y - 1))
            break
        end
        
        -- 一つ下に移動
        if not safe_down() then
            slog("Cannot go deeper from y=" .. current_y)
            break
        end
        current_y = current_y - 1
        
        -- bedrock到達チェック
        if current_y < -64 then
            slog("Bedrock level reached")
            break
        end
        
        os.sleep(0.05)
    end
    
    -- y=63に戻る
    slog("Returning to y=63")
    while pos.y < TARGET_Y do
        if not safe_up() then 
            slog("Failed to return to y=63 from y=" .. pos.y)
            break 
        end
    end
    
    return true
end

-- メイン処理
local function main()
    slog("=== Relative Coordinate Landfill System ===")
    slog("Start: " .. START_X .. "," .. START_Y .. "," .. START_Z)
    slog("Range: (-1786,-143) to (-1287,356)")
    
    local count = 0
    local total = 500 * 500
    
    for x = -1786, -1287 do
        slog("X=" .. x .. " start (" .. (-1786 - x + 1) .. "/500)")
        
        for z = -143, 356 do
            if process_col(x, z) then
                count = count + 1
            else
                -- 土不足で終了
                if not has_dirt() then
                    slog("=== Work stopped: No dirt left ===")
                    slog("Final position: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
                    slog("Completed: " .. count .. "/" .. total)
                    return
                end
            end
            
            if count % 100 == 0 then
                local progress = math.floor((count / total) * 100)
                slog("Progress: " .. count .. "/" .. total .. " (" .. progress .. "%)")
                slog("Current pos: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
            end
        end
        
        slog("X=" .. x .. " complete (total: " .. count .. ")")
    end
    
    slog("=== Landfill complete ===")
    slog("Final position: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
    slog("Total: " .. count .. "/" .. total)
end

-- 実行
if fs and fs.exists("log.txt") then fs.delete("log.txt") end
slog("Relative Coordinate Landfill System")
slog("Starting position: " .. START_X .. "," .. START_Y .. "," .. START_Z)
slog("Place turtle at exactly this position facing NORTH")
slog("Starting in 5 seconds...")
os.sleep(5)
main()