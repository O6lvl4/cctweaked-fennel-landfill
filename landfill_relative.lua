-- タートル用自動整地システム（相対移動版）
-- 指定範囲をy63フラットに整地し、y62以下は土で埋め立て

-- 定数定義
local TARGET_Y = 63
local FILL_Y = 62
local AREA = {
    width = 500,   -- X方向の幅
    depth = 500    -- Z方向の奥行き
}

-- 現在位置追跡
local position = {
    x = 0,  -- 開始位置を原点とする
    y = 0,  -- 開始位置を原点とする  
    z = 0,  -- 開始位置を原点とする
    facing = 0  -- 0=北, 1=東, 2=南, 3=西
}

-- 方向管理
local function turn_right()
    turtle.turnRight()
    position.facing = (position.facing + 1) % 4
    print("右転回 - 現在方向: " .. position.facing)
end

local function turn_left()
    turtle.turnLeft()
    position.facing = (position.facing - 1) % 4
    if position.facing < 0 then position.facing = 3 end
    print("左転回 - 現在方向: " .. position.facing)
end

-- 指定方向に向く
local function face_direction(target_facing)
    while position.facing ~= target_facing do
        turn_right()
    end
end

-- 安全な移動
local function safe_forward()
    if not turtle.forward() then
        turtle.dig()
        if not turtle.forward() then
            print("前進失敗")
            return false
        end
    end
    
    -- 位置更新
    if position.facing == 0 then      -- 北 (-Z)
        position.z = position.z - 1
    elseif position.facing == 1 then  -- 東 (+X) 
        position.x = position.x + 1
    elseif position.facing == 2 then  -- 南 (+Z)
        position.z = position.z + 1
    elseif position.facing == 3 then  -- 西 (-X)
        position.x = position.x - 1
    end
    
    return true
end

local function safe_up()
    if not turtle.up() then
        turtle.digUp()
        turtle.up()
    end
    position.y = position.y + 1
    return true
end

local function safe_down()
    if not turtle.down() then
        turtle.digDown()
        turtle.down()
    end
    position.y = position.y - 1
    return true
end

-- 相対移動システム
local function move_to_relative(target_x, target_y, target_z)
    print("目標位置: " .. target_x .. ", " .. target_y .. ", " .. target_z)
    print("現在位置: " .. position.x .. ", " .. position.y .. ", " .. position.z)
    
    -- Y軸移動（高度調整）
    while position.y < target_y do
        safe_up()
        os.sleep(0.1)
    end
    
    while position.y > target_y do
        safe_down()
        os.sleep(0.1)
    end
    
    -- X軸移動
    while position.x ~= target_x do
        if position.x < target_x then
            face_direction(1)  -- 東向き
        else
            face_direction(3)  -- 西向き
        end
        
        if not safe_forward() then
            print("X軸移動失敗")
            return false
        end
        os.sleep(0.1)
    end
    
    -- Z軸移動
    while position.z ~= target_z do
        if position.z < target_z then
            face_direction(2)  -- 南向き
        else
            face_direction(0)  -- 北向き
        end
        
        if not safe_forward() then
            print("Z軸移動失敗")
            return false
        end
        os.sleep(0.1)
    end
    
    print("目標位置到達: " .. target_x .. ", " .. target_y .. ", " .. target_z)
    return true
end

-- ブロック検知関数
local function detect_block(direction)
    if direction == "up" then
        return turtle.detectUp()
    elseif direction == "down" then
        return turtle.detectDown()
    elseif direction == "front" then
        return turtle.detect()
    end
end

-- ブロック配置関数
local function place_block(direction)
    if direction == "up" then
        return turtle.placeUp()
    elseif direction == "down" then
        return turtle.placeDown()
    elseif direction == "front" then
        return turtle.place()
    end
end

-- インベントリに土があるかチェック
local function has_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and (string.find(item.name, "dirt") or string.find(item.name, "土")) then
            return true
        end
    end
    return false
end

-- 土ブロックを選択
local function select_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and (string.find(item.name, "dirt") or string.find(item.name, "土")) then
            return true
        end
    end
    return false
end

-- エンダーチェストから土ブロック補給
local function refill_dirt()
    print("土ブロックを補給中...")
    
    -- 安全な高度に移動
    local safe_y = math.max(position.y + 10, 100)
    move_to_relative(position.x, safe_y, position.z)
    
    -- エンダーチェストを設置
    turtle.select(1)
    if not turtle.placeDown() then
        print("エンダーチェストの設置に失敗")
        return false
    end
    
    -- エンダーチェストから土を取得
    for slot = 2, 16 do
        turtle.select(slot)
        -- 不要なアイテムを預ける
        if turtle.getItemCount() > 0 then
            local item = turtle.getItemDetail()
            if not (item and (string.find(item.name, "dirt") or string.find(item.name, "土") or string.find(item.name, "enderchest"))) then
                turtle.dropDown(64)
            end
        end
        -- 土を取得
        turtle.suckDown(64)
    end
    
    -- エンダーチェストを回収
    turtle.select(1)
    turtle.digDown()
    
    print("補給完了")
    return true
