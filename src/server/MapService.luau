--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local shared = ReplicatedStorage.Mayhem.Shared
local Catalog = require(shared.MapCatalog)
local MapRules = require(shared.MapRules)
local Config = require(shared.Config)
local Geometry = require(shared.Geometry)
local MapArt = require(shared.MapArt)
local Environment = require(shared.Environment)
local Maps = {}
Maps.__index = Maps

local function points(folder: Instance): { CFrame }
	local result = {}
	local children = folder:GetChildren()
	table.sort(children, function(a: Instance, b: Instance): boolean return a.Name < b.Name end)
	for _, child in children do if child:IsA("CFrameValue") then table.insert(result, child.Value) end end
	return result
end

function Maps.new(combat: any, effect: RemoteEvent)
	local self: any = setmetatable({ combat = combat, effect = effect, votes = {}, voteAt = {}, movers = {}, covers = {}, collapsing = {}, hazards = {}, connections = {}, running = false, duel = false, loading = false, generation = 0, random = Random.new(), safeRadius = 185, center = Vector3.zero }, Maps)
	self:load("Collapse")
	return self
end

function Maps.find(self: any, id: string): any
	for _, map in Catalog do if map.id == id then return map end end
	return nil
end

function Maps.load(self: any, id: string)
	local info = self:find(id)
	assert(info, "Unknown map selection")
	local world = Workspace:WaitForChild("MayhemWorld")
	while self.loading do task.wait() end
	if self.info == info and self.model and self.model:IsDescendantOf(world)
		and world:GetAttribute("ActiveMap") == id and world:GetAttribute("MapGeneration") == self.generation then
		return self.spawns
	end
	self.loading = true
	local ok, result = xpcall(function()
		local template = ServerStorage.MapTemplates:FindFirstChild(id)
		assert(template and template:IsA("Model"), "Map template is missing: " .. id)
		local nextMap = template:Clone()
		MapArt.dress(nextMap, id)
		local spawns = points(nextMap.Spawns)
		assert(#spawns == Config.Match.Capacity and #points(nextMap.DuelSpawns) == 2, "Map spawn contract failed")
		self:stop()
		self.generation += 1
		self.voteAt = {}
		for _, connection in self.connections do connection:Disconnect() end
		self.connections = {}
		local old = world:FindFirstChild("ActiveArena")
		if old then old:Destroy() end
		local active = Instance.new("Folder")
		active.Name = "ActiveArena"
		nextMap.Parent = active
		self.model, self.info, self.spawns = nextMap, info, spawns
		self.center, self.safeRadius, self.duel = Vector3.zero, MapRules.SafeStart, false
		Environment.build(nextMap, id)
		self.movers, self.covers, self.collapsing, self.hazards = {}, {}, {}, {}
		for _, part in nextMap.Motion:GetChildren() do
			if part:IsA("BasePart") then
				table.insert(self.movers, { part = part, base = part.CFrame, travel = part.Travel.Value, period = part.Period.Value })
			end
		end
		for _, part in nextMap.Destructibles:GetChildren() do
			if part:IsA("BasePart") then self.covers[part] = { health = 76, restoreAt = 0, color = part.Color } end
		end
		for _, part in nextMap.Collapse:GetChildren() do if part:IsA("BasePart") then table.insert(self.collapsing, { part = part, color = part.Color }) end end
		for _, part in nextMap.Hazards:GetChildren() do if part:IsA("BasePart") then table.insert(self.hazards, part); part.Transparency = 0.92 end end
		for _, part in nextMap.Ice:GetChildren() do if part:IsA("BasePart") then part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.035, 0.05, 50, 1) end end
		for _, part in nextMap.Decor:GetChildren() do
			if part:IsA("BasePart") then part:SetAttribute("MayhemDetail", true); if part.Name:find("Halo") then part:SetAttribute("QualityTier", 2) end end
		end
		for _, landmark in info.landmarks do
			local position = Vector3.new(table.unpack(landmark.p))
			local target = Vector3.new(0, position.Y, 0)
			if Vector3.new(position.X, 0, position.Z).Magnitude < 1 then target += Vector3.new(0, 0, 1) end
			Geometry.sign(nextMap.Decor, CFrame.lookAt(position, target), Vector3.new(11, 2.5, 0.2), landmark.name, info.name, Color3.fromRGB(table.unpack(info.palette.accent)))
		end
		for _, frame in points(nextMap.WeaponSpawns) do
			local pad = Instance.new("Part")
			pad.Name = "AmmoCache"
			pad.Size = Vector3.new(2, 1.5, 2)
			pad.CFrame = frame
			pad.Color = Color3.fromRGB(255, 191, 85)
			pad.Material = Enum.Material.Metal
			pad.Anchored = true
			pad.CanCollide, pad.CanTouch, pad.CanQuery = false, false, false
			pad.Parent = nextMap
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Collect 18 reserve rounds"
			prompt.ObjectText = "AMMO CACHE"
			prompt.HoldDuration = 0.2
			prompt.MaxActivationDistance = 8
			prompt.Parent = pad
			local readyAt = 0
			table.insert(self.connections, prompt.Triggered:Connect(function(player: Player)
				local now = os.clock()
				if not self.running or self.duel or now < readyAt then return end
				local record, root = self.combat:ready(player, now)
				if not record or not root or (root.Position - pad.Position).Magnitude > 8 then return end
				if record.reserve >= Config.Rifle.Reserve then self.effect:FireClient(player, "Notice", { title = "AMMO FULL", body = "Your reserve is already full." }); return end
				readyAt = now + 24
				record.reserve = math.min(Config.Rifle.Reserve, record.reserve + 18)
				prompt.Enabled = false
				pad.Transparency = 0.8
				self.combat.context.sendState(player)
				local generation = self.generation
				task.delay(24, function() if self.generation == generation and pad.Parent then prompt.Enabled = true; pad.Transparency = 0 end end)
			end))
		end
		active.Parent = world
		world:SetAttribute("ActiveMap", id)
		world:SetAttribute("MapGeneration", self.generation)
		local partCount = 0
		for _, item in world:GetDescendants() do if item:IsA("BasePart") then partCount += 1 end end
		world:SetAttribute("WorldPartCount", partCount)
		assert(partCount <= 720, "Arena and hub exceeded the world part budget")
		return spawns
	end, debug.traceback)
	self.loading = false
	if not ok then error(result, 0) end
	return result
