--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Scene = {}
local function color(name: string): Color3
	return Color3.fromRGB(table.unpack(Visuals.Palette[name]))
end
local function detail(parent: Instance, name: string, size: Vector3, frame: CFrame, accent: Color3, neon: boolean?)
	return Geometry.part(parent, name, size, frame, accent, if neon then Enum.Material.Neon else Enum.Material.Metal)
end

local function station(parent: Instance, position: Vector3, title: string, subtitle: string, screen: string, accent: Color3)
	local frame = CFrame.lookAt(position, Vector3.new(0, position.Y, 232))
	detail(parent, "ConsolePlinth", Vector3.new(7, 0.5, 4), frame * CFrame.new(0, -2, 0), color("Metal"))
	local display = Geometry.sign(parent, frame, Vector3.new(7, 3, 0.5), title, subtitle, accent)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open " .. title
	prompt.ObjectText = "MAYHEM X"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("MayhemScreen", screen)
	prompt.Parent = display
	detail(parent, "ConsoleLight", Vector3.new(7, 0.12, 0.2), frame * CFrame.new(0, -1.6, -0.4), accent, true)
end

function Scene.decorate()
	local world = workspace:WaitForChild("MayhemWorld")
	local arena = world:WaitForChild("TheCollapse")
	local lobby = world:WaitForChild("ObservationLobby")
	local previous = world:FindFirstChild("ArtDirection")
	if previous then previous:Destroy() end
	local art = Instance.new("Folder")
	art.Name = "ArtDirection"
	art.Parent = world
	local purple, cyan, magenta = color("Purple"), color("Cyan"), color("Magenta")
	for _, item in world:GetDescendants() do
		if item:IsA("BasePart") then
			if item.Material == Enum.Material.Neon then item.Color = purple
			elseif item.Material == Enum.Material.Metal then item.Color = if item.Name == "FloatingDeck" or item.Name == "CentralDeck" then color("Panel") else color("Navy") end
		end
	end

	local hub = Instance.new("Folder")
	hub.Name = "HubArchitecture"
	hub.Parent = art
	for _, z in { 211, 231, 251 } do
		for _, side in { -1, 1 } do
			local frame = CFrame.new(side * 36, 42, z)
			detail(hub, "PortalRib", Vector3.new(2.4, 19, 2.2), frame, color("Metal"))
			detail(hub, "RibInlay", Vector3.new(0.18, 16, 0.15), frame * CFrame.new(-side * 1.3, 0, -1.15), purple, true)
		end
		detail(hub, "CanopyBeam", Vector3.new(74, 1.5, 2), CFrame.new(0, 51, z), color("Metal"))
	end
	Geometry.sign(hub, CFrame.new(0, 46, 207) * CFrame.Angles(0, math.pi, 0), Vector3.new(33, 6, 0.6), "MAYHEM X", "ENTER THE CHAOS. BECOME THE LEGEND.", purple)
	for _, side in { -1, 1 } do
		detail(hub, "FloorCircuit", Vector3.new(0.16, 0.08, 35), CFrame.new(side * 9, 32.08, 231), cyan, true)
	end
	Geometry.ring(hub, "HubOrrery", CFrame.new(0, 49, 230), 10, 20, purple, 0.2)
	Geometry.ring(hub, "HubOrreryInner", CFrame.new(0, 48.5, 230), 6.8, 16, cyan, -0.3)
	local pedestal = Geometry.part(hub, "ShowcaseDais", Vector3.new(10, 1.4, 8), CFrame.new(-27, 32.7, 240), color("Panel"), Enum.Material.Metal, true)
	Geometry.figure(hub, pedestal.CFrame * CFrame.new(0, 4.8, 0), purple, 1.15)
	Geometry.ring(hub, "ShowcaseLight", CFrame.new(-27, 33.5, 240), 4.2, 12, purple)
	station(hub, Vector3.new(0, 36, 213), "DEPLOY", "LAST SIGNAL / SOLO SURVIVAL", "Matchmaking", purple)
	station(hub, Vector3.new(28, 36, 218), "COLLECTION", "OPERATIVES / WEAPON STYLES", "Inventory", cyan)
	station(hub, Vector3.new(28, 36, 244), "STYLE LAB", "COMPLIMENTARY SESSION STYLES", "Shop", magenta)
	station(hub, Vector3.new(-28, 36, 218), "DAILY CACHE", "SESSION COSMETIC TRIAL", "Daily", purple)
	station(hub, Vector3.new(0, 36, 249), "SYSTEMS", "AUDIO / GRAPHICS / CAMERA", "Settings", cyan)

	local tower = Instance.new("Folder")
	tower.Name = "ReactorArchitecture"
	tower.Parent = art
	for index = 0, 3 do
		local frame = CFrame.new(0, 32, 0) * CFrame.Angles(0, index * math.pi / 2, 0)
		detail(tower, "ReactorHousing", Vector3.new(8, 20, 0.6), frame * CFrame.new(0, 0, -5.8), color("Metal"))
		for _, side in { -1, 1 } do
			detail(tower, "EnergyCell", Vector3.new(0.5, 16, 0.2), frame * CFrame.new(side * 2.5, 0, -6.2), if index % 2 == 0 then purple else cyan, true)
		end
	end
	Geometry.ring(tower, "ReactorHalo", CFrame.new(0, 55, 0), 10.5, 24, purple, 0.15)
	Geometry.ring(tower, "CrownHalo", CFrame.new(0, 52, 0), 7, 16, cyan)
	detail(tower, "SignalSpire", Vector3.new(2, 13, 2), CFrame.new(0, 55, 0), color("Metal"))
	detail(tower, "SpireEmitter", Vector3.new(0.4, 10, 0.4), CFrame.new(0, 55, -1.1), purple, true)

	local accents = { purple, cyan, magenta, color("Red") }
	local centers = { Vector3.new(100, 20, 0), Vector3.new(0, 20, 100), Vector3.new(-100, 20, 0), Vector3.new(0, 20, -100) }
	local subtitles = { "VECTOR / SIGNAL ARRAYS", "ION / POWER CELLS", "ORBIT / OBSERVATORY", "NULL / BLACK ARCHIVE" }
	for index, center in centers do
		local zone = Instance.new("Folder")
		zone.Name = "District" .. index
		zone.Parent = art
		local accent = accents[index]
		local facing = CFrame.lookAt(center, Vector3.new(0, center.Y, 0))
		Geometry.sign(zone, facing * CFrame.new(0, 10, 22), Vector3.new(18, 3.4, 0.4), "0" .. index .. " / " .. ({ "VECTOR", "ION", "ORBIT", "NULL" })[index], subtitles[index], accent)
		for column = -1, 1 do
			local frame = facing * CFrame.new(column * 8, 6, 23)
			detail(zone, "DistrictMachine", Vector3.new(3, if index == 4 then 10 else 6, 3), frame, color("Metal"))
			detail(zone, "MachineCircuit", Vector3.new(0.16, 4, 3.1), frame, accent, true)
			if index == 1 then detail(zone, "Antenna", Vector3.new(6, 0.2, 0.4), frame * CFrame.new(0, 5, 0) * CFrame.Angles(0, column, 0), accent)
			elseif index == 2 then Geometry.ring(zone, "CellCollar", frame * CFrame.new(0, 3.4, 0), 2, 8, accent)
			elseif index == 3 then Geometry.ring(zone, "ReceiverDish", frame * CFrame.new(0, 4, 0) * CFrame.Angles(0.6, 0, 0), 3, 10, accent) end
		end
		for _, x in { -18, 18 } do
			for _, z in { -18, 18 } do
				Geometry.ring(zone, "InsertionBeacon", CFrame.new(center + Vector3.new(x, 1.72, z)), 3.4, 8, accent)
			end
		end
	end
	for _, item in arena:GetDescendants() do
		if item:IsA("BasePart") and item.Name == "Bridge" then
			local length = item.Size.Z
			for _, side in { -1, 1 } do
				detail(art, "BridgeConduit", Vector3.new(0.2, 0.15, length - 4), item.CFrame * CFrame.new(side * (item.Size.X / 2 - 1.2), 1.06, 0), cyan, true)
				for segment = 1, 3 do
					detail(art, "BridgeTruss", Vector3.new(0.5, 3.5, length / 3 - 2), item.CFrame * CFrame.new(side * (item.Size.X / 2), -2.4, (segment - 2) * length / 3), color("Metal"))
				end
			end
		elseif item:IsA("BasePart") and (item.Name == "TacticalCover" or item.Name == "CrownCover") then
			detail(art, "CoverArmor", Vector3.new(item.Size.X - 0.5, 0.3, 0.12), item.CFrame * CFrame.new(0, item.Size.Y / 2 - 0.4, -item.Size.Z / 2 - 0.08), cyan, true)
		end
	end

	Lighting.ClockTime = 0.6
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(40, 37, 65)
	Lighting.OutdoorAmbient = Color3.fromRGB(53, 61, 85)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.65
	Lighting.ShadowSoftness = 0.4
	for _, name in { "MayhemAtmosphere", "MayhemBloom", "MayhemGrade" } do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "MayhemAtmosphere"
	atmosphere.Color = Color3.fromRGB(133, 146, 187)
	atmosphere.Decay = Color3.fromRGB(40, 34, 67)
	atmosphere.Density = 0.26
	atmosphere.Offset = 0.15
	atmosphere.Haze = 1.2
	atmosphere.Glare = 0.04
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "MayhemBloom"
	bloom.Intensity = 0.18
	bloom.Size = 18
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "MayhemGrade"
	grade.Contrast = 0.12
	grade.Saturation = -0.08
	grade.TintColor = Color3.fromRGB(239, 242, 255)
	grade.Parent = Lighting
	local count = 0
	for _, item in world:GetDescendants() do if item:IsA("BasePart") then count += 1 end end
	world:SetAttribute("WorldPartCount", count)
	assert(count <= Visuals.Budgets.WorldParts, "World decoration exceeded its part budget")
end

return Scene
