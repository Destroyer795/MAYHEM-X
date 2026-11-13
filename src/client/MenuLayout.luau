--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local MenuLayout = {}

local groups = {
	{key = "Deploy", label = "PLAY", pages = {{"Deploy", "OVERVIEW"}, {"Matchmaking", "QUEUE"}, {"Maps", "ARENAS"}, {"Mode", "HOW TO PLAY"}}},
	{key = "Character", label = "OPERATORS", pages = {{"Character", "OPERATOR SELECT"}}},
	{key = "Armory", label = "ARMORY", pages = {{"Armory", "WEAPONS"}, {"Inventory", "LOADOUT"}, {"Upgrades", "UPGRADES"}}},
	{key = "Shop", label = "COLLECTION", pages = {{"Shop", "WORKSHOP"}, {"Daily", "DAILY CACHE"}}},
	{key = "Progression", label = "CAREER", pages = {{"Progression", "PROGRESSION"}, {"Missions", "MISSIONS"}, {"Profile", "PROFILE"}, {"Leaderboards", "LEADERBOARDS"}, {"Ranked", "RANKED"}, {"Events", "EVENTS"}}},
	{key = "Settings", label = "SETTINGS", pages = {{"Settings", "PREFERENCES"}}},
}

local function place(item: GuiObject, x: number, y: number, w: number, h: number)
	item.Position, item.Size = UDim2.fromOffset(math.round(x), math.round(y)), UDim2.fromOffset(math.max(0, math.round(w)), math.max(0, math.round(h)))
end

local function link(parent: Instance, name: string, title: string, callback: () -> ())
	local item = Theme.button(parent, name, title, UDim2.new(), UDim2.new(), callback, true)
	item.BackgroundTransparency = 1
	item.TextSize = 13
	item:FindFirstChildOfClass("UIStroke").Enabled = false
	item.SelectionMark.Position, item.SelectionMark.Size = UDim2.new(0, 10, 1, -3), UDim2.new(1, -20, 0, 2)
	return item
end

