--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Catalog = require(game:GetService("ReplicatedStorage").Mayhem.Shared.MapCatalog)
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local Menus = {}
Menus.__index = Menus

function Menus.new(parent: Instance, callbacks: any)
	local self: any = setmetatable({ callbacks = callbacks, page = nil, pages = {}, navigation = {}, draftSkin = "Pulse", draftOperative = "Vanguard", draftMap = "Collapse", weapon = 1, serial = 0 }, Menus)
	local group = Instance.new("CanvasGroup")
	group.Name = "Navigation"
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundColor3 = Theme.Surface
	group.BackgroundTransparency = 0
	group.ZIndex = 20
	group.Visible = false
	group.Parent = parent
	self.group = group
	self.logo = Theme.text(group, "Logo", "MAYHEM X", UDim2.fromOffset(24, 14), UDim2.new(0.6, 0, 0, 40), 26, Theme.Ink, true)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Theme.Purple, Theme.Violet)
	gradient.Parent = self.logo
	self.brandGradient = gradient
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
	for index, definition in { { "Deploy", "01 / PLAY" }, { "Maps", "02 / ARENAS" }, { "Character", "03 / OPERATIVE" }, { "Inventory", "04 / COLLECTION" }, { "Shop", "05 / STYLE LAB" }, { "Daily", "06 / DAILY CACHE" }, { "Settings", "07 / SYSTEMS" } } do
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
	Theme.text(deploy, "Eyebrow", "FIVE WORLDS / ONE FINAL SIGNAL", UDim2.new(), UDim2.new(0.65, 0, 0, 22), 11, Theme.Purple)
	self.hero = Theme.text(deploy, "Title", "ENTER THE\nCHAOS.", UDim2.fromOffset(0, 28), UDim2.new(0.62, 0, 0, 124), 58, Theme.Ink, true)
	self.deployDescription = Theme.text(deploy, "Description", "BECOME THE LEGEND.\nVote for your arena. Outlast every contender.", UDim2.fromOffset(0, 158), UDim2.new(0.52, 0, 0, 68), 16, Theme.Muted)
	self.mapLink = Theme.button(deploy, "ArenaInfo", "EXPLORE FIVE ARENAS  >", UDim2.fromOffset(0, 238), UDim2.new(0.52, 0, 0, 38), function() self:open("Maps") end, true)
	self.profile = Theme.text(deploy, "Profile", "", UDim2.fromOffset(0, 288), UDim2.new(0.52, 0, 0, 54), 12, Theme.Muted)
	self.modeButton = Theme.button(deploy, "Mode", "LAST SIGNAL  /  SOLO SURVIVAL  >", UDim2.new(0, 0, 1, -130), UDim2.new(0.52, 0, 0, 52), function() self:open("Mode") end, true)
	self.play = Theme.button(deploy, "Play", "PLAY  /  JOIN QUEUE", UDim2.new(0, 0, 1, -62), UDim2.new(0.52, 0, 0, 54), function()
		if self.state and not self.state.queued and not self.state.inMatch then callbacks.queue() end
		self:open("Matchmaking")
	end)
	self.preview = Preview.new(deploy)
	self.previewCaption = Theme.text(deploy, "PreviewCaption", "VANGUARD / PULSE", UDim2.new(0.56, 0, 1, -70), UDim2.new(0.44, 0, 0, 30), 12, Theme.Purple)
	self.online = Theme.text(deploy, "Online", "", UDim2.new(0.56, 0, 1, -35), UDim2.new(0.44, 0, 0, 26), 11, Theme.Muted)

	local maps = page("Maps")
	Theme.text(maps, "Title", "CHOOSE YOUR FRONTIER", UDim2.new(), UDim2.new(1, 0, 0, 40), 27, Theme.Ink, true)
	self.voteStatus = Theme.text(maps, "VoteStatus", "", UDim2.fromOffset(0, 44), UDim2.new(1, 0, 0, 40), 12, Theme.Muted)
	self.mapButtons = {}
	for index, entry in Catalog do
		local button = Theme.button(maps, entry.id, entry.name, UDim2.fromOffset(0, 96 + (index - 1) * 54), UDim2.new(0.44, -12, 0, 46), function() self.draftMap = entry.id end, true)
		self.mapButtons[entry.id] = button
	end
	self.mapPreview = Preview.new(maps)
	self.mapPreview.frame.Name = "ArenaPreview"
	self.mapPreview.frame.Position = UDim2.fromScale(0.46, 0.17)
	self.mapPreview.frame.Size = UDim2.fromScale(0.54, 0.46)
	self.mapSubtitle = Theme.text(maps, "MapSubtitle", "", UDim2.new(0.46, 0, 0.66, 0), UDim2.new(0.54, 0, 0, 30), 12, Theme.Purple, true)
	self.mapStrategy = Theme.text(maps, "MapStrategy", "", UDim2.new(0.46, 0, 0.73, 0), UDim2.new(0.54, 0, 0, 70), 13, Theme.Muted)
	self.voteButton = Theme.button(maps, "Vote", "VOTE FOR THIS ARENA", UDim2.new(0, 0, 1, -54), UDim2.new(1, 0, 0, 46), function() callbacks.vote(self.draftMap) end)

	local mode = page("Mode")
	Theme.text(mode, "Title", "LAST SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 56), 32, Theme.Ink, true)
	Theme.text(mode, "Description", Visuals.Mode.Description .. "\n\nThis is the available game mode. Operatives and finishes change appearance only.", UDim2.fromOffset(0, 72), UDim2.new(0.9, 0, 0, 148), 17, Theme.Muted)
	Theme.button(mode, "Select", "SELECT LAST SIGNAL", UDim2.new(0, 0, 1, -56), UDim2.new(0.75, 0, 0, 48), function() self:open("Deploy") end)

	local matchmaking = page("Matchmaking")
	Theme.text(matchmaking, "Title", "FIND YOUR SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.Ink, true)
	self.queueTitle = Theme.text(matchmaking, "Status", "WAITING FOR SERVER", UDim2.fromOffset(0, 62), UDim2.new(1, 0, 0, 50), 24, Theme.Purple, true)
	self.queueDetail = Theme.text(matchmaking, "Detail", "", UDim2.fromOffset(0, 130), UDim2.new(0.9, 0, 0, 95), 17, Theme.Muted)
	Theme.button(matchmaking, "ChooseMap", "MAP BALLOT  >", UDim2.fromOffset(0, 244), UDim2.new(0.62, 0, 0, 42), function() self:open("Maps") end, true)
	self.queueTimer = Theme.text(matchmaking, "Clock", "", UDim2.new(0, 0, 1, -128), UDim2.new(1, 0, 0, 44), 28, Theme.Cyan, true)
	self.queueCancel = Theme.button(matchmaking, "Queue", "LEAVE QUEUE", UDim2.new(0, 0, 1, -58), UDim2.new(0.62, 0, 0, 48), callbacks.queue)
	Theme.button(matchmaking, "Observe", "VIEW HUB", UDim2.new(0.66, 0, 1, -58), UDim2.new(0.34, 0, 0, 48), function() self:close() end, true)

	local character = page("Character")
	Theme.text(character, "Title", "OPERATIVE", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.Ink, true)
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
	Theme.text(inventory, "Title", "COLLECTION", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.Ink, true)
	self.rifleTab = Theme.button(inventory, "Rifle", "VECTOR-18", UDim2.fromOffset(0, 50), UDim2.new(0.24, 0, 0, 34), function() self.weapon = 1 end, true)
	self.bladeTab = Theme.button(inventory, "Blade", "RIFT BLADE", UDim2.new(0.26, 0, 0, 50), UDim2.new(0.24, 0, 0, 34), function() self.weapon = 2 end, true)
	self.skinButtons = {}
	for index, entry in Visuals.Skins do
		local item = Theme.button(inventory, entry.id, entry.name, UDim2.fromOffset(0, 96 + (index - 1) * 46), UDim2.new(0.5, -8, 0, 44), function() self.draftSkin = entry.id end, true)
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
	Theme.text(shop, "Title", "STYLE LAB", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.Ink, true)
	self.shopWallet = Theme.text(shop, "Wallet", "", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 0, 44), 12, Theme.Muted)
	self.shopButtons = {}
	self.shopCards = {}
	for index, id in { "Orchid", "Ember", "Aurum" } do
		local entry = Visuals.skin(id)
		local card = Theme.frame(shop, id, UDim2.new((index - 1) / 3, 0, 0, 100), UDim2.new(1 / 3, -12, 0, 310), Theme.Panel)
		self.shopCards[index] = card
		Theme.corner(card)
		Theme.stroke(card)
		Theme.frame(card, "Swatch", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 48), Color3.fromRGB(table.unpack(entry.color)))
		Theme.text(card, "Name", entry.name, UDim2.fromOffset(18, 80), UDim2.new(1, -36, 0, 48), 16, Theme.Ink, true)
		Theme.text(card, "Description", entry.description, UDim2.fromOffset(18, 134), UDim2.new(1, -36, 0, 70), 12, Theme.Muted)
		self.shopButtons[id] = Theme.button(card, "Claim", "CLAIM STYLE", UDim2.new(0, 18, 1, -64), UDim2.new(1, -36, 0, 46), function()
			if self.style and self.style.owned[id] then callbacks.select("skin", id)
			elseif id == "Aurum" then self:confirmPurchase(id)
			else callbacks.claim(id) end
		end)
	end

	local daily = page("Daily")
	Theme.text(daily, "Title", "DAILY CACHE", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.Ink, true)
	Theme.frame(daily, "PrismSwatch", UDim2.fromOffset(0, 66), UDim2.new(1, 0, 0, 4), Theme.Cyan)
	Theme.text(daily, "Reward", "PRISM + 15 SESSION CREDITS", UDim2.fromOffset(0, 92), UDim2.new(1, 0, 0, 50), 23, Theme.Ink, true)
	Theme.text(daily, "Scope", "A white finish and credits for this server session.\nOne claim per UTC day while in this server. Collection, credits and progression reset after leaving.", UDim2.fromOffset(0, 154), UDim2.new(0.9, 0, 0, 110), 16, Theme.Muted)
	self.dailyClock = Theme.text(daily, "Clock", "", UDim2.new(0, 0, 1, -112), UDim2.new(1, 0, 0, 34), 14, Theme.Cyan)
	self.dailyButton = Theme.button(daily, "Claim", "CLAIM SESSION TRIAL", UDim2.new(0, 0, 1, -58), UDim2.new(0.78, 0, 0, 48), function()
		if self.style and self.style.dailyClaimed then self:open("Inventory"); self.draftSkin = "Prism" else callbacks.daily() end
	end)

	local settings = page("Settings")
	Theme.text(settings, "Title", "SYSTEMS", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.Ink, true)
	self.settingButtons = {}
	for index, definition in { { "camera", callbacks.camera }, { "fov", callbacks.fov }, { "graphics", callbacks.graphics }, { "effects", callbacks.effects }, { "motion", callbacks.motion }, { "music", callbacks.music }, { "sound", callbacks.sound }, { "ui", callbacks.ui }, { "mute", callbacks.mute }, { "testAudio", callbacks.testAudio } } do
		local item = Theme.button(settings, definition[1], "", UDim2.fromOffset(0, 54 + (index - 1) * 48), UDim2.new(1, 0, 0, 42), definition[2], true)
		self.settingButtons[definition[1]] = item
	end
	self.audioNote = Theme.text(settings, "AudioNote", "", UDim2.new(0, 0, 1, -100), UDim2.new(1, 0, 0, 54), 12, Theme.Muted)
	self.saveNote = Theme.text(settings, "SaveStatus", "", UDim2.new(0, 0, 1, -42), UDim2.new(1, 0, 0, 36), 12, Theme.Purple)
	self.confirm = Theme.frame(group, "PurchaseConfirmation", UDim2.new(), UDim2.fromScale(1, 1), Theme.Surface)
	self.confirm.ZIndex = 30
	self.confirm.Active = true
	self.confirm.Visible = false
	Theme.text(self.confirm, "Title", "ADD AURUM TO YOUR COLLECTION?", UDim2.fromScale(0.1, 0.22), UDim2.fromScale(0.8, 0.15), 26, Theme.Ink, true)
	Theme.text(self.confirm, "Scope", "45 earned session credits. Cosmetic only.\nYour collection and balance reset after leaving this server.", UDim2.fromScale(0.1, 0.4), UDim2.fromScale(0.8, 0.18), 16, Theme.Muted)
	self.confirmBuy = Theme.button(self.confirm, "Confirm", "SPEND 45 CREDITS", UDim2.fromScale(0.1, 0.66), UDim2.fromScale(0.8, 0.1), function()
		self.confirm.Visible = false
		callbacks.purchase("Aurum")
	end)
	Theme.button(self.confirm, "Cancel", "CANCEL", UDim2.fromScale(0.1, 0.8), UDim2.fromScale(0.8, 0.1), function() self.confirm.Visible = false end, true)
	self:open("Deploy")
	return self
