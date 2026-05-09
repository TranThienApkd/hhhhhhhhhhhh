-- PS99 Mailbox Reader - Đọc tin nhắn, người gửi, kim cương
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

d("📬 **MAILBOX READER** | `"..plr.Name.."`", 0xffaa00)

local network = require(RS.Library.Client.Network)

local function parseMailItem(mail)
    if type(mail)~="table" then return nil end
    local info = {}
    -- Sender
    local sender = mail.from or mail.sender or mail.username or mail.From or mail.Sender or mail.SenderName
    if sender then table.insert(info, "👤 **Từ:** `"..tostring(sender).."`") end
    -- Message
    local msg = mail.message or mail.msg or mail.Message or mail.text or mail.Text
    if msg and #tostring(msg)>0 then table.insert(info, "💬 **Tin:** "..tostring(msg):sub(1,100)) end
    -- Diamonds/Currency
    local dia = mail.diamonds or mail.currency or mail.amount or mail.gems
    if dia then table.insert(info, "💎 **Diamonds:** "..tostring(dia)) end
    -- Items
    local items = mail.items or mail.gifts or mail.pets
    if type(items)=="table" then
        local cnt=0; for _ in pairs(items) do cnt=cnt+1 end
        if cnt>0 then table.insert(info, "🎁 **Items:** "..cnt.." món") end
    end
    -- Dump tất cả keys còn lại
    local extras={}
    local known={from=1,sender=1,username=1,From=1,Sender=1,SenderName=1,
                 message=1,msg=1,Message=1,text=1,Text=1,
                 diamonds=1,currency=1,amount=1,gems=1,
                 items=1,gifts=1,pets=1}
    for k,v in pairs(mail) do
        if not known[k] and type(v)~="table" then
            table.insert(extras, tostring(k).."="..tostring(v):sub(1,30))
        end
    end
    if #extras>0 then table.insert(info, "📋 "..table.concat(extras," | ")) end
    return #info>0 and table.concat(info,"\n") or nil
end

-- =====================================================
-- CÁCH 1: network.Invoke("Mailbox: Request")
-- =====================================================
d("🔄 Request Mailbox data...", 0xffaa00)
local resp, err = network.Invoke("Mailbox: Request")
if resp ~= nil then
    d("✅ **Mailbox: Request** response:\ntype=`"..type(resp).."`", 0x00ff88)
    if type(resp)=="table" then
        local cnt=0; for _ in pairs(resp) do cnt=cnt+1 end
        d("📦 "..cnt.." entries trong mailbox", 0x5599ff)
        local mailCount=0
        for k,v in pairs(resp) do
            if type(v)=="table" then
                mailCount=mailCount+1
                local parsed=parseMailItem(v)
                if parsed then
                    d("📩 **Mail #"..mailCount..":**\n"..parsed, 0x00ccff)
                else
                    -- dump raw
                    local raw={}
                    for k2,v2 in pairs(v) do
                        table.insert(raw, tostring(k2).."=["..type(v2).."]"..tostring(v2):sub(1,30))
                        if #raw>=10 then break end
                    end
                    d("📩 **Mail #"..mailCount.." (raw):**\n```\n"..table.concat(raw,"\n").."\n```", 0x00ccff)
                end
                if mailCount>=10 then d("_(còn "..cnt-10 .." mails nữa...)_"); break end
            end
        end
    end
else
    d("⚠️ Mailbox: Request = nil\nerr=`"..tostring(err).."`", 0xff8800)
end

-- =====================================================
-- CÁCH 2: Hook "Inbox Updated" event (monitor live)
-- =====================================================
d("🔔 **Hook Inbox Updated** – theo dõi mail mới...", 0xffaa00)
pcall(function()
    Net["Inbox Updated"].OnClientEvent:Connect(function(...)
        local args={...}
        d("📬 **Inbox Updated!** (args="..#args..")", 0x00ff88)
        for i,v in ipairs(args) do
            if type(v)=="table" then
                local cnt=0; for _ in pairs(v) do cnt=cnt+1 end
                -- Thử parse từng mail
                local mailNum=0
                for _,mail in pairs(v) do
                    if type(mail)=="table" then
                        mailNum=mailNum+1
                        local parsed=parseMailItem(mail)
                        if parsed then d("📩 **Mail mới #"..mailNum..":**\n"..parsed, 0x00ff88)
                        else
                            local raw={}
                            for k2,v2 in pairs(mail) do
                                table.insert(raw,k2.."=["..type(v2).."]"..tostring(v2):sub(1,25))
                                if #raw>=8 then break end
                            end
                            d("📩 **Mail mới (raw):**\n```\n"..table.concat(raw,"\n").."\n```", 0x00ff88)
                        end
                    end
                end
                if mailNum==0 then
                    -- v là một mail trực tiếp
                    local parsed=parseMailItem(v)
                    if parsed then d("📩 **Mail mới:**\n"..parsed, 0x00ff88) end
                end
            else
                d("arg"..i.."=("..type(v)..") "..tostring(v):sub(1,60), 0x5599ff)
            end
        end
    end)
end)

d("✅ **Hook active!** Script sẽ tự báo khi có mail mới.\n_(Chạy liên tục – script không tự thoát)_", 0x00ff88)

-- Keep alive
while true do wait(60) end
