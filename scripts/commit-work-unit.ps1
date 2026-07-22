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
    [string]$Justification,
    [string]$AcceptCodeHealth,
    [string]$AcceptUiConformance,
    [switch]$SkipCodeHealthGate,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "harness-version-control/shared.ps1")

$script:exceptionLedgerTouched = $false

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

function Get-DominantCommitStyle {
    $subjects = @()

    try {
        $subjects = @(Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments @("log", "-30", "--format=%s"))
    }
    catch {
        return $null
    }

    if ($subjects.Count -lt 5) {
        return $null
    }

    $semanticPattern = '^[a-z]+(\([^)]+\))?!?:\s'
    $semanticCount = @($subjects | Where-Object { $_ -match $semanticPattern }).Count

    if ($semanticCount * 10 -ge $subjects.Count * 6) {
        return "SEMANTIC"
    }

    return "PLAIN"
}

function Get-CommitGateThresholds {
    param(
        [string]$RelativePath
    )

    # Fallbacks mirror .harness/config.json validation.codeHealth defaults.
    $defaults = [pscustomobject]@{ FeatureFreeze = 800; Failure = 1200 }
    $markup = [pscustomobject]@{ FeatureFreeze = 1200; Failure = 1800 }
    $migration = [pscustomobject]@{ FeatureFreeze = 1800; Failure = 2400 }

    $configPath = Join-Path $repoRootPath ".harness/config.json"

    if (Test-Path -LiteralPath $configPath) {
        try {
            $rawConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
            $codeHealth = $rawConfig.validation.codeHealth

            if ($null -ne $codeHealth) {
                if ($codeHealth.featureFreezeLines) { $defaults = [pscustomobject]@{ FeatureFreeze = [int]$codeHealth.featureFreezeLines; Failure = [int]$codeHealth.failureLines } }
                if ($codeHealth.markupFeatureFreezeLines) { $markup = [pscustomobject]@{ FeatureFreeze = [int]$codeHealth.markupFeatureFreezeLines; Failure = [int]$codeHealth.markupFailureLines } }
                if ($codeHealth.migrationFeatureFreezeLines) { $migration = [pscustomobject]@{ FeatureFreeze = [int]$codeHealth.migrationFeatureFreezeLines; Failure = [int]$codeHealth.migrationFailureLines } }
            }
        }
        catch {
            # Keep defaults when config is unreadable; the validator reports config errors separately.
        }
    }

    $extension = [IO.Path]::GetExtension($RelativePath).ToLowerInvariant()
    $markupExtensions = @(".astro", ".css", ".html", ".jsx", ".sass", ".scss", ".svelte", ".tsx", ".vue")
    $migrationExtensions = @(".proto", ".sql")
    $normalizedPath = $RelativePath -replace "\\", "/"

    if ($migrationExtensions -contains $extension -or $normalizedPath -like "*/migrations/*") {
        return $migration
    }

    if ($markupExtensions -contains $extension) {
        return $markup
    }

    return $defaults
}

function Get-GitFileLineCount {
    param(
        [string]$RelativePath,
        [switch]$FromHead
    )

    if ($FromHead) {
        try {
            $content = @(Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments @("show", "HEAD:$RelativePath"))
            return $content.Count
        }
        catch {
            return 0
        }
    }

    $fullPath = Join-Path $repoRootPath ($RelativePath -replace "/", [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $fullPath)) {
        return 0
    }

    return @(Get-Content -LiteralPath $fullPath -ErrorAction SilentlyContinue).Count
}

