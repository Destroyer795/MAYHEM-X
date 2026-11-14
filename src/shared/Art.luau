--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage.Mayhem:WaitForChild("Art")
local Arsenal = require(script.Parent.Arsenal)
local Art = {}

function Art.place(parent: Instance?, name: string, frame: CFrame, size: Vector3?, tier: number?): Model
	local template = Library:FindFirstChild(name)
	assert(template and template:IsA("Model"), "Missing original art model: " .. name)
	local model = template:Clone() :: Model
	local _, bounds = model:GetBoundingBox()
	local ratio = if size then size / bounds else Vector3.one
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local position = part.Position
			part.CFrame = CFrame.new(position * ratio) * (part.CFrame - position)
			part.Size *= ratio
			if not part:IsA("MeshPart") or part.TextureID ~= "" then part.Color = Color3.new(1, 1, 1) end
			part.Anchored, part.Massless = true, true
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part:SetAttribute("MayhemDetail", true)
			if tier then part:SetAttribute("QualityTier", tier) end
			part.CastShadow = tier ~= 2
		end
	end
	model.WorldPivot = CFrame.identity
	model:PivotTo(frame)
	model.Parent = parent
	return model
end

function Art.weld(model: Model, body: BasePart)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = body, part
			weld.Parent = part
		end
	end
end

local function outfitPiece(style: Model, source: string, piece: string, body: BasePart, offset: CFrame, size: Vector3)
	local template = Library[source]:FindFirstChild(piece, true)
	assert(template and template:IsA("MeshPart"), "Missing outfit piece: " .. piece)
	local part = template:Clone() :: MeshPart
	part.Name = piece
	part.Size, part.CFrame = size, body.CFrame * offset
	part.Color, part.Massless, part.CastShadow = Color3.new(1,1,1), true, false
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = false, false, false, false
	part.Parent = style
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = body, part, part
end

function Art.outfit(character: Model, accent: Color3, width: number, operative: string?)
	local previous = character:FindFirstChild("MayhemStyle")
	if previous then previous:Destroy() end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if not torso or not torso:IsA("BasePart") or not head or not head:IsA("BasePart") then return end
	for _, item in character:GetChildren() do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then item:Destroy()
		elseif item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
			item.Color, item.Material = Color3.fromRGB(35, 37, 40), Enum.Material.SmoothPlastic
			if item:IsA("MeshPart") then item.TextureID = "" end
			for _, surface in item:GetChildren() do if surface:IsA("SurfaceAppearance") or surface:IsA("Decal") then surface:Destroy() end end
		end
	end
	head.Transparency = 1
	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") then for _, part in accessory:GetDescendants() do if part:IsA("BasePart") then part.Transparency = 1 end end end
	end
	local style = Instance.new("Model")
	style.Name, style.Parent = "MayhemStyle", character
	local left = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
	local right = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
	local shoulderSpan = if left and right and left:IsA("BasePart") and right:IsA("BasePart") then (left.Position-right.Position).Magnitude else torso.Size.X
	local t = Vector3.new(math.clamp(shoulderSpan*0.78,1.2,2.4),math.clamp((head.Position-torso.Position).Magnitude*1.25,0.9,1.7),math.clamp(torso.Size.Z,0.7,1.1))
	local h = head.Size
	if operative == "Spectre" then
		outfitPiece(style, "SpectreMantle", "hood_geom", head, CFrame.new(0,0.05,0.04), h * Vector3.new(1.25,1.3,1.25))
		outfitPiece(style, "SpectreMantle", "visor_geom", head, CFrame.new(0,-0.03,-h.Z*0.29), h * Vector3.new(0.72,0.84,0.68))
		outfitPiece(style, "SpectreMantle", "collar_geom", torso, CFrame.new(0,t.Y*0.36,0), t * Vector3.new(1.22,0.38,1.25))
		outfitPiece(style, "SpectreMantle", "cape_geom", torso, CFrame.new(0,-t.Y*0.57,t.Z*0.38), t * Vector3.new(1.5,2.05,1.05))
		outfitPiece(style, "SpectreMantle", "chest harness_geom", torso, CFrame.new(0,0,-t.Z*0.18), t * Vector3.new(1.04,1.1,1.15))
	elseif operative == "Relay" then
		outfitPiece(style, "RelayHarness", "torso_geom", torso, CFrame.new(0,-t.Y*0.13,0), t * Vector3.new(1.12,1.45,1.7))
		for _, side in {"Left","Right"} do
			local arm = character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
			if arm and arm:IsA("BasePart") then
				outfitPiece(style, "RelayHarness", string.lower(side).." arm_geom", arm, CFrame.new(0,-arm.Size.Y*0.05,0), arm.Size * Vector3.new(1.2,1.12,1.2))
			end
		end
		outfitPiece(style,"VanguardBreachKit","combat helmet_geom",head,CFrame.identity,h*Vector3.new(1.3,1.08,1.2))
	else
		outfitPiece(style,"VanguardBreachKit","combat helmet_geom",head,CFrame.identity,h*Vector3.new(1.4,1.12,1.3))
		outfitPiece(style,"VanguardBreachKit","chest cuirass_geom",torso,CFrame.new(0,-t.Y*0.1,0),t*Vector3.new(1.3,1.35,1.25))
		outfitPiece(style,"VanguardBreachKit","abdomen_geom",torso,CFrame.new(0,-t.Y*0.58,0),t*Vector3.new(1.08,0.65,1.16))
		outfitPiece(style,"VanguardBreachKit","shoulder guards_geom",torso,CFrame.new(0,t.Y*0.21,0),t*Vector3.new(1.7,0.9,1.35))
	end
	style:SetAttribute("Operative", operative or "Vanguard")