end

function Maps.stop(self: any)
	self.running = false
	self.chaos = "STABLE"
	Workspace.Gravity = 196.2
end

function Maps.start(self: any, count: number)
	self.startedAt, self.initialCount = os.clock(), count
	self.running, self.duel = true, false
	self.chaos, self.chaosEnd, self.nextChaos, self.chaosIndex = "STABLE", 0, MapRules.ChaosInterval, 0
	self.lastDamageTick = 0
end

function Maps.bounds(self: any): any
	return { center = self.center, half = if self.duel then 34 else 145, ceiling = 85 }
end

function Maps.choose(self: any, eligible: { number }): string
	local id = MapRules.resolve(Catalog, self.votes, eligible, self.info.id, self.random:NextNumber())
	self.votes = {}
	return id
end

function Maps.vote(self: any, userId: number, choice: any): boolean
	if type(choice) ~= "string" or not self:find(choice) then return false end
	local now = os.clock()
	if self.votes[userId] == choice or now - (self.voteAt[userId] or -math.huge) < 0.4 then return false end
	self.voteAt[userId] = now
	self.votes[userId] = choice
	return true
end

function Maps.damageCover(self: any, target: Instance, amount: number)
	local record = self.covers[target]
	if not self.running or not record or record.restoreAt > 0 then return end
	record.health -= amount
	if record.health <= 0 then
		record.restoreAt = os.clock() + 20
		local part = target :: BasePart
		part.CanCollide, part.CanQuery = false, false
		MapArt.coverVisible(part, false)
		self.effect:FireAllClients("Destruction", { at = part.Position })
	end
end

function Maps.snapshot(self: any, eligible: { number }): any
	local counts: { [string]: number } = {}
	for _, map in Catalog do counts[map.id] = 0 end
	for _, userId in eligible do local id = self.votes[userId]; if id and counts[id] then counts[id] += 1 end end
	return { id = self.info.id, name = self.info.name, generation = self.generation, votes = counts, safeRadius = self.safeRadius, center = self.center, duel = self.duel, chaos = self.chaos or "STABLE", chaosRemaining = math.max(0, (self.chaosEnd or 0) - os.clock()) }
end

