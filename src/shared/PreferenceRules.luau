--!strict
local PreferenceRules = {}
local Arsenal = require(script.Parent.Arsenal)
PreferenceRules.Defaults = table.freeze({ firstPerson = false, fov = 80, graphics = "Auto", reducedEffects = false, reducedMotion = false, music = 0.35, sound = 0.7, ui = 0.55, muted = false, primaryWeapon = "Vector", meleeWeapon = "Rift", gunKit = "Standard", meleeKit = "Balanced" })

function PreferenceRules.merge(base: any, input: any): any
	local result = table.clone(base)
	if type(input) ~= "table" then return result end
	for key, default in PreferenceRules.Defaults do
		local value = input[key]
		if Arsenal.valid(key, value) then result[key] = value
		elseif type(default) == "boolean" and type(value) == "boolean" then result[key] = value
		elseif key == "graphics" and (value == "Auto" or value == "High" or value == "Low") then result[key] = value
		elseif type(default) == "number" and type(value) == "number" and value == value and math.abs(value) < math.huge then
			result[key] = if key == "fov" then math.clamp(math.floor(value), 70, 100) else math.clamp(value, 0, 1)
		end
	end
	return result
end

function PreferenceRules.wallet(kills: number, wins: number, bonus: number, spent: number): number
	return math.max(0, kills * 15 + wins * 45 + bonus - spent)
end

return table.freeze(PreferenceRules)
