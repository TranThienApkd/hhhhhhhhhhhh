-- Mailbox Send - thử thẳng các format
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer
local Net=RS.Network

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(1) end

-- ===== CONFIG =====
local TARGET   = "NguoiDungNo1"
local DIAMONDS = 20000
-- ==================

d("📬 Gửi **"..DIAMONDS.."💎** → `"..TARGET.."`", 0xffaa00)

-- Thử từng format
local tried = 0
local function tryFormat(name, fn)
    tried=tried+1
    local ok, err = pcall(fn)
    d("Format "..tried.." **"..name.."**: "..(ok and "✅ Fired (check mailbox!)" or "❌ "..tostring(err):sub(1,80)), ok and 0x00ff88 or 0xff4444)
    if ok then return true end
    return false
end

-- Format 1: (username, items, diamonds, message)
if tryFormat("(user,items,dia,msg)", function()
    Net["Mailbox: Send"]:FireServer(TARGET, {}, DIAMONDS, "")
end) then return end

-- Format 2: (username, diamonds)
if tryFormat("(user, dia)", function()
    Net["Mailbox: Send"]:FireServer(TARGET, DIAMONDS)
end) then return end

-- Format 3: single table
if tryFormat("{username, diamonds}", function()
    Net["Mailbox: Send"]:FireServer({Username=TARGET, Diamonds=DIAMONDS, Items={}, Message=""})
end) then return end

-- Format 4: lowercase keys
if tryFormat("{username, diamonds lower}", function()
    Net["Mailbox: Send"]:FireServer({username=TARGET, diamonds=DIAMONDS, items={}, message=""})
end) then return end

-- Format 5: (username, diamonds, items)
if tryFormat("(user, dia, items)", function()
    Net["Mailbox: Send"]:FireServer(TARGET, DIAMONDS, {})
end) then return end

-- Format 6: (table with To field)
if tryFormat("{To, Diamonds}", function()
    Net["Mailbox: Send"]:FireServer({To=TARGET, Diamonds=DIAMONDS})
end) then return end

-- Format 7: invoke thay vì fire
if tryFormat("InvokeServer(user,dia)", function()
    Net["Mailbox: Send"]:InvokeServer(TARGET, {}, DIAMONDS, "")
end) then return end

d("⚠️ Tất cả format đều fire nhưng game có thể reject nếu sai\n**Kiểm tra hộp thư của "..TARGET.."** xem có nhận không!", 0xff8800)
