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

function Get-MarkdownHeadingsWithLocation {
    param(
        [string]$Content
    )

    $matches = [regex]::Matches($Content, '(?m)^(?<Hashes>#{1,6})\s+(?<Title>.+?)\s*$')
    $headings = @()

    foreach ($match in $matches) {
        $lineNumber = ([regex]::Matches($Content.Substring(0, $match.Index), "`n")).Count + 1

        $headings += [pscustomobject]@{
            Index = $match.Index
            Level = $match.Groups["Hashes"].Value.Length
            Title = $match.Groups["Title"].Value.Trim()
            Line = $lineNumber
        }
    }

    return @($headings)
}

function Add-ExecPlanFormatFinding {
    param(
        [string]$Path,
        [string]$Reason,
        [string]$Heading,
        [int]$ExpectedLevel,
        [Nullable[int]]$ActualLevel,
        [Nullable[int]]$Line,
        [bool]$Strict
    )

    $metadata = @{
        path = $Path
        reason = $Reason
        heading = $Heading
        expectedLevel = $ExpectedLevel
        strict = $Strict
    }

    if ($null -ne $ActualLevel) {
        $metadata.actualLevel = $ActualLevel
    }

    if ($null -ne $Line) {
        $metadata.line = $Line
    }

    Add-MaintenanceFinding -Check "maintenance-exec-plan-format" -Metadata $metadata
}

function Test-ExecPlanHeadingSequence {
    param(
        [object[]]$Headings,
        [string[]]$ExpectedTitles,
        [int]$ExpectedLevel,
        [string]$Path,
        [bool]$Strict
    )

    $findingCount = 0
    $previousIndex = -1

    foreach ($expectedTitle in $ExpectedTitles) {
        $matches = @($Headings | Where-Object { $_.Title -ceq $expectedTitle })

        if ($matches.Count -eq 0) {
            $findingCount += 1
            Add-ExecPlanFormatFinding -Path $Path -Reason "missing_heading" -Heading $expectedTitle -ExpectedLevel $ExpectedLevel -ActualLevel $null -Line $null -Strict:$Strict
            continue
        }

        $heading = $matches[0]

        if ($heading.Level -ne $ExpectedLevel) {
            $findingCount += 1
            Add-ExecPlanFormatFinding -Path $Path -Reason "wrong_heading_depth" -Heading $expectedTitle -ExpectedLevel $ExpectedLevel -ActualLevel $heading.Level -Line $heading.Line -Strict:$Strict
        }

        if ($heading.Index -lt $previousIndex) {
            $findingCount += 1
            Add-ExecPlanFormatFinding -Path $Path -Reason "heading_order" -Heading $expectedTitle -ExpectedLevel $ExpectedLevel -ActualLevel $heading.Level -Line $heading.Line -Strict:$Strict
            continue
        }

        $previousIndex = $heading.Index
    }

    return $findingCount
}

function Test-ExecPlanHeadingSet {
    param(
        [object[]]$Headings,
        [string[]]$ExpectedTitles,
        [int]$ExpectedLevel,
        [string]$Path,
        [bool]$Strict
    )

    $findingCount = 0
    $levelHeadings = @($Headings | Where-Object { $_.Level -eq $ExpectedLevel })

    foreach ($heading in $levelHeadings) {
        if ($ExpectedTitles -cnotcontains $heading.Title) {
            $findingCount += 1
            Add-ExecPlanFormatFinding -Path $Path -Reason "unexpected_heading" -Heading $heading.Title -ExpectedLevel $ExpectedLevel -ActualLevel $heading.Level -Line $heading.Line -Strict:$Strict
        }
    }

    foreach ($expectedTitle in $ExpectedTitles) {
        $matches = @($levelHeadings | Where-Object { $_.Title -ceq $expectedTitle } | Sort-Object Index)

        if ($matches.Count -le 1) {
            continue
        }

        foreach ($heading in @($matches | Select-Object -Skip 1)) {
            $findingCount += 1
            Add-ExecPlanFormatFinding -Path $Path -Reason "duplicate_heading" -Heading $heading.Title -ExpectedLevel $ExpectedLevel -ActualLevel $heading.Level -Line $heading.Line -Strict:$Strict
        }
    }

    return $findingCount
}

function ConvertFrom-CodePoints {
    param(
        [int[]]$CodePoints
    )

    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

function Test-ExecPlanFormat {
    param(
        [bool]$Strict
    )

    $requiredHeadings = @(
        "Status",
        "Goal",
        "Scope",
        "Depends On",
        "Blocks",
        "Parallel Work",
        "Quality Gate",
        "Long Running Work",
        "Steps",
        "Validation",
        "Risks",
        "Result"
    )
    $requiredResultHeadings = @(
        (ConvertFrom-CodePoints -CodePoints @(50836, 52397, 32, 54869, 51064)),
        (ConvertFrom-CodePoints -CodePoints @(48320, 44221, 32, 49324, 54637)),
        (ConvertFrom-CodePoints -CodePoints @(44160, 51613)),
        (ConvertFrom-CodePoints -CodePoints @(44208, 44284, 32, 54869, 51064)),
        "CodeHealth",
        (ConvertFrom-CodePoints -CodePoints @(47532, 49828, 53356, 50752, 32, 45796, 51020, 32, 54032, 45800))
    )
    $planFolders = @(
        "docs/exec-plans/active",
        "docs/exec-plans/completed"
    )
    $files = @()

    foreach ($folder in $planFolders) {
        $folderPath = Resolve-RepoRelativePath -RelativePath $folder

        if (-not (Test-Path -LiteralPath $folderPath)) {
            continue
        }

        $files += @(Get-ChildItem -LiteralPath $folderPath -Filter "*.md" -File)
    }

    $findingCount = 0

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        $headings = @(Get-MarkdownHeadingsWithLocation -Content $content)

        $findingCount += Test-ExecPlanHeadingSequence -Headings $headings -ExpectedTitles $requiredHeadings -ExpectedLevel 2 -Path $relativePath -Strict:$Strict
        $findingCount += Test-ExecPlanHeadingSet -Headings $headings -ExpectedTitles $requiredHeadings -ExpectedLevel 2 -Path $relativePath -Strict:$Strict

        $resultHeading = @($headings | Where-Object { $_.Title -ceq "Result" -and $_.Level -eq 2 } | Sort-Object Index | Select-Object -First 1)

        if ($resultHeading.Count -eq 0) {
            continue
        }

        $resultStart = $resultHeading[0].Index
        $nextTopHeading = @($headings |
            Where-Object { $_.Level -eq 2 -and $_.Index -gt $resultStart } |
            Sort-Object Index |
            Select-Object -First 1)
        $resultEnd = if ($nextTopHeading.Count -gt 0) { $nextTopHeading[0].Index } else { [int]::MaxValue }
        $resultHeadings = @($headings | Where-Object { $_.Index -gt $resultStart -and $_.Index -lt $resultEnd })

        $findingCount += Test-ExecPlanHeadingSequence -Headings $resultHeadings -ExpectedTitles $requiredResultHeadings -ExpectedLevel 3 -Path $relativePath -Strict:$Strict
        $findingCount += Test-ExecPlanHeadingSet -Headings $resultHeadings -ExpectedTitles $requiredResultHeadings -ExpectedLevel 3 -Path $relativePath -Strict:$Strict
    }

    if ($findingCount -eq 0) {
        Write-HarnessLog -Check "maintenance-exec-plan-format" -Status "success" -Metadata @{
            scanned = $files.Count
        }
    }
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
    Test-ExecPlanFormat -Strict:$Strict
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
