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

-- 安全移動（たいまつ対策強化版）
local function safe_forward()
    local attempts = 0
    while attempts < 15 and not turtle.forward() do
        -- 前方・上方・下方を完全掘削（たいまつ対策）
        turtle.dig()
        turtle.digUp()
        turtle.digDown()
        
        -- たいまつドロップ処理のため長めに待機
        os.sleep(0.5)
        
        -- インベントリ満杯チェック＆不要アイテム処理
        for slot = 2, 16 do
            turtle.select(slot)
            local item = turtle.getItemDetail()
            if item and (string.find(item.name, "torch") or 
                        string.find(item.name, "stick") or
                        string.find(item.name, "coal") or
                        not string.find(item.name, "dirt")) then
                -- たいまつ関連・土以外は捨てる
                turtle.drop()
                slog("Dropped item: " .. item.name)
            end
        end
        
        attempts = attempts + 1
    end
    
    if attempts >= 15 then
        slog("Forward blocked after " .. attempts .. " attempts (torch resistance?)")
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
    while attempts < 15 and not turtle.up() do
        -- 上方向の完全掘削（たいまつ対策）
        turtle.digUp()
        turtle.dig()     -- 前方も掘る
        turtle.digDown() -- 下方も掘る
        os.sleep(0.5)    -- たいまつドロップ待機
        attempts = attempts + 1
    end
    if attempts >= 15 then
        slog("Up blocked after " .. attempts .. " attempts (torch resistance?)")
        return false
    end
    pos.y = pos.y + 1
    return true
end

local function safe_down()
    local attempts = 0
    while attempts < 15 and not turtle.down() do
        -- 下方向の完全掘削（たいまつ対策）
        turtle.digDown()
        turtle.dig()     -- 前方も掘る
        turtle.digUp()   -- 上方も掘る
        os.sleep(0.5)    -- たいまつドロップ待機
        attempts = attempts + 1
    end
    if attempts >= 15 then
        slog("Down blocked after " .. attempts .. " attempts (torch resistance?)")
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
    
    -- y=63から開始して下向きに完全埋め立て
    local start_y = TARGET_Y  -- y=63から開始
    
    -- y=63の位置を確認（移動不要）
    if pos.y ~= start_y then
        slog("Position error: expected y=63, got y=" .. pos.y)
        return false
    end
    
    -- ステップ1: 底まで降りて移動距離を記録
    slog("Step 1: Finding bottom and tracking distance")
    
    local start_y = pos.y  -- y=63
    local descent_count = 0  -- 下降回数をカウント
    
    -- y=62から開始して底まで降りる
    if not safe_down() then
        slog("Cannot move down from y=63")
        return false
    end
    descent_count = descent_count + 1
    
    -- 底まで降りる（移動できなくなるまで）
    while descent_count < 200 do  -- 最大200ブロック下まで
        local has_block_below, block_data = turtle.inspectDown()
        local is_solid = false
        
        if has_block_below and block_data then
            -- 固体ブロックかチェック（水や溶岩は固体ではない）
            if not (string.find(block_data.name, "water") or 
                   string.find(block_data.name, "lava") or
                   string.find(block_data.name, "air")) then
                is_solid = true
                slog("Found solid ground: " .. block_data.name .. " at y=" .. (pos.y - 1))
                break
            else
                slog("Found liquid/air: " .. block_data.name .. " at y=" .. (pos.y - 1))
            end
        else
            slog("Found air at y=" .. (pos.y - 1))
        end
        
        -- まだ空洞なので一つ下に移動を試す
        if not safe_down() then
            slog("Cannot go deeper from y=" .. pos.y .. " after " .. descent_count .. " moves")
            break
        end
        descent_count = descent_count + 1
        
        if pos.y < -64 then
            slog("Reached bedrock level")
            break
        end
    end
    
    slog("Descended " .. descent_count .. " blocks, now at y=" .. pos.y)
    
    -- ステップ2: 記録した移動回数分だけ上に移動しながら土を配置
    slog("Step 2: Filling upward for " .. descent_count .. " levels")
    
    local filled_count = 0
    
    for i = 1, descent_count do
        slog("Filling level " .. i .. "/" .. descent_count .. " at y=" .. pos.y)
        
        -- 土不足チェック
        if not has_dirt() then
            slog("No dirt left at level " .. i .. ", filled " .. filled_count .. " blocks")
            return false
        end
        
        -- 一つ上に移動
        if not safe_up() then
            slog("Cannot move up from y=" .. pos.y .. " at level " .. i)
            break
        end
        
        -- 移動後、足元（下）に土を配置（たいまつ対策付き）
        if select_dirt() then
            -- 足元の完全掘削（たいまつ・ブロック除去）
            turtle.digDown()
            turtle.dig()     -- 前方のたいまつも除去
            turtle.digUp()   -- 上方のたいまつも除去
            os.sleep(0.5)    -- たいまつドロップ完了待機
            
            -- 不要アイテム除去（土以外）
            for slot = 2, 16 do
                turtle.select(slot)
                local item = turtle.getItemDetail()
                if item and not string.find(item.name, "dirt") then
                    turtle.drop()
                end
            end
            
            -- 土を再選択して配置
            if select_dirt() then
                if turtle.placeDown() then
                    slog("Dirt placed at y=" .. (pos.y - 1) .. " (level " .. i .. ")")
                    filled_count = filled_count + 1
                else
                    slog("Failed to place dirt at y=" .. (pos.y - 1) .. " (level " .. i .. ")")
                end
            end
        else
            slog("No dirt available at level " .. i)
        end
        
        os.sleep(0.05)
    end
    
    slog("Filling complete: placed " .. filled_count .. " dirt blocks")
    
    slog("Fill complete, reached y=" .. pos.y)
    
    -- y=63を超えている場合は調整
    if pos.y > TARGET_Y then
        slog("Above y=63, moving back down")
        while pos.y > TARGET_Y do
            if not safe_down() then 
                slog("Failed to return to y=63 from y=" .. pos.y)
                break 
            end
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