-- ==========================================
-- السكربت الرئيسي داخل Roblox
-- ==========================================

-- رابط سيرفرك الفعلي على Render
local SERVER_URL = "https://key-system-api-hjxy.onrender.com/verify-key"

local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- التوافق مع مختلف مشغلات روبلوكس (Executors)
local http_request = (syn and syn.request) or (http and http.request) or http_request or request

-- دالة جلب بصمة الجهاز الفريدة (HWID)
local function GetHWID()
    local success, hwid = pcall(function()
        return RbxAnalyticsService:GetClientId()
    end)
    if success and hwid then
        return hwid
    end
    return tostring(LocalPlayer.UserId)
end

-- دالة التحقق من المفتاح عبر السيرفر
local function VerifyKey(inputKey)
    if not inputKey or inputKey == "" then
        return false, "الرجاء إدخال المفتاح!"
    end

    if not http_request then
        return false, "المشغل الخاص بك لا يدعم طلبات HTTP!"
    end

    local userHWID = GetHWID()
    
    local payload = HttpService:JSONEncode({
        key = string.gsub(inputKey, "^%s*(.-)%s*$", "%1"),
        hwid = userHWID
    })

    local success, response = pcall(function()
        return http_request({
            Url = SERVER_URL,
            Method = "POST",
            Headers = { 
                ["Content-Type"] = "application/json" 
            },
            Body = payload
        })
    end)

    if success and response and response.Body then
        local decodeSuccess, result = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if decodeSuccess and result then
            return result.success, result.message
        end
    end

    return false, "فشل الاتصال بالسيرفر!"
end

-- ==========================================
-- واجهة المستخدم المباشرة (Simple GUI)
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local KeyInput = Instance.new("TextBox")
local VerifyBtn = Instance.new("TextButton")
local StatusText = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

MainFrame.Name = "KeySystemUI"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "Key System - Lock HWID"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

KeyInput.Parent = MainFrame
KeyInput.Position = UDim2.new(0.1, 0, 0.3, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 35)
KeyInput.PlaceholderText = "Paste Key Here..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

VerifyBtn.Parent = MainFrame
VerifyBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 35)
VerifyBtn.Text = "Verify Key"
VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 16

StatusText.Parent = MainFrame
StatusText.Position = UDim2.new(0.1, 0, 0.8, 0)
StatusText.Size = UDim2.new(0.8, 0, 0, 30)
StatusText.Text = ""
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.TextSize = 14

-- عند ضغط زر التحقق
VerifyBtn.MouseButton1Click:Connect(function()
    StatusText.Text = "Checking..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.spawn(function()
        local isOK, msg = VerifyKey(KeyInput.Text)
        
        if isOK then
            StatusText.Text = "✅ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
            task.wait(1.5)
            ScreenGui:Destroy()
            
            ------------------------------------------
            -- ضع كود السكربت الخاص بك هنا للتنفيذ --
            print("Script Executed Successfully!")
            ------------------------------------------
        else
            StatusText.Text = "❌ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end)
