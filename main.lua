local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local KEYS_URL = "https://raw.githubusercontent.com/mustapha9384/main.lua/main/keys.json"

-- ==========================================
-- 1. دالة التشفير المصححة SHA-256
-- ==========================================
local sha256 = {}
do
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    }

    local function rrotate(a, b)
        return bit32.bor(bit32.rshift(a, b), bit32.lshift(a, 32 - b))
    end

    function sha256.hash(str)
        local h1, h2, h3, h4, h5, h6, h7, h8 = 
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

        local bytes = {str:byte(1, #str)}
        local bit_len = #str * 8

        table.insert(bytes, 0x80)
        while (#bytes % 64) ~= 56 do
            table.insert(bytes, 0x00)
        end

        for i = 7, 0, -1 do
            table.insert(bytes, math.floor(bit_len / (256^i)) % 256)
        end

        for chunk_start = 1, #bytes, 64 do
            local w = {}
            for i = 0, 15 do
                w[i+1] = bytes[chunk_start + i*4] * 16777216 +
                         bytes[chunk_start + i*4 + 1] * 65536 +
                         bytes[chunk_start + i*4 + 2] * 256 +
                         bytes[chunk_start + i*4 + 3]
            end

            for i = 16, 63 do
                local s0 = bit32.bxor(rrotate(w[i-15], 7), rrotate(w[i-15], 18), bit32.rshift(w[i-15], 3))
                local s1 = bit32.bxor(rrotate(w[i-1], 17), rrotate(w[i-1], 19), bit32.rshift(w[i-1], 10))
                w[i+1] = bit32.band(w[i-15+1] + s0 + w[i-6+1] + s1, 0xFFFFFFFF)
            end

            local a, b, c, d, e, f, g, h = h1, h2, h3, h4, h5, h6, h7, h8
            for i = 0, 63 do
                local S1 = bit32.bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
                local temp1 = bit32.band(h + S1 + ch + K[i+1] + w[i+1], 0xFFFFFFFF)
                local S0 = bit32.bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
                local temp2 = bit32.band(S0 + maj, 0xFFFFFFFF)

                h = g
                g = f
                f = e
                e = bit32.band(d + temp1, 0xFFFFFFFF)
                d = c
                c = b
                b = a
                a = bit32.band(temp1 + temp2, 0xFFFFFFFF)
            end

            h1 = bit32.band(h1 + a, 0xFFFFFFFF)
            h2 = bit32.band(h2 + b, 0xFFFFFFFF)
            h3 = bit32.band(h3 + c, 0xFFFFFFFF)
            h4 = bit32.band(h4 + d, 0xFFFFFFFF)
            h5 = bit32.band(h5 + e, 0xFFFFFFFF)
            h6 = bit32.band(h6 + f, 0xFFFFFFFF)
            h7 = bit32.band(h7 + g, 0xFFFFFFFF)
            h8 = bit32.band(h8 + h, 0xFFFFFFFF)
        end

        return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h1, h2, h3, h4, h5, h6, h7, h8)
    end
end

-- ==========================================
-- 2. دالة التحقق من المفتاح
-- ==========================================
local function ValidateKey(inputKey)
    local hashedInput = sha256.hash(inputKey)
    local success, response = pcall(function()
        return game:HttpGet(KEYS_URL .. "?nocache=" .. os.time())
    end)

    if not success then return false end

    local keysData = HttpService:JSONDecode(response)
    for _, entry in ipairs(keysData) do
        if entry.hash == hashedInput then
            return true
        end
    end
    return false
end

-- ==========================================
-- 3. ميزة الطيران (السكربت الرئيسي)
-- ==========================================
local function StartFly()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    BodyVelocity.Velocity = Vector3.new(0, 80, 0)
    BodyVelocity.Parent = HumanoidRootPart
    
    task.wait(4)
    BodyVelocity:Destroy()
end

-- ==========================================
-- 4. واجهة إدخال المفتاح (Key System GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextBox = Instance.new("TextBox")
local SubmitBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.Position = UDim2.new(0.35, 0, 0.35, 0)
Frame.Size = UDim2.new(0, 300, 0, 180)
Frame.Active = true
Frame.Draggable = true

TextBox.Parent = Frame
TextBox.PlaceholderText = "Enter Key Here..."
TextBox.Size = UDim2.new(0, 260, 0, 40)
TextBox.Position = UDim2.new(0, 20, 0, 30)
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

SubmitBtn.Parent = Frame
SubmitBtn.Text = "Verify Key"
SubmitBtn.Size = UDim2.new(0, 260, 0, 40)
SubmitBtn.Position = UDim2.new(0, 20, 0, 85)
SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

StatusLabel.Parent = Frame
StatusLabel.Size = UDim2.new(0, 260, 0, 25)
StatusLabel.Position = UDim2.new(0, 20, 0, 135)
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1

SubmitBtn.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Checking..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    if ValidateKey(TextBox.Text) then
        StatusLabel.Text = "✅ Success! Key Valid."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1)
        ScreenGui:Destroy()
        StartFly()
    else
        StatusLabel.Text = "❌ Invalid Key!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)
