-- エンダータートル整地システム（エンダーチェストなし版）
local TARGET_Y = 63
local FILL_Y = 62

-- シンプルログ
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
            return {x=x, y=y, z=z}
        end
    end
    local x, y, z = gps.locate()
    if x and y and z then
        return {x=x, y=y, z=z}
    end
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
    local pos = get_pos()
    if not pos then return false end
    
    -- Y移動
    while pos.y < ty do
        if not safe_move(turtle.up) then return false end
        pos = get_pos(); if not pos then break end
    end
    while pos.y > ty do
        if not safe_move(turtle.down) then return false end
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
                        turtle.turnRight(); return false
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
                        turtle.turnRight(); return false
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
                    turtle.turnRight(); return false
                end
            end
        else
            if not safe_move(turtle.forward) then
                turtle.turnLeft()
                if not safe_move(turtle.forward) then
                    turtle.turnLeft(); turtle.turnLeft()
                    if not safe_move(turtle.forward) then
                        turtle.turnRight(); return false
                    end
                end
            end
        end
        pos = get_pos(); if not pos then break end
    end
    
    return true
end

-- 土チェック
local function has_dirt()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then return true end
    end
    return false
end

local function select_dirt()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and string.find(item.name, "dirt") then return true end
    end
    return false
end

-- 列処理
local function process_col(x, z)
    slog("Processing: " .. x .. "," .. z)
    
    if not move_gps(x, TARGET_Y, z) then
        slog("Move failed, skip"); return false
    end
    
    local cy = TARGET_Y
    if not safe_move(turtle.down) then 
        slog("Initial descent failed"); return false 
    end
    cy = cy - 1
    
    for depth = 1, 126 do
        local has_block, _ = turtle.inspectDown()
        if not has_block then
            -- 土がない場合は作業終了
            if not has_dirt() then
                slog("No dirt left at y=" .. cy)
                -- y=63に戻る
                while cy < TARGET_Y do
                    if not safe_move(turtle.up) then break end
                    cy = cy + 1
                end
                return false
            end
            
            if select_dirt() then
                turtle.placeDown()
                slog("Dirt placed: y=" .. (cy - 1))
            end
        else
            slog("Block found at y=" .. cy)
            break
        end
        
        if not safe_move(turtle.down) then 
            slog("Bottom reached"); break 
        end
        cy = cy - 1
        if cy < -64 then 
            slog("Bedrock reached"); break 
        end
    end
    
    -- y=63に戻る
    while cy < TARGET_Y do
        if not safe_move(turtle.up) then break end
        cy = cy + 1
    end
    
    return true
end

-- メイン
local function main()
    slog("=== Landfill System Start ===")
    slog("Range: (-1786,-143) to (-1287,356)")
    
    local pos = get_pos()
    if not pos then 
        slog("Error: No position available")
        return 
    end
    
    slog("Start pos: " .. pos.x .. "," .. pos.y .. "," .. pos.z)
    
    local count = 0
    local total = 500 * 500
    
    for x = -1786, -1287 do
        slog("X=" .. x .. " start (" .. (-1786 - x + 1) .. "/500)")
        
        for z = -143, 356 do
            if process_col(x, z) then
                count = count + 1
            else
                -- 土不足で作業終了
                if not has_dirt() then
                    slog("=== Work stopped: No dirt left ===")
                    slog("Completed columns: " .. count .. "/" .. total)
                    return
                end
            end
            
            if count % 100 == 0 then
                local progress = math.floor((count / total) * 100)
                slog("Progress: " .. count .. "/" .. total .. " (" .. progress .. "%)")
            end
        end
        
        slog("X=" .. x .. " complete (total: " .. count .. " columns)")
    end
    
    slog("=== Landfill complete ===")
    slog("Total columns: " .. count .. "/" .. total)
    slog("Completion: " .. math.floor((count / total) * 100) .. "%")
end

-- 実行
if fs.exists("log.txt") then fs.delete("log.txt") end
slog("EnderModem Landfill System")
slog("No EnderChest needed - uses inventory dirt only")
slog("Starting in 5 seconds...")
os.sleep(5)
main()