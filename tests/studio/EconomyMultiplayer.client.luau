--!strict
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StudioTestService = game:GetService("StudioTestService")
local channel = ReplicatedStorage:WaitForChild("MayhemEconomyQA", 15) :: RemoteEvent?
if not channel then return end
local player = Players.LocalPlayer
local mayhem = ReplicatedStorage:WaitForChild("Mayhem")
local action = mayhem.Remotes.Action
local presentation = mayhem.Presentation
local state: any, style: any = nil, nil
local checks, maximumMusic = 0, 0
local played = {}
local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end
local function waitFor(predicate: () -> boolean, timeout: number, message: string)
	local deadline = os.clock() + timeout
	while not predicate() and os.clock() < deadline do task.wait(0.05) end
	check(predicate(), message)
end
local stateConnection = mayhem.Remotes.State.OnClientEvent:Connect(function(value) state = value end)
local profileConnection = presentation.OnClientEvent:Connect(function(value) style = value end)
local monitor = RunService.Heartbeat:Connect(function()
	local audio = SoundService:FindFirstChild("MayhemAudio")
	if not audio then return end
	local voices = 0
	for _, sound in audio:GetChildren() do
		if sound:IsA("Sound") and sound.SoundGroup and sound.SoundGroup.Name == "Music" and sound.IsPlaying then
			voices += 1
			if sound.IsLoaded and sound.TimePosition > 0 then played[sound.Name] = true end
		end
	end
	maximumMusic = math.max(maximumMusic, voices)
end)
local ok, message = xpcall(function()
	action:FireServer("Ready")
	presentation:FireServer("Request")
	waitFor(function() return state ~= nil and style ~= nil and style.profile.ready and #Players:GetPlayers() == 2 end, 30, "Profiles and two clients ready")
	check(style.profile.credits == 0 and style.profile.shards == 0 and style.profile.seasonTokens == 0, "Requires fresh disposable profiles")
	local contenders = Players:GetPlayers()
	table.sort(contenders, function(a, b) return a.UserId < b.UserId end)
	local winner = contenders[1]
	local attacker = player == winner
	local clientChecks = require(mayhem.ClientChecks).run()
	local audioLoads = require(mayhem.ClientChecks).audio()
	local Calendar=require(mayhem.Shared.DailyCalendar)
	local today=Calendar.Rewards[style.profile.calendar.day]
	local dailyCredits,dailyShards,dailyTokens=today.credits,today.shards or 0,today.seasonTokens or 0
	presentation:FireServer("Daily")
	waitFor(function() return style.profile.credits==dailyCredits and style.dailyClaimed end,5,"UTC daily reward")
	task.wait(0.3)
	presentation:FireServer("Daily")
	task.wait(0.4)
	check(style.profile.credits == dailyCredits, "Duplicate daily claim changed balance")
	presentation:FireServer("Purchase", { id = "Aurum", cost = 0 })
	task.wait(0.3)
	presentation:FireServer("Select", { kind = "skin", id = "Solstice" })
	task.wait(0.4)
	check(style.profile.credits == dailyCredits and not style.owned.Aurum and style.skin ~= "Solstice", "Forged purchase or unowned equip accepted")
	action:FireServer("Queue", true)
	waitFor(function() return state.queued end, 5, "Queue did not acknowledge")
	action:FireServer("Vote", "Jungle")
	waitFor(function() return state.vote == "Jungle" end, 5, "Map vote did not acknowledge")
	waitFor(function() return state.phase == "Active" and state.alive end, 40, "Round did not start")
	check(state.map.id == "Jungle", "Jungle ballot was not assigned")
	local firstRound = state.roundId
	local firstGeneration = state.map.generation
	waitFor(function() return state.combat.protectionRemaining <= 0 end, 5, "Spawn protection never ended")
	local ammo = state.combat.ammo
	action:FireServer("Fire", Vector3.new(0 / 0, 0, 0))
	task.wait(0.6)
	check(state.combat.ammo == ammo, "Nonfinite aim consumed ammo")
	for _ = 1, 12 do action:FireServer("Fire", Vector3.yAxis) end
	task.wait(0.7)
	check(state.combat.ammo == ammo - 1, "Fire-rate burst accepted more than one shot")
	action:FireServer("Reload")
	waitFor(function() return state.combat.reloadRemaining > 0 end, 3, "Reload did not begin")
	waitFor(function() return state.combat.reloadRemaining == 0 and state.combat.ammo == ammo end, 4, "Reload did not finish")
	waitFor(function() return state.map.duel end, 70, "Final duel did not start")
	waitFor(function() return state.combat.protectionRemaining <= 0 end, 5, "Duel protection never ended")
	if attacker then
		local victim = contenders[2]
		local deadline = os.clock() + 7
		while state.phase == "Active" and os.clock() < deadline do
			local origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local target = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if origin and target then action:FireServer("Fire", (target.Position - origin.Position).Unit) end
			task.wait(0.23)
		end
	end
	waitFor(function() return state.phase == "Results" end, 12, "Combat did not finish the round")
	check(state.result.winnerId == winner.UserId, "Wrong combat winner")
	waitFor(function() return style.profile.credits == (dailyCredits+(if attacker then 80 else 20)) end, 4, "Incorrect match Credits")
	check(style.profile.seasonTokens == (dailyTokens+(if attacker then 2 else 1)), "Incorrect match Tokens")
	check(style.profile.shards == (dailyShards+(if attacker then 1 else 0)), "Incorrect first-win Shard")
	check(style.profile.kills == (if attacker then 1 else 0) and style.profile.wins == (if attacker then 1 else 0), "Combat statistics mismatch")
	check(style.profile.xp == (if attacker then 420 else 0), "XP mismatch")
	local payout = nil
	for _, row in state.result.standings do if row.userId == player.UserId then payout = row.reward end end
	check(payout and payout.credits == (if attacker then 65 else 20), "Result bonus differs from server payout")
	presentation:FireServer("Purchase", if attacker then "Aurum" else "VoidReaver")
	task.wait(0.6)
	check(style.profile.credits == (dailyCredits+(if attacker then 35 else 20)) and (style.owned.Aurum == true) == attacker, "Purchase/funds validation failed")
	if attacker then
		presentation:FireServer("Purchase", "Aurum")
		task.wait(0.4)
		check(style.profile.credits == dailyCredits+35, "Duplicate purchase debited twice")
		presentation:FireServer("Purchase", "Voidglass")
		waitFor(function() return style.owned.Voidglass == true and style.profile.shards == dailyShards end, 3, "Shard purchase failed")
		presentation:FireServer("Select", { kind = "skin", id = "Aurum" })
		waitFor(function() return style.skin == "Aurum" end, 3, "Equip request failed")
		local debits = 0
		for _, row in style.profile.recentTransactions do if row.id == "purchase:Aurum" then debits += 1; check(row.credits == -45, "Ledger debit mismatch") end end
		check(debits == 1, "Duplicate/missing purchase ledger entry")
	end
	channel:FireServer("RoundOne", { checks = checks, clientChecks = clientChecks, audioLoads = audioLoads, kills = style.profile.kills, wins = style.profile.wins, credits = style.profile.credits, shards = style.profile.shards, tokens = style.profile.seasonTokens, maxMusic = maximumMusic, played = table.clone(played) })
	waitFor(function() return not state.inMatch and (state.phase == "Waiting" or state.phase == "Intermission") end, 12, "Round did not reset")
	check(not state.map.duel and state.map.center == Vector3.zero and state.map.safeRadius == 185, "Duel state leaked into the lobby")
	action:FireServer("Vote", "Jungle")
	waitFor(function() return state.vote == "Jungle" end, 4, "Second vote did not acknowledge")
	waitFor(function() return state.phase == "Active" and state.roundId == firstRound + 1 end, 35, "Second round did not start")
	check(state.map.id == "Jungle", "Same-map ballot failed")
	check(not state.map.duel and state.map.center == Vector3.zero and state.map.generation == firstGeneration + 1, "Same-map round did not receive fresh state")
	local generation = state.map.generation
	task.wait(2)
	check(state.map.generation == generation, "Map reloaded during active round")
	if not attacker then
		check(StudioTestService:CanLeaveTest(), "Client cannot leave test")
		StudioTestService:LeaveTest()
		return
	end
	waitFor(function() return state.phase == "Results" end, 10, "Disconnect did not resolve the round")
	waitFor(function() return style.profile.credits == dailyCredits+100 and style.profile.wins == 2 end, 4, "Disconnect result reward mismatch")
	check(style.profile.kills == 1 and style.profile.shards == dailyShards and style.profile.seasonTokens == dailyTokens+4, "Disconnect duplicated kill/Shard rewards")
	check(maximumMusic <= 2, "Music stacking exceeded two crossfade voices")
	check(played.Lobby and played.Jungle and played.Showdown and played.Victory, "Expected music contexts did not advance playback")
	channel:FireServer("Complete", { checks = checks, credits = style.profile.credits, shards = style.profile.shards, tokens = style.profile.seasonTokens, maxMusic = maximumMusic, played = played, combatEarnedVictory = true, persistenceVerified = false })
end, debug.traceback)
monitor:Disconnect()
stateConnection:Disconnect()
profileConnection:Disconnect()
if not ok then channel:FireServer("Failure", tostring(message)) end
