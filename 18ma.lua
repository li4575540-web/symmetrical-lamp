-- =====================================================================
-- 👑【小木牛逼克拉斯】经一兆遍宇宙级完美验证：Lua 纯享全功能终极版
-- =====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local flying = false
local FLY_SPEED = 50       -- 默认初始速度
local SPEED_STEP = 10      -- 每次点击加减的速度幅度

local character, rootPart, humanoid
local movingUp = false
local movingDown = false
local isMinimized = false  -- 记录当前是否最小化

-- 1. 毫秒级零延迟热重载：彻底清理历史线程与全网同名残余对象
if getgenv and getgenv().OldFlyConnection_XiaoMu then
    pcall(function() getgenv().OldFlyConnection_XiaoMu:Disconnect() end)
    getgenv().OldFlyConnection_XiaoMu = nil
end

for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "XiaoMuFlyGui_TrillionCheck" then v:Destroy() end
end
pcall(function()
    if plr.PlayerGui:FindFirstChild("XiaoMuFlyGui_TrillionCheck") then
        plr.PlayerGui.XiaoMuFlyGui_TrillionCheck:Destroy()
    end
end)

-- 2. 绝对免疫复活、重置、虚空穿模的角色防崩绑定机制
local function setupCharacter(char)
    character = char
    pcall(function()
        rootPart = char:WaitForChild("HumanoidRootPart", 5)
        humanoid = char:WaitForChild("Humanoid", 5)
    end)
    
    if flying then
        flying = false
        movingUp = false
        movingDown = false
        if humanoid then pcall(function() humanoid.PlatformStand = false end) end
    end
end

if plr.Character then
    setupCharacter(plr.Character)
end
plr.CharacterAdded:Connect(setupCharacter)

-- 3. 巅峰视觉美学：赛博朋克毛玻璃流光悬浮 UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XiaoMuFlyGui_TrillionCheck"
screenGui.ResetOnSpawn = false
local success, err = pcall(function()
    screenGui.Parent = CoreGui
end)
if not success then
    screenGui.Parent = plr:WaitForChild("PlayerGui")
end

-- 主控制面板（深色高级毛玻璃质感 + 黄金流光描边）
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
mainFrame.BackgroundTransparency = 0.25
mainFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
mainFrame.Size = UDim2.new(0, 120, 0, 275)
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 215, 0)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- ⭐️ 最小化悬浮小方块（常驻可拖动，点击完美呼出控制面板）
local minButton = Instance.new("TextButton")
minButton.Name = "MinButton"
minButton.Parent = screenGui
minButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
minButton.BackgroundTransparency = 0.2
minButton.Position = UDim2.new(0.05, 0, 0.22, 0)
minButton.Size = UDim2.new(0, 45, 0, 45)
minButton.Font = Enum.Font.GothamBold
minButton.Text = "小木"
minButton.TextColor3 = Color3.fromRGB(255, 215, 0)
minButton.TextSize = 12
minButton.Visible = false
minButton.Active = true
minButton.Draggable = true

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minButton

local minStroke = Instance.new("UIStroke")
minStroke.Color = Color3.fromRGB(255, 215, 0)
minStroke.Thickness = 2
minStroke.Parent = minButton

-- 专属流光标题栏（内嵌最小化关闭按钮）
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Parent = mainFrame
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleLabel.BackgroundTransparency = 0.5
titleLabel.Position = UDim2.new(0.06, 0, 0.02, 0)
titleLabel.Size = UDim2.new(0, 106, 0, 26)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "小木牛逼克拉斯"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize = 10

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleLabel

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(255, 170, 0)
titleStroke.Thickness = 1
titleStroke.Parent = titleLabel

-- 顶部面板自带的“➖ 最小化”切换按钮
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Parent = titleLabel
minimizeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minimizeBtn.BackgroundTransparency = 0.2
minimizeBtn.Position = UDim2.new(0.78, 0, 0.12, 0)
minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 12

local minBtnCorner = Instance.new("UICorner")
minBtnCorner.CornerRadius = UDim.new(0, 4)
minBtnCorner.Parent = minimizeBtn

-- 无缝坐标同步的最小化/展开逻辑
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        minButton.Position = mainFrame.Position
        mainFrame.Visible = false
        minButton.Visible = true
    else
        mainFrame.Position = minButton.Position
        minButton.Visible = false
        mainFrame.Visible = true
    end
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
minButton.MouseButton1Click:Connect(toggleMinimize)

-- 标准美化按钮工厂函数
local function createStyledButton(name, posY, text, textColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = mainFrame
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
    btn.Position = UDim2.new(0.06, 0, posY, 0)
    btn.Size = UDim2.new(0, 106, 0, 28)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 110)
    stroke.Thickness = 1
    stroke.Parent = btn
    
    return btn
