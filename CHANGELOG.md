# Changelog

## 2026-11-11: Phase 1 source and offline build

### Implemented

- Original procedural floating arena: reactor tower with an open stair exit, four combat districts, eight bridges, cover, sixteen insertion pads, lower secret vault, observation lobby, four future drop markers and isolated future duel deck.
- Manual character loading with serialized requests, per-player spawn serials, loading timeout, late-load guards, death/character-removal cleanup and disconnect handling.
- Opt-in FIFO queue, 16-player round roster, two-player minimum, intermission cancellation, countdown, spawn protection, four-minute rounds, last-survivor wins, no-survivor draws, timeout draws, results and automatic requeue preference.
- Server raycast rifle, finite magazine/reserve, reload and switch cooldown, server melee arc/distance/visibility, Repulse radius/visibility/cooldown, health, shield absorption and regeneration.
- Request rate limiting, finite aim-vector checks, server-derived hit origins, movement/bounds plausibility checks, single elimination credit and session Kills/Wins.
- Original menu, lobby card, HUD, health/shield bars, ammunition, ability cooldown, elimination feed, results, settings, custom first/third-person aim, procedural weapon/viewmodel visuals, mouse/touch/controller gameplay bindings and reduced VFX.
- Rojo mapping, version/checksum lock, relocatable Windows scripts, dependency-free offline place packaging, source/hash manifests, structural checks and executable Luau/Studio test cases.

### Verification status

Initial environment inspection and official release/documentation lookup were performed. Tool download attempts failed because shell network access is blocked. Studio's existing shortcut was located, but access to its target executable was denied; native computer/browser automation was also unavailable. No Studio multiplayer tests, full Roblox type checks, Luau CLI tests or Rojo-native builds have run in this session.

Offline packaging and structural verification results are recorded in `build/manifest.json` and `build/verification.json`. Read those reports for the latest executed check counts. Skipped checks remain explicit. The place's sources are not a claim of runtime acceptance.

Executed commands (each script was invoked with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File`):

- `scripts/build.ps1 -Offline`: succeeded, packaging 14 mapped Luau sources in an openable place XML format. Import in Studio remains unverified.
- `scripts/verify.ps1`: 179 structural checks passed, zero failed, three tool/runtime categories skipped. This includes an executed project-model test group with ten assertions.
- `scripts/setup.ps1 -RojoOnly`: failed to reach GitHub; nothing installed.
- `scripts/build.ps1`: correctly refused the native build because local Rojo is missing.
- `scripts/verify.ps1 -RequireTools`: the same structural checks passed, but the required-tools gate failed because the portable tools are missing. Its report is preserved as `build/verification-required-tools.json`.

Review fixes included the spiral stair exit's overhead clearance, viewmodel pivot placement, non-finite movement handling, initial client module waits, gamepad menu selection and touch attack release. These changes have source/structure checks only, pending Studio verification.

### Known limitations and remaining work

- Phase 1 is implemented in source but has not passed the mandatory Studio gameplay gate. There are no confirmed runtime test results. Camera feel, touch/controller UI, tower/vault traversal, character load timing, collisions and latency behavior need acceptance testing.
- Movement validation is baseline checking for client-owned physics. Sustained flight and sophisticated cheating are not fully prevented. There is no rewind/lag compensation. Production security and 16-player performance are unverified.
- Match duration ends in a draw when multiple contenders survive; there is no Phase 2 shrinking zone or showdown transition yet. The separate duel deck and weapon spawn markers have no active gameplay flow.
- Melee currently has one strike, without combos or finishers. Grenades, additional weapons, alternate powers, ultimate abilities, chaos events, evolution, power stealing, destructibles and collapsing structures are deferred.
- Only The Collapse is playable. Inventory, cosmetics, currency, quests, persistent progression, DataStore saves, persistent leaderboards, advanced matchmaking and audio are not implemented. No fake inventory, currency or ultimate UI is presented. Settings and leaderboard values last only for the current client/server session.
- Project files remain in the supplied writable workspace; creating `C:\MAYHEM-X` is outside this sandbox. No project tool dependencies were installed. The portable setup script is ready for a network-enabled local session.

Next: open the generated place in existing Studio, complete Script Analysis and the two-client checklist in DEVELOPMENT.md, fix observed issues, then broaden to eight local clients and an authorized 16-player session. Do not start Phase 2 until the playable prototype is verified.
