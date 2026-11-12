# Architecture

## Source ownership

| Location | Responsibility |
| --- | --- |
| `default.project.json` | Rojo tree, four gameplay remotes, Presentation remote, shared modules, tests, map templates and daylight editor preview |
| `src/server/MatchService.luau` | FIFO queue, sixteen-slot rounds, serialized spawning, lifecycle, attribution and results |
| `src/server/CombatService.luau` | Server movement checks, weapons, ammo, health/shields, Repulse and Aegis |
| `src/server/MapService.luau` | Voting, active template, spawn assignment, hazards, cover, movers, zone and duel |
| `src/server/ArenaService.luau` | Preserved Phase 1 procedural builder/lobby spawn transforms |
| `src/server/SceneService.luau` | Daylight hub, original signs/showcase/consoles and baseline lighting |
| `src/server/PresentationService.luau` | Server-owned appearance, catalog claims, purchases, daily rewards and profile notices |
| `src/server/PreferenceService.luau` | Versioned account profile, allowlisted preferences, credits, persistent cosmetics and guarded saves |
| `src/server/Equipment.luau` | Original held weapon geometry |
| `src/shared/Art.luau`, `MapArt.luau` | Nonphysical original mesh placement, equipment/outfits, map dressing and lighting profiles |
| `src/shared/Environment.luau` | Owned Terrain surroundings, horizon composition and bounded map-to-map cleanup |
| `src/shared/` | Frozen balance/protocol, pure gameplay/style/map/preference rules, audio config, art tokens and geometry |
| `src/shared/ProfileRules.luau` | Profile defaults, schema migration and catalog validation |
| `src/client/Hud.luau`, `Menus.luau` | Combat telemetry, results and functional navigation/collection/settings/ballots |
| `src/client/Theme.luau`, `Preview.luau` | Typography, colors, 8/16/24 spacing tokens, rounded buttons, state/hover feedback and disposable previews, including the optional live operator showcase |
| `src/client/CameraController.luau` | Both perspectives, input/aim, camera obstruction and cosmetic viewmodel animation |
| `src/client/Effects.luau` | Bounded tracers, Trails, waves, bursts and occluded Highlights |
| `src/client/WorldPresentation.luau` | Map lighting, local orbit/weather, quality controls and nonphysical zone outline |
| `src/client/AudioController.luau` | Preload diagnostics, SoundGroups, spatial effects, ambience and score transitions |
| `assets/maps/*.json`, `scripts/maps.ps1` | Five authored layouts and shared physical-template compiler |
| `assets/audio/scorebook.json`, `scripts/audio.ps1` | Original composition/effect definitions and PCM renderer |
| `assets/art/manifest.json`, `Library.rbxmx`, `scripts/art.ps1` | Thirteen original Studio-generated models, returned asset references and reproducible source export |
| `tests/`, `scripts/` | Structural/geometry/WAV checks, Luau cases, Studio helpers, local setup/build/package |

Five complete baseline files, fourteen original gameplay methods and the camera aiming function are checked against `9172422`. Match/map integration, damage attribution and environmental hit hooks are reviewed changes. Startup runs the preserved arena builder, removes its superseded arena/duel geometry, decorates the hub and clones one premium map. The editor preview is removed by that startup builder.

## Maps and lifecycle

`Waiting -> Intermission -> Loading -> Countdown -> Active -> Results -> Waiting`.

The first sixteen opt-in FIFO entries enter a round; overflow keeps its order. Loading workers retain round/character serial guards. Intermission cancels below two queued players. Loading/countdown cancel safely below two ready survivors. Eliminations are idempotent. Late joins remain in the hub; eliminated players respawn there. Results return participants to the queue according to their opt-in preference. Multiple survivors at timeout draw.

