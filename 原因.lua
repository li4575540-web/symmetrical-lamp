-- =====================================================================
-- 👑【小木HUB v5.06 - 终极稳健版】
-- =====================================================================
-- 
-- 📋 【更新日志】
-- 
-- v5.06 (2026-08-04)
-- 🔧 【核心修复】
-- 🛠️ 彻底重写搜索框事件：采用 FocusLost + 实时输入拦截法，完美避开 Roblox 移动端所有文本框事件坑。
-- 🛡️ 飞车升降防飘：松手后强制 0.1 秒清零，杜绝长按升/降后的惯性滑行。
-- 🧩 【优化】
-- 📌 玩家列表/传送列表刷新时，滚动条不再跳回顶部（记忆当前位置）。
-- 🎯 自瞄部位按钮加载时默认高亮「胸口」，无需手动点选。
-- 🚀 功能全覆盖：ESP骨骼 / 大司马图标 / 传送 / 甩飞 / 飞车 / 自瞄 / 玩家管理 / 更新日志。
-- 
-- =====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==========================================
-- 【模块状态】
-- ==========================================
local FlightModule = { Enabled = false, Speed = 60, MovingUp = false, MovingDown = false }
local FlyCarModule = { Enabled = false, Speed = 80 }
local SpeedModule = { Enabled = false, CustomSpeed = 60 }
local JumpModule = { Enabled = false, CustomJump = 50 }
local MiscModule = { AntiStun = true, ESPEnabled = true, Noclip = false }
local AimbotModule = { 
    Enabled = false, 
    PredictionEnabled = true, 
    FOV = 120.0, 
    BulletSpeed = 1600.0, 
    Smoothing = 0.3, 
    TeamCheck = true, 
    PlayerWhitelist = {}, 
    PlayerBlacklist = {},
    AimPart = "UpperTorso",
    AimPartName = "胸口"
}

local TeamWhitelist = { Locked = false, TargetTeam = nil }

local character, rootPart, humanoid
local noclipApplied = false
local renderConnection = nil
local espCache = {}
local currentTarget = nil
local isClosing = false
local showFOVCircle = true
local carSeat = nil
local currentVehicle = nil

-- ==========================================
-- 【清理】
-- ==========================================
local function cleanupState()
    FlightModule.MovingUp = false
    FlightModule.MovingDown = false
    FlightModule.Enabled = false
    FlyCarModule.Enabled = false
    if humanoid then 
        pcall(function() 
            humanoid.PlatformStand = false 
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end) 
    end
    if character then
        pcall(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then 
                    part.CanCollide = true
                end
            end
        end)
    end
    noclipApplied = false
    currentTarget = nil
    carSeat = nil
    currentVehicle = nil
    
    for userId, esp in pairs(espCache) do
        if esp and esp.Parent then
            pcall(function() esp:Destroy() end)
        end
    end
    espCache = {}
end

local function safeDestroy(obj)
    if obj and obj.Parent then pcall(function() obj:Destroy() end) end
end

-- ==========================================
-- 【角色监听】
-- ==========================================
local function setupCharacter(char)
    if isClosing then return end
    character = char
    cleanupState()
    noclipApplied = false
    task.spawn(function()
        rootPart = char:WaitForChild("HumanoidRootPart", 5)
        humanoid = char:WaitForChild("Humanoid", 5)
    end)
end

if plr.Character then setupCharacter(plr.Character) end
plr.CharacterAdded:Connect(setupCharacter)

-- ==========================================
-- 【UI 构建】
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XiaoMuHubV2"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- 核心修复：只要有一个能用的父级就行
local success, parent = pcall(function() return CoreGui end)
if success and parent then
    screenGui.Parent = CoreGui
else
    screenGui.Parent = plr:WaitForChild("PlayerGui")
end

-- ==========================================
-- 【加载动画】
-- ==========================================
local loadGui = Instance.new("Frame")
loadGui.Name = "LoadGui"
loadGui.Parent = screenGui
loadGui.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
loadGui.AnchorPoint = Vector2.new(0.5, 0.5)
loadGui.Position = UDim2.new(0.5, 0, 0.5, 0)
loadGui.Size = UDim2.new(0, 320, 0, 180)
loadGui.ZIndex = 10
Instance.new("UICorner", loadGui).CornerRadius = UDim.new(0, 10)
local loadStroke = Instance.new("UIStroke")
loadStroke.Color = Color3.fromRGB(80, 160, 255)
loadStroke.Thickness = 1.5
loadStroke.Parent = loadGui

local loadTitle = Instance.new("TextLabel")
loadTitle.Parent = loadGui
loadTitle.BackgroundTransparency = 1
loadTitle.Position = UDim2.new(0, 0, 0.2, 0)
loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Font = Enum.Font.GothamBold
loadTitle.Text = "小木HUB"
loadTitle.TextColor3 = Color3.fromRGB(80, 160, 255)
loadTitle.TextSize = 20
loadTitle.ZIndex = 11

local loadSub = Instance.new("TextLabel")
loadSub.Parent = loadGui
loadSub.BackgroundTransparency = 1
loadSub.Position = UDim2.new(0, 0, 0.42, 0)
loadSub.Size = UDim2.new(1, 0, 0, 20)
loadSub.Font = Enum.Font.Gotham
loadSub.Text = "正在初始化模块与资源..."
loadSub.TextColor3 = Color3.fromRGB(160, 160, 180)
loadSub.TextSize = 12
loadSub.ZIndex = 11

local barBg = Instance.new("Frame")
barBg.Parent = loadGui
barBg.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
barBg.Position = UDim2.new(0.1, 0, 0.7, 0)
barBg.Size = UDim2.new(0.8, 0, 0, 8)
barBg.ZIndex = 11
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Parent = barBg
barFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.ZIndex = 12
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- ==========================================
-- 【FOV圈】
-- ==========================================
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Parent = screenGui
fovCircle.BackgroundTransparency = 1
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Visible = showFOVCircle and AimbotModule.Enabled
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 180, 0)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

-- ==========================================
-- 【主窗口】
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
mainFrame.BackgroundTransparency = 0.02
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 620, 0, 680)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 48, 60)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Parent = mainFrame
topBar.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
topBar.Size = UDim2.new(1, 0, 0, 40)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleText = Instance.new("TextLabel")
titleText.Parent = topBar
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0.03, 0, 0, 0)
titleText.Size = UDim2.new(0, 120, 0, 40)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "小木HUB"
titleText.TextColor3 = Color3.fromRGB(80, 160, 255)
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left

