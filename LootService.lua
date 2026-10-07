local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UpdateLootEvent = ReplicatedStorage.Shared.Network:WaitForChild("UpdateLootEvent") :: RemoteEvent

local LootService = {}
local playerLootCounts: { [number]: number } = {}
local rng = Random.new()

local SPAWN_BOUNDS = 70
local SPAWN_HEIGHT = 3
local RESPAWN_DELAY = 5
local INITIAL_LOOT_COUNT = 10

function LootService.SpawnLootItem()
	local part = Instance.new("Part")
	part.Name = "LootItem"
	part.Size = Vector3.new(2, 2, 2)
	part.Color = Color3.fromRGB(255, 220, 0)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false

	local randomX = rng:NextNumber(-SPAWN_BOUNDS, SPAWN_BOUNDS)
	local randomZ = rng:NextNumber(-SPAWN_BOUNDS, SPAWN_BOUNDS)
	part.Position = Vector3.new(randomX, SPAWN_HEIGHT, randomZ)
	part.Parent = workspace

	local touchedConnection: RBXScriptConnection? = nil
	touchedConnection = part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		if touchedConnection then
			touchedConnection:Disconnect()
			touchedConnection = nil
		end

		part:Destroy()

		local userId = player.UserId
		playerLootCounts[userId] = (playerLootCounts[userId] or 0) + 1
		UpdateLootEvent:FireClient(player, playerLootCounts[userId])

		task.delay(RESPAWN_DELAY, function()
			LootService.SpawnLootItem()
		end)
	end)
end

function LootService.GetLoot(player: Player): number
	return playerLootCounts[player.UserId] or 0
end

function LootService.Init()
	Players.PlayerAdded:Connect(function(player)
		playerLootCounts[player.UserId] = 0
		UpdateLootEvent:FireClient(player, 0)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerLootCounts[player.UserId] = nil
	end)

	for _ = 1, INITIAL_LOOT_COUNT do
		LootService.SpawnLootItem()
	end
end

return LootService
