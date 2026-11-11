# MAYHEM X

**ENTER THE CHAOS. BECOME THE LEGEND.**

An original Roblox PvP survival game for up to sixteen contenders. Vote for a frontier, fight with the VECTOR-18 and Rift Blade, use Repulse, and survive the closing signal. The premium milestone adds five physical arenas, a daylight hub, brighter menus, combat feedback and an original audio pack.

The current Premium place is being edited and tested through the official Roblox Studio MCP. Uploaded audio, queue/voting, combat requests, duel transfer and result music have passed a two-client Studio smoke test. This remains a development build: production progression, the full visual transformation, device performance and sixteen-player acceptance are unfinished.

## Open and play

1. Open `build/MAYHEM-X-Premium.rbxlx` in the existing Roblox Studio. A daylight Collapse editor preview is included. Startup replaces it with the hub and active arena.
2. Start **Server & Clients** with two clients. In each client, click **PLAY / JOIN QUEUE**.
3. Open **ARENAS**, preview a map, then vote before intermission ends. Only the first sixteen queued contenders have ballots.
4. After insertion/countdown, fight until one survivor remains. Repeat for each map and follow [DEVELOPMENT.md](DEVELOPMENT.md).

| Arena | Layout and identity |
| --- | --- |
| The Collapse | Four floating machinery districts, central spiral tower, bridge loop, lower vault |
| Neon Jungle | Tropical islands, nineteen palms, waterfalls, canopy lookout and lower passages |
| Solar Wasteland | Warm mesas, canyon routes, ancient gate, buried gallery and moving skiff |
| Frostbite | Three snow/ice ridges, frozen crossbridges, crystal cover and elevated fortress |
| Skyline Zero | Four roof heights, sloped skybridges, elevators, service deck and city skyline |

Every template has sixteen spawns, four ammo-cache locations, cover, a hazard and a final duel deck. Server integration includes map cleanup, destructible cover, collapsing links, Low Gravity/Shield Drought events, a shrinking safe zone and the defensive Aegis ultimate. Eighty spawn raycasts passed in Studio; Jungle and Frost ran in the two-client test. Complete traversal and combat acceptance on every arena is pending. The current maps contain procedural Parts and no MeshParts, so they do not yet meet the requested production art standard.

The FIFO queue, round transitions, serialized spawning, health/shields, ammo/reloading, kill attribution and server combat validation are retained. New map/environment hooks are explicit changes. Cosmetics never change combat stats.

## Menus, collection and audio

Deployment, matchmaking, map ballots, operative profiles, weapon previews, inventory, Style Lab, daily cache, settings, loading and results share one responsive interface. The HUD shows vitals, ammo, cooldowns, Aegis charge, players, kills, timer, feed and reality/zone status.

Menus use scrolling content, bounded previews, readable text contrast and local animation. Live screenshot review corrected navigation order and text outlines. An iPhone 17 Pro landscape simulation exercised scrolling, Play and arena navigation without Output errors. Short screens still devote too much space to navigation; the broader interface redesign remains pending.

Three operative profiles and six finishes are cosmetic. Two styles are free claims, Prism is a daily session trial, and Aurum costs 45 earned session credits. Eliminations earn 15 credits and wins earn 45; the daily cache adds 15. Credits, XP, level and collection reset after leaving the server. Only preferences have a production DataStore path; Studio preferences are session-only.

All twenty-nine user-uploaded original audio IDs are integrated. Lobby, map insertion, combat, showdown and win/loss music follow server state. Effects have bounded spatial voices, independent volumes, mute and built-in fallbacks. Both simulated clients loaded all twenty-nine uploads plus six fallbacks; advancing playback and nonzero loudness were observed for live events. Human listening quality and permissions in the intended published universe remain unverified. [SETUP.md](SETUP.md#uploaded-audio) lists every ID and event.

PC: WASD/jump, left click attack, 1/2 weapons, R reload, Q Repulse, G Aegis, C camera, M menu. Touch uses Roblox movement/jump, right-side aiming and combat buttons. Controller: RT attack, LB swap, X reload, Y Repulse, B Aegis, D-pad down camera, D-pad left menu.

## Build and handoff

Keep the local Premium place open for the live workflow in [DEVELOPMENT.md](DEVELOPMENT.md). Do not run the default offline build or package command over this Studio-authored place. Source changes are mirrored after inspecting live scripts; Rojo is one-way toward Studio and cannot export scene edits.

The live local file is `build/MAYHEM-X-Premium.rbxlx`. Original Phase 1, Visual archives and earlier Premium backups remain preserved. Current evidence is in `build/Studio-audio-verification.json` and `build/screenshots/`; the earlier offline package report describes an older build. Module ownership is in [ARCHITECTURE.md](ARCHITECTURE.md), with test limits in [DEVELOPMENT.md](DEVELOPMENT.md) and [CHANGELOG.md](CHANGELOG.md).

Work remains in `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`, the writable workspace. Scripts are relocatable to the requested `C:\MAYHEM-X` after inspecting that destination. Git history uses `.version-control/`; use `scripts/git.ps1`. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`. Nothing was published or pushed, no Robux was spent, and no credentials were accessed.