end

function Menus.open(self: any, page: string)
	if not self.pages[page] then return end
	self.serial += 1
	self.page = page
	self.confirm.Visible = false
	self.content.CanvasPosition = Vector2.zero
	self.group.Visible = true
	if self.fade then self.fade:Cancel() end
	self.group.GroupTransparency = if self.reducedMotion then 0 else 0.15
	self.fade = TweenService:Create(self.group, TweenInfo.new(if self.reducedMotion then 0 else 0.18), { GroupTransparency = 0 })
	self.fade:Play()
	if self.callbacks.transition then self.callbacks.transition() end
	for name, item in self.pages do item.Visible = name == page end
	for name, item in self.navigation do Theme.selected(item, name == page) end
	self.preview:hide()
	self.characterPreview:hide()
	self.weaponPreview:hide()
	self.mapPreview:hide()
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		GuiService.SelectedObject = if page == "Deploy" then self.play elseif page == "Matchmaking" then self.queueCancel else self.navigation[page] or self.closeButton
	end
end

function Menus.confirmPurchase(self: any, id: string)
	if id ~= "Aurum" then return end
	self.confirm.Visible = true
	self.confirmBuy.Active = self.style and self.style.ready and (self.style.profile.credits or 0) >= 45
	self.confirmBuy.Text = if self.confirmBuy.Active then "SPEND 45 CREDITS" else "EARN MORE SESSION CREDITS"
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then GuiService.SelectedObject = self.confirmBuy end
end

