# Changelog

## 2026-11-13: Iris menu composition and animated rewards

- Replaced the side rail with six primary sections and contextual navigation. Added a graphite/slate, ivory and iris design system, operator-led home composition, native typography, real three-currency wallet and discovery links.
- Recomposed operators, loadout, armory, workshop, queue, profile and settings. Settings use labelled value rows. Upgrades connect to existing cosmetic actions; ranked, mastery and event availability remains explicit.
- Added portrait stacking, horizontal navigation/finish selectors, tablet layouts, safe-area coverage and scrolling short-screen content. Removed clipped scenery from narrow operator previews.
- Fixed the anchored showcase rig, added the original victory animation, skippable payout counters and an XP reveal. Rewards still come from server results. No combat/economy/network contracts changed in this UI milestone.
- Desktop queue/cancel, grouped navigation and volume controls passed. Studio client checks passed 68 assertions. Reviewed desktop, phone portrait, tablet and phone-landscape result captures. Reward screenshots use a labelled visual fixture with recorded payouts, not a new combat match. Physical touch/controller, ultrawide and complete visual acceptance remain pending.
- Saved the live Transformation place. A separate binary copy was denied; source backups and earlier binary backups remain intact. No new dependencies. Existing generated texture warnings and unpublished-place persistence limits remain unresolved.
- GitHub could not be reached over port 443. The authorized push must not be reported as successful without confirmation.

## 2026-11-13: Combat-earned economy regression and fresh round state

- Fixed same-map rounds retaining duel bounds, destroyed cover and cache state. Each new round now creates a fresh arena; ending a round clears duel and safe-zone state. The lobby HUD no longer labels intermission as a final showdown.
- Added opt-in Studio-only multiplayer drivers under `tests/studio/`. Two real clients voted, reloaded, rejected nonfinite aim and rapid-fire spam, reached the duel and completed a rifle elimination through the existing combat remote. No health, kills or rewards were injected.
- Both Jungle-to-Frost and Jungle-to-Jungle runs passed. The winner earned 80 match/kill Credits, two Tokens and the first-win Shard, bought/equipped cosmetics and rejected duplicate purchases. A second-round disconnect awarded a win without a duplicate kill or first-win Shard. Each client loaded all 29 uploads and six fallbacks; observed music never exceeded two crossfade voices.
- Source validation passed 344 checks. Studio passed 11,326 server assertions and 80 spawn raycasts. The same-map survivor completed 42 scenario assertions. This is scripted multiplayer regression, not physical input, balance or persistence acceptance. Generated texture warnings and a Roblox CoreScripts chat initialization error remain open.

## 2026-11-13: Crisp native menus and focused collection workshop

- Replaced full-screen CanvasGroup composition with native Frames and pixel-snapped page motion. Applied charcoal, cyan and amber styling with measured text contrast and a restrained gamepad focus outline.
- Added Collection to navigation. Replaced five repeated weapon cards with one item stage, a responsive finish list, selected-item reveal, ownership/prices, rotate, rifle/blade preview, purchase and equip controls. Locked inventory finishes route to the correct selected item.
- Fixed portrait operator rendering by refreshing preview cameras after target-size changes. One camera remains after resize. Page opening resets scrolling after layout; safe-area background coverage no longer exposes world scenery around the menu.
- Reviewed actual laptop, phone portrait and phone landscape screenshots. Desktop controls and insufficient-funds confirmation passed. Portrait-to-landscape resizing retained visible controls and selection. Mobile input injection did not activate navigation, so touch/controller acceptance is still pending. This does not complete the full UI or production phase.
- Saved the live local transformation place and screenshot evidence. No dependencies, publishing or remote Git operations were added. Texture metadata investigation remains blocked by the current MCP token reporting `asset:read` as ungranted despite the user's settings confirmation.

## 2026-11-13: Add deterministic three-currency cosmetic economy

