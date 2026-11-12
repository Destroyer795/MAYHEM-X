$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'assets/art/manifest.json') | ConvertFrom-Json
$document = [xml][IO.File]::ReadAllText((Join-Path $projectRoot 'assets/art/Library.rbxmx'))
$models = @($document.SelectNodes('/roblox/Item/Item'))
if ($models.Count -ne $manifest.models.Count -or $models.Count -lt 10) { throw 'Original art model inventory is incomplete' }
$checks = 1
foreach ($entry in $manifest.models) {
    $model = @($models | Where-Object { $_.Properties.string.InnerText -eq $entry.key })
    $hasAssetId = $entry.assetId -match '^[1-9]\d*$'
    $recovered = $entry.PSObject.Properties['recoveredFrom'] -and $entry.recoveredFrom
    if ($model.Count -ne 1 -or (-not $hasAssetId -and -not $recovered) -or -not $entry.generationId) { throw "Invalid original asset attribution: $($entry.key)" }
    $parts = @($model[0].SelectNodes("Item[@class='MeshPart']"))
    if ($parts.Count -lt 1) { throw "Missing mesh geometry: $($entry.key)" }
    $checks += 2
    foreach ($part in $parts) {
        foreach ($name in @('MeshId','TextureID')) {
            if ($part.SelectSingleNode("Properties/Content[@name='$name']/url").InnerText -notmatch '^rbxassetid://[1-9]\d*$') { throw "Invalid art content URI: $($entry.key)/$name" }
            $checks++
        }
        foreach ($name in @('CanCollide','CanQuery','CanTouch')) {
            if ($part.SelectSingleNode("Properties/bool[@name='$name']").InnerText -ne 'false') { throw "Art cannot alter combat collision: $($entry.key)/$name" }
            $checks++
        }
        foreach ($axis in @('X','Y','Z')) {
            $size = [double]::Parse($part.SelectSingleNode("Properties/Vector3[@name='size']/$axis").InnerText, [Globalization.CultureInfo]::InvariantCulture)
            if ($size -le 0 -or [double]::IsNaN($size) -or [double]::IsInfinity($size)) { throw "Invalid mesh dimensions: $($entry.key)" }
            $checks++
        }
    }
}
Write-Output "PASS: $checks original mesh inventory, attribution, URI, dimensions and collision checks (static only)"
