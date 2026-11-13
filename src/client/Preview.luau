--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Catalog = require(ReplicatedStorage.Mayhem.Shared.MapCatalog)
local Art = require(ReplicatedStorage.Mayhem.Shared.Art)
local Animations = require(ReplicatedStorage.Mayhem.Shared.AnimationConfig)
local Players = game:GetService("Players")
local Preview = {}
Preview.__index = Preview

function Preview.new(parent: Instance)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "OperativePreview"
	viewport.BackgroundColor3 = Color3.fromRGB(214, 235, 245)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(177, 197, 211)
	viewport.LightColor = Color3.fromRGB(255, 250, 238)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = parent
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
	camera.FieldOfView = 42
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return setmetatable({ frame = viewport, camera = camera, key = "", world = nil }, Preview)
end

function Preview.show(self: any, kind: string, operative: string, skin: string, weapon: number?)
	local character = Players.LocalPlayer.Character
	local appearance = if character then character:FindFirstChild("MayhemStyle") else nil
	local showcase = if kind == "operative" then ReplicatedStorage.Mayhem.Art:FindFirstChild("OperatorShowcase") else nil
	if showcase and not showcase:IsA("Model") then showcase = nil end
	if kind ~= "weapon" and not showcase and (not character or not appearance or not character:FindFirstChild("Head") or not (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))) then return end
	local key = kind .. operative .. skin .. tostring(weapon)
	if self.key == key and self.character == character and self.appearance == appearance and self.showcase == showcase then return end
	self.key, self.character, self.appearance, self.showcase = key, character, appearance, showcase
	self.lastViewportSize = nil
	if self.animationTrack then
		self.animationTrack:Stop(0.1)
		self.animationTrack:Destroy()
		self.animationTrack = nil
	end
	if self.world then self.world:Destroy() end
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	self.frame.BackgroundColor3 = Color3.fromRGB(205, 222, 232)
	self.camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
	local accent = Color3.fromRGB(table.unpack((Visuals.skin(skin) or Visuals.Skins[1]).color))
	if kind == "weapon" then
		self.subject = Art.weapon(world, weapon or 1, CFrame.identity, accent)
		self.direction = if weapon == 2 then Vector3.new(0.5, 0.2, -1).Unit else Vector3.new(1, 0.25, 0.2).Unit
	elseif showcase or character then
		local source = (showcase or character) :: Model
		local before = source.Archivable
		source.Archivable = true
		local rig = source:Clone()
		source.Archivable = before
		for _, child in rig:GetDescendants() do
			if child:IsA("LuaSourceContainer") or (not showcase and child:IsA("Accessory")) or child.Name == "MayhemWeapon" then child:Destroy()
			elseif child:IsA("BasePart") then
				child.Anchored, child.CanCollide, child.CanTouch, child.CanQuery = true, false, false, false
				child.LocalTransparencyModifier = 0
			end
		end
		rig:PivotTo(CFrame.identity)
		rig.Parent = world
		if showcase then
			local chest = rig:FindFirstChild("UpperTorso")
			if chest and chest:IsA("BasePart") then
				local profileAccent = if operative == "Spectre" then Color3.fromRGB(89, 220, 239) elseif operative == "Relay" then Color3.fromRGB(255, 190, 88) else accent
				local inlay = Instance.new("Part")
				inlay.Name = "MayhemPreviewInlay"
				inlay.Size = Vector3.new(0.22, 0.055, 0.035)
				inlay.CFrame = chest.CFrame * CFrame.new(0, chest.Size.Y * 0.24, -chest.Size.Z * 0.55)
				inlay.Color, inlay.Material = profileAccent, Enum.Material.Neon
				inlay.Anchored, inlay.CanCollide, inlay.CanTouch, inlay.CanQuery = true, false, false, false
				inlay.CastShadow, inlay.Parent = false, rig
			end
		else
			Art.outfit(rig, accent, (Visuals.operative(operative) or Visuals.Operatives[1]).shoulders)
		end
		for _, part in rig:GetDescendants() do if part:IsA("BasePart") then part.Anchored = true end end
		if kind == "victory" then
			for _, joint in rig:GetDescendants() do
				if joint:IsA("Motor6D") and joint.Name == "RightShoulder" then joint.Transform = CFrame.Angles(-0.5, 0, 0.7) end
			end
		end
		self.subject = rig
		self.direction = Vector3.new(0.35, 0.15, -1).Unit
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			if showcase then
				local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
				animator.Parent = humanoid
				local animation = Instance.new("Animation")
				animation.AnimationId = Animations.OperatorShowcaseIdle
				local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
				animation:Destroy()
				if ok and track then
					track.Looped = true
					track.Priority = Enum.AnimationPriority.Idle
					track:Play(0.2)
					self.animationTrack = track
				end
			end
		end
		local pedestalY = -3.25
		if kind ~= "weapon" then
			local bounds, size = self.subject:GetBoundingBox()
			pedestalY = bounds.Position.Y - size.Y * 0.5 - 0.45
		end
		Art.place(world, "AerialBastion", CFrame.new(0, pedestalY, 0), Vector3.new(6, 0.9, 6))
	else self.key = "" end
	if self.subject then
		local bounds, size = self.subject:GetBoundingBox()
		self.focus, self.bounds = bounds.Position, size
		self.camera.FieldOfView = if kind == "weapon" then 34 else 40
		self:step(true)
	end
