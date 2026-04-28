function Get-HarnessRegisteredNames {
    param(
        [string]$SectionName
    )

    $harnessReadmePath = Resolve-RepoRelativePath -RelativePath ".harness/README.md"
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $harnessReadmePath
    $section = Get-MarkdownSection -Content $content -Heading $SectionName
    $paths = Get-BacktickPaths -Content $section

    return @($paths | ForEach-Object { [IO.Path]::GetFileName($_) } | Sort-Object -Unique)
}

function Test-UnregisteredHarnessFiles {
    param(
        [string]$SectionName,
        [string]$Folder,
        [string]$Check,
        [bool]$Strict
    )

    $registeredNames = @(Get-HarnessRegisteredNames -SectionName $SectionName)
    $folderPath = Resolve-RepoRelativePath -RelativePath $Folder
    $files = @(Get-ChildItem -LiteralPath $folderPath -Filter "*.md" -File)
    $missingCount = 0

    foreach ($file in $files) {
        if ($registeredNames -contains $file.Name) {
            continue
        }

        $missingCount += 1
        Add-MaintenanceFinding -Check $Check -Metadata @{
            path = (Join-Path $Folder $file.Name)
            reason = "not_registered"
            strict = $Strict
        }
    }

    if ($missingCount -eq 0) {
        Write-HarnessLog -Check $Check -Status "success" -Metadata @{
            count = $files.Count
        }
    }
}

function Test-StaleActivePlans {
    param(
        [bool]$Strict
    )

    $activePlanFolder = Resolve-RepoRelativePath -RelativePath "docs/exec-plans/active"
    $thresholdDays = $script:harnessConfig.staleActivePlanDays
    $cutoff = (Get-Date).AddDays(-1 * $thresholdDays)
    $files = @(Get-ChildItem -LiteralPath $activePlanFolder -Filter "*.md" -File)
    $staleCount = 0

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $lastChanged = Get-FileLastChangedTime -File $file

        if ($lastChanged.Value -ge $cutoff) {
            continue
        }

        $staleCount += 1
        Add-MaintenanceFinding -Check "maintenance-stale-active-plan" -Metadata @{
            path = $relativePath
            days = [int]((Get-Date) - $lastChanged.Value).TotalDays
            source = $lastChanged.Source
            thresholdDays = $thresholdDays
            strict = $Strict
        }
    }

    if ($staleCount -eq 0) {
        Write-HarnessLog -Check "maintenance-stale-active-plan" -Status "success" -Metadata @{
            count = $files.Count
            thresholdDays = $thresholdDays
        }
    }
}

function Get-FileLastChangedTime {
    param(
        [System.IO.FileInfo]$File
    )

    $relativePath = Get-RepoRelativePath -FullPath $File.FullName

    try {
        $timestamp = git -C $repoRoot log -1 --format=%ct -- $relativePath 2>$null

        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($timestamp)) {
            return [pscustomobject]@{
                Value = [DateTimeOffset]::FromUnixTimeSeconds([int64]$timestamp.Trim()).LocalDateTime
                Source = "git_log"
            }
        }
    }
    catch {
        # Fall back below when git is unavailable or the file is not tracked.
    }

    return [pscustomobject]@{
        Value = $File.LastWriteTime
        Source = "fallback_last_write_time"
    }
}

function Test-GeneratedTodoTimestamps {
    param(
        [bool]$Strict
    )

    $generatedFolder = Resolve-RepoRelativePath -RelativePath "docs/generated"
    $files = @(Get-ChildItem -LiteralPath $generatedFolder -Filter "*.md" -File)
    $todoCount = 0

    foreach ($file in $files) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName

        if ($content -notmatch 'Generated at:\s*`?TODO`?') {
            continue
        }

        $todoCount += 1
        Add-MaintenanceFinding -Check "maintenance-generated-todo" -Metadata @{
            path = "docs/generated/$($file.Name)"
            reason = "generated_at_todo"
            strict = $Strict
        }
    }

    if ($todoCount -eq 0) {
        Write-HarnessLog -Check "maintenance-generated-todo" -Status "success" -Metadata @{
            count = $files.Count
        }
    }
}

