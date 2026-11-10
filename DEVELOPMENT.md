# Development

## Commands

Run from the project root. `-ExecutionPolicy Bypass` applies to the invoked process, not the machine.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -OutputName MAYHEM-X-Visual.rbxlx
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireTools
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\serve.ps1
```

Without downloads, use `scripts/build.ps1 -Offline -OutputName MAYHEM-X-Visual.rbxlx`, then `scripts/verify.ps1` with the same PowerShell prefix. The normal build uses pinned local Rojo and produces a sourcemap. Offline packaging validates mapped paths and emits the supported instance/property types, but cannot check Roblox's full API schema. These commands produce `build/MAYHEM-X-Visual.rbxlx` and a source/hash manifest. The original Phase 1 place remains untouched. Verification reads the manifest's place filename and writes `build/verification.json`, including skipped categories. `-RequireTools` fails when native tools are missing.

Verification checks JSON/tree paths, module references, remote/action name consistency, script classes, PowerShell syntax, the five-document limit, the writing character policy, embedded source integrity and source/build hashes. It executes project-model tests for server/client/module classification, nested sources, missing paths and path-escape rejection, using temporary fixtures inside build/. With tools installed, it also runs Luau compilation, the actual pure rule tests, analysis of engine-independent modules, and Rojo sourcemap generation. Full engine type checks belong in Studio Script Analysis, since the standalone analyzer does not include Roblox engine globals or instance-tree types.

To run only rule tests: `& '.\.tools\luau-0.743\luau.exe' '.\tests\run.luau'`. The shared test cases cover shield damage conservation, magazine/reserve conservation, limiter bursts/refill/backwards time, simultaneous eliminations, timeout draws, transition guards and non-finite input rejection. These are assertions against the actual shared Luau functions, not a separate reimplementation.

VisualCases and StyleCases add catalog/budget checks and allowlisted cosmetic selection, ownership, duplicate request and daily UTC boundary tests. These Luau cases are included but have not executed here. PowerShell checks execute the project-loader cases, compare seven complete gameplay files and the camera aiming function to baseline `9172422`, and resolve menu callbacks, page destinations, VFX handlers and terminal wiring. This does not prove Luau syntax, rendered layout or gameplay behavior.

## Version control

Use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\git.ps1 status` or `... git.ps1 log --oneline`. Git metadata lives in `.version-control/` because this sandbox denies `.git/` writes. No existing history was overwritten. The inspected baseline is commit `9172422`; original files are also archived under `build/backups/`. Review named paths before staging, run relevant checks and `git diff --check`, and make one coherent commit at a time. Nothing was pushed to origin. No remote branch history could be fetched because outbound access is blocked.

The final `build/git-report.json` lists commit hashes, messages, changed files, branch, origin and worktree state. `build/MAYHEM-X-visual.bundle` carries source and local history for offline cloning. See SETUP.md for migration to a normal checkout. Build outputs, local tools, Git metadata and backups are ignored. Keep the local history until it is safely migrated.

## Studio acceptance checklist

These checks are pending. Record results and reproduction details in CHANGELOG.md. Do not mark runtime gameplay verified from the offline build or structural checks.

1. Open `build/MAYHEM-X-Visual.rbxlx` in the existing Studio. Confirm no import warnings. Inspect Script Analysis for every project script and fix errors. Start **Server & Clients** with two clients. Confirm the map, lobby, character spawns and HUD, with no server/client Output errors.
2. In the server simulation's Command Bar, run `require(game.ServerScriptService.MayhemTests).run()`. This explicitly checks actual rules, remotes, anchored map geometry and all 16 insertion pads. It does not simulate combat or prove multiplayer behavior.
3. Queue both clients. Confirm the 15-second intermission, character insertion, frozen five-second countdown, synchronized counters and two-second protection. Attempt shooting and Repulse during countdown/protection; neither damage nor ammo consumption should occur. Remove a queued player during intermission; waiting must resume.
4. Test rifle damage in both perspectives. Shots must stop at cover. Each accepted shot spends one round, magazine capacity is 18, reserve starts at 108, empty weapons cannot fire, reload takes 1.8 seconds, and switching cancels a reload without minting ammunition. Try firing while reloading and rapidly switching weapons. Verify visible hit acknowledgements on actual hits only.
5. Melee must require the blade, an eight-stud maximum range, attack arc, 0.65-second interval and clear line of sight. Repulse must use its 14-stud radius, line of sight and 12-second cooldown, damaging opponents while restoring at most 12 shield up to 40. Verify shield absorption and delayed shield regeneration.
6. Eliminate a client. Confirm exactly one kill and feed entry, accurate alive count, return to the lobby, a single win for the survivor and results for both clients. Continue through three rounds; loadouts must reset, the winner must unfreeze and queue preferences must persist. Falling, Reset Character, unexpected character removal and disconnects must each eliminate once. Two eliminations before outcome resolution must produce a no-survivor result.
7. Disconnect during loading/countdown. The round should cancel safely below two ready players. Rejoin during an active round and confirm lobby-only participation. Force a slow character load or respawn around a round boundary; a late load must not revive an eliminated contender or enter a newer roster. Inspect Output for load failures.
8. In a temporary local test copy, reduce `Config.Match.Duration` to 20 to verify a draw with two survivors, then restore 240. Send malformed Action payloads from a client Command Bar: unknown commands, numeric strings, tables in place of aim, NaN/infinite vectors, Switch(3), and bursts of Fire/Reload/Ability. Confirm no errors, extra damage, rewards or cooldown bypass. Move a client root far away and fire immediately; the server should reject/roll back implausible movement. Restore the original source and rebuild after test edits.
9. Use Device Simulator for a landscape phone and a portrait phone. Confirm health/ammo panels, safe screen insets, movement/jump, camera drag, touch fire hold/release outside the button, reload, swap and Repulse. Test settings, camera changes, menu return and results scrolling. Use Controller Emulator to verify gameplay bindings and menu selection. Test chat focus, the Roblox menu, alt-tab and character respawning while holding attack; firing must stop.
10. Use up to eight local Studio clients, the documented local simulator limit, to test simultaneous combat, queue changes, late joins, feed load and repeated rounds. Use Network Simulator for latency/jitter, and inspect movement rollbacks and aim behavior. Walk every bridge, climb the full tower ascent, enter/leave the lower vault and test cover collision. Measure frame time, network traffic and memory on a lower-end device profile.
11. A full 16-player multiplayer capacity/performance acceptance test needs a separate authorized session beyond the standard eight-client local simulator. No game has been published for that purpose here. Keep that test pending until a permitted test environment is available.

