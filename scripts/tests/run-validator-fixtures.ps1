$ErrorActionPreference = "Stop"

$validatorPath = Resolve-Path (Join-Path $PSScriptRoot "..\validate-harness.ps1")
$bootstrapPath = Resolve-Path (Join-Path $PSScriptRoot "..\init-testing-commands.ps1")
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("harness-validator-fixtures-" + [guid]::NewGuid().ToString("N"))

function Write-FixtureLog {
    param(
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[HarnessFixtureTest] $Status { $metadataText }"
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

function New-MinimalFixture {
    param(
        [string]$Name
    )

    $root = Join-Path $fixtureRoot $Name
    New-Item -ItemType Directory -Force -Path $root | Out-Null

    New-TextFile -Path (Join-Path $root "AGENTS.md") -Content @'
# AGENTS.md

## Required Reading

| situation | documents |
|---|---|
| start | `docs/WORKFLOW.md` |
'@

    New-TextFile -Path (Join-Path $root "docs/README.md") -Content @'
# Docs Index

## Core Documents

| 문서 | 목적 |
|---|---|
| `WORKFLOW.md` | workflow |
| `TESTING.md` | testing |
'@

    New-TextFile -Path (Join-Path $root "docs/WORKFLOW.md") -Content "# Workflow`n"
    New-TextFile -Path (Join-Path $root ".harness/README.md") -Content @'
# Harness

## Checklists

| 파일 | 사용 시점 |
|---|---|

## Prompts

| 파일 | 사용 시점 |
|---|---|
'@

    New-TextFile -Path (Join-Path $root ".harness/config.json") -Content @'
{
  "validation": {
    "maintenanceFindingThreshold": 5,
    "staleActivePlanDays": 14,
    "placeholderTodoThreshold": 3,
    "placeholderPatterns": ["TODO", "FIXME", "TBD", "XXX", "???"],
    "requireExecPlanUsage": false,
    "codeHealth": {
      "warningLines": 500,
      "featureFreezeLines": 800,
      "failureLines": 1200,
      "excludedPaths": [".git", "docs", ".harness", "node_modules"],
      "excludedPatterns": ["**/generated/**"]
    }
  }
}
'@

    New-TextFile -Path (Join-Path $root "docs/TESTING.md") -Content @'
# Testing

## Commands

| purpose | command | note |
|---|---|---|
| install | `TODO` | fixture |
| dev | `TODO` | fixture |
| test | `TODO` | fixture |
| lint | `TODO` | fixture |
| typecheck | `TODO` | fixture |
| build | `TODO` | fixture |
'@

    New-Item -ItemType Directory -Force -Path (Join-Path $root "docs/exec-plans/active") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $root "docs/exec-plans/completed") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $root "docs/generated") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $root ".harness/checklists") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $root ".harness/prompts") | Out-Null

    return $root
}

