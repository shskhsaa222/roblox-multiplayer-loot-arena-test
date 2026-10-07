local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local AbilitiesConfig = require(ReplicatedStorage.Shared.Config.AbilitiesConfig)
local UseAbilityEvent = ReplicatedStorage.Shared.Network:WaitForChild("UseAbilityEvent") :: RemoteEvent

local AbilityService = {}
local cooldowns: { [number]: { [string]: number } } = {}

local function createMuzzleEffect(position: Vector3)
	local muzzle = Instance.new("Part")
	muzzle.Size = Vector3.new(2, 2, 2)
	muzzle.Shape = Enum.PartType.Ball
	muzzle.Material = Enum.Material.Neon
	muzzle.Color = Color3.fromRGB(0, 200, 255)
	muzzle.Anchored = true
	muzzle.CanCollide = false
	muzzle.CFrame = CFrame.new(position)
	muzzle.Parent = workspace

	TweenService:Create(muzzle, TweenInfo.new(0.12), {
		Size = Vector3.new(0.1, 0.1, 0.1),
		Transparency = 1,
	}):Play()

	Debris:AddItem(muzzle, 0.12)
end

local function createHitEffect(position: Vector3)
	local burst = Instance.new("Part")
	burst.Size = Vector3.new(2, 2, 2)
	burst.Shape = Enum.PartType.Ball
	burst.Material = Enum.Material.Neon
	burst.Color = Color3.fromRGB(0, 255, 255)
	burst.Anchored = true
	burst.CanCollide = false
	burst.CFrame = CFrame.new(position)
	burst.Parent = workspace

	TweenService:Create(burst, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(6, 6, 6),
		Transparency = 1,
	}):Play()

	Debris:AddItem(burst, 0.2)
end

local function handleDash(player: Player, direction: Vector3?, config: any)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local moveDir = (typeof(direction) == "Vector3" and direction.Magnitude > 0) 
		and direction.Unit 
		or root.CFrame.LookVector

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = 100000
	velocity.VectorVelocity = moveDir * (config.ImpulsePower or 100)
	velocity.Attachment0 = attachment
	velocity.Parent = root

	Debris:AddItem(velocity, 0.2)
	Debris:AddItem(attachment, 0.2)
end

local function handleFireball(player: Player, targetPosition: Vector3?, config: any)
	local character = player.Character
	if not character or typeof(targetPosition) ~= "Vector3" then return end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local origin = root.Position + Vector3.new(0, 2, 0)
	local aimVector = targetPosition - origin
	local direction = aimVector.Magnitude > 0.1 and aimVector.Unit or root.CFrame.LookVector
	local spawnPos = origin + (direction * 4)

	local projectile = Instance.new("Part")
	projectile.Name = "Fireball"
	projectile.Size = Vector3.new(1.5, 1.5, 1.5)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(0, 200, 255)
	projectile.CanCollide = false
	projectile.Massless = true
	projectile.CFrame = CFrame.new(spawnPos, spawnPos + direction)
	projectile.Parent = workspace

	local attachment = Instance.new("Attachment", projectile)
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = 1000000
	linearVelocity.VectorVelocity = direction * (config.Speed or 140)
	linearVelocity.Parent = projectile

	local att0 = Instance.new("Attachment", projectile)
	local att1 = Instance.new("Attachment", projectile)
	att0.Position = Vector3.new(0, -0.75, 0)
	att1.Position = Vector3.new(0, 0.75, 0)

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.35
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 100, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = projectile

	createMuzzleEffect(origin + direction * 2)

	local connection: RBXScriptConnection? = nil
	connection = projectile.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) or hit:IsDescendantOf(workspace:FindFirstChild("Projectiles") or workspace) then
			if hit:IsDescendantOf(character) then return end
		end

		local targetHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if targetHumanoid and targetHumanoid.Health > 0 then
			targetHumanoid:TakeDamage(config.Damage or 25)
		end

		createHitEffect(projectile.Position)

		if connection then
			connection:Disconnect()
		end
		projectile:Destroy()
	end)

	Debris:AddItem(projectile, config.Lifetime or 5)
end

local function handleSlam(player: Player, _: any, config: any)
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local radius = config.Radius or 15
	local ring = Instance.new("Part")
	ring.Size = Vector3.new(radius * 2, 0.2, radius * 2)
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 100, 0)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	Debris:AddItem(ring, 0.4)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local parts = workspace:GetPartBoundsInRadius(root.Position, radius, params)
	local hitHumanoids: { [Humanoid]: boolean } = {}

	for _, part in ipairs(parts) do
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not hitHumanoids[humanoid] and humanoid.Health > 0 then
			hitHumanoids[humanoid] = true
			humanoid:TakeDamage(config.Damage or 40)
		end
	end
end

local handlers = {
	Dash = handleDash,
	Fireball = handleFireball,
	Slam = handleSlam,
}

function AbilityService.Init()
	UseAbilityEvent.OnServerEvent:Connect(function(player: Player, abilityName: string, param: any)
		if typeof(abilityName) ~= "string" then return end

		local config = AbilitiesConfig[abilityName]
		local handler = handlers[abilityName]
		if not config or not handler then return end

		local userId = player.UserId
		if not cooldowns[userId] then
			cooldowns[userId] = {}
		end

		local lastUsed = cooldowns[userId][abilityName] or 0
		local now = os.clock()

		if now - lastUsed < (config.Cooldown or 0) then
			return
		end

		cooldowns[userId][abilityName] = now
		handler(player, param, config)
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
	end)
end

return AbilityService
