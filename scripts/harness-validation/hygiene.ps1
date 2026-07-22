# Anti-drift hygiene checks, each learned from a real failure observed in a
# consuming project (tradepilot audit, 2026-07-22):
# - working-tree backlog   (253 uncommitted files, oldest 16 days)
# - branch backup          (15 commits with no upstream = one disk away from loss)
# - scratch sprawl         (58 throwaway _tmp_/_validate_ scripts left behind)
# - expired exceptions     (open-ended "예외·분리예정" tags that never expire)
# - plan coverage drift    (26 experiments over 12 days with zero plan updates)

function Invoke-HygieneGit {
    param([string[]]$Arguments)

    # Native stderr under EAP=Stop throws in Windows PowerShell; relax around git.
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & git -C $repoRoot @Arguments 2>$null
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousEap

    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

function Test-WorkingTreeHygiene {
    param(
        [bool]$Strict
    )

    $statusResult = Invoke-HygieneGit -Arguments @("status", "--porcelain")

    if ($statusResult.ExitCode -ne 0) {
        Write-HarnessLog -Check "hygiene-working-tree" -Status "success" -Metadata @{ reason = "not_a_git_repo" }
        return
    }

    $lines = @($statusResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $untrackedCount = @($lines | Where-Object { $_.StartsWith("??") }).Count
    $modifiedCount = $lines.Count - $untrackedCount
    $findingCount = 0

    if ($modifiedCount -ge $script:harnessConfig.hygieneMaxUncommittedFiles) {
        $findingCount += 1
        Add-MaintenanceFinding -Check "hygiene-uncommitted-backlog" -Metadata @{
            modified = $modifiedCount
            threshold = $script:harnessConfig.hygieneMaxUncommittedFiles
            hint = "verified work must be committed in work units (docs/VERSION_CONTROL.md); do not let changes pile up"
            strict = $Strict
        }
    }

    if ($untrackedCount -ge $script:harnessConfig.hygieneMaxUntrackedFiles) {
        $findingCount += 1
        Add-MaintenanceFinding -Check "hygiene-untracked-backlog" -Metadata @{
            untracked = $untrackedCount
            threshold = $script:harnessConfig.hygieneMaxUntrackedFiles
            hint = "decide commit or .gitignore for each untracked file; undecided files hide real changes"
            strict = $Strict
        }
    }

    if ($findingCount -eq 0) {
        Write-HarnessLog -Check "hygiene-working-tree" -Status "success" -Metadata @{
            modified = $modifiedCount
            untracked = $untrackedCount
        }
    }
}

function Test-BranchBackupHygiene {
    param(
        [bool]$Strict
    )

    $branchResult = Invoke-HygieneGit -Arguments @("rev-parse", "--abbrev-ref", "HEAD")

    if ($branchResult.ExitCode -ne 0 -or $branchResult.Output.Count -eq 0) {
        Write-HarnessLog -Check "hygiene-branch-backup" -Status "success" -Metadata @{ reason = "not_a_git_repo" }
        return
    }

    $branch = ([string]$branchResult.Output[0]).Trim()

    if ($branch -eq "HEAD") {
        Write-HarnessLog -Check "hygiene-branch-backup" -Status "success" -Metadata @{ reason = "detached_head" }
        return
    }

    foreach ($protectedPattern in @($script:harnessConfig.protectedBranches)) {
        if ($branch -like $protectedPattern) {
            Write-HarnessLog -Check "hygiene-branch-backup" -Status "success" -Metadata @{ branch = $branch; reason = "protected_branch" }
            return
        }
    }

    $upstreamResult = Invoke-HygieneGit -Arguments @("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")

    if ($upstreamResult.ExitCode -eq 0) {
        Write-HarnessLog -Check "hygiene-branch-backup" -Status "success" -Metadata @{ branch = $branch; reason = "has_upstream" }
        return
    }

    $unpushedResult = Invoke-HygieneGit -Arguments @("log", "--oneline", "HEAD", "--not", "--remotes")
    $unpushedCount = @($unpushedResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count

    if ($unpushedCount -ge $script:harnessConfig.hygieneBranchBackupCommits) {
        Add-MaintenanceFinding -Check "hygiene-branch-backup" -Metadata @{
            branch = $branch
            unpushedCommits = $unpushedCount
            threshold = $script:harnessConfig.hygieneBranchBackupCommits
            hint = "branch has no upstream; push it (git push -u origin $branch) before more work accumulates"
            strict = $Strict
        }
        return
    }

    Write-HarnessLog -Check "hygiene-branch-backup" -Status "success" -Metadata @{
        branch = $branch
        unpushedCommits = $unpushedCount
    }
}

function Test-ScratchSprawl {
    param(
        [bool]$Strict
    )

    $excludedDirs = @(".git", "node_modules", "vendor", "dist", "build", "coverage", ".next")
    $patterns = @($script:harnessConfig.hygieneScratchPatterns)
    $matches = @()

    $allFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $full = $_.FullName
            -not ($excludedDirs | Where-Object { $full -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $_ + [IO.Path]::DirectorySeparatorChar) })
        })

    foreach ($file in $allFiles) {
        foreach ($pattern in $patterns) {
            if ($file.Name -like $pattern) {
                $matches += Get-RepoRelativePath -FullPath $file.FullName
                break
            }
        }
    }

    if ($matches.Count -ge $script:harnessConfig.hygieneScratchThreshold) {
        Add-MaintenanceFinding -Check "hygiene-scratch-sprawl" -Metadata @{
            count = $matches.Count
            threshold = $script:harnessConfig.hygieneScratchThreshold
            sample = (@($matches | Select-Object -First 5) -join ", ")
            hint = "throwaway scripts/files belong in a scratch dir outside the repo, or become real validated artifacts (docs/ARTIFACTS.md)"
            strict = $Strict
        }
        return
    }

    Write-HarnessLog -Check "hygiene-scratch-sprawl" -Status "success" -Metadata @{
        count = $matches.Count
        patterns = ($patterns -join ",")
    }
}

