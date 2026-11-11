$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = [IO.File]::ReadAllText((Join-Path $projectRoot 'src/shared/Visuals.luau'))
$palette = [regex]::Match($source, '(?s)Visuals.Palette = table.freeze\(\{(.*?)\}\)').Groups[1].Value
$luminance = @{}
foreach ($match in [regex]::Matches($palette, '(\w+)\s*=\s*\{\s*(\d+),\s*(\d+),\s*(\d+)\s*\}')) {
    $linear = @()
    for ($index = 2; $index -le 4; $index++) {
        $channel = [double]$match.Groups[$index].Value / 255
        $linear += $(if ($channel -le 0.04045) { $channel / 12.92 } else { [Math]::Pow(($channel + 0.055) / 1.055, 2.4) })
    }
    $luminance[$match.Groups[1].Value] = 0.2126 * $linear[0] + 0.7152 * $linear[1] + 0.0722 * $linear[2]
}
$checks = 0
foreach ($pair in @(@('White','Action'),@('Ink','Panel'),@('Ink','Surface'),@('Muted','Panel'),@('Muted','Surface'),@('Action','Panel'),@('Action','Surface'),@('White','Void'),@('Metal','Void'),@('Cyan','Void'),@('Gold','Void'),@('Ink','Gold'))) {
    $a = $pair[0]; $b = $pair[1]
    if (-not $luminance.ContainsKey($a) -or -not $luminance.ContainsKey($b)) { throw "Missing text color pair: $a/$b" }
    $ratio = ([Math]::Max($luminance[$a],$luminance[$b]) + 0.05) / ([Math]::Min($luminance[$a],$luminance[$b]) + 0.05)
    if ($ratio -lt 4.5) { throw "Small text contrast is below 4.5:1 for $a/$b, measured $ratio" }
    $checks++
}
Write-Output "PASS: $checks text color pairs meet 4.5:1 contrast (rendered legibility pending)"
