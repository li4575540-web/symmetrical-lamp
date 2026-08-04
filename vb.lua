-- =====================================================================
-- 👑【小木HUB v6.0 - 极简全屏触控版 (防遮挡)】
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
local AimbotModule = { Enabled = false, PredictionEnabled = true, FOV = 120.0, BulletSpeed = 1600.0, Smoothing = 0.3, TeamCheck = true, PlayerWhitelist = {}, PlayerBlacklist = {}, AimPart = "UpperTorso", AimPartName = "胸口" }
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

local function cleanupState()
    FlightModule.MovingUp = false; FlightModule.MovingDown = false; FlightModule.Enabled = false; FlyCarModule.Enabled = false
    if humanoid then pcall(function() humanoid.PlatformStand = false; humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
    if character then pcall(function() for _, part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end) end
    noclipApplied = false; currentTarget = nil; carSeat = nil; currentVehicle = nil
    for userId, esp in pairs(espCache) do if esp and esp.Parent then pcall(function() esp:Destroy() end) end end
    espCache = {}
end
local function safeDestroy(obj) if obj and obj.Parent then pcall(function() obj:Destroy() end) end end

local function setupCharacter(char)
    if isClosing then return end
    character = char; cleanupState(); noclipApplied = false
    task.spawn(function() rootPart = char:WaitForChild("HumanoidRootPart", 5); humanoid = char:WaitForChild("Humanoid", 5) end)
end
if plr.Character then setupCharacter(plr.Character) end
plr.CharacterAdded:Connect(setupCharacter)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XiaoMuHubV2"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
local success, parent = pcall(function() return CoreGui end)
if success and parent then screenGui.Parent = CoreGui else screenGui.Parent = plr:WaitForChild("PlayerGui") end

-- ==========================================
-- 【无加载动画，直接秒开】
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
mainFrame.BackgroundTransparency = 0.02
mainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
mainFrame.Size = UDim2.new(0.96, 0, 0.96, 0)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 160, 255)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- 右上角关闭按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = mainFrame
closeBtn.BackgroundTransparency = 1
closeBtn.Position = UDim2.new(0.92, 0, 0.02, 0)
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 16
closeBtn.MouseButton1Click:Connect(function()
    if isClosing then return end; isClosing = true; cleanupState(); if renderConnection then renderConnection:Disconnect() end; safeDestroy(screenGui)
end)

-- 标题
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.BackgroundTransparency = 1
title.Position = UDim2.new(0.05, 0, 0.05, 0)
title.Size = UDim2.new(0, 150, 0, 30)
title.Font = Enum.Font.GothamBold
title.Text = "小木HUB v6.0"
title.TextColor3 = Color3.fromRGB(80, 160, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

-- ==========================================
-- 【分类横向滚动条 (最中间)】
-- ==========================================
local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Parent = mainFrame
tabScroll.BackgroundTransparency = 1
tabScroll.Position = UDim2.new(0.05, 0, 0.12, 0)
tabScroll.Size = UDim2.new(0.9, 0, 0, 35)
tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local currentTab = "移动"
local tabContentFrames = {}
local function createTabBtn(txt, icon)
    local btn = Instance.new("TextButton")
    btn.Parent = tabScroll
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.Text = icon .. txt
    btn.TextColor3 = Color3.fromRGB(160, 160, 180)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function createContentPanel()
    local sf = Instance.new("ScrollingFrame")
    sf.Parent = mainFrame
    sf.BackgroundTransparency = 1
    sf.Position = UDim2.new(0.05, 0, 0.20, 0)
    sf.Size = UDim2.new(0.9, 0, 0.55, 0)
    sf.CanvasSize = UDim2.new(0, 0, 0, 350)
    sf.ScrollBarThickness = 3
    sf.Visible = false
    return sf
end

-- ==========================================
-- 【UI组件】
-- ==========================================
local function createToggle(parent, posY, txt, initialState, cb)
    local card = Instance.new("Frame")
    card.Parent = parent; card.BackgroundColor3 = Color3.fromRGB(24, 26, 35); card.Position = UDim2.new(0, 0, 0, posY); card.Size = UDim2.new(1, 0, 0, 40); Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel"); lbl.Parent = card; lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0.05, 0, 0, 0); lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Font = Enum.Font.GothamBold; lbl.Text = txt; lbl.TextColor3 = Color3.fromRGB(220, 220, 230); lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local bg = Instance.new("TextButton"); bg.Parent = card; bg.BackgroundColor3 = initialState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60); bg.Position = UDim2.new(0.82, 0, 0.2, 0); bg.Size = UDim2.new(0, 40, 0, 22); bg.Text = ""; Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame"); dot.Parent = bg; dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.Position = initialState and UDim2.new(0.52, 0, 0.1, 0) or UDim2.new(0.08, 0, 0.1, 0); dot.Size = UDim2.new(0, 16, 0, 16); Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local state = initialState
    bg.MouseButton1Click:Connect(function() state = not state; local targetColor = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 48, 60); local targetPos = state and UDim2.new(0.52, 0, 0.1, 0) or UDim2.new(0.08, 0, 0.1, 0); TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play(); TweenService:Create(dot, TweenInfo.new(0.2), {Position = targetPos}):Play(); cb(state) end)
