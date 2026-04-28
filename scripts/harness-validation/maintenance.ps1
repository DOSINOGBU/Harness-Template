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
        if ($file.LastWriteTime -ge $cutoff) {
            continue
        }

        $staleCount += 1
        Add-MaintenanceFinding -Check "maintenance-stale-active-plan" -Metadata @{
            path = "docs/exec-plans/active/$($file.Name)"
            days = [int]((Get-Date) - $file.LastWriteTime).TotalDays
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
        $todoCount = [regex]::Matches($content, '\bTODO\b').Count

        if ($todoCount -lt $threshold) {
            continue
        }

        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $findingCount += 1
        Add-MaintenanceFinding -Check "maintenance-placeholder-density" -Metadata @{
            path = $relativePath
            count = $todoCount
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
