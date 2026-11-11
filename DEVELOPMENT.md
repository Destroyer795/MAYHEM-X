# Development

## Commands and gates

Use Windows PowerShell from the project root. Execution policy changes below apply only to that process.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Offline
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

The build regenerates maps and original WAVs, then packages `build/MAYHEM-X-Premium.rbxlx` with a source/hash manifest. It preserves the older place filenames. Source JSON, not generated XML/WAVs, is authoritative. Do not edit generated map templates. Preserve manually edited audio before rebuilding; the audio generator stops on hash mismatches.

When portable tools are available, run `scripts/setup.ps1`, `scripts/build.ps1` without Offline, and `scripts/verify.ps1 -RequireTools`. Native Rojo builds generate a sourcemap. `scripts/serve.ps1` generates maps before localhost sync. The offline writer cannot validate the full Roblox API or execute Luau.

`scripts/package.ps1` runs the offline build, normal verification and strict tool gate, compares previous working places with the premium-start archive when readable, creates/verifies the source/history bundle and zips the original audio. `-Native` selects a native Rojo build. Missing tools remain a recorded strict-gate failure; source/build verification failures stop packaging. A changed or unreadable previous working place is preserved and recorded separately in `preservationIssues`, never overwritten or marked matched. Inspect it manually before closing that gate. The previous Premium backup is checked against its recorded checksum. The Git report also records uncommitted changes.

Current executed checks: 1,811 structural checks, 2,201 physical-map assertions, 174 WAV assertions, ten project-loader assertions, original-method preservation, 73 UI/network/audio wiring checks and twelve text-contrast pairs. Counts describe separate groups and overlap. The normal pass has zero failures and three skipped categories. Native Rojo, Luau compilation/rule execution and Studio acceptance are pending. The added audio routing cases are prepared but have not executed.

Verification covers source/module/config references, remote declarations, UI callbacks/page destinations, XML/source hashes, canonical map properties, five map identities, budgets, rotation matrices, eighty supported spawn locations and body/head clearance, cache/duel support, PCM format/levels/edges and checksums. This does not prove physics, rendering, controls, networking or audio playback.

## Studio acceptance checklist

All steps below are pending. Use the existing Studio; no publishing is needed. The current [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes) include **Server & Clients**, device/controller emulation and network simulation. Start with two clients, then use up to eight local clients. Full sixteen-player capacity needs a separate authorized test session.

1. Open `build/MAYHEM-X-Premium.rbxlx`. Confirm the daylight editor preview imports with correct dimensions/colors and no warnings. Inspect Script Analysis for every project script. Start Server & Clients with two clients and inspect both server and client Output.
2. From the server Command Bar, run:
   ```lua
   require(game.ServerScriptService.MayhemTests).run()
   require(game.ServerScriptService.MayhemTests).maps()
   ```
   The first executes actual rule cases and structure checks. The second temporarily clones all five templates away from the arena, raycasts all eighty spawns and removes its clones. Neither test operates gameplay.
3. From each client Command Bar, run:
   ```lua
   require(game.ReplicatedStorage.Mayhem.ClientChecks).run()
   require(game.ReplicatedStorage.Mayhem.ClientChecks).audio()
   ```
   These check UI references, nonphysical effects, SoundGroups and actual asset preloads. Listen separately; successful fetches alone do not prove sound quality.
