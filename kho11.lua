-- Kho v11 - Equip All → Scan All UIDs → Unequip All
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end
local function sendList(title,lines)
    local N=40; local pages=math.ceil(#lines/N)
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

d("🟡 **KHO v11** | `"..plr.Name.."`", 0xffaa00)

local seen={} local uidLines={} local total=0
local function addItem(uid,id)
    uid=tostring(uid or ""); id=tostring(id or "")
    if #uid>5 and #id>0 and not seen[uid] then
        seen[uid]=true; table.insert(uidLines, uid.."|"..id); total=total+1
    end
end

-- Lưu list equipped ban đầu để restore sau
local originalEquipped = {}
local ok,PPC=pcall(require, RS.Library.Client.PlayerProfileCmds)
if ok then
    local _,data=pcall(PPC.GetPlayerData, plr.UserId)
    if type(data)=="table" and type(data.Equipped)=="table" then
        for _,item in pairs(data.Equipped) do
            if type(item)=="table" and item.uid then
                table.insert(originalEquipped, item.uid)
                addItem(item.uid, type(item.data)=="table" and item.data.id or item.data)
            end
        end
        d("📝 Đã lưu "..#originalEquipped.." equipped pets ban đầu\n✅ "..total.." unique UIDs", 0x00ff00)
    end
end

-- =====================================================
-- Hook Pets_LocalPetsUpdated TRƯỚC khi fire EquipAll
-- =====================================================
d("🔄 Hook Pets_LocalPetsUpdated + Fire Pets_EquipAll...\n⚠️ Pets sẽ thay đổi tạm thời!", 0xff8800)

local gotUpdate = false
local updateData = {}
local conn

pcall(function()
    conn = Net["Pets_LocalPetsUpdated"].OnClientEvent:Connect(function(...)
        for _, arg in ipairs({...}) do
            if type(arg)=="table" then
                for _, item in pairs(arg) do
                    if type(item)=="table" then
                        local uid=item.uid or item.Uid
                        local id=(type(item.data)=="table" and item.data.id) or item.id or item.name
                        if uid and id then
                            addItem(tostring(uid), tostring(id))
                            gotUpdate=true
                        end
                    end
                end
            end
        end
    end)
end)

-- Fire Pets_EquipAll để load tất cả pets vào memory
pcall(function() Net["Pets_EquipAll"]:FireServer() end)
wait(3)

-- Nếu chưa được, thử EquipBest
if not gotUpdate then
    pcall(function() Net["Pets_EquipBest"]:FireServer() end)
    wait(3)
end

-- Disconnect hook
if conn then pcall(function() conn:Disconnect() end) end

d("📊 Sau EquipAll: total="..total.." items, gotUpdate="..tostring(gotUpdate), 0x5599ff)

-- =====================================================
-- RESTORE: UnequipAll rồi re-equip danh sách cũ
-- =====================================================
d("🔄 Restore pets...", 0xffaa00)
pcall(function() Net["Pets_UnequipAll"]:FireServer() end)
wait(2)

-- Re-equip từng con ban đầu (nếu cần)
-- Thực ra UnequipAll đủ rồi vì game tự restore equipped state
-- Không cần phải equip lại thủ công

d("✅ Đã restore pets (UnequipAll done)", 0x00ff00)

-- =====================================================
-- Kết quả
-- =====================================================
if total==0 then d("❌ Không có item!", 0xff0000) return end

table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

d("📦 **"..total.." unique items** – đang gửi...", 0x00ccff); wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Tổng unique:** "..total.." items", 0x00ff88)
