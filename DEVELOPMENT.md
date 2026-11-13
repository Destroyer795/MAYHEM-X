# Development

## Current UI review

Open `build/MAYHEM-X-Transformation.rbxl`, the live Studio deliverable. Do not overwrite it with an offline build. The Iris menu is implemented in the actual place and mirrored to source.

1. Press F5. Inspect the operator home, Play, wallet and top navigation.
2. Check Operators, Armory > Loadout/Upgrades, Collection > Daily Cache, Career > Profile/Missions/Leaderboards, and Settings. Ranked/events disclose availability.
3. Use Play to enter the queue, then Leave Queue. Use the home arena link for previews; voting requires queue eligibility.
4. In Studio's device emulator, inspect phone portrait/landscape and tablet layouts. Scroll secondary navigation and long pages. Stop simulation when finished.
5. Open Output from Studio's View menu. Existing generated-texture warnings are listed in SETUP.md. Report project script errors separately.
6. Optional multiplayer check: Test > Server & Clients, two clients, Start. Join in both clients and compare queue/votes. The full economy regression below has already run before this UI pass.

Live UI evidence: `build/screenshots/Iris-*.png`. Desktop queue entry/cancellation, profile navigation, music-volume cycling and grouped destinations passed. Client reference checks passed 68 assertions. Desktop 1365 x 768, phone portrait 401 x 778, phone landscape 750 x 381 and tablet 1179 x 819 were rendered. Phone input injection was inconsistent; screenshots establish layout only. Wide-monitor, physical touch and controller acceptance remain pending.

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

Review named diffs, run relevant checks, stage explicit source/document paths and create meaningful commits. Never stage secrets, tools, generated places, temporary fixtures or screenshots blindly. The user authorized a normal push for this UI milestone. Do not force-push or overwrite remote changes. GitHub was unreachable over port 443 during this session; use normal Git authentication if required later.

Current source backups include `build/backups/Menus-before-iris-redesign.luau`, `Theme-before-iris-redesign.luau`, `Hud-before-reward-layout.luau` and `Preview-before-rig-motion.luau`. Earlier binary/source archives remain intact. Windows denied copying the open transformation binary; no new binary backup is claimed.
