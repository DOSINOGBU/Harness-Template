# SessionStart hook (startup|resume|compact): re-inject the core harness rules
# so they survive new sessions and context compaction. Fail-open on any error.
$ErrorActionPreference = "Stop"

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        $projectDir = [string]$payload.cwd
    }

    $analogy = ""
    $reportingPath = Join-Path $projectDir ".harness\reporting.json"
    if (Test-Path -LiteralPath $reportingPath) {
        try {
            $reporting = Get-Content -Raw -Encoding UTF8 -LiteralPath $reportingPath | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$reporting.analogy)) {
                $analogy = " Current report analogy (from .harness/reporting.json): " + [string]$reporting.analogy +
                    ". Keep using this analogy in reports until the user asks to change it."
            }
        }
        catch {
        }
    }

    # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
    $context = "[harness session-rules] Core rules (AGENTS.md is authoritative): " +
        "(1) read docs/UI_RULES.md before editing any UI/style file, never restyle outside the requested scope; " +
        "(2) put document artifacts only in the locations defined by docs/ARTIFACTS.md (use scripts/new-artifact.ps1); " +
        "(3) never end a turn with verified-but-uncommitted changes - run scripts/recommend-version-control.ps1 and commit via scripts/commit-work-unit.ps1; " +
        "(4) record verification output as an evidence file and end completion reports with 'EVIDENCE_RECORDED: <path>'; " +
        "(5) report results with visualize widgets (plain words, technical terms followed by simple Korean in parentheses, and keep the established analogy), including risks/next decisions and recommended tasks as widgets." +
        $analogy

    @{
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = $context
        }
    } | ConvertTo-Json -Compress | Write-Output
    exit 0
}
catch {
    exit 0
}
