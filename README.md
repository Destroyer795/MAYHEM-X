# MAYHEM X

**ENTER THE CHAOS. BECOME THE LEGEND.**

An original 16-contender Roblox arena survival game. The first map, The Collapse, connects four floating districts to a central reactor tower with a spiral ascent, bridge network and hidden lower vault. Slate metal, cyan circuitry and amber warning lights define its visual identity. All project geometry and weapon visuals are procedural, with no external asset IDs.

Phase 1 source is implemented. The offline place has been packaged and checked for source integrity. Roblox gameplay, Studio import, Luau compilation and Rojo-native validation are not yet verified in this environment. Do not treat this milestone as a runtime-approved prototype.

## Open the current build

1. In Roblox Studio, open `build/MAYHEM-X.rbxlx`. The arena is generated when simulation starts, so the edit viewport initially has no arena.
2. Select **Server & Clients**, choose two clients, then start the simulation.
3. Click **QUEUE FOR THE COLLAPSE** in both clients. After intermission and insertion, fight to become the final survivor.
4. Follow the multiplayer checklist in [DEVELOPMENT.md](DEVELOPMENT.md) before approving Phase 1.

Implemented: opt-in FIFO queue, up to 16 contenders, lobby respawning, round countdowns, spawn protection, VECTOR-18 rifle, Rift Blade, Repulse, health, shields, finite ammunition, reloading, weapon switching, two camera perspectives, PC and touch controls, controller bindings, elimination feed, round results, session Kills/Wins and client settings. Timeouts with multiple survivors are draws. Queue preference carries into subsequent rounds.

PC controls: WASD and jump, hold left click to attack, 1/2 weapons, R reload, Q Repulse, C camera, M menu. Touch uses Roblox movement and jump plus custom combat buttons; drag the right side to aim. Controller: RT attack, LB swap, X reload, Y Repulse, D-pad down camera, D-pad left menu. Controller menu navigation requires Studio verification.

## Rebuild

From the project root in Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Offline
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

The offline builder reads the same project tree as Rojo and embeds the source into a place XML file. It supports this project's current file/property types and rejects unsupported inputs. It does not replace Rojo's API validation or Studio testing.

For the pinned local Rojo and Luau tools, installation and live sync, see [SETUP.md](SETUP.md). Architecture is in [ARCHITECTURE.md](ARCHITECTURE.md), workflow and tests in [DEVELOPMENT.md](DEVELOPMENT.md), and implemented scope and remaining work in [CHANGELOG.md](CHANGELOG.md).

The requested destination is `C:\MAYHEM-X`. This session can write only inside the supplied workspace, so the current project is at `C:\Users\PRANAV KISHAN\Desktop\forked trash\MAYHEM-X`. All scripts resolve their own project root and support moving the folder later. No publishing, Robux spending or credential access is required.
