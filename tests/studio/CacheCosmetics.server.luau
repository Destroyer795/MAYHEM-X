--!strict
local service=game:GetService("StudioTestService")
if not game:GetService("RunService"):IsStudio() or service:GetTestArgs()~="MayhemCacheCosmetics" then return end
assert(game.PlaceId==0,"Use a disposable unpublished local session")
local channel=Instance.new("RemoteEvent")
channel.Name,channel.Parent="MayhemCacheQA",game.ReplicatedStorage
local report: any={clients={},persistenceVerified=false,creditFixture="9 server-seeded eliminations per client, not a match earning test"}
local seeded,respawned={},{}
local ended=false
local function finish(message: string?)
	if ended then return end
	ended=true
	report.completed,report.error=message==nil,message
	service:EndTest(report)
end
channel.OnServerEvent:Connect(function(player,kind,value)
	if kind=="Failure" then finish(tostring(value))
	elseif kind=="Seed" and not seeded[player] then
		seeded[player]=true
		player.leaderstats.Kills.Value=9
	elseif kind=="Respawn" and not respawned[player] then
		respawned[player]=true
		player:LoadCharacterAsync()
	elseif kind=="GunReady" then
		player:SetAttribute("QAGunReady",true)
	elseif kind=="Complete" then
		report.clients[tostring(player.UserId)]=value
		local count=0
		for _ in report.clients do count+=1 end
		if count==2 then finish(nil) end
	end
end)
task.delay(105,function() finish("Cache and cosmetic multiplayer timeout") end)
