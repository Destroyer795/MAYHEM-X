# Architecture

## Files and ownership

| Path | Responsibility |
| --- | --- |
| `default.project.json` | Authoritative Rojo instance tree, service properties, shared modules, four remotes and Studio test module |
| `src/server/Bootstrap.server.luau` | Manual character lifecycle, server startup, player connections, 10 Hz simulation |
| `src/server/MatchService.luau` | FIFO queue, 16-slot roster, phase transitions, serialized spawn requests, eliminations, session stats and results |
| `src/server/CombatService.luau` | Server loadouts, movement plausibility, shots, raycasts, melee, shield absorption/regen, reloads and Repulse |
| `src/server/ArenaService.luau` | Anchored procedural lobby, four zones, central tower, bridges, vault, future drop markers and isolated duel deck |
| `src/server/Equipment.luau` | Original weapon geometry attached to R6/R15 hands |
| `src/server/SceneService.luau` | Additive art direction, lobby consoles, non-colliding arena decoration and lighting |
| `src/server/PresentationService.luau` | Session cosmetics, entitlement validation, daily UTC guard, signal plates and a separate request limiter |
| `src/shared/Config.luau` | Frozen match, balance, security and simulation settings |
| `src/shared/Protocol.luau` | Remote, action and phase names |
| `src/shared/Rules.luau` | Pure damage, magazine transfer, token bucket, round outcome and transition rules |
| `src/shared/Visuals.luau` | Art tokens, style/operative catalog, feature availability, VFX budgets and empty licensed-audio routes |
| `src/shared/StyleRules.luau` | Pure selection, ownership, duplicate-claim and daily-session rules |
| `src/shared/Geometry.luau` | Shared original signs, segmented rings, decorative parts and operative figures |
| `src/client/Bootstrap.client.luau` | Inputs, snapshot consumption and client controller wiring |
| `src/client/CameraController.luau` | Shoulder/first-person aim, wall collision, mouse, touch, controller and procedural viewmodel |
| `src/client/Hud.luau` | Combat gauges, slots, feed, hit/damage feedback, insertion and results |
| `src/client/Menus.luau` | Deployment, matchmaking, mode briefing, operative/weapon selection, inventory, shop, daily and settings navigation |
| `src/client/Theme.luau`, `Preview.luau` | Shared UI components and disposable ViewportFrame WorldModels |
| `src/client/WorldPresentation.luau` | Client orbit animation, sparse particles and graphics quality |
| `src/client/AudioController.luau` | Music/ambience/UI/effects routing and licensed-asset playback infrastructure |
| `src/client/Effects.luau` | Bounded Beams, Trails, particle bursts, waves and occluded Highlights |
| `tests/` | Reusable rule assertions, optional CLI runner and explicit Studio checks |
| `scripts/` | Local setup, native/offline build, local serve and verification |

There are no required external asset files. Assets are generated from Roblox parts and built-in materials. Sparkles use Roblox's built-in texture URI. UI is built on the client; gameplay geometry and held weapons are built by the server. This phase has no persistence layer or paid content. SceneService runs after ArenaService without moving the original collision geometry. Seven original gameplay files and the camera aiming function are checked against commit `9172422`.

## Match lifecycle

`Waiting -> Intermission -> Loading -> Countdown -> Active -> Results -> Waiting`.

Intermission cancels if fewer than two players remain queued. Loading and countdown may transition to canceled results when fewer than two characters are ready. Loading has an 18-second deadline. A monotonically increasing round ID and per-player spawn serial prevent old loads from activating a player in a newer round. One loading worker per player processes the latest requested spawn. Delayed death/respawn callbacks check their player entry, spawn serial or round ID.

Selected players leave the queue, preserving their opt-in preference. Overflow players keep their FIFO order. Participants rejoin the back of the queue after results. Late joins remain in the lobby. Characters are anchored during insertion/countdown and released for the round. Both incoming damage and outgoing attacks are blocked during the two-second insertion shield. Eliminated players return to the lobby and cannot attack. Session Kills/Wins reset when leaving the server.

