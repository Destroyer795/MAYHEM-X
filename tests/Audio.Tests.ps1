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
  if(BitConverter.ToInt16(data,20)!=1||BitConverter.ToInt16(data,22)!=2||BitConverter.ToInt16(data,34)!=16||BitConverter.ToInt32(data,24)!=22050) throw new Exception("Unexpected PCM format");
  if(BitConverter.ToInt32(data,40)!=data.Length-44) throw new Exception("WAV data length mismatch");
  double peak=0,sum=0; int samples=(data.Length-44)/2;
  for(int i=44;i<data.Length;i+=2) { double sample=BitConverter.ToInt16(data,i)/32768.0; peak=Math.Max(peak,Math.Abs(sample)); sum+=sample*sample; }
  return new double[]{peak,Math.Sqrt(sum/samples),(data.Length-44)/88200.0};
 }
}
'@
}
$checks=0
foreach ($entry in $manifest.files) {
    $path=Join-Path $audioRoot $entry.file
    $stats=[MayhemWaveCheck]::Inspect($path)
    if ($stats[0] -ge 0.95 -or $stats[1] -lt 0.002 -or $stats[2] -le 0.05 -or $stats[2] -gt 60) { throw "Silent, clipped or malformed original audio: $($entry.file)" }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Original audio hash mismatch: $($entry.file)" }
    $checks+=4
}
$config = [IO.File]::ReadAllText((Join-Path $projectRoot 'src/shared/AudioConfig.luau'))
$uploads = [regex]::Match($config,'(?s)AudioConfig.Uploads = table.freeze\(\{(.*?)\}\)').Groups[1].Value
foreach ($entry in $manifest.files) { if ($uploads -notmatch ('\b'+$entry.id+'\s*=')) { throw "Missing upload field: $($entry.id)" }; $checks++ }
if ($manifest.files.Count -ne 29) { throw 'Expected ten original scores/stingers and nineteen effects' }
Write-Output "PASS: $checks PCM, waveform, checksum and route checks for 29 original audio files (Roblox upload/playback pending)"
