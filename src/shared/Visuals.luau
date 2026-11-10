--!strict
local Visuals = {}
Visuals.Palette = table.freeze({
	Void = { 7, 10, 20 }, Navy = { 14, 19, 35 }, Panel = { 24, 31, 49 }, Metal = { 47, 57, 78 },
	Purple = { 149, 95, 255 }, Cyan = { 78, 229, 238 }, Magenta = { 238, 87, 189 },
	Red = { 255, 95, 117 }, White = { 237, 242, 255 }, Muted = { 143, 158, 186 },
})
Visuals.Mode = table.freeze({ Id = "Collapse", Name = "LAST SIGNAL", Subtitle = "SOLO SURVIVAL / THE COLLAPSE", Description = "Sixteen contenders. One signal remains. Rifle, blade and Repulse. Every operative has the same combat stats." })
Visuals.Skins = table.freeze({
	{ id = "Pulse", name = "PULSE / AMETHYST", color = { 149, 95, 255 }, source = "starter", description = "Amethyst energy cells with a graphite shell." },
	{ id = "Glacier", name = "GLACIER / CYAN", color = { 78, 229, 238 }, source = "starter", description = "A clean cyan circuit. Included in your collection." },
	{ id = "Orchid", name = "ORCHID / MAGENTA", color = { 238, 87, 189 }, source = "shop", description = "Claim this complimentary style for this server session." },
	{ id = "Ember", name = "EMBER / CORAL", color = { 255, 116, 132 }, source = "shop", description = "A controlled coral glow. Complimentary session unlock." },
	{ id = "Prism", name = "PRISM / WHITE", color = { 220, 229, 255 }, source = "daily", description = "Daily cache trial, available for this server session." },
})
Visuals.Operatives = table.freeze({
	{ id = "Vanguard", name = "VANGUARD", description = "Wide signal plates with an amethyst default finish. Cosmetic only.", shoulders = 1.15 },
	{ id = "Spectre", name = "SPECTRE", description = "Narrow signal plates and a compact profile. Cosmetic only.", shoulders = 0.85 },
	{ id = "Relay", name = "RELAY", description = "Balanced circuit plates. Cosmetic only.", shoulders = 1 },
})
Visuals.Capabilities = table.freeze({ Ultimates = false, ChaosEvents = false, Destruction = false })
Visuals.Budgets = table.freeze({ WorldParts = 720, EffectRoots = 36, EffectDistance = 360, AnimationDistance = 220, AnimatedRings = 3 })
Visuals.Audio = table.freeze({
	-- Add only audio you own or have verified permission to use. Empty routes stay silent.
	Menu = "", Lobby = "", Combat = "", Shot = "", Slash = "", Repulse = "", UI = "", Eliminate = "", Victory = "", Defeat = "",
})

function Visuals.skin(id: string): any
	for _, entry in Visuals.Skins do if entry.id == id then return entry end end
	return nil
end

function Visuals.operative(id: string): any
	for _, entry in Visuals.Operatives do if entry.id == id then return entry end end
	return nil
end

return table.freeze(Visuals)
