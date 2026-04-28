function Test-TestingTodos {
    param(
        [bool]$CodeHealth,
        [bool]$Maintenance,
        [bool]$Strict
    )

    $testingPath = Resolve-RepoRelativePath -RelativePath "docs/TESTING.md"
    $todoCommandRows = Get-Content -Encoding UTF8 -LiteralPath $testingPath |
        Where-Object { $_ -match '^\|\s*[^|]+\|\s*`TODO`\s*\|' }
    $todoCount = @($todoCommandRows).Count

    if ($todoCount -eq 0) {
        Write-HarnessLog -Check "testing-todo" -Status "success" -Metadata @{
            count = 0
            mode = $script:effectiveMode
            strict = $Strict
        }
        return
    }

    $metadata = @{
        count = $todoCount
        mode = $script:effectiveMode
        strict = $Strict
        path = "docs/TESTING.md"
    }

    $isCodeHealthOnlyRun = $CodeHealth -and -not $Maintenance

    if ($script:isProjectMode -and -not $isCodeHealthOnlyRun) {
        Add-HarnessFailure -Check "testing-todo" -Metadata $metadata
        return
    }

    Add-HarnessWarning -Check "testing-todo" -Metadata $metadata
}