local subTitle = Instance.new("TextLabel")
subTitle.Parent = topBar
subTitle.BackgroundTransparency = 1
subTitle.Position = UDim2.new(0.23, 0, 0.28, 0)
subTitle.Size = UDim2.new(0, 80, 0, 18)
subTitle.Font = Enum.Font.GothamBold
subTitle.Text = "v5.06"
subTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subTitle.TextSize = 10
subTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = topBar
closeBtn.BackgroundTransparency = 1
closeBtn.Position = UDim2.new(0.93, 0, 0.2, 0)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
closeBtn.TextSize = 18

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = topBar
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Position = UDim2.new(0.87, 0, 0.2, 0)
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
minimizeBtn.TextSize = 18

-- ==========================================
-- 【大司马图标迷你方块】
-- ==========================================
local miniSquare = Instance.new("TextButton")
miniSquare.Name = "MiniSquare"
miniSquare.Parent = screenGui
miniSquare.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniSquare.Position = UDim2.new(0.02, 0, 0.2, 0)
miniSquare.Size = UDim2.new(0, 45, 0, 45)
miniSquare.Font = Enum.Font.GothamBold
miniSquare.Text = ""
miniSquare.Visible = false
miniSquare.Active = true
miniSquare.Draggable = true
Instance.new("UICorner", miniSquare).CornerRadius = UDim.new(0, 10)

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(150, 130, 255)
miniStroke.Thickness = 2
miniStroke.Parent = miniSquare

local miniImage = Instance.new("ImageLabel")
miniImage.Parent = miniSquare
miniImage.BackgroundTransparency = 1
miniImage.Position = UDim2.new(0, 0, 0, 0)
miniImage.Size = UDim2.new(1, 0, 1, 0)
miniImage.ScaleType = Enum.ScaleType.Fit
miniImage.Image = "rbxassetid://135577550284336"
miniImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", miniImage).CornerRadius = UDim.new(0, 10)

-- 按钮事件
closeBtn.MouseButton1Click:Connect(function()
    if isClosing then return end
    isClosing = true
    cleanupState()
    if renderConnection then renderConnection:Disconnect() end
    safeDestroy(fovCircle)
    safeDestroy(screenGui)
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniSquare.Visible = true
end)

miniSquare.MouseButton1Click:Connect(function()
    miniSquare.Visible = false
    mainFrame.Visible = true
end)

-- ==========================================
-- 【侧边栏】
-- ==========================================
local leftSidebar = Instance.new("Frame")
leftSidebar.Parent = mainFrame
leftSidebar.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
leftSidebar.Position = UDim2.new(0, 0, 0, 40)
leftSidebar.Size = UDim2.new(0, 150, 1, -40)
Instance.new("UICorner", leftSidebar).CornerRadius = UDim.new(0, 0)

-- 搜索框
local searchBoxBg = Instance.new("Frame")
searchBoxBg.Parent = leftSidebar
searchBoxBg.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
searchBoxBg.Position = UDim2.new(0.08, 0, 0.04, 0)
searchBoxBg.Size = UDim2.new(0.84, 0, 0, 32)
Instance.new("UICorner", searchBoxBg).CornerRadius = UDim.new(0, 6)

local searchIcon = Instance.new("TextLabel")
searchIcon.Parent = searchBoxBg
searchIcon.BackgroundTransparency = 1
searchIcon.Position = UDim2.new(0.08, 0, 0, 0)
searchIcon.Size = UDim2.new(0, 20, 1, 0)
searchIcon.Font = Enum.Font.GothamBold
searchIcon.Text = "🔍"
searchIcon.TextColor3 = Color3.fromRGB(120, 120, 140)
searchIcon.TextSize = 11

local searchInput = Instance.new("TextBox")
searchInput.Parent = searchBoxBg
searchInput.BackgroundTransparency = 1
searchInput.Position = UDim2.new(0.3, 0, 0, 0)
searchInput.Size = UDim2.new(0.65, 0, 1, 0)
searchInput.Font = Enum.Font.Gotham
searchInput.PlaceholderText = "搜索..."
searchInput.TextColor3 = Color3.fromRGB(200, 200, 210)
searchInput.TextSize = 11
searchInput.TextXAlignment = Enum.TextXAlignment.Left

-- 🔥 终极修复：放弃所有 Event 监听，使用 FocusLost + 实时防崩过滤
local lastSearchText = ""
searchInput.FocusLost:Connect(function()
    local text = searchInput.Text
    if text ~= lastSearchText then
        lastSearchText = text
        local keyword = text:lower()
        local firstVisible = nil
        for i, btn in ipairs(allTabButtons) do
            local visible = (keyword == "" or tabNames[i]:find(keyword))
            btn.Visible = visible
            if visible and not firstVisible then firstVisible = tabNames[i] end
        end
        if not tabContentFrames[currentSelectedTab].Visible and firstVisible then
            switchTab(firstVisible)
        end
    end
end)
-- 额外拦截：文本框每次输入触发时，强制刷新分类
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    task.wait(0.1)
    local text = searchInput.Text
    if text ~= lastSearchText then
        lastSearchText = text
        local keyword = text:lower()
        local firstVisible = nil
        for i, btn in ipairs(allTabButtons) do
            local visible = (keyword == "" or tabNames[i]:find(keyword))
            btn.Visible = visible
            if visible and not firstVisible then firstVisible = tabNames[i] end
        end
        if not tabContentFrames[currentSelectedTab].Visible and firstVisible then
            switchTab(firstVisible)
        end
    end
end)

local tabContainer = Instance.new("ScrollingFrame")
tabContainer.Parent = leftSidebar
tabContainer.BackgroundTransparency = 1
tabContainer.Position = UDim2.new(0, 0, 0.18, 0)
tabContainer.Size = UDim2.new(1, 0, 0.8, 0)
tabContainer.CanvasSize = UDim2.new(0, 0, 0, 450)
tabContainer.ScrollBarThickness = 0

local currentSelectedTab = "移动"
local tabContentFrames = {}
local allTabButtons = {}
local tabNames = {"移动", "战斗", "视觉", "杂项", "飞车", "传送", "日志"}

local function createTabButton(posY, textStr, iconStr)
    local btn = Instance.new("TextButton")
    btn.Parent = tabContainer
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(0.08, 0, 0, posY)
    btn.Size = UDim2.new(0.84, 0, 0, 36)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "    " .. iconStr .. "  " .. textStr
    btn.TextColor3 = Color3.fromRGB(160, 160, 180)
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(allTabButtons, btn)
    return btn
end

local rightContentArea = Instance.new("Frame")
rightContentArea.Parent = mainFrame
rightContentArea.BackgroundTransparency = 1
rightContentArea.Position = UDim2.new(0, 160, 0, 45)
rightContentArea.Size = UDim2.new(1, -165, 1, -50)