end

local function createSlider(parent, posY, txt, mn, mx, cur, unit, cb)
    local card = Instance.new("Frame"); card.Parent = parent; card.BackgroundColor3 = Color3.fromRGB(24, 26, 35); card.Position = UDim2.new(0, 0, 0, posY); card.Size = UDim2.new(1, 0, 0, 40); Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel"); lbl.Parent = card; lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0.05, 0, 0, 0); lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.Font = Enum.Font.GothamBold; lbl.Text = txt; lbl.TextColor3 = Color3.fromRGB(220, 220, 230); lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = Instance.new("TextLabel"); val.Parent = card; val.BackgroundTransparency = 1; val.Position = UDim2.new(0.52, 0, 0, 0); val.Size = UDim2.new(0.12, 0, 1, 0); val.Font = Enum.Font.GothamBold; val.Text = tostring(cur); val.TextColor3 = Color3.fromRGB(80, 160, 255); val.TextSize = 12
    local bar = Instance.new("Frame"); bar.Parent = card; bar.BackgroundColor3 = Color3.fromRGB(45, 48, 60); bar.Position = UDim2.new(0.66, 0, 0.45, 0); bar.Size = UDim2.new(0.3, 0, 0, 6); Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame"); fill.Parent = bar; fill.BackgroundColor3 = Color3.fromRGB(80, 160, 255); fill.Size = UDim2.new((cur - mn)/(mx - mn), 0, 1, 0); Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame"); knob.Parent = bar; knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.new((cur - mn)/(mx - mn), 0, 0.5, 0); knob.Size = UDim2.new(0, 14, 0, 14); Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging = false
    knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local posX = input.Position.X - bar.AbsolutePosition.X; local pos = math.clamp(posX / bar.AbsoluteSize.X, 0, 1); local v = math.floor(mn + (mx - mn) * pos); val.Text = tostring(v); fill.Size = UDim2.new(pos, 0, 1, 0); knob.Position = UDim2.new(pos, 0, 0.5, 0); cb(v) end end)
end

-- ==========================================
-- 【构建功能面板】
-- ==========================================
local tabBtns = {}
local function setupTabs()
    local names = {"移动", "战斗", "视觉", "飞车", "传送"}
    local icons = {"⚡", "🎯", "👁️", "🚗", "🌀"}
    local posX = 0
    for i, name in ipairs(names) do
        local btn = createTabBtn(name, icons[i])
        btn.Position = UDim2.new(0, posX, 0, 0)
        posX = posX + 90
        tabBtns[name] = btn
        local panel = createContentPanel()
        panel.Name = name .. "Panel"
        tabContentFrames[name] = panel

        btn.MouseButton1Click:Connect(function()
            currentTab = name
            for _, b in pairs(tabBtns) do b.TextColor3 = Color3.fromRGB(160, 160, 180) end
            btn.TextColor3 = Color3.fromRGB(80, 160, 255)
            for n, p in pairs(tabContentFrames) do p.Visible = (n == name) end
        end)
    end
    tabScroll.CanvasSize = UDim2.new(0, posX, 0, 0)
    -- 默认激活
    if tabBtns["移动"] then tabBtns["移动"].TextColor3 = Color3.fromRGB(80, 160, 255) end
    if tabContentFrames["移动Panel"] then tabContentFrames["移动Panel"].Visible = true end
