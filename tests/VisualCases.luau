--!strict
return function(Visuals: any): number
	local checks = 0
	local ids: { [string]: boolean } = {}
	for _, skin in Visuals.Skins do
		assert(not ids[skin.id] and Visuals.skin(skin.id) == skin, "Style IDs must be unique and resolvable")
		ids[skin.id] = true
		assert(skin.source == "starter" or skin.source == "shop" or skin.source == "daily" or skin.source=="weekly" or ((skin.source == "purchase" or skin.source == "shards" or skin.source == "season") and skin.cost > 0 and type(skin.currency) == "string"), "Unknown entitlement source")
		assert(#skin.color == 3, "Style color needs three channels")
		for _, channel in skin.color do assert(channel >= 0 and channel <= 255, "Color channel out of range"); checks += 1 end
		checks += 3
	end
	assert(Visuals.skin("untrusted") == nil and Visuals.operative("untrusted") == nil, "Unknown selections must be rejected")
	checks += 1
	for _, operative in Visuals.Operatives do
		assert(Visuals.operative(operative.id) == operative and operative.shoulders >= 0.8 and operative.shoulders <= 1.2, "Invalid cosmetic operative")
		checks += 1
	end
	assert(Visuals.Capabilities.Ultimates and Visuals.Capabilities.ChaosEvents, "Premium maps require their live gameplay integrations")
	assert(Visuals.Budgets.WorldParts <= 720 and Visuals.Budgets.EffectRoots <= 36, "Visual budgets must stay bounded")
	return checks + 2
end
