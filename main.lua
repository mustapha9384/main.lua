-- ==========================================
-- السكربت الكامل: إصلاح ResetOnSpawn + طيران مضمون 100% + Key System + Orion
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

-- حالات التشغيل العامة
local ScriptActive = true
local ESP_Player_Enabled = false
local ESP_Chest_Enabled = false
local Flying = false
local FlySpeed = 50

-- متغيرات الشخصية الديناميكية
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    HRP = newChar:WaitForChild("HumanoidRootPart")
    
    if Flying then
        task.wait(0.5)
        ToggleFly(true)
    end
end)

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
-- 1. كاشف اللاعبين (Player ESP)
---------------------------------------------------------
local function CreatePlayerESP(plr)
    if plr == LocalPlayer then return end

    local function ApplyESP(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        if char:FindFirstChild("ESP_Player_HL") then char.ESP_Player_HL:Destroy() end
        if hrp:FindFirstChild("ESP_Player_Tag") then hrp.ESP_Player_Tag:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name = "ESP_Player_HL"
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = ESP_Player_Enabled
        hl.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Player_Tag"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 100, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Enabled = ESP_Player_Enabled

        local txt = Instance.new("TextLabel", billboard)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = plr.Name
        txt.TextColor3 = Color3.fromRGB(255, 50, 50)
        txt.TextStrokeTransparency = 0
        txt.TextSize = 14

        billboard.Parent = hrp
    end

    if plr.Character then ApplyESP(plr.Character) end
    plr.CharacterAdded:Connect(ApplyESP)
end

for _, plr in ipairs(Players:GetPlayers()) do
    CreatePlayerESP(plr)
end
Players.PlayerAdded:Connect(CreatePlayerESP)

task.spawn(function()
    while task.wait(0.5) do
        if not ScriptActive then break end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hl = plr.Character:FindFirstChild("ESP_Player_HL")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local tag = hrp and hrp:FindFirstChild("ESP_Player_Tag")
                
                if hl then hl.Enabled = ESP_Player_Enabled end
                if tag then tag.Enabled = ESP_Player_Enabled end
            end
        end
    end
end)

---------------------------------------------------------
-- 2. كاشف الصناديق (Chest ESP)
---------------------------------------------------------
local function IsChest(obj)
    local name = string.lower(obj.Name)
    if string.find(name, "chest") or string.find(name, "box") or string.find(name, "crate") 
    or string.find(name, "treasure") or string.find(name, "loot") then
        return true
    end
    if obj:FindFirstChildOfClass("ProximityPrompt") then
        return true
    end
    return false
end

local function ApplyChestESP(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    if not IsChest(obj) then return end

    if not obj:FindFirstChild("ESP_Chest_HL") then
        local hl = Instance.new("Highlight")
        hl.Name = "ESP_Chest_HL"
        hl.FillColor = Color3.fromRGB(255, 215, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = ESP_Chest_Enabled
        hl.Parent = obj
    end
end

task.spawn(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        ApplyChestESP(obj)
    end
    workspace.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        ApplyChestESP(obj)
    end)
end)

task.spawn(function()
    while task.wait(1) do
        if not ScriptActive then break end
        for _, obj in ipairs(workspace:GetDescendants()) do
            local hl = obj:FindFirstChild("ESP_Chest_HL")
            if hl then
                hl.Enabled = ESP_Chest_Enabled
            end
        end
    end
end)

---------------------------------------------------------
-- 3. محرك الطيران العالمي والمستقر (Universal Mobile/PC Fly)
---------------------------------------------------------
local flyBV, flyBG, flyLoop

function ToggleFly(state)
    Flying = state
    
    if flyLoop then flyLoop:Disconnect() flyLoop = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    
    if Humanoid then Humanoid.PlatformStand = false end

    if Flying then
        if not HRP or not Humanoid then return end

        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "FlyBV"
        flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = HRP

        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "FlyBG"
        flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        flyBG.P = 9000
        flyBG.CFrame = HRP.CFrame
        flyBG.Parent = HRP

        flyLoop = RunService.RenderStepped:Connect(function()
            if not Flying or not ScriptActive or not HRP or not HRP.Parent or not Humanoid or not Humanoid.Parent then
                ToggleFly(false)
                return
            end

            Humanoid.PlatformStand = true
            local moveDir = Humanoid.MoveVector

            if moveDir.Magnitude > 0 then
                local flyDir = (Camera.CFrame.LookVector * -moveDir.Z) + (Camera.CFrame.RightVector * moveDir.X)
                flyBV.Velocity = flyDir.Unit * FlySpeed
            else
                flyBV.Velocity = Vector3.zero
            end

            flyBG.CFrame = Camera.CFrame
        end)
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

    -- زر التصغير الدائري (|||)
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "ToggleCircleGui"
    ToggleGui.ResetOnSpawn = false
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

    CircleBtn.MouseButton1Click:Connect(function()
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
        Max = 300,
        Default = 50,
        Color = Color3.fromRGB(0, 120, 215),
        Increment = 5,
        ValueName = "Speed",
        Callback = function(Value) FlySpeed = Value end
    })

    -- تبويب Settings للإنهاء الكلي (X)
    local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })

    SettingsTab:AddButton({
        Name = "Destroy Script (X)",
        Callback = function()
            ScriptActive = false
            ESP_Player_Enabled = false
            ESP_Chest_Enabled = false
            ToggleFly(false)
            
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    if plr.Character:FindFirstChild("ESP_Player_HL") then plr.Character.ESP_Player_HL:Destroy() end
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp:FindFirstChild("ESP_Player_Tag") then hrp.ESP_Player_Tag:Destroy() end
                end
            end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:FindFirstChild("ESP_Chest_HL") then obj.ESP_Chest_HL:Destroy() end
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
ScreenGui.Name = "KeySystemUI_Container"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local KeyInput = Instance.new("TextBox")
local VerifyBtn = Instance.new("TextButton")
local StatusText = Instance.new("TextLabel")

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
