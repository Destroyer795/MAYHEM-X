--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)
local Preview = require(script.Parent.Preview)
local ArmoryPanel = require(script.Parent.ArmoryPanel)
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
	self.logo.Font, self.logo.Text = Theme.FontDisplay, "MAYHEM X"
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
	self.hero.Font, self.hero.Text = Theme.FontDisplay, "THE LAST\nSIGNAL."
	self.hero.TextYAlignment = Enum.TextYAlignment.Top
	self.hero.ZIndex, self.eyebrow.ZIndex, self.deployDescription.ZIndex = 3, 3, 3
	self.deployDescription.Text = "Pick your operator. Build your loadout.\nBe the last contender standing."
	self.preview.frame.ZIndex = 1
	self.preview.cinematic = true
	self.stageVeil = Theme.frame(deploy,"StageVeil",UDim2.new(),UDim2.new(),Theme.Surface)
	self.stageVeil.ZIndex = 2
	local veil = Instance.new("UIGradient")
	veil.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.1),NumberSequenceKeypoint.new(1,1)})
	veil.Parent = self.stageVeil
	self.operatorLabel = Theme.text(deploy,"OperatorSignature","",UDim2.new(),UDim2.new(),25,Theme.Ink,true)
	self.operatorLabel.ZIndex = 4
	self.operatorRole = Theme.text(deploy,"OperatorRole","",UDim2.new(),UDim2.new(),11,Theme.Muted)
	self.operatorRole.ZIndex = 4
	self.homeOperator = link(deploy,"ChangeOperator","CHANGE OPERATOR",function() self:open("Character") end)
	self.homeOperator.ZIndex = 4
	self.railRule = Theme.frame(self.group,"RailRule",UDim2.new(),UDim2.new(),Theme.Metal,0.84)
	self.railLabel = Theme.text(self.group,"CommandLabel","COMMAND / 01",UDim2.new(),UDim2.new(),10,Theme.Muted)

	self.heroRule = Theme.frame(deploy, "IdentitySlash", UDim2.new(), UDim2.new(), Theme.Action)
	self.heroRule.ZIndex = 3
	self.heroFeatures = Theme.frame(deploy, "Discover", UDim2.new(), UDim2.new(), nil, 1)
	self.featureButtons = {}
	for index, entry in {{"Daily", "01 / DAILY CACHE", "PRISM + 15 CREDITS"}, {"Maps", "02 / FIVE FRONTIERS", "EXPLORE & VOTE"}, {"Armory", "03 / FIELD ARMORY", "7 WEAPONS / 6 KITS"}} do
		local button = Theme.button(self.heroFeatures, entry[1], "", UDim2.new(), UDim2.new(), function() self:open(entry[1]) end, true)
		button.BackgroundTransparency = 1
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
	Theme.text(upgrades, "Scope", "LOADOUT ENGINEERING / FAIR TRADEOFFS", UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 42), 13, Theme.Action)
	self.upgradeLinks = {}
	for index, entry in {{"Armory", "01  HANDLING WORKSHOP", "Choose three firearm kits and three melee kits with explicit tradeoffs."}, {"Inventory", "02  WEAPON FINISHES", "Equip owned energy finishes on your selected weapons."}, {"Shop", "03  EARNED COLLECTION", "Spend earned currencies on cosmetic finishes."}} do
		local button = Theme.button(upgrades, entry[1], entry[2], UDim2.fromOffset(0, 120 + (index - 1) * 90), UDim2.new(1, 0, 0, 48), function() self:open(entry[1]) end, true)
		button.TextXAlignment = Enum.TextXAlignment.Left
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 18); pad.Parent = button
		Theme.text(upgrades, "Detail" .. index, entry[3], UDim2.fromOffset(18, 171 + (index - 1) * 90), UDim2.new(1, -36, 0, 26), 13, Theme.Muted)
		self.upgradeLinks[index] = button
	end
	Theme.text(upgrades, "Availability", "All weapon and handling choices are free. Your loadout locks at round start. Cosmetic finishes never change combat stats.", UDim2.fromOffset(0, 412), UDim2.new(1, 0, 0, 70), 13, Theme.Muted)
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
	ArmoryPanel.build(self)
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
	self.characterPreview.cinematic = true
	self.characterStage:FindFirstChildOfClass("UIStroke").Enabled = false
	for _, area in self.pages do
		local title = area:FindFirstChild("Title")
		if title and title:IsA("TextLabel") and area ~= deploy then title.Font = Theme.FontDisplay; title.TextSize = 36 end
	end
end

