# Development

## Commands and gates

Use Windows PowerShell from the project root. Execution policy changes below apply only to that process.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Audio.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Maps.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Interface.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Preservation.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Presentation.Tests.ps1
```

Primary workflow: list connected Studio sessions, confirm the local Premium filename, inspect the live hierarchy/scripts, back up affected content, make live edits, inspect screenshots, playtest, mirror script changes into source and save locally through Studio. Preserve user scene/Lighting edits. Rojo cannot pull live changes back into files. The default build/package commands overwrite `build/MAYHEM-X-Premium.rbxlx`; do not run them over the live Studio deliverable. A separate source snapshot can be generated with `scripts/build.ps1 -Offline -OutputName MAYHEM-X-SourceSnapshot.rbxlx`, after reviewing generated content. This is not a substitute for the live project. Preserve edited WAVs before regeneration; hash mismatches stop the audio generator.

When portable tools are available, run `scripts/setup.ps1`, `scripts/build.ps1` without Offline, and `scripts/verify.ps1 -RequireTools`. Native Rojo builds generate a sourcemap. `scripts/serve.ps1` generates maps before localhost sync. The offline writer cannot validate the full Roblox API or execute Luau.

`scripts/package.ps1` runs the offline build, normal verification and strict tool gate, compares previous working places with the premium-start archive when readable, creates/verifies the source/history bundle and zips the original audio. `-Native` selects a native Rojo build. Missing tools remain a recorded strict-gate failure; source/build verification failures stop packaging. A changed or unreadable previous working place is preserved and recorded separately in `preservationIssues`, never overwritten or marked matched. Inspect it manually before closing that gate. The previous Premium backup is checked against its recorded checksum. The Git report also records uncommitted changes.

Current live gate: 11,033 server assertions, eighty spawn raycasts, client checks and thirty-five audio loads per client passed. Two clients each passed seventy checks, queued/voted Jungle, exercised real fire/reload/switch/blade/Repulse requests, entered the duel and returned through results to a Frost round. A server-simulated character reset produced win/loss, so this does not establish a combat-earned victory. Music never exceeded two transition voices in the observed scenario. Mute and independent volume propagation passed on both clients. Output contained no game errors after the preload fix. The iPhone 17 Pro landscape simulator exercised scrolling, Play and arena navigation. It uses LandscapeSensor; portrait was not tested. Runtime MayhemHUD uses CoreUISafeInsets and ClipToDeviceSafeArea. Comprehensive safe-area/touch/device acceptance remains pending.

Current static gate: 2,201 map assertions, 203 WAV/upload-mapping assertions, original-method preservation, 73 UI/network/audio wiring checks and twelve text-contrast pairs passed. Earlier 1,811 offline structural assertions describe the prior offline artifact and were not rerun against the Studio-authored file. Portable Luau/Rojo remain unavailable. Running modules in Studio exercises their engine syntax/runtime paths, but full Script Analysis diagnostics remain pending.

Verification covers source/module/config references, remote declarations, UI callbacks/page destinations, XML/source hashes, canonical map properties, five map identities, budgets, rotation matrices, eighty supported spawn locations and body/head clearance, cache/duel support, PCM format/levels/edges and checksums. This does not prove physics, rendering, controls, networking or audio playback.

## Studio acceptance checklist

The smoke tests above have run. The checklist below is the broader acceptance gate, with remaining cases still pending. Use the existing Studio; no publishing is needed. [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes) include Server & Clients, device/controller emulation and network simulation. The MCP audit used actual StudioTestService.ExecuteMultiplayerTestAsync(2) with separate server/client DataModels. Full sixteen-player capacity needs a separate authorized test session.

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
15. The uploaded IDs are listed in SETUP.md. Re-run the audio check after replacements or permission changes. Listen to hub/map/combat/showdown/result transitions, spatial shots/impacts/waterfalls, reload/swap, Repulse/Aegis, shield/death, menus/rewards/purchases and mute. Check Output and configured/ready/failed music counts. Engine playback has been measured, but human listening quality remains pending. Change maps while a score is loading; an old context must not start late. Test an unavailable upload in a disposable copy, simultaneous shooters, UI feedback under the twenty-voice cap and cleanup after swaps.
16. Use phone landscape, tablet, desktop and a short window, including 320-pixel width where supported. The current game is landscape-only; test portrait if that setting is deliberately changed later. Check safe insets, scrolling deployment content, maps/shop/settings/results, non-overlapping vitals/ammo, touch targets, movement/jump clearance, aim dragging and attack release outside its button. Extremely narrow, short layouts hide a feed that cannot fit between panels. Mobile chaos ticker must remain readable. Check smooth previews/rings with reduced motion on/off, and swap cosmetics/weapons during first person. Controller focus must reach every action. Chat focus, Roblox menu, alt-tab and respawn must stop held attack.
17. Use several clients plus latency/jitter simulation. Measure frame time, draw calls, memory, audio voices and remote traffic with High/Low/Auto graphics. Confirm bounds: 720 world parts, 36/12 VFX roots, twenty one-shot audio voices, 16/32 zone segments and bounded weather. Record measurements; design limits do not establish performance.

Record failures with map, phase, client count, device size, exact actions and Output text in CHANGELOG.md. Fix issues and repeat affected checks, then the multiplayer regression gate. `build/Studio-audio-verification.json` records the current observations and limits; `build/screenshots/menu-before.jpg` and `menu-after.jpg` are actual Studio captures. Only Collapse and menu screens have had visual review so far. Multi-view reviews of the other arenas, weapons and all major screens are pending.

## Next production stages

1. Complete the visual audit with multiple live viewpoints of every arena, held weapons and major screen. Preserve before captures. Retain combat silhouettes/routes while replacing repeated primitive scenery with original architectural kits. Check available modelling tools before adding dependencies; record licenses for any imported content.
2. Establish one material/font/icon system, then finish Collapse as the quality reference in Studio. Review daylight balance, focal landmarks, cover readability and low-quality rendering before adapting distinct jungle, desert, ice and city kits. Capture and refine each arena individually.
3. Replace the oversized short-screen menu shell with compact responsive navigation, then review HUD, collection and result screens through actual interactions. Keep the accepted audio routing and existing server combat contracts.
4. Implement versioned persistent account/mastery/mission/cosmetic data with server-owned rewards and failure tests, then competitive systems. Gate production readiness on persistence, combat-earned full matches, all maps, mobile controls, sixteen players and measured performance. These systems are not complete in the current milestone.

## Git and contribution workflow

Use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\git.ps1 status` or another Git command through that wrapper. Metadata is in `.version-control/`, while protected `.git/` is untouched. The feature branch is `feature/premium-worlds-audio`, based on `58429c5`; `premium-baseline-20261111` and the baseline archive preserve that starting point.

Inspect relevant source, change one coherent system, run applicable checks, review the diff, stage named paths and commit with a descriptive message. Do not blindly stage the whole tree. Never discard user changes, rewrite history, force-push, commit local binaries/secrets or push without authorization.

The earlier `build/premium-git-report.json` describes the offline milestone. Current Studio/audio commits and checks are recorded in `build/Studio-audio-verification.json`. Refresh a source/history bundle directly with Git after commits; do not run the packaging command merely to refresh history because it rebuilds over the live place. Original preservation archives remain unchanged.

Use strict Luau, existing modules and server authority. Keep balance in Config and map/event behavior in MapRules or authored map data. Add tests for meaningful rules/security changes, not cosmetic implementation details. No U+2014, filler, fake features, unknown asset IDs, paid dependencies or credential access. Update only the existing five primary documents. Complete this acceptance gate before further gameplay expansion.
