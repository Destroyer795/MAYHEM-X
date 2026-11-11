$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$audioRoot = Join-Path $projectRoot 'build/audio'
$manifest = Get-Content -Raw -LiteralPath (Join-Path $audioRoot 'manifest.json') | ConvertFrom-Json
if (-not ('MayhemWaveCheck' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class MayhemWaveCheck {
 public static double[] Inspect(string path) {
  byte[] data=File.ReadAllBytes(path);
  if(System.Text.Encoding.ASCII.GetString(data,0,4)!="RIFF"||System.Text.Encoding.ASCII.GetString(data,8,4)!="WAVE") throw new Exception("Invalid WAV container");
  if(BitConverter.ToInt16(data,20)!=1||BitConverter.ToInt16(data,22)!=2||BitConverter.ToInt16(data,34)!=16||BitConverter.ToInt32(data,24)!=44100) throw new Exception("Unexpected PCM format");
  if(BitConverter.ToInt32(data,40)!=data.Length-44) throw new Exception("WAV data length mismatch");
  double peak=0,sum=0; int samples=(data.Length-44)/2;
  for(int i=44;i<data.Length;i+=2) { double sample=BitConverter.ToInt16(data,i)/32768.0; peak=Math.Max(peak,Math.Abs(sample)); sum+=sample*sample; }
  double edge=Math.Max(Math.Abs(BitConverter.ToInt16(data,44)/32768.0),Math.Abs(BitConverter.ToInt16(data,data.Length-2)/32768.0));
  return new double[]{peak,Math.Sqrt(sum/samples),(data.Length-44)/176400.0,edge};
 }
}
'@
}
$checks=0
foreach ($entry in $manifest.files) {
    $path=Join-Path $audioRoot $entry.file
    $stats=[MayhemWaveCheck]::Inspect($path)
    if ($stats[0] -ge 0.95 -or $stats[1] -lt 0.002 -or $stats[2] -le 0.05 -or $stats[2] -gt 60) { throw "Silent, clipped or malformed original audio: $($entry.file)" }
    if ($stats[3] -gt 0.01) { throw "Abrupt waveform edge: $($entry.file)" }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Original audio hash mismatch: $($entry.file)" }
    $checks+=5
}
$config = [IO.File]::ReadAllText((Join-Path $projectRoot 'src/shared/AudioConfig.luau'))
$uploads = [regex]::Match($config,'(?s)AudioConfig.Uploads = table.freeze\(\{(.*?)\}\)').Groups[1].Value
foreach ($entry in $manifest.files) { if ($uploads -notmatch ('\b'+$entry.id+'\s*=')) { throw "Missing upload field: $($entry.id)" }; $checks++ }
if ($manifest.files.Count -ne 29) { throw 'Expected ten original scores/stingers and nineteen effects' }
$mapping = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $projectRoot 'audio-upload/audio-ids.txt')) {
    if ($line -notmatch '^(\w+)\s+([1-9]\d*)$') { throw "Invalid uploaded audio mapping: $line" }
    $name=$Matches[1]; $assetId=$Matches[2]
    if ($mapping.ContainsKey($name) -or $mapping.Values -contains $assetId) { throw "Duplicate uploaded audio route or ID: $name" }
    $mapping[$name]=$assetId
}
if ($mapping.Count -ne 29) { throw 'All twenty-nine uploaded audio routes are required' }
foreach ($entry in $manifest.files) {
    if (-not $mapping.ContainsKey($entry.id) -or $uploads -notmatch ('\b'+$entry.id+'\s*=\s*"rbxassetid://'+$mapping[$entry.id]+'"')) { throw "Uploaded audio route differs from the supplied mapping: $($entry.id)" }
    $checks++
}
Write-Output "PASS: $checks PCM, waveform, checksum and uploaded-ID route checks for 29 original audio files (static checks only)"
