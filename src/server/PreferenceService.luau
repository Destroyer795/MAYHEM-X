--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Mayhem.Shared
local Rules = require(Shared.PreferenceRules)
local ProfileRules = require(Shared.ProfileRules)
local Visuals = require(Shared.Visuals)
local Preferences = {}
Preferences.__index = Preferences

local LOCK_TTL = 120
local AUTOSAVE_INTERVAL = 30
local RETRIES = 3

local function retry(operation: () -> any): (boolean, any)
	local result: any = nil
	for attempt = 1, RETRIES do
		local ok, value = pcall(operation)
		if ok then return true, value end
		result = value
		if attempt < RETRIES then task.wait(2 ^ (attempt - 1)) end
	end
	return false, result
end

local function dataStore(name: string): any?
	local ok, store = pcall(function() return DataStoreService:GetDataStore(name) end)
	return if ok then store else nil
end

local function releaseLease(store: any, key: string, lease: string): boolean
	if not store then return false end
	local ok = retry(function()
		return store:UpdateAsync(key, function(current)
			if type(current) == "table" and current.owner == lease then return nil end
			return current
		end)
	end)
	return ok
end

function Preferences.new()
	local prefix = if RunService:IsStudio() then "MayhemXStudio" else "MayhemX"
	local self: any = setmetatable({
		records = {}, notify = nil,
		store = dataStore(prefix .. "Profiles_v2"),
		legacyStore = dataStore(if RunService:IsStudio() then "MayhemXStudioPreferences_v1" else "MayhemXPreferences_v1"),
		lockStore = dataStore(prefix .. "SessionLocks_v1"),
		sessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false),
	}, Preferences)

	local function add(player: Player)
		if self.records[player] then return end
		local record: any = {
			profile = ProfileRules.default(Rules), loaded = false, persistent = false,
			dirty = false, saving = false, leaving = false, status = "LOADING",
			version = 0, connections = {}, lease = self.sessionId .. ":" .. HttpService:GenerateGUID(false),
		}
		self.records[player] = record
		task.spawn(function()
			if not self.store or not self.lockStore or not self.legacyStore then
				record.status = "SESSION ONLY / DATASTORE UNAVAILABLE"
				self:finishLoad(player, record, false)
				return
			end
			local lockOk, lock = retry(function()
				return self.lockStore:UpdateAsync("P_" .. player.UserId, function(current)
					local now = os.time()
					if type(current) == "table" and type(current.expiresAt) == "number" and current.expiresAt > now and current.owner ~= record.lease then
						return current
					end
					return { owner = record.lease, expiresAt = now + LOCK_TTL }
				end)
			end)
			if self.records[player] ~= record then
				if lockOk and type(lock) == "table" and lock.owner == record.lease then releaseLease(self.lockStore, "P_" .. player.UserId, record.lease) end
				return
			end
			if not lockOk then
				record.status = "SESSION ONLY / LOCK FAILED"
			elseif type(lock) ~= "table" or lock.owner ~= record.lease then
				record.status = "PROFILE IN USE"
			else
				record.locked = true
				local readOk, stored = retry(function() return self.store:GetAsync("P_" .. player.UserId) end)
				if self.records[player] ~= record then
					releaseLease(self.lockStore, "P_" .. player.UserId, record.lease)
					return
				end
				if readOk then
					if type(stored) == "table" and type(stored.version) == "number" and stored.version > ProfileRules.Version then
						record.status = "SESSION ONLY / NEWER PROFILE VERSION"
						self:release(player)
						self:finishLoad(player, record, false)
						return
					end
					local legacy: any = nil
					if stored == nil then
						local legacyOk, legacyValue = retry(function() return self.legacyStore:GetAsync("P_" .. player.UserId) end)
						if self.records[player] ~= record then
							releaseLease(self.lockStore, "P_" .. player.UserId, record.lease)
							return
						end
						if not legacyOk then
							record.status = "SESSION ONLY / MIGRATION READ FAILED"
							self:release(player)
							self:finishLoad(player, record, false)
							return
						end
						legacy = legacyValue
					end
					record.profile = ProfileRules.clean(stored, Rules, Visuals, legacy)
					record.loaded, record.persistent = true, true
					record.dirty = stored == nil and legacy ~= nil
					record.status = if record.dirty then "MIGRATION PENDING" else "READY"
				else
					record.status = "SESSION ONLY / LOAD FAILED"
					self:release(player)
				end
			end
			if self.records[player] ~= record then
				releaseLease(self.lockStore, "P_" .. player.UserId, record.lease)
				return
			end
			self:finishLoad(player, record, true)
		end)
	end

	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player: Player)
		local record = self.records[player]
		if not record then return end
		record.leaving = true
		self:flush(player)
		self:release(player)
		for _, connection in record.connections do connection:Disconnect() end
		self.records[player] = nil
	end)
	for _, player in Players:GetPlayers() do add(player) end
	task.spawn(function()
		while task.wait(AUTOSAVE_INTERVAL) do
			for player, record in self.records do
				if record.persistent and not record.saving then task.spawn(function() self:save(player) end) end
			end
		end
	end)
	game:BindToClose(function()
		local remaining = 0
		for player in self.records do
			remaining += 1
			task.spawn(function() self:flush(player); self:release(player); remaining -= 1 end)
		end
		local deadline = os.clock() + 20
		while remaining > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
	return self
end

function Preferences.finishLoad(self: any, player: Player, record: any, _keepStatus: boolean)
	if self.records[player] ~= record then return end
	record.loaded = true
	if record.status == "LOADING" then record.status = "SESSION ONLY / LOAD FAILED" end
	local stats = player:WaitForChild("leaderstats", 15)
	if stats and self.records[player] == record then
		for _, pair in { { "Kills", "kills" }, { "Wins", "wins" } } do
			local value = stats:WaitForChild(pair[1], 5) :: IntValue?
			if value then
				if record.persistent then value.Value = record.profile[pair[2]] else record.profile[pair[2]] = math.max(0, value.Value) end
				local previous = value.Value
				table.insert(record.connections, value:GetPropertyChangedSignal("Value"):Connect(function()
					if self.records[player] ~= record then return end
					local current = math.clamp(math.floor(value.Value), 0, ProfileRules.MaximumStat)
					if current > previous then
						local delta = current - previous
						record.profile.credits = math.clamp(record.profile.credits + delta * (pair[1] == "Kills" and 15 or 45), 0, ProfileRules.MaximumStat)
					elseif current < previous then
						value.Value = previous
						return
					end
					previous = current
					record.profile[pair[2]] = current
					self:changed(player, record)
				end))
			end
		end
	end
	if self.notify then self.notify(player) end
end

function Preferences.changed(self: any, player: Player, record: any)
	record.version += 1
	if record.persistent then
		record.dirty = true
		record.status = "SAVE PENDING"
	elseif record.loaded and record.status ~= "PROFILE IN USE" then
		record.status = "SESSION ONLY"
	end
	if self.notify then self.notify(player) end
end

function Preferences.canModify(self: any, player: Player): boolean
	local record = self.records[player]
	return record ~= nil and record.loaded and not record.leaving and record.status ~= "PROFILE IN USE"
end

function Preferences.snapshot(self: any, player: Player): any
	local record = self.records[player]
	if not record then return { preferences = table.clone(Rules.Defaults), version = 0, status = "LOADING", credits = 0, xp = 0, level = 1 } end
	local profile = record.profile
	local xp = profile.kills * 120 + profile.wins * 300
	return {
		preferences = table.clone(profile.preferences), version = record.version, status = record.status,
		credits = profile.credits, xp = xp, level = 1 + math.floor(xp / 300),
		kills = profile.kills, wins = profile.wins,
	}
end

function Preferences.update(self: any, player: Player, values: any): boolean
	local record = self.records[player]
		if not record or not record.loaded or record.leaving or record.status == "PROFILE IN USE" or type(values) ~= "table" then return false end
	record.profile.preferences = Rules.merge(record.profile.preferences, values)
	self:changed(player, record)
	return true
end

function Preferences.cosmetics(self: any, player: Player): any?
	local record = self.records[player]
	if not record or not record.loaded or record.leaving or record.status == "PROFILE IN USE" then return nil end
	local profile = record.profile
	return { skin = profile.skin, operative = profile.operative, owned = table.clone(profile.owned), dailyDay = profile.dailyDay }
end

function Preferences.updateCosmetics(self: any, player: Player, cosmetics: any)
	local record = self.records[player]
	if not record or not record.loaded or record.leaving or record.status == "PROFILE IN USE" then return false end
	local cleaned = ProfileRules.cosmetics(cosmetics, record.profile, Visuals)
	record.profile.skin, record.profile.operative = cleaned.skin, cleaned.operative
	record.profile.owned, record.profile.dailyDay = cleaned.owned, cleaned.dailyDay
	self:changed(player, record)
	return true
end

function Preferences.purchase(self: any, player: Player, skinId: string): boolean
	local record = self.records[player]
	if not record or not record.loaded or record.leaving or record.status == "PROFILE IN USE" or not ProfileRules.purchase(record.profile, skinId, Visuals) then return false end
	self:changed(player, record)
	return true
end

function Preferences.claimDaily(self: any, player: Player, day: number): boolean
	local record = self.records[player]
	if not record or not record.loaded or record.leaving or record.status == "PROFILE IN USE" or not ProfileRules.claimDaily(record.profile, day) then return false end
	self:changed(player, record)
	return true
end

function Preferences.save(self: any, player: Player)
	local record = self.records[player]
	if not record or not record.persistent or record.saving or not record.loaded then return end
	record.saving = true
	local lockOk, lock = retry(function()
		return self.lockStore:UpdateAsync("P_" .. player.UserId, function(current)
			if type(current) ~= "table" or current.owner ~= record.lease then return current end
			return { owner = record.lease, expiresAt = os.time() + LOCK_TTL }
		end)
	end)
	if not lockOk or type(lock) ~= "table" or lock.owner ~= record.lease then
		record.persistent, record.status, record.dirty, record.saving = false, "SESSION ONLY / LOCK LOST", false, false
		if self.notify then self.notify(player) end
		return
	end
	if record.dirty then
		local snapshot = table.clone(record.profile)
		snapshot.preferences = table.clone(record.profile.preferences)
		snapshot.owned = table.clone(record.profile.owned)
		snapshot.version = ProfileRules.Version
		local version = record.version
		local saveOk = retry(function()
			return self.store:UpdateAsync("P_" .. player.UserId, function() return snapshot end)
		end)
		record.dirty = not saveOk or record.version ~= version
		record.status = if not saveOk then "SAVE FAILED / RETRYING" elseif record.dirty then "SAVE PENDING" else "SAVED"
	end
	record.saving = false
	if self.records[player] == record and self.notify then self.notify(player) end
end

function Preferences.flush(self: any, player: Player)
	local record = self.records[player]
	if not record then return end
	local deadline = os.clock() + 8
	while record.saving and os.clock() < deadline do task.wait(0.1) end
	self:save(player)
end

function Preferences.release(self: any, player: Player)
	local record = self.records[player]
	if not record or not record.locked or (record.persistent and record.dirty) then return end
	local released = releaseLease(self.lockStore, "P_" .. player.UserId, record.lease)
	if released then record.locked = false end
end

return Preferences
