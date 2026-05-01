$ErrorActionPreference = "Stop"
function Get-HarnessVersionControlConfig {
    param(
        [string]$RepoRoot
    )

    $config = @{
        autoCommitWorkUnit = $true
        autoPushAfterFeatureCommits = 2
        autoPushBranches = @("codex/*", "feature/*", "fix/*")
        protectedBranches = @("main", "master")
        featureCommitTypes = @("feat", "fix", "refactor", "test", "perf")
        blockedPathPatterns = @(
            ".env",
            ".env.*",
            "**/.env",
            "**/.env.*",
            "**/*.pem",
            "**/*.key",
            "**/*.pfx",
            "**/*.p12",
            ".lecturedigest/**",
            "data/raw/**",
            "datasets/raw/**"
        )
        largeFileBytes = 10485760
        largeOriginalDataPatterns = @(
            "data/raw/**",
            "datasets/raw/**",
            "**/raw/**",
            "**/*.zip",
            "**/*.tar",
            "**/*.tgz",
            "**/*.7z"
        )
        workUnitPaths = @{
            code = @("src/**", "app/**", "lib/**", "components/**", "pages/**", "server/**", "client/**", "api/**", "scripts/**")
            tests = @("tests/**", "test/**", "__tests__/**", "**/*.test.*", "**/*.spec.*", "**/*.Tests.*")
            execPlansCompleted = @("docs/exec-plans/completed/**")
            validation = @("docs/validation/**")
        }
    }
    $configPath = Join-Path $RepoRoot ".harness/config.json"

    if (-not (Test-Path -LiteralPath $configPath)) {
        return $config
    }
    $rawConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json -ErrorAction Stop

    if ($null -ne $rawConfig.versionControl) {
        $versionControl = $rawConfig.versionControl
        if ($null -ne $versionControl.autoCommitWorkUnit) {
            $config.autoCommitWorkUnit = [bool]$versionControl.autoCommitWorkUnit
        }
        if ($null -ne $versionControl.autoPushAfterFeatureCommits) {
            $config.autoPushAfterFeatureCommits = [int]$versionControl.autoPushAfterFeatureCommits
        }

        foreach ($key in @("autoPushBranches", "protectedBranches", "featureCommitTypes", "blockedPathPatterns", "largeOriginalDataPatterns")) {
            if ($null -ne $versionControl.$key) {
                $config[$key] = @($versionControl.$key | ForEach-Object { [string]$_ })
            }
        }

        if ($null -ne $versionControl.largeFileBytes) {
            $config.largeFileBytes = [int64]$versionControl.largeFileBytes
        }

        if ($null -ne $versionControl.workUnitPaths) {
            foreach ($key in @("code", "tests", "execPlansCompleted", "validation")) {
                if ($null -ne $versionControl.workUnitPaths.$key) {
                    $config.workUnitPaths[$key] = @($versionControl.workUnitPaths.$key | ForEach-Object { [string]$_ })
                }
            }
        }
    }
    return $config
}
function Invoke-HarnessGit {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments
    )

    $errorPath = [IO.Path]::GetTempFileName()
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & git -C $RepoRoot @Arguments 2> $errorPath
        $exitCode = $LASTEXITCODE
        $errorOutput = Get-Content -Raw -ErrorAction SilentlyContinue -LiteralPath $errorPath
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference

        if (Test-Path -LiteralPath $errorPath) {
            Remove-Item -LiteralPath $errorPath -Force
        }
    }

    if ($exitCode -ne 0) {
        $details = @(@($output) + @($errorOutput)) -join "`n"
        throw "git $($Arguments -join ' ') failed: $details"
    }

    return @($output)
}

