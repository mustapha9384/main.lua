-- ==========================================
-- السكربت الكامل: مفتاح التحقق + قائمة الأوامر (ESP & Fly)
-- ==========================================

local SERVER_URL = "https://key-system-api-hjxy.onrender.com/verify-key"

local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local http_request = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request) or (krnl and krnl.request)

---------------------------------------------------------
-- دالة جلب البصمة (HWID)
---------------------------------------------------------
local function GetHWID()
    local success, hwid = pcall(function()
        return RbxAnalyticsService:GetClientId()
    end)
    if success and hwid then
        return hwid
    end
    return tostring(LocalPlayer.UserId)
end

---------------------------------------------------------
-- دالة التحقق
---------------------------------------------------------
local function VerifyKey(inputKey)
    if not inputKey or inputKey == "" then return false, "الرجاء إدخال المفتاح!" end
    if not http_request then return false, "المشغل لا يدعم طلبات HTTP!" end

    local payload = HttpService:JSONEncode({
        key = string.gsub(inputKey, "^%s*(.-)%s*$", "%1"),
        hwid = GetHWID()
    })

    local success, response = pcall(function()
        return http_request({
            Url = SERVER_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)

    if success and response then
        local responseBody = response.Body or response.body
        if responseBody then
            local decodeSuccess, result = pcall(function() return HttpService:JSONDecode(responseBody) end)
            if decodeSuccess and result then
                return result.success, (result.message or "تمت العملية")
            end
        end
    end
    return false, "فشل الاتصال بالسيرفر!"
end

---------------------------------------------------------
-- نظام المنيو الرئيسي والخصائص (Main Hub UI)
---------------------------------------------------------
local function LoadMainHub()
    local HubGui = Instance.new("ScreenGui")
    HubGui.Name = "MainHubUI"
    HubGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

    local HubFrame = Instance.new("Frame", HubGui)
    HubFrame.Size = UDim2.new(0, 320, 0, 380)
    HubFrame.Position = UDim2.new(0.5, -160, 0.5, -190)
    HubFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    HubFrame.Active = true
    HubFrame.Draggable = true

    local UICorner = Instance.new("UICorner", HubFrame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel", HubFrame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Text = "MAIN MENU - CHEATS"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

    -- متغيرات التفعيل
    local ESP_Player_Enabled = false
    local ESP_Chest_Enabled = false
    local Flying = false
    local FlySpeed = 50

    ---------------------------------------------------------
    -- نظام ESP (اللاعبين والصناديق)
    ---------------------------------------------------------
    local function UpdateESP()
        -- ESP Players
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hl = plr.Character:FindFirstChild("ESP_Player_Highlight")
                if ESP_Player_Enabled then
                    if not hl then
                        hl = Instance.new("Highlight", plr.Character)
                        hl.Name = "ESP_Player_Highlight"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                elseif hl then
                    hl:Destroy()
                end
            end
        end

        -- ESP Chests
        if ESP_Chest_Enabled then
            for _, obj in pairs(workspace:GetDescendants()) do
                if string.find(string.lower(obj.Name), "chest") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    if not obj:FindFirstChild("ESP_Chest_Highlight") then
                        local hl = Instance.new("Highlight", obj)
                        hl.Name = "ESP_Chest_Highlight"
                        hl.FillColor = Color3.fromRGB(255, 215, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                end
            end
        else
            for _, obj in pairs(workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("ESP_Chest_Highlight")
                if hl then hl:Destroy() end
            end
        end
    end

    RunService.RenderStepped:Connect(UpdateESP)

    ---------------------------------------------------------
    -- نظام الطيران المتقدم (Fly System for Mobile & Camera)
    ---------------------------------------------------------
    local BodyVelocity, BodyGyro

    local function ToggleFly(state)
        Flying = state
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        if Flying then
            hum.PlatformStand = true
            BodyVelocity = Instance.new("BodyVelocity", hrp)
            BodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            BodyVelocity.Velocity = Vector3.zero

            BodyGyro = Instance.new("BodyGyro", hrp)
            BodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            BodyGyro.P = 9000
            BodyGyro.CFrame = hrp.CFrame

            task.spawn(function()
                while Flying and char and hrp and hum do
                    local moveDir = hum.MoveVector
                    local camCF = Camera.CFrame
                    
                    -- تحريك الطيران بناءً على الكاميرا والجويستيك
                    local flyVector = (camCF.LookVector * -moveDir.Z) + (camCF.RightVector * moveDir.X)
                    
                    if moveDir.Magnitude > 0 then
                        BodyVelocity.Velocity = flyVector * FlySpeed
                    else
                        BodyVelocity.Velocity = Vector3.zero
                    end
                    
                    BodyGyro.CFrame = camCF
                    RunService.RenderStepped:Wait()
                end
                
                if BodyVelocity then BodyVelocity:Destroy() end
                if BodyGyro then BodyGyro:Destroy() end
                hum.PlatformStand = false
            end)
        else
            if BodyVelocity then BodyVelocity:Destroy() end
            if BodyGyro then BodyGyro:Destroy() end
            hum.PlatformStand = false
        end
    end

    ---------------------------------------------------------
    -- عناصر الواجهة (Buttons & Speed Slider)
    ---------------------------------------------------------
    local function CreateButton(text, pos, callback)
        local btn = Instance.new("TextButton", HubFrame)
        btn.Size = UDim2.new(0.85, 0, 0, 38)
        btn.Position = pos
        btn.Text = text .. " [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local enabled = false
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = text .. (enabled and " [ON]" or " [OFF]")
            btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(40, 40, 40)
            callback(enabled)
        end)
    end

    CreateButton("ESP Player", UDim2.new(0.075, 0, 0.15, 0), function(st) ESP_Player_Enabled = st end)
    CreateButton("ESP Chest", UDim2.new(0.075, 0, 0.28, 0), function(st) ESP_Chest_Enabled = st end)
    CreateButton("Fly", UDim2.new(0.075, 0, 0.41, 0), function(st) ToggleFly(st) end)

    -- عجلة / شريط التحكم بالسرعة (Speed Control)
    local SpeedLabel = Instance.new("TextLabel", HubFrame)
    SpeedLabel.Size = UDim2.new(0.85, 0, 0, 25)
    SpeedLabel.Position = UDim2.new(0.075, 0, 0.58, 0)
    SpeedLabel.Text = "Fly Speed: " .. FlySpeed
    SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedLabel.BackgroundTransparency = 1

    local SpeedBtnMinus = Instance.new("TextButton", HubFrame)
    SpeedBtnMinus.Size = UDim2.new(0.4, 0, 0, 35)
    SpeedBtnMinus.Position = UDim2.new(0.075, 0, 0.67, 0)
    SpeedBtnMinus.Text = "- Speed"
    SpeedBtnMinus.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    SpeedBtnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", SpeedBtnMinus)

    local SpeedBtnPlus = Instance.new("TextButton", HubFrame)
    SpeedBtnPlus.Size = UDim2.new(0.4, 0, 0, 35)
    SpeedBtnPlus.Position = UDim2.new(0.525, 0, 0.67, 0)
    SpeedBtnPlus.Text = "+ Speed"
    SpeedBtnPlus.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    SpeedBtnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", SpeedBtnPlus)

    SpeedBtnMinus.MouseButton1Click:Connect(function()
        FlySpeed = math.max(10, FlySpeed - 20)
        SpeedLabel.Text = "Fly Speed: " .. FlySpeed
    end)

    SpeedBtnPlus.MouseButton1Click:Connect(function()
        FlySpeed = math.min(500, FlySpeed + 20)
        SpeedLabel.Text = "Fly Speed: " .. FlySpeed
    end)
end

---------------------------------------------------------
-- واجهة إدخال المفتاح (Key System UI)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local KeyInput = Instance.new("TextBox")
local VerifyBtn = Instance.new("TextButton")
local StatusText = Instance.new("TextLabel")

ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

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

VerifyBtn.MouseButton1Click:Connect(function()
    StatusText.Text = "Checking..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.spawn(function()
        local isOK, msg = VerifyKey(KeyInput.Text)
        
        if isOK then
            StatusText.Text = "✅ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
            task.wait(1)
            ScreenGui:Destroy()
            
            -- تشغيل المنيو الرئيسي بعد نجاح التفعيل
            LoadMainHub()
        else
            StatusText.Text = "❌ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end)
