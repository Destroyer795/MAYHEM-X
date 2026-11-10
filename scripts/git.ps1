$gitArguments = @($args)
$projectRoot = Split-Path -Parent $PSScriptRoot
$metadata = Join-Path $projectRoot '.version-control'
if (-not (Test-Path -LiteralPath (Join-Path $metadata 'HEAD'))) { $metadata = Join-Path $projectRoot '.git' }
if (-not $gitArguments) { $gitArguments = @('status','--short','--branch') }
& git "--git-dir=$metadata" "--work-tree=$projectRoot" @gitArguments
exit $LASTEXITCODE
