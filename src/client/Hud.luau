--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Config)
local Theme = require(script.Parent.Theme)
local Menus = require(script.Parent.Menus)
local Preview = require(script.Parent.Preview)
local Hud = {}
Hud.__index = Hud

function Hud.new(callbacks: any)
	local self: any = setmetatable({ callbacks = callbacks, touch = UserInputService.TouchEnabled, feedItems = {}, hitSerial = 0, resultRound = -1, tweens = {} }, Hud)
	local screen = Instance.new("ScreenGui")
	screen.Name = "MayhemHUD"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 10
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.screen = screen
	self.root = Theme.frame(screen, "Interface", UDim2.new(), UDim2.fromScale(1, 1), nil, 1)
	self.header = Theme.frame(self.root, "Telemetry", UDim2.new(0.5, -230, 0, 12), UDim2.fromOffset(460, 54), Theme.Void, 0.05)
	Theme.corner(self.header)
	Theme.stroke(self.header, Theme.Purple, 0.5)
	self.remaining = Theme.text(self.header, "Remaining", "16 ALIVE", UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.3, 0.72), 17, Theme.White, true)
	self.timer = Theme.text(self.header, "Timer", "00:00", UDim2.fromScale(0.38, 0.12), UDim2.fromScale(0.26, 0.72), 25, Theme.Cyan, true)
	self.kills = Theme.text(self.header, "Kills", "0 KILLS", UDim2.fromScale(0.72, 0.12), UDim2.fromScale(0.26, 0.72), 15, Theme.White, true)
	self.phase = Theme.text(self.root, "Mode", "LAST SIGNAL / THE COLLAPSE", UDim2.new(0.5, -200, 0, 72), UDim2.fromOffset(400, 22), 10, Theme.Muted)
	self.phase.TextXAlignment = Enum.TextXAlignment.Center
	self.menuButton = Theme.button(self.root, "Menu", "MX", UDim2.fromOffset(12, 14), UDim2.fromOffset(44, 36), function() self:toggleMenu() end)
	self.cameraButton = Theme.button(self.root, "Camera", "CAM", UDim2.new(1, -58, 0, 14), UDim2.fromOffset(46, 36), callbacks.camera, true)
	self.vitals = Theme.frame(self.root, "Vitals", UDim2.new(0, 18, 1, -142), UDim2.fromOffset(240, 124), Theme.Void, 0.04)
	Theme.corner(self.vitals)
	Theme.stroke(self.vitals)
	self.health = Theme.text(self.vitals, "Health", "100", UDim2.fromOffset(12, 6), UDim2.fromOffset(72, 32), 26, Theme.White, true)
	Theme.text(self.vitals, "Hull", "HULL", UDim2.fromOffset(83, 12), UDim2.fromOffset(65, 22), 11, Theme.Metal)
	self.healthFill = Theme.bar(self.vitals, "HealthTrack", UDim2.fromOffset(12, 42), UDim2.new(1, -24, 0, 6), Theme.Purple)
	self.shield = Theme.text(self.vitals, "Shield", "SHIELD 40", UDim2.fromOffset(12, 54), UDim2.new(1, -24, 0, 22), 11, Theme.Cyan)
	self.shieldFill = Theme.bar(self.vitals, "ShieldTrack", UDim2.fromOffset(12, 80), UDim2.new(1, -24, 0, 4), Theme.Cyan)
	self.ultimateLabel = Theme.text(self.vitals, "Ultimate", "AEGIS / 0%", UDim2.fromOffset(12, 93), UDim2.new(1, -24, 0, 17), 9, Theme.Gold)
	self.ultimateFill = Theme.bar(self.vitals, "UltimateTrack", UDim2.fromOffset(12, 114), UDim2.new(1, -24, 0, 3), Theme.Gold)
	self.weapon = Theme.frame(self.root, "Weapon", UDim2.new(1, -258, 1, -142), UDim2.fromOffset(240, 124), Theme.Void, 0.04)
	Theme.corner(self.weapon)
	Theme.stroke(self.weapon)
	self.weaponName = Theme.text(self.weapon, "Name", "VECTOR-18", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 22), 14, Theme.White, true)
	self.ammo = Theme.text(self.weapon, "Ammo", "18", UDim2.fromOffset(12, 32), UDim2.new(0.48, 0, 0, 42), 34, Theme.White, true)
	self.reserve = Theme.text(self.weapon, "Reserve", "/ 108", UDim2.new(0.49, 0, 0, 46), UDim2.new(0.42, 0, 0, 24), 14, Theme.Metal)
	self.slotHint = Theme.text(self.weapon, "Slots", "1 / VECTOR     2 / RIFT", UDim2.fromOffset(12, 92), UDim2.new(1, -24, 0, 20), 10, Theme.Cyan)
	self.ability = Theme.button(self.root, "Repulse", "Q / REPULSE", UDim2.new(0.5, -174, 1, -90), UDim2.fromOffset(164, 50), callbacks.ability)
	self.ultimate = Theme.button(self.root, "Aegis", "G / AEGIS", UDim2.new(0.5, 10, 1, -90), UDim2.fromOffset(164, 50), callbacks.ultimate, true)
	self.abilityFill = Theme.bar(self.ability, "Recharge", UDim2.new(0, 0, 1, -3), UDim2.new(1, 0, 0, 3), Theme.Cyan)
	self.protection = Theme.text(self.root, "Protection", "", UDim2.new(0.5, -160, 0.62, 0), UDim2.fromOffset(320, 24), 12, Theme.Cyan)
	self.protection.TextXAlignment = Enum.TextXAlignment.Center
	self.reality = Theme.text(self.root, "Reality", "REALITY / STABLE", UDim2.new(0.5, -180, 1, -28), UDim2.fromOffset(360, 18), 10, Theme.White)
	self.reality.TextStrokeColor3 = Theme.Void
	self.reality.TextStrokeTransparency = 0.2
	self.reality.TextXAlignment = Enum.TextXAlignment.Center
	self.crosshair = Theme.frame(self.root, "Crosshair", UDim2.new(0.5, -15, 0.5, -15), UDim2.fromOffset(30, 30), nil, 1)
	for _, offset in { Vector2.new(14, 2), Vector2.new(14, 23), Vector2.new(2, 14), Vector2.new(23, 14) } do
		Theme.frame(self.crosshair, "Reticle", UDim2.fromOffset(offset.X, offset.Y), UDim2.fromOffset(if offset.X == 14 then 2 else 5, if offset.X == 14 then 5 else 2), Theme.White, 0.15)
	end
	self.hitMarker = Theme.text(self.root, "HitMarker", "X", UDim2.new(0.5, -22, 0.5, -22), UDim2.fromOffset(44, 44), 30, Theme.Cyan, true)
	self.hitMarker.TextXAlignment = Enum.TextXAlignment.Center
	self.hitMarker.Visible = false
	self.damageLabel = Theme.text(self.root, "DamageIndicator", "", UDim2.new(0.5, -150, 0.7, 0), UDim2.fromOffset(300, 24), 15, Theme.Red, true)
	self.damageLabel.TextXAlignment = Enum.TextXAlignment.Center
	self.damageLabel.TextTransparency = 1
	self.damageFlash = Theme.frame(self.root, "DamageFlash", UDim2.new(), UDim2.fromScale(1, 1), Theme.Red, 1)
	self.damageFlash.ZIndex = 3
	self.announcement = Theme.frame(self.root, "Announcement", UDim2.new(0.5, -185, 0, 108), UDim2.fromOffset(370, 70), Theme.Void, 0.06)
	Theme.stroke(self.announcement, Theme.Purple, 0.3)
	self.announcement.Visible = false
	self.announcementTitle = Theme.text(self.announcement, "Title", "", UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 28), 17, Theme.White, true)
	self.announcementBody = Theme.text(self.announcement, "Body", "", UDim2.fromOffset(14, 36), UDim2.new(1, -28, 0, 26), 11, Theme.Metal)
	self.feed = Theme.frame(self.root, "EliminationFeed", UDim2.new(1, -310, 0, 108), UDim2.fromOffset(296, 180), nil, 1)
	local feedLayout = Instance.new("UIListLayout")
	feedLayout.Padding = UDim.new(0, 5)
	feedLayout.Parent = self.feed
	self.lobby = Theme.frame(self.root, "HubStatus", UDim2.fromOffset(16, 84), UDim2.fromOffset(250, 112), Theme.Void, 0.05)
	Theme.stroke(self.lobby, Theme.Purple)
	self.lobbyTitle = Theme.text(self.lobby, "Title", "SIGNAL HUB", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 25), 16, Theme.White, true)
	self.lobbyStatus = Theme.text(self.lobby, "Status", "", UDim2.fromOffset(12, 38), UDim2.new(1, -24, 0, 24), 11, Theme.Metal)
	Theme.button(self.lobby, "Deploy", "OPEN DEPLOYMENT", UDim2.fromOffset(12, 73), UDim2.new(1, -24, 0, 28), function() self:openPage("Matchmaking") end)
	self.mobile = Theme.frame(self.root, "TouchCombat", UDim2.new(1, -184, 0.35, 0), UDim2.fromOffset(172, 180), nil, 1)
	self.fireButton = Theme.button(self.mobile, "Attack", "FIRE", UDim2.fromOffset(104, 0), UDim2.fromOffset(64, 64), nil)
	self.fireButton.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self.fireInput = input; callbacks.fire(true) end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject) if self.fireInput == input then self.fireInput = nil; callbacks.fire(false) end end)
	Theme.button(self.mobile, "Reload", "RELOAD", UDim2.fromOffset(16, 72), UDim2.fromOffset(72, 40), callbacks.reload, true)
	Theme.button(self.mobile, "Swap", "SWAP", UDim2.fromOffset(96, 72), UDim2.fromOffset(72, 40), callbacks.switch, true)
	self.touchAbility = Theme.button(self.mobile, "Repulse", "REPULSE", UDim2.fromOffset(0, 128), UDim2.fromOffset(76, 44), callbacks.ability)
	self.touchUltimate = Theme.button(self.mobile, "Aegis", "AEGIS", UDim2.fromOffset(88, 128), UDim2.fromOffset(80, 44), callbacks.ultimate, true)
	self.loading = Theme.frame(self.root, "Insertion", UDim2.new(0.5, -150, 0.5, -95), UDim2.fromOffset(300, 190), Theme.Void, 0.03)
	Theme.stroke(self.loading, Theme.Purple, 0.3)
	Theme.text(self.loading, "Label", "SIGNAL INSERTION", UDim2.fromOffset(20, 16), UDim2.new(1, -40, 0, 22), 12, Theme.Purple, true)
	self.loadingCount = Theme.text(self.loading, "Count", "", UDim2.fromOffset(20, 46), UDim2.new(1, -40, 0, 62), 46, Theme.White, true)
	self.loadingDetail = Theme.text(self.loading, "Detail", "", UDim2.fromOffset(20, 124), UDim2.new(1, -40, 0, 48), 13, Theme.Metal)
	self.results = Theme.frame(self.root, "Results", UDim2.new(), UDim2.fromScale(1, 1), Theme.Surface, 0)
	self.results.ZIndex = 10
	self.resultTitle = Theme.text(self.results, "Title", "", UDim2.fromScale(0.08, 0.05), UDim2.new(0.84, 0, 0, 54), 40, Theme.Ink, true)
	self.resultWinner = Theme.text(self.results, "Winner", "", UDim2.fromScale(0.08, 0.18), UDim2.new(0.84, 0, 0, 38), 21, Theme.Purple, true)
	self.resultReason = Theme.text(self.results, "Reason", "", UDim2.fromScale(0.08, 0.28), UDim2.new(0.84, 0, 0, 26), 13, Theme.Muted)
	local rows = Instance.new("ScrollingFrame")
	rows.Name = "Standings"
	rows.BackgroundTransparency = 1
	rows.BorderSizePixel = 0
	rows.Position = UDim2.fromScale(0.08, 0.39)
	rows.Size = UDim2.fromScale(0.84, 0.37)
	rows.CanvasSize = UDim2.new()
	rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rows.ScrollBarThickness = 3
	rows.Parent = self.results
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.Padding = UDim.new(0, 4)
	rowLayout.Parent = rows
	self.resultRows = rows
	self.resultPreview = Preview.new(self.results)
	self.resultPreview.frame.Name = "VictoryShowcase"
	self.resultPreview.frame.Position = UDim2.fromScale(0.7, 0.3)
	self.resultPreview.frame.Size = UDim2.fromScale(0.24, 0.46)
	self.resultFooter = Theme.text(self.results, "NextRound", "", UDim2.fromScale(0.08, 0.79), UDim2.new(0.84, 0, 0, 26), 12, Theme.Muted)
	self.resultContinue = Theme.button(self.results, "Continue", "OPEN COLLECTION", UDim2.fromScale(0.08, 0.87), UDim2.new(0.84, 0, 0, 44), function() self:openPage("Inventory") end)
	self.menus = Menus.new(self.root, callbacks)
	return self
