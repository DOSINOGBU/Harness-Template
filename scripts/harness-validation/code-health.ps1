function Test-IsCodeHealthExcludedPath {
    param(
        [string]$RelativePath
    )

    $normalizedPath = ($RelativePath -replace "\\", "/").TrimStart("/")
    $segments = @($normalizedPath -split "/")
    $excludedPaths = @($script:harnessConfig.codeHealthExcludedPaths)

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

function Test-CodeHealth {
    param(
        [bool]$Strict
    )

    $warningThreshold = $script:harnessConfig.codeHealthWarningLines
    $featureFreezeThreshold = $script:harnessConfig.codeHealthFeatureFreezeLines
    $failureThreshold = $script:harnessConfig.codeHealthFailureLines

    Write-HarnessLog -Check "code-health" -Status "start" -Metadata @{
        mode = $script:effectiveMode
        strict = $Strict
        warningThreshold = $warningThreshold
        featureFreezeThreshold = $featureFreezeThreshold
        failureThreshold = $failureThreshold
    }

    $files = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
        Where-Object { Test-IsCodeHealthCandidateFile -File $_ })

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName

        try {
            $lineCount = Get-CodeHealthLineCount -File $file
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

        if ($lineCount -ge $failureThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -FailsInStrict $true -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $failureThreshold
                reason = "file_size_failure_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
            continue
        }

        if ($lineCount -ge $featureFreezeThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $featureFreezeThreshold
                reason = "feature_freeze_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
            continue
        }

        if ($lineCount -ge $warningThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $warningThreshold
                reason = "large_file_candidate"
                mode = $script:effectiveMode
                strict = $Strict
            }
        }
    }

    if ($script:codeHealthFindingCount -eq 0) {
        Write-HarnessLog -Check "code-health-large-file" -Status "success" -Metadata @{
            scanned = $files.Count
            warningThreshold = $warningThreshold
            featureFreezeThreshold = $featureFreezeThreshold
            failureThreshold = $failureThreshold
        }
    }

    Write-HarnessLog -Check "code-health" -Status "complete" -Metadata @{
        scanned = $files.Count
        findings = $script:codeHealthFindingCount
    }
}
