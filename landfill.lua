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

-- 安全移動
local function safe_forward()
    if not turtle.forward() then
        turtle.dig()
        if not turtle.forward() then
            slog("Forward blocked")
            return false
        end
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
    if not turtle.up() then
        turtle.digUp()
        if not turtle.up() then
            slog("Up blocked")
            return false
        end
    end
    pos.y = pos.y + 1
    return true
end

local function safe_down()
    if not turtle.down() then
        turtle.digDown()
        if not turtle.down() then
            slog("Down blocked") 
            return false
        end
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

-- 列処理
local function process_col(x, z)
    slog("Processing: " .. x .. "," .. z)
    
    -- y=63に移動
    if not move_to(x, TARGET_Y, z) then
        slog("Move failed, skip")
        return false
    end
    
    -- y=62に下りる
    if not safe_down() then
        slog("Initial descent failed")
        return false
    end
    
    -- 下向きに埋め立て
    for depth = 1, 126 do
        local has_block, _ = turtle.inspectDown()
        if not has_block then
            -- 土不足チェック
            if not has_dirt() then
                slog("No dirt left at y=" .. pos.y)
                -- y=63に戻る
                while pos.y < TARGET_Y do
                    if not safe_up() then break end
                end
                return false
            end
            
            if select_dirt() then
                turtle.placeDown()
                slog("Dirt placed: y=" .. (pos.y - 1))
            end
        else
            slog("Block found at y=" .. pos.y)
            break
        end
        
        if not safe_down() then
            slog("Bottom reached")
            break
        end
        
        if pos.y < -64 then
            slog("Bedrock reached")
            break
        end
        
        os.sleep(0.02)
    end
    
    -- y=63に戻る
    while pos.y < TARGET_Y do
        if not safe_up() then break end
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