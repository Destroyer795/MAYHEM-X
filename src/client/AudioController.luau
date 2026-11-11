--!strict
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Mayhem.Shared.AudioConfig)
local Audio = {}
Audio.__index = Audio

function Audio.new(preferences: any)
	local root = Instance.new("Folder")
	root.Name = "MayhemAudio"
	root.Parent = SoundService
	local spatial = Instance.new("Folder")
	spatial.Name = "MayhemSpatialAudio"
	spatial.Parent = workspace
	local self: any = setmetatable({ preferences = preferences, root = root, spatial = spatial, groups = {}, context = "", loop = nil, ambience = nil, environmental = {}, activeVoices = 0, lastCue = {}, cueKeys = 0, fetch = {}, failures = {} }, Audio)
	for _, name in { "Music", "Ambience", "Effects", "UI" } do
		local group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = root
		self.groups[name] = group
	end
	self:volumes()
	task.spawn(function()
		local uris, seen = {}, {}
		for _, uri in Config.Builtins do table.insert(uris, uri); seen[uri] = true end
		for name, uri in Config.Uploads do
			if uri ~= "" and not table.find(Config.Music, name) and not seen[uri] then table.insert(uris, uri); seen[uri] = true end
		end
		self:preload(uris)
	end)
	return self
end

function Audio.preload(self: any, uris: { string })
	local probes, statuses = {}, {}
	for _, uri in uris do
		self.fetch[uri] = "PENDING"
		local probe = Instance.new("Sound")
		probe.Name, probe.SoundId, probe.Volume = "AudioLoadProbe", uri, 0
		probe.Parent = self.root
		table.insert(probes, probe)
	end
	local ok, message = pcall(function()
		ContentProvider:PreloadAsync(probes, function(uri: string, status: Enum.AssetFetchStatus) statuses[uri] = status.Name end)
	end)
	for _, probe in probes do
		local uri = probe.SoundId
		self.fetch[uri] = if probe.IsLoaded then "Success" else statuses[uri] or "Failure"
		self.failures[uri] = if probe.IsLoaded then nil else true
		if self.failures[uri] then warn("MAYHEM X audio unavailable: " .. uri .. " (" .. self.fetch[uri] .. ")") end
		probe:Destroy()
	end
	if not ok then warn("MAYHEM X audio preload did not finish: " .. tostring(message)) end
end

function Audio.volumes(self: any)
	local mute = if self.preferences.muted then 0 else 1
	self.groups.Music.Volume = self.preferences.music * mute
	self.groups.Ambience.Volume = self.preferences.music * mute
	self.groups.Effects.Volume = self.preferences.sound * mute
	self.groups.UI.Volume = self.preferences.ui * mute
end

function Audio.status(self: any): string
	local configured, loaded, failed, musicReady, musicFailed, effectsReady, effectsFailed = 0, 0, 0, 0, 0, 0, 0
	for _, name in Config.Music do
		local uri = Config.Uploads[name]
		if uri ~= "" then
			configured += 1
			if self.fetch[uri] == "Success" then musicReady += 1 elseif self.failures[uri] then musicFailed += 1 end
		end
	end
	for _, uri in Config.Builtins do if self.fetch[uri] == "Success" then loaded += 1 elseif self.failures[uri] then failed += 1 end end
	for name, uri in Config.Uploads do
		if not table.find(Config.Music, name) then
			if self.fetch[uri] == "Success" then effectsReady += 1 elseif self.failures[uri] then effectsFailed += 1 end
		end
	end
	self.root:SetAttribute("BuiltinsReady", loaded)
	self.root:SetAttribute("BuiltinsFailed", failed)
	self.root:SetAttribute("MusicConfigured", configured)
	self.root:SetAttribute("MusicReady", musicReady)
	self.root:SetAttribute("MusicFailed", musicFailed)
	self.root:SetAttribute("EffectsReady", effectsReady)
	self.root:SetAttribute("EffectsFailed", effectsFailed)
	return string.format("SFX %d/19 READY, %d FAILED / FALLBACK %d/6 / MUSIC %d/10 CONFIGURED, %d READY, %d FAILED", effectsReady, effectsFailed, loaded, configured, musicReady, musicFailed)
end

