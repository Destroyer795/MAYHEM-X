--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Config)

local Hud = {}
Hud.__index = Hud
local colors = {
	background = Color3.fromRGB(9, 14, 23), panel = Color3.fromRGB(21, 29, 43),
	line = Color3.fromRGB(53, 68, 86), text = Color3.fromRGB(225, 238, 245),
	muted = Color3.fromRGB(139, 159, 178), cyan = Color3.fromRGB(72, 225, 230), amber = Color3.fromRGB(255, 153, 70),
}

local function frame(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundColor3 = colors.panel
	item.BorderSizePixel = 0
	item.Parent = parent
	return item
end

local function text(parent: Instance, name: string, content: string, size: number, position: UDim2, dimensions: UDim2, color: Color3?): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Text = content
	item.TextSize = size
	item.Font = Enum.Font.GothamMedium
	item.TextColor3 = color or colors.text
	item.BackgroundTransparency = 1
	item.Position = position
	item.Size = dimensions
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true
	item.Parent = parent
	return item
end

local function button(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, callback: (() -> ())?): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Text = content
	item.TextSize = 15
	item.Font = Enum.Font.GothamBold
	item.TextColor3 = colors.background
	item.BackgroundColor3 = colors.cyan
	item.BorderSizePixel = 0
	item.Position = position
	item.Size = size
	item.AutoButtonColor = true
	item.Selectable = true
	item.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = item
	if callback then item.Activated:Connect(callback) end
	return item
end

local function outline(parent: Instance)
	local stroke = Instance.new("UIStroke")
	stroke.Color = colors.line
	stroke.Thickness = 1
	stroke.Parent = parent
end

function Hud.new(callbacks: any)
	local self: any = setmetatable({ callbacks = callbacks, menuOpen = true, settingsOpen = false, resultRound = -1, feedItems = {}, touch = UserInputService.TouchEnabled }, Hud)
	local screen = Instance.new("ScreenGui")
	screen.Name = "MayhemHUD"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 10
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.screen = screen
	self.root = frame(screen, "Interface", UDim2.fromScale(1, 1), UDim2.new())
	self.root.BackgroundTransparency = 1

	self.status = frame(self.root, "MatchStatus", UDim2.new(0.54, 0, 0, 58), UDim2.new(0.23, 0, 0, 10))
	self.status.BackgroundTransparency = 0.08
	outline(self.status)
	self.phaseLabel = text(self.status, "Phase", "CONNECTING", 13, UDim2.new(0, 12, 0, 5), UDim2.new(0.4, 0, 0, 22), colors.cyan)
	self.timer = text(self.status, "Timer", "00:00", 23, UDim2.new(0.4, 0, 0, 10), UDim2.new(0.22, 0, 0, 36))
	self.remaining = text(self.status, "Remaining", "0 ALIVE", 14, UDim2.new(0.67, 0, 0, 10), UDim2.new(0.32, -10, 0, 36))
	self.kills = text(self.root, "Kills", "0 ELIMINATIONS", 14, UDim2.fromOffset(16, 78), UDim2.fromOffset(230, 24), colors.amber)
	self.menuButton = button(self.root, "Menu", "MENU", UDim2.new(1, -80, 0, 15), UDim2.fromOffset(68, 36), function() self:toggleMenu() end)
	self.cameraButton = button(self.root, "Camera", "CAM", UDim2.fromOffset(12, 15), UDim2.fromOffset(64, 36), callbacks.camera)

	self.vitals = frame(self.root, "Vitals", UDim2.fromOffset(255, 110), UDim2.new(0, 16, 1, -126))
	outline(self.vitals)
	self.healthLabel = text(self.vitals, "Health", "HULL 100", 16, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 24))
	local healthTrack = frame(self.vitals, "HealthTrack", UDim2.new(1, -24, 0, 8), UDim2.fromOffset(12, 38))
	healthTrack.BackgroundColor3 = colors.line
	self.healthFill = frame(healthTrack, "Fill", UDim2.fromScale(1, 1), UDim2.new())
	self.healthFill.BackgroundColor3 = colors.cyan
	self.shieldLabel = text(self.vitals, "Shield", "SHIELD 40", 13, UDim2.fromOffset(12, 56), UDim2.new(1, -24, 0, 22), colors.muted)
	local shieldTrack = frame(self.vitals, "ShieldTrack", UDim2.new(1, -24, 0, 5), UDim2.fromOffset(12, 84))
	shieldTrack.BackgroundColor3 = colors.line
	self.shieldFill = frame(shieldTrack, "Fill", UDim2.fromScale(1, 1), UDim2.new())
	self.shieldFill.BackgroundColor3 = colors.amber

	self.weapon = frame(self.root, "Weapon", UDim2.fromOffset(255, 110), UDim2.new(1, -271, 1, -126))
	outline(self.weapon)
	self.weaponName = text(self.weapon, "Name", Config.Rifle.Name, 16, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 24), colors.cyan)
	self.ammo = text(self.weapon, "Ammo", "18 / 108", 26, UDim2.fromOffset(12, 34), UDim2.new(1, -24, 0, 34))
	self.weaponHint = text(self.weapon, "Hint", "1 RIFLE    2 BLADE    R RELOAD", 11, UDim2.fromOffset(12, 77), UDim2.new(1, -24, 0, 22), colors.muted)
	self.ability = button(self.root, "Repulse", "Q // REPULSE", UDim2.new(0.5, -85, 1, -84), UDim2.fromOffset(170, 52), callbacks.ability)
	self.protection = text(self.root, "Protection", "", 15, UDim2.new(0.5, -180, 0.65, 0), UDim2.fromOffset(360, 28), colors.amber)
	self.protection.TextXAlignment = Enum.TextXAlignment.Center

	self.crosshair = frame(self.root, "Crosshair", UDim2.fromOffset(32, 32), UDim2.new(0.5, -16, 0.5, -16))
	self.crosshair.BackgroundTransparency = 1
	for _, offset in { Vector2.new(15, 4), Vector2.new(15, 23), Vector2.new(4, 15), Vector2.new(23, 15) } do
		local vertical = offset.X == 15
		local line = frame(self.crosshair, "Reticle", UDim2.fromOffset(if vertical then 2 else 6, if vertical then 6 else 2), UDim2.fromOffset(offset.X, offset.Y))
		line.BackgroundColor3 = colors.text
	end
	self.hitMarker = text(self.root, "HitMarker", "X", 28, UDim2.new(0.5, -20, 0.5, -20), UDim2.fromOffset(40, 40), colors.amber)
	self.hitMarker.TextXAlignment = Enum.TextXAlignment.Center
	self.hitMarker.Visible = false
	self.hitSerial = 0

	self.feed = frame(self.root, "EliminationFeed", UDim2.fromOffset(290, 150), UDim2.new(1, -306, 0, 160))
	self.feed.BackgroundTransparency = 1
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.Parent = self.feed
	self.lobby = frame(self.root, "LobbyCard", UDim2.fromOffset(260, 132), UDim2.fromOffset(16, 112))
	outline(self.lobby)
	self.lobbyTitle = text(self.lobby, "Title", "THE COLLAPSE", 18, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 26), colors.cyan)
	self.lobbyStatus = text(self.lobby, "Status", "Queue to enter the arena.", 13, UDim2.fromOffset(12, 37), UDim2.new(1, -24, 0, 40), colors.muted)
	self.lobbyQueue = button(self.lobby, "Queue", "JOIN QUEUE", UDim2.fromOffset(12, 84), UDim2.new(1, -24, 0, 36), function() callbacks.queue() end)

	self.mobile = frame(self.root, "TouchCombat", UDim2.fromOffset(164, 202), UDim2.new(1, -180, 0.43, 0))
	self.mobile.BackgroundTransparency = 1
	self.touchFire = button(self.mobile, "Fire", "FIRE", UDim2.fromOffset(90, 0), UDim2.fromOffset(68, 68), nil)
	self.touchFire.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self.fireInput = input; callbacks.fire(true) end
	end)
	self.touchFire.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then callbacks.fire(false) end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == self.fireInput then self.fireInput = nil; callbacks.fire(false) end
	end)
	button(self.mobile, "Reload", "RELOAD", UDim2.fromOffset(4, 76), UDim2.fromOffset(74, 44), callbacks.reload)
	button(self.mobile, "Switch", "SWAP", UDim2.fromOffset(86, 76), UDim2.fromOffset(74, 44), callbacks.switch)
	self.touchAbility = button(self.mobile, "Pulse", "REPULSE", UDim2.fromOffset(26, 128), UDim2.fromOffset(132, 48), callbacks.ability)

	self.menu = frame(self.root, "MainMenu", UDim2.fromScale(1, 1), UDim2.new())
	self.menu.BackgroundColor3 = colors.background
	self.menu.BackgroundTransparency = 0.04
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colors.background, Color3.fromRGB(21, 49, 64))
	gradient.Rotation = 30
	gradient.Parent = self.menu
	text(self.menu, "Edition", "MAYHEM X  /  ARENA COMBAT", 13, UDim2.fromScale(0.08, 0.07), UDim2.new(0.84, 0, 0, 26), colors.cyan)
	self.brand = text(self.menu, "Brand", "MAYHEM X", 68, UDim2.fromScale(0.08, 0.18), UDim2.new(0.84, 0, 0, 82))
	text(self.menu, "Tagline", "ENTER THE CHAOS. BECOME THE LEGEND.", 16, UDim2.fromScale(0.08, 0.34), UDim2.new(0.84, 0, 0, 42), colors.muted)
	self.menuCard = frame(self.menu, "Actions", UDim2.new(0.84, 0, 0, 210), UDim2.fromScale(0.08, 0.48))
	self.menuCard.BackgroundTransparency = 1
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(440, 250)
	constraint.Parent = self.menuCard
	self.mainQueue = button(self.menuCard, "Enter", "QUEUE FOR THE COLLAPSE", UDim2.new(), UDim2.new(1, 0, 0, 52), function() callbacks.queue(); self.menuOpen = false end)
	button(self.menuCard, "Settings", "SETTINGS", UDim2.fromOffset(0, 64), UDim2.new(0.48, 0, 0, 40), function() self.settingsOpen = true; self.menuOpen = false end)
	button(self.menuCard, "Close", "RETURN", UDim2.new(0.52, 0, 0, 64), UDim2.new(0.48, 0, 0, 40), function() self.menuOpen = false end)
	self.controls = text(self.menuCard, "Controls", "PC: aim at the reticle, hold click to attack.\n1/2 switch, R reload, Q Repulse, C camera, M menu.\nController: RT attack, LB swap, X reload, Y Repulse.\nD-pad down camera, D-pad left menu.", 13, UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 90), colors.muted)

	self.settings = frame(self.root, "Settings", UDim2.new(0.84, 0, 0, 290), UDim2.new(0.08, 0, 0.2, 0))
	local settingsSize = Instance.new("UISizeConstraint")
	settingsSize.MaxSize = Vector2.new(470, 320)
	settingsSize.Parent = self.settings
	outline(self.settings)
	text(self.settings, "Title", "SETTINGS", 23, UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 34), colors.cyan)
	self.settingCamera = button(self.settings, "Perspective", "CAMERA: THIRD PERSON", UDim2.fromOffset(20, 60), UDim2.new(1, -40, 0, 42), callbacks.camera)
	self.settingFov = button(self.settings, "Fov", "FIELD OF VIEW: 80", UDim2.fromOffset(20, 114), UDim2.new(1, -40, 0, 42), callbacks.fov)
	self.settingEffects = button(self.settings, "Effects", "EFFECTS: FULL", UDim2.fromOffset(20, 168), UDim2.new(1, -40, 0, 42), callbacks.effects)
	button(self.settings, "Close", "CLOSE", UDim2.fromOffset(20, 228), UDim2.new(1, -40, 0, 40), function() self.settingsOpen = false end)

	self.results = frame(self.root, "Results", UDim2.fromScale(1, 1), UDim2.new())
	self.results.BackgroundColor3 = colors.background
	self.results.BackgroundTransparency = 0.04
	self.resultTitle = text(self.results, "Title", "ROUND COMPLETE", 36, UDim2.fromScale(0.08, 0.06), UDim2.new(0.84, 0, 0, 54), colors.cyan)
	self.resultWinner = text(self.results, "Winner", "", 21, UDim2.fromScale(0.08, 0.18), UDim2.new(0.84, 0, 0, 34))
	self.resultReason = text(self.results, "Reason", "", 14, UDim2.fromScale(0.08, 0.26), UDim2.new(0.84, 0, 0, 30), colors.muted)
	local rows = Instance.new("ScrollingFrame")
	rows.Name = "Standings"
	rows.Position = UDim2.fromScale(0.08, 0.36)
	rows.Size = UDim2.fromScale(0.84, 0.43)
	rows.BackgroundColor3 = colors.panel
	rows.BorderSizePixel = 0
	rows.ScrollBarThickness = 5
	rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rows.CanvasSize = UDim2.new()
	rows.Parent = self.results
	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.Padding = UDim.new(0, 3)
	rowsLayout.Parent = rows
	self.resultRows = rows
	self.resultFooter = text(self.results, "Footer", "Returning to the lobby...", 15, UDim2.fromScale(0.08, 0.85), UDim2.new(0.84, 0, 0, 34), colors.amber)
	return self
