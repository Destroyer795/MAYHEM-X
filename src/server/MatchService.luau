--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage.Mayhem.Shared
local Config = require(shared.Config)
local Protocol = require(shared.Protocol)
local Rules = require(shared.Rules)
local Combat = require(script.Parent.CombatService)
local Arena = require(script.Parent.ArenaService)
local MapService = require(script.Parent.MapService)
local MapRules = require(shared.MapRules)

local Match = {}
Match.__index = Match

function Match.new(remotes: Folder)
	local self: any = setmetatable({
		phase = Protocol.Phase.Waiting, deadline = 0, roundId = 0, order = 0,
		entries = {}, roster = {}, lastBroadcast = 0, result = nil, random = Random.new(), loadingRound = false, resetting = false,
		action = remotes:WaitForChild(Protocol.Remote.Action), state = remotes:WaitForChild(Protocol.Remote.State),
		effect = remotes:WaitForChild(Protocol.Remote.Effect), feed = remotes:WaitForChild(Protocol.Remote.Feed),
	}, Match)
	self.combat = Combat.new({
		canFight = function(): boolean return self.phase == Protocol.Phase.Active end,
		bounds = function() return self.maps:bounds() end,
		environmentHit = function(part: Instance, damage: number) self.maps:damageCover(part, damage) end,
		eliminate = function(victim: Player, attacker: Player?, cause: string) self:eliminate(victim, attacker, cause) end,
		sendState = function(player: Player) self:sendState(player) end,
		effect = self.effect,
	})
	self.maps = MapService.new(self.combat, self.effect)
	return self
end

function Match.transition(self: any, nextPhase: string, duration: number)
	assert(Rules.canTransition(self.phase, nextPhase), "Illegal match transition: " .. self.phase .. " to " .. nextPhase)
	self.phase = nextPhase
	self.deadline = if duration > 0 then os.clock() + duration else 0
	self:broadcast()
end

function Match.enqueue(self: any, entry: any)
	self.order += 1
	entry.queueOrder = self.order
end

function Match.queue(self: any): { Player }
	local queued = {}
	for player, entry in self.entries do
		if entry.wantsQueue and entry.queueOrder and not entry.inMatch then
			table.insert(queued, player)
		end
	end
	table.sort(queued, function(a: Player, b: Player): boolean
		return self.entries[a].queueOrder < self.entries[b].queueOrder
	end)
	return queued
end

function Match.alive(self: any): { number }
	local result = {}
	for player, entry in self.roster do
		local record = self.combat.records[player]
		if self.entries[player] == entry and not entry.eliminated and entry.loaded and record and record.alive then
			table.insert(result, player.UserId)
		end
	end
	return result
end

