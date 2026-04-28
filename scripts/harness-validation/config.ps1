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

    Set-PositiveIntegerConfigValue -Key "maintenanceFindingThreshold" -Value $config.validation.maintenanceFindingThreshold
    Set-PositiveIntegerConfigValue -Key "staleActivePlanDays" -Value $config.validation.staleActivePlanDays
    Set-PositiveIntegerConfigValue -Key "placeholderTodoThreshold" -Value $config.validation.placeholderTodoThreshold
    Set-StringArrayConfigValue -Key "placeholderPatterns" -Value $config.validation.placeholderPatterns
    Set-BooleanConfigValue -Key "requireExecPlanUsage" -Value $config.validation.requireExecPlanUsage
    Set-PositiveIntegerConfigValue -Key "codeHealthWarningLines" -Value $config.validation.codeHealth.warningLines
    Set-PositiveIntegerConfigValue -Key "codeHealthFeatureFreezeLines" -Value $config.validation.codeHealth.featureFreezeLines
    Set-PositiveIntegerConfigValue -Key "codeHealthFailureLines" -Value $config.validation.codeHealth.failureLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMarkupWarningLines" -Value $config.validation.codeHealth.markupWarningLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMarkupFeatureFreezeLines" -Value $config.validation.codeHealth.markupFeatureFreezeLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMarkupFailureLines" -Value $config.validation.codeHealth.markupFailureLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMigrationWarningLines" -Value $config.validation.codeHealth.migrationWarningLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMigrationFeatureFreezeLines" -Value $config.validation.codeHealth.migrationFeatureFreezeLines
    Set-PositiveIntegerConfigValue -Key "codeHealthMigrationFailureLines" -Value $config.validation.codeHealth.migrationFailureLines
    Set-PositiveIntegerConfigValue -Key "codeHealthLongFunctionLines" -Value $config.validation.codeHealth.longFunctionLines
    Set-PositiveIntegerConfigValue -Key "codeHealthRepeatedLineThreshold" -Value $config.validation.codeHealth.repeatedLineThreshold
    Set-StringArrayConfigValue -Key "codeHealthExcludedPaths" -Value $config.validation.codeHealth.excludedPaths
    Set-StringArrayConfigValue -Key "codeHealthExcludedPatterns" -Value $config.validation.codeHealth.excludedPatterns

    if ($script:errorCount -eq $errorCountBeforeValidation) {
        Write-HarnessLog -Check "config" -Status "success" -Metadata @{
            path = ".harness/config.json"
            source = "file"
        }
    }
}
