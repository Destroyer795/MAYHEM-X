--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Visuals = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Visuals)
local Catalog = require(game:GetService("ReplicatedStorage").Mayhem.Shared.MapCatalog)
local Config = require(game:GetService("ReplicatedStorage").Mayhem.Shared.Config)
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
	group.ClipsDescendants = false
	group.Parent = parent
	self.group = group
	self.topInset = GuiService:GetGuiInset().Y
	group.Position = UDim2.new(0, 0, 0, -self.topInset)
	group.Size = UDim2.new(1, 0, 1, self.topInset)
	self.rail = Theme.frame(group, "NavigationRail", UDim2.new(), UDim2.new(0, 188, 1, 0), Theme.Void)
	self.topbar = Theme.frame(group, "MobileHeader", UDim2.new(), UDim2.new(1, 0, 0, 52), Theme.Void)
	self.headerProfile = Theme.text(group, "PlayerSummary", "", UDim2.new(), UDim2.new(), 11, Theme.Metal)
	self.logo = Theme.text(group, "Logo", "MAYHEM X", UDim2.fromOffset(24, 14), UDim2.new(0.6, 0, 0, 40), 26, Theme.White, true)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Theme.White, Theme.Metal)
	gradient.Parent = self.logo
	self.brandGradient = gradient
	local backdrop = Instance.new("UIGradient")
	backdrop.Color = ColorSequence.new(Theme.Surface, Theme.Navy)
	backdrop.Rotation = 18
	local backdropSurface = Theme.frame(group, "Backdrop", UDim2.new(), UDim2.fromScale(1, 1), Theme.White)
	backdropSurface.ZIndex = 0
	backdrop.Parent = backdropSurface
	self.closeButton = Theme.button(group, "Close", "RETURN  /  M", UDim2.new(1, -154, 0, 18), UDim2.fromOffset(130, 32), function() self:close() end, true)
	self.headerRule = Theme.frame(group, "HeaderRule", UDim2.new(0, 24, 0, 66), UDim2.new(1, -48, 0, 1), Theme.Purple, 0.45)
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
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = nav
	self.navLayout = layout
	for index, definition in { { "Deploy", "PLAY" }, { "Character", "OPERATORS" }, { "Inventory", "LOADOUT" }, { "Armory", "ARMORY" }, { "Progression", "PROGRESSION" }, { "Missions", "MISSIONS" }, { "Ranked", "RANKED / UNAVAILABLE" }, { "Leaderboards", "LEADERBOARDS" }, { "Settings", "SETTINGS" } } do
		local item = Theme.button(nav, definition[1], definition[2], UDim2.new(), UDim2.fromOffset(145, 44), function() self:open(definition[1]) end, true)
		item.LayoutOrder = index
		item.TextXAlignment = Enum.TextXAlignment.Left
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 38)
		padding.Parent = item
		Theme.icon(item, index)
		item.Icon.Position = UDim2.new(0, -26, 0.5, -8)
		item.SelectionMark.Position = UDim2.new(0, -38, 0.2, 0)
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
	self.eyebrow = Theme.text(deploy, "Eyebrow", "MAYHEM X / FIELD TEST", UDim2.new(), UDim2.new(0.65, 0, 0, 22), 11, Theme.Action)
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
	self.previewCaption = Theme.text(deploy, "PreviewCaption", "VANGUARD / PULSE", UDim2.new(0.56, 0, 1, -70), UDim2.new(0.44, 0, 0, 30), 12, Theme.Action)
	self.online = Theme.text(deploy, "Online", "", UDim2.new(0.56, 0, 1, -35), UDim2.new(0.44, 0, 0, 26), 11, Theme.Muted)

	self.frontier = Theme.button(deploy, "Frontier", "FIVE ARENAS  /  VIEW & VOTE", UDim2.new(), UDim2.new(), function() self:open("Maps") end, true)

	local maps = page("Maps")
	self.mapsTitle = Theme.text(maps, "Title", "CHOOSE YOUR FRONTIER", UDim2.new(), UDim2.new(1, 0, 0, 40), 27, Theme.Ink, true)
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
	self.mapSubtitle = Theme.text(maps, "MapSubtitle", "", UDim2.new(0.46, 0, 0.66, 0), UDim2.new(0.54, 0, 0, 30), 12, Theme.Action, true)
	self.mapStrategy = Theme.text(maps, "MapStrategy", "", UDim2.new(0.46, 0, 0.73, 0), UDim2.new(0.54, 0, 0, 70), 13, Theme.Muted)
	self.voteButton = Theme.button(maps, "Vote", "VOTE FOR THIS ARENA", UDim2.new(0, 0, 1, -54), UDim2.new(1, 0, 0, 46), function() callbacks.vote(self.draftMap) end)

	local mode = page("Mode")
	Theme.text(mode, "Title", "LAST SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 56), 32, Theme.Ink, true)
	Theme.text(mode, "Description", Visuals.Mode.Description .. "\n\nThis is the available game mode. Operatives and finishes change appearance only.", UDim2.fromOffset(0, 72), UDim2.new(0.9, 0, 0, 148), 17, Theme.Muted)
	Theme.button(mode, "Select", "SELECT LAST SIGNAL", UDim2.new(0, 0, 1, -56), UDim2.new(0.75, 0, 0, 48), function() self:open("Deploy") end)

	local matchmaking = page("Matchmaking")
	Theme.text(matchmaking, "Title", "FIND YOUR SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.Ink, true)
	self.queueTitle = Theme.text(matchmaking, "Status", "WAITING FOR SERVER", UDim2.fromOffset(0, 62), UDim2.new(1, 0, 0, 50), 24, Theme.Action, true)
	self.queueDetail = Theme.text(matchmaking, "Detail", "", UDim2.fromOffset(0, 130), UDim2.new(0.9, 0, 0, 95), 17, Theme.Muted)
	Theme.button(matchmaking, "ChooseMap", "MAP BALLOT  >", UDim2.fromOffset(0, 244), UDim2.new(0.62, 0, 0, 42), function() self:open("Maps") end, true)
	self.queueTimer = Theme.text(matchmaking, "Clock", "", UDim2.new(0, 0, 1, -128), UDim2.new(1, 0, 0, 44), 28, Theme.Action, true)
	self.queueCancel = Theme.button(matchmaking, "Queue", "LEAVE QUEUE", UDim2.new(0, 0, 1, -58), UDim2.new(0.62, 0, 0, 48), callbacks.queue)
	Theme.button(matchmaking, "Observe", "VIEW HUB", UDim2.new(0.66, 0, 1, -58), UDim2.new(0.34, 0, 0, 48), function() self:close() end, true)

	local character = page("Character")
	Theme.text(character, "Title", "OPERATIVE", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.Ink, true)
	self.operativeButtons = {}
	for index, entry in Visuals.Operatives do
		self.operativeButtons[entry.id] = Theme.button(character, entry.id, entry.name, UDim2.fromOffset(0, 54 + (index - 1) * 48), UDim2.new(0.5, -8, 0, 44), function() self.draftOperative = entry.id end, true)
	end
	self.operativeDetail = Theme.text(character, "Detail", "", UDim2.fromOffset(0, 210), UDim2.new(0.5, -8, 0, 80), 14, Theme.Muted)
	self.equipOperative = Theme.button(character, "Equip", "EQUIP PROFILE", UDim2.new(0, 0, 1, -54), UDim2.new(0.5, -8, 0, 46), function() callbacks.select("operative", self.draftOperative) end)
	self.characterPreview = Preview.new(character)
	self.characterPreview.frame.Position = UDim2.fromScale(0.53, 0.12)
	self.characterPreview.frame.Size = UDim2.fromScale(0.47, 0.72)

	local inventory = page("Inventory")
	Theme.text(inventory, "Title", "COLLECTION", UDim2.new(), UDim2.new(1, 0, 0, 40), 28, Theme.Ink, true)
	self.rifleTab = Theme.button(inventory, "Rifle", "VECTOR-18", UDim2.fromOffset(0, 50), UDim2.new(0.24, 0, 0, 44), function() self.weapon = 1 end, true)
	self.bladeTab = Theme.button(inventory, "Blade", "RIFT BLADE", UDim2.new(0.26, 0, 0, 50), UDim2.new(0.24, 0, 0, 44), function() self.weapon = 2 end, true)
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
	Theme.button(inventory, "StyleLab", "STYLE LAB  >", UDim2.new(0.53, 0, 1, -54), UDim2.new(0.47, 0, 0, 44), function() self:open("Shop") end, true)
	self.inventoryNote = Theme.text(inventory, "Note", "Both weapons stay in your loadout. Finishes change appearance only.", UDim2.new(0.53, 0, 1, -140), UDim2.new(0.47, 0, 0, 75), 12, Theme.Muted)

	local shop = page("Shop")
	Theme.text(shop, "Title", "STYLE LAB", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.Ink, true)
	self.shopWallet = Theme.text(shop, "Wallet", "", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 0, 44), 12, Theme.Muted)
	self.shopButtons = {}
	self.shopCards = {}
	self.shopPreviews = {}
	for index, id in { "Orchid", "Ember", "Aurum" } do
		local entry = Visuals.skin(id)
		local card = Theme.frame(shop, id, UDim2.new((index - 1) / 3, 0, 0, 100), UDim2.new(1 / 3, -12, 0, 310), Theme.Panel)
		self.shopCards[index] = card
		Theme.corner(card)
		Theme.stroke(card)
		local sample = Preview.new(card)
		sample.frame.Position, sample.frame.Size = UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 108)
		self.shopPreviews[id] = sample
		Theme.text(card, "Name", entry.name, UDim2.fromOffset(18, 128), UDim2.new(1, -36, 0, 32), 16, Theme.Ink, true)
		Theme.text(card, "Description", entry.description, UDim2.fromOffset(18, 172), UDim2.new(1, -36, 0, 68), 12, Theme.Muted)
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
	self.dailyClock = Theme.text(daily, "Clock", "", UDim2.new(0, 0, 1, -112), UDim2.new(1, 0, 0, 34), 14, Theme.Action)
	self.dailyButton = Theme.button(daily, "Claim", "CLAIM SESSION TRIAL", UDim2.new(0, 0, 1, -58), UDim2.new(0.78, 0, 0, 48), function()
		if self.style and self.style.dailyClaimed then self:open("Inventory"); self.draftSkin = "Prism" else callbacks.daily() end
	end)


	local armory = page("Armory")
	Theme.text(armory, "Title", "ENGINEERED FOR THE LAST SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 44), 30, Theme.Ink, true)
	Theme.text(armory, "Scope", "STANDARD ISSUE / EVERY CONTENDER HAS THE SAME LOADOUT", UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 28), 11, Theme.Cyan)
	self.armoryRifle = Theme.button(armory, "Rifle", "RANGED / VECTOR-18", UDim2.fromOffset(0, 94), UDim2.new(0.45, 0, 0, 44), function() self.weapon = 1 end, true)
	self.armoryBlade = Theme.button(armory, "Blade", "MELEE / RIFT BLADE", UDim2.new(0.48, 0, 0, 94), UDim2.new(0.45, 0, 0, 44), function() self.weapon = 2 end, true)
	self.armoryPreview = Preview.new(armory)
	self.armoryPreview.frame.Position = UDim2.new(0.42, 0, 0, 160)
	self.armoryPreview.frame.Size = UDim2.new(0.58, 0, 0, 260)
	self.weaponStats = Theme.text(armory, "Specification", "", UDim2.fromOffset(0, 168), UDim2.new(0.4, -12, 0, 240), 14, Theme.Muted)
	Theme.button(armory, "Finishes", "CUSTOMIZE FINISH  >", UDim2.new(0, 0, 1, -54), UDim2.new(0.6, 0, 0, 44), function() self:open("Inventory") end)

	local progression = page("Progression")
	Theme.text(progression, "Title", "YOUR SIGNAL", UDim2.new(), UDim2.new(1, 0, 0, 44), 34, Theme.Ink, true)
	Theme.text(progression, "Scope", "SERVER SESSION / ACCOUNT PERSISTENCE NOT RELEASED", UDim2.fromOffset(0, 52), UDim2.new(1, 0, 0, 28), 12, Theme.Gold)
	self.progressLevel = Theme.text(progression, "Level", "", UDim2.fromOffset(0, 104), UDim2.new(0.6, 0, 0, 70), 50, Theme.Ink, true)
	self.progressXP = Theme.text(progression, "XP", "", UDim2.fromOffset(0, 184), UDim2.new(1, 0, 0, 32), 16, Theme.Cyan)
	self.progressFill = Theme.bar(progression, "XPTrack", UDim2.fromOffset(0, 232), UDim2.new(0.9, 0, 0, 5), Theme.Purple)
	Theme.text(progression, "Rewards", "120 XP PER ELIMINATION / 300 XP PER WIN\n\nLevels currently track this session. No permanent unlocks, mastery, prestige or achievements are awarded yet.", UDim2.fromOffset(0, 262), UDim2.new(0.9, 0, 0, 130), 15, Theme.Muted)
	Theme.button(progression, "Collection", "EXPLORE YOUR COLLECTION  >", UDim2.new(0, 0, 1, -54), UDim2.new(0.7, 0, 0, 44), function() self:open("Inventory") end)

	local missions = page("Missions")
	Theme.text(missions, "Title", "OBJECTIVES", UDim2.new(), UDim2.new(1, 0, 0, 44), 34, Theme.Ink, true)
	Theme.text(missions, "Availability", "DAILY / WEEKLY MISSION TRACKING NOT RELEASED", UDim2.fromOffset(0, 58), UDim2.new(1, 0, 0, 40), 13, Theme.Gold)
	Theme.text(missions, "Available", "AVAILABLE NOW / DAILY CACHE", UDim2.fromOffset(0, 130), UDim2.new(1, 0, 0, 42), 24, Theme.Ink, true)
	Theme.text(missions, "Detail", "Claim the Prism finish and 15 earned credits for this server session. No streak, purchase or daily penalty.", UDim2.fromOffset(0, 192), UDim2.new(0.85, 0, 0, 92), 16, Theme.Muted)
	Theme.button(missions, "Cache", "OPEN DAILY CACHE  >", UDim2.new(0, 0, 1, -54), UDim2.new(0.7, 0, 0, 44), function() self:open("Daily") end)

	local ranked = page("Ranked")
	Theme.text(ranked, "Title", "COMPETITIVE", UDim2.new(), UDim2.new(1, 0, 0, 44), 34, Theme.Ink, true)
	Theme.text(ranked, "Availability", "RANKED IS NOT AVAILABLE", UDim2.fromOffset(0, 100), UDim2.new(1, 0, 0, 50), 26, Theme.Gold, true)
	Theme.text(ranked, "Detail", "Last Signal is the current unranked mode. Skill ratings, competitive divisions and seasonal rewards have not been released.\n\nYour equipment has equal combat stats in every arena.", UDim2.fromOffset(0, 176), UDim2.new(0.9, 0, 0, 160), 17, Theme.Muted)
	Theme.button(ranked, "Unranked", "PLAY LAST SIGNAL  >", UDim2.new(0, 0, 1, -54), UDim2.new(0.7, 0, 0, 44), function() self:open("Deploy") end)

	local leaderboard = page("Leaderboards")
	Theme.text(leaderboard, "Title", "SERVER LEADERBOARD", UDim2.new(), UDim2.new(1, 0, 0, 44), 34, Theme.Ink, true)
	Theme.text(leaderboard, "Scope", "CURRENT SERVER / WINS THEN ELIMINATIONS / GLOBAL RANKING NOT RELEASED", UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 42), 12, Theme.Muted)
	self.boardRows = Theme.frame(leaderboard, "Standings", UDim2.fromOffset(0, 112), UDim2.new(1, 0, 1, -112), nil, 1)
	self.boardKey = ""
	local boardLayout = Instance.new("UIListLayout")
	boardLayout.Padding = UDim.new(0, 6)
	boardLayout.Parent = self.boardRows

	local settings = page("Settings")
	Theme.text(settings, "Title", "SYSTEMS", UDim2.new(), UDim2.new(1, 0, 0, 42), 30, Theme.Ink, true)
	self.settingButtons = {}
	for index, definition in { { "camera", callbacks.camera }, { "fov", callbacks.fov }, { "graphics", callbacks.graphics }, { "effects", callbacks.effects }, { "motion", callbacks.motion }, { "music", callbacks.music }, { "sound", callbacks.sound }, { "ui", callbacks.ui }, { "mute", callbacks.mute }, { "testAudio", callbacks.testAudio } } do
		local item = Theme.button(settings, definition[1], "", UDim2.fromOffset(0, 54 + (index - 1) * 48), UDim2.new(1, 0, 0, 42), definition[2], true)
		self.settingButtons[definition[1]] = item
	end
	self.audioNote = Theme.text(settings, "AudioNote", "", UDim2.new(0, 0, 1, -100), UDim2.new(1, 0, 0, 54), 12, Theme.Muted)
	self.saveNote = Theme.text(settings, "SaveStatus", "", UDim2.new(0, 0, 1, -42), UDim2.new(1, 0, 0, 36), 12, Theme.Action)
	self.confirm = Theme.frame(group, "PurchaseConfirmation", UDim2.new(), UDim2.fromScale(1, 1), Theme.Surface)
	self.confirm.ZIndex = 30
	self.confirm.Active = true
	self.confirm.Visible = false
	Theme.text(self.confirm, "Title", "ADD AURUM TO YOUR COLLECTION?", UDim2.fromScale(0.1, 0.22), UDim2.fromScale(0.8, 0.15), 26, Theme.Ink, true)
	Theme.text(self.confirm, "Scope", "45 earned session credits. Cosmetic only.\nYour collection and balance reset after leaving this server.", UDim2.fromScale(0.1, 0.4), UDim2.fromScale(0.8, 0.18), 16, Theme.Muted)
	self.confirmBuy = Theme.button(self.confirm, "Confirm", "SPEND 45 CREDITS", UDim2.fromScale(0.1, 0.66), UDim2.new(0.8, 0, 0, 46), function()
		self:dismissConfirmation()
		callbacks.purchase("Aurum")
	end)
	self.confirmCancel = Theme.button(self.confirm, "Cancel", "CANCEL", UDim2.fromScale(0.1, 0.8), UDim2.new(0.8, 0, 0, 46), function() self:dismissConfirmation() end, true)
	self:open("Deploy")
	return self
