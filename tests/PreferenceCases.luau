--!strict
return function(Rules: any): number
	local defaults = Rules.Defaults
	local result = Rules.merge(defaults, { music = 8, sound = -4, ui = 0.4, fov = 500, graphics = "Low", muted = true, credits = 9999, skin = "Aurum" })
	assert(result.music == 1 and result.sound == 0 and result.ui == 0.4 and result.fov == 100, "Numeric settings must clamp")
	assert(result.graphics == "Low" and result.muted and result.credits == nil and result.skin == nil, "Only settings are accepted")
	result = Rules.merge(defaults, { music = 0/0, sound = math.huge, graphics = "Ultra", firstPerson = "true" })
	assert(result.music == defaults.music and result.sound == defaults.sound and result.graphics == "Auto" and not result.firstPerson, "Invalid values must be rejected")
	assert(Rules.wallet(3, 0, 0, 45) == 0 and Rules.wallet(0, 0, 15, 0) == 15 and Rules.wallet(0, 0, 0, 100) == 0, "Session credit conservation failed")
	return 4
end