end

function Hud.toggleMenu(self: any)
	self.settingsOpen = false
	self.menuOpen = not self.menuOpen
end

function Hud.blocked(self: any): boolean
	return self.menuOpen or self.settingsOpen
end

function Hud.hit(self: any, lethal: boolean)
	self.hitSerial += 1
	local serial = self.hitSerial
	self.hitMarker.TextColor3 = if lethal then colors.amber else colors.text
	self.hitMarker.Visible = true
	task.delay(0.18, function() if self.hitSerial == serial then self.hitMarker.Visible = false end end)
end

function Hud.addFeed(self: any, data: any)
	local message = if data.killer then data.killer .. " > " .. data.victim else data.victim .. " // " .. data.cause
	local row = text(self.feed, "Elimination", message, 13, UDim2.new(), UDim2.new(1, 0, 0, 30), colors.text)
	row.BackgroundTransparency = 0.15
	row.BackgroundColor3 = colors.panel
	row.TextXAlignment = Enum.TextXAlignment.Center
	table.insert(self.feedItems, row)
	if #self.feedItems > 4 then table.remove(self.feedItems, 1):Destroy() end
	task.delay(5, function()
		local index = table.find(self.feedItems, row)
		if index then table.remove(self.feedItems, index); row:Destroy() end
	end)