Map JSON defines palette, lighting, landmarks, spawns, cache locations and geometry commands. Shared compiler operations build floors, grids, stairs, spirals, sloped bridges, palms, crystals and rings. Generated files are `build/generated/Maps/*.rbxmx`, `MapCatalog.luau` and hash/budget metadata. Catalog previews derive from physical geometry with bounded detail. Serialized fields follow [Rojo's reflection patches](https://github.com/rojo-rbx/rbx-dom/blob/master/patches/parts.yml) and [XML RGB encoding](https://github.com/rojo-rbx/rbx-dom/blob/master/rbx_xml/src/types/colors.rs).

Templates live in ServerStorage. Each has Solid, Decor, Destructibles, Collapse, Motion, Hazards, Ice and Duel groups, sixteen spawn CFrames, four cache CFrames and two duel CFrames. Runtime adds nonphysical signs and cache prompts. Only one active map is parented under `Workspace.MayhemWorld.ActiveArena`. Swaps disconnect prompts, destroy old geometry, reset gravity/state and invalidate delayed callbacks by generation.

Votes count only from the upcoming FIFO roster during Waiting/Intermission. A player has one changeable ballot. Repeated votes are ignored and changes are throttled. Highest count wins; ties use a uniform random draw. No-vote rounds choose a different map where possible. Loading selects and validates the map before changing the roster; failure preserves queue order.

Environment simulation shares the existing 10 Hz tick. Movers use authored travel/period metadata and adjust accepted character positions only for server-observed riders. Cover has 76 health, disappears at zero and restores after twenty seconds when clear. Collapse links warn for three seconds before a ten-second outage. Pulsed map hazards deal server damage. Caches grant eighteen reserve rounds, capped at 108, with distance/state validation and a 24-second respawn.

The circular zone starts at radius 185, shrinks after 45 seconds toward 24, and deals nine damage per second outside. Low Gravity and Shield Drought alternate every 38 seconds for nine seconds. Gravity is global while that event runs. With two survivors, the server transfers them to the isolated duel deck after the configured delay (60 seconds for two-player rounds, otherwise 12). Duel protection lasts two seconds; its zone shrinks from 31 to 8 after a ten-second grace.

Aegis gains 34 charge per credited elimination, capped at 100. Activation spends a full charge, restores shields, heals at most thirty health and grants 1.25 seconds of symmetric protection. Server state, movement, life and protection checks apply. Clients cannot grant charge or damage.

## Networking and trust

| Remote | Contract |
| --- | --- |
| Action, client to server | Original Ready, Queue(boolean), Switch(1/2), Fire/Melee(unit Vector3), Reload, Ability, plus Vote(mapId) and Ultimate |
| State, server to client | Phase/time, queue/ballot eligibility, map/generation/votes/zone/chaos/duel, participation, vitals/loadout/charge, kills, survivors and results |
| Effect, server to clients | Accepted Shot/Slash/Pulse/Ultimate/Destruction; Notice; private attacker hit acknowledgement |
| Feed, server to clients | Server-attributed elimination names/cause |
| Presentation, bidirectional | Request, Select, Claim, Daily, Purchase and Preferences; owned styles, revision, profile/settings/save status and feedback reply |

Original gameplay requests share the 24/sec, burst-32 limiter. Aim components/magnitudes, server origins/raycasts, fire rate, ammo, reloads, slot, switch delay, match phase, life, range and line of sight are validated. Movement has a speed budget, bounded rise/altitude and map-dependent bounds. Invalid movement rolls back before an attack is accepted. This is baseline plausibility checking, not complete flight detection or lag compensation.

Presentation has a separate four/sec, burst-six limiter and allowlisted catalog/fields. Server-recorded eliminations and wins award credits and XP. Cosmetic purchases and the daily reward are applied as single profile mutations. Claims cannot mint duplicates or change combat stats. Cosmetic parts are massless/noncolliding/nonquery. Player damage credit expires eight seconds after the last actual player hit; environmental ticks do not extend it.

## Persistence and presentation

`PreferenceService` stores schema version 2 profiles in `MayhemXProfiles_v2`, keyed by player ID. It migrates the prior `MayhemXPreferences_v1` preference record without deleting the original. Preferences, Kills, Wins, earned credits, selected cosmetics, owned cosmetics and the daily claim day are validated and saved together. A separate 120-second per-player lease prevents concurrent servers from overwriting an active profile. Saves renew the lease, retry transient operations, run every thirty seconds, and flush on leave/shutdown. Newer schema data and failed loads are never overwritten. Studio uses separate `MayhemXStudio*` stores.

DataStore behavior requires a published place, Studio API access, and the appropriate runtime permissions. The current local place is unpublished. Studio therefore uses its explicit `SESSION ONLY / DATASTORE UNAVAILABLE` fallback; the DataStore read/write probe was refused by Roblox with “You must publish this place to the web to access DataStore.” No publishing was performed. Profile sanitization and migration rules pass Studio tests, but real save/rejoin, lease contention and production failure recovery remain unverified. XP/level are derived from persisted Kills and Wins. Mastery, missions, ranked seasons and broader achievement progression remain unimplemented.

The UI uses dark navy surfaces, violet actions, cyan selection marks and gold rewards. Oswald headings, Builder Sans body text and Roboto Mono telemetry form the type system. Twelve actual Theme color pairs pass 4.5:1 contrast. Menus use a desktop rail or scrolling mobile navigation, vertical content scrolling, fitted original-model viewports and purchase confirmation. Account XP/level and leaderboards reflect profile stats when storage is available, and show a session fallback in an unpublished Studio file. Mastery, missions and seasonal rank state remain unavailable. UIStroke uses Border mode so it does not outline text. UI and SoundService objects are created at runtime, so empty StarterGui/SoundService in Edit mode is expected. Main mode selection presents Last Signal as the available mode. Preferences hydrate from server state and synchronize after a short debounce, with acknowledgement/retry.

AudioConfig owns six built-in URI references, cue tuning, ambience, twenty-nine uploaded IDs and pure music-context selection. SETUP.md maps every ID to its caller. SoundGroups separate Music, Ambience, Effects and UI; preferences control music/ambience, effects, UI and master mute from initialization. One-shot voices are distance/throttle bounded, spatial carriers are nonphysical and voices expire after at most six seconds. Pending/failed uploaded effects use an available built-in fallback. Preloading passes silent Sound instances to ContentProvider and checks IsLoaded before destroying the probes. Music preloads on context selection, with serial guards against late playback. Crossfades retain at most the current score and one fading predecessor. Loading/countdown use the selected map score, accepted nearby combat changes context, duel takes priority, and results select participant win/loss stingers. Round changes clear combat timing. Map generation invalidates ambience. Settings distinguish configured, loaded and failed assets. Local Studio playback is tested; published-universe permission grants remain unverified.

Live scene edits belong to the open local Studio DataModel. Script changes are inspected, backed up, edited through MCP and mirrored in source. Rojo sync is toward Studio, not a scene export. The generated operator showcase is live at `ReplicatedStorage.Mayhem.Art.OperatorShowcase` and is consumed by `Preview.luau` when present. Its model is not included in `assets/art/Library.rbxmx`, so source-only builds retain the player-character preview fallback. Do not rebuild or sync over live scene changes without reviewing what would be replaced. Earlier offline XML/hash reports do not describe a subsequent Studio save.

## Budgets and remaining boundaries

Templates contain 132 to 286 parts, capped at 500. Hub plus active arena is capped at 720. Only the active map replicates into Workspace; templates remain server-side. Streaming is disabled for these bounded arenas. Effects allow 36 roots, or 12 at reduced quality, four waves per kind, distance culling and timed cleanup. One-shot voices cap at twenty, reserving two slots for UI feedback. Music and ambience loops are separate. Weather stays at nine particles/sec or less, zone outlines use 16/32 segments and at most three nearby hub rings animate.

UI telemetry, map profiles and zone outlines update at 10 Hz. Camera/viewmodel work, one visible menu preview, branding and at most three nearby hub rings animate locally on the render loop. Weather follows the local character there when enabled. The hub caption is cached, and unrelated scene descendants do not reset lighting/weather. Quality/orbit attributes are authored before parenting into the replicated world. Server effects do not use per-frame geometry. Low/Auto quality reduces bloom, secondary rings and particles. Reduced motion stops showcase/orbit/viewmodel motion. These caps are design limits, not measured frame-time results.

Power stealing, evolution paths, grenades, melee combos/finishers, quests, weapon/ability mastery, ranked seasons and additional reality events are not implemented. Broader achievements and missions are not persisted. The v2 profile currently covers settings, account eliminations/wins, credits and cosmetics. Future cue names do not imply those systems exist. Complete the Studio gate before expanding scope.

Environment generation is separate from combat geometry. Background Terrain stays outside the safe/playable routes, or below the fall-death threshold. It records every owned clearing volume on Terrain; subsequent map loads clear those volumes and refuse unreviewed pre-existing Terrain. Clouds, atmospheric profiles and ambient particles change by map. Only the active environment is present. Initial texture fetch warnings and terrain rendering delay remain under review; generation caps are not performance measurements.
