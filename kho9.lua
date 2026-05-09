-- PS99 Full Inventory via Inventory_Opened + Items: Update hook
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

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

d("🟡 **KHO v9** | `"..plr.Name.."`", 0xffaa00)

local seen={} local uidLines={} local total=0
local function addItem(uid,id)
    if type(uid)=="string" and #uid>5 and type(id)=="string" and #id>0 and not seen[uid] then
        seen[uid]=true; table.insert(uidLines, uid.."|"..id); total=total+1
    end
end

-- =====================================================
-- BƯỚC 1: Lấy Equipped từ GetPlayerData (đã biết hoạt động)
-- =====================================================
local ok,PPC=pcall(require, RS.Library.Client.PlayerProfileCmds)
if ok and type(PPC)=="table" then
    local dok,data=pcall(PPC.GetPlayerData, plr.UserId)
    if dok and type(data)=="table" and type(data.Equipped)=="table" then
        for _,item in pairs(data.Equipped) do
            if type(item)=="table" then
                local uid=item.uid
                local id=type(item.data)=="table" and item.data.id or item.data
                addItem(tostring(uid or ""), tostring(id or ""))
            end
        end
        d("✅ Equipped: "..total.." unique pets", 0x00ff00)
    end
end

-- =====================================================
-- BƯỚC 2: Hook Items: Update → fire Inventory_Opened
-- =====================================================
d("🔄 Hook `Items: Update` + fire `Inventory_Opened`...", 0xffaa00)

local storageItems = 0
local gotUpdate = false
local conn

-- Hook "Items: Update" để bắt data từ server
pcall(function()
    conn = Net["Items: Update"].OnClientEvent:Connect(function(updateData)
        gotUpdate = true
        -- Dump cấu trúc để debug
        if type(updateData)=="table" then
            for _,item in pairs(updateData) do
                if type(item)=="table" then
                    local uid=item.uid or item.Uid
                    local id=(type(item.data)=="table" and item.data.id) or item.id or item.name
                    if uid and id then
                        addItem(tostring(uid), tostring(id))
                        storageItems=storageItems+1
                    end
                end
            end
        end
    end)
end)

-- Fire Inventory_Opened để trigger server gửi data
pcall(function() Net["Inventory_Opened"]:FireServer() end)

-- Đợi server respond (tối đa 15s)
local waited=0
repeat wait(1); waited=waited+1 until gotUpdate or waited>=15

if conn then pcall(function() conn:Disconnect() end) end

if storageItems>0 then
    d("✅ **Items: Update** trả về "..storageItems.." items!", 0x00ff88)
elseif gotUpdate then
    d("⚠️ Items: Update fired nhưng không có uid/id\nGửi debug...", 0xff8800)

    -- Debug: xem cấu trúc data trả về
    local debugConn
    pcall(function()
        debugConn = Net["Items: Update"].OnClientEvent:Connect(function(updateData)
            local info = "type="..type(updateData)
            if type(updateData)=="table" then
                local cnt=0; for _ in pairs(updateData) do cnt=cnt+1 end
                info="table["..cnt.."]"
                for k,v in pairs(updateData) do
                    if type(v)=="table" then
                        local ik={}
                        for k2,v2 in pairs(v) do table.insert(ik,k2.."="..type(v2)); if #ik>=6 then break end end
                        info=info.."\n  ["..k.."]: "..table.concat(ik,",")
                    else
                        info=info.."\n  "..tostring(k).."="..tostring(v)
                    end
                    break -- chỉ sample 1
                end
            end
            d("📊 **Items: Update structure:**\n```\n"..info:sub(1,500).."\n```", 0x5599ff)
        end)
    end)
    pcall(function() Net["Inventory_Opened"]:FireServer() end)
    wait(5)
    if debugConn then pcall(function() debugConn:Disconnect() end) end
else
    d("⚠️ Server không fire Items: Update trong 15s\nThử Pets_GetEquipped...", 0xff8800)

    -- Fallback: thử Pets_GetEquipped RemoteFunction
    pcall(function()
        local rf = Net["Pets_GetEquipped"]
        if rf and rf.ClassName=="RemoteFunction" then
            local rOk, rData = pcall(function() return rf:InvokeServer() end)
            if rOk and rData~=nil then
                d("✅ Pets_GetEquipped: type="..type(rData), 0x00ff88)
                if type(rData)=="table" then
                    for _,item in pairs(rData) do
                        if type(item)=="table" then
                            local uid=item.uid or item.Uid
                            local id=(type(item.data)=="table" and item.data.id) or item.id or item.name
                            if uid and id then addItem(tostring(uid),tostring(id)) end
                        end
                    end
                end
            else
                d("⚠️ Pets_GetEquipped: "..tostring(rData), 0xff8800)
            end
        end
    end)
end

-- =====================================================
-- Kết quả
-- =====================================================
if total==0 then d("❌ Không có item!", 0xff0000) return end

table.sort(uidLines,function(a,b)
    local _,an=a:match("^([^|]+)|(.+)$")
    local _,bn=b:match("^([^|]+)|(.+)$")
    return (an or a)<(bn or b)
end)

d("📦 **"..total.." items** – đang gửi...", 0x00ccff)
wait(0.5)
sendList("Kho ["..plr.Name.."]", uidLines)
d("🏁 **XONG!**\n**Acc:** `"..plr.Name.."`\n**Tổng:** "..total.." items\n**Storage items:** "..storageItems, 0x00ff88)