end

function Menus.open(self: any, page: string)
	if not self.pages[page] then return end
	self.serial += 1
	self.page = page
	self:dismissConfirmation()
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
	self.armoryPreview:hide()
	for _, preview in self.shopPreviews do preview:hide() end
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		GuiService.SelectedObject = if page == "Deploy" then self.play elseif page == "Matchmaking" then self.queueCancel else self.navigation[page] or self.closeButton
	end
end

function Menus.confirmPurchase(self: any, id: string)
	if id ~= "Aurum" then return end
	self.confirm.Visible = true
	for _, item in self.group:GetDescendants() do if item:IsA("GuiButton") and not item:IsDescendantOf(self.confirm) then item.Selectable = false end end
	self.confirmBuy.Active = self.style and self.style.ready and (self.style.profile.credits or 0) >= 45
	self.confirmBuy.Text = if self.confirmBuy.Active then "SPEND 45 CREDITS" else "EARN MORE SESSION CREDITS"
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then GuiService.SelectedObject = if self.confirmBuy.Active then self.confirmBuy else self.confirmCancel end
end

function Menus.dismissConfirmation(self: any)
	if not self.confirm.Visible then return end
	self.confirm.Visible = false
	for _, item in self.group:GetDescendants() do if item:IsA("GuiButton") then item.Selectable = true end end
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then GuiService.SelectedObject = self.shopButtons.Aurum end
end

