--!strict
local Art = require(script.Parent.Art)
local Geometry = require(script.Parent.Geometry)
local MapArt = {}
MapArt.Lighting = table.freeze({
	Collapse = { clock = 14.2, density = 0.055, ambient = {103, 126, 150}, sky = {146, 205, 235} },
	Jungle = { clock = 10.5, density = 0.07, ambient = {96, 130, 107}, sky = {133, 212, 223} },
	Solar = { clock = 15.6, density = 0.06, ambient = {130, 112, 89}, sky = {226, 202, 161} },
	Frost = { clock = 12.4, density = 0.055, ambient = {104, 136, 165}, sky = {172, 215, 241} },
	Skyline = { clock = 17.1, density = 0.055, ambient = {113, 122, 161}, sky = {166, 190, 229} },
})
local palettes = {
	Collapse = { deck = Color3.fromRGB(148, 174, 193), trim = Color3.fromRGB(35, 72, 104) },
	Jungle = { deck = Color3.fromRGB(116, 158, 91), trim = Color3.fromRGB(49, 96, 87) },
	Solar = { deck = Color3.fromRGB(196, 143, 82), trim = Color3.fromRGB(99, 66, 48) },
	Frost = { deck = Color3.fromRGB(165, 205, 224), trim = Color3.fromRGB(68, 117, 151) },
	Skyline = { deck = Color3.fromRGB(122, 160, 194), trim = Color3.fromRGB(32, 61, 96) },
}

function MapArt.coverVisible(part: BasePart, visible: boolean)
	local shell = part:FindFirstChild("PremiumShell")
	part.Transparency = if shell then 1 elseif visible then 0 else 1
	if shell then
		for _, child in shell:GetDescendants() do
			if child:IsA("BasePart") then child.Transparency = if visible then 0 else 1 end
		end
	end
end

local function cover(part: BasePart)
	local shell = Art.place(part, "FieldCover", part.CFrame, part.Size)
	shell.Name = "PremiumShell"
	part.Transparency = 1
end

local function light(parent: Instance, frame: CFrame, size: Vector3, color: Color3)
	return Geometry.part(parent, "RouteInlay", size, frame, color, Enum.Material.Metal)
end

