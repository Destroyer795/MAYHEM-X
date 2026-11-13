# Local setup

## Location and existing applications

The writable root is `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`. The requested `C:\MAYHEM-X` is outside this session's writable roots. Scripts resolve their own project root and can run after relocation. Inspect an existing destination before copying or cloning.

The official Roblox Studio MCP is connected to the local transformation place. Live inspection, script editing, screenshots, saving and one-client play tests are working. Windows denied automated restart and copying the open binary. Studio was not reinstalled. The place remains local and unpublished.

No dependencies were installed for this milestone. No Python environment, npm package, Rust installation, administrator access or permanent PATH change is required. Map compilation and audio synthesis use existing PowerShell/.NET.

The active transformation working file is `build/MAYHEM-X-Transformation.rbxl`; the previous Premium file is preserved. Thirteen original models were generated inside Studio, with returned asset IDs, prompts and geometry in `assets/art/manifest.json`. `scripts/art.ps1` exports that captured geometry to `assets/art/Library.rbxmx`; it does not generate a place, upload assets or install software. `tests/Art.Tests.ps1` checks its static asset/collision contract (379 assertions at the current checkpoint). Asset permissions in a published universe still need verification. Keep the library and manifest as source; the generator tooling remains Roblox Studio itself.

The operator showcase idle was generated through Studio and uses `rbxassetid://128214294905072`, configured in `src/shared/AnimationConfig.luau`. Its track loaded in local Studio, but permission in the intended published universe has not been verified. It is used only for the operator viewport, not combat characters.

The latest Play run reported missing content representations for generated texture IDs `137134570533821`, `95314124117901`, `122272855563833`, `117932222879559`, `139030421332826`, `105269080138767`, `99998311990220`, `104817013345409`, `122660213004304` and `74264750154799`. Their original references remain in the art manifest so this is traceable. Mesh geometry rendered, but these textures are not verified. Inspect their asset status and access in the intended test universe; restore the original permitted texture or create an original replacement through Studio if Roblox no longer serves it. No replacement ID is guessed, and this art acceptance issue remains open.

The ten unresolved texture references are mapped below. The metadata probe `GET /assets/v1/assets/137134570533821` was refused because this MCP session still reported `asset:read` as ungranted after the user confirmed enabling it. Reconnect the current Studio MCP session after saving the grant, then retry metadata checks. This is not a claim that the textures were deleted or incorrectly authored.

| Model | Part | Texture ID |
| --- | --- | --- |
| CanopyTree | trunk_geom | 74264750154799 |
| SkySpire | walls_geom | 122272855563833 |
| SkySpire | door_geom | 105269080138767 |
| SkySpire | roof_geom | 117932222879559 |
| SignalArmor | abdominal panels_geom | 137134570533821 |
| SignalArmor | back shell_geom | 95314124117901 |
| RuinedTower | walls_geom | 139030421332826 |
| RuinedTower | windows_geom | 99998311990220 |
| RuinedTower | door_geom | 104817013345409 |
| RuinedTower | roof_geom | 122660213004304 |

| Dependency | Purpose and version | Location/form | Storage |
| --- | --- | --- | --- |
| Windows PowerShell / .NET | Build, checks, original PCM synthesis; 5.1.26100.9711 / CLR 4.0.30319.42000 observed | Existing Windows components | Existing external storage, unchanged |
| Git | Required history, preservation and bundles; 2.50.0.windows.1 | Existing `C:/Program Files/Git/cmd/git.exe` | Existing external application; metadata local |
| Rojo CLI | Native build, sync and sourcemap; pinned 7.7.1 | Portable `.tools/rojo-7.7.1/rojo.exe` | ZIP about 4.36 MB; not installed here |
| Luau CLI suite | Source compilation, rule execution and pure-module analysis; pinned 0.743 | Portable `.tools/luau-0.743/` | ZIP about 3.06 MB; not installed here |
| Rojo Studio plugin | Optional live sync; match CLI 7.7.1 | Manual Studio user-plugin installation, external | Official model about 564 KB |
| Roblox Studio | Engine, rendering and multiplayer tests | Existing external installation | Not measured |

