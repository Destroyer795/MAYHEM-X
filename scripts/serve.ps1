$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'maps.ps1')
$lock = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'tools.lock.json') | ConvertFrom-Json
$rojo = Join-Path $projectRoot ".tools\rojo-$($lock.rojo.version)\rojo.exe"
if (-not (Test-Path -LiteralPath $rojo)) { throw 'Run scripts/setup.ps1 -RojoOnly first.' }
& $rojo serve (Join-Path $projectRoot 'default.project.json') --address 127.0.0.1
if ($LASTEXITCODE -ne 0) { throw "Rojo serve exited with code $LASTEXITCODE" }