function Test-CommitCodeHealthGate {
    param(
        [string[]]$FeaturePaths
    )

    if ($SkipCodeHealthGate -or $FeaturePaths.Count -eq 0) {
        return
    }

    $codeExtensions = @(
        ".astro", ".c", ".cc", ".cjs", ".cpp", ".cs", ".css", ".go", ".h", ".hpp",
        ".html", ".java", ".js", ".jsx", ".kt", ".mjs", ".php", ".ps1", ".psm1",
        ".py", ".rb", ".rs", ".sass", ".scala", ".scss", ".sh", ".sql", ".svelte",
        ".swift", ".ts", ".tsx", ".vue"
    )
    $violations = @()

    foreach ($path in $FeaturePaths) {
        $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()

        if ($codeExtensions -notcontains $extension) {
            continue
        }

        $thresholds = Get-CommitGateThresholds -RelativePath $path
        $newLineCount = Get-GitFileLineCount -RelativePath $path

        if ($newLineCount -ge $thresholds.Failure) {
            $violations += "$path ($newLineCount lines >= failure tier $($thresholds.Failure))"
            continue
        }

        $oldLineCount = Get-GitFileLineCount -RelativePath $path -FromHead

        if ($oldLineCount -ge $thresholds.FeatureFreeze -and $newLineCount -gt $oldLineCount) {
            $violations += "$path grew $oldLineCount -> $newLineCount lines while over the feature-freeze tier ($($thresholds.FeatureFreeze))"
        }
    }

    if ($violations.Count -eq 0) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($AcceptCodeHealth)) {
        Write-WorkUnitLog -Status "code_health_accepted" -Metadata @{
            reason = $AcceptCodeHealth
            violations = ($violations -join "; ")
        }

        if (-not $DryRun) {
            Add-HarnessExceptionEntry -Type "code-health" -Reason $AcceptCodeHealth -Paths ($violations -join "; ")
        }
        return
    }

    throw ("Code-health gate blocked the commit: " + ($violations -join "; ") +
        ". Split or shrink the files, or pass -AcceptCodeHealth `"<reason>`" to record an intentional exception.")
}

function Add-HarnessExceptionEntry {
    param(
        [string]$Type,
        [string]$Reason,
        [string]$Paths
    )

    # Every accepted exception lands in the ledger with an expiry date so it
    # cannot live forever (hygiene check flags expired entries).
    $ttlDays = 30
    $configPath = Join-Path $repoRootPath ".harness/config.json"

    if (Test-Path -LiteralPath $configPath) {
        try {
            $rawConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
            if ([int]$rawConfig.hygiene.exceptionTtlDays -ge 1) {
                $ttlDays = [int]$rawConfig.hygiene.exceptionTtlDays
            }
        }
        catch {
        }
    }

    $harnessDir = Join-Path $repoRootPath ".harness"

    if (-not (Test-Path -LiteralPath $harnessDir)) {
        New-Item -ItemType Directory -Path $harnessDir -Force | Out-Null
    }

    $ledgerPath = Join-Path $harnessDir "exceptions.json"
    $entries = @()

    if (Test-Path -LiteralPath $ledgerPath) {
        try {
            $entries = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $ledgerPath | ConvertFrom-Json)
        }
        catch {
            $entries = @()
        }
    }

    $entries += [pscustomobject]@{
        type = $Type
        reason = $Reason
        paths = $Paths
        recordedAt = (Get-Date).ToString("yyyy-MM-dd")
        expires = (Get-Date).AddDays($ttlDays).ToString("yyyy-MM-dd")
    }

    $json = ConvertTo-Json -InputObject @($entries) -Depth 4
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ledgerPath, $json.Replace("`r`n", "`n") + "`n", $utf8NoBom)

    $script:exceptionLedgerTouched = $true

    Write-WorkUnitLog -Status "exception_recorded" -Metadata @{
        type = $Type
        expires = (Get-Date).AddDays($ttlDays).ToString("yyyy-MM-dd")
        ledger = ".harness/exceptions.json"
    }
}

function Get-UiConformanceGateConfig {
    # Defaults mirror scripts/harness-validation/ui-conformance.ps1.
    $gateConfig = [pscustomobject]@{
        Enabled = $true
        TargetExtensions = @(".astro", ".css", ".jsx", ".less", ".sass", ".scss", ".svelte", ".tsx", ".vue")
        ExcludedPatterns = @("**/globals.css", "**/tokens.css", "**/*.tokens.*")
        ForbiddenPatterns = @(
            @{ pattern = '#[0-9a-fA-F]{6}\b'; reason = "hardcoded_hex_color" },
            @{ pattern = '\b(?:bg-white|bg-black\b|(?:bg|text|border)-(?:emerald|red|green|blue|slate|gray|zinc|amber|rose)-\d{2,3})\b'; reason = "palette_literal" },
            @{ pattern = '@import\s+url\(\s*["'']?https?://'; reason = "cdn_font_import" },
            @{ pattern = 'from\s+["'']@tabler/'; reason = "forbidden_icon_package" }
        )
    }

    $configPath = Join-Path $repoRootPath ".harness/config.json"

    if (-not (Test-Path -LiteralPath $configPath)) {
        return $gateConfig
    }

    try {
        $rawConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
        $uiConformance = $rawConfig.validation.uiConformance

        if ($null -ne $uiConformance) {
            if ($null -ne $uiConformance.enabled) { $gateConfig.Enabled = [bool]$uiConformance.enabled }
            if ($uiConformance.targetExtensions) { $gateConfig.TargetExtensions = @($uiConformance.targetExtensions) }
            if ($uiConformance.excludedPatterns) { $gateConfig.ExcludedPatterns = @($uiConformance.excludedPatterns) }

            if ($uiConformance.forbiddenPatterns) {
                $gateConfig.ForbiddenPatterns = @($uiConformance.forbiddenPatterns | ForEach-Object {
                    @{ pattern = [string]$_.pattern; reason = [string]$_.reason }
                })
            }
        }
    }
    catch {
        # Keep defaults when config is unreadable.
    }

    return $gateConfig
}

function Get-UiViolationCount {
    param(
        [string[]]$Lines,
        [object[]]$ForbiddenPatterns
    )

    $count = 0

    foreach ($line in $Lines) {
        foreach ($forbidden in $ForbiddenPatterns) {
            if (-not [string]::IsNullOrWhiteSpace($forbidden.pattern) -and $line -match $forbidden.pattern) {
                $count += 1
            }
        }
    }

    return $count
}

function Test-CommitUiConformanceGate {
    param(
        [string[]]$FeaturePaths
    )

    if ($FeaturePaths.Count -eq 0) {
        return
    }

    $gateConfig = Get-UiConformanceGateConfig

    if (-not $gateConfig.Enabled) {
        return
    }

    $violations = @()

    foreach ($path in $FeaturePaths) {
        $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()

        if ($gateConfig.TargetExtensions -notcontains $extension) {
            continue
        }

        $normalizedPath = ($path -replace "\\", "/")
        $isExcluded = $false

        foreach ($excludedPattern in $gateConfig.ExcludedPatterns) {
            if ($normalizedPath -like (([string]$excludedPattern) -replace "\\", "/")) {
                $isExcluded = $true
                break
            }
        }

        if ($isExcluded) {
            continue
        }

        $fullPath = Join-Path $repoRootPath ($path -replace "/", [IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path -LiteralPath $fullPath)) {
            continue
        }

        $currentLines = @(Get-Content -LiteralPath $fullPath -ErrorAction SilentlyContinue)
        $currentCount = Get-UiViolationCount -Lines $currentLines -ForbiddenPatterns $gateConfig.ForbiddenPatterns

        if ($currentCount -eq 0) {
            continue
        }

        # Only NEW violations block: editing a file with legacy violations is
        # allowed as long as this commit does not add more of them.
        $headLines = @()
        try {
            $headLines = @(Invoke-HarnessGit -RepoRoot $repoRootPath -Arguments @("show", "HEAD:$path"))
        }
        catch {
            $headLines = @()
        }

        $headCount = Get-UiViolationCount -Lines $headLines -ForbiddenPatterns $gateConfig.ForbiddenPatterns

        if ($currentCount -gt $headCount) {
            $violations += "$path (UI rule violations $headCount -> $currentCount; see docs/UI_RULES.md)"
        }
    }

    if ($violations.Count -eq 0) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($AcceptUiConformance)) {
        Write-WorkUnitLog -Status "ui_conformance_accepted" -Metadata @{
            reason = $AcceptUiConformance
            violations = ($violations -join "; ")
        }

        if (-not $DryRun) {
            Add-HarnessExceptionEntry -Type "ui-conformance" -Reason $AcceptUiConformance -Paths ($violations -join "; ")
        }
        return
    }

    throw ("UI conformance gate blocked the commit (new violations added): " + ($violations -join "; ") +
        ". Replace literals with design tokens per docs/UI_RULES.md, or pass -AcceptUiConformance `"<reason>`" to record an intentional exception.")
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
    # Atomicity floor (ported from lazycodex git-master): 3+ files in one code
    # commit require a one-sentence justification, or a split into ~ceil(n/3) commits.
    if ($summaryObject.Feature.Count -ge 3 -and [string]::IsNullOrWhiteSpace($Justification)) {
        $suggestedCommits = [math]::Ceiling($summaryObject.Feature.Count / 3)
        throw ("Atomicity floor: $($summaryObject.Feature.Count) feature/test files in a single commit require " +
            "-Justification `"<one sentence why this is one unit>`" or a split into ~$suggestedCommits commits.")
    }

    if (-not [string]::IsNullOrWhiteSpace($Justification)) {
        Write-WorkUnitLog -Status "atomicity_justified" -Metadata @{
            files = $summaryObject.Feature.Count
            justification = $Justification
        }
    }

    Test-CommitCodeHealthGate -FeaturePaths @($summaryObject.Feature)
    Test-CommitUiConformanceGate -FeaturePaths @($summaryObject.Feature)

    $planPathsTouched = @($changedPaths | Where-Object { ($_ -replace "\\", "/") -like "docs/exec-plans/*" })

    if ($planPathsTouched.Count -eq 0) {
        Write-WorkUnitLog -Status "retroactive_plan_check" -Metadata @{
            hint = "code changed without any exec-plan update; if behavior changed, record a retroactive plan (docs/exec-plans/README.md)"
        }
    }

    $codeCommitMessage = Get-CodeCommitMessage
    Assert-CleanCommitMessage -Message $codeCommitMessage -Kind "Code"

    $dominantStyle = Get-DominantCommitStyle

    if ($dominantStyle) {
        $matchesSemantic = $codeCommitMessage -match '^[a-z]+(\([^)]+\))?!?:\s'

        if ($dominantStyle -eq "SEMANTIC" -and -not $matchesSemantic) {
            Write-WorkUnitLog -Status "style_mismatch_warning" -Metadata @{
                dominantStyle = $dominantStyle
                message = $codeCommitMessage
            }
        }
        else {
            Write-WorkUnitLog -Status "style_detected" -Metadata @{
                dominantStyle = $dominantStyle
            }
        }
    }

    $featureCommitPaths = @($summaryObject.Feature)

    if ($script:exceptionLedgerTouched) {
        # The ledger entry belongs to the commit that used the exception.
        $featureCommitPaths += ".harness/exceptions.json"
    }

    Invoke-CommitPathSet -Paths $featureCommitPaths -Message $codeCommitMessage

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
