-- ==========================================
-- main.lua - الكود الكامل المدمج والجاهز للرفع على GitHub
-- ==========================================

local SERVER_URL = "https://key-system-api-hjxy.onrender.com/verify-key"

local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local http_request = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request) or (krnl and krnl.request)

-- حالات التشغيل العامة
local ScriptActive = true
local ESP_Player_Enabled = false
local ESP_Chest_Enabled = false
local Flying = false
local FlySpeed = 50

-- حالات الميزات الجديدة (Blox Fruits Features)
_G.AutoChest = false
_G.AutoBounty = false
_G.AutoEliteHunter = false
_G.AutoAwakening = false
_G.AutoFruitSniper = false

-- متغيرات الشخصية
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

-- كائنات الطيران الحديثة
local flyAttachment, flyLinearVelocity, flyAlignOrientation, flyRenderConnection

---------------------------------------------------------
-- 1. دالة جلب البصمة (HWID)
---------------------------------------------------------
local function GetHWID()
    local success, hwid = pcall(function()
        return RbxAnalyticsService:GetClientId()
    end)
    if success and hwid then return hwid end
    return tostring(LocalPlayer.UserId)
end

---------------------------------------------------------
-- 2. دالة التحقق والتفعيل (ترسل Key + Username + HWID)
---------------------------------------------------------
local function VerifyKey(inputKey)
    if not inputKey or inputKey == "" then return false, "الرجاء إدخال المفتاح!" end
    if not http_request then return false, "المشغل لا يدعم طلبات HTTP!" end

    local payload = HttpService:JSONEncode({
        key = string.gsub(inputKey, "^%s*(.-)%s*$", "%1"),
        username = LocalPlayer.Name,
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
-- 3. وظائف الميزات الجديدة (Blox Fruits Logic)
---------------------------------------------------------

-- 💰 Auto Chest Collector
local function collectChests()
    task.spawn(function()
        while _G.AutoChest and ScriptActive do
            for _, chest in pairs(workspace:GetChildren()) do
                if not _G.AutoChest or not ScriptActive then break end

                if chest:IsA("Model") and chest:FindFirstChild("Chest") then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = chest.Chest.CFrame
                        task.wait(0.2)

                        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                            if item:IsA("Tool") and (item.Name == "Fist of Darkness" or item.Name == "God's Chalice") then
                                _G.AutoChest = false
                                print("Rare item found! Stopping Auto Chest Collector.")
                                return
                            end
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end

-- ⚔️ Auto Bounty Farming
local function huntPlayers()
    task.spawn(function()
        while _G.AutoBounty and ScriptActive do
            for _, enemy in pairs(Players:GetPlayers()) do
                if enemy ~= LocalPlayer and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = enemy.Character.HumanoidRootPart.CFrame
                        task.wait(1)
                    end
                end
            end
            task.wait(5)
        end
    end)
end

-- 🏹 Auto Elite Hunter
local function huntEliteBosses()
    task.spawn(function()
        while _G.AutoEliteHunter and ScriptActive do
            for _, boss in pairs(workspace:GetChildren()) do
                if boss:IsA("Model") and boss:FindFirstChild("HumanoidRootPart") and boss.Name:match("Diablo|Deandre|Urban") then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = boss.HumanoidRootPart.CFrame
                        task.wait(0.2)

                        repeat
                            if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                                VirtualUser:CaptureController()
                                VirtualUser:ClickButton1(Vector2.new())
                            end
                            task.wait(0.5)
                        until not boss:FindFirstChild("Humanoid") or boss.Humanoid.Health <= 0 or not _G.AutoEliteHunter or not ScriptActive

                        print("Elite Boss Defeated!")
                    end
                end
            end
            task.wait(5)
        end
    end)
end

-- 🌟 Auto Awakening
local function awakenAllMoves()
    task.spawn(function()
        while _G.AutoAwakening and ScriptActive do
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui and pGui:FindFirstChild("Awakening") and pGui.Awakening:FindFirstChild("Frame") then
                local awakenFrame = pGui.Awakening.Frame
                if awakenFrame.Visible then
                    for _, button in pairs(awakenFrame:GetChildren()) do
                        if button:IsA("TextButton") and button.Text == "Awaken" then
                            button:Activate()
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- 🍏 Auto Fruit Sniper
local rareFruits = {"Dragon", "Dough", "Leopard", "Venom", "Control", "Shadow"}
local function buyRareFruit()
    task.spawn(function()
        while _G.AutoFruitSniper and ScriptActive do
            local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
            if commF then
                local shop = commF:InvokeServer("GetFruits")
                if type(shop) == "table" then
                    for _, fruit in pairs(shop) do
                        if table.find(rareFruits, fruit.Name) then
                            commF:InvokeServer("BuyFruit", fruit.Name)
                            print("Bought rare fruit: " .. fruit.Name)
                            _G.AutoFruitSniper = false
                            return
                        end
                    end
                end
            end
            task.wait(5)
        end
    end)
end

-- 🛑 Anti-AFK
LocalPlayer.Idled:Connect(function()
    if ScriptActive then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end
end)

---------------------------------------------------------
-- 4. محرك الطيران الحديث (LinearVelocity & AlignOrientation)
---------------------------------------------------------
local function CleanupFlyPhysics()
    if flyRenderConnection then
        flyRenderConnection:Disconnect()
        flyRenderConnection = nil
    end
    if flyLinearVelocity then
        flyLinearVelocity:Destroy()
        flyLinearVelocity = nil
    end
    if flyAlignOrientation then
        flyAlignOrientation:Destroy()
        flyAlignOrientation = nil
    end
    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end
    if Humanoid and Humanoid.Parent then
        Humanoid.PlatformStand = false
    end
end

local function ToggleFly(state)
    Flying = state
    CleanupFlyPhysics()

    if not Flying or not ScriptActive then return end

    Character = LocalPlayer.Character
    if not Character then return end
    HRP = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not HRP or not Humanoid then return end

    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "FlyAttachment"
    flyAttachment.Parent = HRP

    flyLinearVelocity = Instance.new("LinearVelocity")
    flyLinearVelocity.Name = "FlyLinearVelocity"
    flyLinearVelocity.Attachment0 = flyAttachment
    flyLinearVelocity.MaxForce = 9e9
    flyLinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyLinearVelocity.VectorVelocity = Vector3.zero
    flyLinearVelocity.Parent = HRP

    flyAlignOrientation = Instance.new("AlignOrientation")
    flyAlignOrientation.Name = "FlyAlignOrientation"
    flyAlignOrientation.Attachment0 = flyAttachment
    flyAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyAlignOrientation.MaxTorque = 9e9
    flyAlignOrientation.Responsiveness = 200
    flyAlignOrientation.CFrame = Camera.CFrame
    flyAlignOrientation.Parent = HRP

    flyRenderConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not ScriptActive or not HRP or not HRP.Parent or not Humanoid or not Humanoid.Parent then
            ToggleFly(false)
            return
        end

        Humanoid.PlatformStand = true
        local moveVector = Humanoid.MoveVector

        if moveVector.Magnitude > 0 then
            local cameraCF = Camera.CFrame
            local direction = (cameraCF.LookVector * -moveVector.Z) + (cameraCF.RightVector * moveVector.X)
            flyLinearVelocity.VectorVelocity = direction.Unit * FlySpeed
        else
            flyLinearVelocity.VectorVelocity = Vector3.zero
        end

        flyAlignOrientation.CFrame = Camera.CFrame
    end)
end

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
-- 5. كاشف اللاعبين والصناديق (ESP)
---------------------------------------------------------
local function CreatePlayerESP(plr)
    if plr == LocalPlayer then return end

    local function ApplyESP(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        local oldHL = char:FindFirstChild("ESP_Player_HL")
        if oldHL then oldHL:Destroy() end
        local oldTag = hrp:FindFirstChild("ESP_Player_Tag")
        if oldTag then oldTag:Destroy() end

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

local function IsChest(obj)
    local name = string.lower(obj.Name)
    return string.find(name, "chest") or string.find(name, "box") or string.find(name, "crate") 
        or string.find(name, "treasure") or string.find(name, "loot") or obj:FindFirstChildOfClass("ProximityPrompt") ~= nil
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
end)

workspace.DescendantAdded:Connect(ApplyChestESP)

---------------------------------------------------------
-- 6. المنيو الرئيسي وإدارة الواجهة (Orion Hub)
---------------------------------------------------------
local function LoadOrionHub()
    local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

    local Window = OrionLib:MakeWindow({
        Name = "Lock HWID Hub (HMAC Security)",
        HidePremium = true,
        SaveConfig = false,
        IntroText = "Loading Hub..."
    })

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

    Instance.new("UICorner", CircleBtn).CornerRadius = UDim.new(1, 0)
    local UIStroke = Instance.new("UIStroke", CircleBtn)
    UIStroke.Color = Color3.fromRGB(60, 60, 60)
    UIStroke.Thickness = 2

    CircleBtn.MouseButton1Click:Connect(function()
        OrionLib:ToggleUi()
    end)

    -- تبويب الميزات التلقائية (Main / Auto Features)
    local MainTab = Window:MakeTab({ Name = "Main Features", Icon = "rbxassetid://4483345998" })

    MainTab:AddToggle({
        Name = "Auto Chest Collector",
        Default = false,
        Callback = function(Value)
            _G.AutoChest = Value
            if Value then collectChests() end
        end
    })

    MainTab:AddToggle({
        Name = "Auto Bounty",
        Default = false,
        Callback = function(Value)
            _G.AutoBounty = Value
            if Value then huntPlayers() end
        end
    })

    MainTab:AddToggle({
        Name = "Auto Elite Hunter",
        Default = false,
        Callback = function(Value)
            _G.AutoEliteHunter = Value
            if Value then huntEliteBosses() end
        end
    })

    MainTab:AddToggle({
        Name = "Auto Awakening",
        Default = false,
        Callback = function(Value)
            _G.AutoAwakening = Value
            if Value then awakenAllMoves() end
        end
    })

    MainTab:AddToggle({
        Name = "Auto Fruit Sniper",
        Default = false,
        Callback = function(Value)
            _G.AutoFruitSniper = Value
            if Value then buyRareFruit() end
        end
    })

    -- تبويب التنقل (Teleport)
    local TeleportTab = Window:MakeTab({ Name = "Teleport", Icon = "rbxassetid://4483345998" })

    TeleportTab:AddButton({
        Name = "Teleport to First Sea",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(2000, 50, 2000)
            end
        end
    })

    TeleportTab:AddButton({
        Name = "Teleport to Second Sea",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(8000, 50, -8000)
            end
        end
    })

    TeleportTab:AddButton({
        Name = "Teleport to Third Sea",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(12000, 50, -12000)
            end
        end
    })

    -- تبويب الرؤية (ESP Visuals)
    local VisualsTab = Window:MakeTab({ Name = "ESP Visuals", Icon = "rbxassetid://4483345998" })

    VisualsTab:AddToggle({
        Name = "ESP Player",
        Default = false,
        Callback = function(Value)
            ESP_Player_Enabled = Value
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hl = plr.Character:FindFirstChild("ESP_Player_HL")
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local tag = hrp and hrp:FindFirstChild("ESP_Player_Tag")
                    if hl then hl.Enabled = Value end
                    if tag then tag.Enabled = Value end
                end
            end
        end
    })

    VisualsTab:AddToggle({
        Name = "ESP Chest",
        Default = false,
        Callback = function(Value)
            ESP_Chest_Enabled = Value
            for _, obj in ipairs(workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("ESP_Chest_HL")
                if hl then hl.Enabled = Value end
            end
        end
    })

    -- تبويب الحركة (Movement)
    local MovementTab = Window:MakeTab({ Name = "Movement", Icon = "rbxassetid://4483345998" })

    MovementTab:AddToggle({
        Name = "Fly (Modern Physics)",
        Default = false,
        Callback = function(Value)
            ToggleFly(Value)
        end
    })

    MovementTab:AddSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 300,
        Default = 50,
        Color = Color3.fromRGB(0, 120, 215),
        Increment = 5,
        ValueName = "Speed",
        Callback = function(Value)
            FlySpeed = Value
        end
    })

    -- تبويب الإعدادات (Settings)
    local SettingsTab = Window:MakeTab({ Name = "Settings", Icon = "rbxassetid://4483345998" })

    SettingsTab:AddButton({
        Name = "Destroy Script (X)",
        Callback = function()
            ScriptActive = false
            ESP_Player_Enabled = false
            ESP_Chest_Enabled = false
            _G.AutoChest = false
            _G.AutoBounty = false
            _G.AutoEliteHunter = false
            _G.AutoAwakening = false
            _G.AutoFruitSniper = false
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
-- 7. واجهة التفعيل (Key UI)
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
Title.Text = "Key System - HMAC Secure"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

KeyInput.Parent = MainFrame
KeyInput.Position = UDim2.new(0.1, 0, 0.3, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 35)
KeyInput.PlaceholderText = "Enter Key Here..."
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
