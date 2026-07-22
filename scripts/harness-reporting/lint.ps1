# Shared report-widget linter (docs/REPORTING.md enforcement).
# ASCII source only (PS 5.1 reads BOM-less scripts as ANSI); all Korean anchors
# are loaded from .harness/reporting.json at runtime, never hardcoded here.

function Test-ReportWidgetCompliance {
    param(
        [string]$Html,
        [string]$RepoRoot
    )

    $violations = @()
    $warnings = @()
    $messages = @()

    if ([string]::IsNullOrWhiteSpace($Html)) {
        return [pscustomobject]@{ IsReport = $false; Violations = @(); Warnings = @(); Messages = @("[ReportLint] skip { reason=empty }") }
    }

    # Escape hatch for genuine non-report widgets that happen to have buttons.
    if ($Html -match 'data-report\s*=\s*["'']skip-lint["'']') {
        return [pscustomobject]@{ IsReport = $false; Violations = @(); Warnings = @(); Messages = @("[ReportLint] skip { reason=skip_marker }") }
    }

    # A widget is a REPORT only if it carries action buttons (data-prompt).
    # Mockups, diagrams, samples without action buttons are out of scope.
    if ($Html -notmatch 'data-prompt') {
        return [pscustomobject]@{ IsReport = $false; Violations = @(); Warnings = @(); Messages = @("[ReportLint] skip { reason=not_a_report_no_action_buttons }") }
    }

    # --- analogy: at least one anchor term from reporting.json must appear ---
    $anchors = @()
    $reportingPath = Join-Path $RepoRoot ".harness/reporting.json"

    if (Test-Path -LiteralPath $reportingPath) {
        try {
            $reporting = Get-Content -Raw -Encoding UTF8 -LiteralPath $reportingPath | ConvertFrom-Json
            $anchors = @($reporting.analogyAnchors | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        catch {
        }
    }

    if ($anchors.Count -gt 0) {
        $hasAnchor = $false

        foreach ($anchor in $anchors) {
            if ($Html.Contains([string]$anchor)) { $hasAnchor = $true; break }
        }

        if (-not $hasAnchor) {
            $violations += "analogy_missing"
        }
    }

    # --- honesty callout: alert-triangle icon or bg-warning band (ASCII signals) ---
    if ($Html -notmatch 'alert-triangle' -and $Html -notmatch 'bg-warning' -and $Html -notmatch '#BA7517') {
        $violations += "honesty_callout_missing"
    }

    # --- gloss density: technical tokens should carry a Korean parenthetical ---
    # Korean range built from code points to keep this source ASCII.
    $ko = "[" + [char]0xAC00 + "-" + [char]0xD7A3 + "]"
    $codeTokens = @()
    $codeTokens += @([regex]::Matches($Html, '<code>[^<]{2,}</code>'))
    $codeTokens += @([regex]::Matches($Html, '\b[A-Z][A-Z_]{3,}\b'))
    $codeTokens += @([regex]::Matches($Html, '\b[a-z][a-z0-9-]*\.(ps1|psm1|mjs|js|json)\b'))
    $koreanParens = @([regex]::Matches($Html, "\([^)]*$ko[^)]*\)"))

    if ($codeTokens.Count -ge 3 -and ($koreanParens.Count * 2) -lt $codeTokens.Count) {
        $violations += "gloss_sparse(code=$($codeTokens.Count),gloss=$($koreanParens.Count))"
    }

    # --- headline present (advisory): skeleton uses a 19px conclusion line ---
    if ($Html -notmatch '19px') {
        $warnings += "headline_19px_not_found"
    }

    if ($violations.Count -gt 0) {
        $messages += "[ReportLint] violations { " + ($violations -join "; ") + " }"
        $messages += "[ReportLint] rule { docs/REPORTING.md: analogy from reporting.json + honesty callout + Korean glosses on technical terms }"
    }
    else {
        $messages += "[ReportLint] ok { report widget compliant }"
    }

    foreach ($w in $warnings) {
        $messages += "[ReportLint] warning { $w }"
    }

    return [pscustomobject]@{
        IsReport = $true
        Violations = @($violations)
        Warnings = @($warnings)
        Messages = @($messages)
    }
}
