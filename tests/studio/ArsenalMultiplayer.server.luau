--!strict
local service=game:GetService("StudioTestService")
if not game:GetService("RunService"):IsStudio() or service:GetTestArgs()~="MayhemArsenalAcceptance" then return end
assert(game.PlaceId==0,"Disposable local session required")
local channel=Instance.new("RemoteEvent")
channel.Name,channel.Parent="MayhemArsenalQA",game.ReplicatedStorage
local report={clients={},rules=0,combat=0}
local ended=false
local function finish(message: string?)
	if ended then return end
	ended=true
	(report :: any).completed=message==nil
	(report :: any).error=message
	service:EndTest(report)
end
channel.OnServerEvent:Connect(function(player,kind,value)
	if kind=="Failure" then finish(tostring(value)); return end
	if kind=="Complete" then
		report.clients[tostring(player.UserId)]=value
		local count=0
		for _ in report.clients do count+=1 end
		if count==2 then finish(nil) end
	end
end)
task.delay(100,function() finish("Arsenal multiplayer timeout") end)
task.spawn(function()
	local ok,message=xpcall(function()
		local shared=game.ReplicatedStorage.Mayhem.Shared
		report.rules=require(game.ServerScriptService.MayhemTests.ArsenalCases)(require(shared.Arsenal),require(shared.PreferenceRules))
		report.combat=require(game.ServerScriptService.MayhemTests.ArsenalCombatCases)(require(game.ServerScriptService.MayhemServer.CombatService),require(shared.Arsenal))
	end,debug.traceback)
	if not ok then finish(tostring(message)) end
end)
