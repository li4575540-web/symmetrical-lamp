-- =====================================================================
-- 👑【小木牛逼克拉斯】全极端场景推演完毕·绝对无 Bug 工业级飞行内核
-- =====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local flying = false
local FLY_SPEED = 50       -- 默认飞行速度

local character, rootPart, humanoid
local movingUp = false
local movingDown = false

-- 1. 彻底清理旧线程与历史残留 UI
if getgenv and getgenv().OldFlyConnection_XiaoMu then
    pcall(function() getgenv().OldFlyConnection_XiaoMu:Disconnect() end)
    getgenv().OldFlyConnection_XiaoMu = nil
end

for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "XiaoMuAbsoluteZeroBugUI" then v:Destroy() end
end
pcall(function()
    if plr.PlayerGui:FindFirstChild("XiaoMuAbsoluteZeroBugUI") then
        plr.PlayerGui.XiaoMuAbsoluteZeroBugUI:Destroy()
    end
end)

-- 2. 状态自愈与角色绑定机制
local function cleanupState()
    flying = false
    movingUp = false
    movingDown = false
    if humanoid then 
        pcall(function() 
            humanoid.PlatformStand = false 
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end) 
    end
end

local function setupCharacter(char)
    character = char
    pcall(function()
        rootPart = char:WaitForChild("HumanoidRootPart", 5)
        humanoid = char:WaitForChild("Humanoid", 5)
    end)
    cleanupState()
end

if plr.Character then setupCharacter(plr.Character) end
plr.CharacterAdded:Connect(setupCharacter)

-- 3. 现代化侧边栏 UI 界面构建
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XiaoMuAbsoluteZeroBugUI"
screenGui.ResetOnSpawn = false
local success, err = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = plr:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -155)
mainFrame.Size = UDim2.new(0, 500, 0, 310)
mainFrame.Active = true
mainFrame.Draggable = true

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 215, 0)
mainStroke.Thickness = 1.2
mainStroke.Parent = mainFrame

-- 顶部标题栏
local topBar = Instance.new("Frame")
topBar.Parent = mainFrame
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
topBar.Size = UDim2.new(1, 0, 0, 35)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

local titleText = Instance.new("TextLabel")
titleText.Parent = topBar
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0.03, 0, 0, 0)
titleText.Size = UDim2.new(0, 350, 1, 0)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "XiaoMu V2.4  |  极限推演·零Bug全防护飞行"
titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = topBar
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Position = UDim2.new(0.93, 0, 0.2, 0)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 10
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

closeBtn.MouseButton1Click:Connect(function()
    cleanupState()
    screenGui:Destroy()
end)

-- 左侧导航栏
local sideBar = Instance.new("Frame")
sideBar.Parent = mainFrame
sideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
sideBar.Position = UDim2.new(0, 0, 0, 35)
sideBar.Size = UDim2.new(0, 130, 1, -35)
sideBar.BackgroundTransparency = 0.5

local tabBtn = Instance.new("TextButton")
tabBtn.Parent = sideBar
tabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
tabBtn.Position = UDim2.new(0.08, 0, 0.05, 0)
tabBtn.Size = UDim2.new(0, 110, 0, 32)
tabBtn.Font = Enum.Font.GothamBold
tabBtn.Text = "🚀 飞行主控"
tabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
tabBtn.TextSize = 11
Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

-- 右侧内容区
local contentArea = Instance.new("Frame")
contentArea.Parent = mainFrame
contentArea.BackgroundTransparency = 1
contentArea.Position = UDim2.new(0, 140, 0, 45)
contentArea.Size = UDim2.new(1, -150, 1, -55)

local function createCard(posY, titleTextStr)
    local card = Instance.new("Frame")
    card.Parent = contentArea
    card.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    card.Position = UDim2.new(0, 0, posY, 0)
    card.Size = UDim2.new(1, 0, 0, 45)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Parent = card
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0.04, 0, 0, 0)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = titleTextStr
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return card
end

-- 组件挂载
local flyCard = createCard(0.0, "飞行功能总开关")
local flyToggleBtn = Instance.new("TextButton")
flyToggleBtn.Parent = flyCard
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
flyToggleBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
flyToggleBtn.Size = UDim2.new(0, 85, 0, 26)
flyToggleBtn.Font = Enum.Font.GothamBold
flyToggleBtn.Text = "【 关闭 】"
flyToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
flyToggleBtn.TextSize = 11
Instance.new("UICorner", flyToggleBtn).CornerRadius = UDim.new(0, 4)

local speedCard = createCard(0.22, "当前飞行速度调节")
local speedValLabel = Instance.new("TextLabel")
speedValLabel.Parent = speedCard
speedValLabel.BackgroundTransparency = 1
speedValLabel.Position = UDim2.new(0.5, 0, 0, 0)
speedValLabel.Size = UDim2.new(0.2, 0, 1, 0)
speedValLabel.Font = Enum.Font.GothamBold
speedValLabel.Text = "50 速"
speedValLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
speedValLabel.TextSize = 12

local speedDownBtn = Instance.new("TextButton")
speedDownBtn.Parent = speedCard
speedDownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
speedDownBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
speedDownBtn.Size = UDim2.new(0, 38, 0, 26)
speedDownBtn.Font = Enum.Font.GothamBold
speedDownBtn.Text = "-"
speedDownBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
speedDownBtn.TextSize = 14
Instance.new("UICorner", speedDownBtn).CornerRadius = UDim.new(0, 4)

local speedUpBtn = Instance.new("TextButton")
speedUpBtn.Parent = speedCard
speedUpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
speedUpBtn.Position = UDim2.new(0.85, 0, 0.2, 0)
speedUpBtn.Size = UDim2.new(0, 38, 0, 26)
speedUpBtn.Font = Enum.Font.GothamBold
speedUpBtn.Text = "+"
speedUpBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
speedUpBtn.TextSize = 14
Instance.new("UICorner", speedUpBtn).CornerRadius = UDim.new(0, 4)

