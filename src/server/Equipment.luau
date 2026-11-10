--!strict
local Equipment = {}

function Equipment.clear(character: Model)
	local old = character:FindFirstChild("MayhemWeapon")
	if old then
		old:Destroy()
	end
end

function Equipment.equip(character: Model, slot: number)
	Equipment.clear(character)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "MayhemWeapon"
	model.Parent = character
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
		local item = Instance.new("Part")
		item.Name = name
		item.Size = size
		item.Material = material
		item.Color = color
		item.CanCollide = false
		item.CanTouch = false
		item.CanQuery = false
		item.Massless = true
		item.CFrame = hand.CFrame * offset
		item.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = item
		weld.Parent = item
		return item
	end
	local dark = Color3.fromRGB(33, 43, 59)
	local cyan = character:GetAttribute("MayhemAccent") or Color3.fromRGB(149, 95, 255)
	if slot == 1 then
		piece("Receiver", Vector3.new(0.65, 0.6, 2.6), CFrame.new(0, -0.25, -0.8), dark, Enum.Material.Metal)
		piece("Barrel", Vector3.new(0.22, 0.22, 1.1), CFrame.new(0, -0.2, -2.3), cyan, Enum.Material.Neon)
		piece("Cell", Vector3.new(0.4, 0.6, 0.7), CFrame.new(0, -0.7, -0.5), dark, Enum.Material.Metal)
	else
		piece("Hilt", Vector3.new(0.3, 1, 0.3), CFrame.new(0, -0.5, 0), dark, Enum.Material.Metal)
		piece("Guard", Vector3.new(1.2, 0.2, 0.4), CFrame.new(0, -1, 0), dark, Enum.Material.Metal)
		piece("Edge", Vector3.new(0.25, 3.2, 0.55), CFrame.new(0, -2.65, 0), cyan, Enum.Material.Neon)
	end
end

return Equipment
