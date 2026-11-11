# Changelog

## Premium acceptance follow-up

- Backed up the accepted source and Premium place at `09d6b8a` before further edits. Original Phase 1 and Visual places remain preserved.
- Failed uploaded effects now select available built-in fallbacks. Music loads per context, late preload completions cannot restart an obsolete score, initial group volumes honor preferences, and two of twenty one-shot voices are reserved for UI feedback. Music diagnostics distinguish configured, ready and failed assets.
- Added pure audio routing cases for fallback selection, unavailable assets, tuning, unknown cues and group classification. Execution still requires Luau or Studio.
- Portrait deployment now stacks the showcase, map link, profile and actions in scrollable content. HUD vitals/ammo share available width on narrow screens, status lines stay inside the screen, short landscape kill feeds fit between panels, and reload/swap touch targets are 44 pixels high. Rendered device acceptance remains pending.
- Menu/showcase cameras, branding and bounded nearby hub rings now animate on the client render loop; telemetry stays at 10 Hz. Cached hub caption lookup, one zone-distance calculation per update and selective art invalidation reduce repeated work. Quality/orbit attributes are set before world parenting, and map generations refresh local art caches. Reduced effects clears existing weather promptly.
- Added a darker action-blue token and stronger muted text. Button text and small menu labels now use readable colors on light surfaces. Twelve intended text color pairs have an executable 4.5:1 contrast gate; rendered legibility still requires device review.
- Desktop inventory now works, but the Studio launch attempt timed out at app approval. The node helper failed to start, and portable tool setup could not connect to the remote server. Studio runtime acceptance remains pending.

## 2026-11-11: Premium milestone, Studio acceptance pending

### Implemented

- Five original physical arenas from independent authored JSON layouts and one reusable compiler: The Collapse, Neon Jungle, Solar Wasteland, Frostbite and Skyline Zero. Each has sixteen spawns, four ammo-cache locations, traversal/cover, a hazard and final duel geometry.
- Daylight editor preview and hub, restrained per-map lighting, light UI surfaces, blue/cyan/violet identity and warm gold accents. Added district machinery, nineteen jungle palms, desert strata/glyphs, snow/crystals, city facades/skyscraper silhouettes, route signs and a live hub queue panel.
- Eligible FIFO map ballots, uniform random ties/no-vote selection, round-to-map assignment, safe template swaps and cleanup. Added server hazards, moving-platform carry, collapsible links, destructible cover, ammo caches, shrinking zones, Low Gravity/Shield Drought and final-two duel transfer/zone.
- Server-authoritative Aegis, charged by credited eliminations. Existing rifle, blade, Repulse, damage/ammo tuning, sixteen-player FIFO roster, serialized spawning and round state machine retained with explicit environmental integration hooks.
- Main deployment, matchmaking, five geometry previews/ballots, mode briefing, operative profiles, collection/weapon previews, cosmetic shop with confirmation, daily cache, audio/graphics/camera settings, loading/countdown, combat HUD and victory/defeat/draw results.
- HUD charge/cooldowns, map/zone/reality status, touch ultimate and mobile announcements. Bounded combat effects, accepted-shot/reload viewmodel motion, showcase/victory pose, reduced motion and graphics settings.
- Session-only earned credits, XP/level and six cosmetic finishes. Purchases/claims and daily bonus are server-validated and idempotent. No paid advantage, purchase API or Robux transaction.
- Validated preference hydration, debounced acknowledgements and production DataStore save path. Failed initial loads block writes, and disconnect/shutdown waits for pending save work. Studio remains session-only; inventory/economy/progression are not persisted.
- Centralized audible built-in cues/ambience with source-backed URIs, preload diagnostics, spatial voices/waterfalls, independent volumes, mute, cleanup and music-context crossfades.
- At the user's request, ten original scores/stingers and nineteen synthesized effects prepared for manual upload. Stereo 44.1 kHz PCM files have level/edge/header/hash checks and a route manifest. Music upload IDs remain empty.
- Offline Premium place, original audio ZIP, complete Git bundle and machine-readable verification/storage/commit report. No new installed dependency.

### Executed verification

| Check | Result |
| --- | --- |
| Offline build | Succeeded, 36 mapped Luau sources plus physical templates/editor preview |
| Normal verification | 1,808 structural checks passed, zero failed, three categories skipped |
| Generated geometry | 2,201 assertions passed; five maps, all eighty spawns supported/clear, cache/duel support, matrices, budgets and hashes |
| Original WAVs | 174 format/level/edge/checksum/route assertions passed for 29 files |
| Loader and interface | Ten loader assertions and 72 callback/navigation/network/audio checks passed |
| Preservation | Five complete Phase 1 files, fourteen methods and camera aiming preserved against 9172422 |
| Strict required-tools gate | Failed because portable Luau and Rojo are unavailable; recorded separately |
| Git bundle / old builds | Packaging verifies bundle integrity and compares both earlier places to the premium-start archive |
| Studio / listening / devices | Not executed; installed Studio is running, but native control pipe and browser host are unavailable |

