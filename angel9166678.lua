local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local guiParent = plr.PlayerGui

local config = {
    FlyEnable = false,
    FlySpeed = 35,
    WindowMinimized = false
}
local rootPart, humanoid
local bodyVelocity = nil

-- 总容器
local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.Name = "小木功能面板"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = guiParent

-- 主窗口
local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0, 600, 0, 460)
mainWindow.Position = UDim2.new(0.02,0,0.07,0)
mainWindow.BackgroundColor3 = Color3.fromRGB(19,19,23)
mainWindow.BorderSizePixel = 1
mainWindow.BorderColor3 = Color3.fromRGB(42,42,48)
mainWindow.ClipsDescendants = true
mainWindow.Parent = screenGui

-- 顶部标题栏（拖动区域）
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,38)
titleBar.BackgroundColor3 = Color3.fromRGB(13,13,17)
titleBar.Parent = mainWindow

-- 左上角名称：小木
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.13,0,1,0)
titleText.Position = UDim2.new(0.02,0,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "小木"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- 最小化按钮
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0,36,0,38)
minimizeBtn.Position = UDim2.new(1,-76,0,0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30,30,36)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.white
minimizeBtn.Parent = titleBar

-- 关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,36,0,38)
closeBtn.Position = UDim2.new(1,-36,0,0)
closeBtn.BackgroundColor3 = Color3.fromRGB(160,22,22)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.white
closeBtn.Parent = titleBar

-- 左右布局分区
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0.27,0,1,-38)
leftPanel.Position = UDim2.new(0,0,0,38)
leftPanel.BackgroundColor3 = Color3.fromRGB(25,25,29)
leftPanel.Visible = true
leftPanel.Parent = mainWindow

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0.73,0,1,-38)
rightPanel.Position = UDim2.new(0.27,0,0,38)
rightPanel.BackgroundTransparency = 1
rightPanel.Visible = true
rightPanel.Parent = mainWindow

-- 左侧菜单文字
local leftLabel = Instance.new("TextLabel")
leftLabel.Size = UDim2.new(0.9,0,0,36)
leftLabel.Position = UDim2.new(0.05,0,0.04,0)
leftLabel.BackgroundTransparency = 1
leftLabel.Text = "移动功能"
leftLabel.TextColor3 = Color3.white
leftLabel.TextSize = 14
leftLabel.Parent = leftPanel

-- 右侧：飞行开关
local flyRow = Instance.new("Frame")
flyRow.Size = UDim2.new(0.97,0,0,46)
flyRow.Position = UDim2.new(0.01,0,0.03,0)
flyRow.BackgroundColor3 = Color3.fromRGB(27,27,31)
flyRow.Parent = rightPanel

local flyText = Instance.new("TextLabel")
flyText.Size = UDim2.new(0.7,0,1,0)
flyText.Position = UDim2.new(0.03,0,0,0)
flyText.BackgroundTransparency = 1
flyText.Text = "开启飞行"
flyText.TextColor3 = Color3.white
flyText.TextSize = 14
flyText.Parent = flyRow

local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(0,44,0,28)
flyToggle.Position = UDim2.new(0.91,0,0.2,0)
flyToggle.BackgroundColor3 = Color3.fromRGB(21,158,43)
flyToggle.Text = "开"
flyToggle.TextColor3 = Color3.white
flyToggle.Parent = flyRow

-- 右侧：速度调节
local speedRow = Instance.new("Frame")
speedRow.Size = UDim2.new(0.97,0,0,46)
speedRow.Position = UDim2.new(0.01,0,0.16,0)
speedRow.BackgroundColor3 = Color3.fromRGB(27,27,31)
speedRow.Parent = rightPanel

local speedText = Instance.new("TextLabel")
speedText.Size = UDim2.new(0.4,0,1,0)
speedText.Position = UDim2.new(0.03,0,0,0)
speedText.BackgroundTransparency = 1
speedText.Text = "移动速度"
speedText.TextColor3 = Color3.white
speedText.TextSize = 14
speedText.Parent = speedRow

local speedMinus = Instance.new("TextButton")
speedMinus.Size = UDim2.new(0,30,0,30)
speedMinus.Position = UDim2.new(0.6,0,0.16,0)
speedMinus.BackgroundColor3 = Color3.fromRGB(28,110,190)
speedMinus.Text = "-"
speedMinus.TextColor3 = Color3.white
speedMinus.Parent = speedRow