end
setupTabs()

-- ==========================================
-- 【功能填充】
-- ==========================================
-- 移动
local mP = tabContentFrames["移动Panel"]
createToggle(mP, 0, "速度加快", SpeedModule.Enabled, function(s) SpeedModule.Enabled = s end)
createSlider(mP, 45, "移动速度", 16, 200, SpeedModule.CustomSpeed, "速", function(v) SpeedModule.CustomSpeed = v end)
createToggle(mP, 90, "跳跃加强", JumpModule.Enabled, function(s) JumpModule.Enabled = s end)
createSlider(mP, 135, "跳跃高度", 50, 300, JumpModule.CustomJump, "高", function(v) JumpModule.CustomJump = v end)
createToggle(mP, 180, "穿墙 (Noclip)", MiscModule.Noclip, function(s) MiscModule.Noclip = s; noclipApplied = false end)
createToggle(mP, 225, "人物飞行", FlightModule.Enabled, function(s) FlightModule.Enabled = s; if not s then cleanupState() end end)

-- 战斗
local bP = tabContentFrames["战斗Panel"]
createToggle(bP, 0, "超维自瞄", AimbotModule.Enabled, function(s) AimbotModule.Enabled = s; if not s then currentTarget = nil; fovCircle.Visible = false end end)
createToggle(bP, 45, "战队保护", AimbotModule.TeamCheck, function(s) AimbotModule.TeamCheck = s end)
createSlider(bP, 90, "FOV范围", 50, 300, AimbotModule.FOV, "度", function(v) AimbotModule.FOV = v; if camera then local r = v * 2.2; fovCircle.Size = UDim2.new(0, r * 2, 0, r * 2); fovCircle.Position = UDim2.new(0, camera.ViewportSize.X / 2, 0, camera.ViewportSize.Y / 2) end end)

-- 视觉
local vP = tabContentFrames["视觉Panel"]
createToggle(vP, 0, "全图透视 ESP", MiscModule.ESPEnabled, function(s) MiscModule.ESPEnabled = s end)

-- 飞车
local cP = tabContentFrames["飞车Panel"]
createToggle(cP, 0, "🚗 飞车模式", FlyCarModule.Enabled, function(s) FlyCarModule.Enabled = s; if not s then carSeat = nil; currentVehicle = nil end end)
createSlider(cP, 45, "飞车速度", 20, 200, FlyCarModule.Speed, "速", function(v) FlyCarModule.Speed = v end)

-- 传送
local tP = tabContentFrames["传送Panel"]
createToggle(tP, 0, "🔮 传送模式", false, function() end)
local tpList = Instance.new("ScrollingFrame"); tpList.Parent = tP; tpList.BackgroundTransparency = 1; tpList.Position = UDim2.new(0, 0, 0, 45); tpList.Size = UDim2.new(1, 0, 0, 150); tpList.CanvasSize = UDim2.new(0, 0, 0, 0); tpList.ScrollBarThickness = 2
local tpTarget = nil
local function refreshTP()
    for _, c in ipairs(tpList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local y = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            local btn = Instance.new("TextButton"); btn.Parent = tpList; btn.BackgroundColor3 = Color3.fromRGB(30, 32, 42); btn.Position = UDim2.new(0, 0, 0, y); btn.Size = UDim2.new(1, 0, 0, 25); btn.Text = "  " .. p.Name; btn.TextColor3 = Color3.fromRGB(200, 200, 210); btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function() tpTarget = p; for _, c in ipairs(tpList:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 32, 42) end end; btn.BackgroundColor3 = Color3.fromRGB(50, 55, 70) end)
            y = y + 30
        end
    end
    tpList.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 10))
