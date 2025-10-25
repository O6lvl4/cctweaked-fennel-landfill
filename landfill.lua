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

-- 完全に上昇禁止の設計に変更
-- 各列処理の最後にy=63の次の位置に直接移動

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

-- 土補給（y=63でのみ実行、上昇禁止）
local function refill_dirt()
    if position.y ~= 63 then
        print("エラー: y=63以外での補給は禁止されています")
        return false
    end
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
    return true
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
    
    -- y=63にいることを確認（上昇はしない）
    if position.y ~= 63 then
        print("警告: y=63以外からの開始です。y=" .. position.y)
    end
    
    -- 2. y=63は空気のまま（スキップ条件なし）
    -- y=62以下を全て土で埋める
    
    -- 3. y=62から下向きに全て埋める
    safe_down()  -- y=62に移動
    
    -- y=62から底まで、空いている部分を全て土で埋める
    for depth = 1, 200 do  -- 最大200ブロック下まで
        -- 現在位置にブロックがない場合は足元に土を配置
        local has_block_here, _ = turtle.inspectDown()  -- 足元をチェック
        if not has_block_here then
            -- 土が必要
            if not has_dirt() then
                print("土不足、y=" .. position.y .. "で中断")
                break
            end
            
            -- 足元に土を配置
            if select_dirt() then
                turtle.placeDown()  -- 足元に配置
                print("土配置: y=" .. (position.y - 1))
            end
        end
        
        -- 一つ下に移動
        if not safe_down() then
            print("下移動失敗、底到達")
            break
        end
        
        -- 深すぎる場合は中断
        if position.y < -100 then
            print("深すぎるため中断 y=" .. position.y)
            break
        end
        
        os.sleep(0.02)  -- パフォーマンス向上
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