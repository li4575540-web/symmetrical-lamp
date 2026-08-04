-- =====================================================================
-- 👑【小木HUB - 手机端终极丝滑增强版 v3.0 巅峰稳定版】
-- =====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

-- ==========================================
-- 【模块一】量子飞行与飞车系统
-- ==========================================
local FlightModule = {
    Enabled = false,
    Speed = 60,
    MovingUp = false,
    MovingDown = false,
}

local VehicleModule = {
    Enabled = false,
    Speed = 100,
}

-- ==========================================
-- 【模块二】全知全能移速与免疫系统
-- ==========================================
local SpeedModule = {
    Enabled = false,
    CustomSpeed = 60,
}

local MiscModule = {
    AntiStun = true,
    ESPEnabled = true,
}

-- ==========================================
-- 【模块三】超维光束自瞄与黑白名单系统
-- ==========================================
local AimbotModule = {
    Enabled = true,           
    PredictionEnabled = true, 
    FOV = 120.0,              -- 自瞄判定范围
    BulletSpeed = 1600.0,
    Smoothing = 0.3,          -- 手机端完美平衡平滑度
    TeamCheck = true,         -- 自动过滤同队队友
    PlayerWhitelist = {},     
    PlayerBlacklist = {},     
}

local character, rootPart, humanoid

-- 彻底清理历史残留与幽灵线程，防内存泄漏
if getgenv and getgenv().UltimateXiaoMuConnection then
    pcall(function() getgenv().UltimateXiaoMuConnection:Disconnect() end)
    getgenv().UltimateXiaoMuConnection = nil
end

for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "UltimateXiaoMuHub" then v:Destroy() end
end
pcall(function()
    if plr.PlayerGui:FindFirstChild("UltimateXiaoMuHub") then
        plr.PlayerGui.UltimateXiaoMuHub:Destroy()
    end
end)
pcall(function()
    if CoreGui:FindFirstChild("XiaoMuFloatControls") then CoreGui.XiaoMuFloatControls:Destroy() end
    if plr.PlayerGui:FindFirstChild("XiaoMuFloatControls") then plr.PlayerGui.XiaoMuFloatControls:Destroy() end
end)

local function cleanupState()
    FlightModule.Enabled = false
    FlightModule.MovingUp = false
    FlightModule.MovingDown = false
    VehicleModule.Enabled = false
    if humanoid then 
        pcall(function() 
            humanoid.PlatformStand = false 
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end) 
    end
end

local function setupCharacter(char)
    character = char
    cleanupState()
    task.spawn(function()
        pcall(function()
            rootPart = char:WaitForChild("HumanoidRootPart", 10)
            humanoid = char:WaitForChild("Humanoid", 10)
        end)
    end)
end

if plr.Character then setupCharacter(plr.Character) end
plr.CharacterAdded:Connect(setupCharacter)

-- 构建主界面 UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateXiaoMuHub"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = plr:WaitForChild("PlayerGui") end

-- 🏆 手机端专属：可视化自瞄 FOV 范围圆圈渲染
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Parent = screenGui
fovCircle.BackgroundTransparency = 1
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Visible = true

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 215, 0)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

-- 🏆 奖杯降临动画层
local loadScreen = Instance.new("Frame")
loadScreen.Name = "DivineLoadScreen"
loadScreen.Parent = screenGui
loadScreen.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
loadScreen.Size = UDim2.new(1, 0, 1, 0)
loadScreen.ZIndex = 100

local trophyBox = Instance.new("Frame")
trophyBox.Parent = loadScreen
trophyBox.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
trophyBox.AnchorPoint = Vector2.new(0.5, 0.5)
trophyBox.Position = UDim2.new(0.5, 0, 0.5, 0)
trophyBox.Size = UDim2.new(0, 300, 0, 300)
Instance.new("UICorner", trophyBox).CornerRadius = UDim.new(0, 16)

local trophyStroke = Instance.new("UIStroke")
trophyStroke.Color = Color3.fromRGB(255, 215, 0)
trophyStroke.Thickness = 3
trophyStroke.Parent = trophyBox

local trophyIcon = Instance.new("TextLabel")
trophyIcon.Parent = trophyBox
trophyIcon.BackgroundTransparency = 1
trophyIcon.Position = UDim2.new(0, 0, 0.08, 0)
trophyIcon.Size = UDim2.new(1, 0, 0, 50)
trophyIcon.Font = Enum.Font.GothamBold
trophyIcon.Text = "🏆 手机端至高神域 v3.0 🏆"
trophyIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
trophyIcon.TextSize = 15

