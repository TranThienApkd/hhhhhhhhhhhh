-- PS99 Mailbox Reader FINAL - Đọc inbox đẹp
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.3) end

d("📬 **MAILBOX READER** | `"..plr.Name.."`\n🔄 Đang hook...", 0xffaa00)

local network = require(RS.Library.Client.Network)

local function fmt(n)
    n = math.floor(tonumber(n) or 0)
    -- Hiện số chính xác có dấu phẩy phân cách (59999 → 59,999)
    local s = tostring(n)
    local result = ""
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then result = result .. "," end
        result = result .. s:sub(i, i)
    end
    return result
end

local function fmtTime(ts)
    if not ts then return "?" end
    -- Hiển thị giờ:phút từ unix timestamp (+7 GMT)
    local t = math.floor(tonumber(ts) or 0) + 7*3600
    local h = math.floor(t/3600) % 24
    local m = math.floor(t/60) % 60
    return string.format("%02d:%02d", h, m)
end

local seenUUID = {}  -- tránh duplicate

local function parseMail(mail)
    if type(mail)~="table" then return nil end
    local uuid = tostring(mail.uuid or "?")
    if seenUUID[uuid] then return nil end
    seenUUID[uuid] = true

    local sender  = tostring(mail.SenderName or mail.sender or "?")
    local message = tostring(mail.Message or mail.message or "")
    local ts      = fmtTime(mail.Timestamp)
    local item    = mail.Item

    -- Parse item
    local itemStr = ""
    if type(item)=="table" then
        local class = tostring(item.class or item.Class or "?")
        local data  = item.data or item.Data
        if type(data)=="table" then
            -- Tìm amount và id
            local id  = data.id or data.Id or class
            local am  = data._am or data.amount or data.Amount or data.Value
            if am then
                itemStr = "💎 **"..fmt(am).."** "..tostring(id)
            else
                -- Dump data
                local sub={}
                for k,v in pairs(data) do
                    table.insert(sub, tostring(k).."="..tostring(v):sub(1,20))
                    if #sub>=6 then break end
                end
                itemStr = class..": {"..table.concat(sub,", ").."}"
            end
        else
            itemStr = class
        end
    end

    return string.format(
        "👤 **%s** · ⏰ %s\n💬 _%s_\n%s\n🆔 `%s`",
        sender, ts,
        #message>0 and message or "_[no message]_",
        #itemStr>0 and itemStr or "📦 No item",
        uuid:sub(1,8).."..."
    )
end

local function processInbox(data)
    if type(data)~="table" then return end
    local inbox = data.Inbox or data.inbox or data
    if type(inbox)~="table" then return end

    local mails={}
    local totalDia=0
    for _,mail in pairs(inbox) do
        local p = parseMail(mail)
        if p then
            table.insert(mails, p)
            -- Cộng dồn diamonds
            if type(mail.Item)=="table" and type(mail.Item.data)=="table" then
                totalDia = totalDia + math.floor(tonumber(mail.Item.data._am or 0))
            end
        end
    end
    if #mails==0 then return end

    d("📬 **"..#mails.." mail(s)** | `"..plr.Name.."`\n💎 Tổng nhận: **"..fmt(totalDia).."**", 0x5599ff)
    for _,m in ipairs(mails) do
        d(m, 0x00ccff)
    end
end

-- Auto Claim All
local function claimAll()
    local resp, err = network.Invoke("Mailbox: Claim All")
    -- Retry nếu bị cooldown
    local retries = 0
    while err == "You must wait 30 seconds before using the mailbox!" and retries < 20 do
        wait(2); retries = retries + 1
        resp, err = network.Invoke("Mailbox: Claim All")
    end
    if resp == true then
        d("✅ **Claim All thành công!**", 0x00ff88)
    elseif err and #tostring(err)>0 then
        d("⚠️ Claim All: `"..tostring(err).."`", 0xff8800)
    end
    return resp, err
end

-- Hook Inbox Updated + auto claim
local ok = pcall(function()
    Net["Inbox Updated"].OnClientEvent:Connect(function(data)
        processInbox(data)
        wait(1)
        claimAll()
    end)
end)

-- Claim ngay khi script chạy
wait(1)
d("🎁 **Auto Claim khi khởi động...**", 0xffaa00)
claimAll()

d("✅ Hook "..(ok and "OK" or "FAIL").." | Auto-claim active\n**Mở Hộp thư** để load inbox + tự nhận quà\n⏱️ Re-claim mỗi 35s", 0x00ff88)

-- Claim định kỳ mỗi 35s
while true do
    wait(35)
    claimAll()
end
