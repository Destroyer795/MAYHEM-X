--!strict
local RunService = game:GetService("RunService")
local StudioTestService = game:GetService("StudioTestService")
if not RunService:IsStudio() or StudioTestService:GetTestArgs() ~= "MayhemEconomyRegression" then return end
assert(game.PlaceId == 0, "This regression requires a disposable unpublished session")
local Players = game:GetService("Players")
local report = { clients = {}, serverAssertions = 0, spawnChecks = 0, completed = false }
local channel = Instance.new("RemoteEvent")
channel.Name = "MayhemEconomyQA"
channel.Parent = game:GetService("ReplicatedStorage")
local ended = false
local function finish(errorMessage: string?)
	if ended then return end
	ended = true
	report.completed = errorMessage == nil
	(report :: any).error = errorMessage
	StudioTestService:EndTest(report)
end
channel.OnServerEvent:Connect(function(player: Player, kind: string, payload: any)
	if kind == "Failure" then finish(player.Name .. ": " .. tostring(payload)); return end
	if kind == "RoundOne" then
		report.clients[tostring(player.UserId)] = payload
		assert(player.leaderstats.Kills.Value == payload.kills, "Server/client kills mismatch")
		assert(player.leaderstats.Wins.Value == payload.wins, "Server/client wins mismatch")
	elseif kind == "Complete" then
		(report :: any).final = payload
		assert(player:GetAttribute("MayhemSkin") == "Aurum", "Equipped finish did not replicate to the server")
		assert(player.leaderstats.Kills.Value == 1 and player.leaderstats.Wins.Value == 2, "Disconnect credited the wrong statistics")
		local count = 0
		for _ in report.clients do count += 1 end
		if count ~= 2 then finish("Missing first-round client report") else finish(nil) end
	end
end)
task.delay(210, function() finish("Multiplayer regression exceeded 210 seconds") end)
task.spawn(function()
	local ok, message = xpcall(function()
		local deadline = os.clock() + 30
		while #Players:GetPlayers() < 2 and os.clock() < deadline do task.wait(0.1) end
		assert(#Players:GetPlayers() == 2, "Two clients did not join")
		workspace:WaitForChild("MayhemWorld", 15)
		task.wait(2)
		local tests = require(game.ServerScriptService.MayhemTests)
		report.serverAssertions = tests.run()
		report.spawnChecks = tests.maps()
	end, debug.traceback)
	if not ok then finish(tostring(message)) end
end)
