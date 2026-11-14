# MAYHEM X

**ENTER THE CHAOS. BECOME THE LEGEND.**

An original Roblox PvP survival game for up to sixteen contenders. Vote for a frontier, choose from four firearms and three melee weapons, use Repulse, and survive the closing signal. The current content pass adds an original hangar hub, structural operator outfits, a field armory and free handling sidegrades.

The current Premium place is being edited and tested through the official Roblox Studio MCP. Uploaded audio, queue/voting, combat requests, duel transfer and result music have passed a two-client Studio smoke test. A versioned profile schema now includes settings, account eliminations/wins, credits and cosmetics with a legacy-preference migration, retries and session leases. The local place is unpublished, so Roblox refuses DataStore calls; persistent save/rejoin remains unverified. This remains a development build: the full visual transformation, device performance and sixteen-player acceptance are unfinished.

The ongoing transformation uses branch `feature/studio-production-transformation` and the live file `build/MAYHEM-X-Transformation.rbxl`. Twenty-two original mesh assets are exported for source control. Vanguard wears breacher armor, Spectre a recon hood and mantle, and Relay a utility jacket. The same outfit builder serves previews and gameplay. The generated R15 showcase and its idle animation are stored in the live place; a source-only build uses the player-character fallback. Earlier Premium/audio builds remain preserved.

## Open and play

1. Open `build/MAYHEM-X-Transformation.rbxl` in the existing Roblox Studio. A daylight Collapse editor preview is included. Startup replaces it with the hub and active arena.
2. Press **F5** for the UI review. The main menu opens automatically. Desktop uses a command rail and contextual tabs; phones use scrolling navigation. For a match, use **Server & Clients** with two clients and click **PLAY / JOIN QUEUE** in each.
3. Use the five-arena action on PLAY or MAP BALLOT in matchmaking, preview a map, then vote before intermission ends. Only the first sixteen queued contenders have ballots.
4. After insertion/countdown, fight until one survivor remains. Repeat for each map and follow [DEVELOPMENT.md](DEVELOPMENT.md).

| Arena | Layout and identity |
| --- | --- |
| The Collapse | Four floating machinery districts, central spiral tower, bridge loop, lower vault |
| Neon Jungle | Tropical islands, nineteen palms, waterfalls, canopy lookout and lower passages |
| Solar Wasteland | Warm mesas, canyon routes, ancient gate, buried gallery and moving skiff |
| Frostbite | Three snow/ice ridges, frozen crossbridges, crystal cover and elevated fortress |
| Skyline Zero | Four roof heights, sloped skybridges, elevators, service deck and city skyline |

Every template has sixteen spawns, four ammo-cache locations, cover, a hazard and a final duel deck. Server integration includes map cleanup, destructible cover, collapsing links, Low Gravity/Shield Drought events, a shrinking safe zone and the defensive Aegis ultimate. Eighty spawn raycasts passed in Studio; Jungle and Frost ran in the two-client test. Complete traversal and combat acceptance on every arena is pending. The maps combine the preserved physical routes with original mesh scenery. Terrain surrounds the playable bounds and is cleared using owned-region metadata. Full production art acceptance is pending.

The FIFO queue, round transitions, serialized spawning, health/shields, ammo/reloading, kill attribution and server combat validation are retained. New map/environment hooks are explicit changes. Cosmetics never change combat stats.

## Menus, collection and audio

Deployment, matchmaking, map ballots, operative profiles, weapon previews, inventory, Style Lab, daily cache, settings, loading and results share one responsive interface. The HUD shows vitals, ammo, cooldowns, Aegis charge, players, kills, timer, feed and reality/zone status.

The Field Operations interface uses warm graphite, ivory actions and restrained oxblood/coral accents. Its home composition combines the hangar, operator, loadout display, large mode title and real profile balances. Armory has seven selectable weapons, rotating 3D previews, base-versus-kit statistics, six handling kits and next-round equip controls. Inventory finishes apply to selected weapons. Existing career, ballot, queue, collection and settings actions share the shell. Ranked/events still disclose unavailable systems.

Portrait phones stack previews and actions, use scrolling navigation and keep all three currencies visible. Tablet/desktop layouts use wider compositions. Reward counters, account XP, a skippable reveal and an original victory pose use the existing server result payload. Native Frames and pixel-aligned text avoid full-screen CanvasGroup blur. Desktop actions and representative phone/tablet screenshots were reviewed in Studio. Physical touch/controller and wide-monitor acceptance remain pending.

Three operative profiles and eight finishes are cosmetic. Orchid and Ember are free catalog claims, Prism and 15 Mayhem Credits are available from the daily cache, Aurum costs 45 Credits, Voidglass costs 1 Chaos Shard, and Solstice costs 6 Season Tokens. Earn 15 Credits per elimination, 20 for completing an active match, and 45 more for a win. Active matches grant one Season Token, with one additional Token for a win; the first victory grants one Chaos Shard. A versioned V3 server profile records all three balances, cosmetics and a bounded transaction ledger. The local unpublished Studio place currently falls back to session-only data. DataStore persistence remains unverified until a permitted published test environment is available.

All twenty-nine user-uploaded original audio IDs are integrated. Lobby, map insertion, combat, showdown and win/loss music follow server state. Effects have bounded spatial voices, independent volumes, mute and built-in fallbacks. Both simulated clients loaded all twenty-nine uploads plus six fallbacks; advancing playback and nonzero loudness were observed for live events. Human listening quality and permissions in the intended published universe remain unverified. [SETUP.md](SETUP.md#uploaded-audio) lists every ID and event.

PC: WASD/jump, left click attack, 1/2 weapons, R reload, Q Repulse, G Aegis, C camera, M menu. Touch uses Roblox movement/jump, right-side aiming and combat buttons. Controller: RT attack, LB swap, X reload, Y Repulse, B Aegis, D-pad down camera, D-pad left menu.

## Build and handoff

Keep the local Premium place open for the live workflow in [DEVELOPMENT.md](DEVELOPMENT.md). Do not run the default offline build or package command over this Studio-authored place. Source changes are mirrored after inspecting live scripts; Rojo is one-way toward Studio and cannot export scene edits.

The current live local file is `build/MAYHEM-X-Transformation.rbxl`. Original Phase 1, Visual archives and earlier Premium backups remain preserved. Current evidence is in `build/Studio-audio-verification.json` and `build/screenshots/`; the earlier offline package report describes an older build. Module ownership is in [ARCHITECTURE.md](ARCHITECTURE.md), with test limits in [DEVELOPMENT.md](DEVELOPMENT.md) and [CHANGELOG.md](CHANGELOG.md).

Work remains in `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`, the writable workspace. Scripts are relocatable to the requested `C:\MAYHEM-X` after inspecting that destination. Git history uses `.version-control/`; use `scripts/git.ps1`. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`. No experience was published, no Robux was spent, and no credentials were accessed. The UI push is authorized, but this session could not reach GitHub over port 443.

The current visual gate remains incomplete. Studio screenshot capture works during playtests. The latest Studio rules and map checks passed, and the place was saved locally. The default offline build must not overwrite live Studio edits. Existing binary and source backups remain in `build/backups/`.
