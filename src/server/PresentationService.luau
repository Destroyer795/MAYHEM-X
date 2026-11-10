--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage.Mayhem.Shared
local Visuals = require(shared.Visuals)
local StyleRules = require(shared.StyleRules)
local Rules = require(shared.Rules)
local Presentation = {}

function Presentation.start()
	local remote = ReplicatedStorage.Mayhem:WaitForChild("Presentation") :: RemoteEvent
	local records: { [Player]: any } = {}
	local connections: { [Player]: RBXScriptConnection } = {}
	local function apply(player: Player)
		local record = records[player]
		local character = player.Character
		if not record or not character then return end
		local skin = Visuals.skin(record.skin)
		local accent = Color3.fromRGB(table.unpack(skin.color))
		player:SetAttribute("MayhemSkin", record.skin)
		player:SetAttribute("MayhemOperative", record.operative)
		character:SetAttribute("MayhemAccent", accent)
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if not torso or not torso:IsA("BasePart") then return end
		local old = character:FindFirstChild("MayhemStyle")
		if old then old:Destroy() end
		local model = Instance.new("Model")
		model.Name = "MayhemStyle"
		model.Parent = character
		local width = Visuals.operative(record.operative).shoulders
		for _, side in { -1, 0, 1 } do
			local item = Instance.new("Part")
			item.Name = "SignalPlate"
			item.Size = Vector3.new(if side == 0 then 0.22 else 0.28 * width, if side == 0 then 0.9 else 0.35, 0.08)
			item.CFrame = torso.CFrame * CFrame.new(side * torso.Size.X * 0.32, if side == 0 then 0 else 0.25, -torso.Size.Z / 2 - 0.06)
			item.Material = Enum.Material.Neon
			item.Color = accent
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.Massless = true
			item.CastShadow = false
			item.Parent = model
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = item
			weld.Parent = item
		end
		local weapon = character:FindFirstChild("MayhemWeapon")
		if weapon then for _, item in weapon:GetChildren() do if item:IsA("BasePart") and item.Material == Enum.Material.Neon then item.Color = accent end end end
	end
	local function send(player: Player, notice: string?)
		local record = records[player]
		if not record or player.Parent ~= Players then return end
		local day = math.floor(os.time() / 86400)
		remote:FireClient(player, {
			skin = record.skin, operative = record.operative, owned = table.clone(record.owned), revision = record.revision,
			dailyClaimed = record.dailyDay == day, nextDaily = (day + 1) * 86400, notice = notice,
		})
	end
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
		local accepted, notice = StyleRules.apply(record, Visuals, command, payload, math.floor(os.time() / 86400))
		if accepted then apply(player) end
		send(player, notice)
	end)
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(function(player: Player)
		if connections[player] then connections[player]:Disconnect(); connections[player] = nil end
		records[player] = nil
	end)
	for _, player in Players:GetPlayers() do add(player) end
end

return Presentation
