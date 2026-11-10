--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Preview = {}
Preview.__index = Preview

function Preview.new(parent: Instance)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "OperativePreview"
	viewport.BackgroundColor3 = Color3.fromRGB(11, 16, 31)
	viewport.BackgroundTransparency = 0.15
	viewport.Ambient = Color3.fromRGB(130, 121, 166)
	viewport.LightColor = Color3.fromRGB(225, 227, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = parent
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
	camera.FieldOfView = 42
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return setmetatable({ frame = viewport, camera = camera, key = "", world = nil }, Preview)
end

function Preview.show(self: any, kind: string, operative: string, skin: string, weapon: number?)
	local key = kind .. operative .. skin .. tostring(weapon)
	if self.key == key then return end
	self.key = key
	if self.world then self.world:Destroy() end
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	local color = Color3.fromRGB(table.unpack((Visuals.skin(skin) or Visuals.Skins[1]).color))
	if kind == "weapon" then
		local frame = CFrame.Angles(0, -0.25, 0)
		if weapon == 2 then
			Geometry.part(world, "Hilt", Vector3.new(0.4, 1, 0.4), frame * CFrame.new(0, -1.5, 0), Color3.fromRGB(37, 45, 65))
			Geometry.part(world, "Guard", Vector3.new(1.4, 0.25, 0.4), frame * CFrame.new(0, -1, 0), color)
			Geometry.part(world, "Blade", Vector3.new(0.3, 3.2, 0.6), frame * CFrame.new(0, 0.7, 0), color, Enum.Material.Neon)
		else
			Geometry.part(world, "Receiver", Vector3.new(0.8, 0.85, 3.6), frame, Color3.fromRGB(37, 45, 65))
			Geometry.part(world, "Barrel", Vector3.new(0.3, 0.3, 2), frame * CFrame.new(0, 0.05, -2.7), color, Enum.Material.Neon)
			Geometry.part(world, "Cell", Vector3.new(0.6, 1, 0.9), frame * CFrame.new(0, -0.8, 0.2), color)
		end
	else
		Geometry.figure(world, CFrame.new(), color, (Visuals.operative(operative) or Visuals.Operatives[1]).shoulders)
		Geometry.ring(world, "Dais", CFrame.new(0, -3.6, 0), 2.6, 12, color)
	end
end

function Preview.hide(self: any)
	if self.world then self.world:Destroy(); self.world = nil end
	self.key = ""
end

return Preview