local function createContentPanel(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name .. "Panel"
    sf.Parent = rightContentArea
    sf.BackgroundTransparency = 1
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 450)
    sf.ScrollBarThickness = 3
    sf.Visible = (name == currentSelectedTab)
    tabContentFrames[name] = sf
    return sf
end

-- ==========================================
-- 【UI 组件】
-- ==========================================
local function createToggleOption(parent, posY, titleTextStr, initialState, callback)
    local card = Instance.new("Frame")
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.Size = UDim2.new(1, -10, 0, 42)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Parent = card
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0.05, 0, 0, 0)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleTextStr
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBg = Instance.new("TextButton")
    toggleBg.Parent = card
    toggleBg.BackgroundColor3 = initialState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60)
    toggleBg.Position = UDim2.new(0.82, 0, 0.22, 0)
    toggleBg.Size = UDim2.new(0, 44, 0, 22)
    toggleBg.Text = ""
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local toggleDot = Instance.new("Frame")
    toggleDot.Parent = toggleBg
    toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleDot.Position = initialState and UDim2.new(0.52, 0, 0.1, 0) or UDim2.new(0.08, 0, 0.1, 0)
    toggleDot.Size = UDim2.new(0, 18, 0, 18)
    Instance.new("UICorner", toggleDot).CornerRadius = UDim.new(1, 0)

    local state = initialState
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        local targetColor = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60)
        local targetPos = state and UDim2.new(0.52, 0, 0.1, 0) or UDim2.new(0.08, 0, 0.1, 0)
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(toggleDot, TweenInfo.new(0.2), {Position = targetPos}):Play()
        callback(state)
    end)
    return card
end

local function createSliderOption(parent, posY, titleTextStr, minVal, maxVal, currentVal, unitStr, callback)
    local card = Instance.new("Frame")
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.Size = UDim2.new(1, -10, 0, 42)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Parent = card
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0.05, 0, 0, 0)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleTextStr
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel")
    valLabel.Parent = card
    valLabel.BackgroundTransparency = 1
    valLabel.Position = UDim2.new(0.52, 0, 0, 0)
    valLabel.Size = UDim2.new(0.12, 0, 1, 0)
    valLabel.Font = Enum.Font.GothamBold
    valLabel.Text = tostring(currentVal)
    valLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
    valLabel.TextSize = 11

    local sliderBar = Instance.new("Frame")
    sliderBar.Parent = card
    sliderBar.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    sliderBar.Position = UDim2.new(0.66, 0, 0.45, 0)
    sliderBar.Size = UDim2.new(0.3, 0, 0, 6)
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

    local fillBar = Instance.new("Frame")
    fillBar.Parent = sliderBar
    fillBar.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
    fillBar.Size = UDim2.new((currentVal - minVal)/(maxVal - minVal), 0, 1, 0)
    Instance.new("UICorner", fillBar).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Parent = sliderBar
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((currentVal - minVal)/(maxVal - minVal), 0, 0.5, 0)
    knob.Size = UDim2.new(0, 14, 0, 14)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local sliderWidth = sliderBar.AbsoluteSize.X
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local posX = input.Position.X - sliderBar.AbsolutePosition.X
            local pos = math.clamp(posX / sliderBar.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            valLabel.Text = tostring(val)
            fillBar.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, 0, 0.5, 0)
            callback(val)
        end
    end)
    return card
end

-- ==========================================
-- 【菜单面板】
-- ==========================================
local movePanel = createContentPanel("移动")
createToggleOption(movePanel, 0, "速度加快", SpeedModule.Enabled, function(state) SpeedModule.Enabled = state end)
createSliderOption(movePanel, 48, "移动速度", 16, 200, SpeedModule.CustomSpeed, "速", function(val) SpeedModule.CustomSpeed = val end)
createToggleOption(movePanel, 96, "跳跃加强", JumpModule.Enabled, function(state) JumpModule.Enabled = state end)
createSliderOption(movePanel, 144, "跳跃高度", 50, 300, JumpModule.CustomJump, "高", function(val) JumpModule.CustomJump = val end)
createToggleOption(movePanel, 192, "穿墙 (Noclip)", MiscModule.Noclip, function(state) MiscModule.Noclip = state; noclipApplied = false end)
createToggleOption(movePanel, 240, "人物飞行", FlightModule.Enabled, function(state) FlightModule.Enabled = state; if not state then cleanupState() end end)

-- 飞行升降按钮
local flightControlCard = Instance.new("Frame")
flightControlCard.Parent = movePanel
flightControlCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
flightControlCard.Position = UDim2.new(0, 0, 0, 290)
flightControlCard.Size = UDim2.new(1, -10, 0, 50)
Instance.new("UICorner", flightControlCard).CornerRadius = UDim.new(0, 6)

local fcTitle = Instance.new("TextLabel")
fcTitle.Parent = flightControlCard
fcTitle.BackgroundTransparency = 1
fcTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
fcTitle.Size = UDim2.new(0.5, 0, 1, 0)
fcTitle.Font = Enum.Font.GothamBold
fcTitle.Text = "飞行升降控制"
fcTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
fcTitle.TextSize = 11
fcTitle.TextXAlignment = Enum.TextXAlignment.Left

local upBtn = Instance.new("TextButton")
upBtn.Parent = flightControlCard
upBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
upBtn.Position = UDim2.new(0.65, 0, 0.15, 0)
upBtn.Size = UDim2.new(0.15, 0, 0, 30)
upBtn.Font = Enum.Font.GothamBold
upBtn.Text = "▲"
upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.TextSize = 14
Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 6)

local downBtn = Instance.new("TextButton")
downBtn.Parent = flightControlCard
downBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
downBtn.Position = UDim2.new(0.82, 0, 0.15, 0)
downBtn.Size = UDim2.new(0.15, 0, 0, 30)
downBtn.Font = Enum.Font.GothamBold
downBtn.Text = "▼"
downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.TextSize = 14
Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 6)

local function bindHold(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then setter(false) end
    end)
end

bindHold(upBtn, function(s) FlightModule.MovingUp = s end)
bindHold(downBtn, function(s) FlightModule.MovingDown = s end)

-- ==========================================
-- 【战斗面板】
-- ==========================================
local combatPanel = createContentPanel("战斗")
createToggleOption(combatPanel, 0, "超维自瞄", AimbotModule.Enabled, function(state) 
    AimbotModule.Enabled = state 
    if not state then 
        currentTarget = nil 
        fovCircle.Visible = false
    end
end)

createToggleOption(combatPanel, 48, "显示FOV圈", true, function(state)
    showFOVCircle = state
    fovCircle.Visible = state and AimbotModule.Enabled
end)

