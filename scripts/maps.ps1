$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$output = Join-Path $projectRoot 'build/generated'
New-Item -ItemType Directory -Path (Join-Path $output 'Maps') -Force | Out-Null
$materials = @{ SmoothPlastic=272; Neon=288; Wood=512; Marble=784; Slate=800; Concrete=816; Metal=1088; Sand=1296; Grass=1280; Snow=1328; Ice=1536; Glass=1568 }
$catalog = [Collections.Generic.List[object]]::new()
$reports = [Collections.Generic.List[object]]::new()
$culture = [Globalization.CultureInfo]::InvariantCulture
function N($number) { return ([double]$number).ToString('0.######',$culture) }
function Lua-Value($value) {
    if ($null -eq $value) { return 'nil' }
    if ($value -is [string]) { return ($value | ConvertTo-Json -Compress) }
    if ($value -is [bool]) { return $value.ToString().ToLowerInvariant() }
    if ($value -is [ValueType]) { return (N $value) }
    if ($value -is [array] -or $value -is [Collections.IList]) { return '{' + (($value | ForEach-Object { Lua-Value $_ }) -join ',') + '}' }
    return '{' + (($value.PSObject.Properties | ForEach-Object { '[' + (Lua-Value $_.Name) + ']=' + (Lua-Value $_.Value) }) -join ',') + '}'
}
function Property($node, [string]$name, $fallback) {
    $entry = $node.PSObject.Properties[$name]
    if ($entry) { return ,$entry.Value }
    return ,$fallback
}
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/maps') -Filter '*.json' | Sort-Object Name) {
    $map = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
    $parts = [Collections.Generic.List[object]]::new()
    function Add-MapPart([string]$name, $size, $position, [double]$yaw, [string]$group, [string]$color, [string]$material='SmoothPlastic', [double]$transparency=0, $motion=$null) {
        if (-not $materials.ContainsKey($material)) { throw "Unknown material: $material" }
        $rgb = $map.palette.$color
        $parts.Add([pscustomobject]@{name=($name+'_'+$parts.Count); size=@($size); p=@($position); yaw=$yaw; group=$group; color=@($rgb); material=$material; transparency=$transparency; motion=$motion})
    }
    foreach ($command in $map.geometry) {
        $group = Property $command 'group' 'Solid'
        $name = Property $command 'name' $command.op
        $color = Property $command 'color' 'floor'
        $material = Property $command 'material' 'SmoothPlastic'
        $yaw = [double](Property $command 'yaw' 0)
        switch ($command.op) {
            'box' { Add-MapPart $name $command.size $command.p $yaw $group $color $material (Property $command 'transparency' 0) (Property $command 'motion' $null) }
            'grid' {
                foreach ($x in $command.x) { foreach ($z in $command.z) { Add-MapPart $name $command.size @($x,$command.y,$z) $yaw $group $color $material } }
            }
            'stairs' {
                for ($i=0; $i -lt $command.steps; $i++) {
                    $angle = $yaw * [math]::PI / 180
                    $run = $i * $command.run
                    Add-MapPart 'Stair' @($command.width,1,($command.run + 0.15)) @(($command.p[0] + [math]::Sin($angle) * $run),($command.p[1] + $i * $command.rise),($command.p[2] + [math]::Cos($angle) * $run)) $yaw 'Solid' $color $material
                }
            }
            'spiral' {
                for ($i=0; $i -lt $command.steps; $i++) {
                    $angle = $i * 2 * [math]::PI / $command.steps
                    Add-MapPart 'SpiralStep' @($command.width,0.9,4) @(($command.p[0] + [math]::Cos($angle)*$command.radius),($command.p[1]+$i*$command.rise),($command.p[2]+[math]::Sin($angle)*$command.radius)) (-$angle*180/[math]::PI) 'Solid' $color $material
                }
            }
            'bridge' {
                $dx=$command.b[0]-$command.a[0]; $dy=$command.b[1]-$command.a[1]; $dz=$command.b[2]-$command.a[2]
                $length=[math]::Sqrt($dx*$dx+$dy*$dy+$dz*$dz)
                $partYaw=[math]::Atan2($dx,$dz)*180/[math]::PI
                $middle=@((($command.a[0]+$command.b[0])/2),(($command.a[1]+$command.b[1])/2),(($command.a[2]+$command.b[2])/2))
                Add-MapPart $name @($command.width,2,$length) $middle $partYaw $group $color $material
                $parts[$parts.Count-1] | Add-Member -NotePropertyName pitch -NotePropertyValue (-[math]::Atan2($dy,[math]::Sqrt($dx*$dx+$dz*$dz)))
            }
            'palms' {
                foreach ($location in $command.locations) {
                    Add-MapPart 'PalmTrunk' @(2,14,2) @($location[0],($location[1]+7),$location[2]) 0 'Decor' 'bark' 'Wood'
                    for ($i=0; $i -lt 5; $i++) { Add-MapPart 'PalmFrond' @(13,0.7,3.5) @($location[0],($location[1]+14),$location[2]) ($i*36) 'Decor' 'green' 'Grass' }
                    Add-MapPart 'FernCover' @(6,3,5) @($location[0],($location[1]+1.5),$location[2]) 20 'Solid' 'green' 'Grass'
                }
            }
            'crystals' {
                foreach ($location in $command.locations) {
                    for ($i=0; $i -lt 3; $i++) { Add-MapPart 'Crystal' @(2,(5+$i*3),2) @(($location[0]+($i-1)*2.5),($location[1]+(5+$i*3)/2),$location[2]) ($i*35) 'Solid' $color 'Ice' }
                }
            }
            'ring' {
                for ($i=0; $i -lt $command.count; $i++) {
                    $angle=$i*2*[math]::PI/$command.count
                    Add-MapPart $name @((2*$command.radius*[math]::Sin([math]::PI/$command.count)*0.9),0.15,0.35) @(($command.p[0]+[math]::Sin($angle)*$command.radius),$command.p[1],($command.p[2]+[math]::Cos($angle)*$command.radius)) ($angle*180/[math]::PI) 'Decor' $color 'Neon'
                }
            }
            default { throw "Unsupported map command: $($command.op)" }
        }
    }
    foreach ($spawn in $map.spawns) {
        $floor = @($parts | Where-Object { $_.group -in @('Solid','Ice') -and [math]::Abs($spawn[0]-$_.p[0]) -le $_.size[0]/2 -and [math]::Abs($spawn[2]-$_.p[2]) -le $_.size[2]/2 -and ($_.p[1]+$_.size[1]/2) -lt $spawn[1] } | Sort-Object { $_.p[1]+$_.size[1]/2 } -Descending | Select-Object -First 1)
        if ($floor.Count -ne 1) { throw "$($map.id) spawn has no support: $spawn" }
        $top = $floor[0].p[1]+$floor[0].size[1]/2
        if ($spawn[1]-$top -lt 3 -or $spawn[1]-$top -gt 6) { throw "$($map.id) spawn clearance invalid: $spawn" }
        Add-MapPart 'InsertionPad' @(5,0.12,5) @($spawn[0],($top+0.07),$spawn[2]) 0 'Decor' 'accent' 'Neon'
    }
    Add-MapPart 'DuelFloor' @(64,3,64) @(0,28,-230) 0 'Duel' 'floor' 'SmoothPlastic'
    Add-MapPart 'DuelCover' @(5,3,5) @(-12,31,-240) 0 'Duel' 'wall' 'Metal'
    Add-MapPart 'DuelCover' @(5,3,5) @(12,31,-220) 0 'Duel' 'wall' 'Metal'
    if ($map.spawns.Count -ne 16) { throw "$($map.id) requires sixteen spawns" }
    $settings=[Xml.XmlWriterSettings]::new(); $settings.Indent=$true; $settings.Encoding=[Text.UTF8Encoding]::new($false)
    $writer=[Xml.XmlWriter]::Create((Join-Path $output "Maps/$($map.id).rbxmx"),$settings)
    $serial=0
    function Start-Item([string]$class,[string]$name) {
        $script:serial++
        $writer.WriteStartElement('Item'); $writer.WriteAttributeString('class',$class); $writer.WriteAttributeString('referent',"RBXM$serial")
        $writer.WriteStartElement('Properties'); $writer.WriteStartElement('string'); $writer.WriteAttributeString('name','Name'); $writer.WriteString($name); $writer.WriteEndElement()
    }
    function Scalar([string]$type,[string]$name,$value) { $writer.WriteStartElement($type); $writer.WriteAttributeString('name',$name); $writer.WriteString([string]$value); $writer.WriteEndElement() }
    function Vector([string]$name,$value) {
        $writer.WriteStartElement('Vector3'); $writer.WriteAttributeString('name',$name)
        for ($i=0;$i -lt 3;$i++) { $writer.WriteElementString(@('X','Y','Z')[$i],(N $value[$i])) }; $writer.WriteEndElement()
    }
    function Frame([string]$name,$position,[double]$yaw,[double]$pitch=0) {
        $a=$yaw*[math]::PI/180; $c=[math]::Cos($a); $s=[math]::Sin($a); $cp=[math]::Cos($pitch); $sp=[math]::Sin($pitch)
        $matrix=@($c,($s*$sp),($s*$cp),0,$cp,(-$sp),(-$s),($c*$sp),($c*$cp))
        $writer.WriteStartElement('CoordinateFrame'); $writer.WriteAttributeString('name',$name)
        for($i=0;$i -lt 3;$i++) { $writer.WriteElementString(@('X','Y','Z')[$i],(N $position[$i])) }
        for($i=0;$i -lt 9;$i++) { $writer.WriteElementString(('R'+[math]::Floor($i/3)+($i%3)),(N $matrix[$i])) }; $writer.WriteEndElement()
    }
    function Value-Item([string]$class,[string]$name,[string]$type,$value) { Start-Item $class $name; Scalar $type 'Value' $value; $writer.WriteEndElement(); $writer.WriteEndElement() }
    try {
        $writer.WriteStartDocument(); $writer.WriteStartElement('roblox'); $writer.WriteAttributeString('version','4')
        Start-Item 'Model' $map.id; $writer.WriteEndElement()
        foreach ($group in @('Solid','Decor','Destructibles','Collapse','Motion','Hazards','Ice','Duel')) {
            Start-Item 'Folder' $group; $writer.WriteEndElement()
            foreach ($part in $parts | Where-Object group -eq $group) {
                Start-Item 'Part' $part.name
                Vector 'Size' $part.size
                Frame 'CFrame' $part.p $part.yaw (Property $part 'pitch' 0)
                Scalar 'bool' 'Anchored' 'true'; Scalar 'bool' 'CanTouch' 'false'
                $solid=$group -notin @('Decor','Hazards')
                Scalar 'bool' 'CanCollide' ($solid.ToString().ToLowerInvariant()); Scalar 'bool' 'CanQuery' ($solid.ToString().ToLowerInvariant())
                Scalar 'bool' 'CastShadow' (($solid -and $part.size[1] -gt 3).ToString().ToLowerInvariant())
                Scalar 'token' 'Material' $materials[$part.material]; Scalar 'token' 'TopSurface' 0; Scalar 'token' 'BottomSurface' 0
                Scalar 'float' 'Transparency' (N $part.transparency)
                $writer.WriteStartElement('Color3'); $writer.WriteAttributeString('name','Color'); for($i=0;$i -lt 3;$i++) { $writer.WriteElementString(@('R','G','B')[$i],(N ($part.color[$i]/255))) }; $writer.WriteEndElement()
                $writer.WriteEndElement()
                if ($part.motion) { Start-Item 'Vector3Value' 'Travel'; Vector 'Value' $part.motion.travel; $writer.WriteEndElement(); $writer.WriteEndElement(); Value-Item 'NumberValue' 'Period' 'double' $part.motion.period }
                $writer.WriteEndElement()
            }
            $writer.WriteEndElement()
        }
        foreach ($definition in @(@('Spawns',$map.spawns),@('WeaponSpawns',$map.weapons),@('DuelSpawns',@(@(-20,33,-230),@(20,33,-230))))) {
            Start-Item 'Folder' $definition[0]; $writer.WriteEndElement(); $index=0
            foreach ($position in $definition[1]) { $index++; Start-Item 'CFrameValue' "Point$index"; $spawnYaw = if ($definition[0] -eq 'DuelSpawns') { if($index -eq 1){-90}else{90} } else {[math]::Atan2($position[0],$position[2])*180/[math]::PI}; Frame 'Value' $position $spawnYaw; $writer.WriteEndElement(); $writer.WriteEndElement() }
            $writer.WriteEndElement()
        }
        $writer.WriteEndElement(); $writer.WriteEndElement(); $writer.WriteEndDocument()
    } finally { $writer.Dispose() }
    $preview=@($parts | Where-Object { $_.group -in @('Solid','Destructibles') -and $_.size[1] -gt 0.5 } | Select-Object -First 110 | ForEach-Object { [pscustomobject]@{size=$_.size; p=$_.p; color=$_.color; yaw=$_.yaw} })
    $catalog.Add([pscustomobject]@{id=$map.id; name=$map.name; subtitle=$map.subtitle; strategy=$map.strategy; palette=$map.palette; lighting=$map.lighting; preview=$preview; hazard=$map.hazard; bounds=145; ceiling=85})
    $reports.Add([pscustomobject]@{id=$map.id; partCount=$parts.Count; spawnCount=$map.spawns.Count; weaponCount=$map.weapons.Count; source=$file.Name; templateSha256=(Get-FileHash -LiteralPath (Join-Path $output "Maps/$($map.id).rbxmx") -Algorithm SHA256).Hash.ToLowerInvariant()})
}
if ($catalog.Count -lt 1) { throw 'No authored maps found' }
$lua = '--!strict' + "`n" + 'return ' + (Lua-Value @($catalog)) + "`n"
[IO.File]::WriteAllText((Join-Path $output 'MapCatalog.luau'),$lua,[Text.UTF8Encoding]::new($false))
@($reports) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'maps.json') -Encoding UTF8
Write-Output "Generated $($catalog.Count) physical map templates"
