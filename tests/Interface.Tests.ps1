$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $projectRoot 'src\client'
$bootstrap = [IO.File]::ReadAllText((Join-Path $clientRoot 'Bootstrap.client.luau'))
$menus = [IO.File]::ReadAllText((Join-Path $clientRoot 'Menus.luau'))
$hud = [IO.File]::ReadAllText((Join-Path $clientRoot 'Hud.luau'))
$scene = [IO.File]::ReadAllText((Join-Path $projectRoot 'src\server\SceneService.luau'))
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
foreach ($name in @('Matchmaking','Inventory','Shop','Daily','Settings')) {
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
Write-Output "PASS: $checks interface callback, navigation and presentation wiring checks"
