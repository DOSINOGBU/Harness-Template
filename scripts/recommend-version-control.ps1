param(
    [ValidateSet("Passed", "Failed", "Partial", "Unknown")]
    [string]$VerificationStatus = "Unknown",
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [ValidateSet("feat", "fix", "refactor", "docs", "style", "test", "chore", "perf")]
    [string]$Type = "feat",
    [string]$Scope = "work",
    [string]$Summary = "describe change",
    [switch]$NoAutoCommit,
    [switch]$PushRequested,
    [switch]$AutoPush
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "harness-version-control/shared.ps1")

$repoRootPath = (Resolve-Path $RepoRoot).Path

function Write-VersionControlRecommendation {
    param(
        [string]$Key,
        [string]$Value
    )

    Write-Host "${Key}: $Value"
}

function Write-PathList {
    param(
        [string]$Label,
        [string[]]$Paths
    )

    if ($Paths.Count -eq 0) {
        return
    }

    Write-VersionControlRecommendation -Key $Label -Value (($Paths | Sort-Object) -join ", ")
}

if (-not (Test-HarnessGitRepository -RepoRoot $repoRootPath)) {
    throw "RepoRoot is not a git work tree: $repoRootPath"
}

$config = Get-HarnessVersionControlConfig -RepoRoot $repoRootPath
$changedPaths = @(Get-HarnessChangedPaths -RepoRoot $repoRootPath)
$changeSummary = Get-HarnessChangeSummary -Paths $changedPaths -Config $config
$blockedFindings = @(Get-HarnessBlockedPathFindings -RepoRoot $repoRootPath -Paths $changedPaths -Config $config)

$hasFeatureChanges = $changeSummary.Feature.Count -gt 0
$hasWorkUnitDocs = $changeSummary.WorkUnitDocs.Count -gt 0
$hasDocsOnlyChanges = $changeSummary.AllDocs.Count -gt 0 -and -not $hasFeatureChanges
$hasUnrelatedChanges = $changeSummary.Other.Count -gt 0
$hasDocsOtherWithWorkUnit = $changeSummary.DocsOther.Count -gt 0 -and ($hasFeatureChanges -or $hasWorkUnitDocs)

$commitStatus = "hold"
$commitReason = "not_evaluated"
$commitMessages = @()

if ($changedPaths.Count -eq 0) {
    $commitStatus = "no_changes"
    $commitReason = "working_tree_clean"
}
elseif ($blockedFindings.Count -gt 0) {
    $commitStatus = "hold"
    $commitReason = "blocked_path"
}
elseif ($NoAutoCommit) {
    $commitStatus = "hold"
    $commitReason = "user_disabled_auto_commit"
}
elseif (-not $config.autoCommitWorkUnit) {
    $commitStatus = "hold"
    $commitReason = "auto_commit_disabled"
}
elseif ($VerificationStatus -eq "Failed") {
    $commitStatus = "hold"
    $commitReason = "verification_failed"
}
elseif ($hasUnrelatedChanges) {
    $commitStatus = "hold"
    $commitReason = "unrelated_changes_present"
}
elseif ($hasDocsOtherWithWorkUnit) {
    $commitStatus = "hold"
    $commitReason = "mixed_work_unit_and_other_docs"
}
elseif ($VerificationStatus -eq "Partial" -and $hasFeatureChanges) {
    $commitStatus = "hold"
    $commitReason = "partial_verification_blocks_code_commit"
}
elseif ($hasFeatureChanges -and $hasWorkUnitDocs) {
    if ($VerificationStatus -eq "Passed") {
        $commitStatus = "auto_split_recommended"
        $commitReason = "feature_and_work_unit_docs"
        $commitMessages += "${Type}(${Scope}): $Summary"
        $commitMessages += New-HarnessDocsCommitMessage -Summary $changeSummary
    }
    else {
        $commitStatus = "hold"
        $commitReason = "verification_required_for_code_commit"
    }
}
elseif ($hasFeatureChanges) {
    if ($VerificationStatus -eq "Passed") {
        $commitStatus = "auto_recommended"
        $commitReason = "feature_only"
        $commitMessages += "${Type}(${Scope}): $Summary"
    }
    else {
        $commitStatus = "hold"
        $commitReason = "verification_required_for_code_commit"
    }
}
elseif ($hasDocsOnlyChanges -or $changeSummary.DocsOther.Count -gt 0) {
    $commitStatus = "docs_recommended"
    $commitReason = "docs_only"
    $commitMessages += New-HarnessDocsCommitMessage -Summary $changeSummary
}
else {
    $commitStatus = "hold"
    $commitReason = "unclassified_changes"
}

Write-VersionControlRecommendation -Key "Verification" -Value $VerificationStatus
Write-VersionControlRecommendation -Key "Commit" -Value $commitStatus
Write-VersionControlRecommendation -Key "CommitReason" -Value $commitReason
Write-PathList -Label "FeaturePaths" -Paths $changeSummary.Feature
Write-PathList -Label "WorkUnitDocPaths" -Paths $changeSummary.WorkUnitDocs
Write-PathList -Label "OtherDocPaths" -Paths $changeSummary.DocsOther
Write-PathList -Label "UnrelatedPaths" -Paths $changeSummary.Other

if ($blockedFindings.Count -gt 0) {
    $blockedText = @($blockedFindings | ForEach-Object { "$($_.Path)[$($_.Reason)]" }) -join ", "
    Write-VersionControlRecommendation -Key "BlockedPaths" -Value $blockedText
}

if ($commitMessages.Count -gt 0) {
    Write-Host "CommitMessages:"

    for ($index = 0; $index -lt $commitMessages.Count; $index += 1) {
        Write-Host "$($index + 1). $($commitMessages[$index])"
    }
}

$pushRecommendation = Get-HarnessPushRecommendation -RepoRoot $repoRootPath -Config $config -VerificationStatus $VerificationStatus -PushRequested:$PushRequested

Write-VersionControlRecommendation -Key "Push" -Value $pushRecommendation.Status
Write-VersionControlRecommendation -Key "PushReason" -Value $pushRecommendation.Reason
Write-VersionControlRecommendation -Key "Branch" -Value ([string]$pushRecommendation.Branch)
Write-VersionControlRecommendation -Key "Upstream" -Value ([string]$pushRecommendation.Upstream)
Write-VersionControlRecommendation -Key "Ahead" -Value ([string]$pushRecommendation.Ahead)
Write-VersionControlRecommendation -Key "Behind" -Value ([string]$pushRecommendation.Behind)
Write-VersionControlRecommendation -Key "FeatureCommitsSincePush" -Value ([string]$pushRecommendation.FeatureCommitsSincePush)

if ($AutoPush) {
    $canPush = $pushRecommendation.Status -eq "auto_recommended" -or $pushRecommendation.Status -eq "push_requested_recommended"

    if (-not $canPush) {
        Write-VersionControlRecommendation -Key "PushResult" -Value "not_pushed"
        exit 0
    }

    try {
        $pushOutput = Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments @("push")
    }
    catch {
        Write-VersionControlRecommendation -Key "PushResult" -Value "failed"
        Write-Host $_.Exception.Message
        exit 1
    }

    Write-VersionControlRecommendation -Key "PushResult" -Value "pushed"
}