- Added profile schema V3 currencies, a bounded transaction ledger, first-win shard tracking, idempotent active-match rewards and fixed cosmetic prices. Kept combat balance settings unchanged in their protected module.
- Active match completion now awards Credits and Season Tokens from server state. Eliminations award Credits through server-maintained kill stats. Queue entry waits for profile load; purchase remotes validate catalog entries and balances on the server.
- Added Voidglass (1 Chaos Shard) and Solstice (6 Season Tokens), expanded Style Lab to five catalog cards, displayed all balances and recent transaction deltas, and added each player's payout summary to match results.
- Fixed session release to write an expired lease instead of cancelling the update. Profile readiness now waits for stat hydration. Match payouts and their ledger deltas are one transaction function, including currency-cap handling. Purchase/reward audio receives an explicit success cue.
- The Studio harness passed 11,326 server assertions, eighty spawn raycasts and fifty-two client checks. Source validation passed 340 checks. A real client free claim, confirmation, 45-Credit purchase, duplicate remote rejection and server-side equip passed. Credits for that purchase came from three server-simulated eliminations in the unpublished local session.
- Studio screenshots exposed repetitive shop cards and soft menu rendering, which remain a visual follow-up. Ten generated texture IDs failed to resolve in the latest Output. Persistence, two-client economy testing, mastery, missions, broader collectibles and Prestige remain unfinished.

## 2026-11-13: Remove unavailable skyline texture

- Studio Output identified unavailable generated texture `rbxassetid://117318376313062` on `SkySpire.windows_geom`.
- Removed that texture reference from the art manifest and exported library, applied a source blue-cyan mesh tint, and updated `Art.place` to preserve original color when a MeshPart has no texture. The art exporter and structural test now explicitly support that intentional case.
- In the next live Play run, the DataModel had zero references to the unavailable texture and Studio Output showed only the normal local-place message. The screenshot request stalled, so no post-fix capture was produced.

## 2026-11-13: Animated operator preview

- Generated the operator idle animation in the live Studio session and configured the returned asset `rbxassetid://128214294905072` in `AnimationConfig.luau`.
- Preview viewports now load one looped idle track and explicitly stop/destroy it when switching or hiding previews. No animation placeholders or guessed IDs were added.
- Verified on the live Studio client: the loaded track duration was 7.9667 seconds, six rig bones had active transforms, the deployment and operator pages each held one active track, and switching pages left zero tracks on the hidden preview. Output showed the normal local-place notice and no animation errors.
- This is a local operator showcase animation only. It does not implement or verify first-person, third-person, or melee combat animations. Permission for a future published universe remains unchecked.

## 2026-11-13: Live operator showcase refinement

- Connected the Studio-generated R15 operator model in `ReplicatedStorage.Mayhem.Art.OperatorShowcase` to menu and character previews, retaining the existing player-character fallback when the model is absent.
- Added a restrained framed stage to the operator page, enlarged the compact-height preview without overlapping the selection controls, and placed the display pedestal from the model's actual bounds to remove the visible foot gap.
- Inspected the deployment screen and operator page in the live Studio client. Clicked Operators and Spectre and confirmed the selected state changes. The model is in a static A-pose and is not final character-selection animation content. The generated rig is not included in the Rojo art library, so the source export does not reproduce this showcase.
- Studio Output showed the normal local-place notice and no script errors during this visual check. Full-screen navigation, mobile, animation and multiplayer checks remain pending.

## Versioned account profile and Studio fallback

- Replaced the preferences-only service with a version 2 server profile for allowlisted settings, cumulative kills and wins, earned credits, cosmetic ownership/equipment and the daily claim day. Account XP and level derive from the persisted server stats.
- Added a one-time migration read from the prior production preferences store, catalog and numeric validation, a per-player 120-second server lease, thirty-second saves, bounded retries, and leave/shutdown flushes. Store names in Studio use a separate prefix. Purchases and daily rewards update the profile atomically.
- Added profile migration, ownership, atomic purchase and one-time daily reward cases to the Studio rule suite. The live server passed 11,287 structure/rules assertions and 80 actual spawn raycasts. MAYHEM X booted without a script error and its menu displayed the expected session-only fallback.
- Roblox refused DataStore calls for this unpublished local place with `You must publish this place to the web to access DataStore.` The user enabled Studio API access and data scopes, but no publishing was performed. Real read/write/rejoin and lease tests remain unverified.
- A fresh StudioTestService two-client launch did not enter Play mode and remained pending. Profile changes have single-client server verification; a current two-client profile interaction test remains open.
- Moved the delayed 476-descendant generated avatar out of Workspace into `ServerStorage.ArtDrafts` to avoid replicating an unused model. It has not been visually accepted or wired to character previews.
- Current live menu screenshot shows the presentation still needs substantial work, including the block-shaped character and incomplete environmental composition. This profile milestone does not accept the overall visual gate.

## Map transition race and UI fixes, visual gate in progress

