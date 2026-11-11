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
	{ id = "Pulse", name = "PULSE / AMETHYST", color = { 149, 95, 255 }, source = "starter", description = "Amethyst energy cells with a graphite shell." },
	{ id = "Glacier", name = "GLACIER / CYAN", color = { 78, 229, 238 }, source = "starter", description = "A clean cyan circuit. Included in your collection." },
	{ id = "Orchid", name = "ORCHID / MAGENTA", color = { 238, 87, 189 }, source = "shop", description = "Claim this complimentary style for this server session." },
	{ id = "Ember", name = "EMBER / CORAL", color = { 255, 116, 132 }, source = "shop", description = "A controlled coral glow. Complimentary session unlock." },
	{ id = "Prism", name = "PRISM / WHITE", color = { 220, 229, 255 }, source = "daily", description = "Daily cache trial, available for this server session." },
	{ id = "Aurum", name = "AURUM / GOLD", color = { 255, 190, 67 }, source = "purchase", cost = 45, description = "45 earned session credits. Cosmetic only. Resets after leaving." },
})
Visuals.Operatives = table.freeze({
	{ id = "Vanguard", name = "VANGUARD", description = "Wide signal plates with an amethyst default finish. Cosmetic only.", shoulders = 1.15 },
	{ id = "Spectre", name = "SPECTRE", description = "Narrow signal plates and a compact profile. Cosmetic only.", shoulders = 0.85 },
	{ id = "Relay", name = "RELAY", description = "Balanced circuit plates. Cosmetic only.", shoulders = 1 },
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
