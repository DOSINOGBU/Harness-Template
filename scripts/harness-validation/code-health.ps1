function Test-IsCodeHealthExcludedPath {
    param(
        [string]$RelativePath
    )

    $normalizedPath = ($RelativePath -replace "\\", "/").TrimStart("/")
    $segments = @($normalizedPath -split "/")
    $excludedPaths = @($script:harnessConfig.codeHealthExcludedPaths)
    $excludedPatterns = @($script:harnessConfig.codeHealthExcludedPatterns)

    foreach ($excludedPath in $excludedPaths) {
        $normalizedExcludedPath = ([string]$excludedPath -replace "\\", "/").Trim("/")

        if ([string]::IsNullOrWhiteSpace($normalizedExcludedPath)) {
            continue
        }

        if ($normalizedPath -eq $normalizedExcludedPath -or $normalizedPath.StartsWith("$normalizedExcludedPath/")) {
            return $true
        }

        if ($segments -contains $normalizedExcludedPath) {
            return $true
        }
    }

    foreach ($excludedPattern in $excludedPatterns) {
        $normalizedPattern = ([string]$excludedPattern -replace "\\", "/").TrimStart("/")

        if ([string]::IsNullOrWhiteSpace($normalizedPattern)) {
            continue
        }

        if ($normalizedPath -like $normalizedPattern) {
            return $true
        }
    }

    if ($normalizedPath -eq "scripts/validate-harness.ps1") {
        return $true
    }

    $fileName = $segments[-1]
    $lockFiles = @(
        "package-lock.json",
        "pnpm-lock.yaml",
        "yarn.lock",
        "bun.lock",
        "bun.lockb",
        "Cargo.lock",
        "poetry.lock",
        "Pipfile.lock",
        "composer.lock",
        "Gemfile.lock",
        "go.sum",
        "uv.lock"
    )

    return ($lockFiles -contains $fileName)
}

function Get-CodeHealthThresholds {
    param(
        [System.IO.FileInfo]$File,
        [string]$RelativePath
    )

    $markupExtensions = @(".astro", ".css", ".html", ".jsx", ".sass", ".scss", ".svelte", ".tsx", ".vue")
    $migrationExtensions = @(".proto", ".sql")
    $normalizedPath = $RelativePath -replace "\\", "/"

    if ($migrationExtensions -contains $File.Extension.ToLowerInvariant() -or $normalizedPath -like "*/migrations/*") {
        return [pscustomobject]@{
            Category = "migration_or_schema"
            Warning = $script:harnessConfig.codeHealthMigrationWarningLines
            FeatureFreeze = $script:harnessConfig.codeHealthMigrationFeatureFreezeLines
            Failure = $script:harnessConfig.codeHealthMigrationFailureLines
        }
    }

    if ($markupExtensions -contains $File.Extension.ToLowerInvariant()) {
        return [pscustomobject]@{
            Category = "markup_or_component"
            Warning = $script:harnessConfig.codeHealthMarkupWarningLines
            FeatureFreeze = $script:harnessConfig.codeHealthMarkupFeatureFreezeLines
            Failure = $script:harnessConfig.codeHealthMarkupFailureLines
        }
    }

    return [pscustomobject]@{
        Category = "default_code"
        Warning = $script:harnessConfig.codeHealthWarningLines
        FeatureFreeze = $script:harnessConfig.codeHealthFeatureFreezeLines
        Failure = $script:harnessConfig.codeHealthFailureLines
    }
}

function Test-IsCodeHealthCandidateFile {
    param(
        [System.IO.FileInfo]$File
    )

    $relativePath = Get-RepoRelativePath -FullPath $File.FullName

    if (Test-IsCodeHealthExcludedPath -RelativePath $relativePath) {
        return $false
    }

    $codeExtensions = @(
        ".astro",
        ".bash",
        ".c",
        ".cc",
        ".cjs",
        ".cpp",
        ".cs",
        ".css",
        ".fish",
        ".go",
        ".h",
        ".hh",
        ".hpp",
        ".html",
        ".java",
        ".js",
        ".jsx",
        ".kt",
        ".kts",
        ".m",
        ".mjs",
        ".mm",
        ".php",
        ".ps1",
        ".psd1",
        ".psm1",
        ".py",
        ".rb",
        ".rs",
        ".sass",
        ".scala",
        ".scss",
        ".sh",
        ".sql",
        ".svelte",
        ".swift",
        ".ts",
        ".tsx",
        ".vue",
        ".zsh"
    )

    return ($codeExtensions -contains $File.Extension.ToLowerInvariant())
}

function Get-CodeHealthLineCount {
    param(
        [System.IO.FileInfo]$File
    )

    return (Get-Content -LiteralPath $File.FullName -ErrorAction Stop | Measure-Object -Line).Lines
}

