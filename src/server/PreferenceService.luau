--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Rules = require(game:GetService("ReplicatedStorage").Mayhem.Shared.PreferenceRules)
local Preferences = {}
Preferences.__index = Preferences

function Preferences.new()
	local self: any = setmetatable({ records = {}, notify = nil, store = if RunService:IsStudio() then nil else DataStoreService:GetDataStore("MayhemXPreferences_v1") }, Preferences)
	local function add(player: Player)
		local record: any = { preferences = table.clone(Rules.Defaults), version = 0, dirty = false, saving = false, loadReady = not self.store, spent = 0, bonus = 0, connections = {}, status = if self.store then "LOADING" else "SESSION ONLY / STUDIO" }
		self.records[player] = record
		task.spawn(function()
			if self.store then
				local ok, data = pcall(function() return self.store:GetAsync("P_" .. player.UserId) end)
				if self.records[player] ~= record then return end
				if ok then
					if record.version == 0 then record.preferences = Rules.merge(Rules.Defaults, data) end
					record.loadReady = true
					record.status = "READY"
				else record.status = "SESSION ONLY / LOAD FAILED" end
				if self.notify then self.notify(player) end
			end
			local stats = player:WaitForChild("leaderstats", 15)
			if stats and self.records[player] == record then
				for _, name in { "Kills", "Wins" } do
					local value = stats:WaitForChild(name, 5) :: IntValue?
					if value then table.insert(record.connections, value:GetPropertyChangedSignal("Value"):Connect(function() if self.notify then self.notify(player) end end)) end
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player: Player)
		local record = self.records[player]
		if not record then return end
		record.leaving = true
		self:flush(player)
		for _, connection in record.connections do connection:Disconnect() end
		self.records[player] = nil
	end)
	for _, player in Players:GetPlayers() do add(player) end
	task.spawn(function()
		while task.wait(30) do for player, record in self.records do if record.dirty and not record.saving then task.spawn(function() self:save(player) end) end end end
	end)
	game:BindToClose(function()
		local remaining = 0
		for player, record in self.records do record.leaving = true; remaining += 1; task.spawn(function() self:flush(player); remaining -= 1 end) end
		local deadline = os.clock() + 20
		while remaining > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
	return self
end

function Preferences.snapshot(self: any, player: Player): any
	local record = self.records[player]
	if not record then return { preferences = table.clone(Rules.Defaults), version = 0, status = "LOADING", credits = 0, xp = 0, level = 1 } end
	local stats = player:FindFirstChild("leaderstats")
	local kills = if stats and stats:FindFirstChild("Kills") then stats.Kills.Value else 0
	local wins = if stats and stats:FindFirstChild("Wins") then stats.Wins.Value else 0
	local xp = kills * 120 + wins * 300
	return { preferences = table.clone(record.preferences), version = record.version, status = record.status, credits = Rules.wallet(kills, wins, record.bonus, record.spent), xp = xp, level = 1 + math.floor(xp / 300) }
end

function Preferences.update(self: any, player: Player, values: any): boolean
	local record = self.records[player]
	if not record or record.leaving or record.status == "LOADING" or type(values) ~= "table" then return false end
	record.preferences = Rules.merge(record.preferences, values)
	record.version += 1
	record.dirty = self.store ~= nil and record.loadReady
	record.status = if not self.store then "SESSION ONLY / STUDIO" elseif record.loadReady then "SAVE PENDING" else "SESSION ONLY / LOAD FAILED"
	return true
end

function Preferences.spend(self: any, player: Player, cost: number): boolean
	local record = self.records[player]
	if not record or self:snapshot(player).credits < cost then return false end
	record.spent += cost
	return true
end

function Preferences.bonus(self: any, player: Player, value: number)
	local record = self.records[player]
	if record then record.bonus += value end
end

function Preferences.save(self: any, player: Player)
	local record = self.records[player]
	if not record or not record.loadReady or not record.dirty or record.saving or not self.store then return end
	record.saving = true
	local version = record.version
	local values = table.clone(record.preferences)
	local ok = pcall(function() self.store:UpdateAsync("P_" .. player.UserId, function() return values end) end)
	record.saving = false
	record.dirty = not ok or record.version ~= version
	record.status = if not ok then "SESSION ONLY / SAVE FAILED" elseif record.dirty then "SAVE PENDING" else "SAVED"
	if self.records[player] == record and self.notify then self.notify(player) end
end

function Preferences.flush(self: any, player: Player)
	local record = self.records[player]
	if not record then return end
	local deadline = os.clock() + 8
	while record.saving and os.clock() < deadline do task.wait(0.1) end
	self:save(player)
end

return Preferences
