<#
.SYNOPSIS
    표준 작업 단위에 맞춰 스테이징된 변경을 기능 커밋과 문서 커밋으로 나눕니다.

.DESCRIPTION
    변경 경로를 work unit 규칙으로 분류한 뒤, 차단 경로·무관 변경·혼합 문서·검증 상태를 검사합니다.
    -DryRun이면 git add/commit을 하지 않고 계획만 로그합니다.

.PARAMETER RepoRoot
    Git 저장소 루트(기본: 이 스크립트의 상위 디렉터리).

.PARAMETER VerificationStatus
    Passed일 때만 기능/테스트 커밋을 허용합니다. Partial일 때는 exec-plan 완료·validation 경로만 문서 커밋을 허용하고, 그 밖의 문서·저장소 위생 경로는 거절합니다.

.PARAMETER DryRun
    커밋을 만들지 않고 어떤 커밋이 나갈지 로그만 남깁니다.

.PARAMETER DocsMessage
    문서 커밋 한 줄 메시지를 덮어씁니다(비우면 New-HarnessDocsCommitMessage 규칙 사용).
#>
param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [ValidateSet("Passed", "Failed", "Partial", "Unknown")]
    [string]$VerificationStatus = "Unknown",
    [ValidateSet("feat", "fix", "refactor", "docs", "style", "test", "chore", "perf")]
    [string]$Type,
    [string]$Scope,
    [string]$Summary,
    [string]$CodeMessage,
    [string]$DocsMessage,
    [switch]$DryRun
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

    if ([regex]::IsMatch(
            $Message,
            '\b(update|fix stuff|changes)\b',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
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

    if ($DryRun) {
        return
    }

    $addArguments = @("add", "--") + @($Paths)
    $commitArguments = @("commit", "-m", $Message, "--") + @($Paths)

    Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments $addArguments | Out-Null
    Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments $commitArguments | Out-Null
}

function Invoke-WorkUnitDocsCommit {
    param(
        [object]$ChangeSummary,
        [string[]]$Paths,
        [string]$BucketLabel
    )

    if ($Paths.Count -eq 0) {
        return
    }

    $docsCommitMessage = $DocsMessage

    if ([string]::IsNullOrWhiteSpace($docsCommitMessage)) {
        $docsCommitMessage = New-HarnessDocsCommitMessage -Summary $ChangeSummary
    }

    Assert-CleanCommitMessage -Message $docsCommitMessage -Kind "Docs"
    Invoke-CommitPathSet -Paths $Paths -Message $docsCommitMessage

    if (-not $DryRun) {
        Write-WorkUnitLog -Status "committed_docs" -Metadata @{
            message = $docsCommitMessage
            paths = ($Paths -join ", ")
            bucket = $BucketLabel
        }
    }
    else {
        Write-WorkUnitLog -Status "dry_run_docs" -Metadata @{
            message = $docsCommitMessage
            paths = ($Paths -join ", ")
            bucket = $BucketLabel
        }
    }
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

if ($summaryObject.Other.Count -gt 0) {
    $unrelated = @($summaryObject.Other) -join ", "
    throw "Unrelated changes prevent automatic work-unit commit: $unrelated"
}

if ($summaryObject.DocsOther.Count -gt 0 -and ($summaryObject.Feature.Count -gt 0 -or $summaryObject.WorkUnitDocs.Count -gt 0)) {
    $mixedDocs = @($summaryObject.DocsOther) -join ", "
    throw "Other documentation or repo hygiene changes prevent automatic work-unit commit: $mixedDocs"
}

$hasFeatureChanges = $summaryObject.Feature.Count -gt 0
$hasWorkUnitDocs = $summaryObject.WorkUnitDocs.Count -gt 0
$hasDocsOtherChanges = $summaryObject.DocsOther.Count -gt 0

if ($VerificationStatus -eq "Failed") {
    throw "VerificationStatus=Failed prevents automatic commit."
}

if ($hasFeatureChanges -and $VerificationStatus -ne "Passed") {
    throw "Feature/test changes require VerificationStatus=Passed before commit."
}

if ($VerificationStatus -eq "Partial" -and $hasDocsOtherChanges -and -not $hasWorkUnitDocs) {
    $blockedOtherDocs = @($summaryObject.DocsOther) -join ", "
    throw "VerificationStatus=Partial allows only exec-plan or validation documentation commits; other documentation or repo hygiene paths are blocked: $blockedOtherDocs"
}

if (-not $hasFeatureChanges -and -not $hasWorkUnitDocs -and -not $hasDocsOtherChanges) {
    throw "No feature/test or documentation changes were found."
}

if ($hasFeatureChanges) {
    $codeCommitMessage = Get-CodeCommitMessage
    Assert-CleanCommitMessage -Message $codeCommitMessage -Kind "Code"
    Invoke-CommitPathSet -Paths $summaryObject.Feature -Message $codeCommitMessage

    if (-not $DryRun) {
        Write-WorkUnitLog -Status "committed_code" -Metadata @{
            message = $codeCommitMessage
            paths = ($summaryObject.Feature -join ", ")
        }
    }
    else {
        Write-WorkUnitLog -Status "dry_run_code" -Metadata @{
            message = $codeCommitMessage
            paths = ($summaryObject.Feature -join ", ")
        }
    }
}

Invoke-WorkUnitDocsCommit -ChangeSummary $summaryObject -Paths $summaryObject.WorkUnitDocs -BucketLabel "work_unit"
Invoke-WorkUnitDocsCommit -ChangeSummary $summaryObject -Paths $summaryObject.DocsOther -BucketLabel "other_docs"

if (-not $DryRun) {
    $remainingPaths = @(Get-HarnessChangedPaths -RepoRoot $repoRootPath)

    if ($remainingPaths.Count -gt 0) {
        throw "Work-unit commit finished with remaining changes: $($remainingPaths -join ', ')"
    }
}
else {
    $remainingPaths = @(Get-HarnessChangedPaths -RepoRoot $repoRootPath)

    if ($remainingPaths.Count -gt 0) {
        Write-WorkUnitLog -Status "dry_run_remaining_paths" -Metadata @{
            paths = ($remainingPaths -join ", ")
        }
    }
}

$commitCount = 0

if ($hasFeatureChanges) {
    $commitCount += 1
}

if ($hasWorkUnitDocs) {
    $commitCount += 1
}

if ($hasDocsOtherChanges) {
    $commitCount += 1
}

Write-WorkUnitLog -Status $(if ($DryRun) { "dry_run_complete" } else { "complete" }) -Metadata @{
    repoRoot = $repoRootPath
    commits = $commitCount
    dryRun = [string]$DryRun
}
