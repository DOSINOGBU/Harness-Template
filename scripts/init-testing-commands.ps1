param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

$repoRootPath = (Resolve-Path $RepoRoot).Path
$testingPath = Join-Path $repoRootPath "docs/TESTING.md"
$commandOrder = @("install", "dev", "test", "lint", "typecheck", "build")

function Write-BootstrapLog {
    param(
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[TestingBootstrap] $Status { $metadataText }"
}

function Get-JsonFile {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return Get-Content -Raw -Encoding UTF8 -LiteralPath $Path | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-BootstrapLog -Status "warning" -Metadata @{
            path = $Path
            reason = "invalid_json"
            error = $_.Exception.Message
        }
        return $null
    }
}

function Get-NodePackageManager {
    if (Test-Path -LiteralPath (Join-Path $repoRootPath "pnpm-lock.yaml")) { return "pnpm" }
    if (Test-Path -LiteralPath (Join-Path $repoRootPath "yarn.lock")) { return "yarn" }
    if (Test-Path -LiteralPath (Join-Path $repoRootPath "bun.lockb")) { return "bun" }
    if (Test-Path -LiteralPath (Join-Path $repoRootPath "bun.lock")) { return "bun" }
    if (Test-Path -LiteralPath (Join-Path $repoRootPath "package-lock.json")) { return "npm" }
    return "npm"
}

function New-CommandResult {
    param(
        [string]$Id,
        [string]$Command,
        [string]$Note
    )

    return [pscustomobject]@{
        id = $Id
        command = $Command
        note = $Note
    }
}

function Get-NodeCommands {
    $packagePath = Join-Path $repoRootPath "package.json"
    $packageJson = Get-JsonFile -Path $packagePath

    if ($null -eq $packageJson) {
        return @()
    }

    $manager = Get-NodePackageManager
    $scripts = $packageJson.scripts
    $commands = @()
    $scriptMap = @{
        dev = @("dev", "start")
        test = @("test")
        lint = @("lint")
        typecheck = @("typecheck", "type-check", "tsc")
        build = @("build")
    }

    $commands += New-CommandResult -Id "install" -Command "$manager install" -Note "package.json detected"

    foreach ($id in @("dev", "test", "lint", "typecheck", "build")) {
        foreach ($scriptName in $scriptMap[$id]) {
            if ($null -ne $scripts -and $null -ne $scripts.$scriptName) {
                $runCommand = if ($manager -eq "npm") { "npm run $scriptName" } else { "$manager $scriptName" }
                $commands += New-CommandResult -Id $id -Command $runCommand -Note "package script '$scriptName'"
                break
            }
        }
    }

    return $commands
}

function Get-PythonCommands {
    $pyprojectPath = Join-Path $repoRootPath "pyproject.toml"

    if (-not (Test-Path -LiteralPath $pyprojectPath)) {
        return @()
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $pyprojectPath
    $commands = @()
    $runner = if (Test-Path -LiteralPath (Join-Path $repoRootPath "uv.lock")) { "uv run" } elseif (Test-Path -LiteralPath (Join-Path $repoRootPath "poetry.lock")) { "poetry run" } else { "python -m" }

    if (Test-Path -LiteralPath (Join-Path $repoRootPath "uv.lock")) {
        $commands += New-CommandResult -Id "install" -Command "uv sync" -Note "uv.lock detected"
    }
    elseif (Test-Path -LiteralPath (Join-Path $repoRootPath "poetry.lock")) {
        $commands += New-CommandResult -Id "install" -Command "poetry install" -Note "poetry.lock detected"
    }
    else {
        $commands += New-CommandResult -Id "install" -Command "python -m pip install -e ." -Note "pyproject.toml detected"
    }

    if ($content -match "pytest") {
        $commands += New-CommandResult -Id "test" -Command "$runner pytest" -Note "pytest detected"
    }

    if ($content -match "ruff") {
        $commands += New-CommandResult -Id "lint" -Command "$runner ruff check ." -Note "ruff detected"
    }

    if ($content -match "mypy") {
        $commands += New-CommandResult -Id "typecheck" -Command "$runner mypy ." -Note "mypy detected"
    }

    return $commands
}

function Get-RustCommands {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRootPath "Cargo.toml"))) {
        return @()
    }

    return @(
        New-CommandResult -Id "test" -Command "cargo test" -Note "Cargo.toml detected"
        New-CommandResult -Id "typecheck" -Command "cargo check" -Note "Cargo.toml detected"
        New-CommandResult -Id "build" -Command "cargo build" -Note "Cargo.toml detected"
    )
}

