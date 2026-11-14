--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local shared = ReplicatedStorage.Mayhem.Shared
local Config = require(shared.Config)
local Arsenal = require(shared.Arsenal)
local Rules = require(shared.Rules)
local Equipment = require(script.Parent.Equipment)

export type Record = {
	character: Model?, alive: boolean, shield: number, ammo: number, reserve: number, slot: number,
	shotAt: number, swingAt: number, switchAt: number, abilityAt: number, reloadAt: number,
	protectedUntil: number, damagedAt: number, lastAttacker: Player?,
	accepted: CFrame, moveAt: number, moveCredit: number,
	ultimate: number, playerHitAt: number?, primary: any, melee: any,
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
	local self = setmetatable({ context = context, records = {} :: { [Player]: Record }, random = Random.new() }, Combat)
	return self
end

function Combat.beginLife(self: any, player: Player, character: Model)
	local humanoid, root = body(character)
	assert(humanoid and root, "Character must be ready before beginning a life")
	local primary, melee = Arsenal.loadout(if self.context.loadout then self.context.loadout(player) else {})
	self.records[player] = {
		primary = primary, melee = melee,
		character = character, alive = true, shield = Config.Character.Shield,
		ammo = primary.magazine, reserve = primary.reserve, slot = 1,
		shotAt = -math.huge, swingAt = -math.huge, switchAt = -math.huge,
		abilityAt = 0, reloadAt = 0, protectedUntil = math.huge, damagedAt = 0, lastAttacker = nil,
		accepted = root.CFrame, moveAt = os.clock(), moveCredit = Config.Security.MoveBurst,
		ultimate = 0, playerHitAt = nil,
	}
	humanoid.MaxHealth = Config.Character.Health
	humanoid.Health = Config.Character.Health
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	root.Anchored = true
	Equipment.equip(character, 1, primary.id, primary.kit)
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
	if record and now - (record.playerHitAt or -math.huge) <= Config.Match.KillCreditWindow then
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
	local bounds = if self.context.bounds then self.context.bounds() else { center = Vector3.zero, half = Config.Arena.Bound, ceiling = Config.Arena.Ceiling }
	valid = valid and allowed and delta.Y <= rise and math.abs(position.X - bounds.center.X) <= bounds.half
		and math.abs(position.Z - bounds.center.Z) <= bounds.half and position.Y <= bounds.ceiling
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
	if attacker then record.lastAttacker = attacker; record.playerHitAt = now end
	if nextHealth <= 0 then
		self.context.eliminate(victim, attacker or self:credit(victim, now), cause)
	end
	humanoid.Health = nextHealth
	self.context.sendState(victim)
	if attacker and attacker.Parent == Players then
		self.context.effect:FireClient(attacker, "Hit", { lethal = nextHealth <= 0 })
	end
	return true
end

function Combat.fire(self: any, player: Player, direction: any, now: number)
	if not unitVector(direction) then return end
	local record, root = self:ready(player, now)
	if not record or not root then return end
	local weapon = record.primary
	if record.slot ~= 1 or record.reloadAt > 0 or now - record.shotAt < weapon.interval
		or now - record.switchAt < 0.25 or record.ammo <= 0 then return end
	record.shotAt = now
	record.ammo -= 1
	local origin = root.Position + Vector3.new(0, 1.4, 0)
	local basis = CFrame.lookAt(Vector3.zero, direction.Unit)
	local traces = {}
	for _ = 1, weapon.pellets do
		local radius = math.tan(math.rad(weapon.spread)) * math.sqrt(self.random:NextNumber())
		local angle = self.random:NextNumber() * math.pi * 2
		local aim = (direction.Unit + basis.RightVector * math.cos(angle) * radius + basis.UpVector * math.sin(angle) * radius).Unit
		local hit = self:raycast(record.character :: Model, origin, aim * weapon.range)
		local endpoint = if hit then hit.Position else origin + aim * weapon.range
		if hit then
			if self.context.environmentHit then self.context.environmentHit(hit.Instance, weapon.damage) end
			for victim: Player, other: Record in self.records do
				if victim ~= player and other.alive and other.character and hit.Instance:IsDescendantOf(other.character) then
					self:damage(victim, player, weapon.damage, weapon.name, now)
					break
				end
			end
		end
		table.insert(traces, {to = endpoint, impact = hit ~= nil})
	end
	self.context.effect:FireAllClients("Shot", {from = origin, to = traces[1].to, impact = traces[1].impact, traces = traces, weapon = weapon.id, userId = player.UserId})
	self.context.sendState(player)
end

function Combat.melee(self: any, player: Player, direction: any, now: number)
	if not unitVector(direction) then
		return
	end
	local record, root = self:ready(player, now)
	if not record or not root or record.slot ~= 2 or now - record.swingAt < record.melee.interval or now - record.switchAt < 0.25 then
		return
	end
	record.swingAt = now
	local nearest: Player? = nil
	local distance = record.melee.range
	for target: Player, other: Record in self.records do
		if target ~= player and other.alive and other.character then
			local humanoid, targetRoot = body(other.character)
			if humanoid and targetRoot and humanoid.Health > 0 then
				local offset = targetRoot.Position - root.Position
				local magnitude = offset.Magnitude
				if magnitude <= distance and (magnitude < 0.1 or direction.Unit:Dot(offset.Unit) >= record.melee.dot)
					and self:lineOfSight(record.character :: Model, other.character, root.Position + Vector3.new(0, 1, 0), targetRoot.Position) then
					distance = magnitude
					nearest = target
				end
			end
		end
	end
	if nearest then
		self:damage(nearest, player, record.melee.damage, record.melee.name, now)
	elseif self.context.environmentHit then
		local hit = self:raycast(record.character :: Model, root.Position + Vector3.new(0, 1, 0), direction.Unit * record.melee.range)
		if hit then self.context.environmentHit(hit.Instance, record.melee.damage) end
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
	local weapon = if slot == 1 then record.primary else record.melee
	Equipment.equip(record.character :: Model, slot, weapon.id, weapon.kit)
	self.context.sendState(player)
end

function Combat.reload(self: any, player: Player, now: number)
	local record = self:ready(player, now)
	if not record or record.slot ~= 1 or record.reloadAt > 0 or record.ammo >= record.primary.magazine or record.reserve <= 0 then
		return
	end
	record.reloadAt = now + record.primary.reload
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
					record.ammo, record.reserve = Rules.reload(record.ammo, record.reserve, record.primary.magazine)
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

function Combat.transport(self: any, player: Player, frame: CFrame, grace: boolean)
	local record: Record? = self.records[player]
	if not record or not record.alive then return end
	local _, root = body(record.character)
	if not root then return end
	local delta = frame.Position - root.Position
	root.CFrame = frame
	if grace then
		root.AssemblyLinearVelocity = Vector3.zero
		record.accepted, record.moveAt, record.moveCredit = frame, os.clock(), Config.Security.MoveBurst
		record.protectedUntil, record.reloadAt = os.clock() + 2, 0
	else record.accepted += delta end
end

function Combat.addCharge(self: any, player: Player)
	local record: Record? = self.records[player]
	if record and record.alive then record.ultimate = math.min(100, record.ultimate + 34) end
end

function Combat.ultimate(self: any, player: Player, now: number)
	local record, root = self:ready(player, now)
	if not record or not root or record.ultimate < 100 then return end
	local humanoid = body(record.character)
	if not humanoid then return end
	record.ultimate = 0
	record.shield = Config.Character.Shield
	humanoid.Health = math.min(Config.Character.Health, humanoid.Health + 30)
	record.protectedUntil = now + 1.25
	self.context.effect:FireAllClients("Ultimate", { at = root.Position, userId = player.UserId })
	self.context.sendState(player)
end

function Combat.snapshot(self: any, player: Player, now: number): any
	local record: Record? = self.records[player]
	if not record then
		return { health = 100, shield = 0, ammo = 0, reserve = 0, slot = 1, abilityRemaining = 0, reloadRemaining = 0, protectionRemaining = 0, ultimate = 0 }
	end
	local humanoid = body(record.character)
	return {
		health = if humanoid then math.ceil(humanoid.Health) else 0, shield = math.ceil(record.shield),
		ammo = record.ammo, reserve = record.reserve, slot = record.slot,
		abilityRemaining = math.max(0, record.abilityAt - now), reloadRemaining = math.max(0, record.reloadAt - now),
		protectionRemaining = if record.protectedUntil == math.huge then 0 else math.max(0, record.protectedUntil - now),
		ultimate = record.ultimate,
		primaryId = record.primary.id, meleeId = record.melee.id, gunKit = record.primary.kit, meleeKit = record.melee.kit,
		fireInterval = record.primary.interval, meleeInterval = record.melee.interval, reloadTime = record.primary.reload,
		primaryName = record.primary.name, meleeName = record.melee.name, recoil = record.primary.recoil,
	}
end

return Combat
