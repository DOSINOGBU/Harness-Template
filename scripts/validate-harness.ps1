param(
    [ValidateSet("Template", "Project")]
    [string]$Mode = "Template",
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [switch]$Strict,
    [switch]$Maintenance,
    [switch]$CodeHealth
)

# Keep Korean and other UTF-8 document output readable in Windows PowerShell.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $RepoRoot).Path
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
$validationModules = @(
    "shared.ps1",
    "encoding.ps1",
    "config.ps1",
    "index.ps1",
    "testing.ps1",
    "maintenance.ps1",
    "code-health.ps1"
)

foreach ($moduleName in $validationModules) {
    $modulePath = Join-Path $moduleRoot $moduleName

    if (-not (Test-Path -LiteralPath $modulePath)) {
        throw "Harness validation module is missing: $modulePath"
    }

    . $modulePath
}

Write-HarnessLog -Check "validation" -Status "start" -Metadata @{
    codeHealth = [bool]$CodeHealth
    effectiveMode = $script:effectiveMode
    maintenance = [bool]$Maintenance
    mode = $Mode
    strict = [bool]$Strict
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
}

if ($CodeHealth) {
    Test-CodeHealth -Strict:$Strict
}

if ($script:errorCount -gt 0) {
    Write-HarnessLog -Check "validation" -Status "failed" -Metadata @{
        effectiveMode = $script:effectiveMode
        errors = $script:errorCount
        warnings = $script:warningCount
    }
    exit 1
}

Write-HarnessLog -Check "validation" -Status "success" -Metadata @{
    effectiveMode = $script:effectiveMode
    errors = $script:errorCount
    warnings = $script:warningCount
}

exit 0
