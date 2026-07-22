<#
.SYNOPSIS
    Validates harness documentation, indexes, and optional maintenance/code-health checks.

.DESCRIPTION
    Loads scripts under scripts/harness-validation/, merges .harness/config.json when present,
    and runs structural checks for this template or a consuming project (see -Mode / -Strict).

.PARAMETER Mode
    Template (default): placeholders and soft maintenance rules. Project: stricter failures where configured.

.PARAMETER RepoRoot
    Repository root to validate. Defaults to the parent of the scripts folder.

.PARAMETER Strict
    Equivalent to -Mode Project for effective strictness (backward-compatible alias).

.PARAMETER Maintenance
    Run drift and maintenance checks (stale plans, unregistered harness files, etc.).

.PARAMETER CodeHealth
    Run file-size and duplication heuristics on code paths.

.PARAMETER TreatWarningsAsErrors
    Exit with code 1 when any warning was recorded, even if no hard failures occurred.

.EXAMPLE
    pwsh -File scripts/validate-harness.ps1 -Mode Template

.EXAMPLE
    pwsh -File scripts/validate-harness.ps1 -Maintenance -CodeHealth -Mode Project

.EXAMPLE
    pwsh -File scripts/validate-harness.ps1 -TreatWarningsAsErrors
#>
[CmdletBinding()]
param(
    [ValidateSet("Template", "Project")]
    [string]$Mode = "Template",
    [string]$RepoRoot,
    [switch]$Strict,
    [switch]$Maintenance,
    [switch]$CodeHealth,
    [switch]$TreatWarningsAsErrors
)

$scriptBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptBase)) {
    $scriptBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    if ([string]::IsNullOrWhiteSpace($scriptBase)) {
        throw "Could not determine script directory to default RepoRoot (PSScriptRoot and command path are empty)."
    }
    $RepoRoot = Join-Path $scriptBase ".."
}

# Keep Korean and other UTF-8 document output readable in Windows PowerShell.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Write-Error "Repo root path does not exist: $RepoRoot"
    exit 1
}

