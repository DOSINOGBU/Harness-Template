# PreToolUse hook (visualize show_widget): lint the widget BEFORE it renders so a
# non-compliant result report never reaches the user. Denies on hard violations
# (missing analogy / honesty callout / sparse glosses) with specifics; the model
# then re-calls show_widget with a corrected version. Fail-open on any error.
# ASCII source only (PS 5.1 ANSI trap); Korean anchors load from reporting.json.
$ErrorActionPreference = "Stop"

try {
    # Read stdin as UTF-8 explicitly: PS 5.1's default console input encoding is
    # the OS ANSI codepage, which garbles the Korean analogy text in widget_code
    # and would false-flag analogy_missing.
    $stdinReader = New-Object System.IO.StreamReader([System.Console]::OpenStandardInput(), (New-Object System.Text.UTF8Encoding($false)))
    $stdin = $stdinReader.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $widgetCode = [string]$payload.tool_input.widget_code
    if ([string]::IsNullOrWhiteSpace($widgetCode)) {
        exit 0
    }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        $projectDir = [string]$payload.cwd
    }
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        exit 0
    }

    $lintPath = Join-Path $projectDir "scripts\harness-reporting\lint.ps1"
    if (-not (Test-Path -LiteralPath $lintPath)) {
        exit 0
    }

    . $lintPath

    $result = Test-ReportWidgetCompliance -Html $widgetCode -RepoRoot $projectDir

    if (-not $result.IsReport -or $result.Violations.Count -eq 0) {
        exit 0
    }

    $violationText = ($result.Violations -join ", ")
    $reason = "[harness report-lint] This result-report widget violates docs/REPORTING.md: " + $violationText + ". " +
        "Fix and re-render: (analogy_missing) frame the report with the construction-site analogy from .harness/reporting.json; " +
        "(honesty_callout_missing) add the bg-warning / alert-triangle honesty callout; " +
        "(gloss_sparse) put a Korean parenthetical gloss after each technical term/code/script name on first use. " +
        "If this widget is genuinely not a result report, add data-report=`"skip-lint`" to the root element."

    @{
        hookSpecificOutput = @{
            hookEventName = "PreToolUse"
            permissionDecision = "deny"
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Compress | Write-Output
    exit 0
}
catch {
    exit 0
}
