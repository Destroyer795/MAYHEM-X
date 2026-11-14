$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$exports = @(@{manifest='manifest.json';output='Library.rbxmx';folder='Art'}, @{manifest='skins.json';output='Skins.rbxmx';folder='Skins'})
$culture = [Globalization.CultureInfo]::InvariantCulture
$settings = [Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [Text.UTF8Encoding]::new($false)
$serial = 0
function Number($value) { ([double]$value).ToString('0.#########', $culture) }
function Scalar($type, $name, $value) {
    $writer.WriteStartElement($type); $writer.WriteAttributeString('name', $name)
    $writer.WriteString([string]$value); $writer.WriteEndElement()
}
function Start-Item($class, $name) {
    $script:serial++
    $writer.WriteStartElement('Item'); $writer.WriteAttributeString('class', $class)
    $writer.WriteAttributeString('referent', "ART$serial")
    $writer.WriteStartElement('Properties'); Scalar 'string' 'Name' $name
}
foreach ($export in $exports) {
$manifestPath=Join-Path $projectRoot ('assets/art/'+$export.manifest)
if (-not (Test-Path -LiteralPath $manifestPath)) { continue }
$manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$destination=Join-Path $projectRoot ('assets/art/'+$export.output)
$writer=[Xml.XmlWriter]::Create($destination,$settings)
try {
    $writer.WriteStartDocument(); $writer.WriteStartElement('roblox'); $writer.WriteAttributeString('version', '4')
    Start-Item 'Folder' $export.folder; $writer.WriteEndElement()
    foreach ($model in $manifest.geometry) {
        if ($model.parts.Count -lt 1) { throw "Empty original mesh model: $($model.name)" }
        Start-Item 'Model' $model.name; $writer.WriteEndElement()
        foreach ($part in $model.parts) {
            if ($part.mesh -notmatch '^rbxassetid://[1-9]\d*$' -or ($part.texture -and $part.texture -notmatch '^rbxassetid://[1-9]\d*$')) { throw "Invalid generated mesh reference: $($model.name)" }
            Start-Item 'MeshPart' $part.name
            $contents = [System.Collections.Generic.List[object]]::new()
            $contents.Add(@('MeshId', $part.mesh))
            if ($part.texture) { $contents.Add(@('TextureID', $part.texture)) }
            foreach ($entry in $contents) {
                $writer.WriteStartElement('Content'); $writer.WriteAttributeString('name', $entry[0])
                $writer.WriteElementString('url', $entry[1]); $writer.WriteEndElement()
            }
            $writer.WriteStartElement('Vector3'); $writer.WriteAttributeString('name', 'size')
            for ($i = 0; $i -lt 3; $i++) { $writer.WriteElementString(@('X','Y','Z')[$i], (Number $part.size[$i])) }; $writer.WriteEndElement()
            $writer.WriteStartElement('CoordinateFrame'); $writer.WriteAttributeString('name', 'CFrame')
            $fields = @('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22')
            for ($i = 0; $i -lt 12; $i++) { $writer.WriteElementString($fields[$i], (Number $part.frame[$i])) }; $writer.WriteEndElement()
            foreach ($name in @('Anchored','Massless','DoubleSided')) { Scalar 'bool' $name $(if ($name -eq 'DoubleSided') { $part.doubleSided.ToString().ToLowerInvariant() } else { 'true' }) }
            foreach ($name in @('CanCollide','CanQuery','CanTouch')) { Scalar 'bool' $name 'false' }
            Scalar 'bool' 'CastShadow' 'true'
            Scalar 'token' 'Material' $part.material
            $rgb = [long][Math]::Round($part.color[0]*255)*65536 + [long][Math]::Round($part.color[1]*255)*256 + [long][Math]::Round($part.color[2]*255)
            Scalar 'Color3uint8' 'Color3uint8' $rgb
            $writer.WriteEndElement()
            if ($part.PSObject.Properties['surface'] -and $part.surface) {
                Start-Item 'SurfaceAppearance' 'SurfaceAppearance'
                foreach ($mapName in @('ColorMap','MetalnessMap','RoughnessMap','NormalMap')) {
                    $uri=$part.surface.$mapName
                    if ($uri) {
                        if ($uri -notmatch '^rbxassetid://[1-9]\d*$') { throw "Invalid PBR asset: $($model.name)/$mapName" }
                        $writer.WriteStartElement('Content'); $writer.WriteAttributeString('name',$mapName)
                        $writer.WriteElementString('url',$uri); $writer.WriteEndElement()
                    }
                }
                $writer.WriteEndElement(); $writer.WriteEndElement()
            }
            $writer.WriteEndElement()
        }
        $writer.WriteEndElement()
    }
    $writer.WriteEndElement(); $writer.WriteEndElement(); $writer.WriteEndDocument()
} finally { $writer.Dispose() }
Write-Output "Exported $($manifest.geometry.Count) models to assets/art/$($export.output)"
}
