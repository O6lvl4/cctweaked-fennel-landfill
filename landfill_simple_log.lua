-- エンダータートル整地システム（シンプルログ版）
local TARGET_Y = 63
local FILL_Y = 62

-- 超シンプルログ
local function slog(msg)
    print(msg)
    local f = fs.open("log.txt", "a")
    if f then f.writeLine(msg); f.close() end
end

-- 座標取得
local function get_pos()
    if commands and commands.getBlockPosition then
        local x, y, z = commands.getBlockPosition()
        if x and y and z then
            slog("EM:" .. x .. "," .. y .. "," .. z)
            return {x=x, y=y, z=z}
        end
    end
    local x, y, z = gps.locate()
    if x and y and z then
        slog("GPS:" .. x .. "," .. y .. "," .. z)
        return {x=x, y=y, z=z}
    end
    slog("NO_POS")
    return nil
end

-- 安全移動
local function safe_move(dir)
    local attempts = 0
    while attempts < 10 and not dir() do
        turtle.dig(); turtle.digUp(); turtle.digDown()
        if not dir() then attempts = attempts + 1; os.sleep(0.2) end
    end
    return attempts < 10
end

-- GPS移動
local function move_gps(tx, ty, tz)
    slog("TARGET:" .. tx .. "," .. ty .. "," .. tz)
    local pos = get_pos()
    if not pos then slog("MOVE_FAIL"); return false end
    
    -- Y移動
    while pos.y < ty do
        if not safe_move(turtle.up) then slog("UP_FAIL"); return false end
        pos = get_pos(); if not pos then break end
    end
    while pos.y > ty do
        if not safe_move(turtle.down) then slog("DOWN_FAIL"); return false end
        pos = get_pos(); if not pos then break end
    end
    
    -- X移動
    while pos and pos.x ~= tx do
        if pos.x < tx then
            if not safe_move(turtle.forward) then
                turtle.turnRight()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft(); turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight(); slog("X_FAIL"); return false
                    end
                end
            end
        else
            turtle.turnLeft(); turtle.turnLeft()
            if not safe_move(turtle.forward) then
                turtle.turnRight()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft(); turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight(); slog("X_FAIL"); return false
                    end
                end
            end
        end
        pos = get_pos(); if not pos then break end
    end
    
    -- Z移動
    while pos and pos.z ~= tz do
        if pos.z < tz then
            turtle.turnRight()
            if not safe_move(turtle.forward) then
                turtle.turnLeft(); turtle.turnLeft()
                if not safe_move(turtle.forward) then
                    turtle.turnRight(); slog("Z_FAIL"); return false
                end
            end
        else
            if not safe_move(turtle.forward) then
                turtle.turnLeft()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft(); turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight(); slog("Z_FAIL"); return false
                    end
                end
            end
        end
        pos = get_pos(); if not pos then break end
    end
    
    slog("ARRIVED")
    return true
end

-- 土チェック
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

-- 補給
local function refill()
    slog("REFILL")
    turtle.select(1); turtle.placeDown()
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
    turtle.select(1); turtle.digDown()
end

-- 列処理
local function process_col(x, z)
    slog("COL:" .. x .. "," .. z)
    
    if not move_gps(x, TARGET_Y, z) then
        slog("SKIP"); return false
    end
    
    local cy = TARGET_Y
    if not safe_move(turtle.down) then slog("DESC_FAIL"); return false end
    cy = cy - 1
    
    for depth = 1, 126 do
        local has_block, _ = turtle.inspectDown()
        if not has_block then
            if not has_dirt() then
                slog("LOW_DIRT")
                for i = 1, (TARGET_Y - cy) do
                    if not safe_move(turtle.up) then break end
                end
                refill()
                for i = 1, (TARGET_Y - cy) do
                    if not safe_move(turtle.down) then break end
                end
            end
            
            if select_dirt() then
                turtle.placeDown()
                slog("DIRT:" .. (cy - 1))
            end
        else
            slog("BLOCK:" .. cy); break
        end
        
        if not safe_move(turtle.down) then slog("BOTTOM"); break end
        cy = cy - 1
        if cy < -64 then slog("BEDROCK"); break end
    end
    
    while cy < TARGET_Y do
        if not safe_move(turtle.up) then break end
        cy = cy + 1
    end
    
    return true
end

-- メイン
local function main()
    slog("START")
    local pos = get_pos()
    if not pos then slog("NO_GPS"); return end
    
    refill()
    local count = 0
    
    for x = -1786, -1287 do
        slog("X:" .. x)
        for z = -143, 356 do
            if process_col(x, z) then count = count + 1 end
            if count % 100 == 0 then
                slog("PROGRESS:" .. count)
            end
        end
    end
    
    slog("DONE:" .. count)
end

-- 実行
if fs.exists("log.txt") then fs.delete("log.txt") end
slog("INIT")
os.sleep(5)
main()