function Invoke-Validator {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments
    )

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $validatorPath -RepoRoot $RepoRoot @Arguments 2>&1

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Invoke-TestingBootstrap {
    param(
        [string]$RepoRoot,
        [switch]$Apply
    )

    $arguments = @("-RepoRoot", $RepoRoot)

    if ($Apply) {
        $arguments += "-Apply"
    }

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrapPath @arguments 2>&1

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
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

try {
    $validFixture = New-MinimalFixture -Name "valid"
    Assert-ExitCode -Name "valid-template" -Result (Invoke-Validator -RepoRoot $validFixture -Arguments @("-Mode", "Template")) -ExpectedExitCode 0

    $malformedFixture = New-MinimalFixture -Name "malformed-testing"
    (Get-Content -Encoding UTF8 -LiteralPath (Join-Path $malformedFixture "docs/TESTING.md")) |
        ForEach-Object { $_ -replace '\| install \| `TODO` \|', '| install | TODO |' } |
        Set-Content -Encoding UTF8 -LiteralPath (Join-Path $malformedFixture "docs/TESTING.md")
    Assert-ExitCode -Name "malformed-testing-table" -Result (Invoke-Validator -RepoRoot $malformedFixture -Arguments @("-Mode", "Template")) -ExpectedExitCode 1

    $placeholderFixture = New-MinimalFixture -Name "placeholder"
    New-TextFile -Path (Join-Path $placeholderFixture "docs/PLACEHOLDER.md") -Content "TODO`nFIXME`n???`n"
    $placeholderResult = Invoke-Validator -RepoRoot $placeholderFixture -Arguments @("-Maintenance")
    Assert-ExitCode -Name "placeholder-patterns" -Result $placeholderResult -ExpectedExitCode 0

    if ($placeholderResult.Output -notmatch "maintenance-placeholder-density") {
        throw "placeholder-patterns expected maintenance-placeholder-density output"
    }

    $staleFixture = New-MinimalFixture -Name "stale-plan"
    $stalePlanPath = Join-Path $staleFixture "docs/exec-plans/active/old.md"
    New-TextFile -Path $stalePlanPath -Content "# Old plan`n"
    git -C $staleFixture init -q | Out-Null
    git -C $staleFixture config core.autocrlf false | Out-Null
    git -C $staleFixture add . | Out-Null
    $env:GIT_AUTHOR_DATE = "2020-01-01T00:00:00Z"
    $env:GIT_COMMITTER_DATE = "2020-01-01T00:00:00Z"
    git -C $staleFixture -c user.name=Fixture -c user.email=fixture@example.com commit -q -m "fixture" | Out-Null
    Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
    Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
    $staleResult = Invoke-Validator -RepoRoot $staleFixture -Arguments @("-Maintenance")
    Assert-ExitCode -Name "stale-active-plan" -Result $staleResult -ExpectedExitCode 0

    if ($staleResult.Output -notmatch "maintenance-stale-active-plan" -or $staleResult.Output -notmatch "source=git_log") {
        throw "stale-active-plan expected git_log stale plan output"
    }

    $configFixture = New-MinimalFixture -Name "invalid-config"
    New-TextFile -Path (Join-Path $configFixture ".harness/config.json") -Content "{ invalid json"
    Assert-ExitCode -Name "invalid-config" -Result (Invoke-Validator -RepoRoot $configFixture -Arguments @("-Mode", "Template")) -ExpectedExitCode 1

    $nodeFixture = New-MinimalFixture -Name "bootstrap-node"
    New-TextFile -Path (Join-Path $nodeFixture "package.json") -Content @'
{
  "scripts": {
    "dev": "vite",
    "test": "vitest",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "build": "vite build"
  }
}
'@
    $beforeApply = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $nodeFixture "docs/TESTING.md")
    $nodeDryRun = Invoke-TestingBootstrap -RepoRoot $nodeFixture
    Assert-ExitCode -Name "bootstrap-node-dry-run" -Result $nodeDryRun -ExpectedExitCode 0
    $afterDryRun = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $nodeFixture "docs/TESTING.md")

    if ($beforeApply -ne $afterDryRun -or $nodeDryRun.Output -notmatch "npm run test") {
        throw "bootstrap-node-dry-run should detect npm commands without changing docs/TESTING.md"
    }

    Assert-ExitCode -Name "bootstrap-node-apply" -Result (Invoke-TestingBootstrap -RepoRoot $nodeFixture -Apply) -ExpectedExitCode 0
    $afterApply = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $nodeFixture "docs/TESTING.md")

    if ($afterApply -notmatch "npm run test" -or $afterApply -notmatch "npm run build") {
        throw "bootstrap-node-apply expected docs/TESTING.md command rows to be updated"
    }

    $pythonFixture = New-MinimalFixture -Name "bootstrap-python"
    New-TextFile -Path (Join-Path $pythonFixture "pyproject.toml") -Content @'
[project]
name = "fixture"

[project.optional-dependencies]
dev = ["pytest", "ruff", "mypy"]
'@
    $pythonDryRun = Invoke-TestingBootstrap -RepoRoot $pythonFixture
    Assert-ExitCode -Name "bootstrap-python-dry-run" -Result $pythonDryRun -ExpectedExitCode 0

    if ($pythonDryRun.Output -notmatch "pytest" -or $pythonDryRun.Output -notmatch "ruff check" -or $pythonDryRun.Output -notmatch "mypy") {
        throw "bootstrap-python-dry-run expected pytest, ruff, and mypy commands"
    }

    $rustFixture = New-MinimalFixture -Name "bootstrap-rust"
    New-TextFile -Path (Join-Path $rustFixture "Cargo.toml") -Content @'
[package]
name = "fixture"
version = "0.1.0"
edition = "2021"
'@
    $rustDryRun = Invoke-TestingBootstrap -RepoRoot $rustFixture
    Assert-ExitCode -Name "bootstrap-rust-dry-run" -Result $rustDryRun -ExpectedExitCode 0

    if ($rustDryRun.Output -notmatch "cargo test" -or $rustDryRun.Output -notmatch "cargo check") {
        throw "bootstrap-rust-dry-run expected cargo commands"
    }

    $goFixture = New-MinimalFixture -Name "bootstrap-go"
    New-TextFile -Path (Join-Path $goFixture "go.mod") -Content "module fixture`n"
    $goDryRun = Invoke-TestingBootstrap -RepoRoot $goFixture
    Assert-ExitCode -Name "bootstrap-go-dry-run" -Result $goDryRun -ExpectedExitCode 0

    if ($goDryRun.Output -notmatch "go test ./..." -or $goDryRun.Output -notmatch "go build ./...") {
        throw "bootstrap-go-dry-run expected go commands"
    }

    Write-FixtureLog -Status "complete" -Metadata @{
        root = $fixtureRoot
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