end

function Hud.render(self: any, state: any, elapsed: number, preferences: any)
	local camera = workspace.CurrentCamera
	local width = if camera then camera.ViewportSize.X else 1000
	local compact = width < 760
	local active = state.phase == "Active" and state.alive
	local overlay = self:blocked()
	local seconds = math.ceil(math.max(0, state.remaining - elapsed))
	self.phaseLabel.Text = string.upper(state.phase)
	self.phaseLabel.TextSize = if compact then 10 else 13
	self.timer.Text = string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
	self.timer.TextSize = if compact then 18 else 23
	self.remaining.Text = state.remainingPlayers .. " ALIVE"
	self.remaining.TextSize = if compact then 10 else 14
	self.kills.Text = state.kills .. " ELIMINATIONS"
	self.kills.Visible = state.inMatch and not overlay and state.phase ~= "Results"
	self.vitals.Visible = state.alive and not overlay and state.phase ~= "Results"
	self.weapon.Visible = self.vitals.Visible
	self.ability.Visible = active and not overlay and not self.touch
	self.mobile.Visible = active and not overlay and self.touch
	self.crosshair.Visible = active and not overlay
	self.protection.Visible = active and not overlay
	self.protection.Text = if state.combat.protectionRemaining > elapsed then "INSERTION SHIELD ACTIVE" else ""
	self.menu.Visible = self.menuOpen and state.phase ~= "Results"
	self.settings.Visible = self.settingsOpen and state.phase ~= "Results"
	self.results.Visible = state.phase == "Results" and state.result ~= nil
	self.lobby.Visible = not state.alive and not overlay and state.phase ~= "Results"
	self.cameraButton.Visible = not overlay and state.phase ~= "Results"
	self.menuButton.Visible = not overlay and state.phase ~= "Results"
	self.feed.Visible = not overlay and state.phase ~= "Results"
	self.lobbyStatus.Text = if state.inMatch and state.phase == "Loading" then "Preparing arena insertion..." elseif state.inMatch then "Eliminated. Next round follows this match." elseif state.queued then "Queued: " .. state.queueCount .. " players. Two needed to start." else "16 contenders. One survivor."
	self.lobbyQueue.Text = if state.inMatch then "ROUND IN PROGRESS" elseif state.queued then "LEAVE QUEUE" else "JOIN QUEUE"
	self.lobbyQueue.Active = not state.inMatch
	self.lobbyQueue.AutoButtonColor = not state.inMatch
	self.mainQueue.Text = if state.inMatch then "RETURN TO MATCH" elseif state.queued then "LEAVE QUEUE" else "QUEUE FOR THE COLLAPSE"
	self.brand.TextSize = if compact then 40 else 68
	self.controls.Text = if self.touch then "Touch: drag on the right to aim. Use the combat buttons to attack, reload, swap and cast Repulse. Use CAM to switch perspective." else "PC: hold click to attack, 1/2 switch, R reload, Q Repulse.\nC camera, M menu. Controller: RT attack, LB swap.\nX reload, Y Repulse, D-pad down camera, left menu."
	self.settingCamera.Text = "CAMERA: " .. (if preferences.firstPerson then "FIRST PERSON" else "THIRD PERSON")
	self.settingFov.Text = "FIELD OF VIEW: " .. preferences.fov
	self.settingEffects.Text = "EFFECTS: " .. (if preferences.reducedEffects then "REDUCED" else "FULL")
	local abilityRemaining = math.ceil(math.max(0, state.combat.abilityRemaining - elapsed))
	local abilityText = if abilityRemaining > 0 then "REPULSE // " .. abilityRemaining .. "s" else "Q // REPULSE"
	self.ability.Text = abilityText
	self.touchAbility.Text = if abilityRemaining > 0 then "PULSE " .. abilityRemaining .. "s" else "REPULSE"
	self.healthLabel.Text = "HULL " .. state.combat.health
	self.shieldLabel.Text = "SHIELD " .. state.combat.shield
	self.healthFill.Size = UDim2.fromScale(math.clamp(state.combat.health / Config.Character.Health, 0, 1), 1)
	self.shieldFill.Size = UDim2.fromScale(math.clamp(state.combat.shield / Config.Character.Shield, 0, 1), 1)
	local rifle = state.combat.slot == 1
	self.weaponName.Text = if rifle then Config.Rifle.Name else Config.Blade.Name
	self.ammo.Text = if state.combat.reloadRemaining > elapsed then "RELOADING" elseif rifle then state.combat.ammo .. " / " .. state.combat.reserve else "CLOSE QUARTERS"
	self.ammo.TextSize = if compact then 16 else (if rifle then 26 else 18)
	self.weaponHint.Text = if self.touch then "AIM AT THE RETICLE" else "1 RIFLE  /  2 BLADE  /  R RELOAD"
	self.vitals.Size = UDim2.fromOffset(if compact then 160 else 255, 100)
	self.weapon.Size = UDim2.fromOffset(if compact then 160 else 255, 100)
	self.vitals.Position = if self.touch then UDim2.fromOffset(12, 112) else UDim2.new(0, 16, 1, -116)
	self.weapon.Position = if self.touch then UDim2.new(1, -172, 0, 112) else UDim2.new(1, if compact then -176 else -271, 1, -116)
	self.feed.Position = UDim2.new(1, -306, 0, if self.touch then 220 else 160)
	if state.result and self.resultRound ~= state.roundId then
		self.resultRound = state.roundId
		self.resultTitle.Text = if state.result.winnerId == Players.LocalPlayer.UserId then "VICTORY" else "ROUND COMPLETE"
		self.resultTitle.TextSize = if compact then 28 else 36
		self.resultWinner.Text = state.result.winner
		self.resultReason.Text = state.result.reason
		for _, child in self.resultRows:GetChildren() do if child:IsA("TextLabel") then child:Destroy() end end
		for index, row in state.result.standings do
			local line = text(self.resultRows, "Player", string.format("  %s  //  %d ELIMINATIONS", row.name, row.kills), 14, UDim2.new(), UDim2.new(1, -10, 0, 30), if row.userId == Players.LocalPlayer.UserId then colors.cyan else colors.text)
			line.LayoutOrder = index
		end
	end
	self.resultFooter.Text = "Lobby in " .. seconds .. "s. Your queue preference is kept."
	local gamepad = UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
	local layer = if not gamepad or state.phase == "Results" then "none" elseif self.settingsOpen then "settings" elseif self.menuOpen then "menu" elseif self.lobby.Visible and not state.inMatch then "lobby" else "none"
	if self.selectionLayer ~= layer then
		self.selectionLayer = layer
		GuiService.SelectedObject = if layer == "settings" then self.settingCamera elseif layer == "menu" then self.mainQueue elseif layer == "lobby" then self.lobbyQueue else nil
	end
end

return Hud
