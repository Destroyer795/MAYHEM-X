--!strict
local Rules = {}

function Rules.finite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Rules.damage(health: number, shield: number, amount: number): (number, number)
	local absorbed = math.min(shield, amount)
	return math.max(0, health - (amount - absorbed)), shield - absorbed
end

function Rules.reload(ammo: number, reserve: number, capacity: number): (number, number)
	local count = math.min(capacity - ammo, reserve)
	return ammo + count, reserve - count
end

function Rules.spend(tokens: number, previous: number, now: number, rate: number, capacity: number, cost: number): (boolean, number)
	local available = math.min(capacity, tokens + math.max(0, now - previous) * rate)
	if available < cost then
		return false, available
	end
	return true, available - cost
end

function Rules.outcome(alive: { number }, expired: boolean): (boolean, number?, string)
	if #alive == 1 then
		return true, alive[1], "Last survivor"
	elseif #alive == 0 then
		return true, nil, "No survivors"
	elseif expired then
		return true, nil, "Time limit: draw"
	end
	return false, nil, ""
end

local transitions: { [string]: { [string]: boolean } } = {
	Waiting = { Intermission = true },
	Intermission = { Waiting = true, Loading = true },
	Loading = { Countdown = true, Results = true },
	Countdown = { Active = true, Results = true },
	Active = { Results = true },
	Results = { Waiting = true },
}

function Rules.canTransition(current: string, nextPhase: string): boolean
	return transitions[current] ~= nil and transitions[current][nextPhase] == true
end

return table.freeze(Rules)
