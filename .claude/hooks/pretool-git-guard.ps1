# PreToolUse hook (Bash/PowerShell tools): deny raw `git commit` so commits go
# through scripts/commit-work-unit.ps1 gates. Escape hatch: include the literal
# HARNESS_ALLOW_RAW_COMMIT in the command when a raw commit is genuinely needed.
$ErrorActionPreference = "Stop"

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $command = [string]$payload.tool_input.command
    if ([string]::IsNullOrWhiteSpace($command)) {
        exit 0
    }

    # Match `git ... commit` where only OPTION tokens (or -C path / -c key=val) sit
    # between git and the commit subcommand. The old pattern allowed ANY tokens, so
    # unrelated text like "git rev-parse ... Base commit:" in a heredoc false-matched.
    if ($command -notmatch 'git(\s+-C\s+\S+|\s+-c\s+\S+|\s+--?[\w-]+(=\S+)?)*\s+commit\b') {
        exit 0
    }

    if ($command -match 'commit-work-unit' -or $command -match 'HARNESS_ALLOW_RAW_COMMIT') {
        exit 0
    }

    # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
    $reason = "[harness git-guard] Raw 'git commit' bypasses the harness gates (atomicity floor, code-health check, " +
        "message rules). Use scripts/commit-work-unit.ps1 (see docs/VERSION_CONTROL.md), or include the literal " +
        "HARNESS_ALLOW_RAW_COMMIT in the command to intentionally bypass this guard once."

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
