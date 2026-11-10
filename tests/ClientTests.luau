--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Tests = {}

function Tests.run(): number
	assert(RunService:IsStudio() and RunService:IsClient(), "Run client checks in a Studio client simulation")
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MayhemHUD", 10)
	assert(gui, "HUD bootstrap did not finish")
	local checks = 0
	for _, name in { "Telemetry", "Vitals", "HealthTrack", "ShieldTrack", "UltimateTrack", "Weapon", "Repulse", "Navigation", "Deploy", "Matchmaking", "Mode", "Character", "Inventory", "Shop", "Daily", "Settings", "Insertion", "Results", "Standings", "TouchCombat" } do
		assert(gui:FindFirstChild(name, true), "Missing UI reference: " .. name)
		checks += 1
	end
	local audio = SoundService:WaitForChild("MayhemAudio", 5)
	assert(audio, "Audio routes were not created")
	for _, name in { "Music", "Ambience", "Effects", "UI" } do
		local group = audio:FindFirstChild(name) :: SoundGroup?
		assert(group and group:IsA("SoundGroup") and group.Volume >= 0 and group.Volume <= 1, "Invalid audio routing: " .. name)
		checks += 1
	end
	local effects = workspace:FindFirstChild("MayhemLocalEffects")
	assert(effects and #effects:GetChildren() <= Visuals.Budgets.EffectRoots, "Effect root budget exceeded")
	for _, item in (effects :: Instance):GetDescendants() do
		if item:IsA("BasePart") then assert(not item.CanCollide and not item.CanTouch and not item.CanQuery, "Effects must not affect combat traces"); checks += 1 end
	end
	local character = Players.LocalPlayer.Character
	local style = if character then character:FindFirstChild("MayhemStyle") else nil
	if style then
		for _, item in style:GetChildren() do
			if item:IsA("BasePart") then assert(item.Massless and not item.CanCollide and not item.CanQuery, "Cosmetics must not change character physics"); checks += 1 end
		end
	end
	print(string.format("MAYHEM X: %d client references, routing and visual-safety checks passed. Layout, input and multiplayer acceptance remain manual.", checks))
	return checks
end

return Tests
