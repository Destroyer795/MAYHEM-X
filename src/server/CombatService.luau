--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local shared = ReplicatedStorage.Mayhem.Shared
local Config = require(shared.Config)
local Rules = require(shared.Rules)
local Equipment = require(script.Parent.Equipment)

export type Record = {
	character: Model?, alive: boolean, shield: number, ammo: number, reserve: number, slot: number,
	shotAt: number, swingAt: number, switchAt: number, abilityAt: number, reloadAt: number,
	protectedUntil: number, damagedAt: number, lastAttacker: Player?,
	accepted: CFrame, moveAt: number, moveCredit: number,
}

local Combat = {}
Combat.__index = Combat

local function body(character: Model?): (Humanoid?, BasePart?)
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return humanoid, nil
	end
	return humanoid, root
end

local function unitVector(value: any): boolean
	return typeof(value) == "Vector3" and Rules.finite(value.X) and Rules.finite(value.Y)
		and Rules.finite(value.Z) and value.Magnitude > 0.9 and value.Magnitude < 1.1
end

function Combat.new(context: any)
	local self = setmetatable({ context = context, records = {} :: { [Player]: Record } }, Combat)
	return self
end

function Combat.beginLife(self: any, player: Player, character: Model)
	local humanoid, root = body(character)
	assert(humanoid and root, "Character must be ready before beginning a life")
	self.records[player] = {
		character = character, alive = true, shield = Config.Character.Shield,
		ammo = Config.Rifle.Magazine, reserve = Config.Rifle.Reserve, slot = 1,
		shotAt = -math.huge, swingAt = -math.huge, switchAt = -math.huge,
		abilityAt = 0, reloadAt = 0, protectedUntil = math.huge, damagedAt = 0, lastAttacker = nil,
		accepted = root.CFrame, moveAt = os.clock(), moveCredit = Config.Security.MoveBurst,
	}
	humanoid.MaxHealth = Config.Character.Health
	humanoid.Health = Config.Character.Health
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	root.Anchored = true
	Equipment.equip(character, 1)
end

function Combat.release(self: any, player: Player, now: number)
	local record: Record? = self.records[player]
	if not record or not record.alive then
		return
	end
	local humanoid, root = body(record.character)
	if humanoid and root then
		record.accepted = root.CFrame
		record.moveAt = now
		record.moveCredit = Config.Security.MoveBurst
		record.protectedUntil = now + Config.Match.SpawnProtection
		humanoid.WalkSpeed = Config.Character.WalkSpeed
		humanoid.JumpPower = Config.Character.JumpPower
		root.Anchored = false
	end
end

function Combat.endLife(self: any, player: Player)
	local record: Record? = self.records[player]
	if record then
		record.alive = false
		record.reloadAt = 0
		if record.character then
			Equipment.clear(record.character)
		end
	end
end

function Combat.credit(self: any, player: Player, now: number): Player?
	local record: Record? = self.records[player]
	if record and now - record.damagedAt <= Config.Match.KillCreditWindow then
		return record.lastAttacker
	end
	return nil
end

function Combat.validatePosition(self: any, player: Player, now: number): boolean
	local record: Record? = self.records[player]
	if not record or not record.alive or player.Character ~= record.character then
		return false
	end
	local humanoid, root = body(record.character)
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	local position = root.Position
	local valid = Rules.finite(position.X) and Rules.finite(position.Y) and Rules.finite(position.Z)
	if not valid then
		root.CFrame = record.accepted
		root.AssemblyLinearVelocity = Vector3.zero
		return false
	end
	local delta = position - record.accepted.Position
	local allowed, credit = Rules.spend(record.moveCredit, record.moveAt, now,
		Config.Security.MoveSpeedAllowance, Config.Security.MoveBurst, Vector3.new(delta.X, 0, delta.Z).Magnitude)
	local rise = math.max(6, (now - record.moveAt) * 75)
	valid = valid and allowed and delta.Y <= rise and math.abs(position.X) <= Config.Arena.Bound
		and math.abs(position.Z) <= Config.Arena.Bound and position.Y <= Config.Arena.Ceiling
	if not valid then
		root.CFrame = record.accepted
		root.AssemblyLinearVelocity = Vector3.zero
		record.moveAt = now
		record.moveCredit = math.min(record.moveCredit, credit)
		return false
	end
	record.accepted = root.CFrame
	record.moveAt = now
	record.moveCredit = credit
	return true
