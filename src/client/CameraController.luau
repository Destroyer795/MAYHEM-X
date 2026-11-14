--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Config = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Config)
local Art = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Art)
local CameraController = {}
CameraController.__index = CameraController

function CameraController.new(preferences: any)
	local self: any = setmetatable({ preferences = preferences, active = false, yaw = 0, pitch = 0, stick = Vector2.zero, touch = nil, touchPosition = Vector2.zero, slot = 0, character = nil, viewmodel = nil }, CameraController)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then self.stick = Vector2.new(input.Position.X, input.Position.Y) end
		if self.active and input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			self.yaw -= input.Delta.X * 0.003
			self.pitch = math.clamp(self.pitch - input.Delta.Y * 0.003, -1.2, 1.2)
		end
	end)
	UserInputService.TouchStarted:Connect(function(input: InputObject, processed: boolean)
		local camera = Workspace.CurrentCamera
		if self.active and not processed and camera and input.Position.X > camera.ViewportSize.X * 0.45 and not self.touch then
			self.touch = input
			self.touchPosition = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.TouchMoved:Connect(function(input: InputObject)
		if self.active and self.touch == input then
			local nextPosition = Vector2.new(input.Position.X, input.Position.Y)
			local delta = nextPosition - self.touchPosition
			self.touchPosition = nextPosition
			self.yaw -= delta.X * 0.006
			self.pitch = math.clamp(self.pitch - delta.Y * 0.006, -1.2, 1.2)
		end
	end)
	UserInputService.TouchEnded:Connect(function(input: InputObject) if self.touch == input then self.touch = nil end end)
	return self
end

function CameraController.transparency(self: any, character: Model, hidden: boolean)
	for _, item in character:GetDescendants() do
		if item:IsA("BasePart") then item.LocalTransparencyModifier = if hidden then 1 else 0 end
	end
end

function CameraController.makeViewmodel(self: any, slot: number)
	if self.viewmodel then self.viewmodel:Destroy() end
	local accent = Color3.fromRGB(table.unpack((Visuals.skin(self.preferences.skin or "Pulse") or Visuals.Skins[1]).color))
	local frame = if slot == 1 then CFrame.new(0.68, -0.55, -1.7) else CFrame.new(0.65, -0.35, -1.45)
	local combat = self.combat or {}
	local id = if slot == 1 then combat.primaryId or self.preferences.primaryWeapon else combat.meleeId or self.preferences.meleeWeapon
	local kit = if slot == 1 then combat.gunKit or self.preferences.gunKit else combat.meleeKit or self.preferences.meleeKit
	local model = Art.weapon(nil, slot, frame, accent, id, kit)
	self.weaponId, self.kit = id, kit
	model:ScaleTo(0.65)
	model.Name = "MayhemViewmodel"
	model.WorldPivot = CFrame.identity
	for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CastShadow = false end end
	self.viewmodel, self.slot, self.skin = model, slot, self.preferences.skin
end

function CameraController.setActive(self: any, active: boolean)
	local character = Players.LocalPlayer.Character
	local changedCharacter = character ~= self.character
	if self.active == active and not changedCharacter then return end
	if self.visibilityConnection then self.visibilityConnection:Disconnect(); self.visibilityConnection = nil end
	if self.character then
		self:transparency(self.character, false)
		local previousHumanoid = self.character:FindFirstChildOfClass("Humanoid")
		if previousHumanoid then previousHumanoid.AutoRotate = true end
	end
	self.character = character
	self.active = active
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if active and root then
		local look = root.CFrame.LookVector
		self.yaw = math.atan2(-look.X, -look.Z)
		self.pitch = 0
		self.hidden = nil
		self.visibilityConnection = character.DescendantAdded:Connect(function(item: Instance)
			if item:IsA("BasePart") then item.LocalTransparencyModifier = if self.preferences.firstPerson then 1 else 0 end
		end)
		camera.CameraType = Enum.CameraType.Scriptable
		if humanoid then humanoid.AutoRotate = false end
	else
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then camera.CameraSubject = humanoid end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		self.touch = nil
		if self.viewmodel then self.viewmodel.Parent = nil end
	end
end

function CameraController.step(self: any, dt: number, slot: number)
	if not self.active then return end
	local camera = Workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not camera or not character or not root then return end
	local stick = if self.stick.Magnitude > 0.15 then self.stick else Vector2.zero
	self.yaw -= stick.X * dt * 2.8
	self.pitch = math.clamp(self.pitch + stick.Y * dt * 2.3, -1.2, 1.2)
	local rotation = CFrame.fromEulerAnglesYXZ(self.pitch, self.yaw, 0)
	local eye = root.Position + Vector3.new(0, 1.5, 0)
	local firstPerson = self.preferences.firstPerson
	if self.hidden ~= firstPerson then
		self:transparency(character, firstPerson)
		self.hidden = firstPerson
	end
	local position = eye
	if not firstPerson then
		local desired = eye - rotation.LookVector * 9 + rotation.RightVector * 1.6 + Vector3.new(0, 0.8, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = if self.viewmodel then { character, self.viewmodel } else { character }
		local hit = Workspace:Raycast(eye, desired - eye, params)
		position = if hit then hit.Position + hit.Normal * 0.35 else desired
	end
	camera.CFrame = CFrame.lookAt(position, position + rotation.LookVector)
	camera.Focus = CFrame.new(eye)
	camera.FieldOfView = self.preferences.fov
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, self.yaw, 0)
	if not UserInputService.TouchEnabled then UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end
	UserInputService.MouseIconEnabled = false
	local combat = self.combat or {}
	local id = if slot == 1 then combat.primaryId else combat.meleeId
	local kit = if slot == 1 then combat.gunKit else combat.meleeKit
	if self.slot ~= slot or self.skin ~= self.preferences.skin or self.weaponId ~= id or self.kit ~= kit or not self.viewmodel then self:makeViewmodel(slot) end
	self.viewmodel.Parent = if firstPerson then camera else nil
	if firstPerson then
		local now = os.clock()
		local swing = if self.preferences.reducedMotion then 0 else math.max(0, (self.swingUntil or 0) - now)
		local kick = if self.preferences.reducedMotion then 0 else math.max(0, (self.kickUntil or 0) - now) * 2 * (combat.recoil or 1)
		local reload = math.clamp(((self.reloadUntil or 0) - now) / (combat.reloadTime or Config.Rifle.ReloadTime), 0, 1)
		local tilt = if self.preferences.reducedMotion then 0 else math.sin(reload * math.pi) * 0.7
		self.viewmodel:PivotTo(camera.CFrame * CFrame.new(0, -tilt * 0.2, kick) * CFrame.Angles(tilt * 0.2, 0, swing * 1.2 + tilt))
	end
end

function CameraController.aim(self: any): Vector3?
	local camera = Workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not camera or not character or not root then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if self.viewmodel then { character, self.viewmodel } else { character }
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * 300
	local offset = target - (root.Position + Vector3.new(0, 1.4, 0))
	return if offset.Magnitude > 0.01 then offset.Unit else ray.Direction
end

return CameraController
