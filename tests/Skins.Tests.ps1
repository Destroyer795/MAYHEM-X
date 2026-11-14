$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath (Join-Path $root 'assets/art/skins.json') | ConvertFrom-Json
[xml]$xml = Get-Content -Raw -LiteralPath (Join-Path $root 'assets/art/Skins.rbxmx')
$checks = 0
function Assert-Skin([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
    $script:checks++
}
Assert-Skin ($manifest.models.Count -eq 21 -and $manifest.geometry.Count -eq 21) 'Expected three full collections for seven weapons'
$names = @($manifest.geometry.name)
Assert-Skin (($names | Sort-Object -Unique).Count -eq 21) 'Duplicate variant'
$components = 0
foreach ($collection in @('VoidReaver','Solaris','Frostborn')) {
    foreach ($weapon in @('VectorRifle','NeedleSMG','MantisDMR','BreakerShotgun','RiftBlade','TalonKnife','MaulHammer')) {
        $key = $weapon + '_' + $collection
        $geometry = @($manifest.geometry | Where-Object name -eq $key)
        $source = @($manifest.models | Where-Object key -eq $key)
        Assert-Skin ($geometry.Count -eq 1 -and $source.Count -eq 1) "Missing variant/provenance: $key"
        Assert-Skin ($source[0].generationTag.StartsWith('RBXAI-TexturedMesh-') -and $source[0].prompt.Length -gt 100) "Missing generation provenance: $key"
        foreach ($part in $geometry[0].parts) {
            $components++
            Assert-Skin ($part.mesh -match '^rbxassetid://[1-9]\d*$') "Invalid mesh URI: $key"
            foreach ($map in @('ColorMap','MetalnessMap','RoughnessMap')) {
                Assert-Skin ($part.surface.$map -match '^rbxassetid://[1-9]\d*$') "Missing PBR map: $key/$map"
            }
            Assert-Skin ($part.size.Count -eq 3 -and @($part.size | Where-Object { $_ -le 0 }).Count -eq 0) "Invalid dimensions: $key"
        }
    }
}
Assert-Skin ($components -eq 66) 'Unexpected mesh component count'
Assert-Skin ($xml.SelectNodes('//Item[@class="SurfaceAppearance"]').Count -eq 66) 'Export lost surface maps'
Assert-Skin ($xml.SelectNodes('//Content[@name="ColorMap"]/url').Count -eq 66) 'Export lost color references'
Assert-Skin ($xml.SelectNodes('//Content[@name="RoughnessMap"]/url').Count -eq 66) 'Export lost roughness references'
$config = Get-Content -Raw -LiteralPath (Join-Path $root 'default.project.json') | ConvertFrom-Json
Assert-Skin ($config.tree.ReplicatedStorage.Mayhem.Art.Skins.'$path' -eq 'assets/art/Skins.rbxmx') 'Rojo does not include the skin library'
. (Join-Path $root 'scripts/ProjectModel.ps1')
$project = Get-MayhemProjectModel -ProjectRoot $root
Assert-Skin (@($project.Entries | Where-Object { $_.LogicalPath -like 'ReplicatedStorage.Mayhem.Art.Skins.*' -and $_.Class -eq 'Model' }).Count -eq 21) 'Source snapshot lost nested skin models'
Write-Output "PASS: $checks skin provenance, PBR, dimensions and export checks (static only)"
