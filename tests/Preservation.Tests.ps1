$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$metadata = Join-Path $projectRoot '.version-control'
if (-not (Test-Path -LiteralPath $metadata)) { $metadata = Join-Path $projectRoot '.git' }
$baseline = '9172422'
$paths = @('src/server/MatchService.luau','src/server/CombatService.luau','src/server/ArenaService.luau','src/shared/Config.luau','src/shared/Rules.luau','src/shared/Protocol.luau','tests/RulesCases.luau')
foreach ($relative in $paths) {
    $original = & git "--git-dir=$metadata" "--work-tree=$projectRoot" rev-parse "${baseline}:$relative"
    if ($LASTEXITCODE -ne 0) { throw 'The inspected Phase 1 baseline is required for preservation checks' }
    $current = & git "--git-dir=$metadata" "--work-tree=$projectRoot" hash-object -- (Join-Path $projectRoot $relative)
    if ($LASTEXITCODE -ne 0 -or $current -ne $original) { throw "Gameplay preservation failed: $relative differs from the baseline" }
}
$originalCamera = (& git "--git-dir=$metadata" "--work-tree=$projectRoot" show "${baseline}:src/client/CameraController.luau") -join "`n"
$currentCamera = [IO.File]::ReadAllText((Join-Path $projectRoot 'src\client\CameraController.luau')).Replace("`r`n","`n")
$pattern = '(?s)function CameraController\.aim\(.*?\nend'
$originalAim = [regex]::Match($originalCamera,$pattern)
$currentAim = [regex]::Match($currentCamera,$pattern)
if (-not $originalAim.Success -or -not $currentAim.Success -or $originalAim.Value -cne $currentAim.Value) { throw 'Camera aim behavior changed from the inspected baseline' }
$origin = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'scripts/git.ps1') remote -v
if ($LASTEXITCODE -ne 0 -or ($origin -join "`n") -notmatch 'origin\s+https://github.com/Destroyer795/MAYHEM-X.git') { throw 'Git wrapper or configured origin did not round-trip correctly' }
Write-Output 'PASS: seven baseline files and camera aim preserved; Git origin wrapper verified'
