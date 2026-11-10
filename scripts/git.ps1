[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
$projectRoot = Split-Path -Parent $PSScriptRoot
$metadata = Join-Path $projectRoot '.version-control'
if (-not (Test-Path -LiteralPath (Join-Path $metadata 'HEAD'))) { $metadata = Join-Path $projectRoot '.git' }
if (-not $GitArgs) { $GitArgs = @('status','--short','--branch') }
& git "--git-dir=$metadata" "--work-tree=$projectRoot" @GitArgs
exit $LASTEXITCODE
