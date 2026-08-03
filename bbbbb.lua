
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local FLY_SPEED = 50
local isFlying = false

-- 清理旧的UI（防止重复注入报错）
if CoreGui:FindFirstChild("ExecutorFlyGui") then
    CoreGui.ExecutorFlyGui:Destroy()
end

-- 创建全屏UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorFlyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- 主开关按钮
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 110, 0, 45)
toggleBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
toggleBtn.Text = "飞行: 关"
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 15
toggleBtn.Parent = screenGui

-- 上升按钮
local upBtn = Instance.new("TextButton")
upBtn.Size = UDim2.new(0, 60, 0, 60)
upBtn.Position = UDim2.new(0.85, 0, 0.35, 0)
upBtn.Text = "上升"
upBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.TextSize = 14
upBtn.Visible = false
upBtn.Parent = screenGui

-- 下降按钮
local downBtn = Instance.new("TextButton")
downBtn.Size = UDim2.new(0, 60, 0, 60)
downBtn.Position = UDim2.new(0.85, 0, 0.52, 0)
downBtn.Text = "下降"
downBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.TextSize = 14
downBtn.Visible = false
downBtn.Parent = screenGui

local movingUp = false
local movingDown = false

upBtn.MouseButton1Down:Connect(function() movingUp = true end)
upBtn.MouseButton1Up:Connect(function() movingUp = false end)
upBtn.TouchDown:Connect(function() movingUp = true end)
upBtn.TouchEnded:Connect(function() movingUp = false end)

downBtn.MouseButton1Down:Connect(function() movingDown = true end)
downBtn.MouseButton1Up:Connect(function() movingDown = false end)
downBtn.TouchDown:Connect(function() movingDown = true end)
downBtn.TouchEnded:Connect(function() movingDown = false end)

-- 物理引擎组件
local bv = Instance.new("BodyVelocity")
local bg = Instance.new("BodyGyro")
bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

-- 飞行主循环
local function toggleFlight()
	isFlying = not isFlying
	
	if isFlying then
		toggleBtn.Text = "飞行: 开"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		upBtn.Visible = true
		downBtn.Visible = true
		
		humanoid.PlatformStand = true
		bv.Parent = humanoidRootPart
		bg.Parent = humanoidRootPart
		
		RunService.RenderStepped:Connect(function()
			if not isFlying then return end
			local camera = workspace.CurrentCamera
			local moveDir = humanoid.MoveDirection -- 绑定手机左侧原生移动摇杆
			
			local velocity = moveDir * FLY_SPEED
			
			if movingUp then
				velocity = velocity + Vector3.new(0, FLY_SPEED, 0)
			end
			if movingDown then
				velocity = velocity - Vector3.new(0, FLY_SPEED, 0)
			end
			
			bv.Velocity = velocity
			bg.CFrame = camera.CFrame
		end)
	else
		toggleBtn.Text = "飞行: 关"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		upBtn.Visible = false
		downBtn.Visible = false
		movingUp = false
		movingDown = false
		
		humanoid.PlatformStand = false
		bv.Parent = nil
		bg.Parent = nil
		humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
	end
end

toggleBtn.MouseButton1Click:Connect(toggleFlight)
