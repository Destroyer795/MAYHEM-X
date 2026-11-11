[CmdletBinding()]
param([switch]$RequireTools)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'ProjectModel.ps1')
$passed = [Collections.Generic.List[string]]::new()
$failed = [Collections.Generic.List[string]]::new()
$skipped = [Collections.Generic.List[string]]::new()
function Check-Mayhem {
    param([bool]$Condition, [string]$Description)
    if ($Condition) { $passed.Add($Description) } else { $failed.Add($Description) }
}
$model = Get-MayhemProjectModel -ProjectRoot $projectRoot
try {
    & (Join-Path $projectRoot 'tests\Maps.Tests.ps1')
    $passed.Add('Generated physical map templates, spawns and budgets')
} catch { $failed.Add('Map templates: ' + $_.Exception.Message) }
try {
    & (Join-Path $projectRoot 'tests\Audio.Tests.ps1')
    $passed.Add('Original PCM audio, levels, checksums and route manifest')
} catch { $failed.Add('Original audio: ' + $_.Exception.Message) }
Check-Mayhem ($model.Config.serveAddress -eq '127.0.0.1') 'Rojo serve binds to localhost'
$logicalPaths = @($model.Entries.LogicalPath)
Check-Mayhem (($logicalPaths | Sort-Object -Unique).Count -eq $logicalPaths.Count) 'No duplicate instance paths'
$required = @(
    'ReplicatedStorage.Mayhem.Shared.Config','ReplicatedStorage.Mayhem.Shared.Protocol','ReplicatedStorage.Mayhem.Shared.Rules',
    'ServerScriptService.MayhemServer.Bootstrap','ServerScriptService.MayhemServer.MatchService',
    'ServerScriptService.MayhemServer.CombatService','ServerScriptService.MayhemServer.ArenaService','ServerScriptService.MayhemServer.Equipment',
    'StarterPlayer.StarterPlayerScripts.MayhemClient.Bootstrap','StarterPlayer.StarterPlayerScripts.MayhemClient.Hud',
    'StarterPlayer.StarterPlayerScripts.MayhemClient.CameraController','StarterPlayer.StarterPlayerScripts.MayhemClient.Effects',
    'ServerScriptService.MayhemTests.RulesCases'
)
foreach ($path in $required) { Check-Mayhem ($logicalPaths -contains $path) "Mapped instance: $path" }
$protocolText = [IO.File]::ReadAllText((Join-Path $projectRoot 'src\shared\Protocol.luau'))
$declared = [regex]::Match($protocolText, 'Remote = table\.freeze\(\{([^}]+)\}').Groups[1].Value
$remoteNames = @([regex]::Matches($declared, '\b(\w+)\s*=\s*"(\w+)"') | ForEach-Object { $_.Groups[1].Value })
foreach ($name in $remoteNames) {
    $nodes = @($model.Entries | Where-Object { $_.LogicalPath -eq "ReplicatedStorage.Mayhem.Remotes.$name" })
    Check-Mayhem ($nodes.Count -eq 1 -and $nodes[0].Class -eq 'RemoteEvent') "RemoteEvent declaration: $name"
}
Check-Mayhem ($remoteNames.Count -eq 4) 'Four protocol RemoteEvents'
$declaredActions = [regex]::Match($protocolText, 'Action = table\.freeze\(\{([^}]+)\}').Groups[1].Value
$actionNames = @([regex]::Matches($declaredActions, '\b(\w+)\s*=\s*"(\w+)"') | ForEach-Object { $_.Groups[1].Value })
$sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src'),(Join-Path $projectRoot 'tests') -Recurse -Filter '*.luau' -File) + @(Get-Item -LiteralPath (Join-Path $projectRoot 'build/generated/MapCatalog.luau'))
$gameConfigText = [IO.File]::ReadAllText((Join-Path $projectRoot 'src/shared/Config.luau'))
$gameConfigGroups = @{}
foreach ($section in [regex]::Matches($gameConfigText,'(\w+)\s*=\s*table\.freeze\(\{([^}]+)\}')) {
    $gameConfigGroups[$section.Groups[1].Value] = @([regex]::Matches($section.Groups[2].Value,'\b(\w+)\s*=') | ForEach-Object { $_.Groups[1].Value })
}
foreach ($file in $sourceFiles) {
    $source = [IO.File]::ReadAllText($file.FullName)
    Check-Mayhem ($source.StartsWith('--!strict')) "Strict Luau directive: $($file.Name)"
    if ($source -match 'local Config = require\([^\r\n]*(?:\.Config\)|WaitForChild\("Config"\))') {
        foreach ($reference in [regex]::Matches($source,'\bConfig\.(\w+)\.(\w+)')) {
            $group=$reference.Groups[1].Value; $field=$reference.Groups[2].Value
            Check-Mayhem ($gameConfigGroups.ContainsKey($group) -and $gameConfigGroups[$group] -contains $field) "Game configuration reference: $($file.Name)/$group.$field"
        }
    }
    foreach ($reference in [regex]::Matches($source, 'Protocol\.Remote\.(\w+)')) {
        Check-Mayhem ($remoteNames -contains $reference.Groups[1].Value) "Remote reference: $($file.Name)/$($reference.Groups[1].Value)"
    }
    foreach ($reference in [regex]::Matches($source, '(?:Protocol\.Action|actions)\.(\w+)')) {
        Check-Mayhem ($actionNames -contains $reference.Groups[1].Value) "Action reference: $($file.Name)/$($reference.Groups[1].Value)"
    }
    $mapped = @($model.Entries | Where-Object { $_.Source -eq $file.FullName })
    if ($mapped.Count -eq 1) {
        $entry = $mapped[0]
        $parentPath = $entry.LogicalPath.Substring(0, $entry.LogicalPath.LastIndexOf('.'))
        foreach ($reference in [regex]::Matches($source, 'require\(script\.Parent\.(\w+)\)')) {
            Check-Mayhem ($logicalPaths -contains "$parentPath.$($reference.Groups[1].Value)") "Sibling module: $($file.Name)/$($reference.Groups[1].Value)"
        }
        foreach ($reference in [regex]::Matches($source, 'require\(shared\.(\w+)\)')) {
            Check-Mayhem ($logicalPaths -contains "ReplicatedStorage.Mayhem.Shared.$($reference.Groups[1].Value)") "Shared module: $($file.Name)/$($reference.Groups[1].Value)"
        }
    }
}
foreach ($file in Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object { $_.Extension -in @('.md','.json','.luau','.ps1') -and $_.FullName -notmatch '\\(build|\.tools)\\' }) {
    Check-Mayhem (-not [IO.File]::ReadAllText($file.FullName).Contains([char]0x2014)) "Writing character policy: $($file.Name)"
}
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot,(Join-Path $projectRoot 'tests') -Filter '*.ps1') {
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    Check-Mayhem ($errors.Count -eq 0) "PowerShell syntax: $($file.Name)"
    foreach ($problem in $errors) { $failed.Add($problem.ToString()) }
}
try {
    & (Join-Path $projectRoot 'tests\ProjectModel.Tests.ps1')
    $passed.Add('Executable project model tests')
} catch { $failed.Add('Executable project model tests: ' + $_.Exception.Message) }
try {
    & (Join-Path $projectRoot 'tests\Preservation.Tests.ps1')
    $passed.Add('Phase 1 gameplay source preservation and Git wrapper')
} catch { $failed.Add('Gameplay preservation: ' + $_.Exception.Message) }
if (Test-Path -LiteralPath (Join-Path $projectRoot 'tests\Interface.Tests.ps1')) {
    try {
        & (Join-Path $projectRoot 'tests\Interface.Tests.ps1')
        $passed.Add('Interface callbacks, navigation and presentation wiring')
    } catch { $failed.Add('Interface wiring: ' + $_.Exception.Message) }
}
$primaryDocs = @(Get-ChildItem -LiteralPath $projectRoot -Filter '*.md' -File | Select-Object -ExpandProperty Name | Sort-Object)
try {
    & (Join-Path $projectRoot 'tests\Presentation.Tests.ps1')
    $passed.Add('Small text color contrast')
} catch { $failed.Add('Text contrast: ' + $_.Exception.Message) }
Check-Mayhem (($primaryDocs -join ',') -eq 'ARCHITECTURE.md,CHANGELOG.md,DEVELOPMENT.md,README.md,SETUP.md') 'Exactly five primary documentation files'
$lock = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'tools.lock.json') | ConvertFrom-Json
foreach ($name in @('rojo','luau')) {
    Check-Mayhem ($lock.$name.sha256 -match '^[a-f0-9]{64}$') "Pinned download checksum: $name"
    Check-Mayhem ($lock.$name.url.StartsWith('https://github.com/')) "Official download host: $name"
}
$manifestPath = Join-Path $projectRoot 'build\manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.place -notmatch '^[A-Za-z0-9_-]+\.rbxlx$') { throw 'Invalid place filename in build manifest' }
$place = Join-Path (Join-Path $projectRoot 'build') $manifest.place
if (Test-Path -LiteralPath $place) {
    $xml = [xml][IO.File]::ReadAllText($place)
    Check-Mayhem ($xml.roblox.version -eq '4') 'Place XML version'
    $items = @($xml.SelectNodes('//Item'))
    Check-Mayhem ($items.Count -eq $model.Entries.Count) 'Place contains every mapped instance'
    foreach ($entry in $model.Entries) {
        $parts = $entry.LogicalPath.Split('.')
        $cursor = $xml.DocumentElement
        foreach ($part in $parts) {
            $cursor = @($cursor.SelectNodes('Item') | Where-Object { $_.SelectSingleNode('Properties/string[@name="Name"]').InnerText -eq $part }) | Select-Object -First 1
            if (-not $cursor) { break }
        }
        $item = $cursor
        Check-Mayhem ($null -ne $item -and $item.GetAttribute('class') -eq $entry.Class) "Place class and path: $($entry.LogicalPath)"
        if ($entry.Source -and $item) {
            $sourceNode = $item.SelectSingleNode('Properties/ProtectedString[@name="Source"]')
            Check-Mayhem ($null -ne $sourceNode -and $sourceNode.InnerText -ceq [IO.File]::ReadAllText($entry.Source)) "Embedded source matches file: $($entry.Name)"
        }
    }
    Check-Mayhem ($manifest.placeSha256 -eq (Get-FileHash -LiteralPath $place -Algorithm SHA256).Hash.ToLowerInvariant()) 'Build manifest place checksum'
    foreach ($source in $manifest.sources) {
        Check-Mayhem ($source.sha256 -eq (Get-FileHash -LiteralPath (Join-Path $projectRoot $source.path) -Algorithm SHA256).Hash.ToLowerInvariant()) "Build manifest source checksum: $($source.path)"
    }
} else { $skipped.Add('Place XML integrity: run scripts/build.ps1 first') }
$luauDirectory = Join-Path $projectRoot ".tools\luau-$($lock.luau.version)"
$compiler = Join-Path $luauDirectory 'luau-compile.exe'
if (Test-Path -LiteralPath $compiler) {
    foreach ($file in $sourceFiles) {
        & $compiler --null $file.FullName
        Check-Mayhem ($LASTEXITCODE -eq 0) "Luau compilation: $($file.Name)"
    }
    & (Join-Path $luauDirectory 'luau.exe') (Join-Path $projectRoot 'tests\run.luau')
    Check-Mayhem ($LASTEXITCODE -eq 0) 'Executable Luau rules tests'
    & (Join-Path $luauDirectory 'luau-analyze.exe') (Join-Path $projectRoot 'src\shared\Config.luau') (Join-Path $projectRoot 'src\shared\Rules.luau') (Join-Path $projectRoot 'src\shared\Protocol.luau') (Join-Path $projectRoot 'tests\RulesCases.luau')
    Check-Mayhem ($LASTEXITCODE -eq 0) 'Engine-independent Luau type analysis'
} else { $skipped.Add('Luau compilation, pure-module type analysis and executable rules tests: portable Luau unavailable') }
$rojo = Join-Path $projectRoot ".tools\rojo-$($lock.rojo.version)\rojo.exe"
if (Test-Path -LiteralPath $rojo) {
    & $rojo sourcemap (Join-Path $projectRoot 'default.project.json') --output (Join-Path $projectRoot 'build\sourcemap.json')
    Check-Mayhem ($LASTEXITCODE -eq 0) 'Rojo configuration and sourcemap'
} else { $skipped.Add('Rojo-native configuration validation and build: portable Rojo unavailable') }
$skipped.Add('Studio multi-client gameplay and full Roblox type analysis: requires accessible Studio')
if ($RequireTools -and (-not (Test-Path -LiteralPath $compiler) -or -not (Test-Path -LiteralPath $rojo))) { $failed.Add('Required portable tools are missing') }
$reportDirectory = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
[ordered]@{ generatedUtc=[DateTime]::UtcNow.ToString('o'); passed=@($passed); failed=@($failed); skipped=@($skipped); studioRuntimeVerified=$false } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportDirectory 'verification.json') -Encoding UTF8
Write-Output "Passed: $($passed.Count), failed: $($failed.Count), skipped categories: $($skipped.Count)"
foreach ($message in $skipped) { Write-Output "SKIP: $message" }
foreach ($message in $failed) { Write-Output "FAIL: $message" }
if ($failed.Count -gt 0) { throw 'Verification failed. See build/verification.json.' }
