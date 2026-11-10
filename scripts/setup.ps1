[CmdletBinding()]
param([switch]$RojoOnly)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$lock = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'tools.lock.json') | ConvertFrom-Json
$toolRoot = Join-Path $projectRoot '.tools'
New-Item -ItemType Directory -Path $toolRoot -Force | Out-Null
$names = if ($RojoOnly) { @('rojo') } else { @('rojo','luau') }
foreach ($name in $names) {
    $tool = $lock.$name
    $destination = Join-Path $toolRoot "$name-$($tool.version)"
    $receipt = Join-Path $destination 'receipt.json'
    $complete = Test-Path -LiteralPath $receipt
    foreach ($exe in $tool.executables) {
        $complete = $complete -and (Test-Path -LiteralPath (Join-Path $destination $exe))
    }
    if ($complete) {
        $existing = Get-Content -Raw -LiteralPath $receipt | ConvertFrom-Json
        $complete = $existing.archiveSha256 -eq $tool.sha256
        foreach ($entry in $existing.files) {
            $exePath = Join-Path $destination $entry.name
            $complete = $complete -and (Test-Path -LiteralPath $exePath)
            if ($complete) { $complete = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $entry.sha256 }
        }
    }
    if ($complete) { Write-Output "Already installed: $name $($tool.version)"; continue }
    if (Test-Path -LiteralPath $destination) {
        throw "Incomplete or modified tool directory: $destination. Inspect it and remove only that directory before retrying."
    }
    $archive = Join-Path $toolRoot $tool.asset
    if (-not (Test-Path -LiteralPath $archive)) {
        Write-Output "Downloading $name $($tool.version) into $archive"
        $partial = "$archive.partial"
        Invoke-WebRequest -UseBasicParsing -Uri $tool.url -OutFile $partial
        Move-Item -LiteralPath $partial -Destination $archive
    }
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $tool.sha256) { throw "SHA-256 mismatch: $archive. No executable was run." }
    Expand-Archive -LiteralPath $archive -DestinationPath $destination
    $files = @()
    foreach ($exe in $tool.executables) {
        $exePath = Join-Path $destination $exe
        if (-not (Test-Path -LiteralPath $exePath)) { throw "Missing expected executable: $exePath" }
        $files += [ordered]@{ name=$exe; sha256=(Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
    [ordered]@{ version=$tool.version; archiveSha256=$actual; files=$files } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $receipt -Encoding UTF8
    $size = (Get-ChildItem -LiteralPath $destination -File -Recurse | Measure-Object Length -Sum).Sum
    Write-Output ("Installed {0} {1}, {2:N2} MiB at {3}" -f $name,$tool.version,($size / 1MB),$destination)
}
Write-Output 'Setup complete. No global installs, PATH changes, runtimes or Studio plugins were installed.'