- Fixed a server tick reentry discovered in a real two-client Studio test. Terrain generation yields during map loading, which had allowed additional Intermission ticks to start conflicting selections. Match startup and Results reset now have guards, while MapService serializes loads, avoids duplicate same-map builds, and releases its guard after errors.
- Repeated a two-client session through two consecutive rounds. The first active map was Skyline, the second was voted Solar after a server-simulated elimination. Both rounds had exactly one ActiveArena whose model matched the server ActiveMap attribute. MapGeneration advanced once per round, from two to three, and remained stable after ten seconds. This verifies transition sequencing, not a combat-earned win or five-map visual acceptance.
- Both clients passed 68 client checks and 35 audio asset loads after the fix. Server output contained no MAYHEM X script errors; original mesh asset requests still log content-representation warnings.
- The standalone map suite passed 2,207 assertions, including six new source regression checks for load serialization, idempotency, error unlock and MatchService reentry guards.
- Saved live Studio images at `build/screenshots/skyline-zero-live-post-lock.jpg` and `build/screenshots/solar-wasteland-live.jpg`. The flat Solar combat floor and block-shaped player remain clear visual defects.
- Studio saved `build/MAYHEM-X-Transformation.rbxl`. Static source and match changes are included in this checkpoint.

## Compact UI fixes and Studio review, visual gate in progress

- Reconnected to the correct saved Studio place and restored live screenshot capture. A separate full-screen menu backdrop now covers the Roblox safe-inset strip without moving menu controls under the Roblox top bar. Its height follows the current inset.
- Replaced the operator base outfit's mottled Fabric shading with SmoothPlastic while retaining the existing armor and helmet meshes.
- Short matchmaking pages now keep LEAVE QUEUE and VIEW HUB visible. The queue timer yields space on short viewports. In Studio, PLAY opened matchmaking, LEAVE QUEUE returned the display to READY TO QUEUE with zero queued players, and the edited output reported no game errors.
- Saved fresh live screenshots at `build/screenshots/main-menu-ui-refined.jpg` and `build/screenshots/matchmaking-ui-refined.jpg`. The current 678 x 521 viewport was reviewed. The character remains visibly block-shaped, and the map and other-screen visual gates remain incomplete.
- Original rigged-operator generation through Studio MCP timed out after five minutes and produced no model. No new avatar asset was inserted; the existing block-shaped showcase remains a known limitation.
- Source-only checks passed 325, art contracts 379, map checks 2,207, audio checks 203, interface wiring 75, preservation checks 5 baseline files and 14 methods, and contrast checks 12 pairs. No Roblox runtime, device or performance completion is implied.
- Studio saved `build/MAYHEM-X-Transformation.rbxl`. No gameplay system or combat balance was changed.

## Terrain and horizon integration, visual gate in progress

- Added owned Terrain generation and cleanup, per-map cloud/atmosphere profiles and distant architectural, vegetation, desert and ice compositions. Removed the old flat Jungle water panel. Refined floating terrain spheres with connected ground and ridges, and reduced the build to eight horizon sectors. Existing combat routes and server damage contracts remain intact.
- Generated and exported the original abandoned-city tower (105435080279086). The earlier abandoned-tower attempt failed moderation and created no accepted asset. No Creator Store search result was inserted.
- Latest source-only verification passed 325 checks; thirteen-model art contracts passed 379. The reduced environment boot passed 11,276 live server assertions and eighty spawn raycasts, with 502,970 occupied terrain cells. These numbers do not establish rendering performance.
- Captured intermediate Collapse and Jungle terrain views. Solar, Frost and Skyline final views remain outstanding. A Studio reconnect restored capture, but it also revealed primitive Solar combat-floor geometry and other unfinished presentation. This maps milestone is not accepted.
- This phase is incomplete. All five final environment captures, remaining UI/mobile fixes, animations, persistence, missions, ranked systems, full match acceptance and performance profiling remain required.

## Premium interface redesign, integration checkpoint

