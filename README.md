# MAYHEM X

**ENTER THE CHAOS. BECOME THE LEGEND.**

An original 16-contender Roblox arena survival game. The Collapse connects four floating districts to a central reactor tower with a spiral ascent, bridge network and hidden lower vault. The visual milestone adds a navy, electric-purple and cyan identity, a 3D orbital lobby, district machinery, restrained atmospheric lighting and a complete presentation flow. Geometry, weapons and operative previews are procedural, with no external asset IDs.

Phase 1 and the visual overhaul are implemented in source. Offline packaging, source preservation and interface wiring checks pass. Studio import, multiplayer gameplay, device layouts, performance, Luau compilation and Rojo-native validation remain unverified here. The visual acceptance gate is pending, and Phase 2 gameplay is not enabled.

## Open the current build

1. In Roblox Studio, open `build/MAYHEM-X-Visual.rbxlx`. The arena is generated when simulation starts, so the edit viewport initially has no arena. The original `build/MAYHEM-X.rbxlx` is preserved.
2. Select **Server & Clients**, choose two clients, then start the simulation.
3. Click **PLAY / JOIN QUEUE** in both clients. After intermission and insertion, fight to become the final survivor. The hub's 3D consoles also open deployment, collection, Style Lab, daily cache and settings.
4. Follow the multiplayer checklist in [DEVELOPMENT.md](DEVELOPMENT.md) before approving Phase 1.

Implemented: opt-in FIFO queue, up to 16 contenders, lobby respawning, round countdowns, spawn protection, VECTOR-18 rifle, Rift Blade, Repulse, health, shields, finite ammunition, reloading, weapon switching, two camera perspectives, PC and touch controls, controller bindings, elimination feed, round results, session Kills/Wins and client settings. Timeouts with multiple survivors are draws. Queue preference carries into subsequent rounds.

Presentation: animated lobby rings, 3D operative/weapon previews, matchmaking and mode briefing, session inventory, three signal-plate profiles, two starter finishes, two complimentary Style Lab finishes, a daily Prism session trial, loading/countdown feedback and victory/defeat/draw screens. Cosmetics have no combat advantage and are not saved after leaving. Last Signal is the available game mode. Ultimate and chaos indicators explicitly show unavailable/stable status.

Settings control camera, FOV, automatic/high/low graphics, effects, environment motion and audio groups. Tracers, impacts, sword Trails, Repulse waves, shield Highlights and elimination effects are bounded and cleaned up locally. Audio infrastructure is connected, but no licensed tracks or sound IDs ship, so the current game is silent.

PC controls: WASD and jump, hold left click to attack, 1/2 weapons, R reload, Q Repulse, C camera, M menu. Touch uses Roblox movement and jump plus custom combat buttons; drag the right side to aim. Controller: RT attack, LB swap, X reload, Y Repulse, D-pad down camera, D-pad left menu. Controller menu navigation requires Studio verification.

## Rebuild

From the project root in Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Offline -OutputName MAYHEM-X-Visual.rbxlx
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

The offline builder reads the same project tree as Rojo and embeds the source into a place XML file. It supports this project's current file/property types and rejects unsupported inputs. It does not replace Rojo's API validation or Studio testing.

For the pinned local Rojo and Luau tools, installation and live sync, see [SETUP.md](SETUP.md). Architecture is in [ARCHITECTURE.md](ARCHITECTURE.md), workflow and tests in [DEVELOPMENT.md](DEVELOPMENT.md), and implemented scope and remaining work in [CHANGELOG.md](CHANGELOG.md).

Local history uses `.version-control/` because this sandbox denies `.git/` writes. Use `scripts/git.ps1` for Git operations. Origin is `https://github.com/Destroyer795/MAYHEM-X.git`; nothing was pushed. A portable history bundle and per-commit file report are generated under `build/` at handoff.

The requested destination is `C:\MAYHEM-X`. This session can write only inside the supplied workspace, so the current project is at `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`. All scripts resolve their own project root and support moving the folder later. No publishing, Robux spending or credential access is required.
