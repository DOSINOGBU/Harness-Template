$ErrorActionPreference = "Stop"

$recommendPath = Resolve-Path (Join-Path $PSScriptRoot "..\recommend-version-control.ps1")
$commitWorkUnitPath = Resolve-Path (Join-Path $PSScriptRoot "..\commit-work-unit.ps1")
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("harness-version-control-fixtures-" + [guid]::NewGuid().ToString("N"))

function Write-FixtureLog {
    param(
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[VersionControlFixtureTest] $Status { $metadataText }"
}

function New-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Set-Content -Encoding UTF8 -LiteralPath $Path -Value $Content
}

function Invoke-CheckedGit {
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

function New-VersionControlFixture {
    param(
        [string]$Name,
        [switch]$WithRemote
    )

    $root = Join-Path $fixtureRoot $Name
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("init", "-q") | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("config", "user.name", "Fixture") | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("config", "user.email", "fixture@example.com") | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("config", "core.autocrlf", "false") | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("checkout", "-q", "-b", "feature/fixture") | Out-Null

    New-TextFile -Path (Join-Path $root ".harness/config.json") -Content @'
{
  "versionControl": {
    "autoCommitWorkUnit": true,
    "autoPushAfterFeatureCommits": 2,
    "autoPushBranches": ["codex/*", "feature/*", "fix/*"],
    "protectedBranches": ["main", "master"],
    "featureCommitTypes": ["feat", "fix", "refactor", "test", "perf"],
    "blockedPathPatterns": [".env", ".env.*", "**/.env", "**/.env.*", "**/*.pem", "**/*.key", ".lecturedigest/**", "data/raw/**", "datasets/raw/**"],
    "largeFileBytes": 10485760,
    "largeOriginalDataPatterns": ["data/raw/**", "datasets/raw/**", "**/raw/**", "**/*.zip"],
    "workUnitPaths": {
      "code": ["src/**", "scripts/**"],
      "tests": ["tests/**", "**/*.test.*", "**/*.spec.*"],
      "execPlansCompleted": ["docs/exec-plans/completed/**"],
      "validation": ["docs/validation/**"]
    }
  }
}
'@

    New-TextFile -Path (Join-Path $root "README.md") -Content "# Fixture`n"
    Invoke-CheckedGit -RepoRoot $root -Arguments @("add", ".") | Out-Null
    Invoke-CheckedGit -RepoRoot $root -Arguments @("commit", "-q", "-m", "chore(repo): seed fixture") | Out-Null

    if ($WithRemote) {
        $remotePath = Join-Path $fixtureRoot "$Name-remote.git"
        & git init --bare -q $remotePath

        if ($LASTEXITCODE -ne 0) {
            throw "git init --bare failed for $remotePath"
        }

        Invoke-CheckedGit -RepoRoot $root -Arguments @("remote", "add", "origin", $remotePath) | Out-Null
        Invoke-CheckedGit -RepoRoot $root -Arguments @("push", "-q", "-u", "origin", "feature/fixture") | Out-Null
    }

    return $root
}

function Invoke-Recommend {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments = @()
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $recommendPath -RepoRoot $RepoRoot @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output -join "`n")
    }
}

function Invoke-CommitWorkUnit {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments = @()
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $commitWorkUnitPath -RepoRoot $RepoRoot @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output -join "`n")
    }
}

function Assert-ExitCode {
    param(
        [string]$Name,
        [object]$Result,
        [int]$ExpectedExitCode
    )

    if ($Result.ExitCode -ne $ExpectedExitCode) {
        Write-Host $Result.Output
        throw "$Name expected exit code $ExpectedExitCode but got $($Result.ExitCode)"
    }

    Write-FixtureLog -Status "passed" -Metadata @{
        name = $Name
        exitCode = $Result.ExitCode
    }
}

function Assert-OutputMatches {
    param(
        [string]$Name,
        [object]$Result,
        [string]$Pattern
    )

    if ($Result.Output -notmatch $Pattern) {
        Write-Host $Result.Output
        throw "$Name expected output to match: $Pattern"
    }
}

function Add-FeatureWorkUnitChanges {
    param(
        [string]$RepoRoot
    )

    New-TextFile -Path (Join-Path $RepoRoot "src/app.ps1") -Content "'hello'`n"
    New-TextFile -Path (Join-Path $RepoRoot "tests/app.test.ps1") -Content "'test'`n"
    New-TextFile -Path (Join-Path $RepoRoot "docs/exec-plans/completed/sample-plan.md") -Content "# Sample Plan`n"
}

function Add-ValidationDoc {
    param(
        [string]$RepoRoot
    )

    New-TextFile -Path (Join-Path $RepoRoot "docs/validation/sample.md") -Content "# Validation`n"
}

