function Set-PositiveIntegerConfigValue {
    param(
        [string]$Key,
        [object]$Value
    )

    if ($null -eq $Value) {
        return
    }

    $parsedValue = 0

    if (-not [int]::TryParse([string]$Value, [ref]$parsedValue) -or $parsedValue -lt 1) {
        Add-HarnessFailure -Check "config" -Metadata @{
            path = ".harness/config.json"
            key = $Key
            reason = "invalid_positive_integer"
            value = $Value
        }
        return
    }

    $script:harnessConfig[$Key] = $parsedValue
}

function Set-BooleanConfigValue {
    param(
        [string]$Key,
        [object]$Value
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [bool]) {
        $script:harnessConfig[$Key] = [bool]$Value
        return
    }

    $parsedValue = $false

    if (-not [bool]::TryParse([string]$Value, [ref]$parsedValue)) {
        Add-HarnessFailure -Check "config" -Metadata @{
            path = ".harness/config.json"
            key = $Key
            reason = "invalid_boolean"
            value = $Value
        }
        return
    }

    $script:harnessConfig[$Key] = $parsedValue
}

function Set-StringArrayConfigValue {
    param(
        [string]$Key,
        [object]$Value
    )

    if ($null -eq $Value) {
        return
    }

    $script:harnessConfig[$Key] = @(
        $Value |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Import-HarnessConfig {
    $configPath = Resolve-RepoRelativePath -RelativePath ".harness/config.json"

    if (-not (Test-Path -LiteralPath $configPath)) {
        Write-HarnessLog -Check "config" -Status "warning" -Metadata @{
            path = ".harness/config.json"
            reason = "missing_using_defaults"
        }
        return
    }

    try {
        $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Add-HarnessFailure -Check "config" -Metadata @{
            path = ".harness/config.json"
            reason = "invalid_json"
            error = $_.Exception.Message
        }
        return
    }

    $errorCountBeforeValidation = $script:errorCount

    $validation = $config.validation
    if ($null -ne $validation) {
        Set-PositiveIntegerConfigValue -Key "maintenanceFindingThreshold" -Value $validation.maintenanceFindingThreshold
        Set-PositiveIntegerConfigValue -Key "staleActivePlanDays" -Value $validation.staleActivePlanDays
        Set-PositiveIntegerConfigValue -Key "placeholderTodoThreshold" -Value $validation.placeholderTodoThreshold
        Set-StringArrayConfigValue -Key "placeholderPatterns" -Value $validation.placeholderPatterns
        Set-BooleanConfigValue -Key "requireExecPlanUsage" -Value $validation.requireExecPlanUsage

        $codeHealth = $validation.codeHealth
        if ($null -ne $codeHealth) {
            Set-PositiveIntegerConfigValue -Key "codeHealthWarningLines" -Value $codeHealth.warningLines
            Set-PositiveIntegerConfigValue -Key "codeHealthFeatureFreezeLines" -Value $codeHealth.featureFreezeLines
            Set-PositiveIntegerConfigValue -Key "codeHealthFailureLines" -Value $codeHealth.failureLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMarkupWarningLines" -Value $codeHealth.markupWarningLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMarkupFeatureFreezeLines" -Value $codeHealth.markupFeatureFreezeLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMarkupFailureLines" -Value $codeHealth.markupFailureLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMigrationWarningLines" -Value $codeHealth.migrationWarningLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMigrationFeatureFreezeLines" -Value $codeHealth.migrationFeatureFreezeLines
            Set-PositiveIntegerConfigValue -Key "codeHealthMigrationFailureLines" -Value $codeHealth.migrationFailureLines
            Set-PositiveIntegerConfigValue -Key "codeHealthLongFunctionLines" -Value $codeHealth.longFunctionLines
            Set-PositiveIntegerConfigValue -Key "codeHealthRepeatedLineThreshold" -Value $codeHealth.repeatedLineThreshold
            Set-StringArrayConfigValue -Key "codeHealthExcludedPaths" -Value $codeHealth.excludedPaths
            Set-StringArrayConfigValue -Key "codeHealthExcludedPatterns" -Value $codeHealth.excludedPatterns
        }
    }

    $uiConformance = $null
    if ($null -ne $validation) {
        $uiConformance = $validation.uiConformance
    }
    if ($null -ne $uiConformance) {
        Set-BooleanConfigValue -Key "uiConformanceEnabled" -Value $uiConformance.enabled
        Set-StringArrayConfigValue -Key "uiConformanceTargetExtensions" -Value $uiConformance.targetExtensions
        Set-StringArrayConfigValue -Key "uiConformanceExcludedPatterns" -Value $uiConformance.excludedPatterns

        if ($null -ne $uiConformance.forbiddenPatterns) {
            $parsedPatterns = @()

            foreach ($entry in @($uiConformance.forbiddenPatterns)) {
                $pattern = [string]$entry.pattern

                if ([string]::IsNullOrWhiteSpace($pattern)) {
                    Add-HarnessFailure -Check "config" -Metadata @{
                        path = ".harness/config.json"
                        key = "validation.uiConformance.forbiddenPatterns"
                        reason = "missing_pattern"
                    }
                    continue
                }

                $reason = [string]$entry.reason
                if ([string]::IsNullOrWhiteSpace($reason)) {
                    $reason = "forbidden_pattern"
                }

                $parsedPatterns += @{ pattern = $pattern; reason = $reason }
            }

            $script:harnessConfig["uiConformanceForbiddenPatterns"] = $parsedPatterns
        }
    }

    $versionControl = $config.versionControl
    if ($null -ne $versionControl) {
        Set-BooleanConfigValue -Key "autoCommitWorkUnit" -Value $versionControl.autoCommitWorkUnit
        Set-PositiveIntegerConfigValue -Key "autoPushAfterFeatureCommits" -Value $versionControl.autoPushAfterFeatureCommits
        Set-StringArrayConfigValue -Key "autoPushBranches" -Value $versionControl.autoPushBranches
        Set-StringArrayConfigValue -Key "protectedBranches" -Value $versionControl.protectedBranches
        Set-StringArrayConfigValue -Key "featureCommitTypes" -Value $versionControl.featureCommitTypes
        Set-StringArrayConfigValue -Key "blockedPathPatterns" -Value $versionControl.blockedPathPatterns
        Set-PositiveIntegerConfigValue -Key "largeFileBytes" -Value $versionControl.largeFileBytes
        Set-StringArrayConfigValue -Key "largeOriginalDataPatterns" -Value $versionControl.largeOriginalDataPatterns

        $workUnitPaths = $versionControl.workUnitPaths
        if ($null -ne $workUnitPaths) {
            Set-StringArrayConfigValue -Key "workUnitCodePaths" -Value $workUnitPaths.code
            Set-StringArrayConfigValue -Key "workUnitTestPaths" -Value $workUnitPaths.tests
            Set-StringArrayConfigValue -Key "workUnitExecPlanCompletedPaths" -Value $workUnitPaths.execPlansCompleted
            Set-StringArrayConfigValue -Key "workUnitValidationPaths" -Value $workUnitPaths.validation
        }
    }

    if ($script:errorCount -eq $errorCountBeforeValidation) {
        Write-HarnessLog -Check "config" -Status "success" -Metadata @{
            path = ".harness/config.json"
            source = "file"
        }
    }
}
