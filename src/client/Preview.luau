--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Geometry = require(ReplicatedStorage.Mayhem.Shared.Geometry)
local Visuals = require(ReplicatedStorage.Mayhem.Shared.Visuals)
local Catalog = require(ReplicatedStorage.Mayhem.Shared.MapCatalog)
local Art = require(ReplicatedStorage.Mayhem.Shared.Art)
local Animations = require(ReplicatedStorage.Mayhem.Shared.AnimationConfig)
local Players = game:GetService("Players")
local Inspection = require(script.Parent.InspectionInput)
local Theme = require(script.Parent.Theme)
local loadedAssets: {[string]:boolean} = {}
local Preview = {}
Preview.__index = Preview

function Preview.new(parent: Instance)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "OperativePreview"
	viewport.BackgroundColor3 = Color3.fromRGB(214, 235, 245)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(157, 166, 183)
	viewport.LightColor = Color3.fromRGB(255, 241, 215)
	viewport.LightDirection = Vector3.new(-0.6, -0.8, -1)
	viewport.Parent = parent
	local reflections=Instance.new("Sky")
	reflections.Name,reflections.Parent="DisplayReflections",viewport
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
	camera.FieldOfView = 42
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local self: any=setmetatable({frame=viewport,camera=camera,key="",world=nil,zoom=1,pitch=0},Preview)
	local loading=Instance.new("TextLabel")
	loading.Name,loading.Text,loading.TextSize="AssetLoading","Loading surface materials...",14
	loading.Font,loading.TextColor3=Enum.Font.BuilderSansMedium,Color3.fromRGB(242,237,226)
	loading.Size,loading.BackgroundTransparency,loading.ZIndex=UDim2.fromScale(1,1),1,4
	loading.Visible,loading.Parent=false,viewport
	self.loadingText=loading
	self.retry=Theme.button(viewport,"RetryAssets","RETRY LOADING",UDim2.new(0.5,-82,0.5,24),UDim2.fromOffset(164,40),function()
		if self.reloadMaterials then self.reloadMaterials() end
	end,true)
	self.retry.ZIndex,self.retry.Visible=5,false
	self.inspection=Inspection.new(viewport,function(delta)
		self.yaw=(self.yaw or 0)-delta.X*0.009
		self.pitch=math.clamp(self.pitch-delta.Y*0.006,-0.6,0.6)
		self.lastInputAt=os.clock()
		viewport:SetAttribute("InspectionYaw",self.yaw)
	end,function(value)
		self.zoom=math.clamp(self.zoom+value*0.12,0.7,1.7)
		self.lastInputAt=os.clock()
		viewport:SetAttribute("InspectionZoom",self.zoom)
	end)
	return self
end