function Test-ExpiredExceptions {
    param(
        [bool]$Strict
    )

    $ledgerPath = Resolve-RepoRelativePath -RelativePath ".harness/exceptions.json"

    if (-not (Test-Path -LiteralPath $ledgerPath)) {
        Write-HarnessLog -Check "hygiene-expired-exception" -Status "success" -Metadata @{ count = 0 }
        return
    }

    try {
        $entries = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $ledgerPath | ConvertFrom-Json)
    }
    catch {
        Add-HarnessWarning -Check "hygiene-expired-exception" -Metadata @{
            path = ".harness/exceptions.json"
            reason = "invalid_json"
        }
        return
    }

    $today = (Get-Date).Date
    $expiredCount = 0

    foreach ($entry in $entries) {
        $expiresValue = [datetime]::MinValue

        if (-not [datetime]::TryParse([string]$entry.expires, [ref]$expiresValue)) {
            $expiredCount += 1
            Add-MaintenanceFinding -Check "hygiene-expired-exception" -Metadata @{
                type = [string]$entry.type
                reason = "missing_or_invalid_expiry"
                exceptionReason = [string]$entry.reason
                strict = $Strict
            }
            continue
        }

        if ($expiresValue.Date -ge $today) {
            continue
        }

        $expiredCount += 1
        Add-MaintenanceFinding -Check "hygiene-expired-exception" -Metadata @{
            type = [string]$entry.type
            expired = $expiresValue.ToString("yyyy-MM-dd")
            exceptionReason = [string]$entry.reason
            paths = [string]$entry.paths
            hint = "resolve the underlying debt or consciously renew the entry with a new expiry - exceptions may not live forever"
            strict = $Strict
        }
    }

    if ($expiredCount -eq 0) {
        Write-HarnessLog -Check "hygiene-expired-exception" -Status "success" -Metadata @{
            count = $entries.Count
        }
    }
}

function Test-PlanCoverageDrift {
    param(
        [bool]$Strict
    )

    $windowDays = $script:harnessConfig.staleActivePlanDays
    $since = "$windowDays days ago"

    $subjectsResult = Invoke-HygieneGit -Arguments @("log", "--since=$since", "--format=%s")

    if ($subjectsResult.ExitCode -ne 0) {
        Write-HarnessLog -Check "hygiene-plan-coverage" -Status "success" -Metadata @{ reason = "not_a_git_repo" }
        return
    }

    $typeAlternation = (@($script:harnessConfig.featureCommitTypes) -join "|")
    $featureCommitCount = @($subjectsResult.Output | Where-Object { $_ -match "^($typeAlternation)(\(|:)" }).Count

    $planLogResult = Invoke-HygieneGit -Arguments @("log", "--since=$since", "--oneline", "--", "docs/exec-plans")
    $planCommitCount = @($planLogResult.Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count

    if ($featureCommitCount -ge $script:harnessConfig.hygienePlanDriftMinFeatureCommits -and $planCommitCount -eq 0) {
        Add-MaintenanceFinding -Check "hygiene-plan-coverage" -Metadata @{
            featureCommits = $featureCommitCount
            planCommits = 0
            windowDays = $windowDays
            hint = "feature work is landing without any exec-plan updates; plan-before-code is drifting (docs/exec-plans/README.md)"
            strict = $Strict
        }
        return
    }

    Write-HarnessLog -Check "hygiene-plan-coverage" -Status "success" -Metadata @{
        featureCommits = $featureCommitCount
        planCommits = $planCommitCount
        windowDays = $windowDays
    }
}

function Test-HygieneDrift {
    param(
        [bool]$Strict
    )

    Test-WorkingTreeHygiene -Strict:$Strict
    Test-BranchBackupHygiene -Strict:$Strict
    Test-ScratchSprawl -Strict:$Strict
    Test-ExpiredExceptions -Strict:$Strict
    Test-PlanCoverageDrift -Strict:$Strict
}
