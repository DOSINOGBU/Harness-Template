param(
    [switch]$Strict,
    [switch]$Maintenance,
    [switch]$CodeHealth
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$script:errorCount = 0
$script:warningCount = 0
$script:maintenanceFindingCount = 0
$script:codeHealthFindingCount = 0

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

function Add-MaintenanceFinding {
    param(
        [string]$Check,
        [hashtable]$Metadata
    )

    $script:maintenanceFindingCount += 1

    if ($Strict) {
        Add-HarnessFailure -Check $Check -Metadata $Metadata
        return
    }

    Add-HarnessWarning -Check $Check -Metadata $Metadata
}

function Add-CodeHealthFinding {
    param(
        [string]$Check,
        [hashtable]$Metadata,
        [bool]$FailsInStrict = $false
    )

    $script:codeHealthFindingCount += 1

    if ($Strict -and $FailsInStrict) {
        Add-HarnessFailure -Check $Check -Metadata $Metadata
        return
    }

    Add-HarnessWarning -Check $Check -Metadata $Metadata
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

function Get-RepoRelativePath {
    param(
        [string]$FullPath
    )

    $rootUri = New-Object System.Uri (($repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar))
    $fileUri = New-Object System.Uri $FullPath
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString())
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
        [string]$Check
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
            strict = [bool]$Strict
        }
    }

    if ($missingCount -eq 0) {
        Write-HarnessLog -Check $Check -Status "success" -Metadata @{
            count = $files.Count
        }
    }
}

function Test-StaleActivePlans {
    $activePlanFolder = Resolve-RepoRelativePath -RelativePath "docs/exec-plans/active"
    $thresholdDays = 14
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
            strict = [bool]$Strict
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
            strict = [bool]$Strict
        }
    }

    if ($todoCount -eq 0) {
        Write-HarnessLog -Check "maintenance-generated-todo" -Status "success" -Metadata @{
            count = $files.Count
        }
    }
}

function Test-PlaceholderDensity {
    $threshold = 3
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
            strict = [bool]$Strict
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
    Write-HarnessLog -Check "maintenance" -Status "start" -Metadata @{
        strict = [bool]$Strict
    }

    Test-UnregisteredHarnessFiles -SectionName "Checklists" -Folder ".harness/checklists" -Check "maintenance-unregistered-checklist"
    Test-UnregisteredHarnessFiles -SectionName "Prompts" -Folder ".harness/prompts" -Check "maintenance-unregistered-prompt"
    Test-StaleActivePlans
    Test-GeneratedTodoTimestamps
    Test-PlaceholderDensity

    if ($script:maintenanceFindingCount -ge 5) {
        $metadata = @{
            count = $script:maintenanceFindingCount
            threshold = 5
            strict = [bool]$Strict
        }

        if ($Strict) {
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

function Test-IsCodeHealthExcludedPath {
    param(
        [string]$RelativePath
    )

    $normalizedPath = ($RelativePath -replace "\\", "/").TrimStart("/")
    $segments = @($normalizedPath -split "/")
    $excludedSegments = @(
        ".git",
        "docs",
        ".harness",
        "generated",
        "vendor",
        "dist",
        "build",
        "coverage",
        "node_modules"
    )

    foreach ($segment in $segments) {
        if ($excludedSegments -contains $segment) {
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
    $warningThreshold = 500
    $featureFreezeThreshold = 800
    $failureThreshold = 1200

    Write-HarnessLog -Check "code-health" -Status "start" -Metadata @{
        strict = [bool]$Strict
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
                strict = [bool]$Strict
            }
            continue
        }

        if ($lineCount -ge $failureThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -FailsInStrict $true -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $failureThreshold
                reason = "file_size_failure_candidate"
                strict = [bool]$Strict
            }
            continue
        }

        if ($lineCount -ge $featureFreezeThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $featureFreezeThreshold
                reason = "feature_freeze_candidate"
                strict = [bool]$Strict
            }
            continue
        }

        if ($lineCount -ge $warningThreshold) {
            Add-CodeHealthFinding -Check "code-health-large-file" -Metadata @{
                path = $relativePath
                lines = $lineCount
                threshold = $warningThreshold
                reason = "large_file_candidate"
                strict = [bool]$Strict
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

    $isCodeHealthOnlyRun = $CodeHealth -and -not $Maintenance

    if ($Strict -and -not $isCodeHealthOnlyRun) {
        Add-HarnessFailure -Check "testing-todo" -Metadata $metadata
        return
    }

    Add-HarnessWarning -Check "testing-todo" -Metadata $metadata
}

Write-HarnessLog -Check "validation" -Status "start" -Metadata @{
    codeHealth = [bool]$CodeHealth
    maintenance = [bool]$Maintenance
    strict = [bool]$Strict
}

Test-AgentsRequiredReading
Test-DocsCoreDocuments
Test-HarnessIndexSection -SectionName "Checklists" -Folder ".harness/checklists" -Check "harness-checklist"
Test-HarnessIndexSection -SectionName "Prompts" -Folder ".harness/prompts" -Check "harness-prompt"
Test-TestingTodos

if ($Maintenance) {
    Test-MaintenanceDrift
}

if ($CodeHealth) {
    Test-CodeHealth
}

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
