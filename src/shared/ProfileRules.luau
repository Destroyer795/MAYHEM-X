--!strict
local ProfileRules = {}
ProfileRules.Version = 2
ProfileRules.MaximumStat = 1_000_000_000

function ProfileRules.default(preferences: any): any
	return {
		version = ProfileRules.Version,
		preferences = table.clone(preferences.Defaults),
		kills = 0,
		wins = 0,
		credits = 0,
		skin = "Pulse",
		operative = "Vanguard",
		owned = { Pulse = true, Glacier = true },
		dailyDay = -1,
	}
end

function ProfileRules.clean(input: any, preferences: any, visuals: any, legacyPreferences: any?): any
	local result = ProfileRules.default(preferences)
	if type(input) ~= "table" then
		result.preferences = preferences.merge(result.preferences, legacyPreferences)
		return result
	end
	local source = if type(input.version) == "number" and input.version >= 1 then input else { preferences = input }
	result.preferences = preferences.merge(result.preferences, source.preferences)
	for _, field in { "kills", "wins", "credits" } do
		local value = source[field]
		if type(value) == "number" and value == value and value >= 0 and value < math.huge then
			result[field] = math.clamp(math.floor(value), 0, ProfileRules.MaximumStat)
		end
	end
	if type(source.dailyDay) == "number" and source.dailyDay == source.dailyDay then
		result.dailyDay = math.clamp(math.floor(source.dailyDay), -1, 100_000_000)
	end
	if type(source.owned) == "table" then
		for _, skin in visuals.Skins do
			if source.owned[skin.id] == true then result.owned[skin.id] = true end
		end
	end
	local equippedSkin = if type(source.skin) == "string" then visuals.skin(source.skin) else nil
	if equippedSkin and result.owned[equippedSkin.id] then result.skin = equippedSkin.id end
	local operative = if type(source.operative) == "string" then visuals.operative(source.operative) else nil
	if operative then result.operative = operative.id end
	return result
end

function ProfileRules.cosmetics(input: any, current: any, visuals: any): any
	local result = { skin = current.skin, operative = current.operative, owned = table.clone(current.owned), dailyDay = current.dailyDay }
	if type(input) ~= "table" then return result end
	if type(input.skin) == "string" then
		local skin = visuals.skin(input.skin)
		if skin and result.owned[skin.id] then result.skin = skin.id end
	end
	if type(input.operative) == "string" and visuals.operative(input.operative) then result.operative = input.operative end
	if type(input.owned) == "table" then
		for _, skin in visuals.Skins do if input.owned[skin.id] == true then result.owned[skin.id] = true end end
	end
	if type(input.dailyDay) == "number" and input.dailyDay == input.dailyDay then result.dailyDay = math.clamp(math.floor(input.dailyDay), -1, 100_000_000) end
	if not result.owned[result.skin] then result.skin = "Pulse" end
	return result
end

function ProfileRules.purchase(profile: any, skinId: string, visuals: any): boolean
	local item = if type(skinId) == "string" then visuals.skin(skinId) else nil
	if not item or item.source ~= "purchase" or profile.owned[item.id] or profile.credits < item.cost then return false end
	profile.credits -= item.cost
	profile.owned[item.id] = true
	return true
end

function ProfileRules.claimDaily(profile: any, day: number): boolean
	if type(day) ~= "number" or day ~= day or day < 0 or profile.dailyDay == day then return false end
	profile.dailyDay = math.floor(day)
	profile.owned.Prism = true
	profile.credits = math.clamp(profile.credits + 15, 0, ProfileRules.MaximumStat)
	return true
end

return table.freeze(ProfileRules)