function Match.sendState(self: any, player: Player)
	local entry = self.entries[player]
	if not entry or player.Parent ~= Players then
		return
	end
	local now = os.clock()
	local eligible = {}
	local upcoming = self:queue()
	for index = 1, math.min(#upcoming, Config.Match.Capacity) do table.insert(eligible, upcoming[index].UserId) end
	self.state:FireClient(player, {
		phase = self.phase, roundId = self.roundId, remaining = math.max(0, self.deadline - now),
		queued = entry.wantsQueue, queueCount = #self:queue(), capacity = Config.Match.Capacity,
		inMatch = entry.inMatch, alive = entry.inMatch and entry.loaded and not entry.eliminated,
		remainingPlayers = #self:alive(), kills = entry.kills, combat = self.combat:snapshot(player, now),
		result = self.result,
		map = self.maps:snapshot(eligible), vote = self.maps.votes[player.UserId], ballotEligible = table.find(eligible, player.UserId) ~= nil,
	})
end

function Match.broadcast(self: any)
	for player in self.entries do
		self:sendState(player)
	end
	self.lastBroadcast = os.clock()
end

function Match.characterLost(self: any, player: Player, serial: number)
	local entry = self.entries[player]
	if not entry or serial ~= entry.spawnSerial or entry.expectedRemoval then
		return
	end
	if entry.inMatch and not entry.eliminated then
		self:eliminate(player, self.combat:credit(player, os.clock()), "Eliminated")
	else
		task.delay(2, function()
			if self.entries[player] == entry and serial == entry.spawnSerial then
				self:spawn(player, Arena.lobbyFrame(player.UserId), nil)
			end
		end)
	end
end

function Match.spawn(self: any, player: Player, frame: CFrame, roundId: number?)
	local entry = self.entries[player]
	if not entry then
		return
	end
	entry.spawnSerial += 1
	entry.pendingSpawn = { frame = frame, roundId = roundId, serial = entry.spawnSerial }
	if entry.spawnBusy then
		return
	end
	entry.spawnBusy = true
	task.spawn(function()
		while self.entries[player] == entry and entry.pendingSpawn do
			local request = entry.pendingSpawn
			entry.pendingSpawn = nil
			if entry.deathConnection then
				entry.deathConnection:Disconnect()
				entry.deathConnection = nil
			end
			entry.expectedRemoval = true
			local ok, message = pcall(function() player:LoadCharacterAsync() end)
			entry.expectedRemoval = false
			local character = player.Character
			if ok and character and request.serial == entry.spawnSerial and self.entries[player] == entry then
				local humanoid = character:WaitForChild("Humanoid", 6) :: Humanoid?
				local root = character:WaitForChild("HumanoidRootPart", 6) :: BasePart?
				if humanoid and root and request.serial == entry.spawnSerial and self.entries[player] == entry then
					character:PivotTo(request.frame)
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
					humanoid.NameDisplayDistance = 65
					humanoid.HealthDisplayDistance = 0
					local field = character:FindFirstChildOfClass("ForceField")
					if field then field:Destroy() end
					entry.deathConnection = humanoid.Died:Connect(function() self:characterLost(player, request.serial) end)
					if request.roundId then
						if self.phase == Protocol.Phase.Loading and request.roundId == self.roundId and entry.inMatch and not entry.eliminated then
							self.combat:beginLife(player, character)
							entry.loaded = true
						end
					else
						humanoid.MaxHealth = Config.Character.Health
						humanoid.Health = Config.Character.Health
						humanoid.WalkSpeed = Config.Character.WalkSpeed
						humanoid.UseJumpPower = true
						humanoid.JumpPower = Config.Character.JumpPower
						root.Anchored = false
					end
				end
			elseif not ok then
				warn("MAYHEM X character load failed for player " .. player.UserId .. ": " .. tostring(message))
			end
		end
		entry.spawnBusy = false
	end)
end

function Match.add(self: any, player: Player)
	if self.entries[player] then return end
	local now = os.clock()
	local entry: any = {
		name = player.DisplayName, wantsQueue = false, queueOrder = nil, inMatch = false,
		eliminated = false, loaded = false, kills = 0, spawnSerial = 0, spawnBusy = false,
		expectedRemoval = false, tokens = Config.Security.RequestBurst, requestAt = now, readyAt = -math.huge,
	}
	self.entries[player] = entry
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	for _, name in { "Kills", "Wins" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	entry.removingConnection = player.CharacterRemoving:Connect(function() self:characterLost(player, entry.spawnSerial) end)
	self:spawn(player, Arena.lobbyFrame(player.UserId), nil)
	self:sendState(player)
end

function Match.remove(self: any, player: Player)
	local entry = self.entries[player]
	if not entry then return end
	if entry.inMatch and not entry.eliminated then
		self:eliminate(player, self.combat:credit(player, os.clock()), "Disconnected")
	end
	entry.spawnSerial += 1
	entry.pendingSpawn = nil
	if entry.deathConnection then entry.deathConnection:Disconnect() end
	entry.removingConnection:Disconnect()
	self.entries[player] = nil
	self.combat:remove(player)
	self.maps.votes[player.UserId] = nil
	self.maps.voteAt[player.UserId] = nil
end

function Match.eliminate(self: any, victim: Player, attacker: Player?, cause: string)
	local entry = self.entries[victim]
	if not entry or not entry.inMatch or entry.eliminated then return end
	entry.eliminated = true
	self.combat:endLife(victim)
	if self.phase == Protocol.Phase.Active then
		local killer = if attacker and attacker ~= victim then self.roster[attacker] else nil
		if killer and self.entries[attacker] == killer then
			killer.kills += 1
			self.combat:addCharge(attacker)
			local stats = (attacker :: Player):FindFirstChild("leaderstats")
			if stats then
				local value = stats:FindFirstChild("Kills") :: IntValue?
				if value then value.Value += 1 end
			end
		end
		self.feed:FireAllClients({ killer = if killer then killer.name else nil, victim = entry.name, cause = cause })
	end
	local round = self.roundId
	task.delay(2, function()
		if self.entries[victim] == entry and entry.eliminated and self.roundId == round then
			self:spawn(victim, Arena.lobbyFrame(victim.UserId), nil)
		end
	end)
	self:sendState(victim)
end

function Match.beginLoading(self: any)
	local queued = self:queue()
	local eligible = {}
	for index = 1, math.min(#queued, Config.Match.Capacity) do table.insert(eligible, queued[index].UserId) end
	local choice = self.maps:choose(eligible)
	local ok, frames = pcall(function() return self.maps:load(choice) end)
	if not ok then
		warn("MAYHEM X map load failed: " .. tostring(frames))
		self:transition(Protocol.Phase.Waiting, 0)
		self.effect:FireAllClients("Notice", { title = "MAP LOAD FAILED", body = "Your queue position is preserved. Retrying next intermission." })
		return
	end
	self.roundId += 1
	self.result = nil
	self.roster = {}
	frames = table.clone(frames)
	for index = #frames, 2, -1 do
		local swap = self.random:NextInteger(1, index)
		frames[index], frames[swap] = frames[swap], frames[index]
	end
	for index = 1, math.min(#queued, Config.Match.Capacity) do
		local player = queued[index]
		local entry = self.entries[player]
		entry.inMatch = true
		entry.eliminated = false
		entry.loaded = false
		entry.kills = 0
		entry.queueOrder = nil
		self.roster[player] = entry
	end
	self:transition(Protocol.Phase.Loading, Config.Match.LoadingTimeout)
	local index = 0
	for player in self.roster do
		index += 1
		self:spawn(player, frames[index], self.roundId)
	end
end

function Match.finish(self: any, winnerId: number?, reason: string)
	if self.phase ~= Protocol.Phase.Active and self.phase ~= Protocol.Phase.Loading and self.phase ~= Protocol.Phase.Countdown then return end
	local wasActive = self.phase == Protocol.Phase.Active
	self.maps:stop()
	local standings = {}
	local winnerName = "NO WINNER"
	for player, entry in self.roster do
		table.insert(standings, { name = entry.name, kills = entry.kills, userId = player.UserId })
		if winnerId == player.UserId then
			winnerName = entry.name
			local stats = player:FindFirstChild("leaderstats")
			local wins = if stats then stats:FindFirstChild("Wins") :: IntValue? else nil
			if wasActive and wins then wins.Value += 1 end
		end
		local record = self.combat.records[player]
		if record and record.alive and record.character then
			local root = record.character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then root.Anchored = true end
		end
		self.combat:endLife(player)
		if not wasActive and self.entries[player] then
			self:spawn(player, Arena.lobbyFrame(player.UserId), nil)
		end
	end
	table.sort(standings, function(a: any, b: any): boolean
		return if a.kills == b.kills then a.userId < b.userId else a.kills > b.kills
	end)
	self.result = { winnerId = winnerId, winner = winnerName, reason = reason, standings = standings }
	self:transition(Protocol.Phase.Results, Config.Match.ResultsDuration)
end

function Match.reset(self: any)
	for player, entry in self.roster do
		if self.entries[player] == entry then
			entry.inMatch = false
			entry.loaded = false
			entry.eliminated = false
			self.combat:remove(player)
			if entry.wantsQueue then self:enqueue(entry) end
			self:spawn(player, Arena.lobbyFrame(player.UserId), nil)
		end
	end
	self.roster = {}
	self.result = nil
	self.maps:load(self.maps.info.id)
	self:transition(Protocol.Phase.Waiting, 0)
end

function Match.handle(self: any, player: Player, action: any, payload: any)
	local entry = self.entries[player]
	if not entry then return end
	local now = os.clock()
	local allowed, tokens = Rules.spend(entry.tokens, entry.requestAt, now, Config.Security.RequestsPerSecond, Config.Security.RequestBurst, 1)
	entry.tokens = tokens
	entry.requestAt = now
	if not allowed or type(action) ~= "string" or #action > 16 then return end
	local actions = Protocol.Action
	if action == actions.Ready then
		if now - entry.readyAt >= 1 then
			entry.readyAt = now
			self:sendState(player)
		end
	elseif action == actions.Queue then
		if type(payload) == "boolean" and not entry.inMatch and entry.wantsQueue ~= payload then
			entry.wantsQueue = payload
			if payload then self:enqueue(entry) else entry.queueOrder = nil end
			self:broadcast()
		end
	elseif action == actions.Fire then
		self.combat:fire(player, payload, now)
	elseif action == actions.Melee then
		self.combat:melee(player, payload, now)
	elseif action == actions.Switch then
		self.combat:switch(player, payload, now)
	elseif action == actions.Reload then
		self.combat:reload(player, now)
	elseif action == actions.Ability then
		self.combat:ability(player, now)
	elseif action == MapRules.Command.Vote then
		local rank = table.find(self:queue(), player)
		if rank and rank <= Config.Match.Capacity and not entry.inMatch and (self.phase == "Waiting" or self.phase == "Intermission") and self.maps:vote(player.UserId, payload) then self:broadcast() end
	elseif action == MapRules.Command.Ultimate then
		self.combat:ultimate(player, now)
	end
end

function Match.tick(self: any, dt: number)
	local now = os.clock()
	self.maps:tick(now)
	self.combat:tick(now, dt)
	local phase = Protocol.Phase
	if self.phase == phase.Waiting then
		if #self:queue() >= Config.Match.MinimumPlayers then self:transition(phase.Intermission, Config.Match.Intermission) end
	elseif self.phase == phase.Intermission then
		if #self:queue() < Config.Match.MinimumPlayers then
			self:transition(phase.Waiting, 0)
		elseif now >= self.deadline and not self.loadingRound then
			self.loadingRound = true
			local ok, message = pcall(function() self:beginLoading() end)
			self.loadingRound = false
			if not ok then
				warn("MAYHEM X round startup failed: " .. tostring(message))
				if self.phase == phase.Intermission then self:transition(phase.Waiting, 0) end
			end
		end
	elseif self.phase == phase.Loading then
		local pending = 0
		for player, entry in self.roster do
			if not entry.loaded and not entry.eliminated then
				if now >= self.deadline then
					self:eliminate(player, nil, "Spawn timeout")
				else pending += 1 end
			end
		end
		if pending == 0 then
			if #self:alive() >= Config.Match.MinimumPlayers then
				self:transition(phase.Countdown, Config.Match.Countdown)
			else self:finish(nil, "Round canceled: not enough ready players") end
		end
	elseif self.phase == phase.Countdown then
		if #self:alive() < Config.Match.MinimumPlayers then
			self:finish(nil, "Round canceled: not enough survivors")
		elseif now >= self.deadline then
			self.maps:start(#self:alive())
			for player in self.roster do self.combat:release(player, now) end
			self:transition(phase.Active, Config.Match.Duration)
		end
	elseif self.phase == phase.Active then
		local done, winner, reason = Rules.outcome(self:alive(), now >= self.deadline)
		if done then self:finish(winner, reason) end
	elseif self.phase == phase.Results and now >= self.deadline and not self.resetting then
		self.resetting = true
		local ok, message = pcall(function() self:reset() end)
		self.resetting = false
		if not ok then warn("MAYHEM X round reset failed: " .. tostring(message)) end
	end
	if now - self.lastBroadcast >= Config.NetworkInterval then self:broadcast() end
end

return Match
