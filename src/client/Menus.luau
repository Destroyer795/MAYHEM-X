--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local Menus = {}
Menus.__index = Menus

function Menus.new(parent: Instance, callbacks: any)
	local self: any = setmetatable({ callbacks = callbacks, page = nil, pages = {}, navigation = {}, draftSkin = "Pulse", draftOperative = "Vanguard", weapon = 1, serial = 0 }, Menus)
	local group = Instance.new("CanvasGroup")
	group.Name = "Navigation"
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundColor3 = Theme.Void
	group.BackgroundTransparency = 0.08
	group.ZIndex = 20
	group.Visible = false
	group.Parent = parent
	self.group = group
	self.logo = Theme.text(group, "Logo", "MAYHEM X", UDim2.fromOffset(24, 14), UDim2.new(0.6, 0, 0, 40), 26, Theme.White, true)
	self.closeButton = Theme.button(group, "Close", "RETURN  /  M", UDim2.new(1, -154, 0, 18), UDim2.fromOffset(130, 32), function() self:close() end, true)
	local line = Theme.frame(group, "HeaderRule", UDim2.new(0, 24, 0, 66), UDim2.new(1, -48, 0, 1), Theme.Purple, 0.45)
	local nav = Instance.new("ScrollingFrame")
	nav.Name = "Sections"
	nav.BackgroundTransparency = 1
	nav.BorderSizePixel = 0
	nav.ScrollBarThickness = 2
	nav.CanvasSize = UDim2.new()
	nav.AutomaticCanvasSize = Enum.AutomaticSize.X
	nav.ScrollingDirection = Enum.ScrollingDirection.X
	nav.Parent = group
	self.nav = nav
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.Parent = nav
	for index, definition in { { "Deploy", "01 / DEPLOY" }, { "Character", "02 / OPERATIVE" }, { "Inventory", "03 / COLLECTION" }, { "Shop", "04 / STYLE LAB" }, { "Daily", "05 / DAILY CACHE" }, { "Settings", "06 / SYSTEMS" } } do
		local item = Theme.button(nav, definition[1], definition[2], UDim2.new(), UDim2.fromOffset(145, 36), function() self:open(definition[1]) end, true)
		item.LayoutOrder = index
		self.navigation[definition[1]] = item
	end
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.CanvasSize = UDim2.new()
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.ScrollBarThickness = 3
	content.Parent = group
	self.content = content
	self.footer = Theme.text(group, "Feedback", "SESSION COLLECTION / COSMETICS ONLY / NO PAID ADVANTAGE", UDim2.new(0, 24, 1, -42), UDim2.new(1, -48, 0, 30), 11, Theme.Muted)
	local function page(name: string): Frame
		local area = Theme.frame(self.content, name, UDim2.new(), UDim2.fromScale(1, 1), nil, 1)
		area.Visible = false
		self.pages[name] = area
		return area
	end
	local deploy = page("Deploy")
	Theme.text(deploy, "Eyebrow", "PVP / THE FLOATING FRONTIER", UDim2.new(), UDim2.new(0.65, 0, 0, 22), 11, Theme.Cyan)
	self.hero = Theme.text(deploy, "Title", "THE\nCOLLAPSE", UDim2.fromOffset(0, 28), UDim2.new(0.62, 0, 0, 124), 58, Theme.White, true)
	self.deployDescription = Theme.text(deploy, "Description", "Enter the arena. Break the signal.\nBecome the last contender standing.", UDim2.fromOffset(0, 158), UDim2.new(0.52, 0, 0, 68), 16, Theme.Muted)
	self.modeButton = Theme.button(deploy, "Mode", "LAST SIGNAL  /  SOLO SURVIVAL  >", UDim2.new(0, 0, 1, -130), UDim2.new(0.52, 0, 0, 52), function() self:open("Mode") end, true)
	self.play = Theme.button(deploy, "Play", "PLAY  /  JOIN QUEUE", UDim2.new(0, 0, 1, -62), UDim2.new(0.52, 0, 0, 54), function()
		if self.state and not self.state.queued and not self.state.inMatch then callbacks.queue() end
		self:open("Matchmaking")
	end)
	self.preview = Preview.new(deploy)
	self.previewCaption = Theme.text(deploy, "PreviewCaption", "VANGUARD / PULSE", UDim2.new(0.56, 0, 1, -70), UDim2.new(0.44, 0, 0, 30), 12, Theme.Purple)
	self.online = Theme.text(deploy, "Online", "", UDim2.new(0.56, 0, 1, -35), UDim2.new(0.44, 0, 0, 26), 11, Theme.Muted)

	local mode = page("Mode")
	Theme.text(mode, "Title", "LAST SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 56), 32, Theme.White, true)
	Theme.text(mode, "Description", Visuals.Mode.Description .. "\n\nThis is the available game mode. Operatives and finishes change appearance only.", UDim2.fromOffset(0, 72), UDim2.new(0.9, 0, 0, 148), 17, Theme.Muted)
	Theme.button(mode, "Select", "SELECT LAST SIGNAL", UDim2.new(0, 0, 1, -56), UDim2.new(0.75, 0, 0, 48), function() self:open("Deploy") end)

	local matchmaking = page("Matchmaking")
	Theme.text(matchmaking, "Title", "FIND YOUR SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.White, true)
	self.queueTitle = Theme.text(matchmaking, "Status", "WAITING FOR SERVER", UDim2.fromOffset(0, 62), UDim2.new(1, 0, 0, 50), 24, Theme.Purple, true)
	self.queueDetail = Theme.text(matchmaking, "Detail", "", UDim2.fromOffset(0, 130), UDim2.new(0.9, 0, 0, 95), 17, Theme.Muted)
	self.queueTimer = Theme.text(matchmaking, "Clock", "", UDim2.new(0, 0, 1, -128), UDim2.new(1, 0, 0, 44), 28, Theme.Cyan, true)
	self.queueCancel = Theme.button(matchmaking, "Queue", "LEAVE QUEUE", UDim2.new(0, 0, 1, -58), UDim2.new(0.62, 0, 0, 48), callbacks.queue)
	Theme.button(matchmaking, "Observe", "VIEW HUB", UDim2.new(0.66, 0, 1, -58), UDim2.new(0.34, 0, 0, 48), function() self:close() end, true)

	local character = page("Character")
	Theme.text(character, "Title", "OPERATIVE", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.White, true)
	self.operativeButtons = {}
	for index, entry in Visuals.Operatives do
		self.operativeButtons[entry.id] = Theme.button(character, entry.id, entry.name, UDim2.fromOffset(0, 54 + (index - 1) * 48), UDim2.new(0.5, -8, 0, 40), function() self.draftOperative = entry.id end, true)
	end
	self.operativeDetail = Theme.text(character, "Detail", "", UDim2.fromOffset(0, 210), UDim2.new(0.5, -8, 0, 80), 14, Theme.Muted)
	self.equipOperative = Theme.button(character, "Equip", "EQUIP PROFILE", UDim2.new(0, 0, 1, -54), UDim2.new(0.5, -8, 0, 46), function() callbacks.select("operative", self.draftOperative) end)
	self.characterPreview = Preview.new(character)
	self.characterPreview.frame.Position = UDim2.fromScale(0.53, 0.12)
	self.characterPreview.frame.Size = UDim2.fromScale(0.47, 0.72)

	local inventory = page("Inventory")
	Theme.text(inventory, "Title", "COLLECTION", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.White, true)
	self.rifleTab = Theme.button(inventory, "Rifle", "VECTOR-18", UDim2.fromOffset(0, 50), UDim2.new(0.24, 0, 0, 34), function() self.weapon = 1 end, true)
	self.bladeTab = Theme.button(inventory, "Blade", "RIFT BLADE", UDim2.new(0.26, 0, 0, 50), UDim2.new(0.24, 0, 0, 34), function() self.weapon = 2 end, true)
	self.skinButtons = {}
	for index, entry in Visuals.Skins do
		local item = Theme.button(inventory, entry.id, entry.name, UDim2.fromOffset(0, 96 + (index - 1) * 38), UDim2.new(0.5, -8, 0, 30), function() self.draftSkin = entry.id end, true)
		self.skinButtons[entry.id] = item
	end
	self.weaponPreview = Preview.new(inventory)
	self.weaponPreview.frame.Position = UDim2.fromScale(0.53, 0.13)
	self.weaponPreview.frame.Size = UDim2.fromScale(0.47, 0.63)
	self.equipSkin = Theme.button(inventory, "Equip", "EQUIP FINISH", UDim2.new(0, 0, 1, -54), UDim2.new(0.5, -8, 0, 46), function()
		if self.style and self.style.owned[self.draftSkin] then callbacks.select("skin", self.draftSkin) else self:open(if self.draftSkin == "Prism" then "Daily" else "Shop") end
	end)
	self.inventoryNote = Theme.text(inventory, "Note", "Both weapons stay in your loadout. Finishes change appearance only.", UDim2.new(0.53, 0, 1, -85), UDim2.new(0.47, 0, 0, 75), 12, Theme.Muted)

	local shop = page("Shop")
	Theme.text(shop, "Title", "STYLE LAB", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.White, true)
	Theme.text(shop, "Subtitle", "COMPLIMENTARY / SERVER SESSION / NO ROBUX", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 0, 36), 11, Theme.Cyan)
	self.shopButtons = {}
	for index, id in { "Orchid", "Ember" } do
		local entry = Visuals.skin(id)
		local card = Theme.frame(shop, id, UDim2.new((index - 1) * 0.51, 0, 0, 100), UDim2.new(0.49, 0, 1, -112), Theme.Panel)
		Theme.stroke(card)
		Theme.frame(card, "Swatch", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 48), Color3.fromRGB(table.unpack(entry.color)))
		Theme.text(card, "Name", entry.name, UDim2.fromOffset(18, 80), UDim2.new(1, -36, 0, 48), 16, Theme.White, true)
		Theme.text(card, "Description", entry.description, UDim2.fromOffset(18, 134), UDim2.new(1, -36, 0, 70), 12, Theme.Muted)
		self.shopButtons[id] = Theme.button(card, "Claim", "CLAIM STYLE", UDim2.new(0, 18, 1, -64), UDim2.new(1, -36, 0, 46), function()
			if self.style and self.style.owned[id] then callbacks.select("skin", id) else callbacks.claim(id) end
		end)
	end

	local daily = page("Daily")
	Theme.text(daily, "Title", "DAILY CACHE", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.White, true)
	Theme.frame(daily, "PrismSwatch", UDim2.fromOffset(0, 66), UDim2.new(1, 0, 0, 4), Theme.Cyan)
	Theme.text(daily, "Reward", "PRISM / WHITE", UDim2.fromOffset(0, 92), UDim2.new(1, 0, 0, 40), 24, Theme.White, true)
	Theme.text(daily, "Scope", "Claim the Prism finish for this server session.\nOne claim per UTC day while in this server. Collection items are not saved after leaving.", UDim2.fromOffset(0, 150), UDim2.new(0.9, 0, 0, 100), 16, Theme.Muted)
	self.dailyClock = Theme.text(daily, "Clock", "", UDim2.new(0, 0, 1, -112), UDim2.new(1, 0, 0, 34), 14, Theme.Cyan)
	self.dailyButton = Theme.button(daily, "Claim", "CLAIM SESSION TRIAL", UDim2.new(0, 0, 1, -58), UDim2.new(0.78, 0, 0, 48), function()
		if self.style and self.style.dailyClaimed then self:open("Inventory"); self.draftSkin = "Prism" else callbacks.daily() end
	end)

	local settings = page("Settings")
	Theme.text(settings, "Title", "SYSTEMS", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.White, true)
	self.settingButtons = {}
	for index, definition in { { "camera", callbacks.camera }, { "fov", callbacks.fov }, { "graphics", callbacks.graphics }, { "effects", callbacks.effects }, { "music", callbacks.music }, { "sound", callbacks.sound }, { "motion", callbacks.motion } } do
		local item = Theme.button(settings, definition[1], "", UDim2.fromOffset(0, 54 + (index - 1) * 40), UDim2.new(1, 0, 0, 34), definition[2], true)
		self.settingButtons[definition[1]] = item
	end
	self.audioNote = Theme.text(settings, "AudioNote", "Audio routes are ready. No licensed sound assets are configured.", UDim2.new(0, 0, 1, -32), UDim2.new(1, 0, 0, 30), 11, Theme.Muted)
	self:open("Deploy")
	return self
