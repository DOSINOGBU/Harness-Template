function Test-IsUiConformanceExcludedPath {
    param(
        [string]$RelativePath
    )

    if (Test-IsCodeHealthExcludedPath -RelativePath $RelativePath) {
        return $true
    }

    $normalizedPath = ($RelativePath -replace "\\", "/").TrimStart("/")

    foreach ($excludedPattern in @($script:harnessConfig.uiConformanceExcludedPatterns)) {
        $normalizedPattern = ([string]$excludedPattern -replace "\\", "/").TrimStart("/")

        if ([string]::IsNullOrWhiteSpace($normalizedPattern)) {
            continue
        }

        if ($normalizedPath -like $normalizedPattern) {
            return $true
        }
    }

    return $false
}

function Get-UiConformanceTargetFiles {
    $targetExtensions = @($script:harnessConfig.uiConformanceTargetExtensions)

    return @(Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
        Where-Object {
            $targetExtensions -contains $_.Extension.ToLowerInvariant() -and
            -not (Test-IsUiConformanceExcludedPath -RelativePath (Get-RepoRelativePath -FullPath $_.FullName))
        })
}

function Test-UiConformance {
    param(
        [bool]$Strict
    )

    if (-not $script:harnessConfig.uiConformanceEnabled) {
        Write-HarnessLog -Check "ui-conformance" -Status "success" -Metadata @{
            enabled = $false
        }
        return
    }

    $forbiddenPatterns = @($script:harnessConfig.uiConformanceForbiddenPatterns)

    Write-HarnessLog -Check "ui-conformance" -Status "start" -Metadata @{
        mode = $script:effectiveMode
        patterns = $forbiddenPatterns.Count
        strict = $Strict
    }

    $files = @(Get-UiConformanceTargetFiles)
    $findingCount = 0
    $maxFindingsPerFile = 10

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName

        try {
            $lines = @(Get-Content -LiteralPath $file.FullName -Encoding UTF8 -ErrorAction Stop)
        }
        catch {
            Add-CodeHealthFinding -Check "ui-conformance-read-file" -Metadata @{
                path = $relativePath
                reason = "read_failed"
                error = $_.Exception.Message
                strict = $Strict
            }
            continue
        }

        $fileFindingCount = 0

        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex += 1) {
            foreach ($forbidden in $forbiddenPatterns) {
                $pattern = [string]$forbidden.pattern

                if ([string]::IsNullOrWhiteSpace($pattern)) {
                    continue
                }

                if ($lines[$lineIndex] -notmatch $pattern) {
                    continue
                }

                $findingCount += 1
                $fileFindingCount += 1

                if ($fileFindingCount -le $maxFindingsPerFile) {
                    Add-CodeHealthFinding -Check "ui-conformance-forbidden-pattern" -Metadata @{
                        path = $relativePath
                        line = $lineIndex + 1
                        reason = [string]$forbidden.reason
                        rulesDoc = "docs/UI_RULES.md"
                        strict = $Strict
                    }
                }
            }
        }

        if ($fileFindingCount -gt $maxFindingsPerFile) {
            Add-CodeHealthFinding -Check "ui-conformance-forbidden-pattern" -Metadata @{
                path = $relativePath
                reason = "additional_findings_truncated"
                truncated = $fileFindingCount - $maxFindingsPerFile
                strict = $Strict
            }
        }
    }

    if ($findingCount -eq 0) {
        Write-HarnessLog -Check "ui-conformance" -Status "success" -Metadata @{
            scanned = $files.Count
            patterns = $forbiddenPatterns.Count
        }
        return
    }

    Write-HarnessLog -Check "ui-conformance" -Status "complete" -Metadata @{
        scanned = $files.Count
        findings = $findingCount
    }
}