end
task.spawn(function() while screenGui and screenGui.Parent do refreshTP() task.wait(3) end end)
refreshTP()

local function teleportPlayer(mode)
    if not tpTarget or not tpTarget.Character then return end
    local hrp = tpTarget.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not rootPart then return end
    if mode == "direct" then rootPart.CFrame = hrp.CFrame
    elseif mode == "front" then rootPart.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 0.5
    elseif mode == "back" then rootPart.CFrame = hrp.CFrame - hrp.CFrame.LookVector * 0.5 end
end

local btnCard = Instance.new("Frame"); btnCard.Parent = tP; btnCard.BackgroundColor3 = Color3.fromRGB(24, 26, 35); btnCard.Position = UDim2.new(0, 0, 0, 210); btnCard.Size = UDim2.new(1, 0, 0, 40); Instance.new("UICorner", btnCard).CornerRadius = UDim.new(0, 6)
local dBtn = Instance.new("TextButton"); dBtn.Parent = btnCard; dBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113); dBtn.Position = UDim2.new(0.05, 0, 0.1, 0); dBtn.Size = UDim2.new(0.25, 0, 0, 30); dBtn.Text = "直接"; dBtn.TextColor3 = Color3.fromRGB(255, 255, 255); dBtn.TextSize = 11; Instance.new("UICorner", dBtn).CornerRadius = UDim.new(0, 4); dBtn.MouseButton1Click:Connect(function() teleportPlayer("direct") end)
local fBtn = Instance.new("TextButton"); fBtn.Parent = btnCard; fBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219); fBtn.Position = UDim2.new(0.37, 0, 0.1, 0); fBtn.Size = UDim2.new(0.25, 0, 0, 30); fBtn.Text = "前面"; fBtn.TextColor3 = Color3.fromRGB(255, 255, 255); fBtn.TextSize = 11; Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 4); fBtn.MouseButton1Click:Connect(function() teleportPlayer("front") end)
local bBtn = Instance.new("TextButton"); bBtn.Parent = btnCard; bBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60); bBtn.Position = UDim2.new(0.70, 0, 0.1, 0); bBtn.Size = UDim2.new(0.25, 0, 0, 30); bBtn.Text = "后面"; bBtn.TextColor3 = Color3.fromRGB(255, 255, 255); bBtn.TextSize = 11; Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0, 4); bBtn.MouseButton1Click:Connect(function() teleportPlayer("back") end)

-- ==========================================
-- 【右下角飞车/飞行升降按钮 (大实体按键)】
-- ==========================================
local ctrlPanel = Instance.new("Frame")
ctrlPanel.Parent = mainFrame
ctrlPanel.BackgroundTransparency = 1
ctrlPanel.Position = UDim2.new(0.7, 0, 0.82, 0)
ctrlPanel.Size = UDim2.new(0, 70, 0, 70)

local upBig = Instance.new("TextButton")
upBig.Parent = ctrlPanel
upBig.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
upBig.Position = UDim2.new(0, 0, 0, 0)
upBig.Size = UDim2.new(0, 70, 0, 30)
upBig.Text = "▲ 飞"
upBig.TextColor3 = Color3.fromRGB(255, 255, 255)
upBig.TextSize = 14
Instance.new("UICorner", upBig).CornerRadius = UDim.new(0, 8)

local downBig = Instance.new("TextButton")
downBig.Parent = ctrlPanel
downBig.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
downBig.Position = UDim2.new(0, 0, 0, 35)
downBig.Size = UDim2.new(0, 70, 0, 30)
downBig.Text = "▼ 降"
downBig.TextColor3 = Color3.fromRGB(255, 255, 255)
downBig.TextSize = 14
Instance.new("UICorner", downBig).TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", downBig).CornerRadius = UDim.new(0, 8)

local function bindBigHold(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then setter(false) end end)
end
bindBigHold(upBig, function(s) FlightModule.MovingUp = s end)
bindBigHold(downBig, function(s) FlightModule.MovingDown = s end)

