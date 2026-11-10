--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Mayhem.Shared.Config)
local Protocol = require(ReplicatedStorage.Mayhem.Shared.Protocol)
local Arena = require(script.Parent.ArenaService)
local Scene = require(script.Parent.SceneService)
local MatchService = require(script.Parent.MatchService)

Players.CharacterAutoLoads = false
Arena.build()
Scene.decorate()
local remotes = ReplicatedStorage.Mayhem.Remotes
local matches = MatchService.new(remotes)
local actionRemote = remotes:WaitForChild(Protocol.Remote.Action) :: RemoteEvent
actionRemote.OnServerEvent:Connect(function(player: Player, action: any, payload: any)
	matches:handle(player, action, payload)
end)
Players.PlayerAdded:Connect(function(player: Player) matches:add(player) end)
Players.PlayerRemoving:Connect(function(player: Player) matches:remove(player) end)
for _, player in Players:GetPlayers() do matches:add(player) end

local accumulated = 0
RunService.Heartbeat:Connect(function(dt: number)
	accumulated += dt
	if accumulated >= Config.SimulationInterval then
		local elapsed = accumulated
		accumulated = 0
		matches:tick(math.min(elapsed, 1))
	end
end)
print("MAYHEM X Phase 1 loaded. Queue at least two players to start a round.")
