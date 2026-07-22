<#
.SYNOPSIS
    Checks whether an evidence document still matches the current code state.

.DESCRIPTION
    Reads the "Tree hash: `<hash>`" line from a docs/validation evidence file and
    compares it with the current git tree hash (git rev-parse --short "HEAD^{tree}").
    Evidence recorded for an older tree is reported as stale — reviewers must not
    trust stale evidence without re-running the recorded commands.

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
$match = [regex]::Match($content, 'Tree hash:\s*`?([0-9a-f]{4,40}|unavailable)`?')

if (-not $match.Success) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=no_tree_hash_line; hint=create evidence via scripts/new-artifact.ps1 -Type validation }"
    exit 1
}

$recordedHash = $match.Groups[1].Value

if ($recordedHash -eq "unavailable") {
    Write-Host "[VerifyEvidence] warning { path=$Path; reason=recorded_without_git }"
    exit 2
}

# Native stderr under EAP=Stop throws in Windows PowerShell; relax around git.
$previousEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$currentHash = (& git -C $repoRoot rev-parse --short "HEAD^{tree}" 2>$null)
$gitExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousEap

if ($gitExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($currentHash)) {
    Write-Host "[VerifyEvidence] failed { path=$Path; reason=git_unavailable }"
    exit 1
}

$currentHash = ([string]$currentHash).Trim()

if ($currentHash.StartsWith($recordedHash) -or $recordedHash.StartsWith($currentHash)) {
    Write-Host "[VerifyEvidence] fresh { path=$Path; treeHash=$recordedHash }"
    exit 0
}

Write-Host "[VerifyEvidence] stale { path=$Path; recorded=$recordedHash; current=$currentHash; hint=tracked content changed after evidence was recorded - re-run the recorded commands }"
exit 2
