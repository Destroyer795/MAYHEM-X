--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Config = require(ReplicatedStorage.Mayhem.Shared.Config)
local Effects = {}
Effects.__index = Effects
local purple = Color3.fromRGB(149, 95, 255)
local cyan = Color3.fromRGB(78, 229, 238)
local magenta = Color3.fromRGB(238, 87, 189)

local function part(parent: Instance, name: string, position: Vector3): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = Vector3.one * 0.1
	item.Position = position
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	item.Material = Enum.Material.Neon
	item.Transparency = 1
	item.Parent = parent
	return item
end

function Effects.new(preferences: any)
	local folder = Instance.new("Folder")
	folder.Name = "MayhemLocalEffects"
	folder.Parent = workspace
	local self: any = setmetatable({ folder = folder, preferences = preferences, watches = {} }, Effects)
	local function watch(player: Player)
		if self.watches[player] then return end
		local record: any = {}
		self.watches[player] = record
		local function characterAdded(character: Model)
			if record.death then record.death:Disconnect(); record.death = nil end
			task.spawn(function()
				local humanoid = character:WaitForChild("Humanoid", 8) :: Humanoid?
				if not humanoid or self.watches[player] ~= record or player.Character ~= character then return end
				record.death = humanoid.Died:Connect(function()
					local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if root then self:play("Eliminate", { at = root.Position, character = character }) end
				end)
			end)
		end
		record.added = player.CharacterAdded:Connect(characterAdded)
		if player.Character then characterAdded(player.Character) end
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player: Player)
		local record = self.watches[player]
		if record then record.added:Disconnect(); if record.death then record.death:Disconnect() end end
		self.watches[player] = nil
	end)
	for _, player in Players:GetPlayers() do watch(player) end
	return self
end

function Effects.reduced(self: any): boolean
	local camera = workspace.CurrentCamera
	return self.preferences.reducedEffects or self.preferences.graphics == "Low"
		or (self.preferences.graphics == "Auto" and (UserInputService.TouchEnabled or (camera ~= nil and camera.ViewportSize.X < 760)))
end

function Effects.root(self: any, name: string, position: Vector3, lifetime: number): Part?
	local reduced = self:reduced()
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - position).Magnitude > (if reduced then 200 else Visuals.Budgets.EffectDistance) then return nil end
	if #self.folder:GetChildren() >= (if reduced then 12 else Visuals.Budgets.EffectRoots) then return nil end
	local root = part(self.folder, name, position)
	Debris:AddItem(root, lifetime)
	return root
end

function Effects.burst(self: any, position: Vector3, color: Color3, count: number)
	local root = self:root("Sparks", position, 0.6)
	if not root then return end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.15, 0.4)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.13), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	emitter.LightEmission = 0.8
	emitter.Parent = root
	emitter:Emit(if self:reduced() then 2 else count)
end

function Effects.highlight(self: any, character: Model, color: Color3, duration: number)
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end
	local root = self:root("ShieldHighlight", rootPart.Position, duration + 0.1)
	if not root then return end
	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.94
	highlight.OutlineTransparency = 0.25
	highlight.Parent = root
	TweenService:Create(highlight, TweenInfo.new(duration), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
end

function Effects.wave(self: any, name: string, position: Vector3, color: Color3, radius: number)
	local active = 0
	for _, item in self.folder:GetChildren() do if item.Name == name then active += 1 end end
	if active >= 4 then return end
	local root = self:root(name, position, 0.5)
	if not root then return end
	root.Color = color
	root.Shape = Enum.PartType.Ball
	root.Size = Vector3.one
	root.Transparency = if self:reduced() then 1 else 0.84
	TweenService:Create(root, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * radius * 2, Transparency = 1 }):Play()
	local count = if self:reduced() then 4 else 10
	for index = 1, count do
		local angle = index * math.pi * 2 / count
		local segment = part(root, "WaveSegment", position)
		segment.Size = Vector3.new(1.6, 0.12, 0.2)
		segment.Color = color
		segment.Transparency = 0.15
		segment.CFrame = CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -1)
		TweenService:Create(segment, TweenInfo.new(0.38), { CFrame = CFrame.new(position) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius), Transparency = 1 }):Play()
	end
end

function Effects.play(self: any, kind: string, data: any)
	if kind == "Shot" then
		local offset = data.to - data.from
		local length = offset.Magnitude
		if length < 0.01 then return end
		local player = Players:GetPlayerByUserId(data.userId)
		local character = if player then player.Character else nil
		local color = if character then character:GetAttribute("MayhemAccent") or purple else purple
		local root = self:root("Tracer", data.from, 0.08)
		if root then
			local start = Instance.new("Attachment")
			start.Parent = root
			local finish = Instance.new("Attachment")
			finish.Position = offset
			finish.Parent = root
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = start, finish
			beam.Width0, beam.Width1 = 0.055, 0.02
			beam.Color = ColorSequence.new(color)
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Parent = root
		end
		if not self:reduced() then
			local weapon = if character then character:FindFirstChild("MayhemWeapon") else nil
			if player == Players.LocalPlayer and self.preferences.firstPerson and workspace.CurrentCamera then weapon = workspace.CurrentCamera:FindFirstChild("MayhemViewmodel") end
			local barrel = if weapon then weapon:FindFirstChild("Barrel") :: BasePart? else nil
			local flash = self:root("Muzzle", if barrel then barrel.Position else data.from, 0.1)
			if flash then
				flash.Color = color
				flash.Transparency = 0.1
				flash.Shape = Enum.PartType.Ball
				flash.Size = Vector3.one * 0.25
				TweenService:Create(flash, TweenInfo.new(0.08), { Size = Vector3.one * 0.05, Transparency = 1 }):Play()
			end
		end
		if length < Config.Rifle.Range - 0.2 then self:burst(data.to, color, 5) end
	elseif kind == "Slash" then
		local root = self:root("SwordSweep", data.at.Position, 0.3)
		if not root then return end
		root.CFrame = data.at * CFrame.new(-0.8, 0.5, -3) * CFrame.Angles(0, 0, -0.6)
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(-2, 0, 0)
		a.Parent = root
		local b = Instance.new("Attachment")
		b.Position = Vector3.new(2, 0, 0)
		b.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a, b
		trail.Lifetime = if self:reduced() then 0.08 else 0.16
		trail.Color = ColorSequence.new(cyan)
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		trail.FaceCamera = true
		trail.LightEmission = 0.8
		trail.Parent = root
		TweenService:Create(root, TweenInfo.new(0.18), { CFrame = data.at * CFrame.new(0.8, 1, -3) * CFrame.Angles(0, 0, 0.6) }):Play()
	elseif kind == "Pulse" then self:wave("Repulse", data.at, purple, Config.Ability.Radius)
	elseif kind == "MeleeHit" then self:burst(data.at, cyan, 8)
	elseif kind == "Protection" then if data.character then self:highlight(data.character, cyan, data.duration or 2) end
	elseif kind == "ShieldBreak" then
		if data.character then self:highlight(data.character, cyan, 0.3) end
		self:burst(data.at, cyan, 9)
	elseif kind == "Eliminate" then
		if data.character and not self:reduced() then self:highlight(data.character, magenta, 0.5) end
		self:wave("Elimination", data.at, magenta, 3)
		self:burst(data.at, magenta, 12)
	elseif kind == "Mutation" then self:wave("Mutation", data.at, magenta, 5)
	elseif kind == "Ultimate" then self:wave("Ultimate", data.at, magenta, 22)
	elseif kind == "Destruction" then self:burst(data.at, Color3.fromRGB(170, 188, 214), 16) end
end

return Effects
