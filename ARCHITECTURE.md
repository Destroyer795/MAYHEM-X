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
| `src/server/PresentationService.luau` | Server-owned session cosmetics, claims, purchases and daily guard |
| `src/server/PreferenceService.luau` | Validated preferences, production DataStore saving and derived session profile/wallet |
| `src/server/Equipment.luau` | Original held weapon geometry |
| `src/shared/` | Frozen balance/protocol, pure gameplay/style/map/preference rules, audio config, art tokens and geometry |
| `src/client/Hud.luau`, `Menus.luau` | Combat telemetry, results and functional navigation/collection/settings/ballots |
| `src/client/Theme.luau`, `Preview.luau` | Typography, colors, 8/16/24 spacing tokens, rounded buttons, state/hover feedback and disposable geometry previews |
| `src/client/CameraController.luau` | Both perspectives, input/aim, camera obstruction and cosmetic viewmodel animation |
| `src/client/Effects.luau` | Bounded tracers, Trails, waves, bursts and occluded Highlights |
| `src/client/WorldPresentation.luau` | Map lighting, local orbit/weather, quality controls and nonphysical zone outline |
| `src/client/AudioController.luau` | Preload diagnostics, SoundGroups, spatial effects, ambience and score transitions |
| `assets/maps/*.json`, `scripts/maps.ps1` | Five authored layouts and shared physical-template compiler |
| `assets/audio/scorebook.json`, `scripts/audio.ps1` | Original composition/effect definitions and PCM renderer |
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

Presentation has a separate four/sec, burst-six limiter and allowlisted catalog/fields. Currency is derived from authoritative session Kills/Wins plus daily bonus minus validated spending. Claims and purchases cannot mint duplicates or change stats. Cosmetic parts are massless/noncolliding/nonquery. Player damage credit expires eight seconds after the last actual player hit; environmental ticks do not extend it.

## Persistence and presentation

Only preferences use `MayhemXPreferences_v1`, keyed by player ID. Loads merge allowlisted fields; saves use UpdateAsync every thirty seconds and disconnect/shutdown flushing with revision guards. Failed initial loads prevent writes to unknown saved data. Studio deliberately uses no DataStore. Load/save failure states are visible. Cross-server preference conflicts use last successful writer behavior; no session-lock economy is claimed.

Inventory, daily claim guard, wallet, XP and level are server-session data. Rejoining resets them. Production DataStore operation and failure recovery have not been runtime-tested.

The visual system uses clean light surfaces, blue/cyan accents and gold rewards. A separate darker action blue and muted body color keep twelve intended small-text color pairs above 4.5:1 contrast. Navy panels support HUD contrast. Menus have horizontal navigation, vertical content scrolling, compact map/shop layouts, a stacked portrait showcase and purchase confirmation. Main mode selection honestly presents Last Signal as the available mode. Preferences hydrate from server state and synchronize after a short debounce, with acknowledgement/retry.

AudioConfig owns six built-in URI references, cue tuning, ambience and twenty-nine manual-upload fields. SoundGroups separate Music, Ambience, Effects and UI; preferences control music/ambience, effects, UI and master mute from initialization. One-shot voices are distance/throttle bounded, spatial carriers are nonphysical and voices expire after at most six seconds. Failed uploaded effects use their built-in fallback when available. Music preloads only when its context is selected, with serial guards against late playback after a context change. Settings distinguish configured, loaded and failed music. Score contexts crossfade; Victory/Defeat are stingers. Recent combat can replace a map score without restarting its ambience. Full music depends on verified manual uploads.

## Budgets and remaining boundaries

Templates contain 132 to 286 parts, capped at 500. Hub plus active arena is capped at 720. Only the active map replicates into Workspace; templates remain server-side. Streaming is disabled for these bounded arenas. Effects allow 36 roots, or 12 at reduced quality, four waves per kind, distance culling and timed cleanup. One-shot voices cap at twenty, reserving two slots for UI feedback. Music and ambience loops are separate. Weather stays at nine particles/sec or less, zone outlines use 16/32 segments and at most three nearby hub rings animate.

UI telemetry, map profiles and zone outlines update at 10 Hz. Camera/viewmodel work, one visible menu preview, branding and at most three nearby hub rings animate locally on the render loop. Weather follows the local character there when enabled. The hub caption is cached, and unrelated scene descendants do not reset lighting/weather. Quality/orbit attributes are authored before parenting into the replicated world. Server effects do not use per-frame geometry. Low/Auto quality reduces bloom, secondary rings and particles. Reduced motion stops showcase/orbit/viewmodel motion. These caps are design limits, not measured frame-time results.

Power stealing, evolution paths, grenades, melee combos/finishers, quests, persistent progression/inventory/economy and additional reality events are not implemented. Future cue names do not imply those systems exist. Complete the Studio gate before expanding scope.
