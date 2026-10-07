# roblox-multiplayer-loot-arena-test

Multiplayer Loot Arena — Technical Assignment Developer: Arshad

Role: Roblox Scripter Assignment — Soaring Eagle Games

Architecture Overview The project is built on a standard Server-Client (Service-Controller) setup in Luau:

ServerScriptService/Services/

AbilityService: Handles ability execution, server-side cooldown validation, projectile creation, raycasting/collision detection, and damage logic.

LootService: Manages loot spawning across the arena, handles pickup validation, tracks player counts, and syncs data to clients.

StarterPlayerScripts/Controllers/

AbilityController: Captures keybind inputs (Q / E / R / LeftShift), handles camera raycasting for mouse targeting, and fires server events.

ReplicatedStorage/Shared/

AbilitiesConfig: Shared module containing ability stats (cooldowns, damage, speed, keys).

Network: RemoteEvent communication channels.

What's Working Core Mechanics & Networking Server Authority: All damage, loot pickups, and cooldown tracking (os.clock()) are validated server-side to prevent client spoofing.

Loot System: Randomly spawns items in arena bounds, detects pickups via touched connections, updates client UI, and handles respawn timers.

Abilities Dash (E / Left Shift): Applies a short direction-based LinearVelocity impulse to the player's HumanoidRootPart.

Fireball (Q): Casts a projectile toward the target position using LinearVelocity with collision filtering, trail visual effects, muzzle flash, and an impact explosion.

Ground Slam (R): Triggers an AoE ring effect and hits surrounding characters using workspace:GetPartBoundsInRadius with OverlapParams filtering.

Arena Setup 200x200 bounded arena with perimeter walls and basic cover objects to test spell collisions and line-of-sight targeting.

What Was Omitted & Trade-offs Persistent DataStore: Player loot counts are stored in-memory in LootService and reset when leaving the session. Focused time on getting the physics, network sync, and combat feel right within the timeframe rather than adding DataStore boilerplate.

UI Polish: The loot UI updates instantly when picking up items, but lacks extra polish like floating text animations or sound effects.

Potential Next Steps DataStore Integration: Save player loot counts across sessions.

Client-Side FX Prediction: Fire visual projectiles locally on input so spell casts feel zero-latency on high ping.

Animations & SFX: Add character cast animations and sound effects for spell impacts and loot pickups.