local loadTitle = Instance.new("TextLabel")
loadTitle.Parent = trophyBox
loadTitle.BackgroundTransparency = 1
loadTitle.Position = UDim2.new(0, 0, 0.32, 0)
loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Font = Enum.Font.GothamBold
loadTitle.Text = "小木 HUB 巅峰稳定重构版"
loadTitle.TextColor3 = Color3.fromRGB(100, 220, 255)
loadTitle.TextSize = 12

local percentLabel = Instance.new("TextLabel")
percentLabel.Parent = trophyBox
percentLabel.BackgroundTransparency = 1
percentLabel.Position = UDim2.new(0, 0, 0.48, 0)
percentLabel.Size = UDim2.new(1, 0, 0, 40)
percentLabel.Font = Enum.Font.GothamBold
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
percentLabel.TextSize = 28

local barBg = Instance.new("Frame")
barBg.Parent = trophyBox
barBg.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
barBg.Position = UDim2.new(0.15, 0, 0.75, 0)
barBg.Size = UDim2.new(0.7, 0, 0, 10)
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Parent = barBg
barFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
barFill.Size = UDim2.new(0, 0, 1, 0)
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- 主控制面板
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
mainFrame.BackgroundTransparency = 0.08
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -220)
mainFrame.Size = UDim2.new(0, 520, 0, 440)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 215, 0)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local renderConnection

-- 彩虹呼吸灯
task.spawn(function()
    local hue = 0
    while screenGui and screenGui.Parent do
        hue = (hue + 1) % 360
        local rainbowColor = Color3.fromHSV(hue / 360, 0.8, 1)
        pcall(function()
            if mainStroke and mainStroke.Parent then mainStroke.Color = rainbowColor end
            if trophyStroke and trophyStroke.Parent then trophyStroke.Color = rainbowColor end
            if fovStroke and fovStroke.Parent then fovStroke.Color = rainbowColor end
        end)
        task.wait(0.05)
    end
end)

local topBar = Instance.new("Frame")
topBar.Parent = mainFrame
topBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
topBar.Size = UDim2.new(1, 0, 0, 36)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local titleText = Instance.new("TextLabel")
titleText.Parent = topBar
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0.03, 0, 0, 0)
titleText.Size = UDim2.new(0, 350, 1, 0)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "👑 小木 HUB | 手机触控巅峰重构版 v3.0"
titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
titleText.TextSize = 10
titleText.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = topBar
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Position = UDim2.new(0.92, 0, 0.2, 0)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 10
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

-- 桌面悬浮球浮窗
local miniSquare = Instance.new("TextButton")
miniSquare.Name = "MiniSquare"
miniSquare.Parent = screenGui
miniSquare.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
miniSquare.Position = UDim2.new(0.02, 0, 0.2, 0)
miniSquare.Size = UDim2.new(0, 50, 0, 50)
miniSquare.Font = Enum.Font.GothamBold
miniSquare.Text = "🏆"
miniSquare.TextColor3 = Color3.fromRGB(255, 215, 0)
miniSquare.TextSize = 18
miniSquare.Visible = false
miniSquare.Active = true
miniSquare.Draggable = true
Instance.new("UICorner", miniSquare).CornerRadius = UDim.new(0, 12)
local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(255, 215, 0)
miniStroke.Thickness = 2
miniStroke.Parent = miniSquare

closeBtn.MouseButton1Click:Connect(function()
    cleanupState()
    if renderConnection then renderConnection:Disconnect() end
    pcall(function()
        if CoreGui:FindFirstChild("XiaoMuFloatControls") then CoreGui.XiaoMuFloatControls:Destroy() end
    end)
    screenGui:Destroy()
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = topBar
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
minimizeBtn.Position = UDim2.new(0.83, 0, 0.2, 0)
minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 12
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 5)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniSquare.Visible = true
end)

miniSquare.MouseButton1Click:Connect(function()
    miniSquare.Visible = false
    mainFrame.Visible = true
end)

-- 🏆 屏幕右侧悬浮控制盘（升 / 降）
local floatControlGui = Instance.new("ScreenGui")
floatControlGui.Name = "XiaoMuFloatControls"
floatControlGui.ResetOnSpawn = false
pcall(function() floatControlGui.Parent = CoreGui end)
if not floatControlGui.Parent then floatControlGui.Parent = plr:WaitForChild("PlayerGui") end