function Preview.show(self: any, kind: string, operative: string, skin: string, weapon: number?, weaponId: string?, kit: string?)
	local character = Players.LocalPlayer.Character
	local appearance = if character then character:FindFirstChild("MayhemStyle") else nil
	local showcase = if kind == "operative" or kind == "victory" then ReplicatedStorage.Mayhem.Art:FindFirstChild("OperatorShowcase") else nil
	if showcase and not showcase:IsA("Model") then showcase = nil end
	if kind ~= "weapon" and not showcase and (not character or not appearance or not character:FindFirstChild("Head") or not (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))) then return end
	local key = kind .. operative .. skin .. tostring(weapon) .. tostring(weaponId) .. tostring(kit)
	if self.key == key and self.character == character and self.appearance == appearance and self.showcase == showcase then return end
	if kind=="weapon" and self.previewWeaponId~=weaponId then self.yaw,self.pitch,self.zoom=0,0,if weapon==2 then 1.4 else 1.15 end
	self.previewWeaponId=weaponId
	self.key, self.character, self.appearance, self.showcase = key, character, appearance, showcase
	self.kind=kind
	self.retry.Visible=false
	self.reloadMaterials=nil
	self.inspection.root.Enabled=kind=="weapon"
	self.frame:SetAttribute("SkinId",skin)
	self.lastViewportSize = nil
	if self.idleTrack then self.idleTrack:Stop(0); self.idleTrack:Destroy(); self.idleTrack = nil end
	self.motionPaused = nil
	if self.animationTrack then
		self.animationTrack:Stop(0.1)
		self.animationTrack:Destroy()
		self.animationTrack = nil
	end
	if self.world then self.world:Destroy() end
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	self.frame.BackgroundColor3 = Color3.fromRGB(205, 222, 232)
	self.camera.CFrame = CFrame.lookAt(Vector3.new(5.4, 2.5, -9), Vector3.new(0, -0.3, 0))
	local accent = Color3.fromRGB(table.unpack((Visuals.skin(skin) or Visuals.Skins[1]).color))
	if kind == "weapon" then
		self.subject = Art.weapon(world, weapon or 1, if weapon==2 then CFrame.Angles(0,0,math.rad(-65)) else CFrame.identity, accent, weaponId, kit, skin)
		self.direction = if weapon == 2 then Vector3.new(0.5, 0.2, -1).Unit else Vector3.new(1, 0.25, 0.2).Unit
	elseif showcase or character then
		local source = (showcase or character) :: Model
		local before = source.Archivable
		source.Archivable = true
		local rig = source:Clone()
		source.Archivable = before
		for _, child in rig:GetDescendants() do
			if child:IsA("LuaSourceContainer") or (not showcase and child:IsA("Accessory")) or child.Name == "MayhemWeapon" then child:Destroy()
			elseif child:IsA("BasePart") then
				child.Anchored, child.CanCollide, child.CanTouch, child.CanQuery = true, false, false, false
				child.LocalTransparencyModifier = 0
			end
		end
		rig:PivotTo(CFrame.identity)
		rig.Parent = world
		Art.outfit(rig, accent, (Visuals.operative(operative) or Visuals.Operatives[1]).shoulders, operative)

		for _, part in rig:GetDescendants() do
			if part:IsA("BasePart") then part.Anchored = part.Name == "HumanoidRootPart"; part.Massless = true end
		end
		if kind == "victory" then
			for _, joint in rig:GetDescendants() do
				if joint:IsA("Motor6D") and joint.Name == "RightShoulder" then joint.Transform = CFrame.Angles(-0.5, 0, 0.7) end
			end
		end
		self.subject = rig
		self.direction = Vector3.new(0.35, 0.15, -1).Unit
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			if showcase then
				local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
				animator.Parent = humanoid
				local animation = Instance.new("Animation")
				animation.AnimationId = Animations.OperatorShowcaseIdle
				local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
				animation:Destroy()
				if ok and track then
					track.Looped = true
					track.Priority = Enum.AnimationPriority.Idle
					track:Play(0.2)
					self.animationTrack = track
				end
				if kind == "victory" then
					self.idleTrack, self.animationTrack = self.animationTrack, nil
					local victory = Instance.new("Animation")
					victory.AnimationId = Animations.Victory
					local victoryOk, victoryTrack = pcall(function() return animator:LoadAnimation(victory) end)
					victory:Destroy()
					if victoryOk and victoryTrack then
						victoryTrack.Looped = false
						victoryTrack.Priority = Enum.AnimationPriority.Action
						victoryTrack:Play(0.2)
						self.animationTrack = victoryTrack
					end
				end
			end
		end
		local pedestalY = -3.25
		if kind ~= "weapon" then
			local bounds, size = self.subject:GetBoundingBox()
			pedestalY = bounds.Position.Y - size.Y * 0.5 - 0.45
		end
		local plinth = Geometry.part(world, "DisplayPlinth", Vector3.new(0.22,4.6,4.6), CFrame.new(0,pedestalY+0.34,0)*CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(58,62,69), Enum.Material.Metal)
		plinth.Shape=Enum.PartType.Cylinder
		plinth.CanCollide, plinth.CanQuery = false, false
	else self.key = "" end
	if self.subject then
		local bounds, size = self.subject:GetBoundingBox()
		self.focus, self.bounds = bounds.Position, size
		self.baseBoundsRotation=bounds-bounds.Position
		self.baseSubjectPivot=self.subject:GetPivot()
		if kind=="weapon" then
			local scale=math.max(size.X,size.Y,size.Z)
			local stage=Instance.new("Folder")
			stage.Name,stage.Parent="InspectionStage",world
			self.dressing,self.dressingHidden=stage,nil
			local position=bounds.Position-self.direction*scale*1.25-Vector3.new(0,scale*0.15,0)
			local room=Art.place(stage,"SignalHangar",CFrame.lookAt(position,position+self.direction),Vector3.new(scale*3.4,scale*1.7,scale*2))
			for _,part in room:GetDescendants() do
				if part:IsA("BasePart") then
					part.Color,part.Material=Color3.fromRGB(68,75,92),Enum.Material.Metal
					if part:IsA("MeshPart") then part.TextureID="" end
					local surface=part:FindFirstChildOfClass("SurfaceAppearance")
					if surface then surface:Destroy() end
				end
			end
			local assetKey=(weaponId or tostring(weapon))..skin
			if not loadedAssets[assetKey] then
				local subject=self.subject
				self.reloadMaterials=function()
					self.materialSerial=(self.materialSerial or 0)+1
					local serial=self.materialSerial
					local finished=false
					self.loadingText.Text="Loading surface materials..."
					self.loadingText.Visible,self.retry.Visible=true,false
					self.frame:SetAttribute("TextureStatus","LOADING")
					task.delay(10,function()
						if finished or self.key~=key or self.subject~=subject or self.materialSerial~=serial or not self.frame.Parent then return end
						self.loadingText.Text="Asset delivery is taking longer than expected."
						self.retry.Visible=true
						self.frame:SetAttribute("TextureStatus","TIMED_OUT")
					end)
					task.spawn(function()
						local ok=Art.preload(subject,weaponId,skin)
						finished=true
						if self.key~=key or self.subject~=subject or self.materialSerial~=serial or not self.frame.Parent then return end
						local success=ok and not subject:GetAttribute("SkinUnavailable")
						loadedAssets[assetKey]=success
						self.loadingText.Visible,self.retry.Visible=not success,not success
						self.loadingText.Text="Surface assets unavailable. Retry loading or check permissions."
						self.frame:SetAttribute("TextureStatus",if success then "READY" else "FAILED")
						self.lastViewportSize=nil
					end)
				end
				self.reloadMaterials()
			else self.loadingText.Visible=false;self.frame:SetAttribute("TextureStatus","READY") end
		end
		if (self.cinematic and kind == "operative") or kind=="victory" then
			local h = size.Y
			local dressing = Instance.new("Folder")
			dressing.Name, dressing.Parent = "CinematicScenery", world
			self.dressing, self.dressingHidden = dressing, nil
			Art.place(dressing, "SignalHangar", CFrame.new(0,bounds.Position.Y+h*0.25,h*1.15), Vector3.new(h*4.3,h*2.5,h*2.8))
			Art.weapon(dressing, 1, CFrame.new(h*0.65,bounds.Position.Y-h*0.28,-h*0.06)*CFrame.Angles(0,math.rad(70),math.rad(-12)),accent,weaponId,kit,skin)
			local floorY=bounds.Position.Y-h*0.5-0.12
			local mountY=bounds.Position.Y-h*0.28
			local dock=Geometry.part(dressing,"WeaponDock",Vector3.new(0.12,1.6,1.6),CFrame.new(h*0.65,floorY,-h*0.06)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(65,68,74),Enum.Material.Metal)
			dock.Shape=Enum.PartType.Cylinder
			dock.CanCollide,dock.CanTouch,dock.CanQuery=false,false,false
			local support=Geometry.part(dressing,"WeaponSupport",Vector3.new(0.09,mountY-floorY,0.09),CFrame.new(h*0.65,(mountY+floorY)/2,-h*0.06),Color3.fromRGB(116,120,128),Enum.Material.Metal)
			support.CanCollide,support.CanTouch,support.CanQuery=false,false,false
		end
		self.camera.FieldOfView = if kind == "weapon" then 34 else 40
		self:step(true)
	end
