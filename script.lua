local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local MAX_ALLOW_SPEED = 40
local DEFAULT_WALK_SPEED = 16
local CHECK_INTERVAL = 0.2

localPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 3)
    if not humanoid then return end

    local isAlive = true
    humanoid.Died:Connect(function()
        isAlive = false
    end)

    task.spawn(function()
        while isAlive and task.wait(CHECK_INTERVAL) do
            if humanoid.WalkSpeed > MAX_ALLOW_SPEED then
                humanoid.WalkSpeed = DEFAULT_WALK_SPEED
            end
        end
    end)
end)