end

-- 各功能模块面板元素布局
local upButton = createStyledButton("UpButton", 0.12, "▲ 上升")
local speedUpBtn = createStyledButton("SpeedUpBtn", 0.25, "➕ 加速", Color3.fromRGB(120, 255, 120))

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Parent = mainFrame
speedLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
speedLabel.Position = UDim2.new(0.06, 0, 0.38, 0)
speedLabel.Size = UDim2.new(0, 106, 0, 24)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Text = "速度: 50"
speedLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
speedLabel.TextSize = 12

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedLabel

local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(60, 90, 150)
speedStroke.Thickness = 1
speedStroke.Parent = speedLabel

local speedDownBtn = createStyledButton("SpeedDownBtn", 0.50, "➖ 减速", Color3.fromRGB(255, 120, 120))

local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyButton"
flyButton.Parent = mainFrame
flyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
flyButton.Position = UDim2.new(0.06, 0, 0.64, 0)
flyButton.Size = UDim2.new(0, 106, 0, 34)
flyButton.Font = Enum.Font.GothamBold
flyButton.Text = "飞行: 关"
flyButton.TextColor3 = Color3.fromRGB(255, 80, 80)
flyButton.TextSize = 14

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 6)
flyCorner.Parent = flyButton

local flyStroke = Instance.new("UIStroke")
flyStroke.Color = Color3.fromRGB(255, 100, 100)
flyStroke.Thickness = 1.2
flyStroke.Parent = flyButton

local downButton = createStyledButton("DownButton", 0.78, "▼ 下降")

-- 状态安全闭包同步
local function updateFlyUI()
    if flying then
        flyButton.Text = "飞行: 开"
        flyButton.TextColor3 = Color3.fromRGB(80, 255, 120)
        flyStroke.Color = Color3.fromRGB(80, 255, 120)
        if humanoid and humanoid.Parent then 
            pcall(function() humanoid.PlatformStand = true end) 
        end
    else
        flyButton.Text = "飞行: 关"
        flyButton.TextColor3 = Color3.fromRGB(255, 80, 80)
        flyStroke.Color = Color3.fromRGB(255, 100, 100)
        movingUp = false
        movingDown = false
        if humanoid and humanoid.Parent then 
            pcall(function() humanoid.PlatformStand = false end) 
        end
    end
end

flyButton.MouseButton1Click:Connect(function()
    flying = not flying
    updateFlyUI()
end)

speedUpBtn.MouseButton1Click:Connect(function()
    FLY_SPEED = math.clamp(FLY_SPEED + SPEED_STEP, 10, 800)
    speedLabel.Text = "速度: " .. tostring(FLY_SPEED)
end)

speedDownBtn.MouseButton1Click:Connect(function()
    FLY_SPEED = math.clamp(FLY_SPEED - SPEED_STEP, 10, 800)
    speedLabel.Text = "速度: " .. tostring(FLY_SPEED)
end)

-- 全平台无死角防粘连（杜绝手机端触摸不回弹Bug）
local function bindHoldEvents(btn, stateSetter)
    btn.MouseButton1Down:Connect(function() stateSetter(true) end)
    btn.MouseButton1Up:Connect(function() stateSetter(false) end)
    btn.MouseLeave:Connect(function() stateSetter(false) end)
    btn.TouchEnded:Connect(function() stateSetter(false) end)
end

bindHoldEvents(upButton, function(state) movingUp = state end)
bindHoldEvents(downButton, function(state) movingDown = state end)

-- 4. 极致物理引擎：融合 LookAt 矩阵降维对齐 + 双重惯性强力封锁
local connection
connection = RunService.RenderStepped:Connect(function(dt)
    if not screenGui or not screenGui.Parent then
        if connection then connection:Disconnect() end
        return
    end
    
    if flying then
        local currentRoot = rootPart
        local currentHumanoid = humanoid
        local cam = workspace.CurrentCamera
        
        if currentRoot and currentRoot.Parent and currentHumanoid and currentHumanoid.Parent and currentHumanoid.Health > 0 and cam then
            local moveDir = currentHumanoid.MoveDirection
            local currentPos = currentRoot.Position
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
            
            local newPos = currentPos + (velocity * dt)
            local camCF = cam.CFrame
            currentRoot.CFrame = CFrame.new(newPos, newPos + camCF.LookVector)
            
            currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

if getgenv then
    getgenv().OldFlyConnection_XiaoMu = connection
end

print("👑【小木牛逼克拉斯】一兆遍纯Lua完美终极版加载成功！")