end

function Preview.map(self: any, id: string)
	if self.key == "map:" .. id then return end
	local definition: any = nil
	for _, entry in Catalog do if entry.id == id then definition = entry; break end end
	if not definition then return end
	self:hide()
	self.key = "map:" .. id
	self.lastViewportSize = nil
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	for _, entry in definition.preview do
		Geometry.part(world, "Terrain", Vector3.new(table.unpack(entry.size)) * 0.04,
			CFrame.new(Vector3.new(table.unpack(entry.p)) * 0.04) * CFrame.Angles(0, math.rad(entry.yaw), 0) * CFrame.Angles(entry.pitch, 0, 0), Color3.fromRGB(table.unpack(entry.color)))
	end
	local function prop(name: string, x: number, y: number, z: number, size: Vector3)
		Art.place(world, name, CFrame.new(x, y, z), size)
	end
	if id == "Collapse" then
		prop("ReactorTurbine", 0, 1.4, 0, Vector3.new(0.6, 1, 0.6))
		for _, p in {Vector3.new(4, 0.2, 0), Vector3.new(-4, 0.2, 0), Vector3.new(0, 0.2, 4), Vector3.new(0, 0.2, -4)} do prop("AerialBastion", p.X, p.Y, p.Z, Vector3.new(2.3, 0.7, 2.3)) end
	elseif id == "Jungle" then
		for _, x in {-2.6, 2.6} do for _, z in {-2.6, 2.6} do
			prop("RockShelf", x, 0.2, z, Vector3.new(3.4, 1, 3.4))
			prop("CanopyTree", x, 1.8, z, Vector3.new(1.2, 1.8, 1.2))
		end end
	elseif id == "Solar" then
		prop("SolarRelic", 0, 1.6, 0, Vector3.new(1, 1.8, 0.6))
		for _, x in {-4.5, 4.5} do prop("SolarRelic", x, 1.4, -3.4, Vector3.new(0.9, 1.8, 0.6)) end
	elseif id == "Frost" then
		for _, x in {-3, 0, 3} do prop("FrostCrown", x, 1.9, 0, Vector3.new(0.7, 1.6, 0.6)) end
	elseif id == "Skyline" then
		for _, x in {-3.3, 3.3} do for _, z in {-3.1, 3.1} do prop("SkySpire", x, 0.7, z, Vector3.new(1.5, 2.6, 1.5)) end end
	end
	self.frame.BackgroundColor3 = Color3.fromRGB(table.unpack(definition.lighting.sky))
	self.camera.CFrame = CFrame.lookAt(Vector3.new(11, 10, -13), Vector3.new(0, 0.7, 0))
end

function Preview.step(self: any, reducedMotion: boolean)
	if not self.world then return end
	local viewportSize = self.frame.AbsoluteSize
	if viewportSize ~= self.lastViewportSize and viewportSize.X > 0 and viewportSize.Y > 0 then
		local previous = self.camera
		self.camera = previous:Clone()
		self.camera.Parent = self.frame
		self.frame.CurrentCamera = self.camera
		previous:Destroy()
		self.lastViewportSize = viewportSize
	end
	if not self.bounds or self.key:sub(1, 4) == "map:" then return end
	local angle = (self.yaw or 0) + (if reducedMotion then 0 else math.sin(os.clock() * 0.4) * 0.12)
	local direction = CFrame.Angles(0, angle, 0):VectorToWorldSpace(self.direction)
	local rotation = CFrame.lookAt(Vector3.zero, -direction)
	local extent = Vector3.zero
	for _, x in {-0.5, 0.5} do for _, y in {-0.5, 0.5} do for _, z in {-0.5, 0.5} do
		local v = rotation:VectorToObjectSpace(self.bounds * Vector3.new(x, y, z))
		extent = Vector3.new(math.max(extent.X, math.abs(v.X)), math.max(extent.Y, math.abs(v.Y)), math.max(extent.Z, math.abs(v.Z)))
	end end end
	local aspect = math.max(0.3, self.frame.AbsoluteSize.X / math.max(1, self.frame.AbsoluteSize.Y))
	local tangent = math.tan(math.rad(self.camera.FieldOfView / 2))
	local distance = math.max(extent.Y / tangent, extent.X / (tangent * aspect)) * 1.12 + extent.Z
	self.camera.CFrame = CFrame.lookAt(self.focus + direction * distance, self.focus)
end

function Preview.hide(self: any)
	if self.animationTrack then
		self.animationTrack:Stop(0.1)
		self.animationTrack:Destroy()
		self.animationTrack = nil
	end
	if self.world then self.world:Destroy(); self.world = nil end
	self.key = ""
	self.subject, self.bounds = nil, nil
	self.lastViewportSize = nil
end

return Preview