function MenuLayout.shell(self: any, width: number, height: number)
	local narrow, short = width < 600, height < 500
	local rail = width >= 960
	local pad, header = if narrow then 16 else 28, if narrow then 82 else 68
	local left = if rail then 196 else pad
	local usable = width-left-pad
	place(self.topbar,0,0,width,header)
	place(self.logo,pad,8,if narrow then 155 else 190,36)
	self.logo.TextSize = if narrow then 22 else 26
	place(self.closeButton,width-pad-82,8,82,44)
	place(self.headerProfile,if narrow then pad else 260,if narrow then 40 else 9,if narrow then width-pad*2 else width-390-pad,20)
	self.headerProfile.TextSize = if narrow then 11 else 13
	self.headerProfile.TextXAlignment = if narrow then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	self.profileLink.Position,self.profileLink.Size = self.headerProfile.Position,self.headerProfile.Size
	place(self.wallet,if narrow then pad else 260,if narrow then 60 else 34,if narrow then width-pad*2 else width-390-pad,20)
	self.wallet.TextSize = if narrow then 11 else 12
	self.wallet.TextXAlignment = if narrow then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	self.wallet.Visible = true
	self.navLayout.FillDirection = if rail then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal
	self.nav.ScrollingDirection = if rail then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X
	self.nav.AutomaticCanvasSize = if rail then Enum.AutomaticSize.Y else Enum.AutomaticSize.X
	self.nav.CanvasSize = UDim2.new()
	place(self.nav,if rail then 18 else pad-10,if rail then 128 else header,if rail then 152 else width-pad*2+20,if rail then math.min(height-176,420) else 48)
	self.railRule.Visible,self.railLabel.Visible = rail,rail
	place(self.railRule,172,header+24,1,height-header-68)
	place(self.railLabel,28,96,140,20)
	for _,group in groups do
		local item=self.navigation[group.key]
		place(item,0,0,if rail then 150 elseif narrow then 111 else 136,if rail then 52 else 46)
		item.TextXAlignment = if rail then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
		item.SelectionMark.Position = if rail then UDim2.new(0,0,0,10) else UDim2.new(0,10,1,-3)
		item.SelectionMark.Size = if rail then UDim2.new(0,3,1,-20) else UDim2.new(1,-20,0,2)
		local padding = item:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0,if rail then 16 else 0)
		padding.Parent = item
	end
	local activeGroup = groups[1]
	for _,group in groups do for _,entry in group.pages do if entry[1]==self.page then activeGroup=group end end end
	for _,group in groups do
		local item=self.navigation[group.key]
		item.TextColor3=if group==activeGroup then Theme.Ink else Theme.Muted
		item.SelectionMark.Visible=group==activeGroup
	end
	local subVisible=#activeGroup.pages>1 and self.page~="Deploy"
	self.contextNav.Visible=subVisible
	place(self.contextNav,left-10,header+(if rail then 10 else 50),usable+20,44)
	for name,item in self.contextButtons do
		local visible=false
		for _,entry in activeGroup.pages do if name==entry[1] then visible=true end end
		item.Visible=visible
		item.TextColor3=if name==self.page then Theme.Action else Theme.Muted
		item.SelectionMark.Visible=name==self.page
	end
	if self.contextGroup~=activeGroup.key then self.contextGroup=activeGroup.key; self.contextNav.CanvasPosition=Vector2.zero end
	place(self.headerRule,pad,header-1,width-pad*2,1)
	local top=header+(if rail then (if subVisible then 66 else 24) else (if subVisible then 106 else 62))
	self.contentBase=UDim2.fromOffset(left,top)
	self.content.Position=self.contentBase+UDim2.fromOffset(0,math.round(self.pageSlide.Value))
	self.content.Size=UDim2.fromOffset(usable,math.max(80,height-top-30))
	place(self.footer,left,height-27,usable,24)
	self.footer.Visible=not short
	local sheetWidth = math.min(580, width - 32)
	place(self.confirmSheet, (width - sheetWidth) / 2, math.max(8, (height - 330) / 2), sheetWidth, 330)
	place(self.confirmTitle, 24, 22, sheetWidth - 48, 56)
	place(self.confirmScope, 24, 86, sheetWidth - 48, 92)
	place(self.confirmBuy, 24, 202, sheetWidth - 48, 46)
	place(self.confirmCancel, 24, 262, sheetWidth - 48, 44)
	for name, area in self.pages do
		local minimum = if name == "Deploy" then (if short then 0 elseif narrow then 616 else 560)
			elseif name == "Settings" then (if narrow then 760 else 520)
			elseif name == "Maps" then (if narrow then 790 else 500)
			elseif name == "Inventory" then (if narrow then 890 else 600)
			elseif name == "Character" then (if narrow then 690 else 490)
			elseif name == "Armory" then (if narrow then 730 else 520)
			elseif name == "Shop" then (if narrow then 620 else 570)
			elseif name == "Leaderboards" then 112 + #Players:GetPlayers() * 52
			else 500
		area.Size = UDim2.fromOffset(usable - 8, math.max(minimum, self.content.AbsoluteSize.Y))
	end
	return narrow, short
