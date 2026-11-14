--!strict
local Visuals = {}
Visuals.Palette = table.freeze({
	Void = { 16, 37, 58 }, Navy = { 34, 64, 91 }, Panel = { 231, 241, 246 }, Metal = { 148, 178, 199 },
	Purple = { 27, 132, 213 }, Cyan = { 22, 177, 200 }, Magenta = { 217, 78, 153 },
	Red = { 224, 79, 91 }, White = { 248, 251, 252 }, Muted = { 76, 104, 126 }, Action = { 18, 108, 183 },
	Surface = { 247, 249, 246 }, Ink = { 25, 49, 73 }, Gold = { 242, 174, 63 }, Violet = { 150, 106, 224 },
})
Visuals.Mode = table.freeze({ Id = "LastSignal", Name = "LAST SIGNAL", Subtitle = "SOLO SURVIVAL / FIVE ARENAS", Description = "Sixteen contenders. Five arenas. Vote, survive the closing zone, and win the final signal. Every operative has the same combat stats." })
Visuals.Skins = table.freeze({
	{ id="VoidReaver",name="VOID REAVER",meleeName="VOID EDGE",rarity="Epic",color={174,119,238},source="purchase",currency="credits",cost=135,fullSurface=true,description="Obsidian ceramic, violet metal and engraved silver tessellation across every weapon component." },
	{ id="Solaris",name="SOLARIS",meleeName="SOLAR FANG",rarity="Legendary",color={226,186,104},tint={255,211,139},source="shards",currency="shards",cost=3,fullSurface=true,description="Engraved gold, obsidian mechanics and patterned grips. Original sunburst detailing with contrasting metal and roughness." },
	{ id="Frostborn",name="FROSTBORN",meleeName="FROSTBITE",rarity="Legendary",color={164,222,240},source="weekly",fullSurface=true,description="Crystalline frost etching, ivory ceramic and glacial blue metal. Guaranteed Day 07 collection, permanent ownership when saving is available." },
	{ id = "Pulse", name = "PULSE / AMETHYST", rarity = "Common", color = { 149, 95, 255 }, source = "starter", description = "Amethyst energy cells with a graphite shell." },
	{ id = "Glacier", name = "GLACIER / CYAN", rarity = "Common", color = { 78, 229, 238 }, source = "starter", description = "A clean cyan circuit. Included in your collection." },
	{ id = "Orchid", name = "ORCHID / MAGENTA", rarity = "Uncommon", color = { 238, 87, 189 }, source = "shop", description = "Claim this complimentary cosmetic finish." },
	{ id = "Ember", name = "EMBER / CORAL", rarity = "Uncommon", color = { 255, 116, 132 }, source = "shop", description = "A controlled coral cosmetic finish." },
	{ id = "Prism", name = "PRISM / WHITE", rarity = "Rare", color = { 220, 229, 255 }, source = "daily", description = "Daily cache cosmetic finish." },
	{ id = "Aurum", name = "AURUM / GOLD", rarity = "Rare", currency = "credits", source = "purchase", cost = 45, color = { 255, 190, 67 }, description = "45 Mayhem Credits. Cosmetic only." },
	{ id = "Voidglass", name = "VOIDGLASS / CYAN", rarity = "Rare", currency = "shards", source = "shards", cost = 1, color = { 105, 231, 245 }, description = "Earn one Chaos Shard with your first victory, then claim this cyan finish." },
	{ id = "Solstice", name = "SOLSTICE / AMBER", rarity = "Rare", currency = "seasonTokens", source = "season", cost = 6, color = { 255, 171, 78 }, description = "Earn Season Tokens from completed matches and victories." },
})
Visuals.Operatives = table.freeze({
	{ id = "Vanguard", name = "VANGUARD", description = "Breacher armor, layered shoulder guards and a full combat helmet. Cosmetic only.", shoulders = 1.15 },
	{ id = "Spectre", name = "SPECTRE", description = "Recon hood, opaque visor, asymmetric mantle and chest harness. Cosmetic only.", shoulders = 0.85 },
	{ id = "Relay", name = "RELAY", description = "Field-engineer jacket, articulated utility sleeves and a service helmet. Cosmetic only.", shoulders = 1 },
})
Visuals.Capabilities = table.freeze({ Ultimates = true, ChaosEvents = true, Destruction = true })
Visuals.Budgets = table.freeze({ WorldParts = 720, EffectRoots = 36, EffectDistance = 360, AnimationDistance = 220, AnimatedRings = 3 })

function Visuals.skin(id: string): any
	for _, entry in Visuals.Skins do if entry.id == id then return entry end end
	return nil
end

function Visuals.operative(id: string): any
	for _, entry in Visuals.Operatives do if entry.id == id then return entry end end
	return nil
end

return table.freeze(Visuals)