The final report has exact artifact hashes, file sizes and worktree state. Structural counts overlap subgroup checks. No test result above establishes Roblox runtime correctness.

Review corrected biased tie selection, stopped vote spam broadcasts, continued duel zone damage after transfer, protected failed preference loads, fixed a reload configuration reference and emitted canonical serialized part properties. Broader actual gameplay bugs remain unknown until Studio testing.

### Git milestones

Baseline: `58429c5`. Branch: `feature/premium-worlds-audio`. The source and two previous place files were archived in `build/backups/premium-start-58429c5.zip` before changes. All commits are local; nothing was pushed.

| Commit | Change |
| --- | --- |
| a9bce17 | Reusable physical templates and Collapse |
| 5f5a7b9 | Neon Jungle |
| 2909c0f | Solar Wasteland |
| 8fff2e4 | Frostbite and lower-route exits |
| 7e51a6d | Skyline Zero |
| a2fef45 | Map voting, round assignment and arena systems |
| 3a424cf | Validated preferences and earned session cosmetics |
| b0dc978 | Original audio pack and audible fallback routes |
| d0a7e6b | Bright navigation, ballots and combat telemetry |
| 893b89f | Arena landmarks, facade detail and daylight hub |
| 11ba347 | Balanced ballots, spawn and duel validation |
| 272a949 | Preference save protection and spatial contexts |
| 754f7dd | Canonical Roblox XML export fields |
| 5b3d710 | 44.1 kHz score mastering and smooth edges |
| 2973f73 | Touch targets, weapon feedback and audio transitions |
| b2bfb17 | Daylight editor preview |
| 0e9d6b9 | Controller confirmation focus and protection label |
| e695e5f | Command/effect/audio replacement wiring checks |
| 4f2b8e7 | Modal input refresh and compact combat labels |

Each code milestone ran its available offline/static checks and diff review before committing. Luau/native/Studio checks remained explicitly pending. The final documentation/package commit, full commit messages and changed-file inventory are included in `build/premium-git-report.json`.

### Known limitations and next steps

The project has not passed Studio import, Script Analysis, multiplayer, actual UI rendering, movement/physics, asset loading, listening or device/performance acceptance. Follow DEVELOPMENT.md with two clients, then up to eight local clients; separately schedule an authorized sixteen-player test. Do not mark the milestone production-ready until that gate passes.

Upload the original WAVs manually and set AudioConfig fields only after moderation and experience permission checks. Built-in cue paths have source evidence but current-client playback is unverified. No full music plays with empty Uploads fields.

DataStore saving is implemented for preferences only and is untested in production. Session inventory, currency, daily guard and progression reset on reconnect. Cross-server preference conflicts use last successful writer behavior.

Evolution paths, stolen powers, grenades, combos/finishers, quests, persistent economy/inventory/progression and additional reality mutations remain outside this implementation. PowerSteal is only an unused audio route. Procedural geometry/previews and viewmodel motion do not imply custom uploaded character animations.

## 2026-11-11: Earlier visual milestone

The previous visual build added the original orbital hub, single Collapse presentation, responsive menus/HUD, session cosmetics and bounded VFX. Its offline build and 267 structural checks passed, with native/Studio tests pending and audio routes empty. It is preserved as `build/MAYHEM-X-Visual.rbxlx`, with its source/history in the earlier visual bundle.

Earlier commits: 9172422 (inspected Phase 1 baseline), ce64018 (local Git/artifact isolation), 2806dae (lobby/arena art), 39f641b (cosmetics/previews), 7bf98bc (menus/HUD), 12f2d52 (VFX), 58b4565 (reticle/idempotency), 578eaf0 (small-screen tuning), 58429c5 (acceptance/handoff documentation).

Git metadata uses `.version-control/` because protected `.git/` writes are denied. Origin remains `https://github.com/Destroyer795/MAYHEM-X.git`. No remote history was fetched and no existing commits were rewritten.

## 2026-11-11: Original Phase 1 baseline

Implemented the procedural Collapse/lobby, FIFO queue, sixteen-slot roster, two-player minimum, round state machine, serialized character loading, countdown/protection, server rifle/melee/Repulse, health/shields, finite ammo/reloads, kills, results and disconnect cleanup. Initial offline packaging and structural checks passed. Runtime gameplay was not verified here. The original `build/MAYHEM-X.rbxlx` and `build/backups/phase1-source-baseline.zip` remain preserved.
