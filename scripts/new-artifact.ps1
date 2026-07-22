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
    [ValidateSet("analysis", "validation", "run-log", "exec-plan", "incubator")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [string]$Series,

    [string]$Date,

    [ValidateSet("drafts", "active")]
    [string]$Stage = "drafts"
)

$ErrorActionPreference = "Stop"

$scriptBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptBase)) {
    $scriptBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptBase "..")).Path

$slugPattern = '^[a-z0-9][a-z0-9-]*$'

if ($Type -eq "exec-plan") {
    # Exec plans use the numbering scheme from docs/exec-plans/README.md, no date prefix.
    if ($Slug -notmatch '^\d{2}[a-z]?-[a-z0-9][a-z0-9-]*$') {
        Write-Error "Exec-plan slug must match NN[-letter]-kebab-topic (e.g. 01-auth, 01a-auth-session): '$Slug'"
        exit 1
    }

    $templatePath = Join-Path $repoRoot "docs\exec-plans\template.md"

    if (-not (Test-Path -LiteralPath $templatePath)) {
        Write-Error "Exec-plan template is missing: docs/exec-plans/template.md"
        exit 1
    }

    $planRelativeFolder = "docs/exec-plans/$Stage"
    $planFolderPath = Join-Path $repoRoot ($planRelativeFolder -replace "/", [IO.Path]::DirectorySeparatorChar)
    $planFilePath = Join-Path $planFolderPath "$Slug.md"
    $planRelativePath = "$planRelativeFolder/$Slug.md"

    if (Test-Path -LiteralPath $planFilePath) {
        Write-Error "Exec plan already exists, refusing to overwrite: $planRelativePath"
        exit 1
    }

    if (-not (Test-Path -LiteralPath $planFolderPath)) {
        New-Item -ItemType Directory -Path $planFolderPath -Force | Out-Null
    }

    Copy-Item -LiteralPath $templatePath -Destination $planFilePath
    Write-Host "[NewArtifact] created { path=$planRelativePath; type=exec-plan; stage=$Stage }"

    if ($Stage -eq "drafts") {
        Write-Host "[NewArtifact] note { next=fill the draft, get user approval, then move it to docs/exec-plans/active/ }"
    }

    exit 0
}

if ($Type -eq "incubator") {
    # Isolated small-project skeleton (docs/MODULES.md): grows in incubator/<slug>,
    # promoted to the module warehouse via scripts/promote-module.ps1.
    if ($Slug -notmatch $slugPattern) {
        Write-Error "Incubator slug must be kebab-case: '$Slug'"
        exit 1
    }

    $incubatorDir = Join-Path $repoRoot ("incubator" + [IO.Path]::DirectorySeparatorChar + $Slug)

    if (Test-Path -LiteralPath $incubatorDir) {
        Write-Error "Incubator project already exists: incubator/$Slug"
        exit 1
    }

    New-Item -ItemType Directory -Path (Join-Path $incubatorDir "src") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $incubatorDir "tests") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $incubatorDir "deploy") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $incubatorDir "src\.gitkeep") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $incubatorDir "tests\.gitkeep") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $incubatorDir "deploy\.gitkeep") -Force | Out-Null

    $utf8 = New-Object System.Text.UTF8Encoding($false)

    $readme = "# $Slug (incubator)`n`n" +
        "## Purpose`n`n<!-- what this small project does, in one paragraph -->`n`n" +
        "## Done criteria`n`n<!-- measurable conditions for promotion -->`n`n" +
        "## Public API draft`n`n<!-- what the main project will import after promotion -->`n`n" +
        "## Isolation`n`n" +
        "- Do NOT reference main source roots from here. Promote shared code first.`n" +
        "- Main code must NOT reference incubator/ paths.`n"
    [System.IO.File]::WriteAllText((Join-Path $incubatorDir "README.md"), $readme, $utf8)

    $moduleJson = "{`n  `"name`": `"$Slug`",`n  `"purpose`": `"`",`n  `"entry`": `"src/index`",`n  `"api`": []`n}`n"
    [System.IO.File]::WriteAllText((Join-Path $incubatorDir "module.json"), $moduleJson, $utf8)

    Write-Host "[NewArtifact] created { path=incubator/$Slug; type=incubator }"
    Write-Host "[NewArtifact] note { next=create an exec-plan (-Type exec-plan), fill module.json purpose/entry, develop inside the folder only }"
    exit 0
}

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

Base commit: ``TREE_HASH_PLACEHOLDER``

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

if ($content.Contains("TREE_HASH_PLACEHOLDER")) {
    $treeHash = "unavailable"

    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $resolved = & git -C $repoRoot rev-parse --short HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($resolved)) {
        $treeHash = ([string]$resolved).Trim()
    }
    $ErrorActionPreference = $previousEap

    $content = $content.Replace("TREE_HASH_PLACEHOLDER", $treeHash)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($filePath, $content, $utf8NoBom)

Write-Host "[NewArtifact] created { path=$relativeFilePath; type=$Type }"
exit 0