function MapArt.dress(model: Model, id: string)
	if model:GetAttribute("ArtRevision") == 1 then return end
	local palette = palettes[id]
	assert(palette, "Missing art direction: " .. id)
	local decor = model:FindFirstChild("Decor")
	assert(decor, "Missing map decoration group")
	local art = Instance.new("Folder")
	art.Name = "PremiumArt"
	art.Parent = decor
	local function place(name: string, x: number, y: number, z: number, size: Vector3, yaw: number?, tier: number?)
		return Art.place(art, name, CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0), size, tier)
	end
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		if part.Name:match("^InsertionPad_") then
			part.Material, part.Color = Enum.Material.Metal, Color3.fromRGB(38, 138, 184)
			part.Shape = Enum.PartType.Cylinder
			part.Size = Vector3.new(0.12, 5, 5)
			part.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		elseif part.Parent.Name == "Solid" or part.Parent.Name == "Ice" or part.Parent.Name == "Duel" then
			if part.Size.Y <= 3 and part.Size.X >= 20 and part.Size.Z >= 20 then
				part.Color = palette.deck
				if id == "Collapse" or id == "Skyline" then
					part.Material, part.MaterialVariant, part.Color = Enum.Material.Metal, "MayhemDeck", Color3.new(1, 1, 1)
				elseif id == "Solar" then part.Material = Enum.Material.Sand end
			elseif part.Name:match("Cover_") or part.Name:match("^RoofVent_") or part.Name:match("^CryoBunker_") or part.Name:match("^RelayPod_") or part.Name:match("^ForgePress_") or part.Name:match("^VaultCrate_") then
				cover(part)
			end
		end
	end
	for _, part in model.Destructibles:GetChildren() do if part:IsA("BasePart") then cover(part) end end
	for _, part in decor:GetChildren() do
		if part:IsA("BasePart") and (part.Name:match("^EdgeLight") or part.Name:match("Halo") or part.Name:match("^CrystalCrown")) then
			part.Color, part.Material = palette.trim, Enum.Material.Metal
		end
	end
	if id == "Collapse" then
		for _, p in { Vector3.new(100, 10, 0), Vector3.new(-100, 10, 0), Vector3.new(0, 10, 100), Vector3.new(0, 10, -100) } do
			place("AerialBastion", p.X, p.Y, p.Z, Vector3.new(56, 17, 56))
		end
		place("AerialBastion", 0, 9, 0, Vector3.new(62, 18, 62), 45)
		place("ReactorTurbine", 0, 32, 0, Vector3.new(13, 21, 13), 45)
		for _, p in model.Solid:GetChildren() do
			if p:IsA("BasePart") and (p.Position - Vector3.new(0, 32, 0)).Magnitude < 0.5 then p.Transparency = 1 end
		end
		for _, p in decor:GetChildren() do if p:IsA("BasePart") and (p.Name:match("^TowerArmor") or p.Name:match("^EnergyCell")) then p:Destroy() end end
		for _, sign in { {100, "FORGE"}, {-100, "RELAY"} } do
			Geometry.sign(art, CFrame.new(sign[1], 31, -22), Vector3.new(10, 3, 0.2), sign[2], "COLLAPSE DISTRICT", Color3.fromRGB(87, 189, 229))
		end
	elseif id == "Jungle" then
		local roots = {}
		for _, p in decor:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name:match("^PalmTrunk") then table.insert(roots, p.Position - Vector3.new(0, 7, 0)) end
				if p.Name:match("^PalmTrunk") or p.Name:match("^PalmFrond") then p:Destroy() end
			end
		end
		for index, p in roots do
			local height = 23 + index % 4 * 2
			place("CanopyTree", p.X, p.Y + height / 2, p.Z, Vector3.new(18, height, 18), index * 47)
		end
		for _, x in {-65, 65} do for _, z in {-65, 65} do place("RockShelf", x, 6, z, Vector3.new(85, 24, 85), 45) end end
		for _, p in model.Solid:GetChildren() do if p:IsA("BasePart") and p.Name:match("^IslandBed") then p.Transparency = 1 end end
		place("ReactorTurbine", 0, 28, -10, Vector3.new(8, 11, 8), 0)
		for _, p in decor:GetChildren() do
			if p:IsA("BasePart") and p.Name:match("^Waterfall") then
				p.Color, p.Transparency = Color3.fromRGB(119, 218, 234), 0.5
				local spray = Instance.new("ParticleEmitter")
				spray.Name, spray.Texture = "CascadeSpray", "rbxasset://textures/particles/sparkles_main.dds"
				spray.Rate, spray.Lifetime, spray.Speed = 5, NumberRange.new(1, 1.5), NumberRange.new(8, 12)
				spray.EmissionDirection, spray.SpreadAngle = Enum.NormalId.Bottom, Vector2.new(6, 8)
				spray.Size, spray.Transparency = NumberSequence.new(0.15), NumberSequence.new(0.6)
				spray.Color = ColorSequence.new(Color3.fromRGB(205, 248, 255))
				spray.Parent = p
			elseif p:IsA("BasePart") and p.Name:match("^Lagoon") then
				p.Color, p.Transparency = Color3.fromRGB(45, 145, 183), 0.5
			end
		end
	elseif id == "Solar" then
		place("SolarRelic", 0, 36, 0, Vector3.new(24, 30, 12))
		for _, x in {-1, 1} do
			for _, z in {-1, 1} do
				place("SolarRelic", x * 114, 36, z * 86, Vector3.new(22, 44, 14), x * z * 25)
				place("SolarRelic", x * 154, 14, z * 120, Vector3.new(48, 80, 30), x * 34, 2)
			end
		end
		for _, p in model.Solid:GetChildren() do if p:IsA("BasePart") and (p.Name:find("Gate") or p.Name:find("Pillar")) then p.Transparency = 1 end end
	elseif id == "Frost" then
		for _, p in model.Solid:GetChildren() do
			if p:IsA("BasePart") and p.Name:match("^Crystal_") then
				p.Transparency = 1
				if p.Size.Y == 5 then place("FrostCrown", p.Position.X + 2.5, 26.5, p.Position.Z, Vector3.new(8, 11, 6), p.Position.X) end
			end
		end
		place("FrostCrown", 0, 50, 0, Vector3.new(14, 21, 14), 25)
		for _, x in {-1, 1} do
			place("FrostCrown", x * 155, 14, -30, Vector3.new(58, 94, 54), x * 22, 2)
			place("FrostCrown", x * 132, 2, 105, Vector3.new(46, 60, 36), x * 53, 2)
		end
	elseif id == "Skyline" then
		local towers = {}
		for _, p in decor:GetChildren() do
			if p:IsA("BasePart") and p.Name:match("^DistantTower") then table.insert(towers, {p.Position, p.Size}) end
			if p:IsA("BasePart") and (p.Name:match("^DistantTower") or p.Name:match("^DistantCrown") or p.Name:match("^DistantWindows") or p.Name:match("^FacadeWindow")) then p:Destroy() end
		end
		for index, tower in towers do place("SkySpire", tower[1].X, tower[1].Y, tower[1].Z, tower[2] * Vector3.new(1.4, 1, 1.4), index * 31, 2) end
		for _, p in model.Solid:GetChildren() do
			if p:IsA("BasePart") and p.Name:find("Building") then
				place("SkySpire", p.Position.X, p.Position.Y - 1.5, p.Position.Z, p.Size * Vector3.new(0.98, 0.94, 0.98))
				p.Transparency = 1
			end
		end
		local exchange = decor:FindFirstChild("ExchangeTower")
		if exchange and exchange:IsA("BasePart") then exchange.Transparency = 1 end
		place("ReactorTurbine", 0, 26, 0, Vector3.new(20, 21, 20), 45)
	end
	place("AerialBastion", 0, 17, -230, Vector3.new(67, 18, 67), 0)
	for _, x in {-35, 35} do place("ReactorTurbine", x, 36, -230, Vector3.new(5, 11, 5), 90) end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Size.Y <= 3 and part.Size.Z > 30 and part.Size.X < 20 and part.Parent ~= model.Duel then
			part.Color, part.Material = palette.trim, Enum.Material.DiamondPlate
		end
	end
	model:SetAttribute("ArtRevision", 1)
end

return MapArt
