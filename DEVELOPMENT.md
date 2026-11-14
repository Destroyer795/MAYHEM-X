# Development

## Current UI review

The cache/cosmetic update adds three full-surface collections and a Monday-Sunday UTC calendar. Open Collection > Workshop, select a signature finish and switch between all seven weapons. Drag or use Rotate, zoom, and compare stock; buy/equip controls use the existing server catalog. Collection > Daily Cache shows the actual server weekday, all seven rewards and the next Monday reset. The local file clearly identifies unsaved session rewards. Do not advance the system clock to test rewards.

`require(game.ServerScriptService.MayhemTests).cache()` in the Studio server runs focused calendar, mocked-save recovery, migration, entitlement and PBR-structure cases. The final run passed 372 assertions. The mock suite includes failed writes, a response lost after commit, parallel requests, save recovery and session disclosure. It is not a real persistence test.

The opt-in `tests/studio/CacheCosmetics.*.luau` drivers use `ExecuteMultiplayerTestAsync(2, "MayhemCacheCosmetics")`. They require PlaceId 0, explicitly seed nine server eliminations as a purchase fixture, and do not prove match earnings. They inspect actual queue insertion, duplicate daily/purchase requests, ownership, respawn and other-client weapon replication. Map URL getters require Plugin capability, so LocalScripts assert SurfaceAppearance replication and preload the actual assets; the plugin-side SkinCases verifies every map reference. Headless clients without RenderStepped report first-person factory checks separately from live first-person rendering. Remove both drivers before saving; Rojo excludes them.

The final two-client run passed 67 and 63 assertions, with active render loops on both clients. It verified real first-person firearms/melee, held models visible to the other client, purchase/claim duplication rejection and respawn retention. Early harness attempts exposed a Plugin-only property read and a switch request sent during spawn protection; the final drivers use allowed reads and wait for the valid combat window. Both temporary scripts were removed from the saved place.

Final focused local checks: 599 skin/export assertions, 78 interface bindings, twelve contrast pairs, eleven project-model cases and gameplay preservation. All 63 atlas images loaded in one client; a delayed-preload fixture exposed the ten-second Retry state and was cleaned up. Mouse drag and wheel zoom changed real preview state. Keyboard navigation, a calendar claim and receipt dismissal worked in phone emulation. Desktop 1920 x 1080, laptop 1365 x 768, tablet 1375 x 1031 and phone 401 x 777 / 749 x 381 views were inspected. Short screens scroll the calendar body. Native multi-touch/pinch and physical controllers remain unverified. Studio's renderer sometimes stalled at 1 x 1; no successful capture is claimed for those attempts.

Evidence is `build/screenshots/Cache-*.jpg`, `build/Studio-CacheCosmetics-Acceptance-20261114.json` and `build/CacheCosmetics-UI-Acceptance-20261114.json`. The validated source snapshot contains 58 scripts, all 21 skin variants and the Sensor enum token. Native Rojo and Luau CLI checks were unavailable. Twenty-five changed live modules matched filesystem source in the final parity check.

Open `build/MAYHEM-X-Transformation.rbxl`, the live Studio deliverable. Do not overwrite it with an offline build. The Field Operations menu and hangar are implemented in the actual place and mirrored to source.

1. Press F5. Inspect the hangar home, Play, wallet and desktop command rail.
2. Compare all three operator outfits. In Armory, select one of seven weapons, change its handling kit, inspect the model/stat tradeoffs, then equip it. Inventory and Collection preview the selected slot. Ranked/events disclose availability.
3. Use Play to enter the queue, then Leave Queue. Use the home arena link for previews; voting requires queue eligibility.
4. In Studio's device emulator, inspect phone portrait/landscape and tablet layouts. Scroll secondary navigation and long pages. Stop simulation when finished.
5. Open Output from Studio's View menu. Existing generated-texture warnings are listed in SETUP.md. Report project script errors separately.
6. Optional multiplayer check: Test > Server & Clients, two clients, Start. Join in both clients and compare queue/votes. The full economy regression below has already run before this UI pass.

Current evidence: `build/screenshots/FieldOps-*.jpg`, `build/Studio-Arsenal-Acceptance-20261114.json` and `build/FieldOps-UI-Acceptance-20261114.json`. Reviewed the desktop home, all three outfits, armory, melee kit and live hub, plus phone portrait (401 x 778) and landscape (750 x 381). The Play action remains visible in both phone layouts. Desktop Mantis/Quickdraw and Maul/Reach equip actions received real server acknowledgements; scrolling was positioned programmatically when injected wheel input was inconsistent. Physical touch, controller and wide-monitor acceptance remain pending. Earlier Iris/tablet evidence is retained and is not a fresh test of this pass.

The focused arsenal regression passed 94 catalog/preference assertions, 174 server combat-fixture assertions across all 21 weapon/kit combinations, and 15 scenario assertions on each of two simulated clients. Real clients selected different primary/melee kits, entered a round, reloaded, rejected a fire-rate burst and preserved the active loadout after a preference edit. Held firearm and melee models replicated to the other client. The report retains Roblox chat CoreScript initialization errors separately; no MAYHEM script error was reported in the final run. This does not establish human balance, persistent saving or complete combat animation quality.

