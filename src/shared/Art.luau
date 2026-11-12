--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage.Mayhem:WaitForChild("Art")
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

function Art.outfit(character: Model, accent: Color3, width: number)
	local previous = character:FindFirstChild("MayhemStyle")
	if previous then previous:Destroy() end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if not torso or not torso:IsA("BasePart") or not head or not head:IsA("BasePart") then return end
	for _, item in character:GetChildren() do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then item:Destroy()
		elseif item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" and item.Name ~= "Head" then
			item.Color, item.Material = Color3.fromRGB(34, 47, 65), Enum.Material.SmoothPlastic
			if item:IsA("MeshPart") then item.TextureID = "" end
			for _, surface in item:GetChildren() do if surface:IsA("SurfaceAppearance") or surface:IsA("Decal") then surface:Destroy() end end
		end
	end
	head.Transparency = 1
	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") then for _, part in accessory:GetDescendants() do if part:IsA("BasePart") then part.Transparency = 1 end end end
	end
	local style = Instance.new("Model")
	style.Name = "MayhemStyle"
	style.Parent = character
	local armor = Art.place(style, "SignalArmor", torso.CFrame, torso.Size * Vector3.new(1.12 * width, 1.15, 1.3))
	local helmet = Art.place(style, "SignalHelmet", head.CFrame, head.Size * Vector3.new(1.1, 1.12, 1.15))
	Art.weld(armor, torso)
	Art.weld(helmet, head)
	local inlay = Instance.new("Part")
	inlay.Name = "SignalInlay"
	inlay.Size = Vector3.new(0.12, torso.Size.Y * 0.5, 0.05)
	inlay.CFrame = torso.CFrame * CFrame.new(0, 0.05, -torso.Size.Z * 0.68)
	inlay.Color, inlay.Material = accent, Enum.Material.Neon
	inlay.CanCollide, inlay.CanTouch, inlay.CanQuery, inlay.Massless, inlay.CastShadow = false, false, false, true, false
	inlay.Parent = style
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = torso, inlay, inlay
end

function Art.weapon(parent: Instance?, slot: number, frame: CFrame, accent: Color3): Model
	local model = Art.place(parent, if slot == 1 then "VectorRifle" else "RiftBlade", frame,
		if slot == 1 then Vector3.new(0.5, 1, 3.5) else Vector3.new(0.75, 4.1, 0.3))
	model.Name = "MayhemWeapon"
	local inlay = Instance.new("Part")
	inlay.Name = "EnergyInlay"
	inlay.Size = if slot == 1 then Vector3.new(0.015, 0.035, 0.28) else Vector3.new(0.06, 1.6, 0.025)
	inlay.CFrame = frame * (if slot == 1 then CFrame.new(0.23, 0.12, -0.3) else CFrame.new(0, 0.8, -0.155))
	inlay.Color, inlay.Material = accent, Enum.Material.Neon
	inlay.Anchored, inlay.Massless, inlay.CastShadow = true, true, false
	inlay.CanCollide, inlay.CanTouch, inlay.CanQuery = false, false, false
	inlay.Parent = model
	return model
end

function Art.warm()
	local models = {}
	for _, name in { "VectorRifle", "RiftBlade", "SignalArmor", "SignalHelmet" } do
		local model = Library:FindFirstChild(name)
		if model then table.insert(models, model) end
	end
	local ok, message = pcall(function() game:GetService("ContentProvider"):PreloadAsync(models) end)
	if not ok then warn("MAYHEM X equipment preload: " .. tostring(message)) end
end

if game:GetService("RunService"):IsClient() then task.spawn(Art.warm) end
return Art
