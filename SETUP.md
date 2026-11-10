# Local setup

## Isolation and current environment

Everything created for this project is under the project root. The requested `C:\MAYHEM-X` destination is outside this session's writable sandbox. Work was performed in `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`. To use the requested path, close project tools and copy the entire folder to `C:\MAYHEM-X` yourself, inspecting any existing destination first. Scripts use their own location, not a hard-coded drive path. Rebuild after moving to refresh generated manifests.

Windows PowerShell is the only requirement for offline packaging and structural checks. No Python, Node.js, Rust, npm packages or virtual environment is required or installed. Existing Git and Node.js were detected; neither is a project dependency. No administrator privileges or persistent PATH changes are used. Commands below use execution policy for that PowerShell process only.

Direct outbound shell downloads failed in this session. Studio's existing desktop shortcut points to `C:\Users\PRANAV KISHAN\AppData\Local\Roblox\Versions\version-63eb6055af4e4688\RobloxStudioBeta.exe`, but inspecting that executable returned access denied. The computer/browser automation host was unavailable. Studio is an external existing application and was not reinstalled.

## Pinned tools

| Dependency | Purpose | Version | Local location | Storage and form |
| --- | --- | --- | --- | --- |
| Rojo CLI | Required development sync, native project build and sourcemap validation | 7.7.1 | `.tools/rojo-7.7.1/rojo.exe` | Portable, official ZIP about 4.36 MB; extracted size measured by setup |
| Luau CLI suite | Compile all source, run rule tests, analyze engine-independent modules | 0.743 | `.tools/luau-0.743/` | Portable, official ZIP about 3.06 MB; extracted size measured by setup |
| Rojo Studio plugin | Optional live sync inside Studio | Match CLI 7.7.1 | Studio's user plugin location, outside this project | External Studio installation, official `Rojo.rbxm` about 564 KB |
| Roblox Studio | Engine simulation and multiplayer testing | Existing user installation | Existing Roblox installation | External application, unchanged; size inaccessible here |

Release sources: [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1), [Luau 0.743](https://github.com/luau-lang/luau/releases/tag/0.743). Archive SHA-256 values from those official release assets are pinned in `tools.lock.json`. Installation verifies each archive before extraction and records executable hashes in a local receipt. Re-running setup validates the receipt and reuses a complete local installation without downloading. An incomplete or modified tool directory stops setup for inspection.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -RequireTools
```

`setup.ps1 -RojoOnly` installs only Rojo when compiler checks are not needed. Installation was attempted here but blocked by outbound network access, so no portable dependency was installed. `.tools/` may contain an empty partial download. If ordinary network access is available to you, re-run setup locally. Alternatively, place the exact official ZIPs named in `tools.lock.json` directly in `.tools/` and re-run setup, which verifies and extracts them without downloading.

Run tools locally with `& '.\.tools\rojo-7.7.1\rojo.exe' --version`, `& '.\.tools\luau-0.743\luau-compile.exe' --help`, or the scripts above. `scripts/serve.ps1` starts Rojo at `127.0.0.1:34872`; Ctrl+C stops it.

## Studio connection

Opening a built `.rbxlx` needs no plugin. For live sync, manually install the matching Rojo plugin from the official release or Roblox plugin marketplace, using the [Rojo installation instructions](https://rojo.space/docs/v7/getting-started/installation/). This plugin is not contained entirely in the project. Start `scripts/serve.ps1`, open an unpublished place in Studio, connect the plugin to localhost port 34872, review its changes, then sync. Avoid syncing into unrelated places. Never publish during this milestone.

The match manager limits a round to 16 participants even if a server contains additional queued players. When configuring an experience for later release, set its place/server capacity to 16 in Studio or Creator Dashboard. That external setting is not changed by Rojo here. API Services and DataStore access are unnecessary for Phase 1.

## Update, remove and clean up

To update a portable tool, choose an official release, inspect its asset/checksum, update its entry in `tools.lock.json`, and run setup. New versions use separate versioned folders. Build and verify with the new version before removing the old folder. Keep only one active version per tool. Update the optional Studio plugin separately through Studio so it matches the CLI.

To remove a dependency, stop its process and delete only its named version folder and archive inside this project's `.tools/`. Remove the optional plugin through Studio's plugin manager separately. No global uninstaller is involved.

`build/` contains generated places, manifests, sourcemaps and verification reports. It is safe to regenerate; inspect the folder before deleting it. `.tools/*.partial` are incomplete downloads and may be deleted after a failed setup. ZIPs can be removed after a successful setup to save space; installed executables and their receipts remain sufficient. Deleting the project removes all project-local dependencies. Do not delete Roblox's installation, unrelated folders, source or lockfiles as cleanup.
