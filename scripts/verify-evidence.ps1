<#
.SYNOPSIS
    Checks whether an evidence document still matches the current code state.

.DESCRIPTION
    Reads the "Base commit: `<hash>`" line from a docs/validation evidence file
    and checks whether any tracked content OUTSIDE docs/validation changed since
    that commit (committed or uncommitted). Evidence recorded for older code is
    reported as stale — reviewers must re-run the recorded commands instead of
    trusting it. (Legacy "Tree hash:" lines are accepted as the same field.)

.PARAMETER Path
    Evidence file path (absolute, or relative to the repo root).

.EXAMPLE
    pwsh -File scripts/verify-evidence.ps1 -Path docs/validation/2026-07-22-checkout-regression.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

$scriptBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptBase)) {
    $scriptBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptBase "..")).Path

$fullPath = $Path
if (-not [IO.Path]::IsPathRooted($fullPath)) {
    $fullPath = Join-Path $repoRoot ($Path -replace "/", [IO.Path]::DirectorySeparatorChar)
}

if (-not (Test-Path -LiteralPath $fullPath)) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=missing_file }"
    exit 1
}

$content = Get-Content -Raw -Encoding UTF8 -LiteralPath $fullPath
$match = [regex]::Match($content, '(?:Base commit|Tree hash):\s*`?([0-9a-f]{4,40}|unavailable)`?')

if (-not $match.Success) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=no_base_commit_line; hint=create evidence via scripts/new-artifact.ps1 -Type validation }"
    exit 1
}

$recordedHash = $match.Groups[1].Value

if ($recordedHash -eq "unavailable") {
    Write-Host "[VerifyEvidence] warning { path=$Path; reason=recorded_without_git }"
    exit 2
}

function Invoke-EvidenceGit {
    param([string[]]$Arguments)

    # Native stderr under EAP=Stop throws in Windows PowerShell; relax around git.
    $previousEap = $script:ErrorActionPreference
    $script:ErrorActionPreference = "Continue"
    $output = & git -C $repoRoot @Arguments 2>$null
    $exitCode = $LASTEXITCODE
    $script:ErrorActionPreference = $previousEap

    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

$commitCheck = Invoke-EvidenceGit -Arguments @("rev-parse", "--verify", "--quiet", "$recordedHash^{commit}")

if ($commitCheck.ExitCode -ne 0) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=unknown_base_commit; recorded=$recordedHash }"
    exit 1
}

# Committed changes since the base commit, excluding the evidence folder itself.
$committedDiff = Invoke-EvidenceGit -Arguments @("diff", "--name-only", "$recordedHash..HEAD", "--", ".", ":(exclude)docs/validation")

if ($committedDiff.ExitCode -ne 0) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=git_diff_failed }"
    exit 1
}

# Uncommitted working-tree changes outside the evidence folder.
$statusResult = Invoke-EvidenceGit -Arguments @("status", "--porcelain")
$dirtyPaths = @($statusResult.Output | Where-Object {
    $_ -and ($_.Length -gt 3) -and (($_.Substring(3) -replace "\\", "/") -notlike "docs/validation/*")
})

$changedPaths = @($committedDiff.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($changedPaths.Count -eq 0 -and $dirtyPaths.Count -eq 0) {
    Write-Host "[VerifyEvidence] fresh { path=$Path; baseCommit=$recordedHash }"
    exit 0
}

$sampleChanges = @($changedPaths + @($dirtyPaths | ForEach-Object { $_.Substring(3) })) | Select-Object -First 5
Write-Host "[VerifyEvidence] stale { path=$Path; baseCommit=$recordedHash; changedSince=$($changedPaths.Count + $dirtyPaths.Count); sample=$($sampleChanges -join ', '); hint=code changed after evidence was recorded - re-run the recorded commands }"
exit 2
