-- 手机端专用 Luau 飞行脚本 (终极防粘连稳定版)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local flying = false
local FLY_SPEED = 50

local character, rootPart, humanoid
local bg, bv

-- 状态记录
local movingUp = false
local movingDown = false

-- 清理旧的 UI 防止重复堆积
local oldGui = CoreGui:FindFirstChild("MobileFlyGui_Ultimate") or plr.PlayerGui:FindFirstChild("MobileFlyGui_Ultimate")
if oldGui then oldGui:Destroy() end

-- 初始化角色与物理对象
local function setupCharacter(char)
    character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    
    bg = Instance.new("BodyGyro")
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    
    bv = Instance.new("BodyVelocity")
    bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.velocity = Vector3.new(0, 0, 0)
    
    if flying then
        bg.Parent = rootPart
        bv.Parent = rootPart
        humanoid.PlatformStand = true
    end
end

if plr.Character then
    setupCharacter(plr.Character)
end
plr.CharacterAdded:Connect(setupCharacter)

-- 创建手机端控制 UI 界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileFlyGui_Ultimate"
local success = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success then
    screenGui.Parent = plr:WaitForChild("PlayerGui")
end

-- 1. 主飞行开关按钮
local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyButton"
flyButton.Parent = screenGui
flyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Position = UDim2.new(0.05, 0, 0.35, 0)
flyButton.Size = UDim2.new(0, 90, 0, 45)
flyButton.Font = Enum.Font.SourceSansBold
flyButton.Text = "飞行: 关"
flyButton.TextColor3 = Color3.fromRGB(255, 50, 50)
flyButton.TextSize = 16
flyButton.Active = true
flyButton.Draggable = true

-- 2. 上升按钮 (Up)
local upButton = Instance.new("TextButton")
upButton.Name = "UpButton"
upButton.Parent = screenGui
upButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
upButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
upButton.Position = UDim2.new(0.05, 0, 0.22, 0)
upButton.Size = UDim2.new(0, 90, 0, 35)
upButton.Font = Enum.Font.SourceSansBold
upButton.Text = "▲ 上升"
upButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upButton.TextSize = 14
upButton.Active = true
upButton.Draggable = true

-- 3. 下降按钮 (Down)
local downButton = Instance.new("TextButton")
downButton.Name = "DownButton"
downButton.Parent = screenGui
downButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
downButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
downButton.Position = UDim2.new(0.05, 0, 0.48, 0)
downButton.Size = UDim2.new(0, 90, 0, 35)
downButton.Font = Enum.Font.SourceSansBold
downButton.Text = "▼ 下降"
downButton.TextColor3 = Color3.fromRGB(255, 255, 255)
downButton.TextSize = 14
downButton.Active = true
downButton.Draggable = true

-- 按钮事件：开关飞行
flyButton.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        flyButton.Text = "飞行: 开"
        flyButton.TextColor3 = Color3.fromRGB(50, 255, 50)
        if rootPart and humanoid and humanoid.Health > 0 then
            bg.Parent = rootPart
            bv.Parent = rootPart
            humanoid.PlatformStand = true
        end
    else
        flyButton.Text = "飞行: 关"
        flyButton.TextColor3 = Color3.fromRGB(255, 50, 50)
        if rootPart and humanoid then
            bg.Parent = nil
            bv.Parent = nil
            humanoid.PlatformStand = false
            bv.velocity = Vector3.new(0, 0, 0)
        end
        movingUp = false
        movingDown = false
    end
end)

-- 使用更稳定的触控监听（防止手机端按键粘连）
upButton.MouseButton1Down:Connect(function() movingUp = true end)
upButton.MouseButton1Up:Connect(function() movingUp = false end)
upButton.MouseLeave:Connect(function() movingUp = false end)

downButton.MouseButton1Down:Connect(function() movingDown = true end)
downButton.MouseButton1Up:Connect(function() movingDown = false end)
downButton.MouseLeave:Connect(function() movingDown = false end)

-- 核心飞行循环
RunService.RenderStepped:Connect(function()
    if flying and rootPart and humanoid and humanoid.Health > 0 then
        local cam = workspace.CurrentCamera
        bg.cframe = cam.CFrame
        
        local moveDir = humanoid.MoveDirection
        local velocity = Vector3.new(0, 0, 0)
        
        if moveDir.Magnitude > 0 then
            local relativeMove = cam.CFrame:VectorToObjectSpace(moveDir)
            velocity = (cam.CFrame.LookVector * -relativeMove.Z + cam.CFrame.RightVector * relativeMove.X) * FLY_SPEED
        end
        
        if movingUp then
            velocity = velocity + Vector3.new(0, FLY_SPEED, 0)
        end
        if movingDown then
            velocity = velocity - Vector3.new(0, FLY_SPEED, 0)
        end
        
        bv.velocity = velocity
    end
end)

print("终极版手机飞行脚本加载成功！")
