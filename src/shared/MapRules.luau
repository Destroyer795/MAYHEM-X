--!strict
local MapRules = {}
MapRules.Command = table.freeze({ Vote = "Vote", Ultimate = "Ultimate" })
MapRules.SafeStart = 185
MapRules.SafeMinimum = 24
MapRules.SafeDelay = 45
MapRules.ChaosInterval = 38
MapRules.ChaosDuration = 9
MapRules.LowGravity = 110
MapRules.DuelDelay = 12
MapRules.SparseDuelDelay = 60
MapRules.DuelRadius = 31
MapRules.DuelMinimum = 8

function MapRules.resolve(catalog: any, votes: { [number]: string }, eligible: { number }, previous: string?, roll: number): string
	local counts: { [string]: number } = {}
	for _, map in catalog do counts[map.id] = 0 end
	for _, id in eligible do local choice = votes[id]; if choice and counts[choice] then counts[choice] += 1 end end
	local highest = 0
	for _, count in counts do highest = math.max(highest, count) end
	local choices = {}
	for _, map in catalog do
		if counts[map.id] == highest and (highest > 0 or #catalog == 1 or map.id ~= previous) then table.insert(choices, map.id) end
	end
	return choices[math.clamp(1 + math.floor(roll * #choices), 1, #choices)]
end

function MapRules.duelRadius(elapsed: number): number
	return MapRules.DuelRadius + (MapRules.DuelMinimum - MapRules.DuelRadius) * math.clamp((elapsed - 10) / 45, 0, 1)
end

function MapRules.radius(elapsed: number, duration: number): number
	local progress = math.clamp((elapsed - MapRules.SafeDelay) / math.max(1, duration - MapRules.SafeDelay - 10), 0, 1)
	return MapRules.SafeStart + (MapRules.SafeMinimum - MapRules.SafeStart) * progress
end

function MapRules.inside(point: Vector3, center: Vector3, half: Vector3): boolean
	local delta = point - center
	return math.abs(delta.X) <= half.X and math.abs(delta.Y) <= half.Y and math.abs(delta.Z) <= half.Z
end

return table.freeze(MapRules)