## Visual acceptance additions

In each simulated client, run `require(game.ReplicatedStorage.Mayhem.ClientChecks).run()` from the client Command Bar. This checks UI references, SoundGroups, effect limits and cosmetic physics properties. It does not inspect appearance or operate buttons.

- Walk the orbital hub and use all five ProximityPrompt consoles. Confirm branding, character display, queue/player counts, distinct district silhouettes, bridge paths, tower exit and vault access. Decoration must not obstruct spawns, movement or shots.
- Open every navigation page with mouse, touch and controller. PLAY must queue once; VIEW QUEUE must not leave the queue. Mode briefing must return to Last Signal. Loading, countdown, canceled rounds, victory, defeat and draw results must describe the actual server state. Results must allow opening Collection.
- Preview each operative and both weapons. Equip each starter finish, claim and equip both complimentary shop finishes, claim the Prism session trial, then repeat claims. Confirm styles replicate on other clients, survive respawns within this server and never alter damage, health, speed or ammunition. Unknown/locked selections must fail. Rejoining resets the explicitly session-only collection.
- Test phone portrait, phone landscape, tablet and desktop sizes, including a short window. Scroll menu content/navigation where needed. Check text contrast, 44-pixel collection targets, HUD corners, reticle/raycast alignment, kill feed, mobile movement/jump clearance and gamepad focus. Capture real Studio screenshots for review.
- Fire both weapons into cover and opponents, cast Repulse, break shields and eliminate players. Confirm tracers, muzzle flashes, impacts, Trails, waves, Highlights and damage indicators, without hitbox changes or through-wall outlines. Verify effects disappear and their root count stays within the selected quality cap.
- Switch Auto/High/Low graphics and reduced effects/motion. Check bloom, secondary rings, local orbit animation and sparse particles. Measure frame time, memory, draw calls and network traffic with several clients and a low-end device profile. Design caps alone are not performance verification.
- Check Music, Ambience, Effects and UI SoundGroup volumes in the client. The shipped audio routes are empty and must stay silent without load errors. Before adding audible content, verify license/ownership and update Visuals.Audio plus its permission test. No audio ID was fabricated for this milestone.

Mutation, ultimate and destruction renderers are not live gameplay. Their future integration, persistent cosmetics and audible licensed content remain outside this milestone. Do not enable Phase 2 until the above gate and the original combat/multiplayer checklist pass.

Studio's current multi-client procedure is documented in [Roblox testing modes](https://create.roblox.com/docs/studio/testing-modes). No checklist item has been executed in Studio from this sandbox.

## Conventions

Keep balance values in Config and protocol names in Protocol. Server modules own outcomes, cooldowns, damage and rewards. Client changes may improve input or presentation but may not grant authority. Keep phase changes explicit and cleanup paths idempotent. Use strict Luau, small modules and useful tests for state/security changes. Never include the Unicode character U+2014 in files or UI. Inspect files before editing. Do not introduce external asset IDs, paid dependencies, global installs, automatic publishing or credential access.

Update the five primary documents when behavior changes. Keep current test status honest, including blocked or skipped checks. The next milestone begins only after Phase 1's Studio acceptance gate passes.