function MenuLayout.build(self: any, page: (string) -> Frame)
	self.navigation = {}
	self.topbar.Name = "IdentityBar"
	self.topbar.BackgroundTransparency = 0.08
	self.logo.Font, self.logo.Text = Theme.FontDisplay, "MAYHEM  /  X"
	self.logo.TextSize = 26
	self.headerRule.BackgroundColor3, self.headerRule.BackgroundTransparency = Theme.Metal, 0.85
	self.headerRule.Visible = true
	self.navLayout.Padding = UDim.new(0, 8)
	for index, group in groups do
		local item = link(self.nav, group.key, group.label, function() self:open(group.key) end)
		item.LayoutOrder = index
		self.navigation[group.key] = item
	end
	local sub = Instance.new("ScrollingFrame")
	sub.Name, sub.BackgroundTransparency, sub.BorderSizePixel = "ContextNavigation", 1, 0
	sub.CanvasSize, sub.AutomaticCanvasSize = UDim2.new(), Enum.AutomaticSize.X
	sub.ScrollingDirection, sub.ScrollBarThickness = Enum.ScrollingDirection.X, 2
	sub.ScrollBarImageColor3 = Theme.Action
	sub.Parent = self.group
	local layout = Instance.new("UIListLayout")
	layout.FillDirection, layout.Padding, layout.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 10), Enum.SortOrder.LayoutOrder
	layout.Parent = sub
	self.contextNav, self.contextButtons = sub, {}
	for _, group in groups do for index, entry in group.pages do
		local button = link(sub, entry[1], entry[2], function() self:open(entry[1]) end)
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(math.max(108, #entry[2] * 8 + 24), 44)
		self.contextButtons[entry[1]] = button
	end end
	self.headerProfile.Font, self.headerProfile.TextSize = Theme.Font, 13
	self.headerProfile.TextXAlignment = Enum.TextXAlignment.Right
	self.profileLink = link(self.group, "OpenProfile", "", function() self:open("Profile") end)
	self.wallet = Theme.text(self.group, "Wallet", "", UDim2.new(), UDim2.new(), 12, Theme.Action)
	self.wallet.TextXAlignment, self.wallet.Font = Enum.TextXAlignment.Right, Theme.FontNumeric
	self.closeButton.Text = "HUB  /  M"
	self.closeButton.TextSize = 12
	self.footer.TextSize = 11
	self.content.ScrollBarImageColor3 = Theme.Action

	local deploy = self.pages.Deploy
	self.hero.Font, self.hero.Text = Theme.FontDisplay, "MAYHEM\nX"
	self.hero.TextYAlignment = Enum.TextYAlignment.Top
	self.hero.ZIndex, self.eyebrow.ZIndex, self.deployDescription.ZIndex = 3, 3, 3
	self.deployDescription.Text = "ENTER THE CHAOS.\nBECOME THE LEGEND."
	self.preview.frame.ZIndex = 1
	self.preview.cinematic = true
	self.heroRule = Theme.frame(deploy, "IdentitySlash", UDim2.new(), UDim2.new(), Theme.Action)
	self.heroRule.ZIndex = 3
	self.heroFeatures = Theme.frame(deploy, "Discover", UDim2.new(), UDim2.new(), nil, 1)
	self.featureButtons = {}
	for index, entry in {{"Daily", "01 / DAILY CACHE", "PRISM + 15 CREDITS"}, {"Maps", "02 / FIVE FRONTIERS", "EXPLORE & VOTE"}, {"Armory", "03 / YOUR LOADOUT", "VECTOR-18 + RIFT"}} do
		local button = Theme.button(self.heroFeatures, entry[1], "", UDim2.new(), UDim2.new(), function() self:open(entry[1]) end, true)
		button.BackgroundTransparency = 0.58
		button:FindFirstChildOfClass("UIStroke").Enabled = false
		Theme.text(button, "Eyebrow", entry[2], UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 18), 10, Theme.Muted)
		Theme.text(button, "Title", entry[3], UDim2.fromOffset(14, 29), UDim2.new(1, -28, 0, 22), 13, Theme.Ink, true)
		self.featureButtons[index] = button
	end
	self.mapLink.Visible, self.frontier.Visible, self.profile.Visible = false, false, false
	self.previewCaption.TextSize, self.previewCaption.TextColor3 = 13, Theme.Ink
	self.online.TextSize = 11

	local profile = page("Profile")
	Theme.text(profile, "Title", "YOUR IDENTITY", UDim2.new(), UDim2.new(1, 0, 0, 46), 34, Theme.Ink, true)
	self.identity = Theme.text(profile, "Identity", "", UDim2.fromOffset(0, 74), UDim2.new(1, 0, 0, 62), 26, Theme.Action, true)
	self.profileStats = Theme.text(profile, "Statistics", "", UDim2.fromOffset(0, 154), UDim2.new(1, 0, 0, 130), 18, Theme.Ink)
	self.profileStorage = Theme.text(profile, "Storage", "", UDim2.fromOffset(0, 302), UDim2.new(1, 0, 0, 70), 13, Theme.Muted)
	Theme.button(profile, "Customize", "CUSTOMIZE OPERATOR", UDim2.new(0, 0, 1, -52), UDim2.new(0.48, 0, 0, 44), function() self:open("Character") end)
	Theme.button(profile, "Wallet", "VIEW COLLECTION", UDim2.new(0.52, 0, 1, -52), UDim2.new(0.48, 0, 0, 44), function() self:open("Shop") end, true)
	local upgrades = page("Upgrades")
	Theme.text(upgrades, "Title", "MAKE IT YOURS", UDim2.new(), UDim2.new(1, 0, 0, 46), 34, Theme.Ink, true)
	Theme.text(upgrades, "Scope", "PERSONAL EXPRESSION. EQUAL COMBAT STATS.", UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 42), 13, Theme.Action)
	self.upgradeLinks = {}
	for index, entry in {{"Inventory", "01  WEAPON FINISHES", "Equip owned finishes on both weapons."}, {"Character", "02  OPERATOR PROFILES", "Choose Vanguard, Spectre or Relay."}, {"Shop", "03  EARNED COLLECTION", "Spend earned currencies on cosmetic finishes."}} do
		local button = Theme.button(upgrades, entry[1], entry[2], UDim2.fromOffset(0, 120 + (index - 1) * 90), UDim2.new(1, 0, 0, 48), function() self:open(entry[1]) end, true)
		button.TextXAlignment = Enum.TextXAlignment.Left
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 18); pad.Parent = button
		Theme.text(upgrades, "Detail" .. index, entry[3], UDim2.fromOffset(18, 171 + (index - 1) * 90), UDim2.new(1, -36, 0, 26), 13, Theme.Muted)
		self.upgradeLinks[index] = button
	end
	Theme.text(upgrades, "Availability", "Mastery trees and handling upgrades are not available. Cosmetics never change damage, health or movement.", UDim2.fromOffset(0, 412), UDim2.new(1, 0, 0, 70), 13, Theme.Muted)
	local events = page("Events")
	Theme.text(events, "Title", "ON THE HORIZON", UDim2.new(), UDim2.new(1, 0, 0, 46), 34, Theme.Ink, true)
	Theme.text(events, "State", "NO SCHEDULED EVENT", UDim2.fromOffset(0, 110), UDim2.new(1, 0, 0, 48), 26, Theme.Action, true)
	Theme.text(events, "Detail", "Season Tokens are earned in completed matches and can unlock the Solstice finish. A seasonal event schedule and timed missions have not been released.", UDim2.fromOffset(0, 188), UDim2.new(0.9, 0, 0, 128), 17, Theme.Muted)
	Theme.button(events, "Rewards", "EXPLORE EARNED REWARDS", UDim2.new(0, 0, 1, -52), UDim2.new(1, 0, 0, 44), function() self.draftShop = "Solstice"; self:open("Shop") end)
	self.pages.Inventory.Title.Text = "YOUR LOADOUT"
	self.pages.Armory.Title.Text = "THE ARMORY"
	self.pages.Settings.Title.Text = "YOUR PREFERENCES"
	self.pages.Progression.Scope.Text = "ACCOUNT EXPERIENCE / EARNED THROUGH COMBAT"
	self.pages.Progression.Rewards.Text = "120 XP per elimination. 300 XP per victory.\n\nLevels reflect your current profile. Mastery, prestige and achievement rewards are not yet available."
	self.pages.Missions.Detail.Text = "Claim the Prism finish and 15 earned Credits. No streaks, purchases or penalties for taking a break."
	self.settingsDisplay = Theme.text(self.pages.Settings, "DisplaySection", "DISPLAY & CAMERA", UDim2.new(), UDim2.new(), 12, Theme.Action)
	self.settingsAudio = Theme.text(self.pages.Settings, "AudioSection", "AUDIO & MIX", UDim2.new(), UDim2.new(), 12, Theme.Action)
	for _, button in self.settingButtons do
		button.BackgroundTransparency = 1
		button:FindFirstChildOfClass("UIStroke").Enabled = false
		Theme.frame(button, "Separator", UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1), Theme.Metal, 0.8)
		Theme.text(button, "SettingLabel", "", UDim2.fromOffset(10, 0), UDim2.new(0.6, -10, 1, 0), 13, Theme.Muted)
		local value = Theme.text(button, "SettingValue", "", UDim2.new(0.6, 0, 0, 0), UDim2.new(0.4, -12, 1, 0), 13, Theme.Ink, true)
		value.TextXAlignment = Enum.TextXAlignment.Right
		button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), {BackgroundTransparency = 0.35}):Play() end)
		button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play() end)
	end
	self.queueLine = Theme.bar(self.pages.Matchmaking, "SearchProgress", UDim2.fromOffset(0, 119), UDim2.new(1, 0, 0, 2), Theme.Action)
	self.queuePreview = Preview.new(self.pages.Matchmaking)
	self.queuePreview.frame.Name = "WaitingOperator"
	self.operatorName = Theme.text(self.pages.Character, "SelectedName", "", UDim2.new(), UDim2.new(), 32, Theme.Ink, true)
	self.operatorName.Font = Theme.FontDisplay
	self.confirm.BackgroundTransparency = 0.15
	self.confirmSheet = Theme.frame(self.confirm, "PurchaseSheet", UDim2.new(), UDim2.new(), Theme.Panel)
	Theme.corner(self.confirmSheet, 10)
	for _, item in {self.confirmTitle, self.confirmScope, self.confirmBuy, self.confirmCancel} do item.Parent = self.confirmSheet end
	self.characterStage.BackgroundTransparency = 1
	self.characterStage:FindFirstChildOfClass("UIStroke").Enabled = false
	for _, area in self.pages do
		local title = area:FindFirstChild("Title")
		if title and title:IsA("TextLabel") and area ~= deploy then title.Font = Theme.FontDisplay; title.TextSize = 36 end
	end