4. In both clients, PLAY must queue once. VIEW QUEUE must keep the queue intact. Check the FIFO count, fifteen-second intermission, frozen five-second countdown, sixteen distinct spawn assignments and two-second symmetric insertion protection. Fewer than two queued/ready players must cancel safely. Repeated queue requests must not jump FIFO order.
5. Preview and vote for each of the five maps across successive rounds. Confirm synchronized counts, one changeable ballot per eligible player, locked ballots after insertion, random ties and no-vote fallback. On each swap, only one ActiveArena should exist, old prompt connections/effects should clear and gravity should reset. Overflow/late joiners remain in the hub.
6. Walk every route, including the Collapse spiral exit/vault, Jungle lookout/lower passages, Solar valley escape stairs/gallery/skiff, Frost crossbridges/fortress and Skyline roofs/service deck/both lifts. Check headroom, bridge joins, spawn clearance, cover lines and fall deaths. Check per-map lighting from both the hub and arena.
7. Test the rifle in both cameras: cover blocks shots, each accepted shot spends one round, magazine 18, reserve 108, 1.8-second reload, no fire while reloading, and swapping cancels reload without creating ammo. Check accepted-shot recoil/reload animation and reticle/raycast alignment.
8. Test Rift Blade slot/range/arc/line of sight and 0.65-second interval. Repulse must use server range/line of sight and twelve-second cooldown. Check shield absorption, delayed regeneration, private hit acknowledgement and exactly one credited kill/feed entry.
9. Leave both players alive long enough to see the zone and chaos. Outside-zone damage must match the visible boundary. Low Gravity must restore normal gravity; Shield Drought must suppress regeneration. Check pulsed hazards, collapse warnings/outages, destructible cover restoration and ammo caches, including duplicate prompt requests and full reserves.
10. With at least five contenders, earn three eliminations, activate Aegis and verify charge consumption, capped heal/shield restoration and symmetric protection. Client Ultimate spam must not bypass charge, life, position or phase checks. With two survivors, test duel transfer, protection, shrinking duel zone and final results.
11. Confirm one win, accurate standings, victory/defeat/draw feedback, lobby return and queue preference over repeated rounds. Test deaths, Reset Character, simultaneous eliminations, unexpected character removal, disconnect during loading/countdown/active/results and late character loads. Old callbacks must not revive players or duplicate rewards.
12. In a disposable local test copy, shorten match duration to exercise timeout draws, then restore source. Send unknown commands, invalid Switch values, malformed/NaN/infinite aim, invalid map IDs and request bursts. Move a client far beyond bounds before attacking; server validation must reject/roll back. No client-reported damage, kills or credits should be accepted.
13. Open every menu using mouse, touch and controller. Test operative/weapon previews, starter styles, free claims, daily duplicates/UTC reset, Aurum purchase cancellation, insufficient funds and duplicate purchases. Compare other clients' cosmetic replication and unchanged combat stats. Rejoining must reset the clearly labeled session collection/wallet/XP.
14. Test all camera, FOV, quality, effects, motion, music, effects volume, UI volume and mute controls. Test rapid changes and menu closing while preference acknowledgement is delayed. Studio must say session-only. Production load/save, failed-load protection, shutdown flush and cross-server preference behavior require a later authorized experience test; do not publish to perform it here.
15. After the manual uploads in SETUP.md, run the audio check again. Listen to hub/map/combat/showdown/result transitions, spatial shots/impacts/waterfalls, reload/swap, Repulse/Aegis, shield/death, menus/rewards/purchases and mute. Check Output and configured/ready/failed music counts. Change maps while a score is loading; the previous context must not start late. Where an approved test asset is unavailable, its effect must use its built-in fallback. Test simultaneous shooters, UI feedback under the twenty-voice cap and cleanup after swaps.
16. Use phone portrait/landscape, tablet, desktop and a short window, including 320-pixel width. Check safe insets, stacked deployment content, scrollable maps/shop/settings/results, non-overlapping vitals/ammo, touch targets, movement/jump clearance, aim dragging and attack release outside its button. Extremely narrow, short layouts hide a feed that cannot fit between panels. Mobile chaos ticker must remain readable. Check smooth previews/rings with reduced motion on/off, and swap cosmetics/weapons during first person. Controller focus must reach every action. Chat focus, Roblox menu, alt-tab and respawn must stop held attack.
17. Use several clients plus latency/jitter simulation. Measure frame time, draw calls, memory, audio voices and remote traffic with High/Low/Auto graphics. Confirm bounds: 720 world parts, 36/12 VFX roots, twenty one-shot audio voices, 16/32 zone segments and bounded weather. Record measurements; design limits do not establish performance.

Record failures with map, phase, client count, device size, exact actions and Output text in CHANGELOG.md. Fix issues and repeat only the affected checks, then the multiplayer regression gate. Appearance needs actual Studio screenshots and human visual review; no rendered review was possible in this environment.

## Git and contribution workflow

Use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\git.ps1 status` or another Git command through that wrapper. Metadata is in `.version-control/`, while protected `.git/` is untouched. The feature branch is `feature/premium-worlds-audio`, based on `58429c5`; `premium-baseline-20261111` and the baseline archive preserve that starting point.

Inspect relevant source, change one coherent system, run applicable checks, review the diff, stage named paths and commit with a descriptive message. Do not blindly stage the whole tree. Never discard user changes, rewrite history, force-push, commit local binaries/secrets or push without authorization.

`build/premium-git-report.json` contains all milestone hashes/messages/changed paths, checks, storage, artifact hashes and remaining worktree changes. `build/MAYHEM-X-premium.bundle` carries source/history for a normal local clone. Original place/archive checksum comparisons are recorded during packaging. Re-run packaging after the final commit to refresh bundle/report HEAD.

Use strict Luau, existing modules and server authority. Keep balance in Config and map/event behavior in MapRules or authored map data. Add tests for meaningful rules/security changes, not cosmetic implementation details. No U+2014, filler, fake features, unknown asset IDs, paid dependencies or credential access. Update only the existing five primary documents. Complete this acceptance gate before further gameplay expansion.
