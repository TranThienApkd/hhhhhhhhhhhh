-- PS99 Diamond Farm - Auto collect orbs + AutoFarm
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network
local running=true

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) end

d("💎 **DIAMOND FARM BẮT ĐẦU** | `"..plr.Name.."`\nĐang hook Orbs: Collect...", 0xffaa00)

-- =====================================================
-- BƯỚC 1: Hook Orbs: Collect để xem format params
-- =====================================================
local orbFormat = nil
local hookDone = false

-- Hook outgoing (khi game fire Orbs: Collect lên server)
-- Dùng hookfunction hoặc newcclosure nếu executor hỗ trợ
local origNamecall
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall

-- Thử hook __namecall để bắt :FireServer calls
local hookOk = pcall(function()
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == Net["Orbs: Collect"] then
            local args = {...}
            if not hookDone then
                hookDone = true
                orbFormat = args
                -- Log format
                local info = "Format args: "..#args
                for i,v in ipairs(args) do info=info.."\narg"..i.."="..type(v).." "..tostring(v):sub(1,30) end
                d("🔍 **Orbs: Collect format:**\n```\n"..info.."\n```", 0x5599ff)
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

if hookOk then
    d("✅ __namecall hook OK – chạy vài giây rồi học format...", 0x00ff00)
else
    d("⚠️ Hook thất bại – thử cách khác", 0xff8800)
end

-- =====================================================
-- BƯỚC 2: Enable AutoFarm (tự break blocks)
-- =====================================================
d("🔄 Enable **AutoFarm**...", 0xffaa00)
local afOk = pcall(function()
    Net["AutoFarm_Enable"]:FireServer()
end)
if afOk then
    d("✅ AutoFarm enabled!", 0x00ff00)
else
    d("⚠️ AutoFarm_Enable thất bại", 0xff8800)
end

-- =====================================================
-- BƯỚC 3: Auto-collect Orbs trong workspace
-- Tìm tất cả orb instances và fire Orbs: Collect
-- =====================================================
d("💫 **Auto-collect orbs bắt đầu...**", 0x00ccff)

local collected = 0
local lastReport = 0

local function findAndCollect()
    -- Tìm orb instances trong workspace (thử nhiều tên)
    local orbNames = {"Orb", "Coin", "Diamond", "Currency", "Drop", "Collect"}
    for _, obj in ipairs(WS:GetDescendants()) do
        local n = obj.Name:lower()
        local cn = obj.ClassName
        -- Orbs thường là Part hoặc Model với tên chứa từ khoá
        if cn == "Part" or cn == "Model" or cn == "MeshPart" or cn == "BasePart" then
            for _, kw in ipairs(orbNames) do
                if n:find(kw:lower()) then
                    -- Thử fire collect với instance
                    pcall(function()
                        Net["Orbs: Collect"]:FireServer(obj)
                        collected = collected + 1
                    end)
                    -- Thử teleport đến rồi collect
                    pcall(function()
                        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local pos = obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
                            if pos then
                                plr.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
                            end
                        end
                    end)
                    break
                end
            end
        end
    end
end

-- Thử collect lần đầu
findAndCollect()
d("💎 Round 1: "..collected.." orbs collected", 0x00ff88)

-- Loop liên tục
local loopCount = 0
spawn(function()
    while running do
        wait(0.5)
        findAndCollect()
        loopCount = loopCount + 1
        -- Report mỗi 30s
        if loopCount % 60 == 0 then
            d("📊 **Farm status:** "..collected.." orbs | loops="..loopCount, 0x00ccff)
        end
    end
end)

-- =====================================================
-- BƯỚC 4: Thử Orbs: Combine để ghép orbs nhỏ
-- =====================================================
wait(3)
pcall(function() Net["Orbs: Combine"]:FireServer() end)

d("✅ **Farm đang chạy!**\n`running=true` → đang loop\nStop: `running=false` trong console\n\nOrbs collected: "..collected, 0x00ff88)

-- Thử report sau 30s
wait(30)
d("📊 **30s Report:** "..collected.." orbs | AutoFarm=ON", 0x00ccff)