function Test-HarnessGitRepository {
    param(
        [string]$RepoRoot
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $insideWorkTree = (& git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return $exitCode -eq 0 -and $insideWorkTree -eq "true"
}

function Normalize-HarnessPath {
    param(
        [string]$Path
    )

    return ($Path -replace "\\", "/").Trim()
}

function Test-HarnessPathPattern {
    param(
        [string]$Path,
        [string]$Pattern
    )

    $normalizedPath = Normalize-HarnessPath -Path $Path
    $normalizedPattern = Normalize-HarnessPath -Path $Pattern

    if ($normalizedPath -like $normalizedPattern) {
        return $true
    }

    if ($normalizedPattern.StartsWith("**/")) {
        $withoutPrefix = $normalizedPattern.Substring(3)
        return $normalizedPath -like $withoutPrefix
    }

    return $false
}

function Test-HarnessAnyPathPattern {
    param(
        [string]$Path,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if (Test-HarnessPathPattern -Path $Path -Pattern $pattern) {
            return $true
        }
    }

    return $false
}

function Get-HarnessChangedPaths {
    param(
        [string]$RepoRoot
    )

    $paths = @()
    $paths += Invoke-HarnessGit -RepoRoot $RepoRoot -Arguments @("diff", "--name-only")
    $paths += Invoke-HarnessGit -RepoRoot $RepoRoot -Arguments @("diff", "--cached", "--name-only")
    $paths += Invoke-HarnessGit -RepoRoot $RepoRoot -Arguments @("ls-files", "--others", "--exclude-standard")

    return @($paths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { Normalize-HarnessPath -Path $_ } |
        Sort-Object -Unique)
}

function Get-HarnessPathGroup {
    param(
        [string]$Path,
        [hashtable]$Config
    )

    if (Test-HarnessAnyPathPattern -Path $Path -Patterns $Config.workUnitPaths.execPlansCompleted) {
        return "exec_plan"
    }

    if (Test-HarnessAnyPathPattern -Path $Path -Patterns $Config.workUnitPaths.validation) {
        return "validation"
    }

    if (Test-HarnessAnyPathPattern -Path $Path -Patterns $Config.workUnitPaths.tests) {
        return "test"
    }

    if (Test-HarnessAnyPathPattern -Path $Path -Patterns $Config.workUnitPaths.code) {
        return "code"
    }

    if ($Path -like "docs/*" -or $Path -like "*.md" -or $Path -like ".harness/checklists/*" -or $Path -like ".harness/prompts/*") {
        return "docs_other"
    }

    return "other"
}

function Get-HarnessChangeSummary {
    param(
        [string[]]$Paths,
        [hashtable]$Config
    )

    $summary = [ordered]@{
        Code = @()
        Tests = @()
        ExecPlans = @()
        Validation = @()
        DocsOther = @()
        Other = @()
    }

    foreach ($path in $Paths) {
        switch (Get-HarnessPathGroup -Path $path -Config $Config) {
            "code" { $summary["Code"] += $path }
            "test" { $summary["Tests"] += $path }
            "exec_plan" { $summary["ExecPlans"] += $path }
            "validation" { $summary["Validation"] += $path }
            "docs_other" { $summary["DocsOther"] += $path }
            default { $summary["Other"] += $path }
        }
    }

    $featurePaths = @($summary["Code"] + $summary["Tests"])
    $workUnitDocs = @($summary["ExecPlans"] + $summary["Validation"])
    $allDocs = @($summary["ExecPlans"] + $summary["Validation"] + $summary["DocsOther"])

    return [pscustomobject]@{
        Code = @($summary["Code"])
        Tests = @($summary["Tests"])
        Feature = @($featurePaths)
        ExecPlans = @($summary["ExecPlans"])
        Validation = @($summary["Validation"])
        WorkUnitDocs = @($workUnitDocs)
        DocsOther = @($summary["DocsOther"])
        AllDocs = @($allDocs)
        Other = @($summary["Other"])
        All = @($Paths)
    }
}

function Get-HarnessBlockedPathFindings {
    param(
        [string]$RepoRoot,
        [string[]]$Paths,
        [hashtable]$Config
    )

    $findings = @()

    foreach ($path in $Paths) {
        if (Test-HarnessAnyPathPattern -Path $path -Patterns $Config.blockedPathPatterns) {
            $findings += [pscustomobject]@{
                Path = $path
                Reason = "blocked_path_pattern"
            }
            continue
        }

        $fullPath = Join-Path $RepoRoot ($path -replace "/", [IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        $file = Get-Item -LiteralPath $fullPath

        if ($file.Length -ge $Config.largeFileBytes -and (Test-HarnessAnyPathPattern -Path $path -Patterns $Config.largeOriginalDataPatterns)) {
            $findings += [pscustomobject]@{
                Path = $path
                Reason = "large_original_data"
            }
        }
    }

    return @($findings)
}

function Get-HarnessPlanId {
    param(
        [string[]]$ExecPlanPaths
    )

    if ($ExecPlanPaths.Count -eq 0) {
        return $null
    }

    return [IO.Path]::GetFileNameWithoutExtension($ExecPlanPaths[0])
}

function Get-HarnessValidationTopic {
    param(
        [string[]]$ValidationPaths
    )

    if ($ValidationPaths.Count -eq 0) {
        return $null
    }

    return [IO.Path]::GetFileNameWithoutExtension($ValidationPaths[0])
}

function New-HarnessDocsCommitMessage {
    param(
        [object]$Summary
    )

    $planId = Get-HarnessPlanId -ExecPlanPaths $Summary.ExecPlans

    if (-not [string]::IsNullOrWhiteSpace($planId)) {
        return "docs(exec-plans): complete $planId"
    }

    $topic = Get-HarnessValidationTopic -ValidationPaths $Summary.Validation

    if (-not [string]::IsNullOrWhiteSpace($topic)) {
        return "docs(validation): record $topic"
    }

    return "docs: update project documentation"
}

function Get-HarnessCurrentBranch {
    param(
        [string]$RepoRoot
    )

    $branch = @(Invoke-HarnessGit -RepoRoot $RepoRoot -Arguments @("branch", "--show-current"))

    if ($branch.Count -eq 0 -or [string]::IsNullOrWhiteSpace($branch[0])) {
        return $null
    }

    return [string]$branch[0]
}

function Get-HarnessUpstreamState {
    param(
        [string]$RepoRoot
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $upstreamOutput = & git -C $RepoRoot rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0 -or [string]::IsNullOrWhiteSpace($upstreamOutput)) {
        return [pscustomobject]@{
            HasUpstream = $false
            Upstream = $null
            Ahead = 0
            Behind = 0
        }
    }

    $countOutput = @(Invoke-HarnessGit -RepoRoot $RepoRoot -Arguments @("rev-list", "--left-right", "--count", "HEAD...@{u}"))
    $parts = @(([string]$countOutput[0]).Trim() -split "\s+")

    return [pscustomobject]@{
        HasUpstream = $true
        Upstream = [string]$upstreamOutput
        Ahead = [int]$parts[0]
        Behind = [int]$parts[1]
    }
}

function Get-HarnessFeatureCommitCountSincePush {
    param(
        [string]$RepoRoot,
        [string[]]$FeatureCommitTypes
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $subjects = & git -C $RepoRoot log --format=%s "@{u}..HEAD" 2>$null
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        return 0
    }

    $escapedTypes = @($FeatureCommitTypes | ForEach-Object { [regex]::Escape($_) })
    $typePattern = "^($($escapedTypes -join '|'))(\([^)]+\))?:"
    $count = 0

    foreach ($subject in @($subjects)) {
        if ($subject -match $typePattern) {
            $count += 1
        }
    }

    return $count
}

function Get-HarnessPushRecommendation {
    param(
        [string]$RepoRoot,
        [hashtable]$Config,
        [string]$VerificationStatus,
        [switch]$PushRequested
    )

    $branch = Get-HarnessCurrentBranch -RepoRoot $RepoRoot
    $changedPaths = @(Get-HarnessChangedPaths -RepoRoot $RepoRoot)
    $upstreamState = Get-HarnessUpstreamState -RepoRoot $RepoRoot
    $featureCommitCount = 0

    if ($upstreamState.HasUpstream) {
        $featureCommitCount = Get-HarnessFeatureCommitCountSincePush -RepoRoot $RepoRoot -FeatureCommitTypes $Config.featureCommitTypes
    }

    $status = "hold"
    $reason = "not_evaluated"

    if ($VerificationStatus -ne "Passed") {
        $reason = "verification_not_passed"
        $status = "hold_verification_not_passed"
    }
    elseif ([string]::IsNullOrWhiteSpace($branch)) {
        $reason = "detached_head"
        $status = "hold_detached_head"
    }
    elseif (Test-HarnessAnyPathPattern -Path $branch -Patterns $Config.protectedBranches) {
        $reason = "protected_branch"
        $status = "hold_protected_branch"
    }
    elseif ((-not $PushRequested) -and (-not (Test-HarnessAnyPathPattern -Path $branch -Patterns $Config.autoPushBranches))) {
        $reason = "branch_not_auto_push_enabled"
        $status = "hold_branch_not_auto_push_enabled"
    }
    elseif (-not $upstreamState.HasUpstream) {
        $reason = "missing_upstream"
        $status = "hold_missing_upstream"
    }
    elseif ($upstreamState.Behind -gt 0) {
        $reason = "upstream_behind"
        $status = "hold_upstream_behind"
    }
    elseif ($changedPaths.Count -gt 0) {
        $reason = "dirty_working_tree"
        $status = "hold_dirty_tree"
    }
    elseif ($PushRequested) {
        $reason = "user_requested_push"
        $status = "push_requested_recommended"
    }
    elseif ($featureCommitCount -ge $Config.autoPushAfterFeatureCommits) {
        $reason = "feature_commit_threshold_met"
        $status = "auto_recommended"
    }
    else {
        $reason = "feature_commit_threshold_not_met"
        $status = "hold_until_$($Config.autoPushAfterFeatureCommits)_feature_commits"
    }

    return [pscustomobject]@{
        Status = $status
        Reason = $reason
        Branch = $branch
        Upstream = $upstreamState.Upstream
        Ahead = $upstreamState.Ahead
        Behind = $upstreamState.Behind
        FeatureCommitsSincePush = $featureCommitCount
    }
}
