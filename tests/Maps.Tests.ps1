$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$reports = @(Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'build/generated/maps.json') | ConvertFrom-Json)
$checks=0
foreach ($map in $reports) {
    $path=Join-Path $projectRoot "build/generated/Maps/$($map.id).rbxmx"
    $xml=[xml][IO.File]::ReadAllText($path)
    $model=$xml.roblox.Item
    $names=@($model.SelectNodes('.//Item') | ForEach-Object { ($_.ParentNode.GetAttribute('referent')) + '/' + $_.SelectSingleNode('Properties/string[@name="Name"]').InnerText })
    if (($names | Sort-Object -Unique).Count -ne $names.Count) { throw "Duplicate child names in $($map.id)" }
    $spawns=@($model.SelectNodes('Item[Properties/string[@name="Name"]="Spawns"]/Item'))
    if ($spawns.Count -ne 16) { throw "Invalid spawn count: $($map.id)" }
    foreach ($spawn in $spawns) {
        $frame=$spawn.Properties.CoordinateFrame
        if ([math]::Abs([double]$frame.X) -gt 140 -or [math]::Abs([double]$frame.Z) -gt 140 -or [double]$frame.Y -gt 75) { throw "Spawn outside arena bounds: $($map.id)" }
        $checks++
    }
    if (@($model.SelectNodes('Item[Properties/string[@name="Name"]="WeaponSpawns"]/Item')).Count -lt 4) { throw 'Missing weapon locations' }
    if (@($model.SelectNodes('Item[Properties/string[@name="Name"]="DuelSpawns"]/Item')).Count -ne 2) { throw 'Missing duel locations' }
    $parts=@($model.SelectNodes('.//Item[@class="Part"]'))
    if ($parts.Count -gt 500) { throw "Map part budget exceeded: $($map.id)" }
    foreach ($part in $parts) {
        $size=$part.SelectSingleNode('Properties/Vector3[@name="Size"]')
        if ([double]$size.X -le 0 -or [double]$size.Y -le 0 -or [double]$size.Z -le 0) { throw 'Invalid physical dimensions' }
        if ($part.SelectSingleNode('Properties/bool[@name="Anchored"]').InnerText -ne 'true') { throw 'Map templates must start anchored' }
        $checks++
    }
    $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $map.templateSha256) { throw 'Map template hash is stale' }
    $checks+=5
}
Write-Output "PASS: $checks physical-map checks across $($reports.Count) generated templates (Studio physics pending)"