try {
    $repoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
}
catch {
    throw "Could not resolve repo root path: $RepoRoot. $($_.Exception.Message)"
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$script:errorCount = 0
$script:warningCount = 0
$script:maintenanceFindingCount = 0
$script:codeHealthFindingCount = 0
$script:effectiveMode = if ($Strict) { "Project" } else { $Mode }
$script:isProjectMode = $script:effectiveMode -eq "Project"
$script:harnessConfig = @{
    maintenanceFindingThreshold = 5
    staleActivePlanDays = 14
    placeholderTodoThreshold = 3
    placeholderPatterns = @("TODO", "FIXME", "TBD", "XXX", "???")
    requireExecPlanUsage = $true
    codeHealthWarningLines = 500
    codeHealthFeatureFreezeLines = 800
    codeHealthFailureLines = 1200
    codeHealthMarkupWarningLines = 800
    codeHealthMarkupFeatureFreezeLines = 1200
    codeHealthMarkupFailureLines = 1800
    codeHealthMigrationWarningLines = 1200
    codeHealthMigrationFeatureFreezeLines = 1800
    codeHealthMigrationFailureLines = 2400
    codeHealthLongFunctionLines = 120
    codeHealthRepeatedLineThreshold = 6
    codeHealthExcludedPaths = @(
        ".git",
        "docs",
        ".harness",
        "vendor",
        "dist",
        "build",
        "coverage",
        "node_modules"
    )
    codeHealthExcludedPatterns = @(
        "**/generated/**",
        "**/vendor/**",
        "**/*.lock",
        "**/*.generated.*",
        "**/migrations/**"
    )
    uiConformanceEnabled = $true
    uiConformanceTargetExtensions = @(
        ".astro",
        ".css",
        ".jsx",
        ".less",
        ".sass",
        ".scss",
        ".svelte",
        ".tsx",
        ".vue"
    )
    uiConformanceExcludedPatterns = @(
        "**/globals.css",
        "**/tokens.css",
        "**/*.tokens.*"
    )
    hygieneMaxUncommittedFiles = 20
    hygieneMaxUntrackedFiles = 30
    hygieneScratchThreshold = 10
    hygieneScratchPatterns = @(
        "_tmp_*",
        "tmp_*",
        "*.tmp",
        "scratch-*",
        "_validate_*",
        "_verify_*"
    )
    hygieneExceptionTtlDays = 30
    hygieneBranchBackupCommits = 5
    hygienePlanDriftMinFeatureCommits = 3
    uiConformanceForbiddenPatterns = @(
        @{ pattern = '#[0-9a-fA-F]{6}\b'; reason = "hardcoded_hex_color" },
        @{ pattern = '\b(?:bg-white|bg-black\b|(?:bg|text|border)-(?:emerald|red|green|blue|slate|gray|zinc|amber|rose)-\d{2,3})\b'; reason = "palette_literal" },
        @{ pattern = '@import\s+url\(\s*["'']?https?://'; reason = "cdn_font_import" },
        @{ pattern = 'from\s+["'']@tabler/'; reason = "forbidden_icon_package" }
    )
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
    workUnitCodePaths = @(
        "src/**",
        "app/**",
        "lib/**",
        "components/**",
        "pages/**",
        "server/**",
        "client/**",
        "api/**",
        "scripts/**"
    )
    workUnitTestPaths = @(
        "tests/**",
        "test/**",
        "__tests__/**",
        "**/*.test.*",
        "**/*.spec.*",
        "**/*.Tests.*"
    )
    workUnitExecPlanCompletedPaths = @(
        "docs/exec-plans/completed/**"
    )
    workUnitValidationPaths = @(
        "docs/validation/**"
    )
}

$moduleRoot = Join-Path $PSScriptRoot "harness-validation"
# Order matters: shared.ps1 defines logging and counters used by the rest.
$validationModules = @(
    "shared.ps1",
    "encoding.ps1",
    "config.ps1",
    "index.ps1",
    "testing.ps1",
    "maintenance.ps1",
    "hygiene.ps1",
    "code-health.ps1",
    "ui-conformance.ps1"
)

foreach ($moduleName in $validationModules) {
    $modulePath = Join-Path $moduleRoot $moduleName

    if (-not (Test-Path -LiteralPath $modulePath)) {
        throw "Harness validation module is missing: $modulePath"
    }

    . $modulePath
}

function Write-HarnessSummaryLine {
    param(
        [string]$Outcome,
        [int]$ElapsedMs
    )

    $elapsedSec = [math]::Round($ElapsedMs / 1000.0, 2)
    Write-Host (
        "[HarnessValidation] Summary ($Outcome): errors=$($script:errorCount); " +
        "warnings=$($script:warningCount); maintenanceFindings=$($script:maintenanceFindingCount); " +
        "codeHealthFindings=$($script:codeHealthFindingCount); elapsed=${elapsedSec}s"
    )
}

Write-HarnessLog -Check "validation" -Status "start" -Metadata @{
    codeHealth = [bool]$CodeHealth
    effectiveMode = $script:effectiveMode
    maintenance = [bool]$Maintenance
    mode = $Mode
    strict = [bool]$Strict
    treatWarningsAsErrors = [bool]$TreatWarningsAsErrors
}

Import-HarnessConfig
Test-DocumentationEncoding
Test-AgentsRequiredReading
Test-DocsCoreDocuments
Test-HarnessIndexSection -SectionName "Checklists" -Folder ".harness/checklists" -Check "harness-checklist"
Test-HarnessIndexSection -SectionName "Prompts" -Folder ".harness/prompts" -Check "harness-prompt"
Test-TestingTodos -CodeHealth:$CodeHealth -Maintenance:$Maintenance -Strict:$Strict

if ($Maintenance) {
    Test-MaintenanceDrift -Strict:$Strict
    Test-HygieneDrift -Strict:$Strict
}

if ($CodeHealth) {
    Test-CodeHealth -Strict:$Strict
    Test-UiConformance -Strict:$Strict
}

$stopwatch.Stop()
$elapsedMs = [int]$stopwatch.ElapsedMilliseconds
Write-Verbose "Harness validation finished in ${elapsedMs}ms."

if ($script:errorCount -gt 0) {
    Write-HarnessLog -Check "validation" -Status "failed" -Metadata @{
        effectiveMode = $script:effectiveMode
        errors = $script:errorCount
        warnings = $script:warningCount
        maintenanceFindings = $script:maintenanceFindingCount
        codeHealthFindings = $script:codeHealthFindingCount
        elapsedMs = $elapsedMs
    }
    Write-HarnessSummaryLine -Outcome "failed" -ElapsedMs $elapsedMs
    exit 1
}

if ($TreatWarningsAsErrors -and $script:warningCount -gt 0) {
    Write-HarnessLog -Check "validation" -Status "failed" -Metadata @{
        effectiveMode = $script:effectiveMode
        errors = $script:errorCount
        warnings = $script:warningCount
        maintenanceFindings = $script:maintenanceFindingCount
        codeHealthFindings = $script:codeHealthFindingCount
        elapsedMs = $elapsedMs
        reason = "treat_warnings_as_errors"
    }
    Write-HarnessSummaryLine -Outcome "failed (warnings as errors)" -ElapsedMs $elapsedMs
    exit 1
}

Write-HarnessLog -Check "validation" -Status "success" -Metadata @{
    effectiveMode = $script:effectiveMode
    errors = $script:errorCount
    warnings = $script:warningCount
    maintenanceFindings = $script:maintenanceFindingCount
    codeHealthFindings = $script:codeHealthFindingCount
    elapsedMs = $elapsedMs
}

Write-HarnessSummaryLine -Outcome "success" -ElapsedMs $elapsedMs

exit 0