end

function Menus.open(self: any, page: string)
	if not self.pages[page] then return end
	self.serial += 1
	self.page = page
	self.content.CanvasPosition = Vector2.zero
	self.group.Visible = true
	if self.fade then self.fade:Cancel() end
	self.group.GroupTransparency = 0.15
	self.fade = TweenService:Create(self.group, TweenInfo.new(0.18), { GroupTransparency = 0 })
	self.fade:Play()
	for name, item in self.pages do item.Visible = name == page end
	for name, item in self.navigation do item.BackgroundColor3 = if name == page then Theme.Purple else Theme.Panel end
	self.preview:hide()
	self.characterPreview:hide()
	self.weaponPreview:hide()
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		GuiService.SelectedObject = if page == "Deploy" then self.play elseif page == "Matchmaking" then self.queueCancel else self.navigation[page] or self.closeButton
	end
end

function Menus.close(self: any)
	self.serial += 1
	local serial = self.serial
	self.page = nil
	GuiService.SelectedObject = nil
	if self.fade then self.fade:Cancel() end
	self.fade = TweenService:Create(self.group, TweenInfo.new(0.14), { GroupTransparency = 1 })
	self.fade:Play()
	task.delay(0.14, function()
		if self.serial == serial then
			self.group.Visible = false
			self.preview:hide(); self.characterPreview:hide(); self.weaponPreview:hide()
		end
	end)