function Audio.play(self: any, cue: string, position: Vector3?, emitterId: number?): boolean
	local camera = workspace.CurrentCamera
	if position and camera and (position - camera.CFrame.Position).Magnitude > 160 then return false end
	if cue == "Shot" or cue == "Shield" or cue == "MeleeHit" or cue == "Repulse" then self.combatUntil = os.clock() + 8 end
	local uri, speed, volume = Config.effect(cue, self.failures, self.fetch)
	local isUI = Config.isUI(cue)
	local budget = if isUI then Config.MaxVoices else Config.MaxVoices - Config.UIReserve
	if not uri or self.activeVoices >= budget or self.preferences.muted or (if isUI then self.preferences.ui else self.preferences.sound) <= 0 then return false end
	local key = cue .. tostring(emitterId or 0)
	if os.clock() - (self.lastCue[key] or -math.huge) < (if cue == "Hover" then 0.09 else 0.04) then return false end
	if not self.lastCue[key] then self.cueKeys += 1 end
	if self.cueKeys > 512 then self.lastCue = {}; self.cueKeys = 1 end
	self.lastCue[key] = os.clock()
	local carrier: Part? = nil
	if position then
		carrier = Instance.new("Part")
		carrier.Name = "AudioEmitter"
		carrier.Size = Vector3.one * 0.1
		carrier.Position = position
		carrier.Anchored, carrier.CanCollide, carrier.CanQuery, carrier.CanTouch = true, false, false, false
		carrier.Transparency = 1
		carrier.Parent = self.spatial
	end
	local sound = Instance.new("Sound")
	sound.Name = cue
	sound.SoundId = uri
	sound.PlaybackSpeed = speed
	sound.Volume = volume
	sound.SoundGroup = self.groups[if isUI then "UI" else "Effects"]
	sound.RollOffMinDistance, sound.RollOffMaxDistance = 6, 120
	sound.Parent = carrier or self.root
	sound.Loaded:Once(function() self.fetch[uri] = "Success"; self.failures[uri] = nil end)
	self.activeVoices += 1
	local closed = false
	local function cleanup()
		if closed then return end
		closed = true
		self.activeVoices -= 1
		if carrier then carrier:Destroy() else sound:Destroy() end
	end
	sound.Ended:Once(cleanup)
	sound:Play()
	task.delay(6, cleanup)
	return true
end

function Audio.music(self: any, cue: string)
	self.musicSerial = (self.musicSerial or 0) + 1
	local serial = self.musicSerial
	if self.fading then self.fading:Destroy(); self.fading = nil end
	if self.loop then
		local old = self.loop
		self.fading = old
		TweenService:Create(old, TweenInfo.new(0.6), { Volume = 0 }):Play()
		Debris:AddItem(old, 0.65)
		self.loop = nil
		task.delay(0.65, function() if self.fading == old then self.fading = nil end end)
	end
	local uri = Config.Uploads[cue]
	if not uri or uri == "" or self.failures[uri] then return end
	task.spawn(function()
		if self.fetch[uri] ~= "Success" then self:preload({ uri }) end
		if self.musicSerial ~= serial or self.failures[uri] then return end
		local sound = Instance.new("Sound")
		sound.Name = cue
		sound.SoundId = uri
		sound.Volume = 0
		sound.Looped = cue ~= "Victory" and cue ~= "Defeat"
		sound.SoundGroup = self.groups.Music
		sound.Parent = self.root
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(0.8), { Volume = 0.6 }):Play()
		self.loop = sound
		if not sound.Looped then sound.Ended:Once(function() if self.loop == sound then self.loop = nil end; sound:Destroy() end) end
	end)
end

function Audio.update(self: any, state: any)
	self:volumes()
	local mapId = if state.map then state.map.id else "Collapse"
	if self.roundId ~= state.roundId then self.combatUntil = 0 end
	local context = Config.context(state, Players.LocalPlayer.UserId, os.clock() < (self.combatUntil or 0))
	if context ~= self.context or self.roundId ~= state.roundId then self.context = context; self.roundId = state.roundId; self:music(context) end
	local scene = mapId .. tostring(state.map and state.map.generation) .. state.phase .. tostring(state.alive) .. tostring(state.map and state.map.duel)
	if scene == self.scene then return end
	self.scene = scene
	if self.ambience then self.ambience:Destroy(); self.ambience = nil end
	for _, sound in self.environmental do sound:Destroy() end
	self.environmental = {}
	if context == "Lobby" or (state.phase == "Active" and state.alive and Config.Ambience[mapId]) then
		local sound = Instance.new("Sound")
		sound.Name = "MapAmbience"
		sound.SoundId = Config.Builtins[if context == "Lobby" then "Wind" else Config.Ambience[mapId]]
		sound.Volume = if context == "Lobby" then 0.012 elseif mapId == "Jungle" then 0.018 else 0.035
		sound.PlaybackSpeed = if mapId == "Frost" then 0.65 elseif mapId == "Skyline" then 1.2 else 0.85
		sound.Looped = true
		sound.SoundGroup = self.groups.Ambience
		sound.Parent = self.root
		if not self.failures[sound.SoundId] then sound:Play() end
		self.ambience = sound
	end
	if mapId == "Jungle" and state.alive and state.phase == "Active" and not (state.map and state.map.duel) then
		local world = workspace:FindFirstChild("MayhemWorld")
		local arena = if world then world:FindFirstChild("ActiveArena") else nil
		if arena then
			for _, part in arena:GetDescendants() do
				if part:IsA("BasePart") and part.Name:match("^Waterfall_") then
					local sound = Instance.new("Sound")
					sound.Name, sound.SoundId, sound.Looped = "Cascade", Config.Builtins.Water, true
					sound.RollOffMinDistance, sound.RollOffMaxDistance, sound.Volume = 10, 85, 0.09
					sound.SoundGroup, sound.Parent = self.groups.Ambience, part
					if not self.failures[sound.SoundId] then sound:Play() end
					table.insert(self.environmental, sound)
				end
			end
		end
	end
end

return Audio
