--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Art = require(ReplicatedStorage.Mayhem.Shared.Art)
local Scene = {}
local function color(name: string): Color3
	return Color3.fromRGB(table.unpack(Visuals.Palette[name]))
end
local function detail(parent: Instance, name: string, size: Vector3, frame: CFrame, accent: Color3, neon: boolean?)
	return Geometry.part(parent, name, size, frame, accent, if neon then Enum.Material.Neon else Enum.Material.Metal)
end

local function station(parent: Instance, position: Vector3, title: string, subtitle: string, screen: string, accent: Color3)
	local frame = CFrame.lookAt(position, Vector3.new(0, position.Y, 232))
	detail(parent, "ConsolePlinth", Vector3.new(7, 0.5, 4), frame * CFrame.new(0, -2, 0), Color3.fromRGB(53,55,59))
	detail(parent, "ConsoleSupport", Vector3.new(1.3, 2, 1.1), frame * CFrame.new(0, -1.1, 0.3), Color3.fromRGB(83,84,87))
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
	local stone = Color3.fromRGB(222,215,202)
	local ember = Color3.fromRGB(173,74,77)
	local graphite = Color3.fromRGB(45,46,49)
	for _, item in lobby:GetChildren() do
		if item:IsA("BasePart") then
			item.Color,item.Material = graphite,Enum.Material.Metal
			if item.Name=="RearWall" then
				item.Transparency=1
				item.CFrame=CFrame.new(0,37,260.5)
				item:SetAttribute("MayhemCollisionProxy",true)
			elseif item.Name=="LobbyRail" then
				item.Size=Vector3.new(2,6,56)
				item.CFrame=CFrame.new(item.Position.X,35,233)
			end
			if item.Name=="ObservationGlass" then item.Color,item.Material,item.Transparency=Color3.fromRGB(175,190,203),Enum.Material.Glass,0.86 end
			if item.Name=="BrandPanel" then
				item.Transparency=1
				for _,gui in item:GetChildren() do if gui:IsA("SurfaceGui") then gui.Enabled=false end end
			end
		end
	end
	local hub=Instance.new("Folder")
	hub.Name,hub.Parent="HubArchitecture",art
	Art.place(hub,"SignalHangar",CFrame.new(0,48,230),Vector3.new(84,34,62))
	local deck=lobby:FindFirstChild("LobbyDeck")
	if deck and deck:IsA("BasePart") then
		deck.MaterialVariant,deck.Color="MayhemDeck",Color3.fromRGB(125,130,136)
		deck.Size,deck.CFrame=Vector3.new(80,4,56),CFrame.new(0,30,233)
	end
	Geometry.sign(hub,CFrame.new(0,46,251),Vector3.new(25,5,0.4),"MAYHEM X","FIELD OPERATIONS / ARMORY 07",stone)
	for _,x in {-19,19} do
		detail(hub,"AisleMarker",Vector3.new(0.08,0.03,29),CFrame.new(x,32.03,229),stone)
	end
	for index,id in {"Vector","Needle","Mantis","Breaker","Rift","Talon","Maul"} do
		local Arsenal=require(ReplicatedStorage.Mayhem.Shared.Arsenal)
		local definition=Arsenal.Items[id]
		local x=-28+(index-1)*9.3
		local frame=CFrame.new(x,37.2,249.5)
		detail(hub,"WeaponDock",Vector3.new(6.8,0.3,3.6),CFrame.new(x,33.1,249),graphite)
		local weapon=Art.weapon(hub,definition.slot,frame*CFrame.Angles(0,math.rad(80),if definition.slot==1 then math.rad(-10) else math.rad(18)),stone,id)
		weapon.Name="Display"..id
		Geometry.sign(hub,CFrame.new(x,34,247.5),Vector3.new(6.7,1.15,0.15),definition.name,definition.category,stone)
	end
	local template=ReplicatedStorage.Mayhem.Art:FindFirstChild("OperatorShowcase")
	if template and template:IsA("Model") then
		for index,id in {"Vanguard","Spectre","Relay"} do
			local x=-30
			local z=213+(index-1)*10
			local rig=template:Clone()
			rig.Name=id.."Display"
			for _,item in rig:GetDescendants() do if item:IsA("LuaSourceContainer") then item:Destroy() end end
			rig.Parent=hub
			rig:PivotTo(CFrame.new(x,36,z)*CFrame.Angles(0,-math.pi/2,0))
			Art.outfit(rig,stone,Visuals.operative(id).shoulders,id)
			local bounds,size=rig:GetBoundingBox()
			rig:PivotTo(rig:GetPivot()+Vector3.new(0,32.5-(bounds.Position.Y-size.Y/2),0))
			for _,p in rig:GetDescendants() do if p:IsA("BasePart") then p.Anchored=true; p.CanCollide,p.CanTouch,p.CanQuery=false,false,false end end
			detail(hub,"OperatorPlinth",Vector3.new(5,0.5,5),CFrame.new(x,32.25,z),graphite)
			Geometry.sign(hub,CFrame.new(-26.8,34,z)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(4.8,1.2,0.15),string.upper(id),"OPERATOR BAY / 0"..index,stone)
		end
	end
	station(hub,Vector3.new(0,35,208),"PLAY","LAST SIGNAL / SOLO SURVIVAL","Matchmaking",stone)
	station(hub,Vector3.new(29,35,215),"ARMORY","7 WEAPONS / HANDLING KITS","Armory",ember)
	station(hub,Vector3.new(29,35,230),"COLLECTION","EARN / PREVIEW / EQUIP","Shop",stone)
	station(hub,Vector3.new(29,35,243),"DAILY CACHE","CHECK TODAY'S REWARD","Daily",stone)
	station(hub,Vector3.new(-12,35,242),"ARENAS","EXPLORE / VOTE / DEPLOY","Maps",ember)
	station(hub,Vector3.new(12,35,242),"SYSTEMS","AUDIO / DISPLAY / CAMERA","Settings",stone)
	local telemetry=Geometry.sign(hub,CFrame.new(0,40,207)*CFrame.Angles(0,math.pi,0),Vector3.new(18,2,0.3),"LAST SIGNAL","WAITING FOR CONTENDERS",stone)
	telemetry.Name="HubTelemetry"
	for _,x in {-24,24} do
		local lamp=detail(hub,"CeilingWash",Vector3.new(0.3,0.3,8),CFrame.new(x,52,230),stone,true)
		local light=Instance.new("PointLight")
		light.Color,light.Brightness,light.Range=stone,1.2,32
		light.Shadows,light.Parent=false,lamp
	end

	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(140, 134, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(161, 165, 180)
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
