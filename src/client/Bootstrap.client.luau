--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local mayhem = ReplicatedStorage:WaitForChild("Mayhem")
local shared = mayhem:WaitForChild("Shared")
local Config = require(shared:WaitForChild("Config"))
local Protocol = require(shared:WaitForChild("Protocol"))
local MapRules = require(shared:WaitForChild("MapRules"))
local PreferenceRules = require(shared:WaitForChild("PreferenceRules"))
local Hud = require(script.Parent.Hud)
local CameraController = require(script.Parent.CameraController)
local Effects = require(script.Parent.Effects)
local Theme = require(script.Parent.Theme)
local AudioController = require(script.Parent.AudioController)
local WorldPresentation = require(script.Parent.WorldPresentation)
local remotes = mayhem:WaitForChild("Remotes")
local action = remotes:WaitForChild(Protocol.Remote.Action) :: RemoteEvent
local stateRemote = remotes:WaitForChild(Protocol.Remote.State) :: RemoteEvent
local effectRemote = remotes:WaitForChild(Protocol.Remote.Effect) :: RemoteEvent
local feedRemote = remotes:WaitForChild(Protocol.Remote.Feed) :: RemoteEvent
local presentationRemote = mayhem:WaitForChild("Presentation") :: RemoteEvent
local preferences: any = table.clone(PreferenceRules.Defaults)
preferences.skin, preferences.loaded, preferences.saveStatus = "Pulse", false, "LOADING"
local style: any = { skin = "Pulse", operative = "Vanguard", owned = { Pulse = true, Glacier = true }, dailyClaimed = false, nextDaily = 0, revision = 0, ready = false, profile = { credits = 0, level = 1, xp = 0, status = "LOADING" } }
local camera = CameraController.new(preferences)
local effects = Effects.new(preferences)
local audio = AudioController.new(preferences)
local worldPresentation = WorldPresentation.new(preferences)
Theme.onClick = function() audio:play("UI") end
Theme.onHover = function() audio:play("Hover") end
effects.onEliminated = function(position: Vector3, userId: number) audio:play("Eliminate", position, userId) end
local firing = false
local shotAt = -math.huge
local coreMenuOpen = false
local receivedAt = os.clock()
local state: any = {
	phase = "Waiting", roundId = 0, remaining = 0, queued = false, queueCount = 0, capacity = 16,
	inMatch = false, alive = false, remainingPlayers = 0, kills = 0, result = nil,
	combat = { health = 100, shield = 40, ammo = 18, reserve = 108, slot = 1, ultimate = 0, abilityRemaining = 0, reloadRemaining = 0, protectionRemaining = 0 },
	map = { id = "Collapse", name = "THE COLLAPSE", votes = {}, safeRadius = 185, center = Vector3.zero, duel = false, chaos = "STABLE" },
}
local hud: any
local settingsSerial, serverVersion, sentSerial, expectedVersion = 0, 0, 0, 0
local dirty, awaiting, saveAt, sentAt = false, false, 0, 0

local function setting(key: string, value: any)
	if not preferences.loaded then return end
	preferences[key] = value
	settingsSerial += 1
	dirty = true
	saveAt = os.clock() + 0.65
	preferences.saveStatus = "SYNCING WITH SERVER"
end

local function volume(key: string)
	setting(key, if preferences[key] >= 1 then 0 else math.min(1, math.round((preferences[key] + 0.25) * 100) / 100))
end

local function canAct(): boolean
	return state.phase == "Active" and state.alive and not hud:blocked() and not coreMenuOpen and UserInputService:GetFocusedTextBox() == nil
end

local function send(command: string)
	if canAct() then action:FireServer(command) end
end

local function switch()
	if canAct() then action:FireServer(Protocol.Action.Switch, if state.combat.slot == 1 then 2 else 1) end
end

