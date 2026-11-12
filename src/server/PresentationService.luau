--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage.Mayhem.Shared
local Visuals = require(shared.Visuals)
local StyleRules = require(shared.StyleRules)
local Rules = require(shared.Rules)
local Art = require(shared.Art)
local Presentation = {}

function Presentation.start(profiles: any)
	local remote = ReplicatedStorage.Mayhem:WaitForChild("Presentation") :: RemoteEvent
	local records: { [Player]: any } = {}
	local connections: { [Player]: RBXScriptConnection } = {}
	local appearanceConnections: { [Player]: RBXScriptConnection } = {}
	local function apply(player: Player)
		local record = records[player]
		local character = player.Character
		if not record or not character then return end
		local skin = Visuals.skin(record.skin)
		local accent = Color3.fromRGB(table.unpack(skin.color))
		player:SetAttribute("MayhemSkin", record.skin)
		player:SetAttribute("MayhemOperative", record.operative)
		character:SetAttribute("MayhemAccent", accent)
		Art.outfit(character, accent, Visuals.operative(record.operative).shoulders)
		local weapon = character:FindFirstChild("MayhemWeapon")
		if weapon then for _, item in weapon:GetDescendants() do if item:IsA("BasePart") and item.Material == Enum.Material.Neon then item.Color = accent end end end
	end
	local function send(player: Player, notice: string?)
		local record = records[player]
		if not record or player.Parent ~= Players then return end
		local day = math.floor(os.time() / 86400)
		remote:FireClient(player, {
			skin = record.skin, operative = record.operative, owned = table.clone(record.owned), revision = record.revision,
			dailyClaimed = record.dailyDay == day, nextDaily = (day + 1) * 86400, notice = notice,
			profile = profiles:snapshot(player),
		})
	end
	profiles.notify = function(player: Player) send(player, nil) end
	local function add(player: Player)
		if records[player] then return end
		local record = StyleRules.new()
		record.tokens = 6
		record.requestAt = os.clock()
		records[player] = record
		connections[player] = player.CharacterAdded:Connect(function(character: Model)
			task.spawn(function()
				local torso = character:WaitForChild("HumanoidRootPart", 8)
				if torso and records[player] == record and player.Character == character then apply(player) end
			end)
		end)
		appearanceConnections[player] = player.CharacterAppearanceLoaded:Connect(function(character: Model)
			if records[player] == record and player.Character == character then apply(player) end
		end)
		if player.Character then apply(player) end
	end
	remote.OnServerEvent:Connect(function(player: Player, command: any, payload: any)
		local record = records[player]
		if not record then return end
		local now = os.clock()
		local allowed, tokens = Rules.spend(record.tokens, record.requestAt, now, 4, 6, 1)
		record.tokens, record.requestAt = tokens, now
		if not allowed or type(command) ~= "string" or #command > 12 then return end
		if command == "Request" then send(player, nil); return end
		if command == "Preferences" then
			local accepted = profiles:update(player, payload)
			send(player, if accepted then "Preferences accepted." else "Preferences rejected. Try again after loading.")
			return
		end
		if command == "Purchase" then
			local item = if type(payload) == "string" then Visuals.skin(payload) else nil
			if not item or item.source ~= "purchase" then send(player, "Unknown purchase."); return end
			if record.owned[item.id] then send(player, "Already in your collection."); return end
			if not profiles:spend(player, item.cost) then send(player, "Not enough session credits."); return end
			record.owned[item.id] = true
			record.revision += 1
			send(player, "Aurum added. No combat stats changed.")
			return
		end
		local previousRevision = record.revision
		local accepted, notice = StyleRules.apply(record, Visuals, command, payload, math.floor(os.time() / 86400))
		if accepted and record.revision ~= previousRevision then apply(player) end
		if accepted and command == "Daily" and record.revision ~= previousRevision then profiles:bonus(player, 15) end
		send(player, notice)
	end)
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player: Player)
		if connections[player] then connections[player]:Disconnect(); connections[player] = nil end
		if appearanceConnections[player] then appearanceConnections[player]:Disconnect(); appearanceConnections[player] = nil end
		records[player] = nil
	end)
	for _, player in Players:GetPlayers() do add(player) end
end

return Presentation
