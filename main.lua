-- ==========================================
-- السكربت الكامل: تفعيل الموزع + Orion Lib مع إصلاح الخصائص وزر التخفي والإنهاء
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

-- حالات التشغيل العام
local ScriptActive = true
local ESP_Player_Enabled = false
local ESP_Chest_Enabled = false
local Flying = false
local FlySpeed = 50

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
-- المحرك الفعلي للخصائص (ESP & Fly Engine)
---------------------------------------------------------

-- 1. كاشف اللاعبين (Player ESP)
task.spawn(function()
    while task.wait(0.5) do
        if not ScriptActive then break end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hl = plr.Character:FindFirstChild("ESP_Player_HL")
                if ESP_Player_Enabled then
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "ESP_Player_HL"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character
                    end
                elseif hl then
                    hl:Destroy()
                end
            end
        end
    end
end)

-- 2. كاشف الصناديق (Chest ESP)
task.spawn(function()
    while task.wait(1.5) do
        if not ScriptActive then break end
        if ESP_Chest_Enabled then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local name = string.lower(obj.Name)
                    if (string.find(name, "chest") or string.find(name, "box")) and not string.find(name, "part") then
                        local hl = obj:FindFirstChild("ESP_Chest_HL")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "ESP_Chest_HL"
                            hl.FillColor = Color3.fromRGB(255, 215, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = obj
                        end
                    end
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("ESP_Chest_HL")
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- 3. محرك الطيران (Fly Engine)
local function ToggleFly(state)
    Flying = state
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if Flying then
        task.spawn(function()
            hum.PlatformStand = true
            local bv = Instance.new("BodyVelocity", hrp)
            bv.Name = "FlyBV"
            bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bv.Velocity = Vector3.zero

            local bg = Instance.new("BodyGyro", hrp)
            bg.Name = "FlyBG"
            bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bg.P = 9000
            bg.CFrame = hrp.CFrame

            while Flying and ScriptActive and char and hrp and hum do
                local moveDir = hum.MoveVector
                local camCF = Camera.CFrame
                
                if moveDir.Magnitude > 0 then
                    local flyDir = (camCF.LookVector * -moveDir.Z) + (camCF.RightVector * moveDir.X)
                    bv.Velocity = flyDir.Unit * FlySpeed
                else
                    bv.Velocity = Vector3.zero
                end
                bg.CFrame = camCF
                RunService.RenderStepped:Wait()
            end

            bv:Destroy()
            bg:Destroy()
            if hum then hum.PlatformStand = false end
        end)
    else
        local bv = hrp:FindFirstChild("FlyBV")
        local bg = hrp:FindFirstChild("FlyBG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        hum.PlatformStand = false
    end
end

---------------------------------------------------------
-- المنيو الرئيسي وإدارة الأزرار الدائرية
---------------------------------------------------------
local function LoadOrionHub()
    local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

    local Window = OrionLib:MakeWindow({
        Name = "Lock HWID Hub",
        HidePremium = true,
        SaveConfig = false,
        IntroText = "Loading Hub..."
    })

    -- زر التصغير الدائري (الدائرة السوداء |||)
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "ToggleCircleGui"
    ToggleGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

    local CircleBtn = Instance.new("TextButton", ToggleGui)
    CircleBtn.Size = UDim2.new(0, 50, 0, 50)
    CircleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
    CircleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    CircleBtn.Text = "|||"
    CircleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CircleBtn.TextSize = 18
    CircleBtn.Active = true
    CircleBtn.Draggable = true

    local UICorner = Instance.new("UICorner", CircleBtn)
    UICorner.CornerRadius = UDim.new(1, 0)

    local UIStroke = Instance.new("UIStroke", CircleBtn)
    UIStroke.Color = Color3.fromRGB(60, 60, 60)
    UIStroke.Thickness = 2

    local isHidden = false
    CircleBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        OrionLib:ToggleUi()
    end)

    -- تبويب Visuals
    local VisualsTab = Window:MakeTab({ Name = "ESP Visuals", Icon = "rbxassetid://4483345998" })

    VisualsTab:AddToggle({
        Name = "ESP Player",
        Default = false,
        Callback = function(Value) ESP_Player_Enabled = Value end
    })

    VisualsTab:AddToggle({
        Name = "ESP Chest",
        Default = false,
        Callback = function(Value) ESP_Chest_Enabled = Value end
    })

    -- تبويب Movement
    local MovementTab = Window:MakeTab({ Name = "Movement", Icon = "rbxassetid://4483345998" })

    MovementTab:AddToggle({
        Name = "Fly (Mobile & PC)",
        Default = false,
        Callback = function(Value) ToggleFly(Value) end
    })

    MovementTab:AddSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 500,
        Default = 50,
        Color = Color3.fromRGB(0, 120, 215),
        Increment = 5,
        ValueName = "Speed",
        Callback = function(Value) FlySpeed = Value end
    })

    -- تبويب Settings للإنهاء الكلي X
    local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })

    SettingsTab:AddButton({
        Name = "Destroy Script (X)",
        Callback = function()
            ScriptActive = false
            ESP_Player_Enabled = false
            ESP_Chest_Enabled = false
            ToggleFly(false)
            
            -- مسح التأثيرات
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("ESP_Player_HL") then
                    plr.Character.ESP_Player_HL:Destroy()
                end
            end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:FindFirstChild("ESP_Chest_HL") then
                    obj.ESP_Chest_HL:Destroy()
                end
            end
            
            ToggleGui:Destroy()
            OrionLib:Destroy()
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
            
            LoadOrionHub()
        else
            StatusText.Text = "❌ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
end)
