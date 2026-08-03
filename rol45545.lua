local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local PlayerGui = plr.PlayerGui

local Settings = {
    Fly = false,
    Speed = 35,
    JumpEnhance = false,
    JumpPower = 1.4,
    NoClip = false
}
local RootPart, Humanoid

local Screen = Instance.new("ScreenGui")
Screen.IgnoreGuiInset = true
Screen.Parent = PlayerGui

-- 主窗口Window
local MainWin = Instance.new("Frame")
MainWin.Size = UDim2.new(0, 530, 0, 430)
MainWin.Position = UDim2.new(0.02,0,0.1,0)
MainWin.BackgroundColor3 = Color3.fromRGB(20,20,24)
MainWin.BorderColor3 = Color3.fromRGB(40,40,48)
MainWin.BorderSizePixel = 2
MainWin.ClipsDescendants = true
MainWin.Parent = Screen

-- 顶部可拖动标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,38)
TitleBar.BackgroundColor3 = Color3.fromRGB(12,12,16)
TitleBar.Parent = MainWin

-- 左上角名称：小木
local TopName = Instance.new("TextLabel")
TopName.Size = UDim2.new(0.2,0,1,0)
TopName.Position = UDim2.new(0.02,0,0,0)
TopName.BackgroundTransparency = 1
TopName.Text = "小木"
TopName.TextColor3 = Color3.fromRGB(180,220,255)
TopName.Font = Enum.Font.SourceSansBold
TopName.TextSize = 16
TopName.TextXAlignment = Enum.TextXAlignment.Left
TopName.Parent = TitleBar

-- 关闭按钮
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,38,0,38)
CloseBtn.Position = UDim2.new(1,-38,0,0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(160,20,20)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.white
CloseBtn.Parent = TitleBar

-- 左右分区 左侧分类 + 右侧功能区
local LeftMenu = Instance.new("Frame")
LeftMenu.Size = UDim2.new(0.28,0,1,-38)
LeftMenu.Position = UDim2.new(0,0,0,38)
LeftMenu.BackgroundColor3 = Color3.fromRGB(26,26,30)
LeftMenu.Parent = MainWin

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.72,0,1,-38)
RightPanel.Position = UDim2.new(0.28,0,0,38)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = MainWin

-- 左侧菜单文字
local MenuText = Instance.new("TextLabel")
MenuText.Size = UDim2.new(0.9,0,0,36)
MenuText.Position = UDim2.new(0.05,0,0.04,0)
MenuText.BackgroundTransparency = 1
MenuText.Text = "移动功能"
MenuText.TextColor3 = Color3.new(1,1,1)
MenuText.TextSize = 14
MenuText.Parent = LeftMenu

-- ========= 右侧功能项 样式参考你的截图 =========
-- 1.飞行开关
local FlyFrame = Instance.new("Frame")
FlyFrame.Size = UDim2.new(0.96,0,0,46)
FlyFrame.Position = UDim2.new(0.02,0,0.03,0)
FlyFrame.BackgroundColor3 = Color3.fromRGB(28,28,32)
FlyFrame.Parent = RightPanel

local FlyText = Instance.new("TextLabel")
FlyText.Size = UDim2.new(0.7,0,1,0)
FlyText.Position = UDim2.new(0.03,0,0,0)
FlyText.BackgroundTransparency = 1
FlyText.Text = "开启飞行"
FlyText.TextColor3 = Color3.white
FlyText.TextSize = 13
FlyText.Parent = FlyFrame

local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.new(0,42,0,26)
FlyToggle.Position = UDim2.new(0.92,0,0.22,0)
FlyToggle.BackgroundColor3 = Color3.fromRGB(22,160,45)
FlyToggle.Text = "开"
FlyToggle.TextColor3 = Color3.white
FlyToggle.Parent = FlyFrame

-- 2.速度调节
local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(0.96,0,0,46)
SpeedFrame.Position = UDim2.new(0.02,0,0.15,0)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(28,28,32)
SpeedFrame.Parent = RightPanel

local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(0.4,0,1,0)
SpeedText.Position = UDim2.new(0.03,0,0,0)
SpeedText.BackgroundTransparency = 1
SpeedText.Text = "移动速度"
SpeedText.TextColor3 = Color3.white
SpeedText.TextSize = 13
SpeedText.Parent = SpeedFrame

local SpeedValue = Instance.new("TextLabel")
SpeedValue.Size = UDim2.new(0.2,0,1,0)
SpeedValue.Position = UDim2.new(0.7,0,0,0)
SpeedValue.BackgroundTransparency = 1
SpeedValue.Text = Settings.Speed
SpeedValue.TextColor3 = Color3.white
SpeedValue.TextSize = 13
SpeedValue.Parent = SpeedFrame

local SpeedAdd = Instance.new("TextButton")
SpeedAdd.Size = UDim2.new(0,28,0,28)
SpeedAdd.Position = UDim2.new(0.62,0,0.18,0)
SpeedAdd.Text = "+"
SpeedAdd.BackgroundColor3 = Color3.fromRGB(30,120,200)
SpeedAdd.TextColor3 = Color3.white
SpeedAdd.Parent = SpeedFrame

local SpeedMinus = Instance.new("TextButton")
SpeedMinus.Size = UDim2.new(0,28,0,28)
SpeedMinus.Position = UDim2.new(0.54,0,0.18,0)
SpeedMinus.Text = "-"
SpeedMinus.BackgroundColor3 = Color3.fromRGB(30,120,200)
SpeedMinus.TextColor3 = Color3.white
SpeedMinus.Parent = SpeedFrame

-- 窗口拖动（手机触屏）
local drag = false
local dragStart, winStart
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragStart = input.Position
        winStart = MainWin.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if drag and input.UserInputType == Enum.UserInputType.Touch then
        local offset = input.Position - dragStart
        MainWin.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + offset.X, winStart.Y.Scale, winStart.Y.Offset + offset.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    drag = false
end)

-- 关闭面板
CloseBtn.MouseButton1Click:Connect(function()
    Screen:Destroy()
end)

-- 飞行开关逻辑
FlyToggle.MouseButton1Click:Connect(function()
    Settings.Fly = not Settings.Fly
    if Settings.Fly then
        FlyToggle.BackgroundColor3 = Color3.fromRGB(170,20,20)
        FlyToggle.Text = "关"
    else
        FlyToggle.BackgroundColor3 = Color3.fromRGB(22,160,45)
        FlyToggle.Text = "开"
    end
end)

-- 增减速度
SpeedAdd.MouseButton1Click:Connect(function()
    Settings.Speed = Settings.Speed + 5
    SpeedValue.Text = Settings.Speed
end)
SpeedMinus.MouseButton1Click:Connect(function()
    if Settings.Speed > 10 then
        Settings.Speed = Settings.Speed - 5
        SpeedValue.Text = Settings.Speed
    end
end)

-- 刷新角色
local function RefreshChar()
    local char = plr.Character or plr.CharacterAdded:Wait()
    RootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end
RefreshChar()
plr.CharacterAdded:Connect(RefreshChar)

-- 飞行运行逻辑
RunService.RenderStepped:Connect(function()
    if not Settings.Fly or not RootPart or not Humanoid then return end
    local moveDir = Humanoid.MoveDirection
    local upDir = Vector3.new(0,0,0)
    if Humanoid.Jump then upDir = Vector3.new(0,1,0) end
    if Humanoid.Crouching then upDir = Vector3.new(0,-1,0) end
    RootPart.CFrame += (moveDir + upDir) * Settings.Speed * RunService.RenderStepped:Wait()
end)
