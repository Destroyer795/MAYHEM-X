# Local setup

## Location and existing applications

The writable root is `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`. The requested `C:\MAYHEM-X` is outside this session's writable roots. Scripts resolve their own project root and can run after relocation. Inspect an existing destination before copying or cloning.

Roblox Studio is installed and a running Studio process was observed. The earlier computer-control helper returned a missing native-pipe error. During the acceptance follow-up, desktop inventory became available but Studio exposed no window; launching it timed out at app approval. The separate node helper also failed to start. Automated Studio testing remains pending. Studio was not reinstalled. Shell access to its executable previously returned access denied.

No dependencies were installed for this milestone. No Python environment, npm package, Rust installation, administrator access or permanent PATH change is required. Map compilation and audio synthesis use existing PowerShell/.NET.

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

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireTools
```

Shell downloads were blocked here, so Rojo and Luau remain unavailable. Re-run setup where ordinary network access is available, or place the exact official ZIP files named in the lockfile into `.tools/` first. Setup verifies them before extraction. `-RojoOnly` installs just Rojo. Release sources: [Rojo](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), [Luau](https://github.com/luau-lang/luau/releases/tag/0.743).

Run installed tools by local path, for example `& '.\.tools\rojo-7.7.1\rojo.exe' --version` or `& '.\.tools\luau-0.743\luau.exe' '.\tests\run.luau'`. No shell profile or system configuration change is needed.

Opening the Premium place needs no plugin. For live sync, manually install the matching plugin using [Rojo's instructions](https://rojo.space/docs/v7/getting-started/installation/). The plugin is not fully contained in this project. Run `scripts/serve.ps1`, connect to `127.0.0.1:34872`, review changes and sync into the intended local test place. Stop simulation before syncing.

## Original audio, manual upload

The user selected original tracks for manual upload. `assets/audio/scorebook.json` and `scripts/audio.ps1` produce stereo 44.1 kHz, 16-bit WAVs under `build/audio/`. Their manifest contains route names, hashes and usage terms. Generated-file edits are detected before regeneration.

1. Listen to the WAVs and review `manifest.json`. Start with `Lobby.wav`, the five map tracks, `Combat.wav`, `Showdown.wav`, `Victory.wav` and `Defeat.wav`.
2. In Creator Dashboard, choose **Development Items > Audio > Upload Asset**. Upload the files under the intended creator and wait for moderation. Studio's Asset Manager Import is another supported route. Follow the current [audio import instructions](https://create.roblox.com/docs/audio/assets).
3. For each approved asset, open **Configure > Permissions > Experiences > Add experiences** and use the intended existing experience's universe ID. Check the selected experience carefully. See [asset permissions](https://create.roblox.com/docs/projects/assets/privacy#on-an-asset-level). No upload or permission change was performed here.
4. Edit `src/shared/AudioConfig.luau`, replacing the matching empty `Uploads` value with the returned `rbxassetid://` URI. The manifest `id` matches the config field. Example: `Lobby.wav` maps to `Uploads.Lobby`; `SFX-Shot.wav` maps to `Uploads.Shot`. Do not substitute guesses.
5. Rebuild, run the client audio check in DEVELOPMENT.md and listen in multiple simulated clients. Verify music/effects/UI volumes and mute. If an asset fails, inspect Output and its experience permission; leave its field empty until resolved.

Music fields are intentionally empty. Built-in SFX/ambience fallbacks use six URIs listed in [Roblox Core-Scripts](https://github.com/Roblox/Core-Scripts/blob/master/PlayerScripts/StarterCharacterScripts/Sound.server.lua). This verifies their source, not successful loading in the current client. Failed uploaded effects fall back when their built-in cue is available. Music preloads on context selection, so a configured track is not necessarily loaded yet. Settings show configured, ready and failed music counts. `PowerSteal` is an unused future audio cue, with no power-stealing gameplay.

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

Generated `build/generated/`, `build/audio/`, manifests and verification reports can be rebuilt. Preserve edited WAVs before regeneration. Inspect artifacts before cleanup. Keep the original Phase 1/Visual places, baseline archives, the `09d6b8a` source/place review backups, bundles and `.version-control/` until acceptance and migration. Never delete live Studio lock files. Temporary download `.partial` files can be removed after failed setup; ZIP downloads can be removed after a verified install. Do not remove source, lockfiles or unrelated Roblox/user files.
