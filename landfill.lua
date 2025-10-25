-- GPS対応エンダータートル整地システム
-- y=63は空気、y=62以下を土で埋め立て

-- 定数
local TARGET_Y = 63
local FILL_Y = 62

-- 座標取得（エンダーモデム/GPS対応）
local function get_position()
    -- 方法1: エンダーモデムで座標取得
    if commands and commands.getBlockPosition then
        local x, y, z = commands.getBlockPosition()
        if x and y and z then
            print("エンダーモデムで座標取得: " .. x .. ", " .. y .. ", " .. z)
            return {x = x, y = y, z = z}
        end
    end
    
    -- 方法2: GPSで座標取得
    local x, y, z = gps.locate()
    if x and y and z then
        print("GPSで座標取得: " .. x .. ", " .. y .. ", " .. z)
        return {x = x, y = y, z = z}
    end
    
    -- 両方失敗
    print("座標取得失敗: エンダーモデムもGPSも利用できません")
    return nil
end

-- 安全な移動
local function safe_move(direction)
    local attempts = 0
    while attempts < 10 and not direction() do
        turtle.dig()
        turtle.digUp()
        turtle.digDown()
        if not direction() then
            attempts = attempts + 1
            os.sleep(0.2)
        end
    end
    return attempts < 10
end

-- GPS座標への移動
local function move_to_gps(target_x, target_y, target_z)
    print("目標: (" .. target_x .. ", " .. target_y .. ", " .. target_z .. ")")
    
    local pos = get_position()
    if not pos then
        print("GPS信号なし、移動失敗")
        return false
    end
    
    print("現在: (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")")
    
    -- Y軸移動
    while pos.y < target_y do
        if not safe_move(turtle.up) then
            print("上移動失敗")
            return false
        end
        pos = get_position()
        if not pos then break end
        os.sleep(0.1)
    end
    
    while pos.y > target_y do
        if not safe_move(turtle.down) then
            print("下移動失敗")
            return false
        end
        pos = get_position()
        if not pos then break end
        os.sleep(0.1)
    end
    
    -- X軸移動
    while pos and pos.x ~= target_x do
        if pos.x < target_x then
            -- 東向き(+X)
            if not safe_move(turtle.forward) then
                turtle.turnRight()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft()
                    turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight()
                        print("X軸移動失敗")
                        return false
                    end
                end
            end
        else
            -- 西向き(-X)
            turtle.turnLeft()
            turtle.turnLeft()
            if not safe_move(turtle.forward) then
                turtle.turnRight()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft()
                    turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight()
                        print("X軸移動失敗")
                        return false
                    end
                end
            end
        end
        pos = get_position()
        if not pos then break end
        os.sleep(0.1)
    end
    
    -- Z軸移動
    while pos and pos.z ~= target_z do
        if pos.z < target_z then
            -- 南向き(+Z)
            turtle.turnRight()
            if not safe_move(turtle.forward) then
                turtle.turnLeft()
                turtle.turnLeft()
                if not safe_move(turtle.forward) then
                    turtle.turnRight()
                    print("Z軸移動失敗")
                    return false
                end
            end
        else
            -- 北向き(-Z)
            if not safe_move(turtle.forward) then
                turtle.turnLeft()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft()
                    turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight()
                        print("Z軸移動失敗")
                        return false
                    end
                end
            end
        end
        pos = get_position()
        if not pos then break end
        os.sleep(0.1)
    end
    
    print("到達: (" .. (pos and pos.x or "?") .. ", " .. (pos and pos.y or "?") .. ", " .. (pos and pos.z or "?") .. ")")
    return true
end

-- 土関連
local function has_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then
            return true
        end
    end
    return false
end

local function select_dirt()
    for slot = 2, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then
            return true
        end
    end
    return false
end

-- エンダーチェスト補給
local function refill_dirt()
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

-- 列処理（GPS+相対移動ハイブリッド）
local function process_column(x, z)
    print("列処理: (" .. x .. ", " .. z .. ")")
    
    -- 1. y=63に移動（GPS使用）
    if not move_to_gps(x, TARGET_Y, z) then
        print("y=63移動失敗、スキップ")
        return false
    end
    
    -- 2. y=62以下を垂直移動で埋める（GPS不要）
    local current_y = TARGET_Y
    
    -- y=62に下りる
    if not safe_move(turtle.down) then
        print("初期下降失敗")
        return false
    end
    current_y = current_y - 1
    
    -- y=62から下向きに埋め立て
    for depth = 1, 126 do  -- y=62からy=-64まで
        -- 足元にブロックがあるかチェック
        local has_block_below, _ = turtle.inspectDown()
        if not has_block_below then
            -- 空洞なので土を配置
            if not has_dirt() then
                print("土不足、y=" .. current_y .. "で中断")
                -- y=63に戻って補給（上昇のみ）
                for i = 1, (TARGET_Y - current_y) do
                    if not safe_move(turtle.up) then
                        print("上昇失敗")
                        return false
                    end
                end
                refill_dirt()
                -- 元の位置に戻る（下降のみ）
                for i = 1, (TARGET_Y - current_y) do
                    if not safe_move(turtle.down) then
                        print("下降失敗")
                        return false
                    end
                end
            end
            
            if select_dirt() then
                turtle.placeDown()
                print("土配置: y=" .. (current_y - 1))
            end
        else
            -- ブロック発見、この深度で終了
            print("ブロック発見、y=" .. current_y .. "で終了")
            break
        end
        
        -- 一つ下に移動
        if not safe_move(turtle.down) then
            print("下降失敗、底到達")
            break
        end
        current_y = current_y - 1
        
        -- 深すぎる場合は中断
        if current_y < -64 then
            print("bedrock到達")
            break
        end
        
        os.sleep(0.02)
    end
    
    -- 3. y=63に戻る（上昇のみ）
    while current_y < TARGET_Y do
        if not safe_move(turtle.up) then
            print("上昇失敗")
            break
        end
        current_y = current_y + 1
    end
    
    return true
end

-- メイン処理
local function main()
    print("=== エンダーモデム対応整地システム ===")
    print("範囲: (-1786,-143) から (-1287,356)")
    
    -- 座標取得確認
    local pos = get_position()
    if not pos then
        print("エラー: 座標を取得できません")
        print("エンダーモデムまたはGPSサーバーが必要です")
        return
    end
    
    print("開始位置: (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")")
    
    -- 初期補給
    refill_dirt()
    
    local count = 0
    local total = 500 * 500
    
    for x = -1786, -1287 do
        print("\nX=" .. x .. " 処理開始 (" .. (-1786 - x + 1) .. "/500)")
        
        for z = -143, 356 do
            if process_column(x, z) then
                count = count + 1
            end
            
            -- 100列ごとに進捗表示
            if count % 100 == 0 then
                local progress = math.floor((count / total) * 100)
                print("進捗: " .. count .. "/" .. total .. " (" .. progress .. "%)")
            end
        end
        
        print("X=" .. x .. " 完了 (累計: " .. count .. "列)")
    end
    
    print("\n=== 整地作業完了 ===")
    print("処理した列: " .. count .. "/" .. total)
    print("完了率: " .. math.floor((count / total) * 100) .. "%")
end

-- 実行
print("エンダーモデム対応整地システム")
print("エンダーモデムまたはGPSサーバーが必要です")
print("エンダーチェストをスロット1に配置")
print("5秒後に開始...")
os.sleep(5)

main()