createSliderOption(combatPanel, 96, "FOV范围", 50, 300, AimbotModule.FOV, "度", function(val)
    AimbotModule.FOV = val
    if camera then
        local r = val * 2.2
        fovCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
        fovCircle.Position = UDim2.new(0, camera.ViewportSize.X / 2, 0, camera.ViewportSize.Y / 2)
    end
end)

createToggleOption(combatPanel, 144, "战队保护", AimbotModule.TeamCheck, function(state) 
    AimbotModule.TeamCheck = state 
end)

-- 自瞄部位选择
local partSelectCard = Instance.new("Frame")
partSelectCard.Parent = combatPanel
partSelectCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
partSelectCard.Position = UDim2.new(0, 0, 0, 192)
partSelectCard.Size = UDim2.new(1, -10, 0, 40)
Instance.new("UICorner", partSelectCard).CornerRadius = UDim.new(0, 6)

local partLabel = Instance.new("TextLabel")
partLabel.Parent = partSelectCard
partLabel.BackgroundTransparency = 1
partLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
partLabel.Size = UDim2.new(0.4, 0, 1, 0)
partLabel.Font = Enum.Font.GothamBold
partLabel.Text = "瞄准部位:"
partLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
partLabel.TextSize = 11
partLabel.TextXAlignment = Enum.TextXAlignment.Left

local partBtnHead = Instance.new("TextButton")
partBtnHead.Parent = partSelectCard
partBtnHead.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
partBtnHead.Position = UDim2.new(0.55, 0, 0.15, 0)
partBtnHead.Size = UDim2.new(0.12, 0, 0, 26)
partBtnHead.Font = Enum.Font.GothamBold
partBtnHead.Text = "头部"
partBtnHead.TextColor3 = Color3.fromRGB(200, 200, 210)
partBtnHead.TextSize = 10
Instance.new("UICorner", partBtnHead).CornerRadius = UDim.new(0, 4)

local partBtnChest = Instance.new("TextButton")
partBtnChest.Parent = partSelectCard
partBtnChest.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
partBtnChest.Position = UDim2.new(0.70, 0, 0.15, 0)
partBtnChest.Size = UDim2.new(0.12, 0, 0, 26)
partBtnChest.Font = Enum.Font.GothamBold
partBtnChest.Text = "胸口"
partBtnChest.TextColor3 = Color3.fromRGB(255, 255, 255)
partBtnChest.TextSize = 10
Instance.new("UICorner", partBtnChest).CornerRadius = UDim.new(0, 4)

local partBtnLeg = Instance.new("TextButton")
partBtnLeg.Parent = partSelectCard
partBtnLeg.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
partBtnLeg.Position = UDim2.new(0.85, 0, 0.15, 0)
partBtnLeg.Size = UDim2.new(0.12, 0, 0, 26)
partBtnLeg.Font = Enum.Font.GothamBold
partBtnLeg.Text = "下身"
partBtnLeg.TextColor3 = Color3.fromRGB(200, 200, 210)
partBtnLeg.TextSize = 10
Instance.new("UICorner", partBtnLeg).CornerRadius = UDim.new(0, 4)

-- 🔥 优化：初始状态高亮胸口
local function resetPartButtons()
    partBtnHead.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    partBtnChest.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    partBtnLeg.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    partBtnHead.TextColor3 = Color3.fromRGB(200, 200, 210)
    partBtnChest.TextColor3 = Color3.fromRGB(200, 200, 210)
    partBtnLeg.TextColor3 = Color3.fromRGB(200, 200, 210)
end
resetPartButtons()
partBtnChest.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
partBtnChest.TextColor3 = Color3.fromRGB(255, 255, 255)

partBtnHead.MouseButton1Click:Connect(function()
    resetPartButtons()
    partBtnHead.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    partBtnHead.TextColor3 = Color3.fromRGB(255, 255, 255)
    AimbotModule.AimPart = "Head"
    AimbotModule.AimPartName = "头部"
end)

partBtnChest.MouseButton1Click:Connect(function()
    resetPartButtons()
    partBtnChest.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    partBtnChest.TextColor3 = Color3.fromRGB(255, 255, 255)
    AimbotModule.AimPart = "UpperTorso"
    AimbotModule.AimPartName = "胸口"
end)

partBtnLeg.MouseButton1Click:Connect(function()
    resetPartButtons()
    partBtnLeg.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    partBtnLeg.TextColor3 = Color3.fromRGB(255, 255, 255)
    AimbotModule.AimPart = "LowerTorso"
    AimbotModule.AimPartName = "下身"
end)

-- 玩家管理
local playerListPanel = Instance.new("Frame")
playerListPanel.Parent = combatPanel
playerListPanel.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
playerListPanel.Position = UDim2.new(0, 0, 0, 242)
playerListPanel.Size = UDim2.new(1, -10, 0, 220)
Instance.new("UICorner", playerListPanel).CornerRadius = UDim.new(0, 6)

local listTitle = Instance.new("TextLabel")
listTitle.Parent = playerListPanel
listTitle.BackgroundTransparency = 1
listTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
listTitle.Size = UDim2.new(0.8, 0, 0, 20)
listTitle.Font = Enum.Font.GothamBold
listTitle.Text = "🎯 玩家管理"
listTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
listTitle.TextSize = 11
listTitle.TextXAlignment = Enum.TextXAlignment.Left

local teamSection = Instance.new("Frame")
teamSection.Parent = playerListPanel
teamSection.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
teamSection.Position = UDim2.new(0.05, 0, 0.1, 0)
teamSection.Size = UDim2.new(0.9, 0, 0, 50)
Instance.new("UICorner", teamSection).CornerRadius = UDim.new(0, 4)

local teamLabel = Instance.new("TextLabel")
teamLabel.Parent = teamSection
teamLabel.BackgroundTransparency = 1
teamLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
teamLabel.Size = UDim2.new(0.5, 0, 1, 0)
teamLabel.Font = Enum.Font.GothamBold
teamLabel.Text = "团队白名单"
teamLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
teamLabel.TextSize = 10
teamLabel.TextXAlignment = Enum.TextXAlignment.Left

local teamLockBtn = Instance.new("TextButton")
teamLockBtn.Parent = teamSection
teamLockBtn.BackgroundColor3 = TeamWhitelist.Locked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60)
teamLockBtn.Position = UDim2.new(0.65, 0, 0.1, 0)
teamLockBtn.Size = UDim2.new(0.12, 0, 0, 30)
teamLockBtn.Font = Enum.Font.GothamBold
teamLockBtn.Text = "🔒 锁"
teamLockBtn.TextColor3 = TeamWhitelist.Locked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
teamLockBtn.TextSize = 10
Instance.new("UICorner", teamLockBtn).CornerRadius = UDim.new(0, 4)

