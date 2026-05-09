-- PS99 Mailbox Reader FINAL - Đọc inbox đẹp
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.3) end

d("📬 **MAILBOX READER** | `"..plr.Name.."`\n🔄 Đang hook...", 0xffaa00)

local network = require(RS.Library.Client.Network)

local function fmt(n) n=math.floor(tonumber(n) or 0)
    if n>=1e9 then return string.format("%.2fB",n/1e9)
    elseif n>=1e6 then return string.format("%.2fM",n/1e6)
    elseif n>=1e3 then return string.format("%.1fK",n/1e3)
    else return tostring(n) end
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
    for _,mail in pairs(inbox) do
        local p = parseMail(mail)
        if p then table.insert(mails, p) end
    end
    if #mails==0 then return end

    d("📬 **"..#mails.." mail(s)** | `"..plr.Name.."`", 0x5599ff)
    for _,m in ipairs(mails) do
        d(m, 0x00ccff)
    end
end

-- Hook Inbox Updated
local ok = pcall(function()
    Net["Inbox Updated"].OnClientEvent:Connect(function(data)
        processInbox(data)
    end)
end)

d("✅ Hook "..(ok and "OK" or "FAIL").."\n**Mở Hộp thư trong game** để load inbox\nScript tự báo khi có mail mới", 0x00ff88)

while true do wait(60) end
