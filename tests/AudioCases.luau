--!strict
return function(Config: any): number
	local count = 0
	for name, cue in Config.Cues do
		assert(Config.Builtins[cue.builtin] and cue.volume > 0 and cue.volume <= 0.4 and cue.speed > 0 and cue.speed <= 3, "Invalid fallback cue: " .. name)
		local uri, speed, volume = Config.effect(name, {})
		local upload = Config.Uploads[name]
		assert(uri == (if upload and upload ~= "" then upload else Config.Builtins[cue.builtin]), "Incorrect effect route: " .. name)
		assert(speed == (if upload and upload ~= "" then 1 else cue.speed) and volume == cue.volume, "Incorrect effect tuning: " .. name)
		local failed: { [string]: boolean } = {}
		if upload and upload ~= "" then failed[upload] = true end
		assert(Config.effect(name, failed) == Config.Builtins[cue.builtin], "Unavailable upload did not fall back: " .. name)
		failed[Config.Builtins[cue.builtin]] = true
		assert(Config.effect(name, failed) == nil, "Unavailable fallback must remain silent: " .. name)
		count += 5
	end
	for name, uri in Config.Uploads do
		assert(uri == "" or uri:match("^rbxassetid://[1-9]%d*$"), "Invalid uploaded audio ID: " .. name)
		count += 1
	end
	assert(Config.MaxVoices <= 20, "Audio voice budget is unbounded")
	assert(Config.UIReserve >= 1 and Config.UIReserve < Config.MaxVoices, "UI voices must be reserved within the budget")
	assert(#Config.Music == 10, "Music context catalog changed")
	for _, name in Config.Music do assert(Config.Uploads[name] ~= nil, "Missing music upload field: " .. name); count += 1 end
	assert(Config.effect("Unknown", {}) == nil, "Unknown cue must not allocate a voice")
	assert(Config.isUI("Purchase") and Config.isUI("Hover") and not Config.isUI("Shot"), "Incorrect audio group")
	return count + 5
end