- Replaced the light menu shell with dark layered surfaces, violet actions, cyan selection marks and an Oswald / Builder Sans / Roboto Mono font system. Added nine navigation sections, adaptive desktop rail and scrolling mobile navigation, press/hover/disabled feedback, original-model showcases, fitted weapon cameras and collection previews.
- Armory statistics read the actual shared weapon configuration. Progression shows real server-session XP. Leaderboards read live replicated wins and eliminations. Ranked, permanent mastery and daily/weekly missions are explicitly unavailable; the daily cache remains a working session trial.
- Tested actual desktop navigation and the iPhone 17 Pro landscape layout. Fixed Play clipping and early-character preview cloning. Portrait display was inspected, but portrait navigation clicks remain under investigation. No complete mobile acceptance is claimed.
- Two actual Studio clients each passed 68 client checks and 35 audio loads. The server passed 11,208 assertions and 80 spawn raycasts. Both queued into Jungle; accepted shots spent ammunition, reload restored 18 with 92 reserve, switching and Repulse updated the HUD, and both entered the final duel with the uploaded showdown track. A simulated Player2 reset produced victory/defeat screens. This was not a combat-earned full match and did not verify persistence or sixteen-player performance.
- Source-only verification passed 321 checks with no failures. After a helper placement correction, a fresh single-player boot passed 52 client checks. Current screenshots are under build/screenshots. Remaining work includes portrait input, short-screen layouts, result rewards, full visual review and performance measurements. The UI phase is still in progress.
## Live arena and equipment integration

- Reconnected to the transformation place in Edit mode. Integrated twelve original mesh models, including the new helmet and torso armor, plus an original four-channel PBR deck material. Arena templates now use map-specific landmarks, hulls, vegetation and cover shells while keeping the existing physical routes and spawns.
- Added Art and MapArt modules. Destructible visual shells now follow existing destruction/restoration. Rifle and blade use original models in held equipment, first-person presentation and collection previews. Character appearance loading refreshes the armor, and previews wait for a complete character.
- Replaced hub block scenery with original hull/tower/reactor models and a helmet/armor exhibit. No new dependency, balance change, publish or remote push.
- Executed 11,208 server assertions, eighty spawn raycasts and fifty-two client checks in single-player Studio. Source-only verification passed 312 checks; original mesh contracts passed 345. Offline Premium XML integrity was not run because the preserved file could not be read, and native Rojo/Luau tools are unavailable.
- Generated textures can emit initial content-representation warnings even when explicit fetches report Success. Actual appearance needs continued device and multiplayer review. Full traversal, sixteen-player performance and current-art multiplayer are not verified. The following UI milestone is in progress.
## Earlier transformation asset checkpoint

- Created `feature/studio-production-transformation` from the clean audio checkpoint. Saved a live Studio baseline to `build/backups/MAYHEM-X-live-4a5f2ad.rbxl` and a separate working place to `build/MAYHEM-X-Transformation.rbxl`, preserving the previous Premium file.
- Generated ten original mesh models through official Studio MCP: reactor, canopy tree, desert relic, ice crown, city spire, floating hull, rock shelf, field generator, rifle and blade. Recorded their returned model/mesh/texture IDs and prompts in `assets/art/manifest.json`, exported the live geometry for source control and mapped the library into Rojo. These are assets awaiting gameplay-scene integration, not completed arena or weapon replacements.
- Captured two baseline viewpoints of all five arenas in Studio. Reviewed the textured reactor clone. The review confirmed primitive composition, excessive white surfaces and weak landmarks. No arena redesign is marked complete.
- Backed up ten live presentation scripts before editing. The attempted Art helper insertion did not run because Studio disconnected; its unverified source is preserved under `build/drafts/`, outside the source tree.
- Studio reconnected with no place open. Desktop control reported an unavailable native pipe, and Windows denied launching the saved place. Live editing and verification require reopening the transformation file in Edit mode. No offline replacement build, publishing, remote push, new dependency or Robux spending occurred.

## Live Studio audit and uploaded audio

