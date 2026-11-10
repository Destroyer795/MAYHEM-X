--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tests = {}
function Tests.run(): number
	assert(RunService:IsStudio() and RunService:IsServer(), "Run these checks in the Studio server simulation")
	local shared = ReplicatedStorage:WaitForChild("Mayhem"):WaitForChild("Shared")
	local Config = require(shared.Config)
	local Rules = require(shared.Rules)
	local Protocol = require(shared.Protocol)
	local checks = require(script.RulesCases)(Rules, Config)
	local Visuals = require(shared.Visuals)
	checks += require(script.VisualCases)(Visuals)
	for _, name in Protocol.Remote do
		local remote = ReplicatedStorage.Mayhem.Remotes:FindFirstChild(name)
		assert(remote and remote:IsA("RemoteEvent"), "Missing RemoteEvent: " .. name)
		checks += 1
	end
	local world = workspace:WaitForChild("MayhemWorld", 10)
	assert(world, "Arena bootstrap did not finish")
	local arena = world:FindFirstChild("TheCollapse")
	assert(arena and arena:FindFirstChild("SecretVaultFloor") and world:FindFirstChild("FinalDuelDeck"), "Arena geometry is incomplete")
	checks += 1
	local detailCount = 0
	for _, item in world:GetDescendants() do
		if item:IsA("BasePart") then
			detailCount += 1
			if item:GetAttribute("MayhemDetail") then assert(not item.CanCollide and not item.CanTouch and not item.CanQuery, "Decor cannot affect combat geometry"); checks += 1 end
		end
	end
	assert(detailCount <= Visuals.Budgets.WorldParts and world:FindFirstChild("ArtDirection"), "Visual world is missing or over budget")
	checks += 1
	local pads = 0
	for _, item in (arena :: Instance):GetDescendants() do
		if item.Name == "InsertionPad" then pads += 1 end
		if item:IsA("BasePart") then assert(item.Anchored, "Arena geometry must remain anchored"); checks += 1 end
	end
	assert(pads == Config.Match.Capacity, "The arena must expose sixteen insertion pads")
	checks += 1
	local markers = (arena :: Instance):FindFirstChild("WeaponSpawnPoints")
	assert(markers and #markers:GetChildren() == 4, "Four future weapon drop points are required")
	checks += 1
	print(string.format("MAYHEM X: %d Studio structure and rules assertions passed. Multiplayer checklist remains required.", checks))
	return checks
end

return Tests