function Menus.close(self: any)
	self.serial += 1
	local serial = self.serial
	self.page = nil
	self:dismissConfirmation()
	GuiService.SelectedObject = nil
	if self.fade then self.fade:Cancel() end
	self.fade = TweenService:Create(self.group, TweenInfo.new(if self.reducedMotion then 0 else 0.14), { GroupTransparency = 1 })
	self.fade:Play()
	task.delay(0.14, function()
		if self.serial == serial then
			self.group.Visible = false
			self.preview:hide(); self.characterPreview:hide(); self.weaponPreview:hide(); self.mapPreview:hide(); self.armoryPreview:hide()
			for _, preview in self.shopPreviews do preview:hide() end
		end
	end)
end

function Menus.render(self: any, state: any, elapsed: number, preferences: any, style: any)
	if not self.page then return end
	self.style = style
	self.state = state
	self.reducedMotion = preferences.reducedMotion
	Theme.reducedMotion = preferences.reducedMotion
	local selected = GuiService.SelectedObject
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 and (not selected or not selected:IsDescendantOf(self.group) or (self.confirm.Visible and not selected:IsDescendantOf(self.confirm))) then
		GuiService.SelectedObject = if self.confirm.Visible then (if self.confirmBuy.Active then self.confirmBuy else self.confirmCancel) elseif self.page == "Deploy" then self.play elseif self.page == "Matchmaking" then self.queueCancel else self.navigation[self.page] or self.closeButton
	end
	local width = self.group.AbsoluteSize.X
	local height = self.group.AbsoluteSize.Y
	local topInset = GuiService:GetGuiInset().Y
	if topInset ~= self.topInset then
		self.topInset = topInset
		self.group.Position = UDim2.new(0, 0, 0, -topInset)
		self.group.Size = UDim2.new(1, 0, 1, topInset)
	end
	local compact = width < 640
	local short = height < 540
	self.queueTimer.Visible = not short
	local rail = width >= 760 and not short
	self.rail.Visible = rail
	self.topbar.Visible = not rail
	self.headerRule.Visible = false
	self.logo.Position = UDim2.fromOffset(rail and 18 or 16, rail and 24 or 6)
	self.logo.Size = UDim2.fromOffset(158, 38)
	self.logo.TextSize = rail and 27 or 24
	self.closeButton.Size = UDim2.fromOffset(rail and 152 or 100, 40)
	self.closeButton.Position = if rail then UDim2.new(0, 18, 1, -65) else UDim2.new(1, -116, 0, 6)
	self.navLayout.FillDirection = if rail then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal
	self.nav.ScrollingDirection = if rail then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X
	self.nav.AutomaticCanvasSize = if rail then Enum.AutomaticSize.Y else Enum.AutomaticSize.X
	self.nav.Position = if rail then UDim2.fromOffset(16, 116) else UDim2.new(0, 16, 1, -64)
	self.nav.Size = if rail then UDim2.new(0, 156, 1, -238) else UDim2.new(1, -32, 0, 46)
	for _, item in self.navigation do
		item.Size = UDim2.fromOffset(rail and 156 or 144, 44)
		item.TextSize = 15
		if rail and item ~= self.navigation[self.page] then item.BackgroundColor3, item.TextColor3 = Theme.Void, Theme.Muted end
	end
	self.content.Position = UDim2.fromOffset(rail and 216 or 16, rail and 28 or 68)
	self.content.Size = UDim2.new(1, rail and -248 or -32, 1, rail and -88 or -164)
	self.footer.Position = if rail then UDim2.new(0, 216, 1, -42) else UDim2.new(0, 16, 1, -92)
	self.footer.Size = UDim2.new(1, rail and -248 or -32, 0, 24)
	self.footer.TextSize = 10
	self.headerProfile.Position = if rail then UDim2.new(0, 18, 1, -148) else UDim2.new(0.4, 0, 0, 8)
	self.headerProfile.Size = if rail then UDim2.fromOffset(152, 68) else UDim2.new(0.6, -132, 0, 36)
	for name, area in self.pages do
		local minimum = if name == "Settings" then 680 elseif name == "Deploy" then 0 elseif name == "Maps" then (if compact then 790 else 490) elseif name == "Leaderboards" then 112 + #Players:GetPlayers() * 52 elseif name == "Progression" then 480 elseif name == "Armory" then 490 elseif name == "Inventory" then 520 elseif name == "Shop" then (if compact then 1110 else 440) elseif name == "Matchmaking" then (if short then 0 else 470) else 420
		area.Size = UDim2.new(1, -8, 0, math.max(minimum, self.content.AbsoluteSize.Y))
	end
	local heroHeight = self.pages.Deploy.AbsoluteSize.Y
	local portrait = width < 500
	self.hero.Text = if heroHeight < 240 then "ENTER THE CHAOS." else "ENTER THE\nCHAOS."
	self.hero.TextSize = if portrait then 42 elseif heroHeight < 320 then 30 elseif short then 42 else 62
	self.hero.Position = UDim2.fromOffset(0, 26)
	self.hero.Size = UDim2.new(0.52, 0, 0, if heroHeight < 260 then 58 elseif heroHeight < 320 then 82 else 142)
	self.frontier.Position = UDim2.new(0.55, 0, 1, -35)
	self.frontier.Size = UDim2.new(0.45, 0, 0, 32)
	self.frontier.TextSize = 12
	self.previewCaption.Visible = false
	self.mapsTitle.TextSize = if compact then 22 else 30
	self.deployDescription.Position = UDim2.fromOffset(0, 178)
	self.deployDescription.Size = UDim2.new(0.48, 0, 0, 68)
	self.deployDescription.TextSize = 16
	self.deployDescription.Visible = heroHeight > 420
	self.mapLink.Position = UDim2.fromOffset(0, 266)
	self.mapLink.Size = UDim2.new(0.48, 0, 0, 44)
	self.mapLink.Visible = heroHeight > 480
	self.profile.Visible = false
	self.preview.frame.Position = UDim2.fromScale(0.55, 0)
	self.preview.frame.Size = UDim2.new(0.45, 0, 1, -42)
	self.modeButton.Visible = heroHeight >= 240
	self.modeButton.Position = UDim2.new(0, 0, 1, -100)
	self.modeButton.Size = UDim2.new(0.5, -8, 0, 44)
	self.play.Position = UDim2.new(0, 0, 1, -48)
	self.play.Size = UDim2.new(0.5, -8, 0, 44)
	self.previewCaption.Position = UDim2.new(0.55, 0, 1, -36)
	self.previewCaption.Size = UDim2.new(0.45, 0, 0, 28)
	self.online.Visible = false
	self.previewCaption.Visible = false
	if portrait then
		self.hero.Size = UDim2.new(1, 0, 0, 124)
		self.preview.frame.Position = UDim2.new(0.15, 0, 0, 154)
		self.preview.frame.Size = UDim2.new(0.7, 0, 1, -296)
		self.play.Size = UDim2.new(1, 0, 0, 44)
		self.modeButton.Size = UDim2.new(1, 0, 0, 44)
		self.frontier.Visible = false
	else self.frontier.Visible = true end
	self.deployDescription.Visible = heroHeight > 420 and not portrait
	self.mapLink.Visible = heroHeight > 480 and not portrait
	self.characterPreview.frame.Position = UDim2.new(0.53, 0, 0, 42)
	self.characterPreview.frame.Size = UDim2.new(0.47, 0, 0, if short then 150 else 300)
	for index, entry in Visuals.Operatives do
		local item = self.operativeButtons[entry.id]
		item.Position = if short then UDim2.new((index - 1) * 0.18, 0, 0, 48) else UDim2.fromOffset(0, 54 + (index - 1) * 48)
		item.Size = UDim2.new(if short then 0.17 else 0.5, if short then 0 else -8, 0, 44)
	end
	self.equipOperative.Position = if short then UDim2.fromOffset(0, 108) else UDim2.new(0, 0, 1, -54)
	self.equipOperative.Size = UDim2.new(if short then 0.52 else 0.5, -8, 0, 44)
	if short then self.characterPreview.frame.Position = UDim2.new(0.57, 0, 0, 0) end
	local profile = style.profile or { credits = 0, level = 1, xp = 0, status = "LOADING" }
	if self.confirm.Visible then
		self.confirmBuy.Active = style.ready and profile.credits >= 45
		self.confirmBuy.Text = if self.confirmBuy.Active then "SPEND 45 CREDITS" else "EARN MORE SESSION CREDITS"
	end
	self.profile.Text = string.upper(Players.LocalPlayer.DisplayName) .. " / LV " .. profile.level .. "\n" .. profile.credits .. " CREDITS / " .. profile.xp .. " XP / THIS SESSION"
	self.headerProfile.Text = string.upper(Players.LocalPlayer.DisplayName) .. "\nLV " .. profile.level .. " / " .. profile.credits .. " CR / SESSION"
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

	self.progressLevel.Text = "LEVEL " .. profile.level
	self.progressXP.Text = (profile.xp % 300) .. " / 300 XP TO NEXT LEVEL"
	self.progressFill.Size = UDim2.fromScale((profile.xp % 300) / 300, 1)
	Theme.selected(self.armoryRifle, self.weapon == 1)
	Theme.selected(self.armoryBlade, self.weapon == 2)
	self.weaponStats.Text = if self.weapon == 1 then string.format("VECTOR-18 / AUTO\n\n%d DAMAGE\n%.2fs FIRE INTERVAL\n%d STUD RANGE\n%d + %d AMMUNITION\n%.1fs RELOAD\n\nNO MASTERY BONUSES", Config.Rifle.Damage, Config.Rifle.Interval, Config.Rifle.Range, Config.Rifle.Magazine, Config.Rifle.Reserve, Config.Rifle.ReloadTime) else string.format("RIFT BLADE / MELEE\n\n%d DAMAGE\n%.2fs ATTACK INTERVAL\n%d STUD RANGE\nLINE OF SIGHT REQUIRED\n\nNO MASTERY BONUSES", Config.Blade.Damage, Config.Blade.Interval, Config.Blade.Range)
	local roster = {}
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		table.insert(roster, {id = player.UserId, name = player.DisplayName, wins = if stats and stats:FindFirstChild("Wins") then stats.Wins.Value else 0, kills = if stats and stats:FindFirstChild("Kills") then stats.Kills.Value else 0})
	end
	table.sort(roster, function(a, b) if a.wins ~= b.wins then return a.wins > b.wins elseif a.kills ~= b.kills then return a.kills > b.kills else return a.id < b.id end end)
	local parts = {}
	for _, player in roster do table.insert(parts, player.id .. ":" .. player.name .. ":" .. player.wins .. ":" .. player.kills) end
	local boardKey = table.concat(parts, "|")
	if self.boardKey ~= boardKey then
		self.boardKey = boardKey
		for _, child in self.boardRows:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
		for index, player in roster do
			local row = Theme.frame(self.boardRows, "Contender", UDim2.new(), UDim2.new(1, -8, 0, 46), Theme.Panel)
			row.LayoutOrder = index
			Theme.text(row, "Name", string.format("%02d  %s", index, player.name), UDim2.fromOffset(14, 4), UDim2.new(0.6, -14, 1, -8), 15, if player.id == Players.LocalPlayer.UserId then Theme.Cyan else Theme.Ink)
			Theme.text(row, "Score", player.wins .. " W / " .. player.kills .. " K", UDim2.fromScale(0.64, 0.12), UDim2.fromScale(0.34, 0.76), 13, Theme.Muted)
		end
	end
	local buttons = self.settingButtons
	local order = {"camera", "fov", "graphics", "effects", "motion", "music", "sound", "ui", "mute", "testAudio"}
	for index, name in order do
		local item = buttons[name]
		local twoColumns = width >= 700
		item.Position = if twoColumns then UDim2.new(if index > 5 then 0.52 else 0, 0, 0, 70 + ((index - 1) % 5) * 56) else UDim2.fromOffset(0, 54 + (index - 1) * 48)
		item.Size = UDim2.new(if twoColumns then 0.48 else 1, 0, 0, 44)
	end
	self.audioNote.Position = if width >= 700 then UDim2.new(0.52, 0, 0, 368) else UDim2.new(0, 0, 1, -100)
	self.audioNote.Size = UDim2.new(if width >= 700 then 0.48 else 1, 0, 0, 76)
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
	elseif self.page == "Maps" then self.mapPreview:map(self.draftMap)
	elseif self.page == "Armory" then self.armoryPreview:show("weapon", style.operative, style.skin, self.weapon)
	elseif self.page == "Shop" then for id, preview in self.shopPreviews do preview:show("weapon", style.operative, id, 1); preview:step(true) end end
end

function Menus.animate(self: any)
	if not self.page then return end
	self.brandGradient.Offset = if self.reducedMotion then Vector2.zero else Vector2.new(math.sin(os.clock() * 0.3) * 0.35, 0)
	if self.page == "Deploy" then self.preview:step(self.reducedMotion)
	elseif self.page == "Character" then self.characterPreview:step(self.reducedMotion)
	elseif self.page == "Inventory" then self.weaponPreview:step(self.reducedMotion)
	elseif self.page == "Armory" then self.armoryPreview:step(self.reducedMotion) end
end

return Menus
