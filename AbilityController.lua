local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local AbilitiesConfig = require(ReplicatedStorage.Shared.Config.AbilitiesConfig)
local UseAbilityEvent = ReplicatedStorage.Shared.Network:WaitForChild("UseAbilityEvent") :: RemoteEvent

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local AbilityController = {}

-- Keybind map built dynamically at runtime + custom secondary binds
local keybindMap: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.LeftShift] = "Dash",
}

for name, config in pairs(AbilitiesConfig) do
	keybindMap[config.Key] = name
end

local function getAimPosition(): Vector3
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if localPlayer.Character then
		raycastParams.FilterDescendantsInstances = { localPlayer.Character }
	end

	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
	return result and result.Position or (ray.Origin + ray.Direction * 500)
end

local function handleInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	local abilityName = keybindMap[input.KeyCode]
	if not abilityName then return end

	local character = localPlayer.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local payload: any = nil

	if abilityName == "Dash" then
		payload = root.CFrame.LookVector
	elseif abilityName == "Fireball" then
		payload = getAimPosition()
	elseif abilityName == "Slam" then
		payload = root.Position
	end

	UseAbilityEvent:FireServer(abilityName, payload)
end

function AbilityController.Init()
	UserInputService.InputBegan:Connect(handleInput)
end

return AbilityController
