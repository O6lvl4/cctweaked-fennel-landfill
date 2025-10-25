-- タートル用自動整地システム（超シンプル版）
-- y=63起点、上昇禁止、下降のみ

-- 定数
local TARGET_Y = 63
local FILL_Y = 62

-- 位置追跡（実際の座標）
local position = {x = -1786, y = 63, z = -143, facing = 0}  -- 北向き

-- 方向制御
local function turn_right()
    turtle.turnRight()
    position.facing = (position.facing + 1) % 4
end

local function face_direction(target)
    while position.facing ~= target do
        turn_right()
    end
end

-- 移動（下降のみ）
local function safe_down()
    if turtle.down() then
        position.y = position.y - 1
        return true
    end
    return false
end

local function safe_forward()
    if not turtle.forward() then
        turtle.dig()
        turtle.forward()
    end
    -- 位置更新
    if position.facing == 0 then position.z = position.z - 1
    elseif position.facing == 1 then position.x = position.x + 1
    elseif position.facing == 2 then position.z = position.z + 1
    elseif position.facing == 3 then position.x = position.x - 1 end
end

-- y=63に戻る（上昇は最小限）
local function return_to_63()
    while position.y < 63 do
        turtle.up()
        position.y = position.y + 1
    end
end

-- 土チェック・選択
local function has_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then return true end
    end
    return false
end

local function select_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then return true end
    end
    return false
end

-- 土補給（y=63で実行）
local function refill_dirt()
    return_to_63()  -- y=63に戻る
    print("土補給中...")
    
    turtle.select(1)
    turtle.placeDown()
    
    for slot = 2, 16 do
        turtle.select(slot)
        if turtle.getItemCount() > 0 then
            local item = turtle.getItemDetail()
            if not (item and string.find(item.name, "dirt")) then
                turtle.dropDown(64)
            end
        end
        turtle.suckDown(64)
    end
    
    turtle.select(1)
    turtle.digDown()
    print("補給完了")
end

-- 列処理（超シンプル）
local function process_column(x, z)
    -- 1. 目標位置のy=63に移動
    local move_count = 0
    while position.x ~= x or position.z ~= z do
        move_count = move_count + 1
        if move_count > 1000 then
            print("移動ループが無限ループしています。中断。")
            return false
        end
        if position.x < x then
            face_direction(1); safe_forward()
        elseif position.x > x then
            face_direction(3); safe_forward()
        elseif position.z < z then
            face_direction(2); safe_forward()
        elseif position.z > z then
            face_direction(0); safe_forward()
        end
    end
    
    return_to_63()  -- y=63確保
    
    -- 2. y=63の下にブロックチェック
    local has_block, _ = turtle.inspectDown()
    if has_block then
        print("y=63下にブロック、スキップ")
        return false
    end
    
    -- 3. y=62から下向きに埋め立て
    -- y=62に移動
    safe_down()  -- y=62
    
    -- 下向きに埋め立て
    for depth = 1, 100 do  -- 最大100ブロック下まで
        local has_block_below, _ = turtle.inspectDown()
        if has_block_below then
            print("底到達、埋め立て完了")
            break
        end
        
        -- 土が必要
        if not has_dirt() then
            local save_y = position.y
            refill_dirt()
            -- y=62に戻る
            while position.y > save_y do
                safe_down()
            end
        end
        
        -- 土を配置
        if select_dirt() then
            turtle.placeDown()
            print("土配置: y=" .. (position.y - 1))
        end
        
        -- 一つ下へ
        safe_down()
        
        if position.y < -50 then
            print("深すぎ、中断")
            break
        end
    end
    
    return true
end

-- メイン処理
local function main()
    print("=== 超シンプル整地システム ===")
    print("範囲: (-1786,-143) から (-1287,356) - 500x500ブロック")
    print("開始位置: (" .. position.x .. ", " .. position.y .. ", " .. position.z .. ") 北向き")
    print("y=63からスタート、上昇禁止")
    
    refill_dirt()
    
    local count = 0
    local total = 500 * 500
    
    -- デバッグ用: 最初の3x3ブロックのみテスト
    print("デバッグモード: 3x3ブロックのみテスト")
    
    for x = -1786, -1784 do  -- 3ブロック幅
        for z = -143, -141 do   -- 3ブロック奥行
            print("\n=== 列 (" .. x .. ", " .. z .. ") 処理開始 ===")
            print("現在位置: (" .. position.x .. ", " .. position.y .. ", " .. position.z .. ")")
            
            if process_column(x, z) then
                count = count + 1
                print("✓ 列 (" .. x .. ", " .. z .. ") 成功")
            else
                print("✗ 列 (" .. x .. ", " .. z .. ") 失敗/スキップ")
            end
            
            print("処理後位置: (" .. position.x .. ", " .. position.y .. ", " .. position.z .. ")")
        end
        print("\nX=" .. x .. " 完了")
    end
    
    print("\n=== デバッグテスト完了 ===")
    print("成功した列: " .. count .. "/9")
    print("最終位置: (" .. position.x .. ", " .. position.y .. ", " .. position.z .. ")")
end

-- 実行
print("超シンプル整地システム")
print("タートルを(-1786, 63, -143)に配置してください")
print("本格モード: 500x500ブロックの整地を開始")
print("エンダーチェストをスロット１に配置")
print("Ctrl+Tで停止")
print("5秒後開始...")
os.sleep(5)

main()