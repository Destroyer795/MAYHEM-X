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
$preservationIssues = [Collections.Generic.List[string]]::new()
$baselineArchive = Join-Path $output 'backups/premium-start-58429c5.zip'
if (Test-Path -LiteralPath $baselineArchive) {
    $archive = [IO.Compression.ZipFile]::OpenRead($baselineArchive)
    try {
        foreach ($relative in @('build/MAYHEM-X.rbxlx','build/MAYHEM-X-Visual.rbxlx')) {
            $entry = $archive.GetEntry($relative)
            if (-not $entry) { throw "Missing baseline build in archive: $relative" }
            $stream = $entry.Open(); $hash = [Security.Cryptography.SHA256]::Create()
            try { $expected = ([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-','').ToLowerInvariant() } finally { $hash.Dispose(); $stream.Dispose() }
            $current = $null
            $issue = $null
            try { $current = (Get-FileHash -LiteralPath (Join-Path $projectRoot $relative) -Algorithm SHA256).Hash.ToLowerInvariant() }
            catch { $issue = "Cannot read preserved working place: $relative. Its baseline remains in the source/archive backup; inspect the working file manually." }
            if ($current -and $current -ne $expected) { $issue = "Working place differs from its baseline: $relative. Both versions were left untouched." }
            if ($issue) { $preservationIssues.Add($issue); Write-Warning $issue }
            $originalBuilds += [ordered]@{ path=$relative; sha256=$current; archivedSha256=$expected; baselineArchive='build/backups/premium-start-58429c5.zip'; matchesBaselineArchive=$(if ($current) { $current -eq $expected } else { $null }) }
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
$followUpRevisions = @(Invoke-MayhemGit rev-list '09d6b8a..HEAD')
$followUpCommits = @($commits | Where-Object { $followUpRevisions -contains $_.hash })
$premiumBackup = Join-Path $output 'backups/MAYHEM-X-Premium-09d6b8a.rbxlx'
if (Test-Path -LiteralPath $premiumBackup) {
    $expectedPremium = '895ada320118bd32d68c35906b2f83ea5ada716302357d7a605b76e3b8bada55'
    $premiumHash = (Get-FileHash -LiteralPath $premiumBackup -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($premiumHash -ne $expectedPremium) { throw 'The preserved Premium review place changed' }
    $originalBuilds += [ordered]@{ path='build/backups/MAYHEM-X-Premium-09d6b8a.rbxlx'; sha256=$premiumHash; matchesPreviousPackage=$true }
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
    followUpBaseline='09d6b8a'
    followUpCommitCount=$followUpCommits.Count
    followUpCommits=$followUpCommits
    followUpChangedFiles=@(Invoke-MayhemGit diff --name-status '09d6b8a..HEAD')
    changedFiles=@(Invoke-MayhemGit diff --name-status '58429c5..HEAD')
    uncommitted=@(Invoke-MayhemGit status --porcelain)
    verification=[ordered]@{ structuralPassed=$verification.passed.Count; failed=$verification.failed; skipped=$verification.skipped; requiredToolsFailures=$requiredTools.failed; preservationIssues=@($preservationIssues); studioRuntimeVerified=$false }
    checksByMilestone=@(
        @{milestone='Five authored arenas and shared compiler'; performed='Offline packaging and physical template checks before each map commit'; pending='Studio import, traversal and multiplayer'},
        @{milestone='Voting and gameplay integration'; performed='Source preservation, remote wiring and offline build'; pending='Luau rule execution and Studio interactions'},
        @{milestone='UI and client presentation'; performed='Callback/page/reference checks and embedded-source integrity'; pending='Rendered layout, input, device and frame-time review'},
        @{milestone='Original audio'; performed='174 PCM, level, waveform-edge, checksum and route assertions'; pending='Listening, manual upload, moderation, permissions and playback'},
        @{milestone='Map hardening'; performed='2201 generated-geometry assertions, including spawn/weapon/duel support and spawn clearance'; pending='Actual Studio raycasts, character collision and moving-platform latency'},
        @{milestone='Acceptance follow-up'; performed='Offline build, 73 interface wiring checks, twelve text-contrast pairs and baseline preservation'; pending='Luau audio routing cases, Studio device layouts, smooth animation, first-person cosmetics and unavailable-upload playback'}
    )
    originalBuilds=$originalBuilds
    dependenciesInstalled=@()
    storageMeasuredBeforeReportWrite=$true
    storage=$storage
    artifacts=$artifacts
    commands=@('scripts/build.ps1 -Offline','scripts/package.ps1 (offline by default, native with -Native)','scripts/verify.ps1','scripts/verify.ps1 -RequireTools','git diff --check','git bundle create --all','git bundle verify','Compress-Archive (original audio)','Baseline ZIP and preserved Premium SHA-256 comparison')
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'premium-git-report.json') -Encoding UTF8
Write-Output "Packaged Premium place, original audio and source/history bundle. Commits: $($commits.Count). Studio acceptance remains pending."
if ($preservationIssues.Count -gt 0) { Write-Output "Preserved working-place checks requiring manual review: $($preservationIssues.Count). See premium-git-report.json." }