end

-- 指定座標の列処理（シンプル版）
local function process_column(relative_x, relative_z)
    print("列処理開始: x=" .. relative_x .. " z=" .. relative_z)
    
    -- 1. y63に移動
    if not move_to_relative(relative_x, TARGET_Y, relative_z) then
        print("移動失敗、列をスキップ")
        return false
    end
    
    -- 2. y63の下にブロックがあるかチェック
    local has_block_below, _ = turtle.inspectDown()
    if has_block_below then
        print("y63の下にブロック発見、列をスキップ")
        return false
    end
    
    -- 3. 底まで下りる（空洞を探す）
    local bottom_y = TARGET_Y - 1  -- y62から開始
    
    -- 空洞の底を見つける
    while bottom_y > 0 do
        -- 一つ下に移動
        if not safe_down() then
            break
        end
        bottom_y = position.y
        
        -- 足元にブロックがあるかチェック
        local has_ground, _ = turtle.inspectDown()
        if has_ground then
            print("底発見: y=" .. bottom_y)
            break
        end
        
        -- 深すぎる場合は中断
        if bottom_y < -50 then
            print("深すぎるため中断")
            bottom_y = 0
            break
        end
    end
    
    -- 4. 底からy62まで土で埋める
    for target_y = bottom_y, FILL_Y do
        -- 目標の高度に移動
        while position.y < target_y do
            safe_up()
        end
        while position.y > target_y do
            safe_down()
        end
        
        -- 足元にブロックがない場合は土を配置
        local has_block_here, _ = turtle.inspectDown()
        if not has_block_here then
            -- 土が不足している場合は補給
            if not has_dirt() then
                print("土補給中...")
                local current_pos = {x = position.x, y = position.y, z = position.z}
                refill_dirt()
                -- 元の位置に戻る
                move_to_relative(current_pos.x, current_pos.y, current_pos.z)
            end
            
            -- 土を配置
            if select_dirt() then
                place_block("down")
                print("土配置: y=" .. target_y)
            else
                print("土ブロックがありません")
            end
        end
        
        os.sleep(0.05)
    end
    
    -- 5. y63に戻る
    move_to_relative(relative_x, TARGET_Y, relative_z)
    
    return true
end

-- メイン整地ループ
local function main_leveling()
    print("=== タートル整地システム開始（相対移動版） ===")
    print("範囲: " .. AREA.width .. "x" .. AREA.depth .. " ブロック")
    print("開始位置を原点(0,0,0)として処理します")
    
    -- 基本機能確認
    if not turtle.forward then
        print("エラー: タートルが正しく動作していません")
        return
    end
    
    -- 初期補給
    if not refill_dirt() then
        print("エラー: 初期補給に失敗しました")
        return
    end
    
    local processed_columns = 0
    local skipped_columns = 0
    local total_columns = AREA.width * AREA.depth
    
    print("処理予定列数: " .. total_columns)
    
    -- X軸方向にループ
    for x = 0, AREA.width - 1 do
        print("\n=== X=" .. x .. " の処理開始 (" .. (x + 1) .. "/" .. AREA.width .. ") ===")
        
        -- Z軸方向にループ  
        for z = 0, AREA.depth - 1 do
            print("\n列 (" .. x .. ", " .. z .. ") 処理中...")
            
            -- 列処理
            if process_column(x, z) then
                processed_columns = processed_columns + 1
                print("✓ 列 (" .. x .. ", " .. z .. ") 処理完了")
            else
                skipped_columns = skipped_columns + 1
                print("✗ 列 (" .. x .. ", " .. z .. ") スキップ")
            end
            
            -- 10列ごとに進捗表示
            if (processed_columns + skipped_columns) % 10 == 0 then
                local progress = math.floor(((processed_columns + skipped_columns) / total_columns) * 100)
                print("\n--- 進捗 " .. progress .. "% ---")
                print("処理済み: " .. processed_columns .. " | スキップ: " .. skipped_columns .. " | 残り: " .. (total_columns - processed_columns - skipped_columns))
            end
            
            -- 100列ごとに補給
            if (processed_columns + skipped_columns) % 100 == 0 then
                refill_dirt()
            end
        end
        
        print("X=" .. x .. " 完了 (処理済み: " .. processed_columns .. ", スキップ: " .. skipped_columns .. ")")
    end
    
    print("\n=== 整地完了 ===")
    print("処理した列: " .. processed_columns)
    print("スキップした列: " .. skipped_columns)
    print("合計: " .. (processed_columns + skipped_columns))
end

-- 緊急停止機能
local function emergency_stop()
    print("緊急停止 - 現在位置に留まります")
    print("相対位置: " .. position.x .. " " .. position.y .. " " .. position.z)
    print("方向: " .. position.facing)
end

-- 実行開始
print("タートル整地システム（相対移動版）")
print("Ctrl+T で緊急停止")
print("エンダーチェストをスロット1に配置してください")
print("5秒後に開始...")
os.sleep(5)

-- メイン実行
local success, err = pcall(main_leveling)
if not success then
    print("エラー発生: " .. err)
    emergency_stop()
end