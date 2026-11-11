$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$output = Join-Path $projectRoot 'build/audio'
$scorePath = Join-Path $projectRoot 'assets/audio/scorebook.json'
$score = Get-Content -Raw -LiteralPath $scorePath | ConvertFrom-Json
$stamp = (Get-FileHash -LiteralPath $scorePath -Algorithm SHA256).Hash + (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
$manifestPath = Join-Path $output 'manifest.json'
$uploadedIds = @{}
$mappingPath = Join-Path $projectRoot 'audio-upload/audio-ids.txt'
if (Test-Path -LiteralPath $mappingPath) {
    foreach ($line in Get-Content -LiteralPath $mappingPath) {
        if ($line -notmatch '^(\w+)\s+([1-9]\d*)$' -or $uploadedIds.ContainsKey($Matches[1])) { throw "Invalid or duplicate audio upload entry: $line" }
        $uploadedIds[$Matches[1]]=$Matches[2]
    }
}
function Write-MayhemAudioManifest($data) {
    $enriched = @()
    foreach ($entry in $data.files) {
        $item = $entry | ConvertTo-Json -Depth 4 | ConvertFrom-Json
        $assetId = $uploadedIds[$item.id]
        $item | Add-Member -NotePropertyName assetId -NotePropertyValue $assetId -Force
        $item.uploadRequired = -not $assetId
        $enriched += $item
    }
    $data.files=$enriched
    $data.runtimeUploaded=(@($enriched | Where-Object uploadRequired).Count -eq 0)
    $data | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
}
if (Test-Path -LiteralPath $manifestPath) {
    $prior = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $complete = $true
    foreach ($entry in $prior.files) {
        $path = Join-Path $output $entry.file
        if (-not (Test-Path -LiteralPath $path)) { $complete=$false; continue }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Generated audio was modified: $path. Preserve that edit before rebuilding." }
    }
    if ($complete -and $prior.sourceStamp -eq $stamp) { Write-MayhemAudioManifest $prior; Write-Output 'Original audio pack and upload mapping are current'; return }
}
New-Item -ItemType Directory -Path $output -Force | Out-Null
if (-not ('MayhemComposer' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class MayhemComposer {
    static double F(double midi) { return 440 * Math.Pow(2,(midi-69)/12); }
    static double S(double frequency,double t) { return Math.Sin(2*Math.PI*frequency*t); }
    static double Bell(double frequency,double t,double decay) { return (S(frequency,t)+0.25*S(frequency*2.01,t)+0.08*S(frequency*3.98,t))*Math.Exp(-t*decay); }
    static void Header(BinaryWriter w,int samples,int rate) {
        w.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); w.Write(36+samples*4); w.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt "));
        w.Write(16); w.Write((short)1); w.Write((short)2); w.Write(rate); w.Write(rate*4); w.Write((short)4); w.Write((short)16);
        w.Write(System.Text.Encoding.ASCII.GetBytes("data")); w.Write(samples*4);
    }
    public static void Music(string path,int rate,double bpm,int root,int beats,int mood,int[] notes) {
        double duration=beats*60.0/bpm; int count=(int)(rate*duration); var random=new Random(1000+root*31+mood); int[] progression={0,5,3,7};
        using(var w=new BinaryWriter(File.Create(path))) {
            Header(w,count,rate);
            for(int i=0;i<count;i++) {
                double t=i/(double)rate,beat=t*bpm/60.0,localBeat=beat-Math.Floor(beat),stepTime=60.0/bpm/2;
                int step=(int)Math.Floor(beat*2), chord=progression[((int)beat/8)%4]; double nt=t-step*stepTime;
                double frequency=F(root+12+notes[step%notes.Length]); double arp=Bell(frequency,nt,mood==4?4.2:8.5)*0.19*Math.Min(1,(stepTime-nt)/0.015);
                double chordTime=beat%8,padWindow=Math.Min(1,chordTime/0.3)*Math.Min(1,(8-chordTime)/0.3);
                double pad=(S(F(root-12+chord),t)+S(F(root+chord+7),t)*0.5+S(F(root+chord+((mood==1||mood==2||mood==3||mood==6||mood==7||mood==9)?3:4)),t)*0.35)*0.055*padWindow;
                double kt=localBeat*60/bpm;
                double kick=Math.Sin(2*Math.PI*(47*kt+95*(1-Math.Exp(-kt*22))/22))*Math.Exp(-kt*14)*(mood==4?0.05:0.17);
                double noise=random.NextDouble()*2-1, snare=(((int)beat%4==1)||((int)beat%4==3))?noise*Math.Exp(-localBeat*24)*0.075:0;
                double hat=noise*Math.Exp(-nt*90)*(mood==4?0.008:0.025);
                double fade=Math.Min(1,t/0.04)*Math.Min(1,(duration-t)/0.08);
                double common=pad+kick+snare+hat;
                double left=Math.Tanh((common+arp*(0.84+0.16*Math.Sin(step)))*1.4)*0.82*fade;
                double right=Math.Tanh((common+arp*(0.84-0.16*Math.Sin(step)))*1.4)*0.82*fade;
                w.Write((short)(left*32767)); w.Write((short)(right*32767));
            }
        }
    }
    public static void Effect(string path,int rate,string name) {
        bool longSound=name=="Repulse"||name=="Ultimate"||name=="Explosion"||name=="Mutation"||name=="PowerSteal";
        double duration=longSound?1.35:(name=="Reload"?0.85:0.28); int count=(int)(duration*rate),seed=0; foreach(char c in name) seed=seed*17+c;
        var random=new Random(seed); double previous=0;
        using(var w=new BinaryWriter(File.Create(path))) {
            Header(w,count,rate);
            for(int i=0;i<count;i++) {
                double t=i/(double)rate,x=t/duration,noise=random.NextDouble()*2-1; previous=previous*0.8+noise*0.2;
                double value;
                if(name=="Shot"||name=="Impact"||name=="MeleeHit") value=(noise*0.5+S(85,t)*0.6)*Math.Exp(-t*24);
                else if(name=="Explosion") value=(previous*2+S(36,t)*0.4)*Math.Exp(-t*3);
                else if(name=="Slash") value=noise*Math.Sin(Math.PI*x)*0.4;
                else if(name=="Reload"||name=="Switch") value=noise*(Math.Exp(-t*55)+Math.Exp(-Math.Abs(t-0.52)*70))*0.5;
                else if(name=="Repulse"||name=="Ultimate"||name=="Mutation"||name=="PowerSteal") value=(S(90+600*x*x,t)*0.25+Bell(440+440*x,t,2))*Math.Sin(Math.PI*x)*0.4;
                else value=(Bell(name=="Hover"?880:660,t,14)+Bell(name=="Reward"||name=="Purchase"?990:1320,t,18)*0.35)*0.3;
                value=Math.Tanh(value*1.3)*Math.Min(1,t/0.003)*Math.Min(1,(duration-t)/0.02)*0.85;
                short sample=(short)(value*32767); w.Write(sample); w.Write(sample);
            }
        }
    }
}
'@
}
$entries=@()
foreach ($track in $score.tracks) {
    $file="$($track.id).wav"; $path=Join-Path $output $file
    [MayhemComposer]::Music($path,$score.sampleRate,$track.bpm,$track.root,$track.beats,$track.mood,[int[]]$track.notes)
    $entries += [ordered]@{id=$track.id; file=$file; kind='music'; seconds=($track.beats*60/$track.bpm); sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant(); uploadRequired=$true}
}
foreach ($id in $score.effects) {
    $file="SFX-$id.wav"; $path=Join-Path $output $file
    [MayhemComposer]::Effect($path,$score.sampleRate,$id)
    $entries += [ordered]@{id=$id; file=$file; kind='effect'; sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant(); uploadRequired=$true}
}
Write-MayhemAudioManifest ([pscustomobject][ordered]@{sourceStamp=$stamp; license=$score.license; format='Stereo PCM WAV, 44100 Hz, 16 bit'; files=$entries; runtimeUploaded=$false})
Write-Output "Generated $($entries.Count) original WAV files with their supplied Roblox upload IDs"
