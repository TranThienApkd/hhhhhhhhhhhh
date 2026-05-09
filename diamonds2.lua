-- PS99 Diamond Monitor - Theo dõi kim cương theo thời gian
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) end

local function fmt(n)
    n=math.floor(n or 0)
    if n>=1e9 then return string.format("%.2fB",n/1e9)
    elseif n>=1e6 then return string.format("%.2fM",n/1e6)
    elseif n>=1e3 then return string.format("%.1fK",n/1e3)
    else return tostring(n) end
end

local ls = plr:FindFirstChild("leaderstats")
if not ls then
    -- Thử WaitForChild ngắn
    ls = plr:WaitForChild("leaderstats", 5)
end
if not ls then d("❌ Không có leaderstats!", 0xff0000) return end

-- Tìm Diamond stat (thử nhiều tên)
local diamondStat = ls:FindFirstChild("Diamonds")
    or ls:FindFirstChild("Diamond")
    or ls:FindFirstChild("Gems")
    or ls:FindFirstChild("Currency")

-- Nếu không tìm theo tên, lấy stat có value lớn nhất
if not diamondStat then
    local biggest, biggestVal = nil, 0
    for _, stat in ipairs(ls:GetChildren()) do
        local v = tonumber(stat.Value) or 0
        if v > biggestVal then biggestVal = v; biggest = stat end
    end
    diamondStat = biggest
end

if not diamondStat then
    -- Dump tất cả children để debug
    local names = {}
    for _, c in ipairs(ls:GetChildren()) do table.insert(names, c.Name.."="..tostring(c.Value)) end
    d("❌ Không xác định được Diamond stat!\nLeaderstats: ```"..table.concat(names,"\n").."```", 0xff0000)
    return
end

d("✅ Tìm thấy stat: **"..diamondStat.Name.."** = "..tostring(diamondStat.Value), 0x00ff00)

-- Đọc tất cả stats ban đầu
local function getAllStats()
    local lines = {}
    for _, stat in ipairs(ls:GetChildren()) do
        table.insert(lines, stat.Name..": **"..fmt(stat.Value or 0).."**")
    end
    return table.concat(lines, "\n")
end

local startDiamonds = diamondStat.Value
local startTime = os.time()

d("💎 **DIAMOND MONITOR**\n**Acc:** `"..plr.Name.."`\n\n"..getAllStats().."\n\n_Đang theo dõi thay đổi..._", 0xffaa00)

-- Theo dõi thay đổi - report mỗi 60s hoặc khi tăng nhiều
local lastReport = diamondStat.Value
local lastTime = os.time()

-- Report khi có thay đổi lớn (>10K)
diamondStat:GetPropertyChangedSignal("Value"):Connect(function()
    local now = diamondStat.Value
    local diff = now - lastReport
    if math.abs(diff) >= 10000 then
        local sign = diff > 0 and "+" or ""
        d("💎 **Diamond Update** | `"..plr.Name.."`\n"..
          "Hiện tại: **"..fmt(now).."**\n"..
          "Thay đổi: **"..sign..fmt(diff).."**\n"..
          "Tổng tăng từ đầu: **"..fmt(now-startDiamonds).."**", 
          diff>0 and 0x00ff88 or 0xff4444)
        lastReport = now
    end
end)

-- Report định kỳ mỗi 5 phút
while true do
    wait(300)
    local now = diamondStat.Value
    local elapsed = os.time() - startTime
    local gained = now - startDiamonds
    local rate = elapsed > 0 and (gained / elapsed * 3600) or 0
    d("📊 **5-min Report** | `"..plr.Name.."`\n"..
      getAllStats().."\n\n"..
      "▲ Tăng từ đầu: **"..fmt(gained).."**\n"..
      "⚡ Tốc độ: **"..fmt(rate).."/hr**\n"..
      "⏱️ Đã chạy: **"..math.floor(elapsed/60).." phút**", 0x00ccff)
end