end

function Preview.map(self: any, id: string)
	if self.key == "map:" .. id then return end
	local definition: any = nil
	for _, entry in Catalog do if entry.id == id then definition = entry; break end end
	if not definition then return end
	self:hide()
	self.key = "map:" .. id
	self.lastViewportSize = nil
	local world = Instance.new("WorldModel")
	world.Parent = self.frame
	self.world = world
	for _, entry in definition.preview do
		Geometry.part(world, "Terrain", Vector3.new(table.unpack(entry.size)) * 0.04,
			CFrame.new(Vector3.new(table.unpack(entry.p)) * 0.04) * CFrame.Angles(0, math.rad(entry.yaw), 0) * CFrame.Angles(entry.pitch, 0, 0), Color3.fromRGB(table.unpack(entry.color)))
	end
	local function prop(name: string, x: number, y: number, z: number, size: Vector3)
		Art.place(world, name, CFrame.new(x, y, z), size)
	end
	if id == "Collapse" then
		prop("ReactorTurbine", 0, 1.4, 0, Vector3.new(0.6, 1, 0.6))
		for _, p in {Vector3.new(4, 0.2, 0), Vector3.new(-4, 0.2, 0), Vector3.new(0, 0.2, 4), Vector3.new(0, 0.2, -4)} do prop("AerialBastion", p.X, p.Y, p.Z, Vector3.new(2.3, 0.7, 2.3)) end
	elseif id == "Jungle" then
		for _, x in {-2.6, 2.6} do for _, z in {-2.6, 2.6} do
			prop("RockShelf", x, 0.2, z, Vector3.new(3.4, 1, 3.4))
			prop("CanopyTree", x, 1.8, z, Vector3.new(1.2, 1.8, 1.2))
		end end
	elseif id == "Solar" then
		prop("SolarRelic", 0, 1.6, 0, Vector3.new(1, 1.8, 0.6))
		for _, x in {-4.5, 4.5} do prop("SolarRelic", x, 1.4, -3.4, Vector3.new(0.9, 1.8, 0.6)) end
	elseif id == "Frost" then
		for _, x in {-3, 0, 3} do prop("FrostCrown", x, 1.9, 0, Vector3.new(0.7, 1.6, 0.6)) end
	elseif id == "Skyline" then
		for _, x in {-3.3, 3.3} do for _, z in {-3.1, 3.1} do prop("SkySpire", x, 0.7, z, Vector3.new(1.5, 2.6, 1.5)) end end
	end
	self.frame.BackgroundColor3 = Color3.fromRGB(table.unpack(definition.lighting.sky))
	self.camera.CFrame = CFrame.lookAt(Vector3.new(11, 10, -13), Vector3.new(0, 0.7, 0))
