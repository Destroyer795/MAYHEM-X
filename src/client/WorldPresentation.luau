--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local shared = game:GetService("ReplicatedStorage").Mayhem.Shared
local Catalog = require(shared.MapCatalog)
local Visuals = require(shared.Visuals)
local WorldPresentation = {}
WorldPresentation.__index = WorldPresentation
local lobbyLight = { clock = 13.8, density = 0.055, ambient = { 164, 188, 207 }, sky = { 157, 211, 242 } }

local function carrier(parent: Instance, name: string): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = true, false, false, false, false
	item.Transparency = 1
	item.Parent = parent
	return item
end

function WorldPresentation.new(preferences: any)
	local folder = Instance.new("Folder")
	folder.Name = "MayhemLocalWorld"
	folder.Parent = workspace
	local self: any = setmetatable({ preferences = preferences, rings = {}, details = {}, applied = "", folder = folder, zone = {} }, WorldPresentation)
	local weather = carrier(folder, "Weather")
	weather.Size = Vector3.new(48, 1, 48)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "MapWeather"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Lifetime = NumberRange.new(3, 5)
	emitter.Speed = NumberRange.new(2, 3)
	emitter.Size = NumberSequence.new(0.1)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(1, 1) })
	emitter.Enabled = false
	emitter.Parent = weather
	self.weather, self.emitter = weather, emitter
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.Name = "MayhemSky"
		sky.CelestialBodiesShown = true
		sky.Parent = Lighting
	end
	task.spawn(function()
		local world = workspace:WaitForChild("MayhemWorld", 30)
		if not world then return end
		local function cache(item: Instance)
			if item:IsA("Model") and item:GetAttribute("OrbitSpeed") then table.insert(self.rings, { model = item, base = item:GetPivot(), speed = item:GetAttribute("OrbitSpeed") }) end
			if item:IsA("BasePart") and item:GetAttribute("QualityTier") == 2 then table.insert(self.details, item) end
			self.applied = ""
		end
		world.DescendantAdded:Connect(cache)
		for _, item in world:GetDescendants() do cache(item) end
	end)
	return self
end

function WorldPresentation.zoneRing(self: any, count: number)
	if #self.zone == count then return end
	for _, item in self.zone do item:Destroy() end
	self.zone = {}
	for _ = 1, count do
		local segment = carrier(self.folder, "SafeBoundary")
		segment.Material = Enum.Material.Neon
		table.insert(self.zone, segment)
	end
end

function WorldPresentation.step(self: any, state: any)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local low = self.preferences.graphics == "Low" or (self.preferences.graphics == "Auto" and (UserInputService.TouchEnabled or camera.ViewportSize.X < 760))
	local map = state.map
	local world = workspace:FindFirstChild("MayhemWorld")
	local art = if world then world:FindFirstChild("ArtDirection") else nil
	local telemetry = if art then art:FindFirstChild("HubTelemetry", true) else nil
	local caption = if telemetry then telemetry:FindFirstChild("Caption", true) :: TextLabel? else nil
	if caption then caption.Text = state.queueCount .. " QUEUED / " .. #Players:GetPlayers() .. " ONLINE / " .. string.upper(state.phase) end
	local inArena = state.alive and state.phase ~= "Results"
	local profile, mapId = lobbyLight, "Lobby"
	if map and inArena then
		for _, entry in Catalog do if entry.id == map.id then profile, mapId = entry.lighting, entry.id; break end end
	end
	local key = mapId .. tostring(low) .. tostring(self.preferences.reducedMotion)
	if key ~= self.applied then
		self.applied = key
		Lighting.ClockTime = profile.clock
		Lighting.Brightness = 2.5
		Lighting.ExposureCompensation = 0.1
		Lighting.Ambient = Color3.fromRGB(table.unpack(profile.ambient))
		Lighting.OutdoorAmbient = Lighting.Ambient
		Lighting.ColorShift_Top = Color3.fromRGB(255, 242, 218)
		Lighting.FogStart, Lighting.FogEnd = 600, 1800
		Lighting.FogColor = Color3.fromRGB(table.unpack(profile.sky))
		local bloom = Lighting:FindFirstChild("MayhemBloom") :: BloomEffect?
		if bloom then bloom.Enabled = not low; bloom.Intensity = 0.12; bloom.Size = 16; bloom.Threshold = 1.6 end
		local atmosphere = Lighting:FindFirstChild("MayhemAtmosphere") :: Atmosphere?
		if atmosphere then
			atmosphere.Density = if low then profile.density * 0.65 else profile.density
			atmosphere.Color = Color3.fromRGB(table.unpack(profile.sky))
			atmosphere.Decay = Lighting.Ambient
			atmosphere.Haze, atmosphere.Glare = 0.4, 0.05
		end
		for index = #self.details, 1, -1 do
			local item = self.details[index]
			if item.Parent then item.LocalTransparencyModifier = if low then 1 else 0 else table.remove(self.details, index) end
		end
		for index = #self.rings, 1, -1 do
			local item = self.rings[index]
			if item.model.Parent then item.model:PivotTo(item.base) else table.remove(self.rings, index) end
		end
		self:zoneRing(if low then 16 else 32)
		self.emitter:Clear()
		self.emitter.Color = ColorSequence.new(if mapId == "Frost" then Color3.new(1, 1, 1) elseif mapId == "Solar" then Color3.fromRGB(246, 193, 98) else Color3.fromRGB(78, 219, 177))
		self.emitter.Rate = if mapId == "Frost" then 9 elseif mapId == "Jungle" then 2 elseif mapId == "Solar" then 3 else 0
	end
	local animated = 0
	for _, item in self.rings do
		if item.model.Parent and not low and not self.preferences.reducedMotion and animated < Visuals.Budgets.AnimatedRings
			and (item.base.Position - camera.CFrame.Position).Magnitude <= Visuals.Budgets.AnimationDistance then
			item.model:PivotTo(item.base * CFrame.Angles(0, os.clock() * item.speed, 0))
			animated += 1
		end
	end
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	self.emitter.Enabled = inArena and root ~= nil and not low and not self.preferences.reducedEffects and not self.preferences.reducedMotion
	if root then self.weather.Position = root.Position + Vector3.new(0, 24, 0) end
	local showZone = inArena and state.phase == "Active" and root ~= nil and map ~= nil
	for index, item in self.zone do
		item.Transparency = if showZone then 0.25 else 1
		if showZone then
			local radius = map.safeRadius
			local angle = (index - 0.5) * math.pi * 2 / #self.zone
			local offset = (root :: BasePart).Position - map.center
			local outside = Vector3.new(offset.X, 0, offset.Z).Magnitude > radius
			item.Color = if outside then Color3.fromRGB(255, 171, 68) else Color3.fromRGB(22, 177, 200)
			item.Size = Vector3.new(2 * radius * math.sin(math.pi / #self.zone), 0.15, 0.3)
			item.CFrame = CFrame.new(map.center.X, (root :: BasePart).Position.Y - 2.8, map.center.Z) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, radius)
		end
	end
end

return WorldPresentation