end

function Hud.openPage(self: any, page: string) self.callbacks.fire(false); self.menus:open(page) end
function Hud.closeMenus(self: any) self.menus:close() end
function Hud.toggleMenu(self: any)
	self.callbacks.fire(false)
	if self.menus.page then self.menus:close() else self.menus:open(if self.lastState and self.lastState.queued then "Matchmaking" else "Deploy") end
end
function Hud.blocked(self: any): boolean return self.menus.page ~= nil end

function Hud.announce(self: any, title: string, description: string)
	self.announcementTitle.Text = title
	self.announcementBody.Text = description
	self.announcementUntil = os.clock() + 3
end

function Hud.hit(self: any, lethal: boolean)
	self.hitSerial += 1
	local serial = self.hitSerial
	self.hitMarker.TextColor3 = if lethal then Theme.Magenta else Theme.Cyan
	self.hitMarker.Visible = true
	task.delay(0.16, function() if serial == self.hitSerial then self.hitMarker.Visible = false end end)
end

function Hud.damage(self: any, amount: number, shielded: boolean)
	self.damageLabel.Text = (if shielded then "SHIELD -" else "HULL -") .. math.ceil(amount)
	self.damageLabel.TextColor3 = if shielded then Theme.Cyan else Theme.Red
	self.damageLabel.TextTransparency = 0
	self.damageFlash.BackgroundTransparency = 0.9
	if self.damageTween then self.damageTween:Cancel() end
	self.damageTween = TweenService:Create(self.damageLabel, TweenInfo.new(0.65), { TextTransparency = 1 })
	self.damageTween:Play()
	TweenService:Create(self.damageFlash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
end

function Hud.addFeed(self: any, data: any)
	local row = Theme.frame(self.feed, "Elimination", UDim2.new(), UDim2.new(1, 0, 0, 35), Theme.Void, 0.08)
	Theme.frame(row, "Accent", UDim2.new(), UDim2.new(0, 2, 1, 0), if data.killer then Theme.Purple else Theme.Red)
	local message = if data.killer then data.killer .. "  >  " .. data.victim else data.victim .. " / " .. data.cause
	Theme.text(row, "Names", message, UDim2.fromOffset(10, 3), UDim2.new(1, -20, 1, -6), 11, Theme.White)
	table.insert(self.feedItems, row)
	if #self.feedItems > (if self.touch then 2 else 4) then table.remove(self.feedItems, 1):Destroy() end
	task.delay(5, function()
		local index = table.find(self.feedItems, row)
		if index then table.remove(self.feedItems, index); row:Destroy() end
	end)
end

function Hud.fill(self: any, key: string, item: Frame, fraction: number)
	local value = math.clamp(fraction, 0, 1)
	if self[key] == value then return end
	self[key] = value
	if self.tweens[key] then self.tweens[key]:Cancel() end
	self.tweens[key] = TweenService:Create(item, TweenInfo.new(0.12), { Size = UDim2.fromScale(value, 1) })
	self.tweens[key]:Play()
end

function Hud.render(self: any, state: any, elapsed: number, preferences: any, style: any)
	self.lastState = state
	local size = self.root.AbsoluteSize
	local camera = workspace.CurrentCamera
	if camera then
		local center = camera.ViewportSize / 2 - self.root.AbsolutePosition
		self.crosshair.Position = UDim2.fromOffset(center.X - 15, center.Y - 15)
		self.hitMarker.Position = UDim2.fromOffset(center.X - 22, center.Y - 22)
	end
	local compact = size.X < 760
	local overlay = self:blocked()
	local active = state.phase == "Active" and state.alive
	local map = state.map or { name = "THE COLLAPSE", duel = false, chaos = "STABLE", chaosRemaining = 0, safeRadius = 185, center = Vector3.zero }
	local seconds = math.ceil(math.max(0, state.remaining - elapsed))
	self.header.Size = UDim2.fromOffset(math.min(460, size.X - 128), 54)
	self.header.Position = UDim2.new(0.5, -math.min(460, size.X - 128) / 2, 0, 12)
	self.remaining.Text = state.remainingPlayers .. " ALIVE"
	self.remaining.TextSize = if compact then 11 else 17
	self.timer.Text = string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
	self.timer.TextSize = if compact then 19 else 25
	self.kills.Text = state.kills .. " KILLS"
	self.kills.TextSize = if compact then 10 else 15
	self.phase.Text = (if map.duel then "FINAL SHOWDOWN" else string.upper(state.phase)) .. " / " .. map.name
	self.phase.TextColor3 = Theme.White
	self.phase.TextStrokeColor3 = Theme.Void
	self.phase.TextStrokeTransparency = 0.2
	self.header.Visible = not overlay and state.phase ~= "Results"
	self.phase.Visible = self.header.Visible
	self.menuButton.Visible = not overlay and state.phase ~= "Results"
	self.cameraButton.Visible = self.menuButton.Visible
	self.vitals.Visible = state.alive and not overlay and state.phase ~= "Results"
	self.weapon.Visible = self.vitals.Visible
	self.vitals.Size = UDim2.fromOffset(if compact then 160 else 240, 124)
	self.weapon.Size = self.vitals.Size
	local topPanels = self.touch or size.X < 560
	self.vitals.Position = if topPanels then UDim2.fromOffset(12, 98) else UDim2.new(0, 18, 1, -142)
	self.weapon.Position = if topPanels then UDim2.new(1, if compact then -172 else -252, 0, 98) else UDim2.new(1, if compact then -178 else -258, 1, -142)
	self.health.Text = tostring(state.combat.health)
	self.shield.Text = "SHIELD " .. state.combat.shield
	self:fill("lastHealth", self.healthFill, state.combat.health / Config.Character.Health)
	self:fill("lastShield", self.shieldFill, state.combat.shield / Config.Character.Shield)
	local charge = state.combat.ultimate or 0
	self:fill("lastUltimate", self.ultimateFill, charge / 100)
	self.ultimateLabel.Text = if charge >= 100 then "AEGIS / READY" else "AEGIS / " .. charge .. "%"
	local rifle = state.combat.slot == 1
	local reloading = state.combat.reloadRemaining > elapsed
	self.weaponName.Text = if rifle then "VECTOR-18 / AUTO" else "RIFT / MELEE"
	self.ammo.Text = if reloading then "LOAD" elseif rifle then tostring(state.combat.ammo) else "RIFT"
	self.reserve.Text = if reloading then string.format("%.1fs", state.combat.reloadRemaining - elapsed) elseif rifle then "/ " .. state.combat.reserve else "BLADE"
	self.slotHint.Text = if self.touch then "SWAP / VECTOR + RIFT" elseif compact then "1 VECTOR / 2 RIFT" else "1 VECTOR / 2 RIFT / R RELOAD"
	local cooldown = math.max(0, state.combat.abilityRemaining - elapsed)
	self.ability.Visible = active and not overlay and not self.touch
	self.ultimate.Visible = self.ability.Visible
	self.ultimate.Active = active and charge >= 100
	self.ultimate.Text = if charge >= 100 then "G / AEGIS READY" else "AEGIS / " .. charge .. "%"
	self.ultimate.BackgroundColor3 = if charge >= 100 then Theme.Gold else Theme.Panel
	self.ability.Size = UDim2.fromOffset(if compact then 142 else 164, 50)
	self.ability.Position = UDim2.new(0.5, if compact then -150 else -174, 1, -90)
	self.ultimate.Size = self.ability.Size
	self.ability.Active = active and cooldown <= 0
	self.ability.Text = if cooldown > 0 then string.format("Q / REPULSE / %.1fs", cooldown) else "Q / REPULSE READY"
	self.abilityFill.Size = UDim2.fromScale(1 - cooldown / Config.Ability.Cooldown, 1)
	self.mobile.Visible = active and not overlay and self.touch
	self.fireButton.Text = if rifle then "FIRE" else "SLASH"
	self.touchAbility.Text = if cooldown > 0 then string.format("%.1fs", cooldown) else "REPULSE"
	self.touchAbility.Active = active and cooldown <= 0
	self.touchUltimate.Text = if charge >= 100 then "AEGIS" else charge .. "%"
	self.touchUltimate.Active = active and charge >= 100
	self.touchUltimate.BackgroundColor3 = if charge >= 100 then Theme.Gold else Theme.Panel
	self.crosshair.Visible = active and not overlay
	self.protection.Visible = active and not overlay
	self.protection.Text = if state.combat.protectionRemaining > elapsed then "AEGIS / PROTECTION ACTIVE" else ""
	self.reality.Visible = active and not overlay
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local offset = if root then root.Position - map.center else Vector3.zero
	local outside = Vector3.new(offset.X, 0, offset.Z).Magnitude > map.safeRadius
	self.reality.Text = if outside then "OUTSIDE SIGNAL / RETURN TO THE SAFE ZONE" elseif map.chaos ~= "STABLE" then map.chaos .. " / " .. math.ceil(math.max(0, (map.chaosRemaining or 0) - elapsed)) .. "s" else "SAFE ZONE / " .. math.ceil(map.safeRadius) .. " STUDS"
	self.reality.TextColor3 = if outside then Theme.Gold else Theme.White
	self.feed.Visible = not overlay and state.phase ~= "Results"
	self.feed.Size = UDim2.fromOffset(if topPanels then (if size.Y < 500 then 240 else 160) else 296, if topPanels then 80 else 180)
	self.feed.Position = if topPanels then (if size.Y < 500 then UDim2.new(0.5, -120, 0, 102) else UDim2.fromOffset(12, 236)) else UDim2.new(1, -310, 0, 108)
	self.announcement.Size = UDim2.fromOffset(math.min(370, size.X - 32), 70)
	self.announcement.Position = UDim2.new(0.5, -math.min(370, size.X - 32) / 2, 0, if self.touch then 236 else 108)
	self.announcement.Visible = not overlay and (self.announcementUntil or 0) > os.clock()
	self.lobby.Visible = not state.alive and not overlay and state.phase ~= "Results"
	self.lobbyTitle.Text = if state.queued then "QUEUED / LAST SIGNAL" else "SIGNAL HUB"
	self.lobbyStatus.Text = state.queueCount .. " QUEUED / " .. #Players:GetPlayers() .. " IN SERVER"
	self.loading.Visible = state.inMatch and (state.phase == "Loading" or state.phase == "Countdown") and not overlay
	self.loadingCount.Text = if state.phase == "Countdown" then string.format("%02d", seconds) else "SYNC"
	self.loadingDetail.Text = map.name .. "\n" .. (if state.phase == "Countdown" then "Hold position. Protection follows release." else "Preparing character and combat loadout.")
	self.results.Visible = state.phase == "Results" and state.result ~= nil and not overlay
	if state.result and self.resultRound ~= state.roundId then
		self.resultRound = state.roundId
		local win = state.result.winnerId == Players.LocalPlayer.UserId
		local canceled = state.result.reason:find("canceled", 1, true) ~= nil
		self.resultTitle.Text = if canceled then "SIGNAL ABORTED" elseif win then "SIGNAL SECURED" elseif not state.result.winnerId then "ROUND DRAW" elseif state.inMatch then "SIGNAL LOST" else "MATCH COMPLETE"
		self.resultTitle.TextColor3 = if win then Theme.Purple elseif state.result.winnerId then Theme.Magenta else Theme.Ink
		self.resultTitle.TextSize = if compact then 28 else 40
		self.resultWinner.Text = if win then "VICTORY / " .. state.result.winner else "FINAL SIGNAL / " .. state.result.winner
		self.resultReason.Text = state.result.reason .. " / YOUR ELIMINATIONS: " .. state.kills
		for _, child in self.resultRows:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
		for index, entry in state.result.standings do
			local row = Theme.frame(self.resultRows, "Contender", UDim2.new(), UDim2.new(1, -8, 0, 34), Theme.Panel)
			row.LayoutOrder = index
			Theme.text(row, "Name", entry.name, UDim2.fromOffset(12, 2), UDim2.new(0.68, -12, 1, -4), 13, if entry.userId == Players.LocalPlayer.UserId then Theme.Purple else Theme.Ink)
			Theme.text(row, "Kills", entry.kills .. " KILLS", UDim2.fromScale(0.74, 0), UDim2.fromScale(0.25, 1), 11, Theme.Muted)
		end
		if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then GuiService.SelectedObject = self.resultContinue end
	end
	self.resultFooter.Text = "Lobby reset in " .. seconds .. "s. Your queue preference is kept."
	self.resultPreview.frame.Visible = self.results.Visible and not compact
	self.resultRows.Size = UDim2.fromScale(if compact then 0.84 else 0.57, 0.37)
	if self.resultPreview.frame.Visible then
		self.resultPreview:show("operative", style.operative, style.skin)
		self.resultPreview:step(preferences.reducedMotion)
	else self.resultPreview:hide() end
	self.menus:render(state, elapsed, preferences, style)
end

return Hud
