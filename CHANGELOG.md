# Changelog

## 2026-11-11: Premium worlds and audio, in development

Created branch `feature/premium-worlds-audio` from `58429c5`, tagged the baseline and archived 50 source/build files under `build/backups/premium-start-58429c5.zip`. Added a dependency-free authored map compiler that emits physical Roblox XML templates and a shared catalog. The new Collapse template includes sixteen supported insertion points, four weapon locations, a tower/vault layout, destructible cover, an outer collapse bridge, hazards and duel geometry. Map round assignment is the next integration step. The existing builds are preserved. Available checks passed; Studio physics and native Luau/Rojo checks remain pending.

All five physical templates now package. Round integration adds eligible-player voting with randomized ties, map cleanup/cloning, per-map spawn assignment, shrinking safe zones, pulsed map hazards, Low Gravity/Shield Drought chaos, moving-platform carry, destructible cover, ammo caches and a final two-survivor deck. Aegis is a server-authoritative defensive ultimate charged by three credited eliminations. Original weapon damage/ammo/cooldown tuning, FIFO selection, character loading and Repulse are preserved. Preservation checks now protect five complete baseline files, fourteen unchanged methods and camera aiming; match/map integration and environmental hit hooks are explicit reviewed changes. Runtime verification is still pending.

At the user's request, original music is prepared for manual Roblox upload. A deterministic PowerShell/.NET synthesizer produces ten original scores/stingers and nineteen effects, with PCM/header/level/hash tests. The central AudioConfig records each replacement field and verified built-in URI references from Roblox's Core-Scripts. Built-in SFX and ambience are configured; experience-specific playback remains untested. Music Upload fields deliberately stay empty until the original files are uploaded and permitted. The controller reports preload failures, caps voices, supports spatial effects, crossfades music and separates music/effects/UI volumes. No numeric audio IDs were invented.

## 2026-11-11: Visual implementation, Studio acceptance pending

### Implemented

- Navy, purple, cyan and magenta art direction; orbital lobby canopy, large branding, operative display and five 3D menu consoles.
- District-specific machinery, reactor housings, spawn beacons, bridge conduits, restrained bloom, atmospheric haze, local orbit animation and sparse built-in particles.
- Deployment, live matchmaking, mode briefing, operative and weapon previews, inventory, complimentary Style Lab, daily session cache, settings, insertion/countdown and victory/defeat/draw screens.
- Responsive HUD gauges, reload and Repulse clocks, weapon slots, eliminations, alive count, timer, hit/damage feedback and readable inactive ultimate/chaos status. Small-screen menu content scrolls, collection targets are 44 pixels high and gamepad navigation has explicit focus.
- Separate, rate-limited session cosmetics: three signal-plate profiles, two starter finishes, two free shop claims and a daily Prism trial. Selections/claims are server-validated and do not change stats. They are not saved after leaving.
- Bounded Beam tracers, muzzle flashes, sparkle impacts, sword Trails, Repulse segments, occluded shield Highlights and elimination effects. Mutation/ultimate/destruction renderers have no live gameplay triggers.
- Functional Music/Ambience/Effects/UI SoundGroups and playback routes. No licensed sound IDs are configured, so the build is silent.
- Auto/High/Low graphics, reduced effects/motion and camera/FOV/audio controls. World decoration has a 720-part runtime cap, VFX have 36 full-quality or 12 reduced roots, waves have per-kind caps and cleanup uses Debris. These caps are not measured performance results.

### Preservation and Git

The initial project was inspected, backed up to `build/backups/phase1-source-baseline.zip` with 33 entries and recorded in commit `9172422`. Seven complete gameplay files remain byte-for-byte unchanged: MatchService, CombatService, ArenaService, Config, Rules, Protocol and the original RulesCases. The camera aiming function is also unchanged. Art runs after the original arena generator, without moving combat geometry. Cosmetic parts and arena decorations are excluded from combat raycasts.

Local history uses `.version-control/`, because the sandbox allowed initialization but denied subsequent `.git/` writes. Use `scripts/git.ps1`. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`. No remote history could be fetched, and nothing was pushed. No existing commits were amended or replaced. The final file inventory and all hashes/messages are in `build/git-report.json`; `build/MAYHEM-X-visual.bundle` provides offline history migration.

| Commit | Milestone | Executed verification |
| --- | --- | --- |
| `9172422` | Inspected Phase 1 baseline | 179 structural checks, ten loader assertions |
| `ce64018` | Local Git wrapper and artifact isolation | 181 structural checks |
| `2806dae` | Lobby/arena art and lighting | 206 checks, gameplay preservation |
| `39f641b` | Session cosmetics and 3D preview components | 237 checks, gameplay preservation |
| `7bf98bc` | Connected menus, HUD, graphics and audio routing | 262 checks, 34 interface checks |
| `12f2d52` | Combat VFX and shield feedback | 262 checks, 37 interface checks |
| `58b4565` | Reticle alignment, idempotency and client test module | 267 checks, preserved camera aim |
| `578eaf0` | Small-screen controls and automatic effect quality | 267 checks, preservation and wiring |

The final documentation/acceptance commit follows these milestones and is included in the generated Git report. Each code milestone was reviewed with a Git diff and available checks before committing. Runtime verification was explicitly pending in the commits.

### Executed checks and limits

Commands use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`:

- `scripts/build.ps1 -Offline -OutputName MAYHEM-X-Visual.rbxlx`: succeeded, packaging 27 mapped Luau sources. The original `MAYHEM-X.rbxlx` was preserved.
- `scripts/verify.ps1`: 267 checks passed, zero failed, three categories skipped. Executed subgroups include ten project-loader assertions, source/aim preservation, Git wrapper validation and 37 interface/wiring checks. XML source round-tripping, checksums, module paths, remotes, PowerShell syntax and the character policy passed.
- Native build and `scripts/verify.ps1 -RequireTools`: blocked/failing because portable Rojo and Luau are unavailable. The required-tools report is saved separately under build/. No tool dependencies were installed.
- Git origin inspection through `ls-remote`: network connection failed. Local origin configuration and commit history were checked successfully.
- Server/client Studio test modules are included, but neither ran here. The computer/browser automation host is unavailable, and the existing Studio executable returned access denied. Luau compilation, pure Luau test execution and Rojo-native validation were not performed.

Known runtime bugs remain unknown until Studio testing. Actual lighting, traversal, avatar load timing, menu layout, mobile/controller input, multiplayer HUD synchronization, cosmetic replication, VFX cleanup and frame-time/network budgets require the acceptance checklist in DEVELOPMENT.md. Design caps and static checks do not verify runtime performance.

The project remains in the supplied workspace because `C:\MAYHEM-X` is outside the writable sandbox. A normal checkout can be cloned from the bundle when the destination is available; see SETUP.md.

## 2026-11-11: Original Phase 1 baseline

Implemented the procedural Collapse map, lobby and FIFO queue, 16-slot roster, two-player minimum, round state machine, serialized character loading, countdown/protection, server rifle/melee/Repulse, health/shields, finite ammunition/reloading, kills, results and disconnect cleanup. Offline packaging and structural checks passed. Studio gameplay was not verified from this environment.

Reality events, evolution, stolen powers, ultimates, destructibles, collapsing structures, shrinking zones, weapon drops, final-duel transitions, grenades, combos/finishers, extra maps, persistent progression/cosmetics, currency, quests and DataStore saving remain unimplemented. The inactive duel deck/drop markers are map preparation. No Phase 2 gameplay was enabled during the visual milestone. Complete Studio visual and multiplayer acceptance before proceeding.
