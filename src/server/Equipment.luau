--!strict
local Art = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Art)
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
	if not hand or not hand:IsA("BasePart") then return end
	local accent = character:GetAttribute("MayhemAccent") or Color3.fromRGB(149, 95, 255)
	local grip = if slot == 1 then CFrame.new(0, -0.15, -1) else CFrame.new(0, -1.55, 0) * CFrame.Angles(math.pi, 0, 0)
	local model = Art.weapon(character, slot, hand.CFrame * grip, accent)
	Art.weld(model, hand)
end

return Equipment