end

local function attachment(model: Model, name: string, frame: CFrame, size: Vector3, color: Color3, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name, part.CFrame, part.Size = name, frame, size
	part.Shape = shape or Enum.PartType.Block
	part.Color, part.Material = color, Enum.Material.Metal
	part.Anchored, part.Massless, part.CastShadow = true, true, false
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Parent = model
	return part
end

function Art.weapon(parent: Instance?, slot: number, frame: CFrame, accent: Color3, id: string?, kit: string?): Model
	local item = Arsenal.resolve(id or (if slot==1 then "Vector" else "Rift"), kit)
	local model = Art.place(parent, item.model, frame, item.size)
	model.Name = "MayhemWeapon"
	model:SetAttribute("WeaponId", item.id)
	model:SetAttribute("HandlingKit", item.kit)
	local height, length = item.size.Y, item.size.Z
	local inlay = attachment(model,"EnergyInlay",frame * (if slot==1 then CFrame.new(item.size.X*0.5,height*0.12,-length*0.09) else CFrame.new(0,height*0.21,-length*0.52)),
		if slot==1 then Vector3.new(0.018,0.045,length*0.14) else Vector3.new(0.045,height*0.26,0.018),accent)
	inlay.Material = Enum.Material.Neon
	local metal, grip = Color3.fromRGB(71,74,79), Color3.fromRGB(25,27,30)
	if item.kit=="Precision" then
		attachment(model,"OpticMount",frame*CFrame.new(0,height*0.51,0),Vector3.new(0.22,0.12,0.42),metal)
		attachment(model,"OpticHousing",frame*CFrame.new(0,height*0.65,-0.02)*CFrame.Angles(0,math.pi/2,0),Vector3.new(0.58,0.24,0.24),grip,Enum.PartType.Cylinder)
		attachment(model,"OpticLens",frame*CFrame.new(0,height*0.65,-0.32)*CFrame.Angles(0,math.pi/2,0),Vector3.new(0.015,0.18,0.18),accent,Enum.PartType.Cylinder)
	elseif item.kit=="Quickdraw" then
		attachment(model,"CompactStock",frame*CFrame.new(0,height*0.08,length*0.47),Vector3.new(0.21,0.27,0.48),metal)
		attachment(model,"MagazinePull",frame*CFrame.new(0,-height*0.46,0.05),Vector3.new(0.24,0.12,0.3),accent)
	elseif item.kit=="Reach" then
		attachment(model,"ExtendedHaft",frame*CFrame.new(0,-height*0.49,0)*CFrame.Angles(0,0,math.pi/2),Vector3.new(0.7,0.15,0.15),metal,Enum.PartType.Cylinder)
		attachment(model,"Pommel",frame*CFrame.new(0,-height*0.49-0.35,0),Vector3.new(0.23,0.18,0.23),accent,Enum.PartType.Ball)
	elseif item.kit=="Tempo" then
		for i=1,3 do attachment(model,"GripWrap",frame*CFrame.new(0,-height*0.32-i*0.09,0),Vector3.new(0.2,0.035,0.2),accent) end
	end
	return model
end

function Art.warm()
	local models = {}
	for _, name in { "VectorRifle", "RiftBlade", "SignalArmor", "SignalHelmet", "NeedleSMG", "MantisDMR", "BreakerShotgun", "TalonKnife", "MaulHammer", "SpectreMantle", "RelayHarness", "VanguardBreachKit" } do
		local model = Library:FindFirstChild(name)
		if model then table.insert(models, model) end
	end
	local ok, message = pcall(function() game:GetService("ContentProvider"):PreloadAsync(models) end)
	if not ok then warn("MAYHEM X equipment preload: " .. tostring(message)) end
end

if game:GetService("RunService"):IsClient() then task.spawn(Art.warm) end
return Art