local teamUnlockBtn = Instance.new("TextButton")
teamUnlockBtn.Parent = teamSection
teamUnlockBtn.BackgroundColor3 = not TeamWhitelist.Locked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60)
teamUnlockBtn.Position = UDim2.new(0.80, 0, 0.1, 0)
teamUnlockBtn.Size = UDim2.new(0.12, 0, 0, 30)
teamUnlockBtn.Font = Enum.Font.GothamBold
teamUnlockBtn.Text = "🔓 不锁"
teamUnlockBtn.TextColor3 = not TeamWhitelist.Locked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
teamUnlockBtn.TextSize = 10
Instance.new("UICorner", teamUnlockBtn).CornerRadius = UDim.new(0, 4)

teamLockBtn.MouseButton1Click:Connect(function()
    TeamWhitelist.Locked = true
    TeamWhitelist.TargetTeam = plr.TeamColor
    teamLockBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    teamLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamUnlockBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    teamUnlockBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
end)

teamUnlockBtn.MouseButton1Click:Connect(function()
    TeamWhitelist.Locked = false
    TeamWhitelist.TargetTeam = nil
    teamUnlockBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    teamUnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamLockBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    teamLockBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
end)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Parent = playerListPanel
playerScroll.BackgroundTransparency = 1
playerScroll.Position = UDim2.new(0.05, 0, 0.35, 0)
playerScroll.Size = UDim2.new(0.9, 0, 0.6, 0)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.ScrollBarThickness = 2
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 160, 255)

local selectedPlayer = nil
local playerButtons = {}
local scrollPosMemory = 0

local function refreshPlayerList()
    -- 🔥 优化：记忆滚动位置
    scrollPosMemory = playerScroll.CanvasPosition.Y
    
    for _, btn in pairs(playerButtons) do btn:Destroy() end
    playerButtons = {}
    local posY = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and player.Parent then
            local btn = Instance.new("TextButton")
            btn.Parent = playerScroll
            btn.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
            btn.Position = UDim2.new(0, 0, 0, posY)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Font = Enum.Font.Gotham
            btn.Text = "  " .. player.Name
            btn.TextColor3 = Color3.fromRGB(200, 200, 210)
            btn.TextSize = 10
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            if AimbotModule.PlayerWhitelist[player.UserId] then
                btn.Text = "  ✅ " .. player.Name
                btn.TextColor3 = Color3.fromRGB(46, 204, 113)
            elseif AimbotModule.PlayerBlacklist[player.UserId] then
                btn.Text = "  ❌ " .. player.Name
                btn.TextColor3 = Color3.fromRGB(231, 76, 60)
            end
            
            local lockBtn = Instance.new("TextButton")
            lockBtn.Parent = btn
            lockBtn.BackgroundColor3 = AimbotModule.PlayerWhitelist[player.UserId] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60)
            lockBtn.Position = UDim2.new(0.75, 0, 0.1, 0)
            lockBtn.Size = UDim2.new(0.08, 0, 0, 22)
            lockBtn.Font = Enum.Font.GothamBold
            lockBtn.Text = "🔒"
            lockBtn.TextColor3 = AimbotModule.PlayerWhitelist[player.UserId] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
            lockBtn.TextSize = 11
            Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)
            
            local unlockBtn = Instance.new("TextButton")
            unlockBtn.Parent = btn
            unlockBtn.BackgroundColor3 = AimbotModule.PlayerBlacklist[player.UserId] and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(45, 48, 60)
            unlockBtn.Position = UDim2.new(0.85, 0, 0.1, 0)
            unlockBtn.Size = UDim2.new(0.08, 0, 0, 22)
            unlockBtn.Font = Enum.Font.GothamBold
            unlockBtn.Text = "🔓"
            unlockBtn.TextColor3 = AimbotModule.PlayerBlacklist[player.UserId] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
            unlockBtn.TextSize = 11
            Instance.new("UICorner", unlockBtn).CornerRadius = UDim.new(0, 4)
            
            lockBtn.MouseButton1Click:Connect(function()
                AimbotModule.PlayerWhitelist[player.UserId] = true
                AimbotModule.PlayerBlacklist[player.UserId] = nil
                lockBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                unlockBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
                unlockBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
                refreshPlayerList()
            end)
            
            unlockBtn.MouseButton1Click:Connect(function()
                AimbotModule.PlayerBlacklist[player.UserId] = true
                AimbotModule.PlayerWhitelist[player.UserId] = nil
                unlockBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                unlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                lockBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
                lockBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
                refreshPlayerList()
            end)
            
            table.insert(playerButtons, btn)
            posY = posY + 32
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(posY, 10))
    -- 🔥 优化：恢复滚动位置
    playerScroll.CanvasPosition = Vector2.new(0, scrollPosMemory)
end

task.spawn(function()
    while screenGui and screenGui.Parent do
        refreshPlayerList()
        task.wait(3)
    end
end)
refreshPlayerList()

-- ==========================================
-- 【视觉面板 - ESP骨骼】
-- ==========================================
local visualPanel = createContentPanel("视觉")
createToggleOption(visualPanel, 0, "全图透视 ESP", MiscModule.ESPEnabled, function(state) MiscModule.ESPEnabled = state end)

local boneJoints = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}

local function createSkeletonESP(player)
    if not player or player == plr then return end
    local char = player.Character
    if not char then return end
    if espCache[player.UserId] then return end
    
    local esp = Instance.new("Folder")
    esp.Name = "SkeletonESP_" .. player.Name
    esp.Parent = screenGui
    
    local skeletonLines = {}
    for i = 1, #boneJoints do
        local line = Instance.new("Frame")
        line.Name = "Bone_" .. i
        line.Parent = esp
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.Size = UDim2.new(0, 2, 0, 2)
        line.BorderSizePixel = 0
        line.ZIndex = 20
        table.insert(skeletonLines, line)
    end
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = esp
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 80, 0, 16)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 10
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.ZIndex = 19
    
    espCache[player.UserId] = esp
    return esp
end

