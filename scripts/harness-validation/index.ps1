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
