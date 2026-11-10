--!strict
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local WorldPresentation = {}
WorldPresentation.__index = WorldPresentation

function WorldPresentation.new(preferences: any)
	local self: any = setmetatable({ preferences = preferences, rings = {}, details = {}, emitters = {}, applied = "" }, WorldPresentation)
	task.spawn(function()
		local world = workspace:WaitForChild("MayhemWorld", 30)
		if not world then return end
		local art = world:WaitForChild("ArtDirection", 10)
		if not art then return end
		local seen: { [Instance]: boolean } = {}
		local function cache(item: Instance)
			if seen[item] then return end
			seen[item] = true
			if item:IsA("Model") and item:GetAttribute("OrbitSpeed") then table.insert(self.rings, { model = item, base = item:GetPivot(), speed = item:GetAttribute("OrbitSpeed") }) end
			if item:IsA("BasePart") and item:GetAttribute("QualityTier") == 2 then table.insert(self.details, item) end
			self.applied = ""
		end
		world.DescendantAdded:Connect(cache)
		for _, item in world:GetDescendants() do cache(item) end
		for _, position in { Vector3.new(0, 42, 230), Vector3.new(0, 48, 0) } do
			local carrier = Instance.new("Part")
			carrier.Name = "LocalAtmospherics"
			carrier.Size = Vector3.new(20, 12, 20)
			carrier.Position = position
			carrier.Transparency = 1
			carrier.Anchored = true
			carrier.CanCollide = false
			carrier.CanTouch = false
			carrier.CanQuery = false
			carrier.Parent = art
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			emitter.Color = ColorSequence.new(Color3.fromRGB(149, 95, 255))
			emitter.Rate = 1.5
			emitter.Lifetime = NumberRange.new(3, 5)
			emitter.Speed = NumberRange.new(0.2, 0.5)
			emitter.Size = NumberSequence.new(0.08)
			emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
			emitter.LightEmission = 0.6
			emitter.Parent = carrier
			table.insert(self.emitters, emitter)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(149, 95, 255)
			light.Range = 20
			light.Brightness = 0.45
			light.Shadows = false
			light.Parent = carrier
		end
		self.applied = ""
	end)
	return self
end

function WorldPresentation.step(self: any)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local low = self.preferences.graphics == "Low" or (self.preferences.graphics == "Auto" and (UserInputService.TouchEnabled or camera.ViewportSize.X < 760))
	local key = tostring(low) .. tostring(self.preferences.reducedMotion)
	if key ~= self.applied then
		self.applied = key
		for _, item in self.details do if item.Parent then item.LocalTransparencyModifier = if low then 1 else 0 end end
		local bloom = Lighting:FindFirstChild("MayhemBloom") :: BloomEffect?
		if bloom then bloom.Enabled = not low end
		local atmosphere = Lighting:FindFirstChild("MayhemAtmosphere") :: Atmosphere?
		if atmosphere then atmosphere.Density = if low then 0.2 else 0.26 end
		for _, item in self.rings do item.model:PivotTo(item.base) end
	end
	local animated = 0
	for _, item in self.rings do
		if not low and not self.preferences.reducedMotion and animated < Visuals.Budgets.AnimatedRings
			and (item.base.Position - camera.CFrame.Position).Magnitude <= Visuals.Budgets.AnimationDistance then
			item.model:PivotTo(item.base * CFrame.Angles(0, os.clock() * item.speed, 0))
			animated += 1
		end
	end
	for _, emitter in self.emitters do
		local carrier = emitter.Parent :: BasePart
		emitter.Enabled = not low and not self.preferences.reducedEffects and (carrier.Position - camera.CFrame.Position).Magnitude < 100
	end
end

return WorldPresentation
