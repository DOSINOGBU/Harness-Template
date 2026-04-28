param(
    [ValidateSet("Template", "Project")]
    [string]$Mode = "Template",
    [switch]$Strict,
    [switch]$Maintenance,
    [switch]$CodeHealth
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
    codeHealthWarningLines = 500
    codeHealthFeatureFreezeLines = 800
    codeHealthFailureLines = 1200
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
}

$moduleRoot = Join-Path $PSScriptRoot "harness-validation"
$validationModules = @(
    "shared.ps1",
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