function Get-LongFunctionCandidates {
    param(
        [System.IO.FileInfo]$File,
        [string[]]$Lines
    )

    $candidates = @()
    $threshold = $script:harnessConfig.codeHealthLongFunctionLines
    $functionStartPattern = '^\s*(function\s+[\w-]+|(?:export\s+)?(?:async\s+)?function\s+\w+|(?:export\s+)?(?:const|let|var)\s+\w+\s*=\s*(?:async\s*)?\([^)]*\)\s*=>|def\s+\w+\s*\()'
    $currentFunction = $null
    $braceDepth = 0
    $startIndent = 0

    for ($lineIndex = 0; $lineIndex -lt $Lines.Count; $lineIndex += 1) {
        $line = $Lines[$lineIndex]

        if ($null -eq $currentFunction -and $line -match $functionStartPattern) {
            $currentFunction = [pscustomobject]@{
                StartLine = $lineIndex + 1
                Name = $matches[1].Trim()
                UsesIndent = ($line -match '^\s*def\s+')
            }
            $startIndent = ($line.Length - $line.TrimStart().Length)
            $braceDepth = ([regex]::Matches($line, '\{').Count - [regex]::Matches($line, '\}').Count)

            if ($braceDepth -le 0 -and -not $currentFunction.UsesIndent) {
                $braceDepth = 1
            }

            continue
        }

        if ($null -eq $currentFunction) {
            continue
        }

        if ($currentFunction.UsesIndent) {
            $trimmedLine = $line.Trim()
            $indent = $line.Length - $line.TrimStart().Length
            $isFunctionEnd = $trimmedLine.Length -gt 0 -and $indent -le $startIndent -and ($lineIndex + 1) -gt $currentFunction.StartLine

            if (-not $isFunctionEnd -and $lineIndex -lt ($Lines.Count - 1)) {
                continue
            }
        }
        else {
            $braceDepth += ([regex]::Matches($line, '\{').Count - [regex]::Matches($line, '\}').Count)

            if ($braceDepth -gt 0 -and $lineIndex -lt ($Lines.Count - 1)) {
                continue
            }
        }

        $endLine = $lineIndex + 1
        $lineCount = $endLine - $currentFunction.StartLine + 1

        if ($lineCount -ge $threshold) {
            $candidates += [pscustomobject]@{
                name = $currentFunction.Name
                startLine = $currentFunction.StartLine
                lines = $lineCount
            }
        }

        $currentFunction = $null
        $braceDepth = 0
    }

    return $candidates
}

function Get-RepeatedLineCandidates {
    param(
        [string[]]$Lines
    )

    $threshold = $script:harnessConfig.codeHealthRepeatedLineThreshold
    $lineCounts = @{}

    foreach ($line in $Lines) {
        $normalizedLine = ($line.Trim() -replace '\s+', ' ')

        if ($normalizedLine.Length -lt 40) {
            continue
        }

        if ($normalizedLine -match '^[{}\[\]();,]+$') {
            continue
        }

        if (-not $lineCounts.ContainsKey($normalizedLine)) {
            $lineCounts[$normalizedLine] = 0
        }

        $lineCounts[$normalizedLine] += 1
    }

    return @(
        $lineCounts.GetEnumerator() |
            Where-Object { $_.Value -ge $threshold } |
            Sort-Object Value -Descending |
            Select-Object -First 5
    )
}

function Test-CodeHealth {
    param(
        [bool]$Strict
    )

    Write-HarnessLog -Check "code-health" -Status "start" -Metadata @{
        mode = $script:effectiveMode
        strict = $Strict
        warningThreshold = $script:harnessConfig.codeHealthWarningLines
        featureFreezeThreshold = $script:harnessConfig.codeHealthFeatureFreezeLines
        failureThreshold = $script:harnessConfig.codeHealthFailureLines
    }

    $files = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
        Where-Object { Test-IsCodeHealthCandidateFile -File $_ })

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $thresholds = Get-CodeHealthThresholds -File $file -RelativePath $relativePath

        try {
            $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)
            $lineCount = $lines.Count
        }
        catch {
            Add-CodeHealthFinding -Check "code-health-read-file" -FailsInStrict $true -Metadata @{
                path = $relativePath
                reason = "read_failed"
                error = $_.Exception.Message
                mode = $script:effectiveMode
                strict = $Strict
            }
            continue
        }

        if ($lineCount -ge $thresholds.Failure) {
            Add-CodeHealthFinding -Check "code-health-large-file" -FailsInStrict $true -Metadata @{
                category = $thresholds.Category
                path = $relativePath
                lines = $lineCount
                threshold = $thresholds.Failure
                reason = "file_size_failure_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
            continue
        }

        if ($lineCount -ge $thresholds.FeatureFreeze) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                category = $thresholds.Category
                path = $relativePath
                lines = $lineCount
                threshold = $thresholds.FeatureFreeze
                reason = "feature_freeze_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
            continue
        }

        if ($lineCount -ge $thresholds.Warning) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                category = $thresholds.Category
                path = $relativePath
                lines = $lineCount
                threshold = $thresholds.Warning
                reason = "large_file_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
        }

        foreach ($candidate in @(Get-LongFunctionCandidates -File $file -Lines $lines)) {
            Add-CodeHealthFinding -Check "code-health-long-function" -Metadata @{
                path = $relativePath
                name = $candidate.name
                startLine = $candidate.startLine
                lines = $candidate.lines
                threshold = $script:harnessConfig.codeHealthLongFunctionLines
                mode = $script:effectiveMode
                strict = $Strict
            }
        }

        foreach ($candidate in @(Get-RepeatedLineCandidates -Lines $lines)) {
            Add-CodeHealthFinding -Check "code-health-repeated-line" -Metadata @{
                path = $relativePath
                count = $candidate.Value
                threshold = $script:harnessConfig.codeHealthRepeatedLineThreshold
                sample = $candidate.Key.Substring(0, [Math]::Min(80, $candidate.Key.Length))
                mode = $script:effectiveMode
                strict = $Strict
            }
        }
    }

    if ($script:codeHealthFindingCount -eq 0) {
        Write-HarnessLog -Check "code-health-large-file" -Status "success" -Metadata @{
            scanned = $files.Count
            warningThreshold = $script:harnessConfig.codeHealthWarningLines
            featureFreezeThreshold = $script:harnessConfig.codeHealthFeatureFreezeLines
            failureThreshold = $script:harnessConfig.codeHealthFailureLines
        }
    }

    Write-HarnessLog -Check "code-health" -Status "complete" -Metadata @{
        scanned = $files.Count
        findings = $script:codeHealthFindingCount
    }
}
