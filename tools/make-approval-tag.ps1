param(
  [Parameter(Mandatory=$true)][string]$Branch
)
$sha = (git rev-parse $Branch).Trim()
if (-not $?) { Write-Error "Branch not found: $Branch"; exit 1 }
$email = (git config user.email).Trim()
if (-not $email) { Write-Error "No git user.email set"; exit 1 }
git tag -s "approve/$sha/$email" -m "Approve $sha" $sha
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "✅ Created signed approval tag: approve/$sha/$email"