end

function Menus.render(self: any, state: any, elapsed: number, preferences: any, style: any)
	if not self.page then return end
	self.style = style
	self.state = state
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 and (not GuiService.SelectedObject or not GuiService.SelectedObject:IsDescendantOf(self.group)) then
		GuiService.SelectedObject = if self.page == "Deploy" then self.play elseif self.page == "Matchmaking" then self.queueCancel else self.navigation[self.page] or self.closeButton
	end
	local width = self.group.AbsoluteSize.X
	local height = self.group.AbsoluteSize.Y
	local compact = width < 640
	local short = height < 540
	self.logo.TextSize = if compact then 21 else 26
	self.closeButton.Size = UDim2.fromOffset(if compact then 100 else 130, 32)
	self.closeButton.Position = UDim2.new(1, if compact then -116 else -154, 0, 18)
	self.nav.Position = UDim2.fromOffset(24, 78)
	self.nav.Size = UDim2.new(1, -48, 0, 38)
	self.content.Position = UDim2.fromOffset(24, 128)
	self.content.Size = UDim2.new(1, -48, 1, -176)
	for _, area in self.pages do area.Size = UDim2.new(1, -8, 0, math.max(400, self.content.AbsoluteSize.Y)) end
	self.hero.TextSize = if compact then 36 elseif short then 40 else 58
	self.hero.Size = UDim2.new(0.62, 0, 0, if short then 88 else 124)
	self.deployDescription.Position = UDim2.fromOffset(0, if short then 116 else 158)
	self.deployDescription.TextSize = if compact or short then 13 else 16
	self.deployDescription.Visible = not short
	self.preview.frame.Position = UDim2.fromScale(if compact then 0.65 else 0.56, 0.03)
	self.preview.frame.Size = UDim2.fromScale(if compact then 0.35 else 0.44, if compact then 0.38 else 0.72)
	self.modeButton.Size = UDim2.new(if compact then 1 else 0.52, 0, 0, 46)
	self.play.Size = UDim2.new(if compact then 1 else 0.52, 0, 0, 54)
	self.previewCaption.Visible = not compact and not short
	self.online.Visible = not compact and not short
	self.online.Text = #Players:GetPlayers() .. " IN SERVER / 16 CONTENDERS PER ROUND"
	self.previewCaption.Text = string.upper(style.operative .. " / " .. style.skin)
	self.play.Text = if state.inMatch then "VIEW MATCH STATUS" elseif state.queued then "VIEW QUEUE" else "PLAY  /  JOIN QUEUE"
	self.play.Active = true
	self.footer.Text = style.notice or "SESSION COLLECTION / COSMETICS ONLY / NO PAID ADVANTAGE"
	local seconds = math.ceil(math.max(0, state.remaining - elapsed))
	self.queueTitle.Text = if state.inMatch then string.upper(state.phase) elseif state.queued then "YOU ARE IN THE QUEUE" else "READY TO QUEUE"
	self.queueDetail.Text = if state.inMatch then (if state.alive then "Insertion confirmed. Your combat loadout is ready." else "The current round is in progress. Watch from the hub until results.") else state.queueCount .. " QUEUED / " .. #Players:GetPlayers() .. " IN SERVER\nTwo contenders are needed. Up to sixteen enter each round."
	self.queueTimer.Text = if seconds > 0 then string.format("%02d:%02d / %s", math.floor(seconds / 60), seconds % 60, string.upper(state.phase)) else "AWAITING CONTENDERS"
	self.queueCancel.Text = if state.inMatch then "ROUND LOCKED" elseif state.queued then "LEAVE QUEUE" else "JOIN QUEUE"
	self.queueCancel.Active = not state.inMatch
	for id, item in self.operativeButtons do item.BackgroundColor3 = if id == self.draftOperative then Theme.Purple else Theme.Panel end
	self.operativeDetail.Text = (Visuals.operative(self.draftOperative) or Visuals.Operatives[1]).description
	self.operativeDetail.Visible = not short
	self.equipOperative.Text = if style.operative == self.draftOperative then "EQUIPPED" else "EQUIP PROFILE"
	self.equipOperative.Active = style.ready
	for id, item in self.skinButtons do
		item.Text = (if style.owned[id] then "" else "LOCKED / ") .. Visuals.skin(id).name
		item.TextSize = if compact then 10 else 12
		item.BackgroundColor3 = if id == self.draftSkin then Theme.Purple else Theme.Panel
	end
	self.equipSkin.Text = if not style.owned[self.draftSkin] then "UNLOCK STYLE" elseif style.skin == self.draftSkin then "EQUIPPED" else "EQUIP FINISH"
	self.equipSkin.Active = style.ready
	self.rifleTab.BackgroundColor3 = if self.weapon == 1 then Theme.Purple else Theme.Panel
	self.bladeTab.BackgroundColor3 = if self.weapon == 2 then Theme.Purple else Theme.Panel
	for id, item in self.shopButtons do item.Text = if style.owned[id] then "EQUIP STYLE" else "CLAIM / FREE"; item.Active = style.ready end
	self.dailyButton.Text = if style.dailyClaimed then "VIEW PRISM IN COLLECTION" else "CLAIM SESSION TRIAL"
	self.dailyButton.Active = style.ready
	local untilReset = math.max(0, (style.nextDaily or 0) - os.time())
	self.dailyClock.Text = if style.dailyClaimed then string.format("NEXT UTC RESET / %02dh %02dm", math.floor(untilReset / 3600), math.floor(untilReset % 3600 / 60)) else "AVAILABLE / A SERVER SESSION COSMETIC"
	local buttons = self.settingButtons
	buttons.camera.Text = "CAMERA / " .. (if preferences.firstPerson then "FIRST PERSON" else "THIRD PERSON")
	buttons.fov.Text = "FIELD OF VIEW / " .. preferences.fov
	buttons.graphics.Text = "GRAPHICS / " .. preferences.graphics
	buttons.effects.Text = "COMBAT EFFECTS / " .. (if preferences.reducedEffects then "REDUCED" else "FULL")
	buttons.music.Text = "MUSIC / " .. math.floor(preferences.music * 100) .. "%"
	buttons.sound.Text = "SOUND / " .. math.floor(preferences.sound * 100) .. "%"
	buttons.motion.Text = "ENVIRONMENT MOTION / " .. (if preferences.reducedMotion then "REDUCED" else "FULL")
	if self.page == "Deploy" then self.preview:show("operative", style.operative, style.skin)
	elseif self.page == "Character" then self.characterPreview:show("operative", self.draftOperative, style.skin)
	elseif self.page == "Inventory" then self.weaponPreview:show("weapon", style.operative, self.draftSkin, self.weapon) end
	if short then
		for index, item in { buttons.camera, buttons.fov, buttons.graphics, buttons.effects, buttons.music, buttons.sound, buttons.motion } do
			item.Position = UDim2.new(if index > 4 then 0.51 else 0, 0, 0, 48 + ((index - 1) % 4) * 38)
			item.Size = UDim2.new(0.49, 0, 0, 32)
		end
	else
		for index, item in { buttons.camera, buttons.fov, buttons.graphics, buttons.effects, buttons.music, buttons.sound, buttons.motion } do
			item.Position = UDim2.fromOffset(0, 54 + (index - 1) * 40)
			item.Size = UDim2.new(1, 0, 0, 34)
		end
	end
end

return Menus
