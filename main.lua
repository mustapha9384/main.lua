-- ==========================================
-- السكربت الرئيسي مع واجهة Orion Library الاحترافية
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
    if success and hwid then return hwid end
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
-- المنيو الرئيسي عبر Orion Library
---------------------------------------------------------
local function LoadOrionHub()
    local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

    local Window = OrionLib:MakeWindow({
        Name = "Lock HWID Hub | Cheat Menu",
        HidePremium = true,
        SaveConfig = false,
        IntroText = "Loading Cheat Hub..."
    })

    -- تبويب الكشوفات (ESP)
    local VisualsTab = Window:MakeTab({
        Name = "Visuals (ESP)",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    local ESP_Player_Enabled = false
    local ESP_Chest_Enabled = false

    VisualsTab:AddToggle({
        Name = "ESP Player",
        Default = false,
        Callback = function(Value)
            ESP_Player_Enabled = Value
        end
    })

    VisualsTab:AddToggle({
        Name = "ESP Chest",
        Default = false,
        Callback = function(Value)
            ESP_Chest_Enabled = Value
        end
    })

    RunService.RenderStepped:Connect(function()
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
    end)

    -- تبويب الحركة والطيران (Movement)
    local MovementTab = Window:MakeTab({
        Name = "Movement",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    local Flying = false
    local FlySpeed = 50
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

    MovementTab:AddToggle({
        Name = "Fly (Mobile & PC)",
        Default = false,
        Callback = function(Value)
            ToggleFly(Value)
        end
    })

    MovementTab:AddSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 500,
        Default = 50,
        Color = Color3.fromRGB(0, 120, 215),
        Increment = 5,
        ValueName = "Speed",
        Callback = function(Value)
            FlySpeed = Value
        end
    })

    OrionLib:Init()
end

---------------------------------------------------------
-- واجهة إدخال المفتاح (Key Verification UI)
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
            
            -- فتح منيو Orion الجاهزة
            LoadOrionHub()
        else
            StatusText.Text = "❌ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end)
