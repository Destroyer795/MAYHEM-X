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
	local rejected = ProfileRules.clean({ version = 2, skin = "Aurum", owned = { Pulse = true } }, PreferenceRules, Visuals)
	assert(rejected.skin == "Pulse", "An unowned cosmetic cannot be equipped from stored data")
	local updated = ProfileRules.cosmetics({ skin = "Aurum", operative = "Relay", owned = { Orchid = true, Unknown = true }, dailyDay = 31 }, migrated, Visuals)
	assert(updated.skin == "Pulse" and updated.operative == "Relay" and updated.owned.Orchid and not updated.owned.Unknown and updated.dailyDay == 31, "Cosmetic updates must validate ownership and catalog entries")
	local purchase = ProfileRules.clean({ version = 2, credits = 45 }, PreferenceRules, Visuals)
	assert(ProfileRules.purchase(purchase, "Aurum", Visuals) and purchase.credits == 0 and purchase.owned.Aurum, "A valid purchase must atomically debit and grant a cosmetic")
	assert(not ProfileRules.purchase(purchase, "Aurum", Visuals) and purchase.credits == 0, "A duplicate purchase must not debit twice")
	assert(not ProfileRules.purchase(purchase, "Orchid", Visuals), "A free claim cannot enter the paid purchase path")
	local daily = ProfileRules.default(PreferenceRules)
	assert(ProfileRules.claimDaily(daily, 100) and daily.credits == 15 and daily.owned.Prism, "Daily claim must grant its cosmetic and credits together")
	assert(not ProfileRules.claimDaily(daily, 100) and daily.credits == 15, "A duplicate daily claim must not grant twice")
	return 11
end
