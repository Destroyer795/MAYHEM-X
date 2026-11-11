--!strict
local AudioConfig = {}
AudioConfig.Source = "https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua"
AudioConfig.Builtins = table.freeze({
	Jump = "rbxasset://sounds/action_jump.mp3", Land = "rbxasset://sounds/action_jump_land.mp3",
	Water = "rbxasset://sounds/impact_water.mp3", Wind = "rbxasset://sounds/action_falling.mp3",
	Rise = "rbxasset://sounds/action_get_up.mp3", Swim = "rbxasset://sounds/action_swim.mp3",
})
AudioConfig.Uploads = table.freeze({
	-- Replace empty values only after uploading the matching original WAV and checking experience permissions.
	Lobby = "", Collapse = "", Jungle = "", Solar = "", Frost = "", Skyline = "", Combat = "", Showdown = "", Victory = "", Defeat = "",
	Shot = "", Reload = "", Switch = "", Slash = "", MeleeHit = "", Impact = "", Explosion = "", Shield = "", Eliminate = "", Repulse = "", Ultimate = "", Mutation = "", PowerSteal = "", UI = "", Hover = "", Transition = "", Notification = "", Reward = "", Purchase = "",
})
AudioConfig.Cues = table.freeze({
	Shot = { builtin = "Land", speed = 1.8, volume = 0.23 }, Impact = { builtin = "Land", speed = 2.2, volume = 0.14 },
	Reload = { builtin = "Rise", speed = 1.6, volume = 0.2 }, Switch = { builtin = "Rise", speed = 2, volume = 0.12 },
	Slash = { builtin = "Wind", speed = 2, volume = 0.18 }, MeleeHit = { builtin = "Land", speed = 0.85, volume = 0.3 },
	Explosion = { builtin = "Land", speed = 0.5, volume = 0.35 }, Shield = { builtin = "Jump", speed = 0.8, volume = 0.15 },
	Eliminate = { builtin = "Rise", speed = 1.15, volume = 0.22 }, Repulse = { builtin = "Swim", speed = 1.8, volume = 0.25 },
	Ultimate = { builtin = "Rise", speed = 0.8, volume = 0.3 }, Mutation = { builtin = "Jump", speed = 0.65, volume = 0.18 },
	PowerSteal = { builtin = "Rise", speed = 1.5, volume = 0.2 },
	UI = { builtin = "Jump", speed = 2.2, volume = 0.09 }, Hover = { builtin = "Jump", speed = 2.8, volume = 0.035 },
	Transition = { builtin = "Rise", speed = 2, volume = 0.09 }, Notification = { builtin = "Jump", speed = 1.5, volume = 0.1 },
	Reward = { builtin = "Rise", speed = 1.7, volume = 0.18 }, Purchase = { builtin = "Jump", speed = 1.2, volume = 0.17 },
	Victory = { builtin = "Rise", speed = 1.2, volume = 0.25 }, Defeat = { builtin = "Land", speed = 0.6, volume = 0.2 },
})
AudioConfig.Ambience = table.freeze({ Collapse = "Wind", Jungle = "Water", Solar = "Wind", Frost = "Wind", Skyline = "Wind" })
AudioConfig.Music = table.freeze({ "Lobby", "Collapse", "Jungle", "Solar", "Frost", "Skyline", "Combat", "Showdown", "Victory", "Defeat" })
AudioConfig.MaxVoices = 20
AudioConfig.UIReserve = 2

function AudioConfig.effect(cue: string, failures: { [string]: boolean }): (string?, number, number)
	local fallback = AudioConfig.Cues[cue]
	local upload = AudioConfig.Uploads[cue]
	if upload and upload ~= "" and not failures[upload] then
		return upload, 1, if fallback then fallback.volume else 0.3
	end
	local uri = if fallback then AudioConfig.Builtins[fallback.builtin] else nil
	if uri and not failures[uri] then return uri, fallback.speed, fallback.volume end
	return nil, 1, 0
end

function AudioConfig.isUI(cue: string): boolean
	return cue == "UI" or cue == "Hover" or cue == "Transition" or cue == "Notification" or cue == "Reward" or cue == "Purchase"
end

return table.freeze(AudioConfig)
