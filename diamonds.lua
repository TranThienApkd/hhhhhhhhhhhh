-- PS99 - Đọc số lượng kim cương (currency) gửi Discord
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

d("💎 **ĐỌC KIM CƯƠNG** | `"..plr.Name.."`", 0xffaa00)

local results = {}

-- =====================================================
-- CÁCH 1: Leaderstats
-- =====================================================
pcall(function()
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        local info = {}
        for _, stat in ipairs(ls:GetChildren()) do
            table.insert(info, stat.Name.." = "..tostring(stat.Value))
        end
        if #info > 0 then
            table.insert(results, "📊 **Leaderstats:**\n```\n"..table.concat(info,"\n").."\n```")
        end
    else
        table.insert(results, "⚠️ Không có leaderstats")
    end
end)

-- =====================================================
-- CÁCH 2: PlayerGui (các label hiển thị currency)
-- =====================================================
pcall(function()
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    if pg then
        local currencyLabels = {}
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextBox") then
                local txt = obj.Text or ""
                -- Tìm label chứa số lớn (currency thường hiển thị số)
                local num = txt:match("([%d,%.KMBkm]+)")
                if num and #num > 2 and obj.Parent and obj.Parent.Name then
                    table.insert(currencyLabels, obj.Parent.Name.."."..obj.Name.."="..txt:sub(1,20))
                end
            end
        end
        if #currencyLabels > 0 then
            -- Chỉ lấy top 10
            local top = {}
            for i=1,math.min(10,#currencyLabels) do table.insert(top, currencyLabels[i]) end
            table.insert(results, "🖥️ **GUI Labels:**\n```\n"..table.concat(top,"\n").."\n```")
        end
    end
end)

-- =====================================================
-- CÁCH 3: PlayerProfileCmds.GetPlayerData
-- =====================================================
pcall(function()
    local ok,PPC=pcall(require, RS.Library.Client.PlayerProfileCmds)
    if ok then
        local _,data=pcall(PPC.GetPlayerData, plr.UserId)
        if type(data)=="table" then
            local info = {}
            -- Tìm các field số (currency thường là number)
            for k,v in pairs(data) do
                if type(v)=="number" and v > 0 then
                    table.insert(info, tostring(k).." = "..string.format("%.0f",v))
                end
            end
            if #info > 0 then
                table.insert(results, "👤 **PlayerProfile (numbers):**\n```\n"..table.concat(info,"\n").."\n```")
            end
        end
    end
end)

-- =====================================================
-- CÁCH 4: Tìm RemoteFunction trả về currency
-- =====================================================
pcall(function()
    -- Thử RAP_Get2 (Recent Average Price - related to value)
    local rf = RS.Network["RAP_Get2"]
    if rf and rf.ClassName=="RemoteFunction" then
        local ok,data=pcall(function() return rf:InvokeServer() end)
        if ok and data~=nil then
            table.insert(results, "💹 **RAP_Get2:**\n```\n"..tostring(data):sub(1,200).."\n```")
        end
    end
end)

-- =====================================================
-- CÁCH 5: Tìm trong module BoostExchangeCmds hoặc tương tự
-- =====================================================
pcall(function()
    local ok,BC=pcall(require, RS.Library.Client.BlockPartyCmds)
    if ok and type(BC)=="table" then
        local info={}
        for k,v in pairs(BC) do
            if type(v)=="function" then
                local fok,fv=pcall(v)
                if fok and (type(fv)=="number" or type(fv)=="string") then
                    table.insert(info, k.."() = "..tostring(fv))
                end
            end
        end
        if #info>0 then
            table.insert(results, "🎯 **BlockPartyCmds:**\n```\n"..table.concat(info,"\n").."\n```")
        end
    end
end)

-- Gửi tất cả kết quả
if #results == 0 then
    d("❌ Không đọc được currency!", 0xff0000)
else
    for _, r in ipairs(results) do d(r, 0x00ccff) end
end

d("✅ **XONG!** | `"..plr.Name.."`", 0x00ff88)
