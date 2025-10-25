-- エンダータートル用自動整地システム
-- 指定範囲をy63フラットに整地し、y62以下は土で埋め立て

-- 定数定義
local TARGET_Y = 63
local FILL_Y = 62
local AREA = {
    min_x = -1786,
    max_x = -1286,
    min_z = -641,
    max_z = -141
}

-- 現在位置取得
local function get_position()
    local x, y, z = gps.locate()
    return {x = x, y = y, z = z}
end

-- 安全な移動関数
local function safe_move(direction)
    local attempts = 0
    while attempts < 10 and not direction() do
        attempts = attempts + 1
        os.sleep(0.1)
    end
    return attempts > 0
end

-- エンダータートル用テレポート移動
local function teleport_to(x, y, z)
    if turtle.teleport(x, y, z) then
        return true
    else
        print("テレポート失敗: " .. x .. " " .. y .. " " .. z)
        return false
    end
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

-- ブロック採掘関数
local function dig_block(direction)
    if direction == "up" then
        return turtle.digUp()
    elseif direction == "down" then
        return turtle.digDown()
    elseif direction == "front" then
        return turtle.dig()
    end
end

-- エンダーチェストから土ブロック補給
local function refill_dirt()
    print("土ブロックを補給中...")
    -- エンダーチェストを設置
    turtle.select(1)
    turtle.placeUp()
    
    -- エンダーチェストを開いて土を取得
    for slot = 2, 16 do
        turtle.select(slot)
        if turtle.getItemCount() > 0 then
            turtle.dropUp(64)  -- 余分なアイテムを預ける
        end
        turtle.suckUp(64)     -- 土を取得
    end
    
    -- エンダーチェストを回収
    turtle.select(1)
    turtle.digUp()
    print("補給完了")
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

-- 指定座標の列処理
local function process_column(x, z)
    print("列処理開始: x=" .. x .. " z=" .. z)
    
    -- y63の位置にテレポート
    if not teleport_to(x, TARGET_Y, z) then
        print("テレポート失敗、列をスキップ")
        return false
    end
    
    -- y63にブロックがあるかチェック
    if detect_block("down") then
        print("y63にブロック発見 (" .. x .. "," .. TARGET_Y .. "," .. z .. ")、列をスキップ")
        return false
    end
    
    -- y62から下に向かって処理
    for y = FILL_Y, 1, -1 do
        teleport_to(x, y, z)
        
        -- 現在位置にブロックがない場合は土を配置
        if not detect_block("down") then
            -- 土が不足している場合は補給
            if not has_dirt() then
                refill_dirt()
            end
            
            -- 土を選択して配置
            if select_dirt() then
                if not place_block("down") then
                    print("配置失敗: " .. x .. " " .. y .. " " .. z)
                end
            else
                print("土ブロックが見つかりません")
            end
        end
        
        os.sleep(0.05)  -- 少し待機
    end
    
    return true
end

-- Y63上のブロッククリア（必要に応じて）
local function clear_above_y63(x, z)
    teleport_to(x, TARGET_Y + 1, z)
    local current_y = TARGET_Y + 1
    
    -- 上方向のブロックを確認・除去
    while current_y < 320 and detect_block("down") do
        dig_block("down")
        current_y = current_y + 1
        teleport_to(x, current_y, z)
        os.sleep(0.05)
    end
end

-- メイン整地ループ
local function main_leveling()
    print("=== エンダータートル整地システム開始 ===")
    print("範囲: x=" .. AREA.min_x .. "~" .. AREA.max_x .. " z=" .. AREA.min_z .. "~" .. AREA.max_z)
    
    -- 初期補給
    refill_dirt()
    
    local processed_columns = 0
    local skipped_columns = 0
    
    -- X軸方向にループ
    for x = AREA.min_x, AREA.max_x do
        print("X=" .. x .. " の処理開始 (" .. (x - AREA.min_x + 1) .. "/" .. (AREA.max_x - AREA.min_x + 1) .. ")")
        
        -- Z軸方向にループ
        for z = AREA.min_z, AREA.max_z do
            -- Y63上のクリア（オプション）
            -- clear_above_y63(x, z)
            
            -- 列処理
            if process_column(x, z) then
                processed_columns = processed_columns + 1
            else
                skipped_columns = skipped_columns + 1
            end
            
            -- 100列ごとに進捗表示
            if (processed_columns + skipped_columns) % 100 == 0 then
                print("進捗: 処理済み=" .. processed_columns .. " スキップ=" .. skipped_columns)
                refill_dirt()  -- 定期的に補給
            end
        end
        
        print("X=" .. x .. " 完了")
    end
    
    print("=== 整地完了 ===")
    print("処理した列: " .. processed_columns)
    print("スキップした列: " .. skipped_columns)
    print("合計: " .. (processed_columns + skipped_columns))
end

-- 緊急停止機能
local function emergency_stop()
    print("緊急停止 - 現在位置に留まります")
    local pos = get_position()
    print("現在位置: " .. pos.x .. " " .. pos.y .. " " .. pos.z)
end

-- 実行開始
print("エンダータートル整地システム")
print("Ctrl+T で緊急停止")
print("5秒後に開始...")
os.sleep(5)

-- メイン実行
local success, err = pcall(main_leveling)
if not success then
    print("エラー発生: " .. err)
    emergency_stop()
end