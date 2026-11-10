--!strict
local Workspace = game:GetService("Workspace")

local Arena = {}
local slate = Color3.fromRGB(25, 32, 46)
local panel = Color3.fromRGB(44, 55, 72)
local cyan = Color3.fromRGB(72, 225, 230)
local amber = Color3.fromRGB(255, 153, 70)
local white = Color3.fromRGB(211, 228, 239)
local root: Folder
local arenaModel: Model
local spawnFrames: { CFrame } = {}

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = frame
	item.Color = color
	item.Material = material or Enum.Material.Metal
	item.Anchored = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function label(parent: BasePart, text: string, face: Enum.NormalId, size: number)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 35
	surface.Parent = parent
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = white
	title.TextSize = size
	title.Text = text
	title.Parent = surface
end

local function trim(parent: Instance, size: Vector3, position: Vector3, color: Color3)
	local item = part(parent, "LightStrip", size, CFrame.new(position), color, Enum.Material.Neon)
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
end

local function bridge(parent: Instance, start: Vector3, finish: Vector3, width: number)
	local length = (finish - start).Magnitude
	local frame = CFrame.lookAt((start + finish) / 2, finish)
	part(parent, "Bridge", Vector3.new(width, 2, length), frame, slate)
	for _, sign in { -1, 1 } do
		part(parent, "BridgeRail", Vector3.new(0.8, 2, length), frame * CFrame.new(sign * (width / 2 - 0.4), 1.8, 0), panel)
		local light = part(parent, "BridgeEdge", Vector3.new(0.12, 0.12, length), frame * CFrame.new(sign * (width / 2 - 0.4), 2.85, 0), cyan, Enum.Material.Neon)
		light.CanQuery = false
		light.CanCollide = false
	end
end

