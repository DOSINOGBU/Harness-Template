<#
.SYNOPSIS
    저장소를 읽기 전용으로 요약해 에이전트 시작 컨텍스트 로그를 출력합니다.

.DESCRIPTION
    최상위 레이아웃, AGENTS.md 필수 문서 경로 존재 여부, docs/TESTING.md 명령 표,
    일반 런타임 도구 가용성, git 상태, 마크다운 placeholder 요약, 실행 계획 개수를
    [AgentContext] 형식으로 표시합니다. 파일을 수정하지 않습니다.

.PARAMETER RepoRoot
    요약할 Git 저장소 루트 경로입니다. 기본값은 이 스크립트 위치 기준 상위 디렉터리입니다.

.PARAMETER MaxFiles
    layout file-sample에 포함할 상대 경로 샘플의 최대 개수입니다.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1 -RepoRoot "D:\my\repo" -MaxFiles 40
#>
param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),
    [int]$MaxFiles = 80
)

$ErrorActionPreference = "Stop"

# 한글 등 유니코드 로그가 Windows 콘솔에서 깨지지 않도록 출력 인코딩을 UTF-8로 맞춥니다.
$script:__utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $script:__utf8NoBom
$OutputEncoding = $script:__utf8NoBom

$repoRootPath = (Resolve-Path $RepoRoot).Path

function Write-IoEncodingMarker {
    # ASCII-only: helps agents detect that UTF-8 console output was requested (avoids guessing from mojibake).
    Write-Host "[AgentContext] io encoding { console_output=utf8 }"
}

function Write-AgentContextLog {
    param(
        [string]$Section,
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[AgentContext] $Section $Status { $metadataText }"
}

function Get-RepoRelativePath {
    param(
        [string]$FullPath
    )

    $rootUri = New-Object System.Uri (($repoRootPath.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar))
    $fileUri = New-Object System.Uri $FullPath
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString())
}

function Get-MarkdownSection {
    param(
        [string]$Content,
        [string]$Heading
    )

    $escapedHeading = [regex]::Escape($Heading)
    $sectionPattern = "(?ms)^##\s+$escapedHeading\s*\r?\n(?<Body>.*?)(?=^##\s+|\z)"
    $match = [regex]::Match($Content, $sectionPattern)

    if (-not $match.Success) {
        return ""
    }

    return $match.Groups["Body"].Value
}

function Get-BacktickPaths {
    param(
        [string]$Content
    )

    $paths = @()
    $matches = [regex]::Matches($Content, '`([^`]+)`')

    foreach ($match in $matches) {
        $paths += $match.Groups[1].Value
    }

    return @($paths | Sort-Object -Unique)
}

function Get-CommandRows {
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

        $cells = @($line.Trim().Trim("|").Split("|") | ForEach-Object { $_.Trim() })

        if ($cells.Count -ge 3) {
            $rows += [pscustomobject]@{
                purpose = $cells[0]
                command = $cells[1].Trim([char]0x60)
                note = $cells[2]
            }
        }
    }

    return $rows
}

function Write-RequiredReading {
    $agentsPath = Join-Path $repoRootPath "AGENTS.md"

    if (-not (Test-Path -LiteralPath $agentsPath)) {
        Write-AgentContextLog -Section "required-reading" -Status "missing" -Metadata @{ path = "AGENTS.md" }
        return
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $agentsPath
    $requiredReading = Get-MarkdownSection -Content $content -Heading "Required Reading"
    $paths = Get-BacktickPaths -Content $requiredReading

    Write-AgentContextLog -Section "required-reading" -Status "summary" -Metadata @{ count = $paths.Count }

    foreach ($path in $paths) {
        $resolvedPath = Join-Path $repoRootPath ($path -replace "/", [IO.Path]::DirectorySeparatorChar)
        $status = if (Test-Path -LiteralPath $resolvedPath) { "available" } else { "missing" }
        Write-AgentContextLog -Section "required-reading" -Status $status -Metadata @{ path = $path }
    }
}

function Write-TestingCommands {
    $testingPath = Join-Path $repoRootPath "docs/TESTING.md"

    if (-not (Test-Path -LiteralPath $testingPath)) {
        Write-AgentContextLog -Section "testing" -Status "missing" -Metadata @{ path = "docs/TESTING.md" }
        return
    }

    $rows = Get-CommandRows -Lines @(Get-Content -Encoding UTF8 -LiteralPath $testingPath)

    foreach ($row in $rows) {
        $status = if ($row.command -eq "TODO") { "not_configured" } else { "configured" }
        Write-AgentContextLog -Section "testing" -Status $status -Metadata @{
            purpose = $row.purpose
            command = $row.command
            note = $row.note
        }
    }
}

function Write-RuntimeAvailability {
    $commandNames = @("git", "powershell", "pwsh", "node", "npm", "python", "py", "uv", "go", "cargo", "dotnet")

    foreach ($commandName in $commandNames) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($null -eq $command) {
            Write-AgentContextLog -Section "runtime" -Status "missing" -Metadata @{ name = $commandName }
            continue
        }

        Write-AgentContextLog -Section "runtime" -Status "available" -Metadata @{
            name = $commandName
            source = $command.Source
        }
    }
}