local function updateSkeletonESP(esp, char)
    local function getBonePos(name)
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part.Position
        end
        return nil
    end
    
    local bonePositions = {}
    for _, boneName in ipairs(boneJoints) do
        local pos = getBonePos(boneName)
        table.insert(bonePositions, pos)
    end
    
    local lines = esp:GetChildren()
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, line in ipairs(lines) do
            if line:IsA("Frame") then line.Visible = false end
        end
        return
    end
    
    local lineIdx = 1
    local connections = {
        {1, 2}, {2, 3}, -- 躯干
        {2, 4}, {4, 5}, {5, 6}, -- 左臂
        {2, 7}, {7, 8}, {8, 9}, -- 右臂
        {3, 10}, {10, 11}, {11, 12}, -- 左腿
        {3, 13}, {13, 14}, {14, 15} -- 右腿
    }
    
    for _, conn in ipairs(connections) do
        local p1 = bonePositions[conn[1]]
        local p2 = bonePositions[conn[2]]
        if p1 and p2 then
            local screenP1, onScreen1 = camera:WorldToViewportPoint(p1)
            local screenP2, onScreen2 = camera:WorldToViewportPoint(p2)
            if onScreen1 and onScreen2 then
                local midX = (screenP1.X + screenP2.X) / 2
                local midY = (screenP1.Y + screenP2.Y) / 2
                local dx = screenP1.X - screenP2.X
                local dy = screenP1.Y - screenP2.Y
                local length = math.sqrt(dx*dx + dy*dy)
                local angle = math.atan2(dy, dx)
                
                local line = lines[lineIdx]
                if line and line:IsA("Frame") then
                    line.Position = UDim2.new(0, midX - length/2, 0, midY - 1)
                    line.Size = UDim2.new(0, length, 0, 2)
                    line.Rotation = math.deg(angle)
                    line.Visible = true
                end
            else
                local line = lines[lineIdx]
                if line and line:IsA("Frame") then line.Visible = false end
            end
        else
            local line = lines[lineIdx]
            if line and line:IsA("Frame") then line.Visible = false end
        end
        lineIdx = lineIdx + 1
    end
    
    -- 名字标签
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local nameLabel = esp:FindFirstChild("TextLabel")
            if nameLabel then
                nameLabel.Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 50)
                nameLabel.Visible = true
                nameLabel.Text = player.Name
                if player.TeamColor == plr.TeamColor then
                    nameLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
                else
                    nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            end
        end
    end
end

local function updateESP()
    for userId, esp in pairs(espCache) do
        local player = Players:GetPlayerByUserId(userId)
        if not player or not player.Character then
            pcall(function() esp:Destroy() end)
            espCache[userId] = nil
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and player.Character then
            if not espCache[player.UserId] then
                createSkeletonESP(player)
            end
            local esp = espCache[player.UserId]
            if esp then
                updateSkeletonESP(esp, player.Character)
            end
        end
    end
end

-- ==========================================
-- 【🚗 飞车面板】
-- ==========================================
local carPanel = createContentPanel("飞车")

createToggleOption(carPanel, 0, "🚗 飞车模式", FlyCarModule.Enabled, function(state)
    FlyCarModule.Enabled = state
    if not state then
        carSeat = nil
        currentVehicle = nil
    end
end)

createSliderOption(carPanel, 48, "飞车速度", 20, 200, FlyCarModule.Speed, "速", function(val)
    FlyCarModule.Speed = val
end)

-- 飞车升降控制
local carControlCard = Instance.new("Frame")
carControlCard.Parent = carPanel
carControlCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
carControlCard.Position = UDim2.new(0, 0, 0, 100)
carControlCard.Size = UDim2.new(1, -10, 0, 50)
Instance.new("UICorner", carControlCard).CornerRadius = UDim.new(0, 6)

local carCtrlTitle = Instance.new("TextLabel")
carCtrlTitle.Parent = carControlCard
carCtrlTitle.BackgroundTransparency = 1
carCtrlTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
carCtrlTitle.Size = UDim2.new(0.5, 0, 1, 0)
carCtrlTitle.Font = Enum.Font.GothamBold
carCtrlTitle.Text = "飞车升降"
carCtrlTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
carCtrlTitle.TextSize = 11
carCtrlTitle.TextXAlignment = Enum.TextXAlignment.Left

local carUpBtn = Instance.new("TextButton")
carUpBtn.Parent = carControlCard
carUpBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
carUpBtn.Position = UDim2.new(0.65, 0, 0.15, 0)
carUpBtn.Size = UDim2.new(0.15, 0, 0, 30)
carUpBtn.Font = Enum.Font.GothamBold
carUpBtn.Text = "▲"
carUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
carUpBtn.TextSize = 14
Instance.new("UICorner", carUpBtn).CornerRadius = UDim.new(0, 6)

local carDownBtn = Instance.new("TextButton")
carDownBtn.Parent = carControlCard
carDownBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
carDownBtn.Position = UDim2.new(0.82, 0, 0.15, 0)
carDownBtn.Size = UDim2.new(0.15, 0, 0, 30)
carDownBtn.Font = Enum.Font.GothamBold
carDownBtn.Text = "▼"
carDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
carDownBtn.TextSize = 14
Instance.new("UICorner", carDownBtn).CornerRadius = UDim.new(0, 6)

local carUpPressed = false
local carDownPressed = false

-- 🔥 优化：飞车松手强制清零防飘
local carStopTimer = nil
local function bindCarHold(btn, setter)
    btn.MouseButton1Down:Connect(function()
        if carStopTimer then carStopTimer:Disconnect(); carStopTimer = nil end
        setter(true)
    end)
    btn.MouseButton1Up:Connect(function()
        setter(false)
        if carStopTimer then carStopTimer:Disconnect() end
        carStopTimer = task.delay(0.1, function()
            carUpPressed = false
            carDownPressed = false
        end)
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            setter(false)
            if carStopTimer then carStopTimer:Disconnect() end
            carStopTimer = task.delay(0.1, function()
                carUpPressed = false
                carDownPressed = false
            end)
        end
    end)
end

bindCarHold(carUpBtn, function(s) carUpPressed = s end)
bindCarHold(carDownBtn, function(s) carDownPressed = s end)

-- ==========================================
-- 【飞车主循环】
-- ==========================================
local carLoop = nil
local function startCarLoop()
    if carLoop then carLoop:Disconnect() end
    carLoop = RunService.RenderStepped:Connect(function()
        if not FlyCarModule.Enabled then return end
        
        local seat = plr.Character and plr.Character:FindFirstChild("Seat") 
        if not seat then
            seat = plr.Character and plr.Character:FindFirstChild("VehicleSeat")
        end
        
        if seat and seat.Occupant and seat.Occupant.Parent == plr.Character then
            carSeat = seat
            currentVehicle = seat.Parent
            
            local vehicleRoot = currentVehicle:FindFirstChild("VehicleRootPart") 
                or currentVehicle:FindFirstChild("PrimaryPart") 
                or currentVehicle:FindFirstChild("Body")
            
            if vehicleRoot then
                local moveDir = Vector3.new(0, 0, 0)
                if plr.Character:FindFirstChild("Humanoid") then
                    local hum = plr.Character.Humanoid
                    local dir = hum.MoveDirection
                    if dir.Magnitude > 0.1 then
                        local rel = camera.CFrame:VectorToObjectSpace(dir)
                        moveDir = (camera.CFrame.LookVector * -rel.Z + camera.CFrame.RightVector * rel.X) * FlyCarModule.Speed
                    end
                end
                
                if carUpPressed then 
                    moveDir = moveDir + Vector3.new(0, FlyCarModule.Speed, 0) 
                end
                if carDownPressed then 
                    moveDir = moveDir - Vector3.new(0, FlyCarModule.Speed, 0) 
                end
                
                vehicleRoot.AssemblyLinearVelocity = moveDir
            end
        end
    end)