function Get-GoCommands {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRootPath "go.mod"))) {
        return @()
    }

    return @(
        New-CommandResult -Id "test" -Command "go test ./..." -Note "go.mod detected"
        New-CommandResult -Id "build" -Command "go build ./..." -Note "go.mod detected"
    )
}

function Merge-CommandResults {
    $allCommands = @()
    $allCommands += Get-NodeCommands
    $allCommands += Get-PythonCommands
    $allCommands += Get-RustCommands
    $allCommands += Get-GoCommands
    $merged = @{}

    foreach ($id in $commandOrder) {
        $match = @($allCommands | Where-Object { $_.id -eq $id } | Select-Object -First 1)

        if ($match.Count -gt 0) {
            $merged[$id] = $match[0]
        }
        else {
            $merged[$id] = New-CommandResult -Id $id -Command "TODO" -Note "no command detected"
        }
    }

    return $merged
}

function Get-TestingCommandRows {
    param(
        [string[]]$Lines
    )

    $rows = @()
    $insideCommands = $false
    $seenSeparator = $false

    for ($lineIndex = 0; $lineIndex -lt $Lines.Count; $lineIndex += 1) {
        $line = $Lines[$lineIndex]

        if ($line -match '^##\s+Commands\s*$') {
            $insideCommands = $true
            continue
        }

        if ($insideCommands -and $line -match '^##\s+') {
            break
        }

        if (-not $insideCommands -or $line -notmatch '^\|') {
            continue
        }

        if ($line -match '^\|\s*-+') {
            $seenSeparator = $true
            continue
        }

        if (-not $seenSeparator) {
            continue
        }

        $rows += [pscustomobject]@{
            index = $lineIndex
            line = $line
        }
    }

    return $rows
}

function Update-TestingCommands {
    param(
        [hashtable]$CommandsById
    )

    if (-not (Test-Path -LiteralPath $testingPath)) {
        throw "docs/TESTING.md not found at $testingPath"
    }

    $lines = @(Get-Content -Encoding UTF8 -LiteralPath $testingPath)
    $commandRows = @(Get-TestingCommandRows -Lines $lines)

    if ($commandRows.Count -lt $commandOrder.Count) {
        throw "docs/TESTING.md command table has $($commandRows.Count) rows; expected at least $($commandOrder.Count)"
    }

    for ($rowIndex = 0; $rowIndex -lt $commandOrder.Count; $rowIndex += 1) {
        $id = $commandOrder[$rowIndex]
        $commandInfo = $CommandsById[$id]
        $cells = @($commandRows[$rowIndex].line.Trim().Trim("|").Split("|") | ForEach-Object { $_.Trim() })
        $label = $cells[0]
        $lines[$commandRows[$rowIndex].index] = "| $label | ``$($commandInfo.command)`` | $($commandInfo.note) |"
    }

    Set-Content -Encoding UTF8 -LiteralPath $testingPath -Value $lines
}

$commandsById = Merge-CommandResults

foreach ($id in $commandOrder) {
    $commandInfo = $commandsById[$id]
    $status = if ($commandInfo.command -eq "TODO") { "not_detected" } else { "detected" }
    Write-BootstrapLog -Status $status -Metadata @{
        id = $id
        command = $commandInfo.command
        note = $commandInfo.note
    }
}

if ($Apply) {
    Update-TestingCommands -CommandsById $commandsById
    Write-BootstrapLog -Status "applied" -Metadata @{
        path = "docs/TESTING.md"
    }
}
else {
    Write-BootstrapLog -Status "dry_run" -Metadata @{
        apply = "use -Apply to update docs/TESTING.md"
    }
}
