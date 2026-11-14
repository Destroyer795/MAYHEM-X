--!strict
return function(ProfileRules: any, PreferenceRules: any, Visuals: any): number
	local migrated = ProfileRules.clean(nil, PreferenceRules, Visuals, { music = 0.7, firstPerson = true })
	assert(migrated.version == ProfileRules.Version and migrated.preferences.music == 0.7 and migrated.preferences.firstPerson, "Legacy preferences must migrate into the profile schema")
	assert(migrated.kills == 0 and migrated.wins == 0 and migrated.skin == "Pulse", "Missing profile fields must receive safe defaults")
	local loaded = ProfileRules.clean({
		version = 2,
		preferences = { fov = 200, graphics = "Ultra", music = 0.25 },
		kills = 12.9, wins = -4, credits = 80.7, skin = "Aurum", operative = "Spectre",
		owned = { Pulse = true, Aurum = true, Unknown = true }, dailyDay = 20,
	}, PreferenceRules, Visuals)
	assert(loaded.kills == 12 and loaded.wins == 0 and loaded.credits == 80 and loaded.preferences.fov == 100, "Profile numbers and settings must be bounded")
	assert(loaded.preferences.graphics == "Auto" and loaded.skin == "Aurum" and loaded.operative == "Spectre", "Allowed profile appearance must load")
	assert(loaded.owned.Unknown == nil and loaded.owned.Pulse and loaded.owned.Aurum, "Only catalog cosmetics may persist")
	assert(loaded.shards == 0 and loaded.seasonTokens == 0 and not loaded.firstWinShardClaimed, "Version 2 profiles must migrate to empty currencies")
	local veteran = ProfileRules.clean({ version = 2, wins = 6 }, PreferenceRules, Visuals)
	assert(veteran.firstWinShardClaimed, "Version 2 wins must not grant a retroactive first-win Shard")
	local rejected = ProfileRules.clean({ version = 2, skin = "Aurum", owned = { Pulse = true } }, PreferenceRules, Visuals)
	assert(rejected.skin == "Pulse", "An unowned cosmetic cannot be equipped from stored data")
	local updated = ProfileRules.cosmetics({ skin = "Aurum", operative = "Relay", owned = { Orchid = true, Unknown = true }, dailyDay = 31 }, migrated, Visuals)
	assert(updated.skin == "Pulse" and updated.operative == "Relay" and updated.owned.Orchid and not updated.owned.Unknown and updated.dailyDay == 31, "Cosmetic updates must validate ownership and catalog entries")
	local purchase = ProfileRules.clean({ version = 2, credits = 45 }, PreferenceRules, Visuals)
	assert(ProfileRules.purchase(purchase, "Aurum", Visuals) and purchase.credits == 0 and purchase.owned.Aurum, "A valid purchase must atomically debit and grant a cosmetic")
	assert(not ProfileRules.purchase(purchase, "Aurum", Visuals) and purchase.credits == 0, "A duplicate purchase must not debit twice")
	assert(not ProfileRules.purchase(purchase, "Orchid", Visuals), "A free claim cannot enter the paid purchase path")
	local shardProfile = ProfileRules.clean({ version = 3, shards = 1 }, PreferenceRules, Visuals)
	assert(ProfileRules.purchase(shardProfile, "Voidglass", Visuals) and shardProfile.shards == 0 and shardProfile.owned.Voidglass, "Chaos Shards must purchase only the catalog cosmetic")
	assert(not ProfileRules.purchase(shardProfile, "Voidglass", Visuals) and shardProfile.shards == 0, "A repeated Shard purchase must not debit twice")
	local seasonProfile = ProfileRules.clean({ version = 3, seasonTokens = 6 }, PreferenceRules, Visuals)
	assert(ProfileRules.purchase(seasonProfile, "Solstice", Visuals) and seasonProfile.seasonTokens == 0 and seasonProfile.owned.Solstice, "Season Tokens must purchase the seasonal cosmetic")
	assert(not ProfileRules.purchase(ProfileRules.default(PreferenceRules), "Solstice", Visuals), "A client cannot bypass a seasonal cosmetic price")
	local economy = { MatchCredits = 20, WinCredits = 45, SeasonTokensPerMatch = 1, SeasonTokenWinBonus = 1, FirstWinShards = 1 }
	local rewards = ProfileRules.default(PreferenceRules)
	local lost, lossAward = ProfileRules.awardMatch(rewards, "server:1", false, economy)
	assert(lost and lossAward.credits == 20 and lossAward.seasonTokens == 1 and lossAward.shards == 0 and rewards.credits == 20, "A completed loss must earn participation Credits and one Season Token")
	local won, winAward = ProfileRules.awardMatch(rewards, "server:2", true, economy)
	assert(won and winAward.credits == 65 and winAward.seasonTokens == 2 and winAward.shards == 1 and rewards.credits == 85, "The first victory must grant participation, win bonuses and its first-win Shard")
	assert(not ProfileRules.awardMatch(rewards, "server:2", true, economy) and rewards.credits == 85 and rewards.seasonTokens == 3 and rewards.shards == 1, "A duplicated match result must not duplicate any currency")
	local nextWin, nextAward = ProfileRules.awardMatch(rewards, "server:3", true, economy)
	assert(nextWin and nextAward.shards == 0 and rewards.shards == 1 and rewards.seasonTokens == 5, "Later victories grant tokens without repeating the first-win Shard")
	assert(#rewards.ledger == 3 and rewards.ledger[2].action == "match-win", "Currency awards must leave an auditable transaction record")
	local reloaded = ProfileRules.clean(rewards, PreferenceRules, Visuals)
	assert(not ProfileRules.awardMatch(reloaded, "server:3", true, economy) and reloaded.credits == 150, "Serialized match identifiers must retain duplicate protection after a reload")
	local capped = ProfileRules.default(PreferenceRules)
	capped.credits, capped.shards, capped.seasonTokens = ProfileRules.MaximumStat, ProfileRules.MaximumStat, ProfileRules.MaximumStat
	local cappedOk, cappedAward = ProfileRules.awardMatch(capped, "capped:1", true, economy)
	assert(cappedOk and cappedAward.credits == 0 and cappedAward.shards == 0 and cappedAward.seasonTokens == 0 and capped.ledger[1].credits == 0, "Balances, result payouts and audit deltas must agree at the currency cap")
	local daily = ProfileRules.default(PreferenceRules)
	assert(ProfileRules.claimDaily(daily, 100) and daily.credits == 20 and daily.shards==1, "Day six grants its currency bundle")
	assert(not ProfileRules.claimDaily(daily, 100) and daily.credits == 20, "A duplicate daily claim must not grant twice")
	assert(ProfileRules.claimDaily(daily, 101) and daily.credits == 45 and daily.owned.Frostborn, "Day seven grants its guaranteed collection")
	assert(not ProfileRules.claimDaily(daily, 100) and not ProfileRules.claimDaily(daily, 101.5) and not ProfileRules.claimDaily(daily, math.huge) and daily.credits == 45, "Daily claims must reject past, fractional and nonfinite dates")
	local cleaned = ProfileRules.clean({ version = 3, credits = -3, shards = 1.5, seasonTokens = math.huge, ledger = { { id = "bad", action = "test", credits = math.huge } } }, PreferenceRules, Visuals)
	assert(cleaned.credits == 0 and cleaned.shards == 1 and cleaned.seasonTokens == 0 and #cleaned.ledger == 1 and cleaned.ledger[1].credits == 0, "Currency and transaction data must be normalized on load")
	return 28
end
