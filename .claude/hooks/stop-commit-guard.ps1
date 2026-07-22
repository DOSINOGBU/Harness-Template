# Stop hook: nudge once per session when the turn ends with uncommitted changes.
# Fail-open by design — any error exits 0 so the hook can never break a session.
$ErrorActionPreference = "Stop"

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    # Loop guard: if we already blocked once and Claude is continuing because of
    # this hook, let the turn end.
    if ($payload.stop_hook_active) {
        exit 0
    }

    $sessionId = [string]$payload.session_id
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        exit 0
    }

    $flagDir = Join-Path $env:TEMP "claude-harness-hooks"
    if (-not (Test-Path -LiteralPath $flagDir)) {
        New-Item -ItemType Directory -Path $flagDir -Force | Out-Null
    }

    # Nudge at most once per session.
    $flagPath = Join-Path $flagDir "stop-commit-nudge-$sessionId.flag"
    if (Test-Path -LiteralPath $flagPath) {
        exit 0
    }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        $projectDir = [string]$payload.cwd
    }
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        exit 0
    }

    $gitStatus = & git -C $projectDir status --porcelain 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($gitStatus -join ""))) {
        exit 0
    }

    New-Item -ItemType File -Path $flagPath -Force | Out-Null

    # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI and would
    # garble non-ASCII literals (repo convention: script output stays ASCII).
    $reason = "[harness stop-commit-guard] Uncommitted changes remain in the working tree. " +
        "Per AGENTS.md Hard Constraints, run scripts/recommend-version-control.ps1 -VerificationStatus <Passed|Partial|Failed> " +
        "to get the commit recommendation, and if recommended, commit via scripts/commit-work-unit.ps1 before ending the turn. " +
        "If the user explicitly asked to hold commits or the changes are intentionally left, state that in the completion report and finish. " +
        "(This reminder fires at most once per session.)"

    @{ decision = "block"; reason = $reason } | ConvertTo-Json -Compress | Write-Output
    exit 0
}
catch {
    exit 0
}
