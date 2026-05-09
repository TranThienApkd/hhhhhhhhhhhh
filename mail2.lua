-- Mailbox Raw Dump - in toàn bộ cấu trúc
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

d("📬 **MAILBOX DUMP** | `"..plr.Name.."`", 0xffaa00)

local network = require(RS.Library.Client.Network)

-- Deep dump bất kỳ table nào
local function deepDump(t, indent, maxDepth)
    if maxDepth<=0 or type(t)~="table" then return tostring(t):sub(1,30) end
    local lines={}
    for k,v in pairs(t) do
        local key=indent..tostring(k)
        if type(v)=="table" then
            local cnt=0; for _ in pairs(v) do cnt=cnt+1 end
            table.insert(lines, key.." (table["..cnt.."]):")
            if cnt<=20 then
                for _,sub in ipairs({deepDump(v, indent.."  ", maxDepth-1):match("(.*)")}  ) do
                    table.insert(lines, sub)
                end
                -- Inline dump
                local subs={}
                for k2,v2 in pairs(v) do
                    table.insert(subs, "  "..indent..tostring(k2).."="..tostring(v2):sub(1,25))
                    if #subs>=15 then table.insert(subs,"  "..indent.."..."); break end
                end
                for _,s in ipairs(subs) do table.insert(lines,s) end
            end
        else
            table.insert(lines, key.." = "..tostring(v):sub(1,50))
        end
    end
    return table.concat(lines,"\n")
end

-- Invoke Mailbox: Request
local resp, err = network.Invoke("Mailbox: Request")
d("**Mailbox: Request →** type=`"..type(resp).."`  err=`"..tostring(err).."`", 0x5599ff)

if type(resp)=="table" then
    local topKeys={}
    for k,v in pairs(resp) do
        table.insert(topKeys, tostring(k).."=("..type(v)..")")
    end
    d("**Top-level keys:**\n```\n"..table.concat(topKeys,"\n"):sub(1,1000).."\n```", 0x5599ff)

    -- In mỗi entry (tối đa 5)
    local count=0
    for k,v in pairs(resp) do
        count=count+1
        if type(v)=="table" then
            local lines={}
            for k2,v2 in pairs(v) do
                if type(v2)=="table" then
                    local sub={}
                    for k3,v3 in pairs(v2) do
                        table.insert(sub, k3.."="..tostring(v3):sub(1,20))
                        if #sub>=6 then break end
                    end
                    table.insert(lines, "  "..tostring(k2).."={"..table.concat(sub,",").."}")
                else
                    table.insert(lines, "  "..tostring(k2).."="..tostring(v2):sub(1,40))
                end
            end
            d("📩 **Entry["..tostring(k).."]:**\n```\n"..table.concat(lines,"\n").."\n```", 0x00ccff)
        else
            d("📩 Entry["..tostring(k).."]=("..type(v)..") "..tostring(v):sub(1,100), 0x00ccff)
        end
        if count>=5 then d("_(còn "..(function() local n=0; for _ in pairs(resp) do n=n+1 end; return n end)()-5 .." entries nữa)_"); break end
    end
end

-- Hook Inbox Updated
pcall(function()
    Net["Inbox Updated"].OnClientEvent:Connect(function(...)
        local args={...}
        d("🔔 **Inbox Updated** fired! args="..#args, 0x00ff88)
        for i,v in ipairs(args) do
            if type(v)=="table" then
                local lines={}
                for k2,v2 in pairs(v) do
                    table.insert(lines, tostring(k2).."=("..type(v2)..") "..tostring(v2):sub(1,40))
                    if #lines>=15 then break end
                end
                d("arg"..i..":\n```\n"..table.concat(lines,"\n").."\n```", 0x00ff88)
            else
                d("arg"..i.."=("..type(v)..") "..tostring(v):sub(1,80), 0x00ff88)
            end
        end
    end)
end)

d("✅ Hook active – đang theo dõi inbox", 0x00ff88)
while true do wait(60) end