function New-Commit {
    param(
        [string]$RepoRoot,
        [string]$Path,
        [string]$Content,
        [string]$Message
    )

    New-TextFile -Path (Join-Path $RepoRoot $Path) -Content $Content
    Invoke-CheckedGit -RepoRoot $RepoRoot -Arguments @("add", $Path) | Out-Null
    Invoke-CheckedGit -RepoRoot $RepoRoot -Arguments @("commit", "-q", "-m", $Message) | Out-Null
}

try {
    New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null

    $autoSplitFixture = New-VersionControlFixture -Name "auto-split"
    Add-FeatureWorkUnitChanges -RepoRoot $autoSplitFixture
    $autoSplitResult = Invoke-Recommend -RepoRoot $autoSplitFixture -Arguments @("-VerificationStatus", "Passed", "-Type", "feat", "-Scope", "sample", "-Summary", "add sample flow")
    Assert-ExitCode -Name "recommend-auto-split" -Result $autoSplitResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "recommend-auto-split" -Result $autoSplitResult -Pattern "Commit: auto_split_recommended"
    Assert-OutputMatches -Name "recommend-auto-split-message" -Result $autoSplitResult -Pattern "docs\(exec-plans\): complete sample-plan"

    $blockedFixture = New-VersionControlFixture -Name "blocked-env"
    New-TextFile -Path (Join-Path $blockedFixture ".env") -Content "TOKEN=secret`n"
    $blockedResult = Invoke-Recommend -RepoRoot $blockedFixture -Arguments @("-VerificationStatus", "Passed")
    Assert-ExitCode -Name "recommend-blocked-env" -Result $blockedResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "recommend-blocked-env" -Result $blockedResult -Pattern "Commit: hold"
    Assert-OutputMatches -Name "recommend-blocked-env-reason" -Result $blockedResult -Pattern "BlockedPaths: .env\[blocked_path_pattern\]"

    $docsOnlyFixture = New-VersionControlFixture -Name "docs-only"
    Add-ValidationDoc -RepoRoot $docsOnlyFixture
    $docsOnlyResult = Invoke-Recommend -RepoRoot $docsOnlyFixture -Arguments @("-VerificationStatus", "Partial")
    Assert-ExitCode -Name "recommend-docs-only" -Result $docsOnlyResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "recommend-docs-only" -Result $docsOnlyResult -Pattern "Commit: docs_recommended"
    Assert-OutputMatches -Name "recommend-docs-only-message" -Result $docsOnlyResult -Pattern "docs\(validation\): record sample"

    $failedFixture = New-VersionControlFixture -Name "verification-failed"
    Add-FeatureWorkUnitChanges -RepoRoot $failedFixture
    $failedResult = Invoke-Recommend -RepoRoot $failedFixture -Arguments @("-VerificationStatus", "Failed")
    Assert-ExitCode -Name "recommend-verification-failed" -Result $failedResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "recommend-verification-failed" -Result $failedResult -Pattern "Commit: hold"
    Assert-OutputMatches -Name "recommend-verification-failed-reason" -Result $failedResult -Pattern "CommitReason: verification_failed"

    $commitFixture = New-VersionControlFixture -Name "commit-split"
    Add-FeatureWorkUnitChanges -RepoRoot $commitFixture
    Add-ValidationDoc -RepoRoot $commitFixture
    $commitResult = Invoke-CommitWorkUnit -RepoRoot $commitFixture -Arguments @("-VerificationStatus", "Passed", "-Type", "feat", "-Scope", "sample", "-Summary", "add sample flow")
    Assert-ExitCode -Name "commit-work-unit-split" -Result $commitResult -ExpectedExitCode 0
    $commitSubjects = Invoke-CheckedGit -RepoRoot $commitFixture -Arguments @("log", "--format=%s", "-2")
    $commitStatus = Invoke-CheckedGit -RepoRoot $commitFixture -Arguments @("status", "--short")

    if ($commitSubjects[0] -ne "docs(exec-plans): complete sample-plan" -or $commitSubjects[1] -ne "feat(sample): add sample flow") {
        throw "commit-work-unit-split expected split commit messages, got: $($commitSubjects -join ' | ')"
    }

    if ($commitStatus.Count -ne 0) {
        throw "commit-work-unit-split expected clean working tree, got: $($commitStatus -join ' | ')"
    }

    $unrelatedFixture = New-VersionControlFixture -Name "commit-unrelated"
    Add-FeatureWorkUnitChanges -RepoRoot $unrelatedFixture
    New-TextFile -Path (Join-Path $unrelatedFixture "README.md") -Content "# Unrelated docs`n"
    $unrelatedResult = Invoke-CommitWorkUnit -RepoRoot $unrelatedFixture -Arguments @("-VerificationStatus", "Passed", "-Type", "feat", "-Scope", "sample", "-Summary", "add sample flow")

    if ($unrelatedResult.ExitCode -eq 0) {
        throw "commit-unrelated expected failure for unrelated docs"
    }

    Assert-OutputMatches -Name "commit-unrelated" -Result $unrelatedResult -Pattern "Unrelated changes prevent automatic work-unit commit"
    Write-FixtureLog -Status "passed" -Metadata @{ name = "commit-unrelated"; exitCode = $unrelatedResult.ExitCode }

    $pushHoldFixture = New-VersionControlFixture -Name "push-hold" -WithRemote
    New-Commit -RepoRoot $pushHoldFixture -Path "src/one.ps1" -Content "'one'`n" -Message "feat(sample): add one"
    New-Commit -RepoRoot $pushHoldFixture -Path "docs/exec-plans/completed/one.md" -Content "# One`n" -Message "docs(exec-plans): complete one"
    $pushHoldResult = Invoke-Recommend -RepoRoot $pushHoldFixture -Arguments @("-VerificationStatus", "Passed")
    Assert-ExitCode -Name "push-hold-one-feature" -Result $pushHoldResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "push-hold-one-feature" -Result $pushHoldResult -Pattern "Push: hold_until_2_feature_commits"

    New-Commit -RepoRoot $pushHoldFixture -Path "src/two.ps1" -Content "'two'`n" -Message "fix(sample): add two"
    $pushReadyResult = Invoke-Recommend -RepoRoot $pushHoldFixture -Arguments @("-VerificationStatus", "Passed")
    Assert-ExitCode -Name "push-ready-two-features" -Result $pushReadyResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "push-ready-two-features" -Result $pushReadyResult -Pattern "Push: auto_recommended"

    $protectedFixture = New-VersionControlFixture -Name "push-protected" -WithRemote
    Invoke-CheckedGit -RepoRoot $protectedFixture -Arguments @("checkout", "-q", "-b", "main") | Out-Null
    Invoke-CheckedGit -RepoRoot $protectedFixture -Arguments @("push", "-q", "-u", "origin", "main") | Out-Null
    New-Commit -RepoRoot $protectedFixture -Path "src/main-one.ps1" -Content "'one'`n" -Message "feat(sample): main one"
    New-Commit -RepoRoot $protectedFixture -Path "src/main-two.ps1" -Content "'two'`n" -Message "fix(sample): main two"
    $protectedResult = Invoke-Recommend -RepoRoot $protectedFixture -Arguments @("-VerificationStatus", "Passed")
    Assert-ExitCode -Name "push-protected-branch" -Result $protectedResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "push-protected-branch" -Result $protectedResult -Pattern "Push: hold_protected_branch"

    $behindFixture = New-VersionControlFixture -Name "push-behind" -WithRemote
    $otherClone = Join-Path $fixtureRoot "push-behind-other"
    & git clone -q --branch feature/fixture (Join-Path $fixtureRoot "push-behind-remote.git") $otherClone

    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed for behind fixture"
    }

    Invoke-CheckedGit -RepoRoot $otherClone -Arguments @("config", "user.name", "Fixture") | Out-Null
    Invoke-CheckedGit -RepoRoot $otherClone -Arguments @("config", "user.email", "fixture@example.com") | Out-Null
    New-Commit -RepoRoot $otherClone -Path "src/remote.ps1" -Content "'remote'`n" -Message "feat(sample): remote change"
    Invoke-CheckedGit -RepoRoot $otherClone -Arguments @("push", "-q") | Out-Null
    Invoke-CheckedGit -RepoRoot $behindFixture -Arguments @("fetch", "-q") | Out-Null
    New-Commit -RepoRoot $behindFixture -Path "src/local-one.ps1" -Content "'one'`n" -Message "feat(sample): local one"
    New-Commit -RepoRoot $behindFixture -Path "src/local-two.ps1" -Content "'two'`n" -Message "fix(sample): local two"
    $behindResult = Invoke-Recommend -RepoRoot $behindFixture -Arguments @("-VerificationStatus", "Passed")
    Assert-ExitCode -Name "push-upstream-behind" -Result $behindResult -ExpectedExitCode 0
    Assert-OutputMatches -Name "push-upstream-behind" -Result $behindResult -Pattern "Push: hold_upstream_behind"

    Write-FixtureLog -Status "complete" -Metadata @{
        root = $fixtureRoot
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
