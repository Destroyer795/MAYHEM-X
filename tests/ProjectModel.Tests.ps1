$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $projectRoot 'scripts\ProjectModel.ps1')
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build'))
$fixture = Join-Path $buildRoot ('model-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture 'src') -Force | Out-Null
$checks = 0
function Assert-ModelTest {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks += 1
}
function Write-Fixture {
    param($Tree)
    [ordered]@{ name='Fixture'; tree=$Tree } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $fixture 'default.project.json') -Encoding UTF8
}
function Assert-FixtureRejected {
    param([string]$Expected)
    $message = ''
    try { [void](Get-MayhemProjectModel -ProjectRoot $fixture) } catch { $message = $_.Exception.Message }
    Assert-ModelTest ($message -like "*$Expected*") "Expected rejection containing: $Expected, actual: $message"
}
try {
    foreach ($name in @('Boot.server.luau','Input.client.luau','Rules.luau')) { '--!strict' | Set-Content -LiteralPath (Join-Path $fixture "src\$name") -Encoding UTF8 }
    Write-Fixture ([ordered]@{ '$className'='DataModel'; ServerScriptService=[ordered]@{ '$className'='ServerScriptService'; Code=[ordered]@{ '$path'='src' } } })
    $model = Get-MayhemProjectModel -ProjectRoot $fixture
    Assert-ModelTest ($model.Entries.Count -eq 5) 'Folder mapping must preserve three scripts and both ancestors'
    Assert-ModelTest ($model.SourcePaths.Count -eq 3) 'Every source must be tracked'
    Assert-ModelTest (@($model.Entries | Where-Object { $_.Name -eq 'Boot' -and $_.Class -eq 'Script' }).Count -eq 1) 'Server suffix must map to Script'
    Assert-ModelTest (@($model.Entries | Where-Object { $_.Name -eq 'Input' -and $_.Class -eq 'LocalScript' }).Count -eq 1) 'Client suffix must map to LocalScript'
    Assert-ModelTest (@($model.Entries | Where-Object { $_.Name -eq 'Rules' -and $_.Class -eq 'ModuleScript' }).Count -eq 1) 'Plain source must map to ModuleScript'
    Assert-ModelTest (($model.Entries.LogicalPath | Sort-Object -Unique).Count -eq $model.Entries.Count) 'Generated paths must be unique'
    Write-Fixture ([ordered]@{ '$className'='Folder' })
    Assert-FixtureRejected 'DataModel'
    Write-Fixture ([ordered]@{ '$className'='DataModel'; Code=[ordered]@{ '$path'='missing.luau' } })
    Assert-FixtureRejected 'Missing project path'
    Write-Fixture ([ordered]@{ '$className'='DataModel'; Code=[ordered]@{ '$path'='..\outside.luau' } })
    Assert-FixtureRejected 'escapes project'
    Write-Fixture ([ordered]@{ '$className'='DataModel'; Rules=[ordered]@{ '$path'='src/Rules.luau'; Child=[ordered]@{ '$path'='src/Boot.server.luau' } } })
    $model = Get-MayhemProjectModel -ProjectRoot $fixture
    Assert-ModelTest ($model.Entries.Count -eq 2 -and $model.Entries[1].LogicalPath -eq 'Rules.Child') 'A mapped source must support explicit children'
    '<roblox version="4"><Item class="Folder"><Properties><string name="Name">Art</string></Properties></Item></roblox>' | Set-Content -LiteralPath (Join-Path $fixture 'src/Art.rbxmx') -Encoding UTF8
    Write-Fixture ([ordered]@{ '$className'='DataModel'; Art=[ordered]@{ '$path'='src/Art.rbxmx'; Skins=[ordered]@{ '$path'='src/Rules.luau' } } })
    $model = Get-MayhemProjectModel -ProjectRoot $fixture
    Assert-ModelTest ($model.Entries.Count -eq 2 -and $model.Entries[1].LogicalPath -eq 'Art.Skins' -and $model.Entries[1].Parent -eq $model.Entries[0].Referent) 'XML assets must preserve explicit Rojo children'
    Write-Output "PASS: $checks project model assertions"
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    if (-not $resolvedFixture.StartsWith($buildRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing to clean a fixture outside build/' }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}