end

function MenuLayout.content(self: any, width: number, height: number, state: any, style: any, profile: any)
	local narrow, short = width < 600, height < 500
	local w, h = self.pages.Deploy.AbsoluteSize.X, self.pages.Deploy.AbsoluteSize.Y
	self.eyebrow.Text = "FIELD OPS  /  16 CONTENDERS"
	place(self.eyebrow,0,8,w*0.5,22)
	self.eyebrow.TextSize=11
	place(self.hero,0,50,if narrow then w*0.72 else w*0.6,if narrow then 116 else 190)
	self.hero.TextSize=if narrow then 40 elseif short then 50 else 68
	place(self.heroRule,0,if narrow then 173 else 236,40,4)
	self.heroRule.BackgroundColor3=Theme.Cyan
	place(self.deployDescription,0,258,w*0.39,54)
	self.deployDescription.Visible=not narrow and not short
	self.deployDescription.TextSize=14
	place(self.preview.frame,w*(if narrow then 0.10 else 0.26),if narrow then 126 else -4,w*(if narrow then 0.95 else 0.79),if narrow then 270 else h-86)
	place(self.stageVeil,0,0,w*(if narrow then 0.35 else 0.55),if narrow then 172 else h-86)
	self.stageVeil.Visible=not narrow
	self.previewCaption.Visible,self.online.Visible=false,false
	local signatureY=if narrow then 358 else h-160
	place(self.operatorLabel,w*(if narrow then 0.40 else 0.65),signatureY,w*(if narrow then 0.60 else 0.35),30)
	self.operatorLabel.Text=string.upper(style.operative)
	self.operatorLabel.TextSize=if narrow then 19 else 25
	place(self.operatorRole,w*(if narrow then 0.4 else 0.65),signatureY+32,w*(if narrow then 0.6 else 0.35),20)
	self.operatorRole.Text=if style.operative=="Spectre" then "RECON / MANTLE KIT" elseif style.operative=="Relay" then "ENGINEER / FIELD KIT" else "BREACHER / HEAVY KIT"
	place(self.homeOperator,w*0.65,signatureY+58,w*0.35,44)
	self.homeOperator.Visible=not narrow
	local buttonY=if narrow then 416 else h-202
	place(self.play,0,buttonY,if narrow then w else math.min(350,w*0.43),56)
	self.play.TextSize,self.play.ZIndex=19,4
	place(self.modeButton,0,buttonY+62,if narrow then w else math.min(350,w*0.43),44)
	self.modeButton.Text="HOW TO PLAY / LAST SIGNAL"
	self.modeButton.TextSize=11
	self.modeButton.ZIndex=4
	self.modeButton.Visible=true
	place(self.heroFeatures,0,if narrow then 540 else h-68,w,64)
	for index,button in self.featureButtons do
		local col=(w-16)/(if narrow then 2 else 3)
		button.Visible=not narrow or index<3
		place(button,(index-1)*(col+8),0,col,64)
		button.Title.TextSize=if narrow then 11 else 13
	end
	self.heroFeatures.Visible=not short
	self.heroRule.Visible=not short
	if short then
		local visibleH=self.content.AbsoluteSize.Y
		local tiny=visibleH<250
		place(self.hero,0,26,w*0.55,if tiny then 75 else 106)
		self.hero.TextSize=if tiny then 32 else 40
		place(self.preview.frame,w*0.39,0,w*0.66,visibleH-8)
		place(self.stageVeil,0,0,w*0.55,visibleH)
		place(self.play,0,visibleH-(if tiny then 56 else 108),w*0.48,52)
		self.play.TextSize=if narrow then 14 else 16
		place(self.modeButton,0,visibleH-48,w*0.48,44)
		self.modeButton.Visible=not tiny
		self.homeOperator.Visible=false
		self.operatorLabel.Visible,self.operatorRole.Visible=not tiny,not tiny
		place(self.operatorLabel,w*0.62,visibleH-60,w*0.38,28)
		place(self.operatorRole,w*0.62,visibleH-32,w*0.38,20)
	else
		self.operatorLabel.Visible,self.operatorRole.Visible=true,true
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
