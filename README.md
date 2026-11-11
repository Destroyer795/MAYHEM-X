# MAYHEM X

**ENTER THE CHAOS. BECOME THE LEGEND.**

An original Roblox PvP survival game for up to sixteen contenders. Vote for a frontier, fight with the VECTOR-18 and Rift Blade, use Repulse, and survive the closing signal. The premium milestone adds five physical arenas, a daylight hub, brighter menus, combat feedback and an original audio pack.

The source and offline place build are implemented. Structural, geometry and WAV checks pass. Luau compilation, native Rojo validation, Studio import, multiplayer behavior, rendered appearance and device performance remain unverified here. This is a development build awaiting Studio acceptance.

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

Every template has sixteen spawns, four ammo-cache locations, cover, a hazard and a final duel deck. Server integration includes map cleanup, destructible cover, collapsing links, Low Gravity/Shield Drought events, a shrinking safe zone and the defensive Aegis ultimate. These integrations need multiplayer testing.

The FIFO queue, round transitions, serialized spawning, health/shields, ammo/reloading, kill attribution and server combat validation are retained. New map/environment hooks are explicit changes. Cosmetics never change combat stats.

## Menus, collection and audio

Deployment, matchmaking, map ballots, operative profiles, weapon previews, inventory, Style Lab, daily cache, settings, loading and results share one responsive interface. The HUD shows vitals, ammo, cooldowns, Aegis charge, players, kills, timer, feed and reality/zone status.

The acceptance follow-up stacks the portrait showcase above navigation actions, fits HUD panels on narrow screens, strengthens small-text contrast and animates previews/branding/hub rings locally. Failed uploaded effects use available built-in cues; music loads per context with readiness diagnostics. These changes passed structural checks, with rendered and playback review still pending.

Three operative profiles and six finishes are cosmetic. Two styles are free claims, Prism is a daily session trial, and Aurum costs 45 earned session credits. Eliminations earn 15 credits and wins earn 45; the daily cache adds 15. Credits, XP, level and collection reset after leaving the server. Only preferences have a production DataStore path; Studio preferences are session-only.

Built-in sound cues and ambience have source-backed Roblox URIs, with client load diagnostics. Ten original scores/stingers and nineteen effects are in `build/audio/` and the audio ZIP. Music needs the manual upload and experience-permission steps in [SETUP.md](SETUP.md). No numeric asset IDs were invented, and actual playback is unverified.

PC: WASD/jump, left click attack, 1/2 weapons, R reload, Q Repulse, G Aegis, C camera, M menu. Touch uses Roblox movement/jump, right-side aiming and combat buttons. Controller: RT attack, LB swap, X reload, Y Repulse, B Aegis, D-pad down camera, D-pad left menu.

## Build and handoff

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Offline
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

The default output is the Premium place. The Phase 1 place, archived earlier Visual build and previous Premium backup are preserved. The existing Visual working place is left untouched; its current checksum needs manual review because Windows denied read access. The package command produces an audio ZIP, source/history bundle and machine-readable Git/verification report. Native build/setup and live sync are described in [SETUP.md](SETUP.md); module ownership is in [ARCHITECTURE.md](ARCHITECTURE.md); milestones and limitations are in [CHANGELOG.md](CHANGELOG.md).

Work remains in `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`, the writable workspace. Scripts are relocatable to the requested `C:\MAYHEM-X` after inspecting that destination. Git history uses `.version-control/`; use `scripts/git.ps1`. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`. Nothing was published or pushed, no Robux was spent, and no credentials were accessed.
