param(
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$script:errorCount = 0
$script:warningCount = 0

function Write-HarnessLog {
    param(
        [string]$Check,
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[HarnessValidation] $Check $Status { $metadataText }"
}

function Add-HarnessFailure {
    param(
        [string]$Check,
        [hashtable]$Metadata
    )

    $script:errorCount += 1
    Write-HarnessLog -Check $Check -Status "failed" -Metadata $Metadata
}

function Add-HarnessWarning {
    param(
        [string]$Check,
        [hashtable]$Metadata
    )

    $script:warningCount += 1
    Write-HarnessLog -Check $Check -Status "warning" -Metadata $Metadata
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

    $matches = [regex]::Matches($Content, '`([^`]+)`')
    $paths = @()

    foreach ($match in $matches) {
        $paths += $match.Groups[1].Value
    }

    return $paths
}

function Resolve-RepoRelativePath {
    param(
        [string]$RelativePath
    )

    $normalizedPath = $RelativePath -replace "/", [IO.Path]::DirectorySeparatorChar
    return Join-Path $repoRoot $normalizedPath
}

function Test-RequiredPath {
    param(
        [string]$Check,
        [string]$RelativePath
    )

    $resolvedPath = Resolve-RepoRelativePath -RelativePath $RelativePath

    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        Add-HarnessFailure -Check $Check -Metadata @{
            path = $RelativePath
            reason = "missing"
        }
        return
    }

    Write-HarnessLog -Check $Check -Status "success" -Metadata @{
        path = $RelativePath
    }
}

function Test-AgentsRequiredReading {
    $agentsPath = Resolve-RepoRelativePath -RelativePath "AGENTS.md"
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $agentsPath
    $requiredReading = Get-MarkdownSection -Content $content -Heading "Required Reading"
    $paths = Get-BacktickPaths -Content $requiredReading

    foreach ($path in $paths) {
        Test-RequiredPath -Check "required-reading" -RelativePath $path
    }

    Write-HarnessLog -Check "required-reading-summary" -Status "success" -Metadata @{
        count = $paths.Count
    }
}

function Test-DocsCoreDocuments {
    $docsReadmePath = Resolve-RepoRelativePath -RelativePath "docs/README.md"
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $docsReadmePath
    $coreDocuments = Get-MarkdownSection -Content $content -Heading "Core Documents"
    $paths = Get-BacktickPaths -Content $coreDocuments

    foreach ($path in $paths) {
        Test-RequiredPath -Check "docs-core-document" -RelativePath (Join-Path "docs" $path)
    }

    Write-HarnessLog -Check "docs-core-document-summary" -Status "success" -Metadata @{
        count = $paths.Count
    }
}

function Test-HarnessIndexSection {
    param(
        [string]$SectionName,
        [string]$Folder,
        [string]$Check
    )

    $harnessReadmePath = Resolve-RepoRelativePath -RelativePath ".harness/README.md"
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $harnessReadmePath
    $section = Get-MarkdownSection -Content $content -Heading $SectionName
    $paths = Get-BacktickPaths -Content $section

    foreach ($path in $paths) {
        Test-RequiredPath -Check $Check -RelativePath (Join-Path $Folder $path)
    }

    Write-HarnessLog -Check "$Check-summary" -Status "success" -Metadata @{
        count = $paths.Count
    }
}

function Test-TestingTodos {
    $testingPath = Resolve-RepoRelativePath -RelativePath "docs/TESTING.md"
    $todoCommandRows = Get-Content -Encoding UTF8 -LiteralPath $testingPath |
        Where-Object { $_ -match '^\|\s*[^|]+\|\s*`TODO`\s*\|' }
    $todoCount = @($todoCommandRows).Count

    if ($todoCount -eq 0) {
        Write-HarnessLog -Check "testing-todo" -Status "success" -Metadata @{
            count = 0
            strict = [bool]$Strict
        }
        return
    }

    $metadata = @{
        count = $todoCount
        strict = [bool]$Strict
        path = "docs/TESTING.md"
    }

    if ($Strict) {
        Add-HarnessFailure -Check "testing-todo" -Metadata $metadata
        return
    }

    Add-HarnessWarning -Check "testing-todo" -Metadata $metadata
}

Write-HarnessLog -Check "validation" -Status "start" -Metadata @{
    strict = [bool]$Strict
}

Test-AgentsRequiredReading
Test-DocsCoreDocuments
Test-HarnessIndexSection -SectionName "Checklists" -Folder ".harness/checklists" -Check "harness-checklist"
Test-HarnessIndexSection -SectionName "Prompts" -Folder ".harness/prompts" -Check "harness-prompt"
Test-TestingTodos

if ($script:errorCount -gt 0) {
    Write-HarnessLog -Check "validation" -Status "failed" -Metadata @{
        errors = $script:errorCount
        warnings = $script:warningCount
    }
    exit 1
}

Write-HarnessLog -Check "validation" -Status "success" -Metadata @{
    errors = $script:errorCount
    warnings = $script:warningCount
}

exit 0
