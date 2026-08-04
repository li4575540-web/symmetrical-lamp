local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FLY_SPEED = 50
local isFlying = false
local flyConnection = nil

local character, humanoid, humanoidRootPart
local movingUp = false
local movingDown = false

local function updateCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end
updateCharacter()
player.CharacterAdded:Connect(updateCharacter)

if playerGui:FindFirstChild("ExecutorFlyGui") then
	playerGui.ExecutorFlyGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExecutorFlyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function createButton(name, text, size, pos, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = pos
	btn.Text = text
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.Font = Enum.Font.SourceSansBold
	btn.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	return btn
end

local toggleBtn = createButton("ToggleBtn", "飞行: 关", UDim2.new(0, 100, 0, 45), UDim2.new(0.75, 0, 0.15, 0), Color3.fromRGB(40, 40, 40))
local upBtn = createButton("UpBtn", "上升", UDim2.new(0, 60, 0, 60), UDim2.new(0.85, 0, 0.35, 0), Color3.fromRGB(0, 170, 0))
local downBtn = createButton("DownBtn", "下降", UDim2.new(0, 60, 0, 60), UDim2.new(0.85, 0, 0.52, 0), Color3.fromRGB(170, 0, 0))

upBtn.Visible = false
downBtn.Visible = false

upBtn.MouseButton1Down:Connect(function() movingUp = true end)
upBtn.MouseButton1Up:Connect(function() movingUp = false end)

downBtn.MouseButton1Down:Connect(function() movingDown = true end)
downBtn.MouseButton1Up:Connect(function() movingDown = false end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		movingUp = false
		movingDown = false
	end
end)

local flyAttachment, linearVelocity, alignOrientation

local function startFly()
	if not humanoidRootPart or not humanoid then return end
	
	humanoid.PlatformStand = true
	
	flyAttachment = Instance.new("Attachment")
	flyAttachment.Name = "FlyAttachment"
	flyAttachment.Parent = humanoidRootPart
	
	linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = flyAttachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = humanoidRootPart
	
	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Attachment0 = flyAttachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = 200
	alignOrientation.Parent = humanoidRootPart
	
	if flyConnection then flyConnection:Disconnect() end
	
	flyConnection = RunService.RenderStepped:Connect(function()
		if not isFlying or not humanoidRootPart or not linearVelocity then return end
		
		local camera = workspace.CurrentCamera
		local moveDir = humanoid.MoveDirection
		
		local velocity = moveDir * FLY_SPEED
		
		if movingUp then
			velocity = velocity + Vector3.new(0, FLY_SPEED, 0)
		elseif movingDown then
			velocity = velocity - Vector3.new(0, FLY_SPEED, 0)
		end
		
		linearVelocity.VectorVelocity = velocity
		alignOrientation.CFrame = camera.CFrame
	end)
end

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	
	if linearVelocity then linearVelocity:Destroy() end
	if alignOrientation then alignOrientation:Destroy() end
	if flyAttachment then flyAttachment:Destroy() end
	
	if humanoid and humanoidRootPart then
		humanoid.PlatformStand = false
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	end
end

local function toggleFlight()
	isFlying = not isFlying
	
	if isFlying then
		toggleBtn.Text = "飞行: 开"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		upBtn.Visible = true
		downBtn.Visible = true
		startFly()
	else
		toggleBtn.Text = "飞行: 关"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		upBtn.Visible = false
		downBtn.Visible = false
		movingUp = false
		movingDown = false
		stopFly()
	end
end

toggleBtn.MouseButton1Click:Connect(toggleFlight)