function Maps.tick(self: any, now: number)
	if not self.running then return end
	local elapsed = now - self.startedAt
	local alive = {}
	for player, record in self.combat.records do
		local character = record.character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if record.alive and humanoid and humanoid.Health > 0 and root then table.insert(alive, { player = player, record = record, root = root }) end
	end
	if #alive == 2 and not self.duel and elapsed >= (if self.initialCount <= 2 then MapRules.SparseDuelDelay else MapRules.DuelDelay) then
		self.duel, self.duelAt, self.center, self.safeRadius = true, now, Vector3.new(0, 0, -230), MapRules.DuelRadius
		Workspace.Gravity = 196.2
		self.chaos = "FINAL SHOWDOWN"
		local frames = points(self.model.DuelSpawns)
		for index, contender in alive do self.combat:transport(contender.player, frames[index], true) end
		self.effect:FireAllClients("Notice", { title = "FINAL SHOWDOWN", body = "Two signals remain. The duel deck is live." })
	end
	if self.duel then
		self.safeRadius = MapRules.duelRadius(now - self.duelAt)
		if now - self.lastDamageTick >= 1 then
			self.lastDamageTick = now
			for _, contender in alive do
				local offset = contender.root.Position - self.center
				if Vector3.new(offset.X, 0, offset.Z).Magnitude > self.safeRadius then self.combat:damage(contender.player, nil, 9, "Outside the duel signal", now) end
			end
		end
		return
	end
	self.safeRadius = MapRules.radius(elapsed, Config.Match.Duration)
	if elapsed >= self.nextChaos then
		self.chaosIndex += 1
		self.chaos = if self.chaosIndex % 2 == 1 then "LOW GRAVITY" else "SHIELD DROUGHT"
		self.chaosEnd = now + MapRules.ChaosDuration
		self.nextChaos = elapsed + MapRules.ChaosInterval
		Workspace.Gravity = if self.chaos == "LOW GRAVITY" then MapRules.LowGravity else 196.2
		self.effect:FireAllClients("Notice", { title = self.chaos, body = "Reality mutation / " .. MapRules.ChaosDuration .. " seconds" })
	elseif self.chaos ~= "STABLE" and now >= self.chaosEnd then self.chaos = "STABLE"; Workspace.Gravity = 196.2 end
	local hazardActive = elapsed % 16 >= 12
	for _, hazard in self.hazards do hazard.Transparency = if hazardActive then 0.55 else 0.94 end
	for index, item in self.collapsing do
		local cycle = (elapsed + index * 7) % 48
		local collapsed = cycle >= 38
		item.part.CanCollide, item.part.CanQuery = not collapsed, not collapsed
		item.part.Transparency = if collapsed then 1 elseif cycle >= 35 then 0.5 else 0
		item.part.Color = if cycle >= 35 then Color3.fromRGB(255, 151, 65) else item.color
	end
	for _, mover in self.movers do
		local nextFrame = mover.base + mover.travel * ((1 - math.cos(elapsed * math.pi * 2 / mover.period)) / 2)
		local delta = nextFrame.Position - mover.part.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { mover.part }
		for _, contender in alive do
			local hit = Workspace:Raycast(contender.root.Position, Vector3.new(0, -5, 0), params)
			if hit then self.combat:transport(contender.player, contender.root.CFrame + delta, false) end
		end
		mover.part.CFrame = nextFrame
	end
	for part, record in self.covers do
		if record.restoreAt > 0 and now >= record.restoreAt then
			local occupied = false
			for _, contender in alive do if MapRules.inside(contender.root.Position, part.Position, part.Size / 2 + Vector3.new(2, 4, 2)) then occupied = true end end
			if occupied then record.restoreAt = now + 1 else record.restoreAt = 0; record.health = 76; part.CanCollide, part.CanQuery = true, true; MapArt.coverVisible(part, true) end
		end
	end
	if now - self.lastDamageTick >= 1 then
		self.lastDamageTick = now
		for _, contender in alive do
			local offset = contender.root.Position - self.center
			if Vector3.new(offset.X, 0, offset.Z).Magnitude > self.safeRadius then self.combat:damage(contender.player, nil, 9, "Outside the safe zone", now) end
			if hazardActive then
				for _, hazard in self.hazards do
					if MapRules.inside(contender.root.Position, hazard.Position, hazard.Size / 2 + Vector3.new(0, 3, 0)) then self.combat:damage(contender.player, nil, 8, self.info.hazard, now) end
				end
			end
			if self.chaos == "SHIELD DROUGHT" then contender.record.damagedAt = now end
		end
	end
end

return Maps
