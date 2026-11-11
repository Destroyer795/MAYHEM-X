--!strict
local AudioConfig = {}
AudioConfig.Source = "https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua"
AudioConfig.Builtins = table.freeze({
	Jump = "rbxasset://sounds/action_jump.mp3", Land = "rbxasset://sounds/action_jump_land.mp3",
	Water = "rbxasset://sounds/impact_water.mp3", Wind = "rbxasset://sounds/action_falling.mp3",
	Rise = "rbxasset://sounds/action_get_up.mp3", Swim = "rbxasset://sounds/action_swim.mp3",
})
AudioConfig.Uploads = table.freeze({
	-- User-provided original audio uploads. Loading and experience permissions are checked at runtime.
	Lobby = "rbxassetid://115295081724326", Collapse = "rbxassetid://119354128442400", Jungle = "rbxassetid://137323613567452", Solar = "rbxassetid://93912277388041", Frost = "rbxassetid://132327355812260", Skyline = "rbxassetid://75930625752768", Combat = "rbxassetid://74401952086561", Showdown = "rbxassetid://93832246189768", Victory = "rbxassetid://126488632915135", Defeat = "rbxassetid://93717867149696",
	Shot = "rbxassetid://117384060288786", Reload = "rbxassetid://127622753054141", Switch = "rbxassetid://133299106908058", Slash = "rbxassetid://85161275315961", MeleeHit = "rbxassetid://75145654636700", Impact = "rbxassetid://125720845191168", Explosion = "rbxassetid://130673317918385", Shield = "rbxassetid://79794280696752", Eliminate = "rbxassetid://85795250351709", Repulse = "rbxassetid://120827402091841", Ultimate = "rbxassetid://116582094733707", Mutation = "rbxassetid://118969565930031", PowerSteal = "rbxassetid://125966715610498", UI = "rbxassetid://87868301798689", Hover = "rbxassetid://83803776836215", Transition = "rbxassetid://78810693063926", Notification = "rbxassetid://123408274839656", Reward = "rbxassetid://104912968188467", Purchase = "rbxassetid://113975906689066",
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

function AudioConfig.effect(cue: string, failures: { [string]: boolean }, fetched: { [string]: string }?): (string?, number, number)
	local fallback = AudioConfig.Cues[cue]
	local upload = AudioConfig.Uploads[cue]
	if upload and upload ~= "" and not failures[upload] and (not fetched or fetched[upload] == "Success") then
		return upload, 1, if fallback then fallback.volume else 0.3
	end
	local uri = if fallback then AudioConfig.Builtins[fallback.builtin] else nil
	if uri and not failures[uri] then return uri, fallback.speed, fallback.volume end
	return nil, 1, 0
end

function AudioConfig.isUI(cue: string): boolean
	return cue == "UI" or cue == "Hover" or cue == "Transition" or cue == "Notification" or cue == "Reward" or cue == "Purchase"
end

function AudioConfig.context(state: any, userId: number, combatRecent: boolean): string
	if state.phase == "Results" and state.inMatch and state.result and state.result.winnerId then
		return if state.result.winnerId == userId then "Victory" else "Defeat"
	end
	if not state.inMatch then return "Lobby" end
	local mapId = if state.map then state.map.id else "Collapse"
	if state.phase == "Loading" or state.phase == "Countdown" then return mapId end
	if state.phase == "Active" and state.alive then
		if state.map and state.map.duel then return "Showdown" end
		return if combatRecent then "Combat" else mapId
	end
	return "Lobby"
end

return table.freeze(AudioConfig)
