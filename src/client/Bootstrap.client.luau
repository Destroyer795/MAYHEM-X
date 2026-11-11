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
local preferences = { firstPerson = false, fov = 80, reducedEffects = false, reducedMotion = false, graphics = "Auto", music = 0.35, sound = 0.7, ui = 0.55, muted = false, skin = "Pulse" }
local style: any = { skin = "Pulse", operative = "Vanguard", owned = { Pulse = true, Glacier = true }, dailyClaimed = false, nextDaily = 0, revision = 0, ready = false }
local camera = CameraController.new(preferences)
local effects = Effects.new(preferences)
local audio = AudioController.new(preferences)
local worldPresentation = WorldPresentation.new(preferences)
Theme.onClick = function() audio:play("UI") end
local firing = false
local shotAt = -math.huge
local coreMenuOpen = false
local receivedAt = os.clock()
local state: any = {
	phase = "Waiting", roundId = 0, remaining = 0, queued = false, queueCount = 0, capacity = 16,
	inMatch = false, alive = false, remainingPlayers = 0, kills = 0, result = nil,
	combat = { health = 100, shield = 40, ammo = 18, reserve = 108, slot = 1, abilityRemaining = 0, reloadRemaining = 0, protectionRemaining = 0 },
}
local hud: any

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
	reload = function() send(Protocol.Action.Reload) end,
	switch = switch,
	camera = function() preferences.firstPerson = not preferences.firstPerson end,
	fov = function() preferences.fov = if preferences.fov >= 90 then 70 else preferences.fov + 10 end,
	effects = function() preferences.reducedEffects = not preferences.reducedEffects end,
	fire = function(held: boolean) firing = held and canAct() end,
	select = function(kind: string, id: string) style.notice = "Requesting style..."; presentationRemote:FireServer("Select", { kind = kind, id = id }) end,
	claim = function(id: string) style.notice = "Requesting session style..."; presentationRemote:FireServer("Claim", id) end,
	daily = function() style.notice = "Requesting session trial..."; presentationRemote:FireServer("Daily") end,
	graphics = function() preferences.graphics = if preferences.graphics == "Auto" then "High" elseif preferences.graphics == "High" then "Low" else "Auto" end,
	music = function() preferences.music = if preferences.music >= 1 then 0 else math.min(1, preferences.music + 0.25) end,
	sound = function() preferences.sound = if preferences.sound >= 1 then 0 else math.min(1, preferences.sound + 0.25) end,
	motion = function() preferences.reducedMotion = not preferences.reducedMotion end,
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
bind("MayhemCamera", function() preferences.firstPerson = not preferences.firstPerson end, Enum.KeyCode.C, Enum.KeyCode.DPadDown)
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
		if nextState.phase == "Results" and nextState.result then audio:play(if nextState.result.winnerId == Players.LocalPlayer.UserId then "Victory" else "Defeat") end
	end
	if state.alive and state.roundId == nextState.roundId then
		local shieldLoss = math.max(0, state.combat.shield - nextState.combat.shield)
		local hullLoss = math.max(0, state.combat.health - nextState.combat.health)
		if shieldLoss + hullLoss > 0 then hud:damage(shieldLoss + hullLoss, hullLoss == 0) end
		if state.combat.shield > 0 and nextState.combat.shield <= 0 then
			local character = Players.LocalPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if root then effects:play("ShieldBreak", { character = character, at = root.Position }) end
		end
	end
	if nextState.roundId ~= state.roundId or not nextState.alive then firing = false end
	state = nextState
	receivedAt = os.clock()
end)
presentationRemote.OnClientEvent:Connect(function(snapshot: any)
	style = snapshot
	style.ready = true
	preferences.skin = style.skin
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	local screen = prompt:GetAttribute("MayhemScreen")
	local world = workspace:FindFirstChild("MayhemWorld")
	if type(screen) == "string" and world and prompt:IsDescendantOf(world) then hud:openPage(screen) end
end)
feedRemote.OnClientEvent:Connect(function(data: any) hud:addFeed(data) end)
effectRemote.OnClientEvent:Connect(function(kind: string, data: any)
	if kind == "Hit" then
		hud:hit(data.lethal)
		if data.lethal then audio:play("Eliminate") end
		if state.combat.slot == 2 and workspace.CurrentCamera then effects:play("MeleeHit", { at = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 5 }) end
	else
		effects:play(kind, data)
		if kind == "Shot" then audio:play("Shot") elseif kind == "Slash" then audio:play("Slash") elseif kind == "Pulse" then audio:play("Repulse") end
		if kind == "Slash" and data.userId == Players.LocalPlayer.UserId then camera.swingUntil = os.clock() + 0.2 end
	end
end)

RunService:BindToRenderStep("MayhemCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	camera:setActive(canAct())
	camera:step(dt, state.combat.slot)
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
		hud:render(state, now - receivedAt, preferences, style)
		worldPresentation:step()
		audio:update(hud:blocked(), state)
	end
end)
hud:render(state, 0, preferences, style)
action:FireServer(Protocol.Action.Ready)
presentationRemote:FireServer("Request")
