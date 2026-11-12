--!strict
local Art = require(script.Parent.Art)
local Environment = {}
local terrain = workspace.Terrain
local owned: { {frame: CFrame, size: Vector3} } = {}
local initialized = false
local profiles = {
	Collapse = { material = Enum.Material.Rock, radius = 420, water = false },
	Jungle = { material = Enum.Material.Grass, radius = 410, water = true },
	Solar = { material = Enum.Material.Sand, radius = 430, water = false },
	Frost = { material = Enum.Material.Snow, radius = 440, water = false },
	Skyline = { material = Enum.Material.Rock, radius = 530, water = false },
}

local function ball(position: Vector3, radius: number, material: Enum.Material)
	terrain:FillBall(position, radius, material)
	table.insert(owned, {frame = CFrame.new(position), size = Vector3.one * (radius * 2 + 8)})
end

function Environment.clear()
	for index, shape in owned do
		terrain:FillBlock(shape.frame, shape.size, Enum.Material.Air)
		if index % 4 == 0 then task.wait() end
	end
	table.clear(owned)
	terrain:SetAttribute("MayhemOwnedTerrain", nil)
end

function Environment.build(model: Model, id: string)
	local profile = profiles[id]
	assert(profile, "Unknown environment profile")
	if not initialized then
		local marker = terrain:GetAttribute("MayhemOwnedTerrain")
		if marker then
			for _, shape in game:GetService("HttpService"):JSONDecode(marker) do
				table.insert(owned, {frame = CFrame.new(table.unpack(shape.p)), size = Vector3.new(table.unpack(shape.size))})
			end
			Environment.clear()
		end
		assert(terrain:CountCells() == 0, "Existing Terrain requires an ownership review before generated surroundings")
		initialized = true
	end
	Environment.clear()
	local folder = Instance.new("Folder")
	folder.Name = "Horizon"
	folder.Parent = model
	local function landmark(name: string, position: Vector3, size: Vector3, yaw: number?, tilt: number?)
		local frame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), math.rad(tilt or 0))
		local asset = Art.place(folder, name, frame, size, 1)
		for _, part in asset:GetDescendants() do if part:IsA("BasePart") then part.CastShadow = false end end
		return asset
	end
	local groundSize = Vector3.new(1280, 8, 1280)
	local groundFrame = CFrame.new(0, if profile.water then -84 else -54, 0)
	terrain:FillBlock(groundFrame, groundSize, if profile.water then Enum.Material.Water else profile.material)
	table.insert(owned, {frame = groundFrame, size = groundSize + Vector3.one * 8})
	if profile.water then
		terrain.WaterColor, terrain.WaterTransparency = Color3.fromRGB(32, 109, 119), 0.35
		terrain.WaterWaveSize, terrain.WaterWaveSpeed = 0.15, 7
	end
	for index = 1, 8 do
		local angle = math.rad(index * 45 + 15)
		local radius = profile.radius + (index % 3) * 24
		local position = Vector3.new(math.cos(angle) * radius, -52 + (index % 4) * 9, math.sin(angle) * radius)
		local size = if id == "Solar" then 76 + index % 3 * 13 elseif id == "Frost" then 82 + index % 4 * 14 elseif id == "Skyline" then 48 else 64 + index % 3 * 10
		if id ~= "Jungle" then ball(position, size, profile.material) end
		if id ~= "Jungle" then
			local ridge = CFrame.new(position + Vector3.new(0, size * 0.15, 0)) * CFrame.Angles(0, angle + math.pi / 2, 0)
			local ridgeSize = Vector3.new(size * 2.7, size * 1.6, size * 1.5)
			terrain:FillWedge(ridge, ridgeSize, profile.material)
			table.insert(owned, {frame = CFrame.new(ridge.Position), size = Vector3.one * (ridgeSize.Magnitude + 8)})
		end
		if id == "Frost" then
			ball(position + Vector3.new(16, size * 0.48, -10), size * 0.55, Enum.Material.Glacier)
			if index % 2 == 0 then landmark("FrostCrown", position + Vector3.new(0, size, 0), Vector3.new(54, 100 + index * 3, 48), index * 23) end
		elseif id == "Jungle" then
			if index % 2 == 0 then
				landmark("RockShelf", position + Vector3.new(0, 15, 0), Vector3.new(180, 90, 160), index * 30)
				for _, offset in {-32, 32} do landmark("CanopyTree", position + Vector3.new(offset, 115 + index % 3 * 6, 10), Vector3.new(68, 110, 68), index * 38) end
			end
		elseif id == "Solar" then
			if index % 2 == 0 then landmark("SolarRelic", position + Vector3.new(0, 94, 0), Vector3.new(38, 110, 32), index * 30) end
		elseif id == "Collapse" then
			local name = if game.ReplicatedStorage.Mayhem.Art:FindFirstChild("RuinedTower") then "RuinedTower" else "SkySpire"
			landmark(name, position + Vector3.new(0, 82, 0), Vector3.new(45, 150 + index % 4 * 28, 46), index * 30, if index % 3 == 0 then 24 else -6)
			if index % 3 == 0 then
				local carrier = Instance.new("Part")
				carrier.Name, carrier.Size, carrier.Position = "DisasterSmoke", Vector3.new(16, 1, 16), position + Vector3.new(0, 120, 0)
				carrier.Anchored, carrier.Transparency, carrier.CanCollide, carrier.CanTouch, carrier.CanQuery = true, 1, false, false, false
				carrier:SetAttribute("MayhemDetail", true)
				carrier.Parent = folder
				local smoke = Instance.new("ParticleEmitter")
				smoke.Texture, smoke.Rate = "rbxasset://textures/particles/smoke_main.dds", 2
				smoke.Lifetime, smoke.Speed = NumberRange.new(7, 10), NumberRange.new(9, 14)
				smoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 32)})
				smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.75), NumberSequenceKeypoint.new(1, 1)})
				smoke.Color = ColorSequence.new(Color3.fromRGB(79, 77, 82))
				smoke:SetAttribute("MayhemAmbient", true)
				smoke.Parent = carrier
			end
		elseif id == "Skyline" then
			landmark("SkySpire", position + Vector3.new(0, 105, 0), Vector3.new(64, 220 + index % 4 * 40, 64), index * 30)
			landmark("SkySpire", position * Vector3.new(1.23, 1, 1.23) + Vector3.new(22, 175, -18), Vector3.new(74, 300 + index % 3 * 32, 74), index * 20)
		end
		if index % 3 == 0 then task.wait() end
	end
	local marker = {}
	for _, shape in owned do table.insert(marker, {p = {shape.frame.X, shape.frame.Y, shape.frame.Z}, size = {shape.size.X, shape.size.Y, shape.size.Z}}) end
	terrain:SetAttribute("MayhemOwnedTerrain", game:GetService("HttpService"):JSONEncode(marker))
	model:SetAttribute("EnvironmentRevision", 1)
end

return Environment