Elimination is idempotent per roster entry. Death, unexpected character removal, falling below the arena and disconnects share this path. Kills use server damage attribution, with an eight-second credit window for subsequent void deaths or disconnects. Outcome resolution runs after the simulation's combat/death processing. Zero survivors and multi-survivor timeouts award no win. A single survivor at timeout wins. Results can be entered only once, preventing duplicate wins.

## Network contract

All events live in `ReplicatedStorage.Mayhem.Remotes`.

| Remote | Direction | Contract |
| --- | --- | --- |
| `Action` | Client to server | `(command, payload)`; Ready, Queue(boolean), Switch(1 or 2), Fire(unit Vector3), Melee(unit Vector3), Reload, Ability |
| `State` | Server to one client | Phase/time, queue, local participation, alive count, kills, authoritative loadout/vitals/cooldown snapshot and optional results |
| `Effect` | Server to clients | Accepted Shot/Slash/Pulse visuals; Hit acknowledgement only to the attacker |
| `Feed` | Server to clients | Server-attributed elimination names and cause |

The separate `ReplicatedStorage.Mayhem.Presentation` RemoteEvent handles Request, Select({kind, id}), Claim(styleId) and Daily. Its server-owned catalog/records cannot change combat stats or rewards. A four-request/sec, six-burst limiter bounds requests. Duplicate selections and claims do not rebuild cosmetics or mint rewards. The reply contains owned finishes, selected profile/finish, revision, daily status, next UTC reset and feedback. Daily access is guarded per player and UTC day within this server, with no persistence across reconnects. Player attributes replicate the selected style; signal plates and weapon glow are massless and excluded from collision/raycasts.

Clients never submit damage, hit targets, ammo, cooldowns, kills or rewards. Requests share a 24/sec token bucket with a burst of 32. Ready snapshots have an additional one-second limit. Fire rate, ammo, reload state, equipment, switch delay, current character, alive state and match state are enforced on the server. Aim vectors reject non-finite components and invalid magnitudes. Shot origin comes from the server root, then a server raycast determines the hit. Melee and Repulse use server distances and line-of-sight checks.

Horizontal movement uses a server speed budget and a bounded burst allowance. Invalid movement or arena bounds violations roll back to the last accepted transform before combat is accepted. Vertical rise and arena altitude are bounded. This is baseline plausibility checking for client-owned Roblox character physics. It is not complete flight detection, lag compensation or production anticheat; adversarial and latency tests remain required.

The server simulates at 10 Hz and broadcasts personalized state at 2 Hz, with additional targeted state on accepted actions or damage. Clients interpolate timers locally. World decoration has a 720-part runtime ceiling. VFX are limited to 36 root objects, or 12 on reduced graphics; a root may own bounded particles or wave segments. Heavy waves are limited to four of each kind. Debris handles expiration, effects are excluded from traces and distant effects are culled. These are design caps, not measured performance results.

UI/graphics updates run at 10 Hz. At most three nearby rings animate locally. Low quality hides secondary ring segments, stops orbit animation and ambient particles, reduces haze and disables bloom. Original collision geometry stays visible. Viewport WorldModels are destroyed when leaving their page. The only per-frame application work remains local camera/viewmodel rendering. No new server per-frame work or VFX broadcasts were added. Damage and elimination feedback derive from existing snapshots/events and replicated character deaths.

## Future boundaries

Reality events, evolution, stolen powers, ultimates, destructibles, shrinking zones, weapon pickups and the final duel transition remain deferred. Mutation/ultimate/destruction VFX renderers have no live gameplay trigger. Duel geometry and four drop-point values remain inactive map preparation. Persistent inventory/progression, currency, quests, paid shop content and DataStore saving are not implemented. The current collection is session-only. No DataStore or purchase API is called. Phase 2 remains blocked on Studio acceptance of the visual milestone.
