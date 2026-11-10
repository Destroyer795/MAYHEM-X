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
| `src/shared/Config.luau` | Frozen match, balance, security and simulation settings |
| `src/shared/Protocol.luau` | Remote, action and phase names |
| `src/shared/Rules.luau` | Pure damage, magazine transfer, token bucket, round outcome and transition rules |
| `src/client/Bootstrap.client.luau` | Inputs, snapshot consumption and client controller wiring |
| `src/client/CameraController.luau` | Shoulder/first-person aim, wall collision, mouse, touch, controller and procedural viewmodel |
| `src/client/Hud.luau` | Responsive menu, lobby, combat HUD, results, feed, touch buttons and session settings |
| `src/client/Effects.luau` | Bounded, short-lived client tracers, melee sweeps and pulse visuals |
| `tests/` | Reusable rule assertions, optional CLI runner and explicit Studio checks |
| `scripts/` | Local setup, native/offline build, local serve and verification |

There are no required external asset files. Assets are generated from Roblox parts and built-in materials. UI is built on the client; gameplay geometry and held weapons are built by the server. This phase has no persistence layer or paid content.

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

Clients never submit damage, hit targets, ammo, cooldowns, kills or rewards. Requests share a 24/sec token bucket with a burst of 32. Ready snapshots have an additional one-second limit. Fire rate, ammo, reload state, equipment, switch delay, current character, alive state and match state are enforced on the server. Aim vectors reject non-finite components and invalid magnitudes. Shot origin comes from the server root, then a server raycast determines the hit. Melee and Repulse use server distances and line-of-sight checks.

Horizontal movement uses a server speed budget and a bounded burst allowance. Invalid movement or arena bounds violations roll back to the last accepted transform before combat is accepted. Vertical rise and arena altitude are bounded. This is baseline plausibility checking for client-owned Roblox character physics. It is not complete flight detection, lag compensation or production anticheat; adversarial and latency tests remain required.

The server simulates at 10 Hz and broadcasts personalized state at 2 Hz, with additional targeted state on accepted actions or damage. Clients interpolate timers locally. VFX use at most 100 local parts and short Debris lifetimes, with a reduced-effects option. The only per-frame application work is local camera/viewmodel rendering. No server damage loop runs per frame.

## Future boundaries

Reality events, evolution, stolen powers, ultimates, destructibles, shrinking zones, weapon pickups, the final duel transition, cosmetics, inventory, currency, quests and DataStore saving are deferred until Phase 1 passes Studio multiplayer tests. Duel geometry and four drop-point values exist as map preparation, without active rewards or pickup prompts. Data saving makes no durability promises in this phase; no DataStore API is called.