The opt-in drivers are `tests/studio/ArsenalMultiplayer.server.luau` and `ArsenalMultiplayer.client.luau`. They are excluded from Rojo and removed from the saved place. To rerun only after relevant combat changes, temporarily insert them and call `StudioTestService:ExecuteMultiplayerTestAsync(2, "MayhemArsenalAcceptance")`. They require an unpublished disposable session and stop within 100 seconds. The fixture uses isolated model/table actors, not fabricated Player instances.

The new reward layout was inspected using `build/UI-RewardReviewFixture.luau`, a disposable client-only fixture with the recorded 65-Credit, 2-Token, 1-Shard, 420-XP round payout. It did not award or save anything. Its screenshots are labelled Fixture. The original victory track loaded and visibly moved the rig. The fixture was removed before saving. A fresh full match was not rerun for the UI-only changes.

## Local commands

Run from the repository in Windows PowerShell. Execution policy changes apply only to the child process.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1 -SourceOnly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/Interface.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/Presentation.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/git.ps1 status --short
```

Source validation checks paths, remotes, configuration and preservation contracts. Interface checks cover callback/page wiring, including MenuLayout. Presentation checks cover twelve 4.5:1 text-contrast pairs. These do not establish visual quality or multiplayer behavior. Portable Rojo/Luau tools remain unavailable, so a native build and full Luau analyzer pass are not claimed. Changed modules were executed in Studio.

Use the current Studio MCP session for inspection, edits, playtests and saving. Compare live scripts with source before syncing. Rojo flows from files toward Studio and does not export live scene edits. The generated operator showcase and animation authoring objects remain in the saved place; the operator is not exported into the Rojo art library, so an offline build uses the character fallback.

The default build/package workflow targets the earlier Premium build. Do not run it over the live transformation file. If a separate source snapshot is needed, use `scripts/build.ps1 -Offline -OutputName MAYHEM-X-SourceSnapshot.rbxlx` after reviewing generated content. Preserve original audio files before regeneration. No new tools are needed for UI work.

## Verified multiplayer checkpoint

Before the Iris UI pass, two Studio clients completed a rifle elimination through the real combat remote, voted Jungle, entered the duel, received server-earned rewards, purchased/equipped cosmetics and rejected duplicate purchases. A second-round disconnect returned a valid win without an extra kill or first-win Shard. Both Jungle-to-Frost and Jungle-to-Jungle runs passed, including fresh map generations.

Evidence:
- `build/Studio-two-client-economy-initial-20261113.json`
- `build/Studio-two-client-economy-reset-20261113.json`
- 11,326 server assertions and eighty spawn raycasts.
- Forty-two scenario assertions in the final surviving client.
- All 29 uploaded audio assets and six built-in fallbacks loaded on both clients. Observed music never exceeded two crossfade voices.

These were scripted multiplayer tests, not human input, balance, persistent save/rejoin or sixteen-player performance tests. StudioTestService supports at most eight simulated clients.

To rerun only when gameplay changes require it, temporarily insert the two `tests/studio/EconomyMultiplayer.*.luau` drivers into their server/client services. Launch `StudioTestService:ExecuteMultiplayerTestAsync(2, "MayhemEconomyRegression")` from a yielding MCP Edit task. Drivers reject persistent places, expect new local profiles and finish within 210 seconds. Remove them before saving. They are excluded from Rojo.

## Remaining acceptance

- Persistent save/rejoin, session conflicts, retries and shutdown flush require an authorized published test universe. The current unpublished file reports session-only storage. Do not publish it to bypass this limit.
- Inspect every arena from several viewpoints and traverse routes, bridges, lifts, cover and spawns. Complete first/third-person combat animation review, physics/latency tests and performance measurements.
- Test real touch and controller input, portrait/landscape HUD clearance, camera aiming, scrolling and attack release. Test wide monitors separately.
- Resolve generated texture warnings using verified metadata/permissions or original replacements. The MCP asset:read scope remains unavailable despite the user's grant confirmation.
- Listen to music transitions, spatial effects and accessibility mixes. Local engine loading/playback does not establish permission in the intended published universe.
- Ranked ratings, mastery trees, daily/weekly mission tracking, parties, seasonal events and global leaderboards remain unimplemented. The UI must continue to disclose that status.
- Do not describe the game as production-complete while these gates are open.

## Git and preservation

Use `scripts/git.ps1`, which selects `.version-control/`; do not replace history or write protected `.git/` metadata. Current branch: `feature/studio-production-transformation`. Origin remains `https://github.com/Destroyer795/MAYHEM-X.git`.

Review named diffs, run relevant checks, stage explicit source/document paths and create meaningful commits. Never stage secrets, tools, generated places, temporary fixtures or screenshots blindly. The cache/cosmetic task explicitly prohibits a push without separate authorization. Do not force-push or overwrite remote changes.

Current source backups include `build/backups/Menus-before-iris-redesign.luau`, `Theme-before-iris-redesign.luau`, `Hud-before-reward-layout.luau` and `Preview-before-rig-motion.luau`. Earlier binary/source archives remain intact. Windows denied copying the open transformation binary; no new binary backup is claimed.