end

function MenuLayout.shell(self: any, width: number, height: number)
	local narrow, short = width < 600, height < 500
	local pad = if narrow then 16 else math.max(28, math.floor((width - 1440) / 2))
	local header = if narrow then 82 else 66
	place(self.topbar, 0, 0, width, header)
	place(self.logo, pad, 4, if narrow then 145 else 190, 42)
	self.logo.TextSize = if narrow then 23 else 28
	place(self.closeButton, width - pad - 82, 7, 82, 44)
	place(self.headerProfile, if narrow then pad else 230, if narrow then 39 else 6, if narrow then width - pad * 2 else width - 360 - pad, if narrow then 18 else 22)
	self.headerProfile.TextSize = if narrow then 11 else 13
	self.headerProfile.TextXAlignment = if narrow then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	self.profileLink.Position, self.profileLink.Size = self.headerProfile.Position, self.headerProfile.Size
	place(self.wallet, if narrow then pad else 225, if narrow then 58 else 31, if narrow then width - pad * 2 else width - 355 - pad, 20)
	self.wallet.TextSize = if narrow then 11 else 12
	self.wallet.TextXAlignment = if narrow then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	self.wallet.Visible = true
	place(self.nav, pad - 10, header, width - pad * 2 + 20, 48)
	for _, group in groups do
		place(self.navigation[group.key], 0, 0, if narrow then 111 else 136, 46)
	end
	local activeGroup = groups[1]
	for _, group in groups do for _, entry in group.pages do if entry[1] == self.page then activeGroup = group end end end
	for _, group in groups do
		local active = group == activeGroup
		local item = self.navigation[group.key]
		item.TextColor3 = if active then Theme.Ink else Theme.Muted
		item.SelectionMark.Visible = active
	end
	local subVisible = #activeGroup.pages > 1 and not (self.page == "Deploy")
	self.contextNav.Visible = subVisible
	place(self.contextNav, pad - 10, header + 50, width - pad * 2 + 20, 44)
	for name, item in self.contextButtons do
		local visible = false
		for _, entry in activeGroup.pages do if name == entry[1] then visible = true end end
		item.Visible = visible
		item.TextColor3 = if name == self.page then Theme.Action else Theme.Muted
		item.SelectionMark.Visible = name == self.page
	end
	if self.contextGroup ~= activeGroup.key then self.contextGroup = activeGroup.key; self.contextNav.CanvasPosition = Vector2.zero end
	place(self.headerRule, pad, header + 48, width - pad * 2, 1)
	local top = header + (if subVisible then 106 else 62)
	self.contentBase = UDim2.fromOffset(pad, top)
	self.content.Position = self.contentBase + UDim2.fromOffset(0, math.round(self.pageSlide.Value))
	self.content.Size = UDim2.fromOffset(width - pad * 2, math.max(80, height - top - 30))
	place(self.footer, pad, height - 27, width - pad * 2, 24)
	self.footer.Visible = not short
	local sheetWidth = math.min(580, width - 32)
	place(self.confirmSheet, (width - sheetWidth) / 2, math.max(8, (height - 330) / 2), sheetWidth, 330)
	place(self.confirmTitle, 24, 22, sheetWidth - 48, 56)
	place(self.confirmScope, 24, 86, sheetWidth - 48, 92)
	place(self.confirmBuy, 24, 202, sheetWidth - 48, 46)
	place(self.confirmCancel, 24, 262, sheetWidth - 48, 44)
	for name, area in self.pages do
		local minimum = if name == "Deploy" then (if narrow then 570 elseif short then 440 else 490)
			elseif name == "Settings" then (if narrow then 760 else 520)
			elseif name == "Maps" then (if narrow then 790 else 500)
			elseif name == "Inventory" then (if narrow then 890 else 600)
			elseif name == "Character" then (if narrow then 690 else 490)
			elseif name == "Armory" then (if narrow then 730 else 520)
			elseif name == "Shop" then (if narrow then 620 else 570)
			elseif name == "Leaderboards" then 112 + #Players:GetPlayers() * 52
			else 500
		area.Size = UDim2.fromOffset(width - pad * 2 - 8, math.max(minimum, self.content.AbsoluteSize.Y))
	end
	return narrow, short
