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

Deployment, matchmaking, map ballots, operative profiles, weapon previews, inventory, collection workshop, daily cache, settings, loading and results share one responsive interface. The HUD shows vitals, ammo, cooldowns, Aegis charge, players, kills, timer, feed and reality/zone status.

The Field Operations interface uses warm graphite, ivory actions and restrained oxblood/coral accents. The new home stage integrates the operator, hangar and mounted loadout with a larger title and real profile balances. Collection uses one inspection stage, seven weapon choices, full-surface versus legacy filters, stock comparison, drag rotation and zoom. Armory retains seven selectable weapons, kit comparisons and next-round equip controls. Ranked/events still disclose unavailable systems.

Portrait phones stack previews and actions, use scrolling navigation and keep all three currencies visible. Tablet/desktop layouts use wider compositions. Reward counters, account XP, a skippable reveal and an original victory pose use the existing server result payload. Native Frames and pixel-aligned text avoid full-screen CanvasGroup blur. Desktop actions and representative phone/tablet screenshots were reviewed in Studio. Physical touch/controller and wide-monitor acceptance remain pending.

Three original full-surface collections cover all four guns and three melee weapons: Void Reaver / Void Edge (135 Credits), Solaris / Solar Fang (3 Shards) and Frostborn / Frostbite (Sunday cache). Their 21 variants have generated UVs, color, metalness and roughness maps across every mesh component. The eight older signal finishes remain owned and are labelled legacy accents. No cosmetic changes combat stats.

The Daily Cache follows a fixed Monday-Sunday UTC week. Only today's reward can be claimed, once. Missed dates cannot be back-claimed; claimed currency and cosmetics remain owned after the weekly reset. Sunday does not require earlier claims.

| UTC day | Guaranteed reward |
| --- | --- |
| Monday | 5 Credits |
| Tuesday | 8 Credits |
| Wednesday | 10 Credits + 1 Season Token |
| Thursday | 12 Credits |
| Friday | 15 Credits + Prism finish |
| Saturday | 20 Credits + 1 Chaos Shard |
| Sunday | 25 Credits + Frostborn collection; owners receive 1 additional Shard |

The week grants 95 Credits, below the old seven-day total of 105. Existing match earning rates and prices remain unchanged: 15 Credits per elimination, 20 for active-match completion, 45 more for a win, one Token per completion and one extra for a win. The first victory grants one Shard. Profile schema V4 preserves V3 balances and ownership. Persistent daily claims confirm the profile write before revealing a reward and retain an idempotent recovery marker after an uncertain write. The open local file has PlaceId and GameId 0, so its calendar explicitly says SESSION PREVIEW. Real DataStore save/rejoin remains unverified.

All twenty-nine user-uploaded original audio IDs are integrated. Lobby, map insertion, combat, showdown and win/loss music follow server state. Effects have bounded spatial voices, independent volumes, mute and built-in fallbacks. Both simulated clients loaded all twenty-nine uploads plus six fallbacks; advancing playback and nonzero loudness were observed for live events. Human listening quality and permissions in the intended published universe remain unverified. [SETUP.md](SETUP.md#uploaded-audio) lists every ID and event.

PC: WASD/jump, left click attack, 1/2 weapons, R reload, Q Repulse, G Aegis, C camera, M menu. Touch uses Roblox movement/jump, right-side aiming and combat buttons. Controller: RT attack, LB swap, X reload, Y Repulse, B Aegis, D-pad down camera, D-pad left menu.

## Build and handoff

Keep the local Premium place open for the live workflow in [DEVELOPMENT.md](DEVELOPMENT.md). Do not run the default offline build or package command over this Studio-authored place. Source changes are mirrored after inspecting live scripts; Rojo is one-way toward Studio and cannot export scene edits.

Open `build/MAYHEM-X-Transformation.rbxl` for the Studio-authored result. The separate `build/MAYHEM-X-CacheCosmetics-Source.rbxlx` is a validated source snapshot, with the documented character fallback instead of the live authoring rig. Original builds remain preserved. This pass passed 372 focused Studio assertions and 130 assertions across two clients. All 63 unique surface images loaded locally. Screenshots are `build/screenshots/Cache-*.jpg`; the actual multiplayer report is `build/Studio-CacheCosmetics-Acceptance-20261114.json`. Module ownership is in [ARCHITECTURE.md](ARCHITECTURE.md), with limits in [DEVELOPMENT.md](DEVELOPMENT.md).

Work remains in `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`, the writable workspace. Scripts are relocatable to the requested `C:\MAYHEM-X` after inspecting that destination. Git history uses `.version-control/`; use `scripts/git.ps1`. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`. No experience was published, no Robux was spent, and no credentials were accessed. The cache/cosmetics task does not authorize a GitHub push.

The cache/cosmetic interface was inspected on desktop, laptop, tablet and emulated phone layouts. Real returning-account persistence, published-universe asset permissions and physical touch/controller input remain open. Studio intermittently returned a 1 x 1 renderer after device switching; captures were retained only from working viewports. The default offline build must not overwrite live Studio edits. Windows denied reading the saved binary for another copy; source backups and older binary archives remain in `build/backups/`.