function Arena.build()
	local previous = Workspace:FindFirstChild("MayhemWorld")
	if previous then
		previous:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "MayhemWorld"
	root.Parent = Workspace
	arenaModel = Instance.new("Model")
	arenaModel.Name = "TheCollapse"
	arenaModel.Parent = root
	spawnFrames = {}

	part(arenaModel, "CentralDeck", Vector3.new(60, 3, 60), CFrame.new(0, 20, 0), panel)
	part(arenaModel, "ReactorCore", Vector3.new(11, 21, 11), CFrame.new(0, 32, 0), slate)
	part(arenaModel, "TowerCrown", Vector3.new(21, 2, 42), CFrame.new(-10.5, 46, 0), panel)
	part(arenaModel, "CrownReturn", Vector3.new(21, 2, 21), CFrame.new(10.5, 46, 10.5), panel)
	for _, x in { -4, 4 } do
		trim(arenaModel, Vector3.new(0.35, 18, 0.35), Vector3.new(x, 32, -5.6), cyan)
		trim(arenaModel, Vector3.new(0.35, 18, 0.35), Vector3.new(x, 32, 5.6), cyan)
	end
	for index = 0, 31 do
		local angle = index * math.pi * 2 / 32
		local frame = CFrame.new(math.cos(angle) * 16, 22 + index * 0.75, math.sin(angle) * 16) * CFrame.Angles(0, -angle, 0)
		part(arenaModel, "SpiralStep", Vector3.new(7, 0.9, 4), frame, slate)
	end
	for _, position in { Vector3.new(-17, 48, -17), Vector3.new(17, 48, 17) } do
		part(arenaModel, "CrownCover", Vector3.new(6, 3, 4), CFrame.new(position), slate)
	end
	local title = part(arenaModel, "TowerSign", Vector3.new(22, 4, 0.8), CFrame.new(0, 41, -6), slate)
	label(title, "THE COLLAPSE", Enum.NormalId.Front, 54)

	local centers = { Vector3.new(100, 20, 0), Vector3.new(0, 20, 100), Vector3.new(-100, 20, 0), Vector3.new(0, 20, -100) }
	local names = { "01 // VECTOR", "02 // ION", "03 // ORBIT", "04 // NULL" }
	local markers = Instance.new("Folder")
	markers.Name = "WeaponSpawnPoints"
	markers.Parent = arenaModel
	for index, center in centers do
		local zone = Instance.new("Model")
		zone.Name = names[index]
		zone.Parent = arenaModel
		local accent = if index % 2 == 0 then amber else cyan
		part(zone, "FloatingDeck", Vector3.new(54, 3, 54), CFrame.new(center), panel)
		part(zone, "Underside", Vector3.new(36, 7, 36), CFrame.new(center - Vector3.new(0, 5, 0)), slate)
		for _, offset in { -24, 24 } do
			trim(zone, Vector3.new(46, 0.15, 0.3), center + Vector3.new(0, 1.6, offset), accent)
			trim(zone, Vector3.new(0.3, 0.15, 46), center + Vector3.new(offset, 1.6, 0), accent)
		end
		for coverIndex = 1, 4 do
			local angle = coverIndex * math.pi / 2 + index * 0.3
			local offset = Vector3.new(math.cos(angle) * 10, 4, math.sin(angle) * 10)
			part(zone, "TacticalCover", Vector3.new(9, 5, 4), CFrame.new(center + offset) * CFrame.Angles(0, angle, 0), slate)
		end
		local sign = part(zone, "ZoneSign", Vector3.new(17, 3, 1), CFrame.new(center + Vector3.new(0, 6, 22)), slate)
		label(sign, names[index], Enum.NormalId.Front, 38)
		for _, x in { -18, 18 } do
			for _, z in { -18, 18 } do
				local position = center + Vector3.new(x, 6, z)
				table.insert(spawnFrames, CFrame.lookAt(position, Vector3.new(0, position.Y, 0)))
				part(zone, "InsertionPad", Vector3.new(5, 0.15, 5), CFrame.new(center + Vector3.new(x, 1.6, z)), accent, Enum.Material.Neon)
			end
		end
		local marker = Instance.new("CFrameValue")
		marker.Name = "Zone" .. index
		marker.Value = CFrame.new(center + Vector3.new(0, 3, 0))
		marker.Parent = markers
		local horizontal = Vector3.new(center.X, 0, center.Z).Unit
		bridge(arenaModel, horizontal * 30 + Vector3.new(0, 20, 0), center, 14)
	end
	for index = 1, 4 do
		bridge(arenaModel, centers[index], centers[index % 4 + 1], 9)
	end

	part(arenaModel, "SecretVaultFloor", Vector3.new(56, 2, 56), CFrame.new(0, 7, 0), slate)
	for _, x in { -27, 27 } do
		part(arenaModel, "VaultWall", Vector3.new(2, 9, 44), CFrame.new(x, 12, 2), panel)
	end
	trim(arenaModel, Vector3.new(40, 0.2, 1), Vector3.new(0, 8.1, -20), amber)
	part(arenaModel, "VaultEntranceLanding", Vector3.new(16, 2, 13), CFrame.new(33, 7, -20), slate)
	for index = 0, 14 do
		part(arenaModel, "VaultStair", Vector3.new(8, 1, 3.3), CFrame.new(34, 21 - index * 0.9, 23 - index * 3), panel)
	end

	local duel = Instance.new("Model")
	duel.Name = "FinalDuelDeck"
	duel.Parent = root
	part(duel, "DuelFloor", Vector3.new(58, 3, 58), CFrame.new(0, 45, -230), slate)
	for _, x in { -27, 27 } do
		trim(duel, Vector3.new(0.3, 0.2, 54), Vector3.new(x, 46.6, -230), amber)
	end

	local lobby = Instance.new("Model")
	lobby.Name = "ObservationLobby"
	lobby.Parent = root
	part(lobby, "LobbyDeck", Vector3.new(80, 4, 50), CFrame.new(0, 30, 230), slate)
	for _, x in { -39, 39 } do
		part(lobby, "LobbyRail", Vector3.new(2, 6, 50), CFrame.new(x, 35, 230), panel)
	end
	part(lobby, "RearWall", Vector3.new(80, 12, 2), CFrame.new(0, 37, 254), panel)
	local glass = part(lobby, "ObservationGlass", Vector3.new(80, 5, 0.5), CFrame.new(0, 34, 205), cyan, Enum.Material.Glass)
	glass.Transparency = 0.6
	local brand = part(lobby, "BrandPanel", Vector3.new(46, 8, 1), CFrame.new(0, 40, 252.5), slate)
	label(brand, "MAYHEM X\nENTER THE CHAOS. BECOME THE LEGEND.", Enum.NormalId.Front, 45)
	trim(lobby, Vector3.new(68, 0.2, 1), Vector3.new(0, 32.1, 210), cyan)
	return spawnFrames
end

function Arena.lobbyFrame(userId: number): CFrame
	return CFrame.lookAt(Vector3.new((math.abs(userId) % 7 - 3) * 6, 36, 232), Vector3.new(0, 36, 200))
end

function Arena.frames(): { CFrame }
	return spawnFrames
end

return Arena