function Test-PlaceholderDensity {
    param(
        [bool]$Strict
    )

    $threshold = $script:harnessConfig.placeholderTodoThreshold
    $files = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter "*.md" -File |
        Where-Object { $_.FullName -notmatch "\\.git\\" })
    $findingCount = 0

    foreach ($file in $files) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        $placeholderCount = Get-PlaceholderCount -Content $content

        if ($placeholderCount -lt $threshold) {
            continue
        }

        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $findingCount += 1
        Add-MaintenanceFinding -Check "maintenance-placeholder-density" -Metadata @{
            path = $relativePath
            count = $placeholderCount
            patterns = ($script:harnessConfig.placeholderPatterns -join ",")
            threshold = $threshold
            strict = $Strict
        }
    }

    if ($findingCount -eq 0) {
        Write-HarnessLog -Check "maintenance-placeholder-density" -Status "success" -Metadata @{
            scanned = $files.Count
            threshold = $threshold
        }
    }
}

function Get-PlaceholderCount {
    param(
        [string]$Content
    )

    $count = 0

    foreach ($pattern in @($script:harnessConfig.placeholderPatterns)) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        if ($pattern -match '^\w+$') {
            $regexPattern = "\b$([regex]::Escape($pattern))\b"
        }
        else {
            $regexPattern = [regex]::Escape($pattern)
        }

        $count += [regex]::Matches($Content, $regexPattern).Count
    }

    return $count
}

function Test-ExecPlanUsage {
    param(
        [bool]$Strict
    )

    if (-not $script:harnessConfig.requireExecPlanUsage) {
        Write-HarnessLog -Check "maintenance-exec-plan-usage" -Status "success" -Metadata @{
            enabled = $false
        }
        return
    }

    $activePlanFolder = Resolve-RepoRelativePath -RelativePath "docs/exec-plans/active"
    $completedPlanFolder = Resolve-RepoRelativePath -RelativePath "docs/exec-plans/completed"
    $activePlans = @(Get-ChildItem -LiteralPath $activePlanFolder -Filter "*.md" -File)
    $completedPlans = @(Get-ChildItem -LiteralPath $completedPlanFolder -Filter "*.md" -File)
    $planCount = $activePlans.Count + $completedPlans.Count

    if ($planCount -gt 0) {
        Write-HarnessLog -Check "maintenance-exec-plan-usage" -Status "success" -Metadata @{
            active = $activePlans.Count
            completed = $completedPlans.Count
        }
        return
    }

    Add-MaintenanceFinding -Check "maintenance-exec-plan-usage" -Metadata @{
        active = 0
        completed = 0
        reason = "no_exec_plans_found"
        strict = $Strict
    }
}

function Test-MaintenanceDrift {
    param(
        [bool]$Strict
    )

    Write-HarnessLog -Check "maintenance" -Status "start" -Metadata @{
        mode = $script:effectiveMode
        strict = $Strict
    }

    Test-UnregisteredHarnessFiles -SectionName "Checklists" -Folder ".harness/checklists" -Check "maintenance-unregistered-checklist" -Strict:$Strict
    Test-UnregisteredHarnessFiles -SectionName "Prompts" -Folder ".harness/prompts" -Check "maintenance-unregistered-prompt" -Strict:$Strict
    Test-StaleActivePlans -Strict:$Strict
    Test-GeneratedTodoTimestamps -Strict:$Strict
    Test-PlaceholderDensity -Strict:$Strict
    Test-ExecPlanUsage -Strict:$Strict

    $findingThreshold = $script:harnessConfig.maintenanceFindingThreshold

    if ($script:maintenanceFindingCount -ge $findingThreshold) {
        $metadata = @{
            count = $script:maintenanceFindingCount
            threshold = $findingThreshold
            mode = $script:effectiveMode
            strict = $Strict
        }

        if ($script:isProjectMode) {
            Add-HarnessFailure -Check "maintenance-finding-threshold" -Metadata $metadata
        }
        else {
            Add-HarnessWarning -Check "maintenance-finding-threshold" -Metadata $metadata
        }
    }

    Write-HarnessLog -Check "maintenance" -Status "complete" -Metadata @{
        findings = $script:maintenanceFindingCount
    }
}