local upCard = createCard(0.44, "向上垂直升空 (长按)")
local upBtn = Instance.new("TextButton")
upBtn.Parent = upCard
upBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
upBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
upBtn.Size = UDim2.new(0, 85, 0, 26)
upBtn.Font = Enum.Font.GothamBold
upBtn.Text = "▲ 按住上升"
upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.TextSize = 11
Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 4)

local downCard = createCard(0.66, "向下垂直降落 (长按)")
local downBtn = Instance.new("TextButton")
downBtn.Parent = downCard
downBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
downBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
downBtn.Size = UDim2.new(0, 85, 0, 26)
downBtn.Font = Enum.Font.GothamBold
downBtn.Text = "▼ 按住下降"
downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.TextSize = 11
Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 4)

-- UI 切换逻辑
local function updateFlyUI()
    if flying then
        flyToggleBtn.Text = "【 开启 】"
        flyToggleBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 40)
        if humanoid and humanoid.Parent then 
            pcall(function() 
                humanoid.PlatformStand = true 
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end) 
        end
    else
        flyToggleBtn.Text = "【 关闭 】"
        flyToggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
        movingUp = false
        movingDown = false
        if humanoid and humanoid.Parent then 
            pcall(function() 
                humanoid.PlatformStand = false 
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end) 
        end
    end
end

flyToggleBtn.MouseButton1Click:Connect(function()
    flying = not flying
    if not flying then movingUp, movingDown = false, false end
    updateFlyUI()
end)

speedUpBtn.MouseButton1Click:Connect(function()
    FLY_SPEED = math.clamp(FLY_SPEED + 10, 10, 800)
    speedValLabel.Text = tostring(FLY_SPEED) .. " 速"
end)

speedDownBtn.MouseButton1Click:Connect(function()
    FLY_SPEED = math.clamp(FLY_SPEED - 10, 10, 800)
    speedValLabel.Text = tostring(FLY_SPEED) .. " 速"
end)

local function bindHoldEvents(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.MouseLeave:Connect(function() setter(false) end)
    if btn.TouchStarted then btn.TouchStarted:Connect(function() setter(true) end) end
    if btn.TouchEnded then btn.TouchEnded:Connect(function() setter(false) end) end
end

bindHoldEvents(upBtn, function(s) movingUp = s end)
bindHoldEvents(downBtn, function(s) movingDown = s end)

-- 4. 历经全场景推演的零 Bug 物理主循环
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local connection
connection = RunService.RenderStepped:Connect(function(dt)
    if not screenGui or not screenGui.Parent then
        if connection then connection:Disconnect() end
        return
    end
    
    if flying then
        -- 卫语句：强力拦截死亡、野指针、非活动状态
        if not character or not character.Parent or not rootPart or not rootPart.Parent or not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
            cleanupState()
            updateFlyUI()
            return
        end
        
        humanoid.PlatformStand = true
        local cam = workspace.CurrentCamera
        if not cam then return end
        
        local moveDir = humanoid.MoveDirection
        local currentPos = rootPart.Position
        local velocity = Vector3.new(0, 0, 0)
        
        if moveDir.Magnitude > 0 then
            local relativeMove = cam.CFrame:VectorToObjectSpace(moveDir)
            velocity = (cam.CFrame.LookVector * -relativeMove.Z + cam.CFrame.RightVector * relativeMove.X) * FLY_SPEED
        end
        
        if movingUp then velocity = velocity + Vector3.new(0, FLY_SPEED, 0) end
        if movingDown then velocity = velocity - Vector3.new(0, FLY_SPEED, 0) end
        
        -- 防掉帧突变
        local safeDt = math.clamp(dt, 0, 0.1)
        local targetPos = currentPos + (velocity * safeDt)
        
        -- NaN 矩阵硬校验
        if targetPos.X ~= targetPos.X or targetPos.Y ~= targetPos.Y or targetPos.Z ~= targetPos.Z then
            targetPos = currentPos
        end
        
        raycastParams.FilterDescendantsInstances = {character}
        
        -- 动态速度纵向防遁地网（极限加速度隔离）
        local dynamicRayLength = math.clamp(5.0 + (FLY_SPEED * 0.15), 5.0, 35.0)
        local floorRay = workspace:Raycast(currentPos, Vector3.new(0, -dynamicRayLength, 0), raycastParams)
        if floorRay then
            local safeY = floorRay.Position.Y + 3.5
            if targetPos.Y < safeY then
                targetPos = Vector3.new(targetPos.X, safeY, targetPos.Z)
            end
        end
        
        -- 行进路线防穿墙夹击
        local travelDir = targetPos - currentPos
        local travelMagnitude = travelDir.Magnitude
        if travelMagnitude > 0.01 then
            local wallRay = workspace:Raycast(currentPos, travelDir.Unit * (travelMagnitude + 2.5), raycastParams)
            if wallRay then
                targetPos = wallRay.Position - (travelDir.Unit * 2.5)
            end
        end
        
        -- 视角矩阵防死锁转换
        local lookAtTarget = targetPos + cam.CFrame.LookVector
        if (lookAtTarget - targetPos).Magnitude < 0.001 then
            lookAtTarget = targetPos + Vector3.new(0, 0, -1)
        end
        
        rootPart.CFrame = CFrame.new(targetPos, lookAtTarget)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end)

if getgenv then getgenv().OldFlyConnection_XiaoMu = connection end

print("👑【小木牛逼克拉斯】极限推演版全防护飞行器加载成功！")