end

function Combat.ready(self: any, player: Player, now: number): (Record?, BasePart?)
	if not self.context.canFight() or not self:validatePosition(player, now) then
		return nil, nil
	end
	local record: Record = self.records[player]
	local _, root = body(record.character)
	if now < record.protectedUntil then
		return nil, nil
	end
	return record, root
end

function Combat.raycast(self: any, character: Model, origin: Vector3, direction: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	return Workspace:Raycast(origin, direction, params)
end

function Combat.lineOfSight(self: any, attacker: Model, victim: Model, origin: Vector3, target: Vector3): boolean
	local hit = self:raycast(attacker, origin, target - origin)
	return hit == nil or hit.Instance:IsDescendantOf(victim)
end

function Combat.damage(self: any, victim: Player, attacker: Player?, amount: number, cause: string, now: number): boolean
	local record: Record? = self.records[victim]
	if not record or not record.alive or now < record.protectedUntil or not self.context.canFight() then
		return false
	end
	local humanoid = body(record.character)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local nextHealth, nextShield = Rules.damage(humanoid.Health, record.shield, amount)
	record.shield = nextShield
	record.damagedAt = now
	record.lastAttacker = attacker
	if nextHealth <= 0 then
		self.context.eliminate(victim, attacker, cause)
	end
	humanoid.Health = nextHealth
	self.context.sendState(victim)
	if attacker and attacker.Parent == Players then
		self.context.effect:FireClient(attacker, "Hit", { lethal = nextHealth <= 0 })
	end
	return true
end

function Combat.fire(self: any, player: Player, direction: any, now: number)
	if not unitVector(direction) then
		return
	end
	local record, root = self:ready(player, now)
	if not record or not root or record.slot ~= 1 or record.reloadAt > 0
		or now - record.shotAt < Config.Rifle.Interval or now - record.switchAt < 0.25 or record.ammo <= 0 then
		return
	end
	record.shotAt = now
	record.ammo -= 1
	local origin = root.Position + Vector3.new(0, 1.4, 0)
	local hit = self:raycast(record.character :: Model, origin, direction.Unit * Config.Rifle.Range)
	local endpoint = if hit then hit.Position else origin + direction.Unit * Config.Rifle.Range
	if hit then
		for victim: Player, other: Record in self.records do
			if victim ~= player and other.alive and other.character and hit.Instance:IsDescendantOf(other.character) then
				self:damage(victim, player, Config.Rifle.Damage, Config.Rifle.Name, now)
				break
			end
		end
	end
	self.context.effect:FireAllClients("Shot", { from = origin, to = endpoint, userId = player.UserId })
	self.context.sendState(player)
end

function Combat.melee(self: any, player: Player, direction: any, now: number)
	if not unitVector(direction) then
		return
	end
	local record, root = self:ready(player, now)
	if not record or not root or record.slot ~= 2 or now - record.swingAt < Config.Blade.Interval or now - record.switchAt < 0.25 then
		return
	end
	record.swingAt = now
	local nearest: Player? = nil
	local distance = Config.Blade.Range
	for target: Player, other: Record in self.records do
		if target ~= player and other.alive and other.character then
			local humanoid, targetRoot = body(other.character)
			if humanoid and targetRoot and humanoid.Health > 0 then
				local offset = targetRoot.Position - root.Position
				local magnitude = offset.Magnitude
				if magnitude <= distance and (magnitude < 0.1 or direction.Unit:Dot(offset.Unit) >= Config.Blade.MinimumDot)
					and self:lineOfSight(record.character :: Model, other.character, root.Position + Vector3.new(0, 1, 0), targetRoot.Position) then
					distance = magnitude
					nearest = target
				end
			end
		end
	end
	if nearest then
		self:damage(nearest, player, Config.Blade.Damage, Config.Blade.Name, now)
	end
	self.context.effect:FireAllClients("Slash", { at = root.CFrame, userId = player.UserId })
end

function Combat.ability(self: any, player: Player, now: number)
	local record, root = self:ready(player, now)
	if not record or not root or now < record.abilityAt then
		return
	end
	record.abilityAt = now + Config.Ability.Cooldown
	record.shield = math.min(Config.Character.Shield, record.shield + Config.Ability.ShieldRestore)
	for victim: Player, other: Record in self.records do
		local _, targetRoot = body(other.character)
		if victim ~= player and other.alive and targetRoot and (targetRoot.Position - root.Position).Magnitude <= Config.Ability.Radius
			and self:lineOfSight(record.character :: Model, other.character :: Model, root.Position + Vector3.new(0, 1, 0), targetRoot.Position) then
			self:damage(victim, player, Config.Ability.Damage, Config.Ability.Name, now)
		end
	end
	self.context.effect:FireAllClients("Pulse", { at = root.Position })
	self.context.sendState(player)
end

function Combat.switch(self: any, player: Player, slot: any, now: number)
	if slot ~= 1 and slot ~= 2 then
		return
	end
	local record = self:ready(player, now)
	if not record or record.slot == slot or now - record.switchAt < 0.25 then
		return
	end
	record.slot = slot
	record.switchAt = now
	record.reloadAt = 0
	Equipment.equip(record.character :: Model, slot)
	self.context.sendState(player)
end

function Combat.reload(self: any, player: Player, now: number)
	local record = self:ready(player, now)
	if not record or record.slot ~= 1 or record.reloadAt > 0 or record.ammo >= Config.Rifle.Magazine or record.reserve <= 0 then
		return
	end
	record.reloadAt = now + Config.Rifle.ReloadTime
	self.context.sendState(player)
end

function Combat.tick(self: any, now: number, dt: number)
	for player: Player, record: Record in self.records do
		if record.alive then
			local humanoid, root = body(record.character)
			if not humanoid or not root or humanoid.Health <= 0 or player.Character ~= record.character then
				self.context.eliminate(player, self:credit(player, now), "Eliminated")
			elseif root.Position.Y < Config.Arena.FloorLimit then
				self.context.eliminate(player, self:credit(player, now), "The void")
				humanoid.Health = 0
			elseif self.context.canFight() then
				self:validatePosition(player, now)
				if record.reloadAt > 0 and now >= record.reloadAt then
					record.ammo, record.reserve = Rules.reload(record.ammo, record.reserve, Config.Rifle.Magazine)
					record.reloadAt = 0
					self.context.sendState(player)
				end
				if now - record.damagedAt >= Config.Character.ShieldDelay then
					record.shield = math.min(Config.Character.Shield, record.shield + Config.Character.ShieldPerSecond * dt)
				end
			end
		end
	end
end

function Combat.remove(self: any, player: Player)
	self.records[player] = nil
end

function Combat.snapshot(self: any, player: Player, now: number): any
	local record: Record? = self.records[player]
	if not record then
		return { health = 100, shield = 0, ammo = 0, reserve = 0, slot = 1, abilityRemaining = 0, reloadRemaining = 0, protectionRemaining = 0 }
	end
	local humanoid = body(record.character)
	return {
		health = if humanoid then math.ceil(humanoid.Health) else 0, shield = math.ceil(record.shield),
		ammo = record.ammo, reserve = record.reserve, slot = record.slot,
		abilityRemaining = math.max(0, record.abilityAt - now), reloadRemaining = math.max(0, record.reloadAt - now),
		protectionRemaining = if record.protectedUntil == math.huge then 0 else math.max(0, record.protectedUntil - now),
	}
end

return Combat
