--!strict
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
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
	local self: any = setmetatable({ preferences = preferences, root = root, spatial = spatial, groups = {}, context = "", loop = nil, ambience = nil, activeVoices = 0, lastCue = {}, fetch = {}, failures = {} }, Audio)
	for _, name in { "Music", "Ambience", "Effects", "UI" } do
		local group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = root
		self.groups[name] = group
	end
	task.spawn(function()
		local uris = {}
		for _, uri in Config.Builtins do table.insert(uris, uri); self.fetch[uri] = "PENDING" end
		for _, uri in Config.Uploads do if uri ~= "" then table.insert(uris, uri); self.fetch[uri] = "PENDING" end end
		local ok, message = pcall(function()
			ContentProvider:PreloadAsync(uris, function(uri: string, status: Enum.AssetFetchStatus)
				self.fetch[uri] = status.Name
				if status ~= Enum.AssetFetchStatus.Success then self.failures[uri] = true; warn("MAYHEM X audio unavailable: " .. uri .. " (" .. status.Name .. ")") end
			end)
		end)
		if not ok then warn("MAYHEM X audio preload did not finish: " .. tostring(message)) end
	end)
	return self
end

function Audio.status(self: any): string
	local configured, loaded, failed = 0, 0, 0
	for _, name in { "Lobby", "Collapse", "Jungle", "Solar", "Frost", "Skyline", "Combat", "Showdown", "Victory", "Defeat" } do if Config.Uploads[name] ~= "" then configured += 1 end end
	for _, uri in Config.Builtins do if self.fetch[uri] == "Success" then loaded += 1 elseif self.failures[uri] then failed += 1 end end
	return string.format("BUILT-INS %d/6 READY, %d FAILED / MUSIC %d/10 CONFIGURED", loaded, failed, configured)
end

function Audio.play(self: any, cue: string, position: Vector3?, emitterId: number?): boolean
	local fallback = Config.Cues[cue]
	local upload = Config.Uploads[cue]
	local uri = if upload and upload ~= "" then upload elseif fallback then Config.Builtins[fallback.builtin] else nil
	if not uri or self.failures[uri] or self.activeVoices >= Config.MaxVoices or self.preferences.muted then return false end
	local camera = workspace.CurrentCamera
	if position and camera and (position - camera.CFrame.Position).Magnitude > 160 then return false end
	local key = cue .. tostring(emitterId or 0)
	if os.clock() - (self.lastCue[key] or -math.huge) < (if cue == "Hover" then 0.09 else 0.04) then return false end
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
	sound.PlaybackSpeed = if upload and upload ~= "" then 1 elseif fallback then fallback.speed else 1
	sound.Volume = if fallback then fallback.volume else 0.3
	sound.SoundGroup = self.groups[if cue == "UI" or cue == "Hover" or cue == "Transition" or cue == "Notification" or cue == "Reward" or cue == "Purchase" then "UI" else "Effects"]
	sound.RollOffMinDistance, sound.RollOffMaxDistance = 6, 120
	sound.Parent = carrier or self.root
	sound.Loaded:Once(function() self.fetch[uri] = "Success" end)
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
	if self.loop then
		local old = self.loop
		TweenService:Create(old, TweenInfo.new(0.6), { Volume = 0 }):Play()
		Debris:AddItem(old, 0.65)
		self.loop = nil
	end
	local uri = Config.Uploads[cue]
	if not uri or uri == "" or self.failures[uri] then return end
	local sound = Instance.new("Sound")
	sound.Name = cue
	sound.SoundId = uri
	sound.Volume = 0
	sound.Looped = true
	sound.SoundGroup = self.groups.Music
	sound.Parent = self.root
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(0.8), { Volume = 0.6 }):Play()
	self.loop = sound
end

function Audio.update(self: any, menu: boolean, state: any)
	local mute = if self.preferences.muted then 0 else 1
	self.groups.Music.Volume = self.preferences.music * mute
	self.groups.Ambience.Volume = self.preferences.music * mute
	self.groups.Effects.Volume = self.preferences.sound * mute
	self.groups.UI.Volume = self.preferences.ui * mute
	local mapId = if state.map then state.map.id else "Collapse"
	local context = if state.map and state.map.duel then "Showdown" elseif state.phase == "Active" and state.alive then mapId elseif menu or state.phase ~= "Active" then "Lobby" else "Combat"
	if context == self.context then return end
	self.context = context
	self:music(context)
	if self.ambience then self.ambience:Destroy(); self.ambience = nil end
	if state.phase == "Active" and state.alive and Config.Ambience[mapId] then
		local sound = Instance.new("Sound")
		sound.Name = "MapAmbience"
		sound.SoundId = Config.Builtins[Config.Ambience[mapId]]
		sound.Volume = if mapId == "Jungle" then 0.025 else 0.035
		sound.PlaybackSpeed = if mapId == "Frost" then 0.65 elseif mapId == "Skyline" then 1.2 else 0.85
		sound.Looped = true
		sound.SoundGroup = self.groups.Ambience
		sound.Parent = self.root
		if not self.failures[sound.SoundId] then sound:Play() end
		self.ambience = sound
	end
end

return Audio
