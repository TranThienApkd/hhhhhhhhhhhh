-- Test GetPlayerData với nhiều cách gọi khác nhau
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

d("🔬 **TEST GetPlayerData** | `"..plr.Name.."`", 0xffaa00)

local ok, PPC = pcall(require, RS.Library.Client.PlayerProfileCmds)
if not ok then d("❌ require fail: `"..tostring(PPC).."`", 0xff0000) return end

-- Thử nhiều cách gọi GetPlayerData
local calls = {
    {name="GetPlayerData()",           fn=function() return PPC.GetPlayerData() end},
    {name="GetPlayerData(plr)",        fn=function() return PPC.GetPlayerData(plr) end},
    {name="GetPlayerData(plr.UserId)", fn=function() return PPC.GetPlayerData(plr.UserId) end},
    {name="GetPlayerData(plr.Name)",   fn=function() return PPC.GetPlayerData(plr.Name) end},
}

for _, call in ipairs(calls) do
    local ok2, result = pcall(call.fn)
    local info = ""
    if not ok2 then
        info = "❌ ERROR: `"..tostring(result):sub(1,80).."`"
    elseif result == nil then
        info = "⚠️ returns nil"
    elseif type(result) == "table" then
        local keys = {}
        for k,v in pairs(result) do
            table.insert(keys, tostring(k).."="..type(v))
            if #keys>=8 then break end
        end
        info = "✅ TABLE ["..#keys.." keys]: "..table.concat(keys,", ")
    else
        info = "✅ "..type(result)..": "..tostring(result):sub(1,50)
    end
    d("`"..call.name.."`\n→ "..info, ok2 and result~=nil and 0x00ff00 or 0xff8800)
end

-- Cũng thử MigrationCmds.Load() rồi retry GetPlayerData
d("🔄 Thử MigrationCmds.Load() trước...", 0xffaa00)
local mok, MC = pcall(require, RS.Library.Client.MigrationCmds)
if mok and type(MC)=="table" and type(MC.Load)=="function" then
    local lok, lerr = pcall(MC.Load)
    d("MigrationCmds.Load(): "..(lok and "✅ OK" or "❌ "..tostring(lerr):sub(1,60)), lok and 0x00ff00 or 0xff0000)
    wait(3)
    -- retry GetPlayerData sau khi Load
    local rok, rdata = pcall(PPC.GetPlayerData)
    if rok and rdata~=nil and type(rdata)=="table" then
        local keys={}
        for k,v in pairs(rdata) do table.insert(keys, k.."="..type(v)); if #keys>=10 then break end end
        d("✅ **GetPlayerData() SAU Load():**\n```\n"..table.concat(keys,"\n").."\n```", 0x00ff88)
    else
        d("⚠️ Vẫn nil sau Load()", 0xff8800)
    end
end