function Menus.close(self: any)
	self.serial += 1
	local serial = self.serial
	self.page = nil
	self.confirm.Visible = false
	GuiService.SelectedObject = nil
	if self.fade then self.fade:Cancel() end
	self.fade = TweenService:Create(self.group, TweenInfo.new(if self.reducedMotion then 0 else 0.14), { GroupTransparency = 1 })
	self.fade:Play()
	task.delay(0.14, function()
		if self.serial == serial then
			self.group.Visible = false
			self.preview:hide(); self.characterPreview:hide(); self.weaponPreview:hide(); self.mapPreview:hide()
		end
	end)
end

function Menus.render(self: any, state: any, elapsed: number, preferences: any, style: any)
	if not self.page then return end
	self.style = style
	self.state = state
	self.reducedMotion = preferences.reducedMotion
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
	for name, area in self.pages do
		local minimum = if name == "Settings" then 680 elseif name == "Deploy" then 520 elseif name == "Maps" then (if compact then 790 else 490) elseif name == "Inventory" then 470 elseif name == "Shop" then (if compact then 1110 else 440) elseif name == "Matchmaking" then 470 else 420
		area.Size = UDim2.new(1, -8, 0, math.max(minimum, self.content.AbsoluteSize.Y))
	end
	self.brandGradient.Offset = if preferences.reducedMotion then Vector2.zero else Vector2.new(math.sin(os.clock() * 0.3) * 0.35, 0)
	self.hero.TextSize = if compact then 36 elseif short then 40 else 58
	self.hero.Size = UDim2.new(0.62, 0, 0, if short then 88 else 124)
	self.deployDescription.Position = UDim2.fromOffset(0, if short then 116 else 158)
	self.deployDescription.TextSize = if compact or short then 13 else 16
	self.deployDescription.Visible = true
	self.mapLink.Position = UDim2.fromOffset(0, if short then 208 else 238)
	self.profile.Position = UDim2.fromOffset(0, if short then 258 else 288)
	self.mapLink.Size = UDim2.new(if compact then 1 else 0.52, 0, 0, 38)
	self.profile.Size = UDim2.new(if compact then 1 else 0.52, 0, 0, 54)
	local profile = style.profile or { credits = 0, level = 1, xp = 0, status = "LOADING" }
	self.profile.Text = string.upper(Players.LocalPlayer.DisplayName) .. " / LV " .. profile.level .. "\n" .. profile.credits .. " CREDITS / " .. profile.xp .. " XP / THIS SESSION"
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
	local map = state.map or { id = "Collapse", name = "THE COLLAPSE", votes = {} }
	self.mapLink.Text = map.name .. " / EXPLORE ARENAS  >"
	local definition = Catalog[1]
	for _, entry in Catalog do if entry.id == self.draftMap then definition = entry; break end end
	local canVote = state.ballotEligible and (state.phase == "Waiting" or state.phase == "Intermission")
	self.voteStatus.Text = if canVote then "BALLOT OPEN / NEXT SIXTEEN QUEUED CONTENDERS / TIES RANDOMIZED" elseif state.inMatch then "CURRENT ROUND LOCKED / EXPLORE THE ARENAS" else "JOIN THE QUEUE TO VOTE / FIRST SIXTEEN GET A BALLOT"
	for index, entry in Catalog do
		local item = self.mapButtons[entry.id]
		item.Text = entry.name .. " / " .. (map.votes[entry.id] or 0) .. (if state.vote == entry.id then " / YOUR VOTE" else "")
		Theme.selected(item, self.draftMap == entry.id)
		item.Size = UDim2.new(if compact then 1 else 0.44, if compact then 0 else -12, 0, 46)
		item.Position = UDim2.fromOffset(0, 96 + (index - 1) * 54)
	end
	self.mapPreview.frame.Position = if compact then UDim2.fromOffset(0, 380) else UDim2.new(0.46, 0, 0, 96)
	self.mapPreview.frame.Size = if compact then UDim2.new(1, 0, 0, 180) else UDim2.new(0.54, 0, 0, 205)
	self.mapSubtitle.Position = if compact then UDim2.fromOffset(0, 574) else UDim2.new(0.46, 0, 0, 314)
	self.mapSubtitle.Size = UDim2.new(if compact then 1 else 0.54, 0, 0, 36)
	self.mapSubtitle.Text = definition.subtitle
	self.mapStrategy.Position = if compact then UDim2.fromOffset(0, 615) else UDim2.new(0.46, 0, 0, 354)
	self.mapStrategy.Size = UDim2.new(if compact then 1 else 0.54, 0, 0, 85)
	self.mapStrategy.Text = definition.strategy .. "\nHAZARD / " .. definition.hazard
	self.voteButton.Active = canVote == true and state.vote ~= self.draftMap
	self.voteButton.Text = if state.vote == self.draftMap then "VOTE RECORDED" elseif canVote then "VOTE FOR " .. definition.name else "BALLOT LOCKED / PREVIEW ONLY"
	local seconds = math.ceil(math.max(0, state.remaining - elapsed))
	self.queueTitle.Text = if state.inMatch then string.upper(state.phase) elseif state.queued then "YOU ARE IN THE QUEUE" else "READY TO QUEUE"
	self.queueDetail.Text = if state.inMatch then (if state.alive then "INSERTION / " .. map.name .. "\nYour combat loadout is ready." else "The current round is in progress. Watch from the hub until results.") else state.queueCount .. " QUEUED / " .. #Players:GetPlayers() .. " IN SERVER\nTwo contenders are needed. Up to sixteen enter each round. Vote before insertion."
	self.queueTimer.Text = if seconds > 0 then string.format("%02d:%02d / %s", math.floor(seconds / 60), seconds % 60, string.upper(state.phase)) else "AWAITING CONTENDERS"
	self.queueCancel.Text = if state.inMatch then "ROUND LOCKED" elseif state.queued then "LEAVE QUEUE" else "JOIN QUEUE"
	self.queueCancel.Active = not state.inMatch
	for id, item in self.operativeButtons do Theme.selected(item, id == self.draftOperative) end
	self.operativeDetail.Text = (Visuals.operative(self.draftOperative) or Visuals.Operatives[1]).description
	self.operativeDetail.Visible = not short
	self.equipOperative.Text = if style.operative == self.draftOperative then "EQUIPPED" else "EQUIP PROFILE"
	self.equipOperative.Active = style.ready
	for id, item in self.skinButtons do
		item.Text = (if style.owned[id] then "" else "LOCKED / ") .. Visuals.skin(id).name
		item.TextSize = 12
		Theme.selected(item, id == self.draftSkin)
	end
	self.equipSkin.Text = if not style.owned[self.draftSkin] then "UNLOCK STYLE" elseif style.skin == self.draftSkin then "EQUIPPED" else "EQUIP FINISH"
	self.equipSkin.Active = style.ready
	Theme.selected(self.rifleTab, self.weapon == 1)
	Theme.selected(self.bladeTab, self.weapon == 2)
	self.shopWallet.Text = profile.credits .. " SESSION CREDITS / 15 PER ELIMINATION + 45 PER WIN\nCollection and credits reset after leaving. No Robux."
	for index, card in self.shopCards do
		card.Position = if compact then UDim2.fromOffset(0, 108 + (index - 1) * 330) else UDim2.new((index - 1) / 3, 0, 0, 108)
		card.Size = UDim2.new(if compact then 1 else 1 / 3, if compact then 0 else -12, 0, 310)
	end
	for id, item in self.shopButtons do item.Text = if style.owned[id] then "EQUIP STYLE" elseif id == "Aurum" then "BUY / 45 CREDITS" else "CLAIM / FREE"; item.Active = style.ready end
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
	buttons.ui.Text = "INTERFACE AUDIO / " .. math.floor(preferences.ui * 100) .. "%"
	buttons.mute.Text = "MASTER AUDIO / " .. (if preferences.muted then "MUTED" else "ON")
	buttons.testAudio.Text = "PLAY AUDIO TEST"
	buttons.motion.Text = "ENVIRONMENT MOTION / " .. (if preferences.reducedMotion then "REDUCED" else "FULL")
	self.audioNote.Text = preferences.audioStatus or "Checking audio..."
	self.saveNote.Text = "PREFERENCES / " .. (preferences.saveStatus or profile.status)
	for name, item in buttons do item.Active = name == "testAudio" or preferences.loaded == true end
	if self.page == "Deploy" then self.preview:show("operative", style.operative, style.skin)
	elseif self.page == "Character" then self.characterPreview:show("operative", self.draftOperative, style.skin)
	elseif self.page == "Inventory" then self.weaponPreview:show("weapon", style.operative, self.draftSkin, self.weapon)
	elseif self.page == "Maps" then self.mapPreview:map(self.draftMap) end
	self.preview:step(preferences.reducedMotion); self.characterPreview:step(preferences.reducedMotion); self.weaponPreview:step(preferences.reducedMotion)
end

return Menus