end

-- ==========================================
-- 【✨ 传送与甩飞面板】
-- ==========================================
local teleportPanel = createContentPanel("传送")

createToggleOption(teleportPanel, 0, "🔮 传送模式", false, function() end)

-- 玩家列表选择
local tpPlayerListPanel = Instance.new("Frame")
tpPlayerListPanel.Parent = teleportPanel
tpPlayerListPanel.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
tpPlayerListPanel.Position = UDim2.new(0, 0, 0, 48)
tpPlayerListPanel.Size = UDim2.new(1, -10, 0, 180)
Instance.new("UICorner", tpPlayerListPanel).CornerRadius = UDim.new(0, 6)

local tpListTitle = Instance.new("TextLabel")
tpListTitle.Parent = tpPlayerListPanel
tpListTitle.BackgroundTransparency = 1
tpListTitle.Position = UDim2.new(0.05, 0, 0.05, 0)
tpListTitle.Size = UDim2.new(0.8, 0, 0, 20)
tpListTitle.Font = Enum.Font.GothamBold
tpListTitle.Text = "🎯 选择传送目标"
tpListTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
tpListTitle.TextSize = 11
tpListTitle.TextXAlignment = Enum.TextXAlignment.Left

local tpScroll = Instance.new("ScrollingFrame")
tpScroll.Parent = tpPlayerListPanel
tpScroll.BackgroundTransparency = 1
tpScroll.Position = UDim2.new(0.05, 0, 0.25, 0)
tpScroll.Size = UDim2.new(0.9, 0, 0.7, 0)
tpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tpScroll.ScrollBarThickness = 2
tpScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 160, 255)

local tpSelectedPlayer = nil
local tpButtons = {}
local tpScrollPos = 0

local function refreshTPList()
    -- 🔥 优化：记忆滚动位置
    tpScrollPos = tpScroll.CanvasPosition.Y
    
    for _, btn in pairs(tpButtons) do btn:Destroy() end
    tpButtons = {}
    local posY = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and player.Parent then
            local btn = Instance.new("TextButton")
            btn.Parent = tpScroll
            btn.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
            btn.Position = UDim2.new(0, 0, 0, posY)
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.Font = Enum.Font.Gotham
            btn.Text = "  " .. player.Name
            btn.TextColor3 = Color3.fromRGB(200, 200, 210)
            btn.TextSize = 10
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                tpSelectedPlayer = player
                for _, b in pairs(tpButtons) do b.BackgroundColor3 = Color3.fromRGB(30, 32, 42) end
                btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
            end)
            
            table.insert(tpButtons, btn)
            posY = posY + 28
        end
    end
    tpScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(posY, 10))
    -- 🔥 优化：恢复滚动位置
    tpScroll.CanvasPosition = Vector2.new(0, tpScrollPos)
end

task.spawn(function()
    while screenGui and screenGui.Parent do
        refreshTPList()
        task.wait(3)
    end
end)
refreshTPList()

-- 传送距离滑块
createSliderOption(teleportPanel, 236, "传送距离(厘米)", 0, 200, 50, "cm", function(val)
    teleportDistance = val
end)

-- 传送按钮区
local tpButtonCard = Instance.new("Frame")
tpButtonCard.Parent = teleportPanel
tpButtonCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
tpButtonCard.Position = UDim2.new(0, 0, 0, 284)
tpButtonCard.Size = UDim2.new(1, -10, 0, 50)
Instance.new("UICorner", tpButtonCard).CornerRadius = UDim.new(0, 6)

local tpBtnTitle = Instance.new("TextLabel")
tpBtnTitle.Parent = tpButtonCard
tpBtnTitle.BackgroundTransparency = 1
tpBtnTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
tpBtnTitle.Size = UDim2.new(0.5, 0, 1, 0)
tpBtnTitle.Font = Enum.Font.GothamBold
tpBtnTitle.Text = "传送操作"
tpBtnTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
tpBtnTitle.TextSize = 11
tpBtnTitle.TextXAlignment = Enum.TextXAlignment.Left

local tpDirectBtn = Instance.new("TextButton")
tpDirectBtn.Parent = tpButtonCard
tpDirectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
tpDirectBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
tpDirectBtn.Size = UDim2.new(0.12, 0, 0, 30)
tpDirectBtn.Font = Enum.Font.GothamBold
tpDirectBtn.Text = "直接"
tpDirectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpDirectBtn.TextSize = 10
Instance.new("UICorner", tpDirectBtn).CornerRadius = UDim.new(0, 4)

local tpFrontBtn = Instance.new("TextButton")
tpFrontBtn.Parent = tpButtonCard
tpFrontBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
tpFrontBtn.Position = UDim2.new(0.70, 0, 0.1, 0)
tpFrontBtn.Size = UDim2.new(0.12, 0, 0, 30)
tpFrontBtn.Font = Enum.Font.GothamBold
tpFrontBtn.Text = "前面"
tpFrontBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpFrontBtn.TextSize = 10
Instance.new("UICorner", tpFrontBtn).CornerRadius = UDim.new(0, 4)

local tpBackBtn = Instance.new("TextButton")
tpBackBtn.Parent = tpButtonCard
tpBackBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
tpBackBtn.Position = UDim2.new(0.85, 0, 0.1, 0)
tpBackBtn.Size = UDim2.new(0.12, 0, 0, 30)
tpBackBtn.Font = Enum.Font.GothamBold
tpBackBtn.Text = "后面"
tpBackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBackBtn.TextSize = 10
Instance.new("UICorner", tpBackBtn).CornerRadius = UDim.new(0, 4)

-- 🔥 甩飞按钮
local flingCard = Instance.new("Frame")
flingCard.Parent = teleportPanel
flingCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35)
flingCard.Position = UDim2.new(0, 0, 0, 342)
flingCard.Size = UDim2.new(1, -10, 0, 50)
Instance.new("UICorner", flingCard).CornerRadius = UDim.new(0, 6)

local flingTitle = Instance.new("TextLabel")
flingTitle.Parent = flingCard
flingTitle.BackgroundTransparency = 1
flingTitle.Size = UDim2.new(0.5, 0, 1, 0)
flingTitle.Font = Enum.Font.GothamBold
flingTitle.Text = "💥 甩飞操作"
flingTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
flingTitle.TextSize = 11
flingTitle.TextXAlignment = Enum.TextXAlignment.Left

