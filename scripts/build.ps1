[CmdletBinding()]
param([switch]$Offline, [ValidatePattern('^[A-Za-z0-9_-]+\.rbxlx$')][string]$OutputName = 'MAYHEM-X-Premium.rbxlx')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'ProjectModel.ps1')
& (Join-Path $PSScriptRoot 'maps.ps1')
& (Join-Path $PSScriptRoot 'audio.ps1')
$model = Get-MayhemProjectModel -ProjectRoot $projectRoot
$outputDirectory = Join-Path $projectRoot 'build'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$place = Join-Path $outputDirectory $OutputName
$lock = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'tools.lock.json') | ConvertFrom-Json
$rojo = Join-Path $projectRoot ".tools\rojo-$($lock.rojo.version)\rojo.exe"
$builder = 'offline-xml'
if (-not $Offline) {
    if (-not (Test-Path -LiteralPath $rojo)) { throw 'Run scripts/setup.ps1 first, or use scripts/build.ps1 -Offline for XML packaging without Rojo.' }
    $builder = "rojo-$($lock.rojo.version)"
    & $rojo build (Join-Path $projectRoot 'default.project.json') --output $place
    if ($LASTEXITCODE -ne 0) { throw "Rojo build failed with exit code $LASTEXITCODE" }
    & $rojo sourcemap (Join-Path $projectRoot 'default.project.json') --output (Join-Path $outputDirectory 'sourcemap.json')
    if ($LASTEXITCODE -ne 0) { throw "Rojo sourcemap failed with exit code $LASTEXITCODE" }
} else {
    $settings = [Xml.XmlWriterSettings]::new()
    $settings.Indent = $true
    $settings.Encoding = [Text.UTF8Encoding]::new($false)
    $settings.NewLineHandling = [Xml.NewLineHandling]::None
    $writer = [Xml.XmlWriter]::Create($place, $settings)
    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $orientationTokens = @{ LandscapeLeft=0; LandscapeRight=1; LandscapeSensor=2; Portrait=3; Sensor=4 }
    function Write-MayhemItem {
        param($Entry)
        $writer.WriteStartElement('Item')
        $writer.WriteAttributeString('class', $Entry.Class)
        $writer.WriteAttributeString('referent', $Entry.Referent)
        $writer.WriteStartElement('Properties')
        $writer.WriteStartElement('string'); $writer.WriteAttributeString('name','Name'); $writer.WriteString($Entry.Name); $writer.WriteEndElement()
        if ($Entry.XmlProperties) { foreach ($property in $Entry.XmlProperties.ChildNodes) { if ($property.GetAttribute('name') -ne 'Name') { $property.WriteTo($writer) } } }
        if ($Entry.Source) {
            $writer.WriteStartElement('ProtectedString'); $writer.WriteAttributeString('name','Source')
            $writer.WriteString([IO.File]::ReadAllText($Entry.Source)); $writer.WriteEndElement()
        }
        if ($Entry.Properties) {
            foreach ($property in $Entry.Properties.PSObject.Properties) {
                $value = $property.Value
                if ($property.Name -in @('Ambient','OutdoorAmbient')) {
                    if ($value.Count -ne 3) { throw "Invalid Color3 property: $($property.Name)" }
                    $writer.WriteStartElement('Color3'); $writer.WriteAttributeString('name',$property.Name)
                    for ($index=0; $index -lt 3; $index++) { $writer.WriteElementString(@('R','G','B')[$index], ([double]$value[$index]).ToString('R',$invariant)) }
                    $writer.WriteEndElement()
                } elseif ($property.Name -eq 'ScreenOrientation' -and $value -is [string] -and $orientationTokens.ContainsKey($value)) {
                    $writer.WriteStartElement('token'); $writer.WriteAttributeString('name',$property.Name)
                    $writer.WriteString([string]$orientationTokens[$value]); $writer.WriteEndElement()
                } elseif ($value -is [bool]) {
                    $writer.WriteStartElement('bool'); $writer.WriteAttributeString('name',$property.Name)
                    $writer.WriteString($value.ToString().ToLowerInvariant()); $writer.WriteEndElement()
                } elseif ($value -is [ValueType]) {
                    $writer.WriteStartElement('float'); $writer.WriteAttributeString('name',$property.Name)
                    $writer.WriteString(([double]$value).ToString('R',$invariant)); $writer.WriteEndElement()
                } else { throw "Unsupported property in offline builder: $($property.Name)" }
            }
        }
        $writer.WriteEndElement()
        foreach ($child in $model.Entries) { if ($child.Parent -eq $Entry.Referent) { Write-MayhemItem $child } }
        $writer.WriteEndElement()
    }
    try {
        $writer.WriteStartDocument()
        $writer.WriteStartElement('roblox'); $writer.WriteAttributeString('version','4')
        $writer.WriteElementString('External','null'); $writer.WriteElementString('External','nil')
        foreach ($entry in $model.Entries) { if (-not $entry.Parent) { Write-MayhemItem $entry } }
        $writer.WriteEndElement(); $writer.WriteEndDocument()
    } finally { $writer.Dispose() }
}
$sources = @($model.Entries | Where-Object Source | ForEach-Object {
    [ordered]@{ instance=$_.LogicalPath; path=$_.Source.Substring($projectRoot.Length + 1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.Source -Algorithm SHA256).Hash.ToLowerInvariant() }
})
[ordered]@{
    builder=$builder; generatedUtc=[DateTime]::UtcNow.ToString('o'); place=$OutputName;
    placeSha256=(Get-FileHash -LiteralPath $place -Algorithm SHA256).Hash.ToLowerInvariant();
    instanceCount=$model.Entries.Count; sourceCount=$sources.Count; sources=$sources;
    studioRuntimeVerified=$false
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $outputDirectory 'manifest.json') -Encoding UTF8
Write-Output "Built $place using $builder ($($sources.Count) sources). Studio import and gameplay testing are still required."