local speedNum = Instance.new("TextLabel")
speedNum.Size = UDim2.new(0.12,0,1,0)
speedNum.Position = UDim2.new(0.66,0,0,0)
speedNum.BackgroundTransparency = 1
speedNum.Text = config.FlySpeed
speedNum.TextColor3 = Color3.white
speedNum.TextSize = 14
speedNum.Parent = speedRow

local speedAdd = Instance.new("TextButton")
speedAdd.Size = UDim2.new(0,30,0,30)
speedAdd.Position = UDim2.new(0.8,0,0.16,0)
speedAdd.BackgroundColor3 = Color3.fromRGB(28,110,190)
speedAdd.Text = "+"
speedAdd.TextColor3 = Color3.white
speedAdd.Parent = speedRow

-- ===================== 优化：窗口拖动（适配手机触屏） =====================
local dragging = false
local dragStartOffset

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartOffset = input.Position - Vector2.new(mainWindow.Position.X.Offset, mainWindow.Position.Y.Offset)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local pos = input.Position - dragStartOffset
        -- 限制窗口不会拖出屏幕
        local X = math.clamp(pos.X, 0, guiParent.AbsoluteSize.X - mainWindow.AbsoluteSize.X)
        local Y = math.clamp(pos.Y, 0, guiParent.AbsoluteSize.Y - mainWindow.AbsoluteSize.Y)
        mainWindow.Position = UDim2.new(0, X, 0, Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ===================== 最小化/还原窗口 优化 =====================
minimizeBtn.MouseButton1Click:Connect(function()
    config.WindowMinimized = not config.WindowMinimized
    if config.WindowMinimized then
        mainWindow.Size = UDim2.new(0, 180, 0, 38)
        leftPanel.Visible = false
        rightPanel.Visible = false
        minimizeBtn.Text = "+"
        titleText.Position = UDim2.new(0.35,0,0,0)
        titleText.TextXAlignment = Enum.TextXAlignment.Center
    else
        mainWindow.Size = UDim2.new(0, 600, 0, 460)
        leftPanel.Visible = true
        rightPanel.Visible = true
        minimizeBtn.Text = "-"
        titleText.Position = UDim2.new(0.02,0,0,0)
        titleText.TextXAlignment = Enum.TextXAlignment.Left
    end
end)

-- 关闭面板
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- 飞行开关切换
flyToggle.MouseButton1Click:Connect(function()
    config.FlyEnable = not config.FlyEnable
    if config.FlyEnable then
        flyToggle.BackgroundColor3 = Color3.fromRGB(156,20,20)
        flyToggle.Text = "关"
        if rootPart then
            rootPart.CanCollide = false
            humanoid.GravityScale = 0
        end
    else
        flyToggle.BackgroundColor3 = Color3.fromRGB(21,158,43)
        flyToggle.Text = "开"
        if rootPart then
            rootPart.CanCollide = true
            humanoid.GravityScale = 1
        end
    end
end)

-- 速度增减
speedAdd.MouseButton1Click:Connect(function()
    config.FlySpeed += 5
    speedNum.Text = config.FlySpeed
end)
speedMinus.MouseButton1Click:Connect(function()
    if config.FlySpeed > 10 then
        config.FlySpeed -= 5
        speedNum.Text = config.FlySpeed
    end
end)

-- 刷新角色部件（修复重生失效）
local function updateCharacter()
    local char = plr.Character or plr.CharacterAdded:Wait()
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    bodyVelocity = nil
    -- 重生同步飞行状态
    if config.FlyEnable then
        rootPart.CanCollide = false
        humanoid.GravityScale = 0
    end
end
plr.CharacterAdded:Connect(updateCharacter)
updateCharacter()

-- 优化飞行物理，不会穿墙卡顿
RunService.RenderStepped:Connect(function()
    if not config.FlyEnable or not rootPart or not humanoid then return end
    local moveDir = humanoid.MoveDirection
    local upVector = Vector3.new(0,0,0)

    if humanoid.Jump then
        upVector = Vector3.new(0,1,0)
    elseif humanoid.Crouching then
        upVector = Vector3.new(0,-1,0)
    end

    local targetVelocity = (moveDir + upVector) * config.FlySpeed
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = targetVelocity
        bodyVelocity.Parent = rootPart
    end
    bodyVelocity.Velocity = targetVelocity
end)
