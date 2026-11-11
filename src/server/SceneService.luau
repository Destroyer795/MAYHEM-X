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
	local lobby = world:WaitForChild("ObservationLobby")
	local previous = world:FindFirstChild("ArtDirection")
	if previous then previous:Destroy() end
	local art = Instance.new("Folder")
	art.Name = "ArtDirection"
	art.Parent = world
	local purple, cyan, magenta = color("Purple"), color("Cyan"), color("Magenta")
	for _, item in world:GetDescendants() do
		if item:IsA("BasePart") then
			if item.Material == Enum.Material.Neon then item.Color = cyan
			elseif item.Material == Enum.Material.Metal then item.Color = if item.Name == "LobbyDeck" then Color3.fromRGB(230, 240, 242) else Color3.fromRGB(157, 186, 205) end
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

	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(149, 174, 194)
	Lighting.OutdoorAmbient = Color3.fromRGB(162, 189, 207)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.65
	Lighting.ShadowSoftness = 0.4
	for _, name in { "MayhemAtmosphere", "MayhemBloom", "MayhemGrade" } do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "MayhemAtmosphere"
	atmosphere.Color = Color3.fromRGB(161, 215, 240)
	atmosphere.Decay = Color3.fromRGB(160, 179, 201)
	atmosphere.Density = 0.07
	atmosphere.Offset = 0.15
	atmosphere.Haze = 0.35
	atmosphere.Glare = 0
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "MayhemBloom"
	bloom.Intensity = 0.08
	bloom.Size = 18
	bloom.Threshold = 1.8
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "MayhemGrade"
	grade.Contrast = 0.04
	grade.Saturation = 0.08
	grade.TintColor = Color3.fromRGB(255, 253, 249)
	grade.Parent = Lighting
	local count = 0
	for _, item in world:GetDescendants() do if item:IsA("BasePart") then count += 1 end end
	world:SetAttribute("WorldPartCount", count)
	assert(count <= Visuals.Budgets.WorldParts, "World decoration exceeded its part budget")
end

return Scene
