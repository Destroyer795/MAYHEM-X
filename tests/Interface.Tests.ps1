$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $projectRoot 'src\client'
$bootstrap = [IO.File]::ReadAllText((Join-Path $clientRoot 'Bootstrap.client.luau'))
$menus = [IO.File]::ReadAllText((Join-Path $clientRoot 'Menus.luau'))
$menus += [IO.File]::ReadAllText((Join-Path $clientRoot 'MenuLayout.luau'))
$menus += [IO.File]::ReadAllText((Join-Path $clientRoot 'ArmoryPanel.luau'))
$menus += [IO.File]::ReadAllText((Join-Path $clientRoot 'CollectionPanel.luau'))
$menus += [IO.File]::ReadAllText((Join-Path $clientRoot 'DailyCachePanel.luau'))
$hud = [IO.File]::ReadAllText((Join-Path $clientRoot 'Hud.luau'))
$scene = [IO.File]::ReadAllText((Join-Path $projectRoot 'src\server\SceneService.luau'))
$effects = [IO.File]::ReadAllText((Join-Path $clientRoot 'Effects.luau'))
$checks = 0
foreach ($name in @([regex]::Matches($menus + $hud, '\bcallbacks\.(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    $inline = $bootstrap -match "(?m)^\s+$name\s*=\s*function"
    $named = [regex]::Match($bootstrap, "(?m)^\s+$name\s*=\s*(\w+),")
    $resolved = $named.Success -and $bootstrap -match ('local function ' + [regex]::Escape($named.Groups[1].Value) + '\(')
    if (-not $inline -and -not $resolved) { throw "Missing interface callback: $name" }
    $checks++
}
$pages = @([regex]::Matches($menus, 'page\("(\w+)"\)') | ForEach-Object { $_.Groups[1].Value })
foreach ($name in @([regex]::Matches($menus + $hud, '(?:self:open|self:openPage)\("(\w+)"\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    if ($pages -notcontains $name) { throw "Missing menu destination: $name" }
    $checks++
}
foreach ($name in @('Matchmaking','Maps','Armory','Shop','Daily','Settings')) {
    if ($pages -notcontains $name -or $scene -notmatch ('"' + $name + '"')) { throw "World terminal is not connected: $name" }
    $checks++
}
foreach ($name in @([regex]::Matches($bootstrap, '\bhud:(\w+)\(') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    if ($hud -notmatch "function Hud\.$name\(") { throw "Missing HUD API: $name" }
    $checks++
}
$config = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'default.project.json') | ConvertFrom-Json
if ($config.tree.ReplicatedStorage.Mayhem.Presentation.'$className' -ne 'RemoteEvent') { throw 'Presentation remote is missing' }
$checks++
foreach ($name in @([regex]::Matches($bootstrap, 'effects:play\("(\w+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    if ($effects -notmatch ('kind == "' + $name + '"')) { throw "Missing visual effect handler: $name" }
    $checks++
}
$serverText = (Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src/server') -Filter '*.luau' | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
foreach ($name in @([regex]::Matches($serverText, '(?:FireAllClients\(|FireClient\(\w+,\s*)"(\w+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    $client = if ($name -in @('Hit','Notice')) { $bootstrap } else { $effects }
    if ($client -notmatch ('kind == "'+$name+'"')) { throw "Server effect has no client handler: $name" }
    $checks++
}
$mapRules = [IO.File]::ReadAllText((Join-Path $projectRoot 'src/shared/MapRules.luau'))
$commands = [regex]::Match($mapRules,'Command = table\.freeze\(\{([^}]+)\}').Groups[1].Value
if ([regex]::Matches($commands,'\b(\w+)\s*=\s*"(\w+)"').Count -ne 2) { throw 'Two map/gameplay commands must be declared' }
foreach ($match in [regex]::Matches($commands,'\b(\w+)\s*=\s*"(\w+)"')) {
    $name = $match.Groups[1].Value
    if ($bootstrap -notmatch [regex]::Escape('MapRules.Command.'+$name) -or $serverText -notmatch [regex]::Escape('action == MapRules.Command.'+$name)) { throw "Unconnected map/gameplay command: $name" }
    $checks++
}
$manifest = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'build/audio/manifest.json') | ConvertFrom-Json
foreach ($name in @([regex]::Matches($bootstrap,'audio:play\("(\w+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    if ($manifest.files.id -notcontains $name) { throw "Audio cue has no original replacement file: $name" }
    $checks++
}
Write-Output "PASS: $checks interface callback, navigation and presentation wiring checks"
