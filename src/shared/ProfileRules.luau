--!strict
local Calendar = require(script.Parent.DailyCalendar)
local ProfileRules = {}
ProfileRules.Version = 4
ProfileRules.MaximumStat = 1_000_000_000
ProfileRules.LedgerLimit = 50
ProfileRules.MatchRewardLimit = 64

local CurrencyFields = table.freeze({ credits = true, shards = true, seasonTokens = true })

local function boundedInteger(value: any, minimum: number, maximum: number, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
	return math.clamp(math.floor(value), minimum, maximum)
end

local function ledgerContains(profile: any, id: string): boolean
	for _, transaction in profile.ledger do if transaction.id == id then return true end end
	return false
end

function ProfileRules.recordTransaction(profile: any, id: string, action: string, credits: number, shards: number, seasonTokens: number, timestamp: number?): boolean
	if type(id) ~= "string" or #id == 0 or #id > 120 or type(action) ~= "string" or #action > 32 or ledgerContains(profile, id) then return false end
	local entry = {
		id = id,
		action = action,
		credits = boundedInteger(credits, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
		shards = boundedInteger(shards, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
		seasonTokens = boundedInteger(seasonTokens, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
		at = boundedInteger(timestamp or os.time(), 0, 100_000_000_000, os.time()),
	}
	table.insert(profile.ledger, entry)
	while #profile.ledger > ProfileRules.LedgerLimit do table.remove(profile.ledger, 1) end
	return true
end

function ProfileRules.default(preferences: any): any
	return {
		version = ProfileRules.Version,
		preferences = table.clone(preferences.Defaults),
		kills = 0,
		wins = 0,
		credits = 0,
		shards = 0,
		seasonTokens = 0,
		firstWinShardClaimed = false,
		matchRewards = {},
		ledger = {},
		skin = "Pulse",
		operative = "Vanguard",
		owned = { Pulse = true, Glacier = true },
		dailyDay = -1,
		dailyWeek = -1,
		dailyMask = 0,
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
	for _, field in { "kills", "wins", "credits", "shards", "seasonTokens" } do
		result[field] = boundedInteger(source[field], 0, ProfileRules.MaximumStat, 0)
	end
	result.firstWinShardClaimed = source.firstWinShardClaimed == true or result.wins > 0
	if type(source.matchRewards) == "table" then
		for index = math.max(1, #source.matchRewards - ProfileRules.MatchRewardLimit + 1), #source.matchRewards do
			local id = source.matchRewards[index]
			if type(id) == "string" and #id > 0 and #id <= 120 and not table.find(result.matchRewards, id) then table.insert(result.matchRewards, id) end
		end
	end
	if type(source.ledger) == "table" then
		for index = math.max(1, #source.ledger - ProfileRules.LedgerLimit + 1), #source.ledger do
			local entry = source.ledger[index]
			if type(entry) == "table" and type(entry.id) == "string" and #entry.id > 0 and #entry.id <= 120 and type(entry.action) == "string" and #entry.action <= 32 then
				ProfileRules.recordTransaction(result, entry.id, entry.action,
					boundedInteger(entry.credits, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
					boundedInteger(entry.shards, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
					boundedInteger(entry.seasonTokens, -ProfileRules.MaximumStat, ProfileRules.MaximumStat, 0),
					boundedInteger(entry.at, 0, 100_000_000_000, os.time()))
			end
		end
	end
	result.dailyDay = boundedInteger(source.dailyDay, -1, 100_000_000, -1)
	Calendar.migrate(result,source)
	if type(source.owned) == "table" then
		for _, skin in visuals.Skins do if source.owned[skin.id] == true then result.owned[skin.id] = true end end
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
	if not item or profile.owned[item.id] or type(item.cost) ~= "number" or item.cost <= 0 or item.cost % 1 ~= 0 then return false end
	local currency = item.currency
	if not CurrencyFields[currency] or (item.source ~= "purchase" and item.source ~= "shards" and item.source ~= "season") then return false end
	if profile[currency] < item.cost then return false end
	local transactionId = "purchase:" .. item.id
	if ledgerContains(profile, transactionId) then return false end
	profile[currency] -= item.cost
	profile.owned[item.id] = true
	local delta = { credits = 0, shards = 0, seasonTokens = 0 }
	delta[currency] = -item.cost
	ProfileRules.recordTransaction(profile, transactionId, "cosmetic", delta.credits, delta.shards, delta.seasonTokens)
	return true
end

function ProfileRules.claimDaily(profile: any, day: number): (boolean,any)
	local accepted,reward=Calendar.grant(profile,day,ProfileRules.MaximumStat)
	if not accepted then return false,nil end
	ProfileRules.recordTransaction(profile,reward.id,"daily-cache",reward.credits,reward.shards,reward.seasonTokens,day*Calendar.DaySeconds)
	return true,reward
end

function ProfileRules.awardMatch(profile: any, matchId: string, won: boolean, economy: any): (boolean, any)
	if type(matchId) ~= "string" or #matchId == 0 or #matchId > 120 or type(won) ~= "boolean" or table.find(profile.matchRewards, matchId) then return false, nil end
	local credits = math.min(economy.MatchCredits + (if won then economy.WinCredits else 0), ProfileRules.MaximumStat - profile.credits)
	local seasonTokens = math.min(economy.SeasonTokensPerMatch + (if won then economy.SeasonTokenWinBonus else 0), ProfileRules.MaximumStat - profile.seasonTokens)
	local shards = math.min(if won and not profile.firstWinShardClaimed then economy.FirstWinShards else 0, ProfileRules.MaximumStat - profile.shards)
	profile.credits += credits
	profile.seasonTokens += seasonTokens
	profile.shards += shards
	if won then profile.firstWinShardClaimed = true end
	table.insert(profile.matchRewards, matchId)
	while #profile.matchRewards > ProfileRules.MatchRewardLimit do table.remove(profile.matchRewards, 1) end
	ProfileRules.recordTransaction(profile, "match:" .. matchId, if won then "match-win" else "match-played", credits, shards, seasonTokens)
	return true, { credits = credits, shards = shards, seasonTokens = seasonTokens }
end

return table.freeze(ProfileRules)