The WAV pack is generated project content, not a new dependency: about 25.1 MiB uncompressed. The final package report measures source, build and local metadata storage.

## Portable tools

`tools.lock.json` pins official release URLs, versions and SHA-256 hashes. Setup validates existing receipts/executable hashes and reuses intact installations. It stops for inspection if an existing tool folder is incomplete or modified.

The commands below describe the source-build workflow. The default build target is the live Premium filename. Preserve that file and use a separate OutputName before running a source snapshot build; do not replace Studio-authored scene changes.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireTools
```

Shell downloads were blocked here, so Rojo and Luau remain unavailable. Re-run setup where ordinary network access is available, or place the exact official ZIP files named in the lockfile into `.tools/` first. Setup verifies them before extraction. `-RojoOnly` installs just Rojo. Release sources: [Rojo](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), [Luau](https://github.com/luau-lang/luau/releases/tag/0.743).

Run installed tools by local path, for example `& '.\.tools\rojo-7.7.1\rojo.exe' --version` or `& '.\.tools\luau-0.743\luau.exe' '.\tests\run.luau'`. No shell profile or system configuration change is needed.

Opening the Premium place needs no plugin. For live sync, manually install the matching plugin using [Rojo's instructions](https://rojo.space/docs/v7/getting-started/installation/). The plugin is not fully contained in this project. Run `scripts/serve.ps1`, connect to `127.0.0.1:34872`, review changes and sync into the intended local test place. Stop simulation before syncing.

## Uploaded audio

The user uploaded the original pack and supplied all twenty-nine IDs below. `audio-upload/audio-ids.txt` preserves the canonical mapping; `src/shared/AudioConfig.luau` supplies runtime URIs. `scripts/audio.ps1` writes those IDs into the generated WAV manifest. It does not upload files or grant permissions. Original stereo 44.1 kHz, 16-bit WAVs come from `assets/audio/scorebook.json`; their manifest records hashes and usage terms. Generated-file edits are detected before regeneration.

| Cue | Roblox audio ID | Intended event |
| --- | --- | --- |
| Lobby | 115295081724326 | Hub, waiting and nonparticipant music |
| Collapse | 119354128442400 | The Collapse insertion and arena score |
| Jungle | 137323613567452 | Neon Jungle insertion and arena score |
| Solar | 93912277388041 | Solar Wasteland insertion and arena score |
| Frost | 132327355812260 | Frostbite insertion and arena score |
| Skyline | 75930625752768 | Skyline Zero insertion and arena score |
| Combat | 74401952086561 | Recent nearby accepted combat |
| Showdown | 93832246189768 | Final duel music |
| Victory | 126488632915135 | Winning participant result stinger |
| Defeat | 93717867149696 | Losing participant result stinger |
| Shot | 117384060288786 | Accepted rifle fire, spatial |
| Reload | 127622753054141 | Server-confirmed local reload |
| Switch | 133299106908058 | Server-confirmed weapon slot change |
| Slash | 85161275315961 | Accepted blade swing, spatial |
| MeleeHit | 75145654636700 | Blade hit acknowledgement and local hull damage |
| Impact | 125720845191168 | Rifle world impact, spatial |
| Explosion | 130673317918385 | Destructible cover breaking, spatial |
| Shield | 79794280696752 | Local shield damage feedback |
| Eliminate | 85795250351709 | Character elimination effect, spatial |
| Repulse | 120827402091841 | Accepted Repulse wave, spatial |
| Ultimate | 116582094733707 | Accepted Aegis activation, spatial |
| Mutation | 118969565930031 | Reality mutation announcement |
| PowerSteal | 125966715610498 | Reserved only, power-stealing gameplay is absent |
| UI | 87868301798689 | Enabled button activation |
| Hover | 83803776836215 | Enabled button hover |
| Transition | 78810693063926 | Menu page transition |
| Notification | 123408274839656 | Notices and nonwinning result feedback |
| Reward | 104912968188467 | Unlock/daily reward, win feedback and audio-test button |
| Purchase | 113975906689066 | Confirmed cosmetic catalog purchase |

All uploads and six built-in fallbacks loaded in both Studio clients. Live tracks/effects produced advancing positions and nonzero loudness. This establishes engine playback in the local Studio context, not human listening quality or permission grants for the eventual published universe. PowerSteal was load-tested but has no live gameplay caller.

For replacement uploads or permission failures:

1. Listen to the WAVs and review `manifest.json`. Start with `Lobby.wav`, the five map tracks, `Combat.wav`, `Showdown.wav`, `Victory.wav` and `Defeat.wav`.
2. In Creator Dashboard, choose **Development Items > Audio > Upload Asset**. Upload the files under the intended creator and wait for moderation. Studio's Asset Manager Import is another supported route. Follow the current [audio import instructions](https://create.roblox.com/docs/audio/assets).
3. For each approved asset, open **Configure > Permissions > Experiences > Add experiences** and use the intended existing experience's universe ID. Check the selected experience carefully. See [asset permissions](https://create.roblox.com/docs/projects/assets/privacy#on-an-asset-level). No upload or permission change was performed here.
4. Update the matching entry in both `audio-upload/audio-ids.txt` and `src/shared/AudioConfig.luau`. The manifest `id` matches the config field: `Lobby.wav` maps to `Uploads.Lobby`, and `SFX-Shot.wav` maps to `Uploads.Shot`. Inspect and edit the live AudioConfig through Studio MCP, then mirror source. Do not substitute guesses.
5. Run `scripts/audio.ps1` and `tests/Audio.Tests.ps1` using process-local execution-policy bypass. Run the client audio check in DEVELOPMENT.md and listen in two simulated clients. Verify music/effects/UI volumes and mute. If an asset fails, inspect Output and its experience permission. Unavailable effects use an available built-in cue; unavailable music stays silent and is reported in settings.

Built-in SFX/ambience fallbacks use six URIs listed in [Roblox Core-Scripts](https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua). Sound-instance probes verify loading; bare URI preload requests incorrectly rejected these assets in the live audit. Music preloads on context selection, so configured and ready counts differ normally. Settings report ready/failed effects and configured/ready/failed music.

If no existing authorized experience is available for permissions, keep that acceptance test pending. Do not publish the game or access credentials to resolve it during this milestone.

## History, updates and cleanup

Git uses `.version-control/` because protected `.git/` writes are denied. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\git.ps1 status`. Both metadata and tool binaries are ignored. Keep the metadata or a verified bundle.

