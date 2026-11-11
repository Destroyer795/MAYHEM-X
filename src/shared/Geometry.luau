--!strict
local Geometry = {}

function Geometry.part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?, solid: boolean?, qualityTier: number?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = frame
	item.Color = color
	item.Material = material or Enum.Material.Metal
	item.Anchored = true
	item.CanCollide = solid == true
	item.CanTouch = false
	item.CanQuery = solid == true
	item.CastShadow = solid == true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item:SetAttribute("MayhemDetail", not solid)
	if qualityTier then item:SetAttribute("QualityTier", qualityTier) end
	item.Parent = parent
	return item
end

function Geometry.ring(parent: Instance, name: string, frame: CFrame, radius: number, count: number, color: Color3, orbit: number?): Model
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = frame
	if orbit then model:SetAttribute("OrbitSpeed", orbit) end
	model.Parent = parent
	for index = 1, count do
		local angle = (index - 1) * math.pi * 2 / count
		local transform = frame * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius)
		Geometry.part(model, "Arc", Vector3.new(radius * 2 * math.sin(math.pi / count) * 0.87, 0.14, 0.24), transform, color, Enum.Material.Neon, false, 2)
	end
	return model
end

function Geometry.sign(parent: Instance, frame: CFrame, size: Vector3, title: string, caption: string, accent: Color3): Part
	local item = Geometry.part(parent, "Display", size, frame, Color3.fromRGB(10, 15, 28))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.LightInfluence = 0
	surface.Parent = item
	for index, content in { title, caption } do
		local label = Instance.new("TextLabel")
		label.Name = if index == 1 then "Title" else "Caption"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(0.92, if index == 1 then 0.6 else 0.3)
		label.Position = UDim2.fromScale(0.04, if index == 1 then 0.04 else 0.65)
		label.Font = if index == 1 then Enum.Font.GothamBlack else Enum.Font.GothamMedium
		label.Text = content
		label.TextColor3 = if index == 1 then Color3.fromRGB(237, 242, 255) else accent
		label.TextScaled = true
		label.Parent = surface
	end
	return item
end

function Geometry.figure(parent: Instance, frame: CFrame, accent: Color3, shoulders: number?, victory: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "OperativeShowcase"
	model.WorldPivot = frame
	model.Parent = parent
	local metal = Color3.fromRGB(38, 47, 68)
	local ceramic = Color3.fromRGB(215, 232, 239)
	local width = shoulders or 1
	Geometry.part(model, "Chest", Vector3.new(2.1, 2.4, 1.1), frame, metal)
	Geometry.part(model, "Helmet", Vector3.new(1.35, 1.2, 1.25), frame * CFrame.new(0, 1.85, 0), metal)
	Geometry.part(model, "HelmetArmor", Vector3.new(1.45, 0.5, 1.3), frame * CFrame.new(0, 2.2, 0), ceramic)
	Geometry.part(model, "ChestArmor", Vector3.new(1.75, 1.5, 0.12), frame * CFrame.new(0, 0.25, -0.62), ceramic)
	Geometry.part(model, "Belt", Vector3.new(2.15, 0.3, 1.2), frame * CFrame.new(0, -1, 0), accent)
	Geometry.part(model, "Visor", Vector3.new(1.25, 0.2, 0.08), frame * CFrame.new(0, 1.9, -0.66), accent, Enum.Material.Neon)
	Geometry.part(model, "Circuit", Vector3.new(0.22, 1.5, 0.1), frame * CFrame.new(0, 0.1, -0.6), accent, Enum.Material.Neon)
	for _, side in { -1, 1 } do
		local arm = frame * CFrame.new(side * (1.2 + width * 0.2), if victory then 0.65 else -0.15, 0) * CFrame.Angles(0, 0, if victory then -side * 0.8 else side * 0.05)
		Geometry.part(model, "Arm", Vector3.new(0.7 * width, 2.3, 0.85), arm, metal)
		Geometry.part(model, "Shoulder", Vector3.new(0.9 * width, 0.45, 1), arm * CFrame.new(0, 0.95, 0), accent)
		Geometry.part(model, "ForearmPlate", Vector3.new(0.74 * width, 0.8, 0.14), arm * CFrame.new(0, -0.55, -0.47), ceramic)
		Geometry.part(model, "Leg", Vector3.new(0.85, 2.35, 0.95), frame * CFrame.new(side * 0.55, -2.35, 0), metal)
		Geometry.part(model, "ShinArmor", Vector3.new(0.75, 1, 0.14), frame * CFrame.new(side * 0.55, -2.6, -0.54), ceramic)
		Geometry.part(model, "Boot", Vector3.new(0.9, 0.35, 1.25), frame * CFrame.new(side * 0.55, -3.4, -0.15), ceramic)
	end
	return model
end

return Geometry
