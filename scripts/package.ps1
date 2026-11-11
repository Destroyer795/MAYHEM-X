[CmdletBinding()]
param([switch]$Native)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$output = Join-Path $projectRoot 'build'
$metadata = Join-Path $projectRoot '.version-control'
if (-not (Test-Path -LiteralPath (Join-Path $metadata 'HEAD'))) { $metadata = Join-Path $projectRoot '.git' }
function Invoke-MayhemGit {
    $result = & git "--git-dir=$metadata" "--work-tree=$projectRoot" @args
    if ($LASTEXITCODE -ne 0) { throw "Git command failed: $($args -join ' ')" }
    $result
}

if ($Native) { & (Join-Path $PSScriptRoot 'build.ps1') } else { & (Join-Path $PSScriptRoot 'build.ps1') -Offline }
& (Join-Path $PSScriptRoot 'verify.ps1')
$verifiedPath = Join-Path $output 'premium-verification.json'
Copy-Item -LiteralPath (Join-Path $output 'verification.json') -Destination $verifiedPath -Force
$verification = Get-Content -Raw -LiteralPath $verifiedPath | ConvertFrom-Json
try { & (Join-Path $PSScriptRoot 'verify.ps1') -RequireTools } catch {
    $required = Get-Content -Raw -LiteralPath (Join-Path $output 'verification.json') | ConvertFrom-Json
    if (@($required.failed | Where-Object { $_ -ne 'Required portable tools are missing' }).Count -gt 0) { throw }
}
Copy-Item -LiteralPath (Join-Path $output 'verification.json') -Destination (Join-Path $output 'premium-required-tools.json') -Force
Copy-Item -LiteralPath $verifiedPath -Destination (Join-Path $output 'verification.json') -Force

Add-Type -AssemblyName System.IO.Compression.FileSystem
$originalBuilds = @()
$baselineArchive = Join-Path $output 'backups/premium-start-58429c5.zip'
if (Test-Path -LiteralPath $baselineArchive) {
    $archive = [IO.Compression.ZipFile]::OpenRead($baselineArchive)
    try {
        foreach ($relative in @('build/MAYHEM-X.rbxlx','build/MAYHEM-X-Visual.rbxlx')) {
            $entry = $archive.GetEntry($relative)
            if (-not $entry) { throw "Missing baseline build in archive: $relative" }
            $stream = $entry.Open(); $hash = [Security.Cryptography.SHA256]::Create()
            try { $expected = ([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-','').ToLowerInvariant() } finally { $hash.Dispose(); $stream.Dispose() }
            $current = (Get-FileHash -LiteralPath (Join-Path $projectRoot $relative) -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($current -ne $expected) { throw "Original place changed: $relative" }
            $originalBuilds += [ordered]@{ path=$relative; sha256=$current; matchesBaselineArchive=$true }
        }
    } finally { $archive.Dispose() }
}

$audioArchive = Join-Path $output 'MAYHEM-X-Original-Audio.zip'
$audioFiles = @(Get-ChildItem -LiteralPath (Join-Path $output 'audio') -File | Select-Object -ExpandProperty FullName)
Compress-Archive -LiteralPath $audioFiles -DestinationPath $audioArchive -Force
$bundle = Join-Path $output 'MAYHEM-X-premium.bundle'
Invoke-MayhemGit bundle create $bundle --all
Invoke-MayhemGit bundle verify $bundle
Invoke-MayhemGit diff --check

$commits = @()
foreach ($revision in @(Invoke-MayhemGit rev-list --reverse '58429c5..HEAD')) {
    $commits += [ordered]@{
        hash=$revision
        message=(Invoke-MayhemGit show -s --format=%s $revision) -join ''
        files=@(Invoke-MayhemGit diff-tree --no-commit-id --name-only -r $revision)
    }
}
$storage = @()
foreach ($relative in @('src','assets','scripts','tests','.tools',(Split-Path -Leaf $metadata),'build')) {
    $directory = Join-Path $projectRoot $relative
    $measure = $null
    if (Test-Path -LiteralPath $directory) { $measure = Get-ChildItem -LiteralPath $directory -File -Recurse -Force | Measure-Object Length -Sum }
    $storage += [ordered]@{ path=$relative; files=$(if ($measure) { $measure.Count } else { 0 }); bytes=$(if ($measure) { [long]$measure.Sum } else { 0 }) }
}
$artifacts = @()
foreach ($path in @((Join-Path $output 'MAYHEM-X-Premium.rbxlx'),$audioArchive,$bundle,$verifiedPath)) {
    $item = Get-Item -LiteralPath $path
    $artifacts += [ordered]@{ path=$item.Name; bytes=$item.Length; sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
}
$requiredTools = Get-Content -Raw -LiteralPath (Join-Path $output 'premium-required-tools.json') | ConvertFrom-Json
$report = [ordered]@{
    generatedUtc=[DateTime]::UtcNow.ToString('o')
    baseline='58429c5'
    branch=(Invoke-MayhemGit branch --show-current) -join ''
    head=(Invoke-MayhemGit rev-parse HEAD) -join ''
    origin=(Invoke-MayhemGit remote get-url origin) -join ''
    commitCount=$commits.Count
    commits=$commits
    changedFiles=@(Invoke-MayhemGit diff --name-status '58429c5..HEAD')
    uncommitted=@(Invoke-MayhemGit status --porcelain)
    verification=[ordered]@{ structuralPassed=$verification.passed.Count; failed=$verification.failed; skipped=$verification.skipped; requiredToolsFailures=$requiredTools.failed; studioRuntimeVerified=$false }
    checksByMilestone=@(
        @{milestone='Five authored arenas and shared compiler'; performed='Offline packaging and physical template checks before each map commit'; pending='Studio import, traversal and multiplayer'},
        @{milestone='Voting and gameplay integration'; performed='Source preservation, remote wiring and offline build'; pending='Luau rule execution and Studio interactions'},
        @{milestone='UI and client presentation'; performed='Callback/page/reference checks and embedded-source integrity'; pending='Rendered layout, input, device and frame-time review'},
        @{milestone='Original audio'; performed='174 PCM, level, waveform-edge, checksum and route assertions'; pending='Listening, manual upload, moderation, permissions and playback'},
        @{milestone='Map hardening'; performed='2201 generated-geometry assertions, including spawn/weapon/duel support and spawn clearance'; pending='Actual Studio raycasts, character collision and moving-platform latency'}
    )
    originalBuilds=$originalBuilds
    dependenciesInstalled=@()
    storageMeasuredBeforeReportWrite=$true
    storage=$storage
    artifacts=$artifacts
    commands=@('scripts/build.ps1 (offline by default, native with -Native)','scripts/verify.ps1','scripts/verify.ps1 -RequireTools','git diff --check','git bundle create --all','git bundle verify','Compress-Archive (original audio)','Baseline ZIP SHA-256 comparison')
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'premium-git-report.json') -Encoding UTF8
Write-Output "Packaged Premium place, original audio and source/history bundle. Commits: $($commits.Count). Studio acceptance remains pending."