end

function Preview.step(self: any, reducedMotion: boolean)
	if not self.world then return end
	if self.motionPaused ~= reducedMotion then
		for _, track in {self.animationTrack, self.idleTrack} do track:AdjustSpeed(if reducedMotion then 0 else 1) end
		self.motionPaused = reducedMotion
	end
	local viewportSize = self.frame.AbsoluteSize
	local hideDressing = viewportSize.X < 260 and self.kind~="weapon"
	if self.dressing and self.dressing.Parent and self.dressingHidden ~= hideDressing then
		self.dressingHidden = hideDressing
		for _, part in self.dressing:GetDescendants() do if part:IsA("BasePart") then part.LocalTransparencyModifier = if hideDressing then 1 else 0 end end
	end
	if viewportSize ~= self.lastViewportSize and viewportSize.X > 0 and viewportSize.Y > 0 then
		local previous = self.camera
		self.camera = previous:Clone()
		self.camera.Parent = self.frame
		self.frame.CurrentCamera = self.camera
		previous:Destroy()
		self.lastViewportSize = viewportSize
	end
	if not self.bounds or self.key:sub(1, 4) == "map:" then return end
	local now=os.clock()
	local dt=math.min(0.1,now-(self.lastStep or now))
	self.lastStep=now
	if self.kind=="weapon" and not reducedMotion and not self.inspection.dragging and now-(self.lastInputAt or 0)>1.5 then self.yaw=(self.yaw or 0)+dt*0.14 end
	local angle=(self.yaw or 0)+(if self.kind=="weapon" or reducedMotion then 0 else math.sin(now*0.4)*0.08)
	local turn=CFrame.Angles(self.pitch or 0,angle,0)
	local direction=if self.kind=="weapon" then self.direction else turn:VectorToWorldSpace(self.direction)
	if self.kind=="weapon" then self.subject:PivotTo(CFrame.new(self.focus)*turn*CFrame.new(-self.focus)*self.baseSubjectPivot) end
	local rotation = CFrame.lookAt(Vector3.zero, -direction)
	local extent = Vector3.zero
	for _, x in {-0.5, 0.5} do for _, y in {-0.5, 0.5} do for _, z in {-0.5, 0.5} do
		local point=self.bounds*Vector3.new(x,y,z)
		if self.kind=="weapon" then point=turn:VectorToWorldSpace(self.baseBoundsRotation:VectorToWorldSpace(point)) end
		local v = rotation:VectorToObjectSpace(point)
		extent = Vector3.new(math.max(extent.X, math.abs(v.X)), math.max(extent.Y, math.abs(v.Y)), math.max(extent.Z, math.abs(v.Z)))
	end end end
	local aspect = math.max(0.3, self.frame.AbsoluteSize.X / math.max(1, self.frame.AbsoluteSize.Y))
	local tangent = math.tan(math.rad(self.camera.FieldOfView / 2))
	local distance = math.max(extent.Y / tangent, extent.X / (tangent * aspect)) * 1.12 + extent.Z
	local target=CFrame.lookAt(self.focus+direction*(distance/(self.zoom or 1)),self.focus)
	self.camera.CFrame=if reducedMotion or dt==0 then target else self.camera.CFrame:Lerp(target,1-math.exp(-dt*16))
end

function Preview.hide(self: any)
	self.inspection.root.Enabled=false
	self.inspection.dragging=false
	self.loadingText.Visible=false
	self.retry.Visible=false
	self.reloadMaterials=nil
	if self.idleTrack then self.idleTrack:Stop(0); self.idleTrack:Destroy(); self.idleTrack = nil end
	if self.animationTrack then
		self.animationTrack:Stop(0.1)
		self.animationTrack:Destroy()
		self.animationTrack = nil
	end
	if self.world then self.world:Destroy(); self.world = nil end
	self.key = ""
	self.subject, self.bounds = nil, nil
	self.lastViewportSize = nil
end

return Preview
