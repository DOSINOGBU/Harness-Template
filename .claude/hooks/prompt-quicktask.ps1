# UserPromptSubmit hook: when no active exec-plan exists, remind once per session
# that plan-less requests enter through the quick-task classification loop.
$ErrorActionPreference = "Stop"

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $sessionId = [string]$payload.session_id
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        exit 0
    }

    $flagDir = Join-Path $env:TEMP "claude-harness-hooks"
    if (-not (Test-Path -LiteralPath $flagDir)) {
        New-Item -ItemType Directory -Path $flagDir -Force | Out-Null
    }

    $flagPath = Join-Path $flagDir "quicktask-nudge-$sessionId.flag"
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

    $activePlanDir = Join-Path $projectDir "docs\exec-plans\active"
    $activePlans = @()
    if (Test-Path -LiteralPath $activePlanDir) {
        $activePlans = @(Get-ChildItem -LiteralPath $activePlanDir -Filter "*.md" -File -ErrorAction SilentlyContinue)
    }

    $draftsDir = Join-Path $projectDir "docs\exec-plans\drafts"
    $draftPlans = @()
    if (Test-Path -LiteralPath $draftsDir) {
        $draftPlans = @(Get-ChildItem -LiteralPath $draftsDir -Filter "*.md" -File -ErrorAction SilentlyContinue)
    }

    # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
    $contextParts = @()

    if ($activePlans.Count -eq 0) {
        $contextParts += "[harness quick-task] No active exec-plan exists. If this request edits anything, classify it first per " +
            ".harness/prompts/quick-task.md: READ-ONLY (report only) / LIGHT (small low-risk edit - needs one recorded proof + auto-commit) / " +
            "HEAVY (security, schema, concurrency, new module, shared interface, behavior change - create an exec-plan first) / GIT-OP. " +
            "The lightweight path is reduced rules, not exempted rules."
    }

    if ($draftPlans.Count -gt 0) {
        $draftNames = @($draftPlans | ForEach-Object { $_.Name }) -join ", "
        $contextParts += "[harness drafts] Unapproved exec-plan drafts exist ($draftNames). Drafts are NOT implementable: " +
            "get explicit user approval and move the file to docs/exec-plans/active/ before implementing any of them."
    }

    if ($contextParts.Count -eq 0) {
        exit 0
    }

    New-Item -ItemType File -Path $flagPath -Force | Out-Null

    $context = ($contextParts -join " ") + " (This reminder fires at most once per session.)"

    @{
        hookSpecificOutput = @{
            hookEventName = "UserPromptSubmit"
            additionalContext = $context
        }
    } | ConvertTo-Json -Compress | Write-Output
    exit 0
}
catch {
    exit 0
}