hud = Hud.new({
	queue = function() if not state.inMatch then action:FireServer(Protocol.Action.Queue, not state.queued) end end,
	ability = function() send(Protocol.Action.Ability) end,
	ultimate = function() send(MapRules.Command.Ultimate) end,
	reload = function() send(Protocol.Action.Reload) end,
	switch = switch,
	camera = function() setting("firstPerson", not preferences.firstPerson) end,
	fov = function() setting("fov", if preferences.fov >= 100 then 70 else math.min(100, preferences.fov + 10)) end,
	effects = function() setting("reducedEffects", not preferences.reducedEffects) end,
	fire = function(held: boolean) firing = held and canAct() end,
	select = function(kind: string, id: string) style.notice = "Requesting style..."; presentationRemote:FireServer("Select", { kind = kind, id = id }) end,
	claim = function(id: string) style.notice = "Requesting session style..."; presentationRemote:FireServer("Claim", id) end,
	purchase = function(id: string) style.notice = "Confirming session purchase..."; presentationRemote:FireServer("Purchase", id) end,
	vote = function(id: string) action:FireServer(MapRules.Command.Vote, id) end,
	daily = function() style.notice = "Requesting session trial..."; presentationRemote:FireServer("Daily") end,
	graphics = function() setting("graphics", if preferences.graphics == "Auto" then "High" elseif preferences.graphics == "High" then "Low" else "Auto") end,
	music = function() volume("music") end,
	sound = function() volume("sound") end,
	ui = function() volume("ui") end,
	mute = function() setting("muted", not preferences.muted) end,
	motion = function() setting("reducedMotion", not preferences.reducedMotion) end,
	testAudio = function() audio:play("Reward"); style.notice = audio:status() .. (if preferences.muted then " / UNMUTE TO HEAR THE TEST" else "") end,
	transition = function() audio:play("Transition") end,
})

local function bind(name: string, callback: () -> (), ...: Enum.KeyCode)
	ContextActionService:BindAction(name, function(_: string, inputState: Enum.UserInputState)
		if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if inputState == Enum.UserInputState.Begin then callback() end
		return Enum.ContextActionResult.Sink
	end, false, ...)
end

