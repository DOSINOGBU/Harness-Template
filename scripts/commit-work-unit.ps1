param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [ValidateSet("Passed", "Failed", "Partial", "Unknown")]
    [string]$VerificationStatus = "Unknown",
    [ValidateSet("feat", "fix", "refactor", "test", "perf")]
    [string]$Type,
    [string]$Scope,
    [string]$Summary,
    [string]$CodeMessage,
    [string]$DocsMessage
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "harness-version-control/shared.ps1")

$repoRootPath = (Resolve-Path $RepoRoot).Path

function Write-WorkUnitLog {
    param(
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[CommitWorkUnit] $Status { $metadataText }"
}

function Assert-CleanCommitMessage {
    param(
        [string]$Message,
        [string]$Kind
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        throw "$Kind commit message is required."
    }

    if ($Message -match '\b(update|fix stuff|changes)\b') {
        throw "$Kind commit message is too vague: $Message"
    }
}

function Get-CodeCommitMessage {
    if (-not [string]::IsNullOrWhiteSpace($CodeMessage)) {
        return $CodeMessage
    }

    if ([string]::IsNullOrWhiteSpace($Type) -or [string]::IsNullOrWhiteSpace($Scope) -or [string]::IsNullOrWhiteSpace($Summary)) {
        throw "Code changes require -CodeMessage or all of -Type, -Scope, and -Summary."
    }

    return "${Type}(${Scope}): $Summary"
}

function Invoke-CommitPathSet {
    param(
        [string[]]$Paths,
        [string]$Message
    )

    if ($Paths.Count -eq 0) {
        return
    }

    $addArguments = @("add", "--") + @($Paths)
    $commitArguments = @("commit", "-m", $Message, "--") + @($Paths)

    Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments $addArguments | Out-Null
    Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments $commitArguments | Out-Null
}

if (-not (Test-HarnessGitRepository -RepoRoot $repoRootPath)) {
    throw "RepoRoot is not a git work tree: $repoRootPath"
}

$config = Get-HarnessVersionControlConfig -RepoRoot $repoRootPath
$changedPaths = @(Get-HarnessChangedPaths -RepoRoot $repoRootPath)
$summaryObject = Get-HarnessChangeSummary -Paths $changedPaths -Config $config
$blockedFindings = @(Get-HarnessBlockedPathFindings -RepoRoot $repoRootPath -Paths $changedPaths -Config $config)

if ($changedPaths.Count -eq 0) {
    Write-WorkUnitLog -Status "no_changes" -Metadata @{ repoRoot = $repoRootPath }
    exit 0
}

if ($blockedFindings.Count -gt 0) {
    $blockedText = @($blockedFindings | ForEach-Object { "$($_.Path)[$($_.Reason)]" }) -join ", "
    throw "Blocked paths prevent automatic commit: $blockedText"
}

if ($summaryObject.Other.Count -gt 0 -or $summaryObject.DocsOther.Count -gt 0) {
    $unrelated = @($summaryObject.Other + $summaryObject.DocsOther) -join ", "
    throw "Unrelated changes prevent automatic work-unit commit: $unrelated"
}

$hasFeatureChanges = $summaryObject.Feature.Count -gt 0
$hasWorkUnitDocs = $summaryObject.WorkUnitDocs.Count -gt 0

if ($VerificationStatus -eq "Failed") {
    throw "VerificationStatus=Failed prevents automatic commit."
}

if ($hasFeatureChanges -and $VerificationStatus -ne "Passed") {
    throw "Feature/test changes require VerificationStatus=Passed before commit."
}

if (-not $hasFeatureChanges -and -not $hasWorkUnitDocs) {
    throw "No feature/test or work-unit documentation changes were found."
}

if ($hasFeatureChanges) {
    $codeCommitMessage = Get-CodeCommitMessage
    Assert-CleanCommitMessage -Message $codeCommitMessage -Kind "Code"
    Invoke-CommitPathSet -Paths $summaryObject.Feature -Message $codeCommitMessage
    Write-WorkUnitLog -Status "committed_code" -Metadata @{
        message = $codeCommitMessage
        paths = ($summaryObject.Feature -join ", ")
    }
}

if ($hasWorkUnitDocs) {
    $docsCommitMessage = $DocsMessage

    if ([string]::IsNullOrWhiteSpace($docsCommitMessage)) {
        $docsCommitMessage = New-HarnessDocsCommitMessage -Summary $summaryObject
    }

    Assert-CleanCommitMessage -Message $docsCommitMessage -Kind "Docs"
    Invoke-CommitPathSet -Paths $summaryObject.WorkUnitDocs -Message $docsCommitMessage
    Write-WorkUnitLog -Status "committed_docs" -Metadata @{
        message = $docsCommitMessage
        paths = ($summaryObject.WorkUnitDocs -join ", ")
    }
}

$remainingPaths = @(Get-HarnessChangedPaths -RepoRoot $repoRootPath)

if ($remainingPaths.Count -gt 0) {
    throw "Work-unit commit finished with remaining changes: $($remainingPaths -join ', ')"
}

$commitCount = 0

if ($hasFeatureChanges) {
    $commitCount += 1
}

if ($hasWorkUnitDocs) {
    $commitCount += 1
}

Write-WorkUnitLog -Status "complete" -Metadata @{
    repoRoot = $repoRootPath
    commits = $commitCount
}
