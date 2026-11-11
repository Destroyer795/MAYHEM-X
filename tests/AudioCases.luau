--!strict
return function(Config: any): number
	local count = 0
	for name, cue in Config.Cues do
		assert(Config.Builtins[cue.builtin] and cue.volume > 0 and cue.volume <= 0.4 and cue.speed > 0 and cue.speed <= 3, "Invalid fallback cue: " .. name)
		count += 1
	end
	for name, uri in Config.Uploads do
		assert(uri == "" or uri:match("^rbxassetid://[1-9]%d*$"), "Invalid uploaded audio ID: " .. name)
		count += 1
	end
	assert(Config.MaxVoices <= 20, "Audio voice budget is unbounded")
	return count + 1
end
