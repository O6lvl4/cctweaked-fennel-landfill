-- デバッグ用簡単テスト
print("=== Debug Test ===")

-- 基本機能チェック
print("1. Turtle API test:")
if turtle then
    print("  turtle API: OK")
    if turtle.forward then print("  forward: OK") else print("  forward: FAIL") end
    if turtle.turnRight then print("  turnRight: OK") else print("  turnRight: FAIL") end
    if turtle.select then print("  select: OK") else print("  select: FAIL") end
else
    print("  turtle API: FAIL - Not a turtle?")
    return
end

-- ファイルシステムチェック
print("2. Filesystem test:")
if fs then
    print("  fs API: OK")
    local f = fs.open("test.txt", "w")
    if f then
        f.writeLine("test")
        f.close()
        print("  file write: OK")
        if fs.exists("test.txt") then
            print("  file exists: OK")
            fs.delete("test.txt")
        else
            print("  file exists: FAIL")
        end
    else
        print("  file write: FAIL")
    end
else
    print("  fs API: FAIL")
end

-- インベントリチェック
print("3. Inventory test:")
local dirt_count = 0
for slot = 1, 16 do
    turtle.select(slot)
    local item = turtle.getItemDetail()
    if item then
        print("  Slot " .. slot .. ": " .. item.name .. " x" .. item.count)
        if string.find(item.name, "dirt") then
            dirt_count = dirt_count + item.count
        end
    end
end
print("  Total dirt: " .. dirt_count)

-- 簡単移動テスト
print("4. Movement test:")
print("  Testing forward movement...")
if turtle.forward() then
    print("  Forward: OK")
    print("  Testing backward...")
    turtle.turnRight()
    turtle.turnRight()
    if turtle.forward() then
        print("  Backward: OK")
        turtle.turnRight()
        turtle.turnRight()
    else
        print("  Backward: FAIL - blocked?")
    end
else
    print("  Forward: FAIL - blocked or no fuel?")
end

-- 燃料チェック
print("5. Fuel test:")
local fuel = turtle.getFuelLevel()
if fuel then
    if fuel == "unlimited" then
        print("  Fuel: Unlimited")
    else
        print("  Fuel: " .. fuel)
        if fuel < 100 then
            print("  WARNING: Low fuel!")
        end
    end
else
    print("  Fuel: Unknown")
end

print("=== Debug Complete ===")
print("If movement failed, check:")
print("1. Blocks in front")
print("2. Fuel level") 
print("3. Turtle permissions")