-- ==========================================
-- 【自瞄与飞车主循环】
-- ==========================================
renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not screenGui or not screenGui.Parent then if renderConnection then renderConnection:Disconnect() end return end

    if AimbotModule.Enabled then
        local target = nil; local dist = AimbotModule.FOV; local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        for _, p in ipairs(Players:GetPlayers()) do if p ~= plr then if AimbotModule.TeamCheck and p.TeamColor == plr.TeamColor then continue end; local c = p.Character; if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then local s, on = camera:WorldToViewportPoint(c.HumanoidRootPart.Position); if on then local d = (Vector2.new(s.X, s.Y) - center).Magnitude; if d < dist then dist = d; target = p end end end end end
        if target then local c = target.Character; if c and c:FindFirstChild("HumanoidRootPart") then local tPos = c.HumanoidRootPart.Position; local lDir = (tPos - camera.CFrame.Position).Unit; camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + lDir), 0.7) end end
    end

    if MiscModule.ESPEnabled then
        -- 简易ESP：画个白框 + 名字
        for _, p in ipairs(Players:GetPlayers()) do if p ~= plr and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local c = p.Character; local hrp = c.HumanoidRootPart; local s, on = camera:WorldToViewportPoint(hrp.Position)
            if on and s.Z > 0 then
                local size = 50 + (200 - s.Z) * 0.3
                if not espCache[p.UserId] then
                    local f = Instance.new("Frame"); f.Parent = screenGui; f.BackgroundTransparency = 1; f.Size = UDim2.new(0, size, 0, size*2); f.Position = UDim2.new(0, s.X - size/2, 0, s.Y - size); f.ZIndex = 20; local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255,255,255); st.Thickness = 1; st.Parent = f; local l = Instance.new("TextLabel"); l.Parent = f; l.BackgroundTransparency = 1; l.Size = UDim2.new(0, 100, 0, 16); l.Position = UDim2.new(0, -25, 0, -20); l.Text = p.Name; l.TextColor3 = Color3.fromRGB(255,255,255); l.TextSize = 10; l.ZIndex = 21; espCache[p.UserId] = {Frame=f, Label=l}
                else
                    local e = espCache[p.UserId]; e.Frame.Size = UDim2.new(0, size, 0, size*2); e.Frame.Position = UDim2.new(0, s.X - size/2, 0, s.Y - size); e.Frame.Visible = true; e.Label.Visible = true
                end
            else
                if espCache[p.UserId] then espCache[p.UserId].Frame.Visible = false; espCache[p.UserId].Label.Visible = false end
            end
        end end
    else
        for _, v in pairs(espCache) do pcall(function() v.Frame:Destroy(); v.Label:Destroy() end) end; espCache = {}
    end

    if FlyCarModule.Enabled then
        local seat = plr.Character and plr.Character:FindFirstChild("Seat") or plr.Character and plr.Character:FindFirstChild("VehicleSeat")
        if seat and seat.Occupant and seat.Occupant.Parent == plr.Character then
            local vr = seat.Parent:FindFirstChild("VehicleRootPart") or seat.Parent:FindFirstChild("PrimaryPart") or seat.Parent:FindFirstChild("Body")
            if vr then
                local v = Vector3.new(0,0,0)
                local h = plr.Character:FindFirstChild("Humanoid")
                if h then
                    local d = h.MoveDirection
                    if d.Magnitude > 0.1 then
                        local r = camera.CFrame:VectorToObjectSpace(d)
                        v = (camera.CFrame.LookVector * -r.Z + camera.CFrame.RightVector * r.X) * FlyCarModule.Speed
                    end
                end
                if FlightModule.MovingUp then v = v + Vector3.new(0, FlyCarModule.Speed, 0) end
                if FlightModule.MovingDown then v = v - Vector3.new(0, FlyCarModule.Speed, 0) end
                vr.AssemblyLinearVelocity = v
            end
        end
    end
end)

print("👑【小木HUB v6.0】极简全屏触控版加载成功！")