ContextActionService:BindAction("MayhemAttack", function(_: string, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then firing = canAct()
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then firing = false end
	return if canAct() then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
bind("MayhemRifle", function() if canAct() then action:FireServer(Protocol.Action.Switch, 1) end end, Enum.KeyCode.One)
bind("MayhemBlade", function() if canAct() then action:FireServer(Protocol.Action.Switch, 2) end end, Enum.KeyCode.Two)
bind("MayhemSwitch", switch, Enum.KeyCode.ButtonL1)
bind("MayhemReload", function() send(Protocol.Action.Reload) end, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
bind("MayhemAbility", function() send(Protocol.Action.Ability) end, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)
bind("MayhemUltimate", function() send(MapRules.Command.Ultimate) end, Enum.KeyCode.G, Enum.KeyCode.ButtonB)
bind("MayhemCamera", function() setting("firstPerson", not preferences.firstPerson) end, Enum.KeyCode.C, Enum.KeyCode.DPadDown)
bind("MayhemMenu", function() firing = false; hud:toggleMenu() end, Enum.KeyCode.M, Enum.KeyCode.DPadLeft)

GuiService.MenuOpened:Connect(function() coreMenuOpen = true; firing = false end)
GuiService.MenuClosed:Connect(function() coreMenuOpen = false end)
UserInputService.WindowFocusReleased:Connect(function() firing = false end)
Players.LocalPlayer.CharacterRemoving:Connect(function() firing = false; camera:setActive(false) end)

stateRemote.OnClientEvent:Connect(function(nextState: any)
	if nextState.phase ~= state.phase then
		if nextState.inMatch and (nextState.phase == "Loading" or nextState.phase == "Countdown" or nextState.phase == "Results") then hud:closeMenus() end
		if nextState.phase == "Active" and nextState.alive then hud:announce("SIGNAL LIVE", "Last contender standing wins. Insertion shield is active.") end
		if nextState.phase == "Active" then
			for _, contender in Players:GetPlayers() do
				local character = contender.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if root and math.abs(root.Position.X) < Config.Arena.Bound and math.abs(root.Position.Z) < Config.Arena.Bound then effects:play("Protection", { character = character, duration = Config.Match.SpawnProtection }) end
			end
		end
		if nextState.phase == "Results" and nextState.result then audio:play(if nextState.result.winnerId == Players.LocalPlayer.UserId then "Reward" else "Notification") end
	end
	if state.alive and state.roundId == nextState.roundId then
		local shieldLoss = math.max(0, state.combat.shield - nextState.combat.shield)
		local hullLoss = math.max(0, state.combat.health - nextState.combat.health)
		if shieldLoss + hullLoss > 0 then hud:damage(shieldLoss + hullLoss, hullLoss == 0); audio:play(if hullLoss == 0 then "Shield" else "MeleeHit") end
		if nextState.combat.reloadRemaining > state.combat.reloadRemaining + 0.4 then audio:play("Reload") end
		if nextState.combat.slot ~= state.combat.slot then audio:play("Switch") end
		if state.combat.shield > 0 and nextState.combat.shield <= 0 then
			local character = Players.LocalPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if root then effects:play("ShieldBreak", { character = character, at = root.Position }) end
		end
	end
	if nextState.roundId ~= state.roundId or not nextState.alive then firing = false end
	state = nextState
	camera.reloadUntil = os.clock() + nextState.combat.reloadRemaining
	receivedAt = os.clock()
end)
presentationRemote.OnClientEvent:Connect(function(snapshot: any)
	if snapshot.revision > style.revision then
		local acquired = false
		for id in snapshot.owned do if not style.owned[id] then acquired = true; break end end
		if acquired then audio:play(if snapshot.owned.Aurum and not style.owned.Aurum then "Purchase" else "Reward") end
	elseif snapshot.notice and snapshot.notice ~= "Preferences accepted." then audio:play("Notification") end
	style = snapshot
	style.ready = true
	preferences.skin = style.skin
	local profile = snapshot.profile
	serverVersion = profile.version
	if awaiting and profile.version >= expectedVersion then
		awaiting = false
		if settingsSerial == sentSerial then dirty = false end
	end
	if profile.status ~= "LOADING" then
		if not dirty and not awaiting then
			for key in PreferenceRules.Defaults do preferences[key] = profile.preferences[key] end
		end
		preferences.loaded = true
	end
	preferences.saveStatus = if dirty or awaiting then "SYNCING WITH SERVER" else profile.status
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	local screen = prompt:GetAttribute("MayhemScreen")
	local world = workspace:FindFirstChild("MayhemWorld")
	if type(screen) == "string" and world and prompt:IsDescendantOf(world) then hud:openPage(screen) end
end)
feedRemote.OnClientEvent:Connect(function(data: any) hud:addFeed(data) end)
effectRemote.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "Notice" then
		hud:announce(data.title, data.body)
		audio:play("Notification")
		if data.title == "LOW GRAVITY" or data.title == "SHIELD DROUGHT" then
			audio:play("Mutation")
			local character = Players.LocalPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if root and state.alive then effects:play("Mutation", { at = root.Position }) end
		end
	elseif kind == "Hit" then
		hud:hit(data.lethal)
		if state.combat.slot == 2 then audio:play("MeleeHit") end
		if state.combat.slot == 2 and workspace.CurrentCamera then effects:play("MeleeHit", { at = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 5 }) end
	else
		effects:play(kind, data)
		if kind == "Shot" then
			audio:play("Shot", data.from, data.userId)
			if data.userId == Players.LocalPlayer.UserId then camera.kickUntil = os.clock() + 0.1 end
			if data.impact then audio:play("Impact", data.to, data.userId) end
		elseif kind == "Slash" then audio:play("Slash", data.at.Position, data.userId)
		elseif kind == "Pulse" then audio:play("Repulse", data.at)
		elseif kind == "Ultimate" then audio:play("Ultimate", data.at, data.userId)
		elseif kind == "Destruction" then audio:play("Explosion", data.at) end
		if kind == "Slash" and data.userId == Players.LocalPlayer.UserId then camera.swingUntil = os.clock() + 0.2 end
	end
end)

RunService:BindToRenderStep("MayhemCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	camera:setActive(canAct())
	camera:step(dt, state.combat.slot)
	worldPresentation:animate()
	hud:animate(preferences)
end)
local accumulated = 0
RunService.Heartbeat:Connect(function(dt: number)
	accumulated += dt
	if not canAct() then firing = false end
	local now = os.clock()
	if firing and canAct() then
		local interval = if state.combat.slot == 1 then Config.Rifle.Interval else Config.Blade.Interval
		if now - shotAt >= interval then
			local direction = camera:aim()
			if direction then
				shotAt = now
				action:FireServer(if state.combat.slot == 1 then Protocol.Action.Fire else Protocol.Action.Melee, direction)
			end
		end
	end
	if accumulated >= 0.1 then
		accumulated = 0
		if awaiting and now - sentAt > 4 then awaiting = false; dirty = true; saveAt = now end
		if dirty and not awaiting and now >= saveAt then
			local values: any = {}
			for key in PreferenceRules.Defaults do values[key] = preferences[key] end
			sentSerial, expectedVersion, sentAt = settingsSerial, serverVersion + 1, now
			awaiting = true
			presentationRemote:FireServer("Preferences", values)
		end
		preferences.audioStatus = audio:status() .. (if (audio.root:GetAttribute("MusicConfigured") or 0) < 10 then "\nSome soundtrack routes are unconfigured." else "\nOriginal tracks configured. Check failures in Studio Output.")
		hud:render(state, now - receivedAt, preferences, style)
		worldPresentation:step(state)
		audio:update(state)
	end
end)
hud:render(state, 0, preferences, style)
action:FireServer(Protocol.Action.Ready)
presentationRemote:FireServer("Request")
