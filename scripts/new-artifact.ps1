<#
.SYNOPSIS
    Scaffolds a dated artifact document with the naming rules from docs/ARTIFACTS.md.

.DESCRIPTION
    Creates docs/analysis, docs/validation, or docs/agent-runs documents named
    YYYY-MM-DD-<slug>.md so artifact naming never depends on agent memory.
    Refuses to overwrite existing files. Prints the created repo-relative path.

.PARAMETER Type
    analysis | validation | run-log

.PARAMETER Slug
    Kebab-case topic slug (lowercase letters, digits, hyphens).

.PARAMETER Series
    Optional series folder (analysis only): docs/analysis/<Series>/YYYY-MM-DD-<slug>.md

.PARAMETER Date
    Optional date override (yyyy-MM-dd). Defaults to today.

.EXAMPLE
    pwsh -File scripts/new-artifact.ps1 -Type analysis -Slug harness-comparison

.EXAMPLE
    pwsh -File scripts/new-artifact.ps1 -Type analysis -Series vwap-prereg -Slug v25-overfit
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("analysis", "validation", "run-log")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [string]$Series,

    [string]$Date
)

$ErrorActionPreference = "Stop"

$scriptBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptBase)) {
    $scriptBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptBase "..")).Path

$slugPattern = '^[a-z0-9][a-z0-9-]*$'

if ($Slug -notmatch $slugPattern) {
    Write-Error "Slug must be kebab-case (lowercase letters, digits, hyphens): '$Slug'"
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($Series) -and $Series -notmatch $slugPattern) {
    Write-Error "Series must be kebab-case (lowercase letters, digits, hyphens): '$Series'"
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($Series) -and $Type -ne "analysis") {
    Write-Error "-Series is only supported for -Type analysis."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Date)) {
    $datePrefix = (Get-Date).ToString("yyyy-MM-dd")
}
else {
    $parsedDate = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($Date, "yyyy-MM-dd", $null, [System.Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
        Write-Error "Date must be yyyy-MM-dd: '$Date'"
        exit 1
    }
    $datePrefix = $parsedDate.ToString("yyyy-MM-dd")
}

$typeFolders = @{
    "analysis"   = "docs/analysis"
    "validation" = "docs/validation"
    "run-log"    = "docs/agent-runs"
}
$relativeFolder = $typeFolders[$Type]

if (-not [string]::IsNullOrWhiteSpace($Series)) {
    $relativeFolder = "$relativeFolder/$Series"
}

$folderPath = Join-Path $repoRoot ($relativeFolder -replace "/", [IO.Path]::DirectorySeparatorChar)
$fileName = "$datePrefix-$Slug.md"
$filePath = Join-Path $folderPath $fileName
$relativeFilePath = "$relativeFolder/$fileName"

if (Test-Path -LiteralPath $filePath) {
    Write-Error "Artifact already exists, refusing to overwrite: $relativeFilePath"
    exit 1
}

if (-not (Test-Path -LiteralPath $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
}

$titleSlug = ($Slug -replace "-", " ")

$templates = @{
    "analysis" = @"
# Analysis: $titleSlug

## Question

## Method

## Findings

## Conclusion

## Follow-up

- Promote durable conclusions into the relevant docs/*.md rule document and link it here.
"@
    "validation" = @"
# Validation: $titleSlug

## Scope

## Commands / Scenarios

## Results (Expected / Observed)

## Not Verified (+reason)

## Verdict
"@
    "run-log" = @"
# Agent Run: $titleSlug

## Request

## Intent

## Context Read

## Commands

## Changes

## Verification

## Loop Signals

## Risks

## Promotion
"@
}

$content = $templates[$Type].Replace("`r`n", "`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($filePath, $content, $utf8NoBom)

Write-Host "[NewArtifact] created { path=$relativeFilePath; type=$Type }"
exit 0