To migrate into a normal checkout, inspect the destination, then:
```powershell
git clone .\build\MAYHEM-X-premium.bundle C:\MAYHEM-X
git -C C:\MAYHEM-X remote set-url origin https://github.com/Destroyer795/MAYHEM-X.git
```
These relocation commands were not run here. The bundle includes source/history, not ignored builds, WAVs or tools; rebuild after cloning. Do not push before remote history is inspected and pushing is separately authorized.

Update a tool by choosing an official release, reviewing its checksum, changing its lockfile entry and testing the new versioned local folder. Keep one active version per function. Remove only the old named version folder/archive after stopping that tool. Update/remove the optional plugin separately through Studio. Existing Git, PowerShell and Studio require no project uninstaller.

Generated templates and WAVs can be rebuilt. Preserve edited WAVs before regeneration. The live Premium place, screenshots and Studio verification report now contain evidence not reproduced by the offline build. Preserve them before cleanup, together with Phase 1/Visual archives, Premium/source backups, bundles and `.version-control/`. Windows denied a shell copy of the open Studio place; the seven-script live source backup is `build/backups/Studio-source-before-uploaded-audio.json`. Never delete live Studio lock files. Temporary download `.partial` files can be removed after failed setup; ZIP downloads can be removed after a verified install. Do not remove source, lockfiles or unrelated Roblox/user files.

For the Studio-authored workflow, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1 -SourceOnly`. This deliberately skips the stale offline place manifest and does not validate the saved binary. No dependencies were added for the terrain, UI or original mesh integration. Preserve `build/backups/Studio-environment-sources-737677c.json` and the earlier binary baseline before cleanup.
