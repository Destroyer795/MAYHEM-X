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
	checks += require(script.StyleCases)(require(shared.StyleRules), Visuals)
	checks += require(script.MapRulesCases)(require(shared.MapRules))
	checks += require(script.PreferenceCases)(require(shared.PreferenceRules))
	checks += require(script.ProfileCases)(require(shared.ProfileRules), require(shared.PreferenceRules), Visuals)
	checks += require(script.SessionLeaseCases)(require(game.ServerScriptService.MayhemServer.SessionLease))
	checks += require(script.AudioCases)(require(shared.AudioConfig))
	assert(ReplicatedStorage.Mayhem.Presentation:IsA("RemoteEvent"), "Presentation remote is missing")
	checks += 1
	for _, name in Protocol.Remote do
		local remote = ReplicatedStorage.Mayhem.Remotes:FindFirstChild(name)
		assert(remote and remote:IsA("RemoteEvent"), "Missing RemoteEvent: " .. name)
		checks += 1
	end
	local world = workspace:WaitForChild("MayhemWorld", 10)
	assert(world, "Arena bootstrap did not finish")
	local active = world:FindFirstChild("ActiveArena")
	local arena = if active then active:FindFirstChildWhichIsA("Model") else nil
	assert(arena and arena:FindFirstChild("Spawns") and arena:FindFirstChild("Duel"), "Arena geometry is incomplete")
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
		if item.Name:match("^InsertionPad_") then pads += 1 end
		if item:IsA("BasePart") then assert(item.Anchored, "Arena geometry must remain anchored"); checks += 1 end
	end
	assert(pads == Config.Match.Capacity, "The arena must expose sixteen insertion pads")
	checks += 1
	local markers = (arena :: Instance):FindFirstChild("WeaponSpawns")
	assert(markers and #markers:GetChildren() == 4, "Four future weapon drop points are required")
	checks += 1
	print(string.format("MAYHEM X: %d Studio structure and rules assertions passed. Multiplayer checklist remains required.", checks))
	return checks
end

function Tests.maps(): number
	assert(RunService:IsStudio() and RunService:IsServer(), "Validate maps in a Studio server simulation")
	local templates = game:GetService("ServerStorage"):WaitForChild("MapTemplates")
	assert(#templates:GetChildren() == 5, "Five playable templates are required")
	local checks = 0
	for _, template in templates:GetChildren() do
		local clone = template:Clone() :: Model
		clone:PivotTo(clone:GetPivot() + Vector3.new(1500, 0, 0))
		clone.Parent = workspace
		RunService.Heartbeat:Wait()
		local ok, message = pcall(function()
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { clone.Solid, clone.Ice }
			assert(#clone.Spawns:GetChildren() == 16 and #clone.DuelSpawns:GetChildren() == 2, "Spawn contract failed")
			for _, value in clone.Spawns:GetChildren() do
				local origin = (value :: CFrameValue).Value.Position + Vector3.new(1500, 0, 0)
				assert(workspace:Raycast(origin, Vector3.new(0, -8, 0), params), "Unsupported spawn in " .. template.Name)
				checks += 1
			end
		end)
		clone:Destroy()
		assert(ok, message)
	end
	print("MAYHEM X: " .. checks .. " actual Studio spawn raycasts passed. Traversal and multiplayer remain manual.")
	return checks
end

return Tests
