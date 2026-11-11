--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Catalog = require(ReplicatedStorage.Mayhem.Shared.MapCatalog)
local Preview = {}
Preview.__index = Preview

function Preview.new(parent: Instance)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "OperativePreview"
	viewport.BackgroundColor3 = Color3.fromRGB(214, 235, 245)
	viewport.BackgroundTransparency = 0
	viewport.Ambient = Color3.fromRGB(177, 197, 211)
	viewport.LightColor = Color3.fromRGB(255, 250, 238)
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
	self.frame.BackgroundColor3 = Color3.fromRGB(214, 235, 245)
	self.camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
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
		Geometry.figure(world, CFrame.new(), color, (Visuals.operative(operative) or Visuals.Operatives[1]).shoulders, kind == "victory")
		Geometry.ring(world, "Dais", CFrame.new(0, -3.6, 0), 2.6, 12, color)
	end
end

function Preview.map(self: any, id: string)
	if self.key == "map:" .. id then return end
	local definition: any = nil
	for _, entry in Catalog do if entry.id == id then definition = entry; break end end
	if not definition then return end
	self:hide()
	self.key = "map:" .. id
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	for _, entry in definition.preview do
		Geometry.part(world, "Terrain", Vector3.new(table.unpack(entry.size)) * 0.04,
			CFrame.new(Vector3.new(table.unpack(entry.p)) * 0.04) * CFrame.Angles(0, math.rad(entry.yaw), 0) * CFrame.Angles(entry.pitch, 0, 0), Color3.fromRGB(table.unpack(entry.color)))
	end
	self.frame.BackgroundColor3 = Color3.fromRGB(table.unpack(definition.lighting.sky))
	self.camera.CFrame = CFrame.lookAt(Vector3.new(11, 10, -13), Vector3.new(0, 0.7, 0))
end

function Preview.step(self: any, reducedMotion: boolean)
	if not self.world or reducedMotion or self.key:sub(1, 4) == "map:" then return end
	local angle = math.sin(os.clock() * 0.4) * 0.2
	self.camera.CFrame = CFrame.Angles(0, angle, 0) * CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
end

function Preview.hide(self: any)
	if self.world then self.world:Destroy(); self.world = nil end
	self.key = ""
end

return Preview
