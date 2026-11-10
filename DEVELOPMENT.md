# Development

## Commands

Run from the project root. `-ExecutionPolicy Bypass` applies to the invoked process, not the machine.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireTools
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\serve.ps1
```

Without downloads, use `scripts/build.ps1 -Offline`, then `scripts/verify.ps1` with the same PowerShell prefix. The normal build uses pinned local Rojo and produces a sourcemap. Offline packaging validates mapped paths and emits the supported instance/property types, but cannot check Roblox's full API schema. Both produce `build/MAYHEM-X.rbxlx` and a source/hash manifest. Verification writes `build/verification.json`, including skipped categories. `-RequireTools` fails when native tools are missing.

Verification checks JSON/tree paths, module references, remote/action name consistency, script classes, PowerShell syntax, the five-document limit, the writing character policy, embedded source integrity and source/build hashes. It executes project-model tests for server/client/module classification, nested sources, missing paths and path-escape rejection, using temporary fixtures inside build/. With tools installed, it also runs Luau compilation, the actual pure rule tests, analysis of engine-independent modules, and Rojo sourcemap generation. Full engine type checks belong in Studio Script Analysis, since the standalone analyzer does not include Roblox engine globals or instance-tree types.

To run only rule tests: `& '.\.tools\luau-0.743\luau.exe' '.\tests\run.luau'`. The shared test cases cover shield damage conservation, magazine/reserve conservation, limiter bursts/refill/backwards time, simultaneous eliminations, timeout draws, transition guards and non-finite input rejection. These are assertions against the actual shared Luau functions, not a separate reimplementation.

## Studio acceptance checklist

These checks are pending. Record results and reproduction details in CHANGELOG.md. Do not mark runtime gameplay verified from the offline build or structural checks.

1. Open `build/MAYHEM-X.rbxlx` in the existing Studio. Confirm no import warnings. Inspect Script Analysis for every project script and fix errors. Start **Server & Clients** with two clients. Confirm the map, lobby, character spawns and HUD, with no server/client Output errors.
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

Studio's current multi-client procedure is documented in [Roblox testing modes](https://create.roblox.com/docs/studio/testing-modes). No checklist item has been executed in Studio from this sandbox.

## Conventions

Keep balance values in Config and protocol names in Protocol. Server modules own outcomes, cooldowns, damage and rewards. Client changes may improve input or presentation but may not grant authority. Keep phase changes explicit and cleanup paths idempotent. Use strict Luau, small modules and useful tests for state/security changes. Never include the Unicode character U+2014 in files or UI. Inspect files before editing. Do not introduce external asset IDs, paid dependencies, global installs, automatic publishing or credential access.

Update the five primary documents when behavior changes. Keep current test status honest, including blocked or skipped checks. The next milestone begins only after Phase 1's Studio acceptance gate passes.
