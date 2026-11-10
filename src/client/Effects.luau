--!strict
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Effects = {}
Effects.__index = Effects

function Effects.new(preferences: any)
	local folder = Instance.new("Folder")
	folder.Name = "MayhemLocalEffects"
	folder.Parent = workspace
	return setmetatable({ folder = folder, preferences = preferences }, Effects)
end

function Effects.play(self: any, kind: string, data: any)
	if self.preferences.reducedEffects then return end
	local camera = workspace.CurrentCamera
	local position = data.from or data.at
	if typeof(position) == "CFrame" then position = position.Position end
	if camera and position and (position - camera.CFrame.Position).Magnitude > 450 then return end
	if #self.folder:GetChildren() >= 100 then return end
	local item = Instance.new("Part")
	item.Name = kind
	item.Material = Enum.Material.Neon
	item.Color = Color3.fromRGB(72, 225, 230)
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	if kind == "Shot" then
		local length = (data.to - data.from).Magnitude
		if length < 0.01 then item:Destroy(); return end
		item.Size = Vector3.new(0.06, 0.06, length)
		item.CFrame = CFrame.lookAt((data.to + data.from) / 2, data.to)
		item.Parent = self.folder
		TweenService:Create(item, TweenInfo.new(0.1), { Transparency = 1 }):Play()
		Debris:AddItem(item, 0.12)
	elseif kind == "Pulse" then
		item.Shape = Enum.PartType.Ball
		item.Size = Vector3.one
		item.CFrame = CFrame.new(data.at)
		item.Transparency = 0.65
		item.Parent = self.folder
		TweenService:Create(item, TweenInfo.new(0.4), { Size = Vector3.new(28, 28, 28), Transparency = 1 }):Play()
		Debris:AddItem(item, 0.45)
	elseif kind == "Slash" then
		item.Size = Vector3.new(5, 0.15, 0.7)
		item.CFrame = data.at * CFrame.new(0, 0.5, -3) * CFrame.Angles(0, 0, -0.4)
		item.Parent = self.folder
		TweenService:Create(item, TweenInfo.new(0.17), { Transparency = 1, CFrame = item.CFrame * CFrame.Angles(0, 0, 1) }):Play()
		Debris:AddItem(item, 0.2)
	else
		item:Destroy()
	end
end

return Effects
