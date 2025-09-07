param(
  [Parameter(Mandatory=$true)][string]$SourceBranch,
  [int]$RequiredApprovals = $(if ($env:REQUIRED_APPROVALS) { [int]$env:REQUIRED_APPROVALS } else { 1 })
)

$AllowList = "approvers/ALLOWLIST.txt"
$MainBranch = "main"

$targetSha = (git rev-parse $SourceBranch).Trim()
if (-not $?) { Write-Error "Branch not found: $SourceBranch"; exit 1 }

git rev-parse $MainBranch *> $null
if ($LASTEXITCODE -ne 0) { Write-Error "No '$MainBranch' branch."; exit 1 }

$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -eq $MainBranch) { Write-Error "Don't run on '$MainBranch'."; exit 1 }

git merge-base --is-ancestor $MainBranch $SourceBranch
if ($LASTEXITCODE -ne 0) {
  Write-Error "'$SourceBranch' is behind '$MainBranch'. Rebase or merge '$MainBranch' into '$SourceBranch' first."
  exit 1
}

$tags = (git tag -l "approve/$targetSha/*" | ForEach-Object { $_.Trim() })
if (-not $tags) {
  Write-Error "No approval tags found for $targetSha. Run tools/make-approval-tag.ps1 -Branch $SourceBranch"
  exit 1
}

if (-not (Test-Path $AllowList)) { Write-Error "Allow-list $AllowList missing"; exit 1 }
$allowEmails = Get-Content $AllowList | Where-Object { $_ -and ($_ -notmatch '^\s*#') } | ForEach-Object { $_.Trim() }

$ok = 0
Write-Host "Checking approvals for $targetSha"
foreach ($email in $allowEmails) {
  $t = "approve/$targetSha/$email"
  if ($tags -contains $t) {
    git verify-tag $t *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "  valid signature from $email on $t"; $ok++ }
    else { Write-Host "  tag $t exists but signature invalid" }
  }
}

if ($ok -lt $RequiredApprovals) {
  Write-Error "Need at least $RequiredApprovals approval(s); got $ok"
  exit 1
}

Write-Host "Approvals satisfied. Merging '$SourceBranch' into '$MainBranch'..."
git checkout $MainBranch
if ($LASTEXITCODE -ne 0) { exit 1 }
git merge --ff-only $targetSha
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "'$MainBranch' updated to include $targetSha"