end

function MenuLayout.content(self: any, width: number, height: number, state: any, style: any, profile: any)
	local narrow, short = width < 600, height < 500
	local w, h = self.pages.Deploy.AbsoluteSize.X, self.pages.Deploy.AbsoluteSize.Y
	self.eyebrow.Text = "LAST SIGNAL   /   16 CONTENDERS"
	place(self.eyebrow, 0, 0, if narrow then w else w * 0.4, 24)
	self.eyebrow.TextSize = 11
	place(self.hero, 0, 26, if narrow then w * 0.58 else w * 0.46, if narrow then 166 else 224)
	self.hero.TextSize = if narrow then 72 elseif short then 68 else 96
	place(self.heroRule, 0, if narrow then 202 elseif short then 194 else 250, 44, 3)
	place(self.deployDescription, 0, h - 270, w * 0.42, 44)
	self.deployDescription.Visible = not narrow and not short and h > 520
	self.deployDescription.TextSize = 15
	place(self.preview.frame, w * (if narrow then 0.23 else 0.31), if narrow then 16 else -16, w * (if narrow then 0.8 else 0.69), if narrow then 350 else h - 78)
	self.previewCaption.Visible, self.online.Visible = not narrow, not narrow
	place(self.previewCaption, w * 0.68, 0, w * 0.32, 24)
	place(self.online, w * 0.68, 26, w * 0.32, 22)
	self.online.Text = #Players:GetPlayers() .. " IN HUB  /  " .. state.queueCount .. " QUEUED"
	local buttonY = if narrow then 366 else h - 208
	place(self.play, 0, buttonY, if narrow then w else math.min(350, w * 0.35), 56)
	self.play.TextSize = 19
	self.play.ZIndex = 4
	place(self.modeButton, 0, buttonY + 63, if narrow then w else math.min(350, w * 0.35), 44)
	self.modeButton.Text = "LAST SIGNAL  /  MODE DETAILS"
	self.modeButton.TextSize = 12
	place(self.heroFeatures, 0, if narrow then 487 else h - 74, w, 68)
	for index, button in self.featureButtons do
		local col = (w - 16) / (if narrow then 2 else 3)
		button.Visible = not narrow or index < 3
		place(button, (index - 1) * (col + 8), 0, col, 64)
		button.Title.TextSize = if narrow then 11 else 14
	end
	self.headerProfile.Text = string.upper(Players.LocalPlayer.DisplayName) .. "   /   LEVEL " .. profile.level
	self.wallet.Text = string.format("%d CR     %d SHARDS     %d TOKENS", profile.credits, profile.shards, profile.seasonTokens)
	self.identity.Text = string.upper(Players.LocalPlayer.DisplayName) .. "\nLEVEL " .. profile.level
	local leaderstats = Players.LocalPlayer:FindFirstChild("leaderstats")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	self.profileStats.Text = string.format("%s / %s\n\n%d XP   /   %d SERVER ELIMINATIONS   /   %d SERVER WINS\n\n%d CREDITS   /   %d SHARDS   /   %d TOKENS", string.upper(style.operative), string.upper(style.skin), profile.xp, kills and kills.Value or 0, wins and wins.Value or 0, profile.credits, profile.shards, profile.seasonTokens)
	self.profileStorage.Text = "PROFILE / " .. string.upper(profile.status) .. "\nGlobal statistics and match history are not available."
	self.pages.Progression.Scope.Text = "PROFILE / " .. string.upper(profile.status)
	self.queueLine.Size = UDim2.fromScale(if state.queued then 0.65 else 0.15, 1)
	self.queueTimer.Visible = true
	local qw = self.pages.Matchmaking.AbsoluteSize.X
	place(self.queueDetail, 0, 136, qw * (if narrow then 1 else 0.46), 95)
	place(self.queuePreview.frame, if narrow then qw * 0.5 else qw * 0.52, if narrow then 232 else 70, qw * (if narrow then 0.5 else 0.48), if narrow then 150 else 290)
	place(self.pages.Matchmaking.ChooseMap, 0, 250, qw * (if narrow then 0.46 else 0.42), 44)
	if self.page == "Matchmaking" then self.queuePreview:show("operative", style.operative, style.skin) end
	self.operativeDetail.Visible = true
	local cw = self.pages.Character.AbsoluteSize.X
	place(self.characterPreview.frame, if narrow then 0 else cw * 0.32, 48, if narrow then cw else cw * 0.68, if narrow then 260 else self.pages.Character.AbsoluteSize.Y - 72)
	self.operatorName.Text = string.upper(self.draftOperative)
	place(self.operatorName, 0, 66, cw * 0.32, 42)
	self.operatorName.Visible = not narrow
	for index, entry in {"Vanguard", "Spectre", "Relay"} do
		place(self.operativeButtons[entry], 0, (if narrow then 330 else 130) + (index - 1) * 56, if narrow then cw else cw * 0.32, 48)
	end
	place(self.operativeDetail, 0, if narrow then 506 else 318, if narrow then cw else cw * 0.33, 90)
	place(self.equipOperative, 0, self.pages.Character.AbsoluteSize.Y - 52, if narrow then cw else cw * 0.34, 44)
	local iw = self.pages.Inventory.AbsoluteSize.X
	place(self.rifleTab, 0, 56, iw * 0.48, 44); place(self.bladeTab, iw * 0.52, 56, iw * 0.48, 44)
	place(self.weaponPreview.frame, if narrow then 0 else iw * 0.4, 112, if narrow then iw else iw * 0.6, if narrow then 210 else 320)
	for index, entry in require(game.ReplicatedStorage.Mayhem.Shared.Visuals).Skins do
		place(self.skinButtons[entry.id], 0, (if narrow then 334 else 116) + (index - 1) * 52, if narrow then iw else iw * 0.35, 46)
	end
	place(self.inventoryNote, if narrow then 0 else iw * 0.43, if narrow then 758 else 440, if narrow then iw else iw * 0.57, 64)
	local aw = self.pages.Armory.AbsoluteSize.X
	place(self.armoryPreview.frame, if narrow then 0 else aw * 0.38, 154, if narrow then aw else aw * 0.62, if narrow then 230 else 300)
	place(self.weaponStats, 0, if narrow then 400 else 168, if narrow then aw else aw * 0.34, 240)
	self.weaponStats.TextSize = 14
	local sw = self.pages.Settings.AbsoluteSize.X
	place(self.settingsDisplay, 0, 60, sw * (if narrow then 1 else 0.48), 26)
	place(self.settingsAudio, if narrow then 0 else sw * 0.52, if narrow then 392 else 60, sw * (if narrow then 1 else 0.48), 26)
	for index, name in {"camera", "fov", "graphics", "effects", "motion", "music", "sound", "ui", "mute", "testAudio"} do
		local right = index > 5
		place(self.settingButtons[name], if right and not narrow then sw * 0.52 else 0, (if right and narrow then 424 else 96) + ((index - 1) % 5) * 54, sw * (if narrow then 1 else 0.48), 46)
		self.settingButtons[name].TextSize = 14
		local item = self.settingButtons[name]
		local label, value = item.Text:match("^(.-) / (.+)$")
		item.SettingLabel.Text = label or item.Text
		item.SettingValue.Text = value or "LISTEN"
		item.SettingValue.TextTransparency = if item.Active then 0 else 0.5
		item.Text = ""
	end
	place(self.audioNote, 0, if narrow then 704 else 390, sw, 52)
	place(self.saveNote, 0, self.pages.Settings.AbsoluteSize.Y - 32, sw, 28)
	self.audioNote.Visible = not narrow
end

return MenuLayout