function Write-RepoLayout {
    $items = @(Get-ChildItem -LiteralPath $repoRootPath -Force |
        Where-Object { $_.Name -ne ".git" } |
        Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name)

    foreach ($item in $items) {
        $kind = if ($item.PSIsContainer) { "dir" } else { "file" }
        Write-AgentContextLog -Section "layout" -Status "top-level" -Metadata @{
            path = $item.Name
            kind = $kind
        }
    }

    $gitSegment = [IO.Path]::DirectorySeparatorChar + ".git" + [IO.Path]::DirectorySeparatorChar
    $files = @(Get-ChildItem -LiteralPath $repoRootPath -Recurse -File |
        Where-Object { $_.FullName -notlike "*$gitSegment*" } |
        Sort-Object FullName)

    $sample = @($files | Select-Object -First $MaxFiles | ForEach-Object { Get-RepoRelativePath -FullPath $_.FullName })
    Write-AgentContextLog -Section "layout" -Status "file-sample" -Metadata @{
        totalFiles = $files.Count
        sampleCount = $sample.Count
        files = ($sample -join ", ")
    }
}

function Write-GitStatus {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRootPath ".git"))) {
        Write-AgentContextLog -Section "git" -Status "not_repo" -Metadata @{ path = $repoRootPath }
        return
    }

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $statusLines = @()
    $gitExit = $null
    try {
        $statusLines = @(& git -C $repoRootPath status --short 2>&1 | ForEach-Object { "$_" })
        $gitExit = $LASTEXITCODE
    }
    catch {
        Write-AgentContextLog -Section "git" -Status "error" -Metadata @{ error = $_.Exception.Message }
        return
    }
    finally {
        $ErrorActionPreference = $prevEap
    }

    if (($null -ne $gitExit) -and ($gitExit -ne 0)) {
        Write-AgentContextLog -Section "git" -Status "error" -Metadata @{
            exitCode = $gitExit
            error = ($statusLines -join " | ")
        }
        return
    }

    if ($statusLines.Count -eq 0) {
        Write-AgentContextLog -Section "git" -Status "clean" -Metadata @{ changes = 0 }
        return
    }

    Write-AgentContextLog -Section "git" -Status "dirty" -Metadata @{
        changes = $statusLines.Count
        sample = (($statusLines | Select-Object -First 10) -join " | ")
    }
}

function Write-PlaceholderSummary {
    $patterns = @("TODO", "FIXME", "TBD", "XXX", "???")
    $gitSegment = [IO.Path]::DirectorySeparatorChar + ".git" + [IO.Path]::DirectorySeparatorChar
    $results = @()

    foreach ($file in @(Get-ChildItem -LiteralPath $repoRootPath -Recurse -Filter "*.md" -File |
        Where-Object { $_.FullName -notlike "*$gitSegment*" })) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        $count = 0

        foreach ($pattern in $patterns) {
            $regexPattern = if ($pattern -match '^\w+$') { "\b$([regex]::Escape($pattern))\b" } else { [regex]::Escape($pattern) }
            $count += [regex]::Matches($content, $regexPattern).Count
        }

        if ($count -gt 0) {
            $results += [pscustomobject]@{
                path = Get-RepoRelativePath -FullPath $file.FullName
                count = $count
            }
        }
    }

    $topResults = @($results | Sort-Object count -Descending | Select-Object -First 8)
    $placeholderTotal = ($results | Measure-Object -Property count -Sum).Sum
    if ($null -eq $placeholderTotal) {
        $placeholderTotal = 0
    }
    Write-AgentContextLog -Section "placeholders" -Status "summary" -Metadata @{
        files = $results.Count
        total = $placeholderTotal
    }

    foreach ($result in $topResults) {
        Write-AgentContextLog -Section "placeholders" -Status "top-file" -Metadata @{
            path = $result.path
            count = $result.count
        }
    }
}

function Write-PlanSummary {
    $activePath = Join-Path $repoRootPath "docs/exec-plans/active"
    $completedPath = Join-Path $repoRootPath "docs/exec-plans/completed"
    $activePlans = if (Test-Path -LiteralPath $activePath) { @(Get-ChildItem -LiteralPath $activePath -Filter "*.md" -File) } else { @() }
    $completedPlans = if (Test-Path -LiteralPath $completedPath) { @(Get-ChildItem -LiteralPath $completedPath -Filter "*.md" -File) } else { @() }

    Write-AgentContextLog -Section "exec-plans" -Status "summary" -Metadata @{
        active = $activePlans.Count
        completed = $completedPlans.Count
    }
}

Write-IoEncodingMarker

Write-AgentContextLog -Section "bootstrap" -Status "start" -Metadata @{
    repoRoot = $repoRootPath
    mode = "read_only"
}

Write-RepoLayout
Write-RequiredReading
Write-TestingCommands
Write-RuntimeAvailability
Write-GitStatus
Write-PlaceholderSummary
Write-PlanSummary

Write-AgentContextLog -Section "bootstrap" -Status "complete" -Metadata @{
    writes = 0
}