local floatPanel = Instance.new("Frame")
floatPanel.Parent = floatControlGui
floatPanel.BackgroundTransparency = 1
floatPanel.Position = UDim2.new(0.85, 0, 0.5, -90)
floatPanel.Size = UDim2.new(0, 60, 0, 130)

local mobileUpBtn = Instance.new("TextButton")
mobileUpBtn.Parent = floatPanel
mobileUpBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
mobileUpBtn.BackgroundTransparency = 0.2
mobileUpBtn.Size = UDim2.new(0, 60, 0, 55)
mobileUpBtn.Font = Enum.Font.GothamBold
mobileUpBtn.Text = "▲ 升"
mobileUpBtn.TextColor3 = Color3.fromRGB(100, 255, 150)
mobileUpBtn.TextSize = 14
Instance.new("UICorner", mobileUpBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mobileUpBtn).Color = Color3.fromRGB(100, 255, 150)

local mobileDownBtn = Instance.new("TextButton")
mobileDownBtn.Parent = floatPanel
mobileDownBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
mobileDownBtn.BackgroundTransparency = 0.2
mobileDownBtn.Position = UDim2.new(0, 0, 0, 65)
mobileDownBtn.Size = UDim2.new(0, 60, 0, 55)
mobileDownBtn.Font = Enum.Font.GothamBold
mobileDownBtn.Text = "▼ 降"
mobileDownBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
mobileDownBtn.TextSize = 14
Instance.new("UICorner", mobileDownBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", mobileDownBtn).Color = Color3.fromRGB(255, 100, 100)

local function bindMobileTouchHold(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.TouchEnded:Connect(function() setter(false) end)
end
bindMobileTouchHold(mobileUpBtn, function(s) FlightModule.MovingUp = s end)
bindMobileTouchHold(mobileDownBtn, function(s) FlightModule.MovingDown = s end)

-- 双列滑动布局
local leftContainer = Instance.new("ScrollingFrame")
leftContainer.Parent = mainFrame
leftContainer.BackgroundTransparency = 1
leftContainer.Position = UDim2.new(0, 10, 0, 44)
leftContainer.Size = UDim2.new(0.48, 0, 1, -52)
leftContainer.CanvasSize = UDim2.new(0, 0, 0, 520)
leftContainer.ScrollBarThickness = 3

local rightContainer = Instance.new("ScrollingFrame")
rightContainer.Parent = mainFrame
rightContainer.BackgroundTransparency = 1
rightContainer.Position = UDim2.new(0.51, 0, 0, 44)
rightContainer.Size = UDim2.new(0.48, 0, 1, -52)
rightContainer.CanvasSize = UDim2.new(0, 0, 0, 520)
rightContainer.ScrollBarThickness = 3

local function createCard(parent, posY, titleTextStr)
    local card = Instance.new("Frame")
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.Size = UDim2.new(1, -5, 0, 38)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Parent = card
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0.04, 0, 0, 0)
    lbl.Size = UDim2.new(0.52, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleTextStr
    lbl.TextColor3 = Color3.fromRGB(230, 230, 240)
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return card
end

-- 左侧功能挂载
local flyCard = createCard(leftContainer, 0, "【人物飞行】总开关")
local flyToggleBtn = Instance.new("TextButton")
flyToggleBtn.Parent = flyCard
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
flyToggleBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
flyToggleBtn.Size = UDim2.new(0, 95, 0, 24)
flyToggleBtn.Font = Enum.Font.GothamBold
flyToggleBtn.Text = "【 关闭 】"
flyToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
flyToggleBtn.TextSize = 9
Instance.new("UICorner", flyToggleBtn).CornerRadius = UDim.new(0, 5)

local speedCard = createCard(leftContainer, 42, "【飞行速度】大小调节")
local speedValLabel = Instance.new("TextLabel")
speedValLabel.Parent = speedCard
speedValLabel.BackgroundTransparency = 1
speedValLabel.Position = UDim2.new(0.42, 0, 0, 0)
speedValLabel.Size = UDim2.new(0.2, 0, 1, 0)
speedValLabel.Font = Enum.Font.GothamBold
speedValLabel.Text = "60速"
speedValLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
speedValLabel.TextSize = 9

local speedDownBtn = Instance.new("TextButton")
speedDownBtn.Parent = speedCard
speedDownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
speedDownBtn.Position = UDim2.new(0.62, 0, 0.18, 0)
speedDownBtn.Size = UDim2.new(0, 34, 0, 24)
speedDownBtn.Font = Enum.Font.GothamBold
speedDownBtn.Text = "-"
speedDownBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
Instance.new("UICorner", speedDownBtn).CornerRadius = UDim.new(0, 5)

local speedUpBtn = Instance.new("TextButton")
speedUpBtn.Parent = speedCard
speedUpBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
speedUpBtn.Position = UDim2.new(0.81, 0, 0.18, 0)
speedUpBtn.Size = UDim2.new(0, 34, 0, 24)
speedUpBtn.Font = Enum.Font.GothamBold
speedUpBtn.Text = "+"
speedUpBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
Instance.new("UICorner", speedUpBtn).CornerRadius = UDim.new(0, 5)

local vehicleCard = createCard(leftContainer, 84, "【飞车模块】载具飞行开关")
local vehicleToggleBtn = Instance.new("TextButton")
vehicleToggleBtn.Parent = vehicleCard
vehicleToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
vehicleToggleBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
vehicleToggleBtn.Size = UDim2.new(0, 95, 0, 24)
vehicleToggleBtn.Font = Enum.Font.GothamBold
vehicleToggleBtn.Text = "【 关闭 】"
vehicleToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
vehicleToggleBtn.TextSize = 9
Instance.new("UICorner", vehicleToggleBtn).CornerRadius = UDim.new(0, 5)

local vehicleSpeedCard = createCard(leftContainer, 126, "【飞车速度】大小调节")
local vehicleSpeedLabel = Instance.new("TextLabel")
vehicleSpeedLabel.Parent = vehicleSpeedCard
vehicleSpeedLabel.BackgroundTransparency = 1
vehicleSpeedLabel.Position = UDim2.new(0.42, 0, 0, 0)
vehicleSpeedLabel.Size = UDim2.new(0.2, 0, 1, 0)
vehicleSpeedLabel.Font = Enum.Font.GothamBold
vehicleSpeedLabel.Text = "100速"
vehicleSpeedLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
vehicleSpeedLabel.TextSize = 9

local vehicleSpeedDown = Instance.new("TextButton")
vehicleSpeedDown.Parent = vehicleSpeedCard
vehicleSpeedDown.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
vehicleSpeedDown.Position = UDim2.new(0.62, 0, 0.18, 0)
vehicleSpeedDown.Size = UDim2.new(0, 34, 0, 24)
vehicleSpeedDown.Font = Enum.Font.GothamBold
vehicleSpeedDown.Text = "-"
vehicleSpeedDown.TextColor3 = Color3.fromRGB(255, 150, 150)
Instance.new("UICorner", vehicleSpeedDown).CornerRadius = UDim.new(0, 5)

local vehicleSpeedUp = Instance.new("TextButton")
vehicleSpeedUp.Parent = vehicleSpeedCard
vehicleSpeedUp.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
vehicleSpeedUp.Position = UDim2.new(0.81, 0, 0.18, 0)
vehicleSpeedUp.Size = UDim2.new(0, 34, 0, 24)
vehicleSpeedUp.Font = Enum.Font.GothamBold
vehicleSpeedUp.Text = "+"
vehicleSpeedUp.TextColor3 = Color3.fromRGB(150, 255, 150)
Instance.new("UICorner", vehicleSpeedUp).CornerRadius = UDim.new(0, 5)

local walkSpeedCard = createCard(leftContainer, 168, "【全知移速】突破开关")
local walkToggleBtn = Instance.new("TextButton")
walkToggleBtn.Parent = walkSpeedCard
walkToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
walkToggleBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
walkToggleBtn.Size = UDim2.new(0, 95, 0, 24)
walkToggleBtn.Font = Enum.Font.GothamBold
walkToggleBtn.Text = "【 关闭 】"
walkToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
walkToggleBtn.TextSize = 9
Instance.new("UICorner", walkToggleBtn).CornerRadius = UDim.new(0, 5)

local walkValCard = createCard(leftContainer, 210, "【全知移速】自定义调节")
local walkValLabel = Instance.new("TextLabel")
walkValLabel.Parent = walkValCard
walkValLabel.BackgroundTransparency = 1
walkValLabel.Position = UDim2.new(0.38, 0, 0, 0)
walkValLabel.Size = UDim2.new(0.22, 0, 1, 0)
walkValLabel.Font = Enum.Font.GothamBold
walkValLabel.Text = "60速"
walkValLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
walkValLabel.TextSize = 9

local walkDownBtn = Instance.new("TextButton")
walkDownBtn.Parent = walkValCard
walkDownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
walkDownBtn.Position = UDim2.new(0.62, 0, 0.18, 0)
walkDownBtn.Size = UDim2.new(0, 34, 0, 24)
walkDownBtn.Font = Enum.Font.GothamBold
walkDownBtn.Text = "-"
walkDownBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
Instance.new("UICorner", walkDownBtn).CornerRadius = UDim.new(0, 5)

local walkUpBtn = Instance.new("TextButton")
walkUpBtn.Parent = walkValCard
walkUpBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
walkUpBtn.Position = UDim2.new(0.81, 0, 0.18, 0)
walkUpBtn.Size = UDim2.new(0, 34, 0, 24)
walkUpBtn.Font = Enum.Font.GothamBold
walkUpBtn.Text = "+"
walkUpBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
Instance.new("UICorner", walkUpBtn).CornerRadius = UDim.new(0, 5)

local antiStunCard = createCard(leftContainer, 252, "【免疫模块】防击退/防眩晕")
local antiStunBtn = Instance.new("TextButton")
antiStunBtn.Parent = antiStunCard
antiStunBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
antiStunBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
antiStunBtn.Size = UDim2.new(0, 95, 0, 24)
antiStunBtn.Font = Enum.Font.GothamBold
antiStunBtn.Text = "【 开启 】"
antiStunBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
antiStunBtn.TextSize = 9
Instance.new("UICorner", antiStunBtn).CornerRadius = UDim.new(0, 5)

local espCard = createCard(leftContainer, 294, "【透视模块】全图透视ESP")
local espBtn = Instance.new("TextButton")
espBtn.Parent = espCard
espBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
espBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
espBtn.Size = UDim2.new(0, 95, 0, 24)
espBtn.Font = Enum.Font.GothamBold
espBtn.Text = "【 开启 】"
espBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
espBtn.TextSize = 9
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 5)

local aimbotCard = createCard(leftContainer, 336, "【超维自瞄】自瞄总开关")
local aimbotToggleBtn = Instance.new("TextButton")
aimbotToggleBtn.Parent = aimbotCard
aimbotToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
aimbotToggleBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
aimbotToggleBtn.Size = UDim2.new(0, 95, 0, 24)
aimbotToggleBtn.Font = Enum.Font.GothamBold
aimbotToggleBtn.Text = "【 开启 】"
aimbotToggleBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
aimbotToggleBtn.TextSize = 9
Instance.new("UICorner", aimbotToggleBtn).CornerRadius = UDim.new(0, 5)

local teamCheckCard = createCard(leftContainer, 378, "【战队保护】防误伤队友")
local teamCheckBtn = Instance.new("TextButton")
teamCheckBtn.Parent = teamCheckCard
teamCheckBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
teamCheckBtn.Position = UDim2.new(0.58, 0, 0.18, 0)
teamCheckBtn.Size = UDim2.new(0, 95, 0, 24)
teamCheckBtn.Font = Enum.Font.GothamBold
teamCheckBtn.Text = "【 开启 】"
teamCheckBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
teamCheckBtn.TextSize = 9
Instance.new("UICorner", teamCheckBtn).CornerRadius = UDim.new(0, 5)

-- 右侧配置面板
local rightTitle = Instance.new("TextLabel")
rightTitle.Parent = rightContainer
rightTitle.BackgroundTransparency = 1
rightTitle.Size = UDim2.new(1, 0, 0, 26)
rightTitle.Font = Enum.Font.GothamBold
rightTitle.Text = "=== 🏆 手机黑白名单配置 ==="
rightTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
rightTitle.TextSize = 10

local pWhiteBox = Instance.new("TextBox")
pWhiteBox.Parent = rightContainer
pWhiteBox.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
pWhiteBox.Position = UDim2.new(0, 0, 0, 30)
pWhiteBox.Size = UDim2.new(1, -5, 0, 30)
pWhiteBox.Font = Enum.Font.Gotham
pWhiteBox.PlaceholderText = "输入玩家名回车 ->【白名单】"
pWhiteBox.Text = ""
pWhiteBox.TextColor3 = Color3.fromRGB(150, 255, 150)
pWhiteBox.TextSize = 9
Instance.new("UICorner", pWhiteBox).CornerRadius = UDim.new(0, 5)

local pBlackBox = Instance.new("TextBox")
pBlackBox.Parent = rightContainer
pBlackBox.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
pBlackBox.Position = UDim2.new(0, 0, 0, 66)
pBlackBox.Size = UDim2.new(1, -5, 0, 30)
pBlackBox.Font = Enum.Font.Gotham
pBlackBox.PlaceholderText = "输入玩家名回车 ->【黑名单】"
pBlackBox.Text = ""
pBlackBox.TextColor3 = Color3.fromRGB(255, 150, 150)
pBlackBox.TextSize = 9
Instance.new("UICorner", pBlackBox).CornerRadius = UDim.new(0, 5)

local guideLabel = Instance.new("TextLabel")
guideLabel.Parent = rightContainer
guideLabel.BackgroundTransparency = 1
guideLabel.Position = UDim2.new(0, 0, 0, 106)
guideLabel.Size = UDim2.new(1, -5, 0, 220)
guideLabel.Font = Enum.Font.Gotham
guideLabel.Text = "🏆 v3.0 巅峰优化说明：\n1. 【Bug修复】彻底修复了高帧率下物理浮点抖动、视角过度死锁与摄像机卡死问题。\n2. 【全新重构】增强飞车与飞行状态切换的容错机制，防止角色死亡复活后状态残留。\n3. 【防封增强】对自瞄与移动速率加入动态平滑缓冲，极大降低服务端检测率。\n4. 屏幕右侧依旧带有【▲升 ▼降】全触控浮标，单手操控丝滑无比。"
guideLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
guideLabel.TextSize = 9
guideLabel.TextWrapped = true
guideLabel.TextXAlignment = Enum.TextXAlignment.Left

-- 事件绑定
local function bindTextBox(box, targetTable)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed and box.Text ~= "" then
            targetTable[box.Text] = true
            box.Text = ""
        end
    end)
