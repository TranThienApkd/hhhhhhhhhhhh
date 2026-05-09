-- Dump Statistics + tìm inventory từ các nguồn đúng
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

d("🔬 **DUMP FULL DATA** | `"..plr.Name.."`", 0xffaa00)

local ok, PPC = pcall(require, RS.Library.Client.PlayerProfileCmds)
local _, data = pcall(PPC.GetPlayerData, plr.UserId)

if type(data)~="table" then d("❌ GetPlayerData fail", 0xff0000) return end

-- Dump TẤT CẢ keys kể cả nested
local function dumpTable(t, prefix, maxDepth)
    if maxDepth<=0 or type(t)~="table" then return {} end
    local lines={}
    for k,v in pairs(t) do
        local key = prefix.."."..tostring(k)
        if type(v)=="table" then
            local cnt=0; for _ in pairs(v) do cnt=cnt+1 end
            -- Sample item đầu tiên
            local sample=""
            for sk,sv in pairs(v) do
                sample=tostring(sk).."="..tostring(sv):sub(1,15)
                break
            end
            table.insert(lines, key.." (table["..cnt.."])  "..sample)
            -- Đệ quy
            for _,sub in ipairs(dumpTable(v, key, maxDepth-1)) do
                table.insert(lines, sub)
            end
        elseif type(v)~="function" then
            table.insert(lines, key.." = "..tostring(v):sub(1,30))
        end
    end
    return lines
end

local allLines = dumpTable(data, "data", 3)

-- Gửi từng chunk 25 dòng
for i=1,#allLines,25 do
    local chunk={}
    for j=i,math.min(i+24,#allLines) do table.insert(chunk,allLines[j]) end
    d("📊 **data structure:**\n```\n"..table.concat(chunk,"\n").."\n```", 0x5599ff)
    wait(0.5)
end

-- Thử StorageGui
d("🔄 **StorageGui.Start() + Get()...**", 0xffaa00)
local sgOk, SG = pcall(require, RS.Library.Client.StorageGui)
if sgOk and type(SG)=="table" then
    if type(SG.Start)=="function" then pcall(SG.Start) wait(3) end
    if type(SG.Get)=="function" then
        local gok, gdata = pcall(SG.Get)
        if gok and gdata~=nil then
            local glines=dumpTable({data=gdata},"SG",3)
            local gchunk={}
            for i=1,math.min(20,#glines) do table.insert(gchunk,glines[i]) end
            d("✅ **StorageGui.Get():**\n```\n"..table.concat(gchunk,"\n").."\n```", 0x00ff88)
        else
            d("⚠️ StorageGui.Get() = nil/error", 0xff8800)
        end
    end
    -- Thử Update
    if type(SG.Update)=="function" then
        pcall(SG.Update) wait(2)
        if type(SG.Get)=="function" then
            local gok2, gdata2 = pcall(SG.Get)
            if gok2 and gdata2~=nil then
                d("✅ **StorageGui.Get() sau Update:**\n```\ntype="..type(gdata2).."\n```", 0x00ff88)
            end
        end
    end
else
    d("❌ StorageGui require fail: `"..tostring(SG).."`", 0xff0000)
end

-- Thử PetEquipCmds
d("🔄 **PetEquipCmds.GetStatus()...**", 0xffaa00)
local eok, EC = pcall(require, RS.Library.Client.PetEquipCmds)
if eok and type(EC)=="table" then
    if type(EC.GetStatus)=="function" then
        local sok, sdata = pcall(EC.GetStatus)
        if sok and sdata~=nil then
            local slines=dumpTable({data=sdata},"EC",2)
            local schunk={}
            for i=1,math.min(20,#slines) do table.insert(schunk,slines[i]) end
            d("✅ **PetEquipCmds.GetStatus():**\n```\n"..table.concat(schunk,"\n").."\n```", 0x00ff88)
        else
            d("⚠️ GetStatus() = "..tostring(sdata), 0xff8800)
        end
    end
    if type(EC.GetMaxEquipped)=="function" then
        local mok, mdata = pcall(EC.GetMaxEquipped)
        d("PetEquipCmds.GetMaxEquipped() = `"..tostring(mdata).."`", 0x9966ff)
    end
end

d("✅ **DUMP XONG!** Gửi info trên cho admin.", 0x00ff88)
