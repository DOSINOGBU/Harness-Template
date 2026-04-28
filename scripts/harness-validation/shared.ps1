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

    if ($script:isProjectMode) {
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

    if ($script:isProjectMode -and $FailsInStrict) {
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