- Connected the official Studio MCP to the local `MAYHEM-X-Premium.rbxlx`, inspected the live service hierarchy and captured actual Collapse/menu screenshots. All five templates have sixteen spawns and four caches, but zero MeshParts. The full arena, weapon and progression transformation remains unfinished.
- Integrated all twenty-nine user-provided original audio IDs. The requested `audio-upload/audio-ids.txt` was absent, so it was reconstructed from the supplied list using canonical cue names. PowerSteal is configured but reserved, because that gameplay is not implemented.
- Fixed an actual runtime bug: preloading bare strings caused asset-type mismatch errors and falsely disabled valid sounds. Production and test preload paths now use Sound instances and check IsLoaded. All twenty-nine uploads and six built-in fallbacks loaded in Studio.
- Map scores start during insertion/countdown, nearby accepted combat changes the score, showdown and result tracks follow server state, and new rounds clear combat timing. Music keeps at most a current score plus one fading predecessor. Pending/failed effects use a ready fallback. Music/effects/UI volumes and mute retain their existing server preference path.
- Executed 11,033 server assertions, eighty actual spawn raycasts, and client checks. Two real simulated clients each passed seventy client checks and thirty-five audio loads. Queue/voting selected Jungle, real shots spent ammo, reloading restored it, and switch/melee/Repulse requests produced uploaded sounds. Both clients entered the duel; a simulated character reset exercised Victory/Defeat, lobby return and another map round. Observed music voices never exceeded two during transitions. Mute and independent volume propagation passed in both clients.
- Recorded nonzero playback positions and loudness for live tracks/effects. This verifies engine playback in the local Studio context, not human listening quality, published-experience permissions, production persistence or sixteen-player performance.
- Fixed live screenshot defects: navigation sorts by LayoutOrder, and button strokes apply to borders instead of outlining text. Before/after Studio captures document the change. The overall UI still requires the requested production redesign.
- Used the iPhone 17 Pro landscape simulator (750 x 381 viewport) to scroll to Play, join the queue and navigate to arena previews. No game Output errors appeared. Navigation consumes too much height on short screens; comprehensive touch/safe-area and physical-device acceptance remain open. Simulation was disabled after testing.
- Saved a live source backup for seven affected scripts under `build/backups/Studio-source-before-uploaded-audio.json`. Studio saved the local place, but Windows denied copying its open file. Earlier source/place backups remain preserved. No publishing, remote push, new dependency or Robux spending occurred.

Historical entries below describe the state at their original commits. The live audit above supersedes their earlier Studio/audio blockers.

## Premium acceptance follow-up

- Backed up the accepted source and Premium place at `09d6b8a` before further edits. Original Phase 1 and Visual places remain preserved.
- Failed uploaded effects now select available built-in fallbacks. Music loads per context, late preload completions cannot restart an obsolete score, initial group volumes honor preferences, and two of twenty one-shot voices are reserved for UI feedback. Music diagnostics distinguish configured, ready and failed assets.
- Added pure audio routing cases for fallback selection, unavailable assets, tuning, unknown cues and group classification. Execution still requires Luau or Studio.
- Portrait deployment now stacks the showcase, map link, profile and actions in scrollable content. HUD vitals/ammo share available width on narrow screens, status lines stay inside the screen, short landscape kill feeds fit between panels, and reload/swap touch targets are 44 pixels high. Rendered device acceptance remains pending.
- Menu/showcase cameras, branding and bounded nearby hub rings now animate on the client render loop; telemetry stays at 10 Hz. Cached hub caption lookup, one zone-distance calculation per update and selective art invalidation reduce repeated work. Quality/orbit attributes are set before world parenting, and map generations refresh local art caches. Reduced effects clears existing weather promptly.
- Added a darker action-blue token and stronger muted text. Button text and small menu labels now use readable colors on light surfaces. Twelve intended text color pairs have an executable 4.5:1 contrast gate; rendered legibility still requires device review.
- First-person character hiding now follows newly replicated weapon/cosmetic parts. Its listener disconnects on deactivation or character replacement; camera aiming remains unchanged.
- Desktop inventory now works, but the Studio launch attempt timed out at app approval. The node helper failed to start, and portable tool setup could not connect to the remote server. Studio runtime acceptance remains pending.

Executed after the follow-up: offline place build, 1,811 structural checks, 2,201 geometry assertions, 174 WAV assertions, ten loader assertions, 73 interface wiring checks, twelve contrast pairs and baseline gameplay preservation all passed. Luau compilation/rule execution, native Rojo, listening and Studio multiplayer remain pending. No new dependency was installed.

Follow-up commits: `df02b30` (audio fallback/loading), `bacd8fc` (portrait and narrow HUD), `0520635` (local animation/caching), `6dc882d` (text contrast), `f30c963` (first-person cosmetic visibility). The final package report includes full hashes/messages, changed paths and the documentation/package commit. The review baseline is tagged `premium-review-baseline-09d6b8a`.

Packaging found the existing Visual working place unreadable by Windows, with a different observed size from its archived baseline. It was left untouched. The original Visual build remains in the premium-start ZIP; the Phase 1 place and previous Premium backup match their recorded hashes. Current working-place preservation is a separate pending review in the package report, not a passed comparison.

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
