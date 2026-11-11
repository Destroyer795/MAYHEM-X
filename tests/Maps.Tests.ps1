$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$reports = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'build/generated/maps.json') | ConvertFrom-Json
if ($reports.Count -ne 5 -or (@($reports.id | Sort-Object -Unique)).Count -ne 5) { throw 'Exactly five distinct maps must package' }
if (-not ('MayhemMapGeometry' -as [type])) {
    Add-Type -ReferencedAssemblies 'System.Xml','System' -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Xml;
public static class MayhemMapGeometry {
    class Box { public double[] p, s, r; public bool solid; public string name; }
    static double D(XmlNode n, string path) { return double.Parse(n.SelectSingleNode(path).InnerText, CultureInfo.InvariantCulture); }
    static double[] Point(XmlNode n) { return new[] { D(n,"X"),D(n,"Y"),D(n,"Z") }; }
    static double Trace(Box box, double[] point, double[] direction, double range) {
        double near=0, far=range;
        for(int axis=0;axis<3;axis++) {
            double origin=0, delta=0;
            for(int row=0;row<3;row++) { origin+=box.r[row*3+axis]*(point[row]-box.p[row]); delta+=box.r[row*3+axis]*direction[row]; }
            if(Math.Abs(delta)<0.000001) { if(Math.Abs(origin)>box.s[axis]/2) return double.PositiveInfinity; }
            else {
                double a=(-box.s[axis]/2-origin)/delta, b=(box.s[axis]/2-origin)/delta;
                near=Math.Max(near,Math.Min(a,b)); far=Math.Min(far,Math.Max(a,b));
                if(near>far) return double.PositiveInfinity;
            }
        }
        return near;
    }
    public static int Validate(XmlNode model, string id) {
        var boxes=new List<Box>(); int checks=0;
        foreach(XmlNode item in model.SelectNodes(".//Item[@class='Part']")) {
            XmlNode props=item.SelectSingleNode("Properties"), frame=props.SelectSingleNode("CoordinateFrame[@name='CFrame']");
            var box=new Box { p=Point(frame),s=Point(props.SelectSingleNode("Vector3[@name='size']")),r=new double[9],solid=props.SelectSingleNode("bool[@name='CanCollide']").InnerText=="true",name=props.SelectSingleNode("string[@name='Name']").InnerText };
            for(int a=0;a<3;a++) for(int b=0;b<3;b++) box.r[a*3+b]=D(frame,"R"+a+b);
            for(int a=0;a<3;a++) for(int b=0;b<3;b++) {
                double dot=0; for(int row=0;row<3;row++) dot+=box.r[row*3+a]*box.r[row*3+b];
                if(Math.Abs(dot-(a==b?1:0))>0.00001) throw new Exception(id+" invalid rotation: "+box.name);
            }
            if(!box.solid && props.SelectSingleNode("bool[@name='CanQuery']").InnerText!="false") throw new Exception(id+" nonphysical art must not intercept shots");
            boxes.Add(box); checks++;
        }
        foreach(string group in new[] {"Spawns","DuelSpawns","WeaponSpawns"}) {
            foreach(XmlNode value in model.SelectNodes("Item[Properties/string[@name='Name']='"+group+"']/Item")) {
                double[] point=Point(value.SelectSingleNode("Properties/CoordinateFrame[@name='Value']"));
                double floor=double.PositiveInfinity;
                foreach(Box box in boxes) if(box.solid) floor=Math.Min(floor,Trace(box,point,new double[]{0,-1,0},8));
                if(double.IsInfinity(floor) || floor<(group=="WeaponSpawns"?0.5:3)) throw new Exception(id+" unsupported/embedded "+group+": "+string.Join(",",point));
                if(group!="WeaponSpawns") {
                    foreach(Box box in boxes) if(box.solid) {
                        if(!double.IsInfinity(Trace(box,point,new double[]{0,1,0},2.8))) throw new Exception(id+" obstructed spawn headroom at "+string.Join(",",point));
                        foreach(double[] dir in new[] {new double[]{1,0,0},new double[]{-1,0,0},new double[]{0,0,1},new double[]{0,0,-1}})
                            if(!double.IsInfinity(Trace(box,point,dir,1.2))) throw new Exception(id+" obstructed spawn body at "+string.Join(",",point));
                    }
                }
                checks++;
            }
        }
        return checks;
    }
}
'@
}
$checks=0
foreach ($map in $reports) {
    $path=Join-Path $projectRoot "build/generated/Maps/$($map.id).rbxmx"
    $xml=[xml][IO.File]::ReadAllText($path)
    $model=$xml.roblox.Item
    $checks += [MayhemMapGeometry]::Validate($model,$map.id)
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
        $size=$part.SelectSingleNode('Properties/Vector3[@name="size"]')
        if ([double]$size.X -le 0 -or [double]$size.Y -le 0 -or [double]$size.Z -le 0) { throw 'Invalid physical dimensions' }
        if ($part.SelectSingleNode('Properties/bool[@name="Anchored"]').InnerText -ne 'true') { throw 'Map templates must start anchored' }
        $color=$part.SelectSingleNode('Properties/Color3uint8[@name="Color3uint8"]')
        if (-not $color -or [long]$color.InnerText -lt 0 -or [long]$color.InnerText -gt 16777215) { throw 'Map color must use the canonical packed RGB property' }
        if ($part.SelectSingleNode('Properties/token[@name="shape"]').InnerText -ne '1' -or $part.SelectSingleNode('Properties/token[@name="formFactorRaw"]').InnerText -ne '3') { throw 'Map parts must preserve block shape and custom dimensions' }
        $checks++
    }
    $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $map.templateSha256) { throw 'Map template hash is stale' }
    $checks+=5
}
Write-Output "PASS: $checks physical-map checks across $($reports.Count) generated templates (Studio physics pending)"
