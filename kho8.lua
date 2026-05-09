-- Scan Remotes đơn giản
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c)
    pcall(function()
        request({Url=W,Method="POST",
            Headers={["Content-Type"]="application/json"},
            Body=Http:JSONEncode({embeds={{description=msg,color=c or 0xffffff}}})})
    end)
    wait(1)
end

d("▶️ kho8 chạy | "..plr.Name, 0xffaa00)

-- Thu thập tất cả Remote trong RS (không đệ quy sâu)
local lines = {}
local function scan(folder, prefix)
    local ok, children = pcall(function() return folder:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        local cn = child.ClassName
        if cn == "RemoteFunction" or cn == "RemoteEvent" then
            table.insert(lines, cn:sub(1,2).."|"..prefix..child.Name)
        end
        -- 1 level sâu hơn
        local ok2, sub = pcall(function() return child:GetChildren() end)
        if ok2 then
            for _, subchild in ipairs(sub) do
                local scn = subchild.ClassName
                if scn == "RemoteFunction" or scn == "RemoteEvent" then
                    table.insert(lines, scn:sub(1,2).."|"..prefix..child.Name.."/"..subchild.Name)
                end
            end
        end
    end
end

scan(RS, "RS/")

d("📋 **Tổng remotes: "..#lines.."**", 0x5599ff)

-- Gửi theo batch 40
for i=1,#lines,40 do
    local chunk={}
    for j=i,math.min(i+39,#lines) do table.insert(chunk,lines[j]) end
    d("```\n"..table.concat(chunk,"\n").."\n```", 0x5599ff)
    wait(0.5)
end

-- Filter relevant
local kws={"stor","inv","pet","bag","save","item","equip","profile"}
local rel={}
for _,line in ipairs(lines) do
    for _,kw in ipairs(kws) do
        if line:lower():find(kw) then table.insert(rel,"⭐ "..line); break end
    end
end
if #rel>0 then
    d("⭐ **Relevant:**\n```\n"..table.concat(rel,"\n").."\n```", 0x00ff88)
else
    d("ℹ️ Không có remote relevant", 0xaaaaaa)
end

d("✅ Xong!", 0x00ff88)