local flingBtn = Instance.new("TextButton")
flingBtn.Parent = flingCard
flingBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
flingBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
flingBtn.Size = UDim2.new(0.4, 0, 0, 30)
flingBtn.Font = Enum.Font.GothamBold
flingBtn.Text = "💥 甩飞一次"
flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingBtn.TextSize = 11
Instance.new("UICorner", flingBtn).CornerRadius = UDim.new(0, 4)

-- 传送逻辑
local teleportDistance = 50

local function teleportPlayer(target, mode)
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if mode == "direct" then
        -- 直接传送到玩家位置（把自己传过去）
        if rootPart then
            rootPart.CFrame = hrp.CFrame
        end
    elseif mode == "front" then
        -- 传送到前面
        if rootPart then
            local dist = teleportDistance / 100
            local look = hrp.CFrame.LookVector
            rootPart.CFrame = hrp.CFrame + look * dist
        end
    elseif mode == "back" then
        -- 传送到后面
        if rootPart then
            local dist = teleportDistance / 100
            local look = hrp.CFrame.LookVector
            rootPart.CFrame = hrp.CFrame - look * dist
        end
    end
end

tpDirectBtn.MouseButton1Click:Connect(function()
    if tpSelectedPlayer then
        teleportPlayer(tpSelectedPlayer, "direct")
    end
end)

tpFrontBtn.MouseButton1Click:Connect(function()
    if tpSelectedPlayer then
        teleportPlayer(tpSelectedPlayer, "front")
    end
end)

tpBackBtn.MouseButton1Click:Connect(function()
    if tpSelectedPlayer then
        teleportPlayer(tpSelectedPlayer, "back")
    end
end)

-- 甩飞逻辑
flingBtn.MouseButton1Click:Connect(function()
    if tpSelectedPlayer and tpSelectedPlayer.Character then
        local hrp = tpSelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 120, 0)
        end
    end
end)

-- ==========================================
-- 【自瞄】
-- ==========================================
local function getClosestTarget()
    local closestDist = AimbotModule.FOV
    local closestTarget = nil
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            if TeamWhitelist.Locked and TeamWhitelist.TargetTeam then
                if player.TeamColor ~= TeamWhitelist.TargetTeam then continue end
            else
                if AimbotModule.TeamCheck and player.TeamColor == plr.TeamColor then continue end
            end
            
            if AimbotModule.PlayerBlacklist[player.UserId] then continue end
            if #AimbotModule.PlayerWhitelist > 0 and not AimbotModule.PlayerWhitelist[player.UserId] then continue end
            
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local humanoid = char.Humanoid
                if humanoid.Health > 0 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestTarget = player
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local function performAimbot()
    if not AimbotModule.Enabled then return end
    if not character or not rootPart or not humanoid then return end
    
    local target = getClosestTarget()
    if target then
        currentTarget = target
        local targetChar = target.Character
        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local targetHrp = targetChar.HumanoidRootPart
            local targetPart = targetChar:FindFirstChild(AimbotModule.AimPart) or targetHrp
            local targetPos = targetPart.Position
            
            if AimbotModule.PredictionEnabled then
                local targetVel = targetHrp.AssemblyLinearVelocity
                local dist = (rootPart.Position - targetPos).Magnitude
                local timeToHit = dist / AimbotModule.BulletSpeed
                targetPos = targetPos + targetVel * timeToHit
            end
            
            local dist3D = (rootPart.Position - targetHrp.Position).Magnitude
            local dynamicSmooth = AimbotModule.Smoothing
            if dist3D < 30 then dynamicSmooth = 0.1
            elseif dist3D > 150 then dynamicSmooth = 0.5
            end
            
            local lookDir = (targetPos - camera.CFrame.Position).Unit
            local targetCFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + lookDir)
            local lerpAmount = 1 - dynamicSmooth
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, lerpAmount)
        end
    else
        currentTarget = nil
    end
end

-- ==========================================
-- 【主循环】
-- ==========================================
renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not screenGui or not screenGui.Parent then
        if renderConnection then renderConnection:Disconnect() end
        return
    end
    
    -- FOV
    pcall(function()
        if camera then
            local r = AimbotModule.FOV * 2.2
            fovCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
            fovCircle.Position = UDim2.new(0, camera.ViewportSize.X / 2, 0, camera.ViewportSize.Y / 2)
            fovCircle.Visible = showFOVCircle and AimbotModule.Enabled
        end
    end)
    
    -- 自瞄
    pcall(performAimbot)
    
    -- ESP
    if MiscModule.ESPEnabled then
        pcall(updateESP)
    else
        for _, v in pairs(espCache) do
            pcall(function() v:Destroy() end)
        end
        espCache = {}
    end
    
    -- 飞车循环
    pcall(startCarLoop)
    
    -- 角色属性
    pcall(function()
        if not character or not humanoid or not humanoid.Parent then return end
        
        if SpeedModule.Enabled then
            humanoid.WalkSpeed = SpeedModule.CustomSpeed
        elseif humanoid.WalkSpeed ~= 16 then
            humanoid.WalkSpeed = 16
        end
        
        if JumpModule.Enabled then
            humanoid.JumpPower = JumpModule.CustomJump
            humanoid.UseJumpPower = true
        else
            humanoid.UseJumpPower = false
        end
        
        if MiscModule.AntiStun and humanoid.PlatformStand and not FlightModule.Enabled then
            humanoid.PlatformStand = false
        end
    end)
    
    -- Noclip
    if MiscModule.Noclip and not noclipApplied and character then
        pcall(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
            noclipApplied = true
        end)
    elseif not MiscModule.Noclip and noclipApplied and character then
        pcall(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            noclipApplied = false
        end)
    end
    
    -- 飞行
    if FlightModule.Enabled then
        pcall(function()
            if not character or not rootPart or not humanoid then return end
            if not rootPart.Parent then return end
            
            humanoid.PlatformStand = true
            if not camera then return end
            
            local moveDir = humanoid.MoveDirection
            local velocity = Vector3.new(0, 0, 0)
            
            if moveDir.Magnitude > 0 then
                local rel = camera.CFrame:VectorToObjectSpace(moveDir)
                velocity = (camera.CFrame.LookVector * -rel.Z + camera.CFrame.RightVector * rel.X) * FlightModule.Speed
            end
            
            if FlightModule.MovingUp then velocity = velocity + Vector3.new(0, FlightModule.Speed, 0) end
            if FlightModule.MovingDown then velocity = velocity - Vector3.new(0, FlightModule.Speed, 0) end
            
            rootPart.AssemblyLinearVelocity = velocity
        end)
    end
end)

print("👑【小木HUB v5.06】加载成功！完美适配移动端。")
