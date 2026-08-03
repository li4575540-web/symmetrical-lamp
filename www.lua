--服务引用
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--玩家基础信息
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--全局设置参数（可自行修改数值）
local Settings = {
    FlyEnabled = false,
    MoveSpeed = 60,
    UpDownSpeed = 35,
    UI_X = 0.01,
    UI_Y = 0.4
}

--角色变量初始化
local Character
local Humanoid
local RootPart

-- ===================== 搭建控制面板UI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlySystem_StudyOnly"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--主面板框架
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 220)
MainFrame.Position = UDim2.new(Settings.UI_X, 0, Settings.UI_Y, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderColor3 = Color3.fromRGB(80,80,80)
MainFrame.BorderSizePixel = 2
MainFrame.Parent = ScreenGui

--标题文字
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "飞行调试面板"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

--开启/关闭飞行按钮
local ToggleFlyBtn = Instance.new("TextButton")
ToggleFlyBtn.Size = UDim2.new(0.85,0,0,36)
ToggleFlyBtn.Position = UDim2.new(0.075,0,0.18,0)
ToggleFlyBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
ToggleFlyBtn.Text = "开启飞行"
ToggleFlyBtn.TextColor3 = Color3.new(1,1,1)
ToggleFlyBtn.Parent = MainFrame

--速度调节文字
local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(1,0,0,24)
SpeedText.Position = UDim2.new(0,0,0.42,0)
SpeedText.BackgroundTransparency = 1
SpeedText.Text = "当前移速："..Settings.MoveSpeed
SpeedText.TextColor3 = Color3.new(1,1,1)
SpeedText.TextSize = 14
SpeedText.Parent = MainFrame

--提速按钮
local SpeedUp = Instance.new("TextButton")
SpeedUp.Size = UDim2.new(0.38,0,0,32)
SpeedUp.Position = UDim2.new(0.07,0,0.52,0)
SpeedUp.Text = "+速度"
SpeedUp.BackgroundColor3 = Color3.fromRGB(30,90,180)
SpeedUp.TextColor3 = Color3.white
SpeedUp.Parent = MainFrame

--减速按钮
local SpeedDown = Instance.new("TextButton")
SpeedDown.Size = UDim2.new(0.38,0,0,32)
SpeedDown.Position = UDim2.new(0.55,0,0.52,0)
SpeedDown.Text = "-速度"
SpeedDown.BackgroundColor3 = Color3.fromRGB(180,60,30)
SpeedDown.TextColor3 = Color3.white
SpeedDown.Parent = MainFrame

--操作说明
local Tips = Instance.new("TextLabel")
Tips.Size = UDim2.new(0.9,0,0,55)
Tips.Position = UDim2.new(0.05,0,0.68,0)
Tips.BackgroundTransparency = 1
Tips.TextWrapped = true
Tips.TextSize = 11
Tips.TextColor3 = Color3.fromRGB(220,220,220)
Tips.Text = "WASD前后左右\n空格上升 | Ctrl下降"
Tips.Parent = MainFrame

-- ===================== 角色加载函数 =====================
local function RefreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    --关闭重力恢复默认
    if Settings.FlyEnabled then
        Humanoid.GravityScale = 1
        Settings.FlyEnabled = false
        ToggleFlyBtn.Text = "开启飞行"
        ToggleFlyBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
    end
end

--初始加载+重生重新加载
RefreshCharacter()
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)

-- ===================== 按钮功能逻辑 =====================
--开关飞行
ToggleFlyBtn.MouseButton1Click:Connect(function()
    Settings.FlyEnabled = not Settings.FlyEnabled
    if Settings.FlyEnabled then
        ToggleFlyBtn.Text = "关闭飞行"
        ToggleFlyBtn.BackgroundColor3 = Color3.fromRGB(160,30,30)
        Humanoid.GravityScale = 0
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    else
        ToggleFlyBtn.Text = "开启飞行"
        ToggleFlyBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
        Humanoid.GravityScale = 1
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    end
end)

--增加移动速度
SpeedUp.MouseButton1Click:Connect(function()
    Settings.MoveSpeed += 5
    SpeedText.Text = "当前移速："..Settings.MoveSpeed
end)

--降低移动速度
SpeedDown.MouseButton1Click:Connect(function()
    if Settings.MoveSpeed > 10 then
        Settings.MoveSpeed -= 5
        SpeedText.Text = "当前移速："..Settings.MoveSpeed
    end
end)

--记录按键按下状态
local KeyStates = {}
UserInputService.InputBegan:Connect(function(input)
    KeyStates[input.KeyCode] = true
end)
UserInputService.InputEnded:Connect(function(input)
    KeyStates[input.KeyCode] = false
end)

--每一帧刷新飞行位置
RunService.RenderStepped:Connect(function()
    if not Settings.FlyEnabled or not RootPart then return end
    local Camera = workspace.CurrentCamera
    local MoveDir = Vector3.new(0,0,0)

    --前后左右
    if KeyStates[Enum.KeyCode.W] then MoveDir += Camera.CFrame.LookVector end
    if KeyStates[Enum.KeyCode.S] then MoveDir -= Camera.CFrame.LookVector end
    if KeyStates[Enum.KeyCode.A] then MoveDir -= Camera.CFrame.RightVector end
    if KeyStates[Enum.KeyCode.D] then MoveDir += Camera.CFrame.RightVector end

    --升降
    if KeyStates[Enum.KeyCode.Space] then MoveDir += Vector3.new(0,1,0) end
    if KeyStates[Enum.KeyCode.LeftControl] then MoveDir -= Vector3.new(0,1,0) end

    --归一化防止斜向过快
    if MoveDir.Magnitude > 0 then
        MoveDir = MoveDir.Unit * Settings.MoveSpeed
    end

    RootPart.Velocity = MoveDir
end)
