-- PS99_GetIDs.lua
-- Lấy toàn bộ item ID (string) từ catalog PS99
-- Upload lên Hastebin → gửi link vào Discord (1 message duy nhất)

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer

local WEBHOOK = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU"

-- Helper gửi Discord đơn giản
local function ping(title, desc, color)
    pcall(function()
        request({
            Url = WEBHOOK, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{title=title, description=desc, color=color or 0xffaa00}}
            }),
        })
    end)
end

-- ============================================================
-- THÔNG BÁO BẮT ĐẦU
-- ============================================================
ping("🟡 BẮT ĐẦU", "**User:** "..plr.Name.."\n**Đang quét catalog PS99...**", 0xffaa00)
print("[PS99] BẮT ĐẦU")

-- ============================================================
-- THU THẬP ID TỪ CATALOG (id là STRING - tên loại item)
-- uid là NUMBER trong inventory, dùng khi gửi mail
-- ============================================================
-- ============================================================
-- PHẦN 1: CATALOG – lấy id (STRING) = tên loại vật phẩm
-- Dùng để: hiển thị trên web, tìm RAP
-- ============================================================
local catalogLines = {}
local total = 0

local categories = {"Pets","Eggs","Charms","Enchant","Enchants",
    "Potion","Potions","Misc","Hoverboard","Hoverboards",
    "Booth","Booths","Ultimate","Ultimates","Charm"}

for _, catName in ipairs(categories) do
    local moduleRef = RS.Library.Directory:FindFirstChild(catName)
    if moduleRef then
        local ok, data = pcall(require, moduleRef)
        if ok and typeof(data) == "table" then
            local count = 0
            for itemId, _ in pairs(data) do
                if typeof(itemId) == "string" then
                    table.insert(catalogLines, catName.."|"..itemId)
                    count = count + 1
                    total = total + 1
                end
            end
            print("[PS99] CATALOG", catName, count, "items")
        else
            print("[PS99] CATALOG SKIP:", catName, tostring(data))
        end
    end
end

-- ============================================================
-- PHẦN 2: INVENTORY – lấy uid (NUMBER) = ID gửi Mailbox
-- Dùng để: gọi network.Invoke("Mailbox: Send", ..., uid, ...)
-- ============================================================
local inventoryLines = {}
local GetSave = function()
    return require(RS.Library.Client.Save).Get()
end

local ok2, save = pcall(function() return GetSave().Inventory end)
if ok2 and save then
    local invCats = {"Pet","Egg","Charm","Enchant","Potion","Misc","Hoverboard","Booth","Ultimate"}
    for _, catName in ipairs(invCats) do
        local bag = save[catName]
        if bag and typeof(bag) == "table" then
            local count = 0
            for uid, item in pairs(bag) do
                -- uid = NUMBER (dùng khi gửi mail)
                -- item.id = STRING (tên loại vật phẩm)
                if typeof(uid) == "number" and typeof(item) == "table" and item.id then
                    local prefix = ""
                    if item.pt == 1 then prefix = "Golden_" elseif item.pt == 2 then prefix = "Rainbow_" end
                    if item.sh then prefix = "Shiny_" .. prefix end
                    table.insert(inventoryLines,
                        string.format("%s|uid:%d|id:%s%s|qty:%d",
                            catName, uid, prefix, item.id, item._am or 1))
                    count = count + 1
                end
            end
            print("[PS99] INVENTORY", catName, count, "items")
        end
    end
else
    print("[PS99] INVENTORY: Không lấy được save data:", tostring(save))
end

-- Gộp cả 2 phần thành 1 output
local lines = {}
table.insert(lines, "=== CATALOG (id - string) ===")
for _, l in ipairs(catalogLines) do table.insert(lines, l) end
table.insert(lines, "")
table.insert(lines, "=== INVENTORY (uid - number) ===")
for _, l in ipairs(inventoryLines) do table.insert(lines, l) end

-- ============================================================
-- NẾU KHÔNG TÌM ĐƯỢC -> fallback: quét toàn bộ Directory
-- ============================================================
if total == 0 then
    print("[PS99] Thử quét toàn bộ RS.Library.Directory...")
    local dirFolder = RS.Library:FindFirstChild("Directory")
    if dirFolder then
        for _, mod in ipairs(dirFolder:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, data = pcall(require, mod)
                if ok and typeof(data) == "table" then
                    for itemId, _ in pairs(data) do
                        if typeof(itemId) == "string" then
                            table.insert(lines, mod.Name.."|"..itemId)
                            total = total + 1
                        end
                    end
                    print("[PS99]", mod.Name, "OK")
                end
            end
        end
    end
end

-- ============================================================
-- UPLOAD LÊN HASTEBIN → GỬI LINK VÀO DISCORD
-- ============================================================
table.sort(lines)
local content = table.concat(lines, "\n")

if total > 0 then
    -- Upload lên Hastebin
    local hasteUrl = ""
    local ok, resp = pcall(function()
        return request({
            Url    = "https://hastebin.com/documents",
            Method = "POST",
            Body   = content,
            Headers = {["Content-Type"] = "text/plain"},
        })
    end)

    if ok and resp and resp.Body then
        local parsed = HttpService:JSONDecode(resp.Body)
        if parsed and parsed.key then
            hasteUrl = "https://hastebin.com/"..parsed.key
        end
    end

    local desc = string.format(
        "**User:** %s\n**Tổng item:** %d\n**Link file:** %s",
        plr.Name, total,
        hasteUrl ~= "" and hasteUrl or "*(Upload thất bại – xem console)*"
    )
    ping("✅ HOÀN THÀNH", desc, 0x00ff00)
    print("[PS99] HOÀN THÀNH -", total, "items")
    if hasteUrl ~= "" then
        print("[PS99] Link:", hasteUrl)
    end
else
    -- Gửi cấu trúc RS để debug
    local rsDebug = {}
    for _, child in ipairs(RS:GetDescendants()) do
        if child:IsA("ModuleScript") and child:FindFirstAncestor("Directory") then
            table.insert(rsDebug, child:GetFullName())
        end
    end
    local debugText = #rsDebug > 0
        and table.concat(rsDebug, "\n")
        or "Không tìm thấy bất kỳ ModuleScript nào trong Directory!"

    ping("❌ THẤT BẠI – RS Debug", "```\n"..debugText:sub(1,1800).."\n```", 0xff0000)
    print("[PS99] THẤT BẠI\n"..debugText)
end
