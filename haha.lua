-- ZapHubCatalogIDs.lua
-- Lấy TOÀN BỘ ID vật phẩm từ catalog của Pet Simulator 99
-- Gửi kết quả tới Discord webhook

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

-- Discord webhook (thay bằng URL của bạn)
local webhook = "https://discord.com/api/webhooks/1502362195713851492/dsHs2vfdFsqse7tgsoL46ys4614t9UsctOntWMDuY-qXO4nFaGwiiqmf1zTba1cVRsJU"

-- ============================================================
-- Danh sách module catalog theo từng category trong PS99
-- ============================================================
local categoryModules = {
    Pets    = RS.Library.Directory.Pets,
    Eggs    = RS.Library.Directory.Eggs,
    Charms  = RS.Library.Directory.Charms,
    Enchant = RS.Library.Directory.Enchant,
    Potion  = RS.Library.Directory.Potion,
    Misc    = RS.Library.Directory.Misc,
    Hoverboard = RS.Library.Directory.Hoverboard,
    Booth   = RS.Library.Directory.Booth,
    Ultimate = RS.Library.Directory.Ultimate,
}

-- ============================================================
-- Thu thập ID từ mỗi module
-- ============================================================
local allItems = {}

for catName, moduleRef in pairs(categoryModules) do
    local ok, catData = pcall(require, moduleRef)
    if ok and typeof(catData) == "table" then
        for id, data in pairs(catData) do
            -- id ở đây là key của bảng (tên vật phẩm string)
            -- data là bảng thông tin chi tiết
            if typeof(id) == "string" then
                table.insert(allItems, {
                    category = catName,
                    id       = id,
                    huge     = (typeof(data) == "table" and data.huge) and true or false,
                    exclusive = (typeof(data) == "table" and data.exclusiveLevel) and true or false,
                })
            end
        end
    else
        warn("[ZapHub] Không thể load module:", catName, catData)
    end
end

-- ============================================================
-- Sắp xếp theo category rồi theo id
-- ============================================================
table.sort(allItems, function(a, b)
    if a.category == b.category then
        return a.id < b.id
    end
    return a.category < b.category
end)

-- ============================================================
-- In ra console
-- ============================================================
print(string.format("--- Game Catalog ID List (%d items) ---", #allItems))
for _, it in ipairs(allItems) do
    local tag = ""
    if it.huge      then tag = tag .. " [HUGE]"      end
    if it.exclusive then tag = tag .. " [EXCLUSIVE]" end
    print(string.format("[%-10s] ID: %-40s%s", it.category, it.id, tag))
end
print("Done. Total items:", #allItems)

-- ============================================================
-- Gửi tới Discord webhook
-- ============================================================
if webhook ~= "" then
    -- Discord giới hạn 2000 ký tự / message -> chia thành nhiều embed
    local CHUNK_SIZE = 50  -- số item mỗi embed
    local chunks = {}
    local current = {}

    for i, it in ipairs(allItems) do
        local tag = ""
        if it.huge      then tag = " [HUGE]"      end
        if it.exclusive then tag = tag .. " [EXCLUSIVE]" end
        table.insert(current,
            string.format("%s | %s%s", it.category, it.id, tag))

        if #current >= CHUNK_SIZE or i == #allItems then
            table.insert(chunks, table.concat(current, "\n"))
            current = {}
        end
    end

    for i, chunk in ipairs(chunks) do
        local payload = {
            embeds = {{
                title       = string.format("Game Catalog ID List (%d/%d)", i, #chunks),
                description = "```\n" .. chunk .. "\n```",
                color       = 0x00ff00,
                footer      = {text = string.format("Total: %d items", #allItems)},
            }}
        }
        local body = HttpService:JSONEncode(payload)
        local ok, err = pcall(function()
            request({
                Url     = webhook,
                Method  = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body    = body,
            })
        end)
        if not ok then
            warn("[ZapHub] Webhook error (chunk "..i.."):", err)
        end
        wait(1) -- tránh rate-limit Discord
    end

    print("[ZapHub] Đã gửi", #chunks, "embed tới Discord.")
end
