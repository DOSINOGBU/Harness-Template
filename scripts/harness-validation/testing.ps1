function Test-TestingTodos {
    param(
        [bool]$CodeHealth,
        [bool]$Maintenance,
        [bool]$Strict
    )

    $testingPath = Resolve-RepoRelativePath -RelativePath "docs/TESTING.md"
    $lines = Get-Content -Encoding UTF8 -LiteralPath $testingPath
    $commandRows = Get-TestingCommandRows -Lines $lines
    Test-TestingCommandRows -Rows $commandRows

    $todoCommandRows = $commandRows |
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

function Get-TestingCommandRows {
    param(
        [string[]]$Lines
    )

    $rows = @()
    $insideCommands = $false
    $seenSeparator = $false

    foreach ($line in $Lines) {
        if ($line -match '^##\s+Commands\s*$') {
            $insideCommands = $true
            continue
        }

        if ($insideCommands -and $line -match '^##\s+') {
            break
        }

        if (-not $insideCommands) {
            continue
        }

        if ($line -notmatch '^\|') {
            continue
        }

        if ($line -match '^\|\s*-+') {
            $seenSeparator = $true
            continue
        }

        if (-not $seenSeparator) {
            continue
        }

        $rows += $line
    }

    return $rows
}

function Test-TestingCommandRows {
    param(
        [string[]]$Rows
    )

    $requiredRowCount = 6

    if ($Rows.Count -lt $requiredRowCount) {
        Add-HarnessFailure -Check "testing-command-row" -Metadata @{
            path = "docs/TESTING.md"
            reason = "missing_command_rows"
            count = $Rows.Count
            expected = $requiredRowCount
        }
        return
    }

    for ($index = 0; $index -lt $requiredRowCount; $index += 1) {
        $cells = @($Rows[$index].Trim().Trim("|").Split("|") | ForEach-Object { $_.Trim() })

        if ($cells.Count -lt 3) {
            Add-HarnessFailure -Check "testing-command-row" -Metadata @{
                path = "docs/TESTING.md"
                rowIndex = $index
                reason = "malformed_command_row"
            }
            continue
        }

        if ($cells[1] -notmatch '^`[^`]+`$') {
            Add-HarnessFailure -Check "testing-command-row" -Metadata @{
                path = "docs/TESTING.md"
                rowIndex = $index
                reason = "command_cell_must_be_backticked"
                value = $cells[1]
            }
        }
    }
}
