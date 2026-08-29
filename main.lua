-- ============================================
-- 1. نظام التحقق من المفتاح (Key System Setup)
-- ============================================
local UserKey = "PASTE_YOUR_KEY_HERE" -- سيتم استبدال التحقق اليدوي بطلب HTTP لاحقاً
local TargetKeyHash = "" -- هنا يتم مطابقة الـ Hash مستقبلاً

local function verifyKey(key)
    -- مؤقتاً: تحقق بسيط للتجربة قبل ربط الـ API
    if key ~= "" and key ~= "PASTE_YOUR_KEY_HERE" then
        return true
    end
    return false
end

if not verifyKey(UserKey) then
    warn("فشل التحقق: المفتاح غير صحيح أو غير مفعل!")
    return
end

print("تم التحقق من المفتاح بنجاح! جاري تشغيل السكربت...")

-- ============================================
-- 2. سكربت الطيران (Fly System)
-- ============================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local flying = false
local speed = 50
local bodyVelocity, bodyGyro

local function startFlying()
    flying = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)
    bodyVelocity.Parent = HumanoidRootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bodyGyro.CFrame = HumanoidRootPart.CFrame
    bodyGyro.Parent = HumanoidRootPart

    RunService.RenderStepped:Connect(function()
        if not flying then return end
        
        local cameraCFrame = workspace.CurrentCamera.CFrame
        local moveDirection = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - cameraCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + cameraCFrame.RightVector
        end

        bodyVelocity.Velocity = moveDirection * speed
        bodyGyro.CFrame = cameraCFrame
    end)
end

local function stopFlying()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
end

-- زر التفعيل والإيقاف (E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end
end)
