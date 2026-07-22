<#
.SYNOPSIS
    Lints a result-report widget's HTML for docs/REPORTING.md compliance.

.DESCRIPTION
    Rendered widgets are ephemeral, so nothing normally checks whether a report
    actually followed the locked format. This linter closes that gap: it scans
    widget HTML for the required analogy, honesty callout, and gloss density.
    Used by .claude/hooks/pretool-report-lint.ps1 (before render) and runnable
    standalone against a saved HTML file for testing.

    A widget is treated as a REPORT only if it contains action buttons
    (data-prompt). Non-report widgets (mockups, diagrams, samples) are skipped,
    as is any widget containing the escape marker data-report="skip-lint".

.PARAMETER Path
    HTML file to lint (standalone use).

.OUTPUTS
    Writes findings to host. Exit 0 = compliant/skip, 1 = violations.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "[ReportLint] failed { reason=missing_file; path=$Path }"
    exit 1
}

. (Join-Path $PSScriptRoot "harness-reporting/lint.ps1")

$html = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$result = Test-ReportWidgetCompliance -Html $html -RepoRoot $repoRoot

foreach ($line in $result.Messages) {
    Write-Host $line
}

if ($result.Violations.Count -gt 0) {
    exit 1
}

exit 0