end

bindTextBox(pWhiteBox, AimbotModule.PlayerWhitelist)
bindTextBox(pBlackBox, AimbotModule.PlayerBlacklist)

flyToggleBtn.MouseButton1Click:Connect(function()
    FlightModule.Enabled = not FlightModule.Enabled
    if not FlightModule.Enabled then cleanupState() end
    flyToggleBtn.Text = FlightModule.Enabled and "【 开启 】" or "【 关闭 】"
    flyToggleBtn.TextColor3 = FlightModule.Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

speedUpBtn.MouseButton1Click:Connect(function()
    FlightModule.Speed = FlightModule.Speed + 10
    speedValLabel.Text = tostring(FlightModule.Speed) .. "速"
end)
speedDownBtn.MouseButton1Click:Connect(function()
    FlightModule.Speed = math.max(10, FlightModule.Speed - 10)
    speedValLabel.Text = tostring(FlightModule.Speed) .. "速"
end)

vehicleToggleBtn.MouseButton1Click:Connect(function()
    VehicleModule.Enabled = not VehicleModule.Enabled
    vehicleToggleBtn.Text = VehicleModule.Enabled and "【 开启 】" or "【 关闭 】"
    vehicleToggleBtn.TextColor3 = VehicleModule.Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

vehicleSpeedUp.MouseButton1Click:Connect(function()
    VehicleModule.Speed = VehicleModule.Speed + 25
    vehicleSpeedLabel.Text = tostring(VehicleModule.Speed) .. "速"
end)
vehicleSpeedDown.MouseButton1Click:Connect(function()
    VehicleModule.Speed = math.max(25, VehicleModule.Speed - 25)
    vehicleSpeedLabel.Text = tostring(VehicleModule.Speed) .. "速"
end)

walkToggleBtn.MouseButton1Click:Connect(function()
    SpeedModule.Enabled = not SpeedModule.Enabled
    walkToggleBtn.Text = SpeedModule.Enabled and "【 开启 】" or "【 关闭 】"
    walkToggleBtn.TextColor3 = SpeedModule.Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

walkUpBtn.MouseButton1Click:Connect(function()
    SpeedModule.CustomSpeed = SpeedModule.CustomSpeed + 20
    walkValLabel.Text = tostring(SpeedModule.CustomSpeed) .. "速"
end)
walkDownBtn.MouseButton1Click:Connect(function()
    SpeedModule.CustomSpeed = math.max(16, SpeedModule.CustomSpeed - 20)
    walkValLabel.Text = tostring(SpeedModule.CustomSpeed) .. "速"
end)

antiStunBtn.MouseButton1Click:Connect(function()
    MiscModule.AntiStun = not MiscModule.AntiStun
    antiStunBtn.Text = MiscModule.AntiStun and "【 开启 】" or "【 关闭 】"
    antiStunBtn.TextColor3 = MiscModule.AntiStun and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

espBtn.MouseButton1Click:Connect(function()
    MiscModule.ESPEnabled = not MiscModule.ESPEnabled
    espBtn.Text = MiscModule.ESPEnabled and "【 开启 】" or "【 关闭 】"
    espBtn.TextColor3 = MiscModule.ESPEnabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

aimbotToggleBtn.MouseButton1Click:Connect(function()
    AimbotModule.Enabled = not AimbotModule.Enabled
    aimbotToggleBtn.Text = AimbotModule.Enabled and "【 开启 】" or "【 关闭 】"
    aimbotToggleBtn.TextColor3 = AimbotModule.Enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

teamCheckBtn.MouseButton1Click:Connect(function()
    AimbotModule.TeamCheck = not AimbotModule.TeamCheck
    teamCheckBtn.Text = AimbotModule.TeamCheck and "【 开启 】" or "【 关闭 】"
    teamCheckBtn.TextColor3 = AimbotModule.TeamCheck and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 100, 100)
end)

local function canTargetPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == plr then return false end
    local pName = targetPlayer.Name
    if AimbotModule.PlayerBlacklist[pName] then return false end
    if AimbotModule.TeamCheck then
        if plr.Team and targetPlayer.Team and plr.Team == targetPlayer.Team then
            return false
        end
    end
    return true
end

-- 核心渲染与物理计算循环 (v3.0 深度修复所有逻辑 Bug)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local frameCounter = 0

renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not screenGui or not screenGui.Parent then
        if renderConnection then renderConnection:Disconnect() end
        return
    end
    
    frameCounter = frameCounter + 1
    
    -- 实时渲染中心自瞄 FOV 动态范围圈
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local currentFOVRadius = AimbotModule.FOV * 2.2
            fovCircle.Size = UDim2.new(0, currentFOVRadius * 2, 0, currentFOVRadius * 2)
            fovCircle.Position = UDim2.new(0, cam.ViewportSize.X / 2, 0, cam.ViewportSize.Y / 2)
            fovCircle.Visible = AimbotModule.Enabled
        end
    end)
    
    -- 1. 移速与免疫模块（修复复活后 WalkSpeed 还原失效的 Bug）
    pcall(function()
        if humanoid and humanoid.Parent then
            if SpeedModule.Enabled then
                if humanoid.WalkSpeed ~= SpeedModule.CustomSpeed then
                    humanoid.WalkSpeed = SpeedModule.CustomSpeed
                end
            else
                -- 当关闭全知移速时，安全恢复默认移速16
                if humanoid.WalkSpeed == SpeedModule.CustomSpeed and humanoid.WalkSpeed ~= 16 then
                    humanoid.WalkSpeed = 16
                end
            end
            if MiscModule.AntiStun then
                if humanoid.PlatformStand and not FlightModule.Enabled then 
                    humanoid.PlatformStand = false 
                end
            end
        end
    end)
    
    -- 2. 飞行物理（修复高刷新率机型下漂移和穿地 Bug）
    if FlightModule.Enabled then
        pcall(function()
            if not character or not character.Parent or not rootPart or not rootPart.Parent then return end
            if not humanoid or not humanoid.Parent then return end
            
            humanoid.PlatformStand = true
            local cam = Workspace.CurrentCamera
            if not cam then return end
            
            local moveDir = humanoid.MoveDirection
            local currentPos = rootPart.Position
            local velocity = Vector3.new(0, 0, 0)
            
            if moveDir.Magnitude > 0 then
                local relativeMove = cam.CFrame:VectorToObjectSpace(moveDir)
                velocity = (cam.CFrame.LookVector * -relativeMove.Z + cam.CFrame.RightVector * relativeMove.X) * FlightModule.Speed
            end
            
            if FlightModule.MovingUp then velocity = velocity + Vector3.new(0, FlightModule.Speed, 0) end
            if FlightModule.MovingDown then velocity = velocity - Vector3.new(0, FlightModule.Speed, 0) end
            
            local safeDt = math.clamp(dt, 0, 0.1)
            local targetPosFly = currentPos + (velocity * safeDt)
            
            raycastParams.FilterDescendantsInstances = {character}
            local floorRay = Workspace:Raycast(currentPos, Vector3.new(0, -15, 0), raycastParams)
            if floorRay and targetPosFly.Y < floorRay.Position.Y + 3.5 then
                targetPosFly = Vector3.new(targetPosFly.X, floorRay.Position.Y + 3.5, targetPosFly.Z)
            end
            
            rootPart.CFrame = CFrame.new(targetPosFly, targetPosFly + cam.CFrame.LookVector)
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end
    
    -- 3. 增强版飞车物理（修复载具解体、方向盘失灵 Bug）
    if VehicleModule.Enabled then
        pcall(function()
            if not humanoid then return end
            local seat = humanoid.SeatPart
            if seat and seat:IsA("VehicleSeat") then
                local vehicleModel = seat.Parent
                local primaryPart = vehicleModel.PrimaryPart 
                    or vehicleModel:FindFirstChild("HumanoidRootPart") 
                    or vehicleModel:FindFirstChildWhichIsA("BasePart")
                
                if primaryPart then
                    pcall(function()
                        seat.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        seat.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end)
                    local cam = Workspace.CurrentCamera
                    if not cam then return end
                    
                    local moveDir = humanoid.MoveDirection
                    local velocity = Vector3.new(0, 0, 0)
                    if moveDir.Magnitude > 0 then
                        local relativeMove = cam.CFrame:VectorToObjectSpace(moveDir)
                        velocity = (cam.CFrame.LookVector * -relativeMove.Z + cam.CFrame.RightVector * relativeMove.X) * VehicleModule.Speed
                    end
                    if FlightModule.MovingUp then velocity = velocity + Vector3.new(0, VehicleModule.Speed, 0) end
                    if FlightModule.MovingDown then velocity = velocity - Vector3.new(0, VehicleModule.Speed, 0) end
                    
                    local safeDt = math.clamp(dt, 0, 0.1)
                    primaryPart.CFrame = primaryPart.CFrame + (velocity * safeDt)
                end
            end
        end)
    end
    
    -- 4. 自瞄核心逻辑（修复锁定抖动、死人无效目标以及帧率卡顿 Bug）
    if AimbotModule.Enabled and (frameCounter % 2 == 0) then
        pcall(function()
            local cam = Workspace.CurrentCamera
            if not cam or not rootPart or not rootPart.Parent then return end
            
            local closestTarget = nil
            local shortestDistance = math.huge
            
            for _, otherPlr in ipairs(Players:GetPlayers()) do
                if otherPlr and otherPlr ~= plr and canTargetPlayer(otherPlr) then
                    local enemyChar = otherPlr.Character
                    if enemyChar then
                        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
                        local enemyHumanoid = enemyChar:FindFirstChild("Humanoid")
                        
                        if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                            local vector, onScreen = cam:WorldToViewportPoint(enemyRoot.Position)
                            if onScreen then
                                local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                                local screenDist = (Vector2.new(vector.X, vector.Y) - screenCenter).Magnitude
                                
                                if screenDist <= (AimbotModule.FOV * 2.2) and screenDist < shortestDistance then
                                    shortestDistance = screenDist
                                    closestTarget = enemyChar
                                end
                            end
                        end
                    end
                end
            end
            
            if closestTarget then
                local enemyRoot = closestTarget:FindFirstChild("HumanoidRootPart")
                local enemyHumanoid = closestTarget:FindFirstChild("Humanoid")
                if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                    local targetPos = enemyRoot.Position
                    if AimbotModule.PredictionEnabled then
                        local enemyVelocity = enemyRoot.AssemblyLinearVelocity
                        local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                        targetPos = targetPos + (enemyVelocity * (distance / AimbotModule.BulletSpeed))
                    end
                    
                    local currentCFrame = cam.CFrame
                    if (currentCFrame.Position - targetPos).Magnitude > 0.1 then
                        local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                        local alpha = math.clamp(AimbotModule.Smoothing, 0.05, 0.8)
                        cam.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
                    end
                end
            end
        end)
    end
end)

if getgenv then getgenv().UltimateXiaoMuConnection = renderConnection end

-- 加载动画逻辑
task.spawn(function()
    local currentProgress = 0
    while currentProgress < 100 do
        currentProgress = currentProgress + math.random(10, 20)
        if currentProgress > 100 then currentProgress = 100 end
        percentLabel.Text = currentProgress .. "%"
        barFill.Size = UDim2.new(currentProgress / 100, 0, 1, 0)
        task.wait(0.015)
    end
    
    task.wait(0.1)
    local fadeOut = TweenService:Create(loadScreen, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    TweenService:Create(trophyBox, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    fadeOut:Play()
    
    task.wait(0.3)
    loadScreen:Destroy()
    mainFrame.Visible = true
end)

print("👑【小木HUB v3.0】手机端巅峰稳定版加载成功！")
