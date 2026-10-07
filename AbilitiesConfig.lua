export type AbilityData = {
	Cooldown: number,
	Key: Enum.KeyCode,
	ImpulsePower: number?,
	Speed: number?,
	Damage: number?,
	Lifetime: number?,
	Radius: number?,
}

export type ConfigTable = {
	[string]: AbilityData,
}

local AbilitiesConfig: ConfigTable = {
	Dash = {
		Cooldown = 2,
		ImpulsePower = 100,
		Key = Enum.KeyCode.E,
	},
	Fireball = {
		Cooldown = 1.5,
		Speed = 150,
		Damage = 25,
		Lifetime = 5,
		Key = Enum.KeyCode.Q,
	},
	Slam = {
		Cooldown = 5,
		Radius = 15,
		Damage = 40,
		Key = Enum.KeyCode.R,
	},
}

return AbilitiesConfig
