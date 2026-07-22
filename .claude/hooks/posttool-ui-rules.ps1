# PostToolUse hook (Edit|Write): remind about docs/UI_RULES.md when a UI/style
# file is edited. Injects context once per session; fail-open on any error.
$ErrorActionPreference = "Stop"

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $filePath = [string]$payload.tool_input.file_path
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        exit 0
    }

    $uiExtensions = @(".tsx", ".jsx", ".vue", ".svelte", ".astro", ".css", ".scss", ".sass", ".less")
    $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
    if ($uiExtensions -notcontains $extension) {
        exit 0
    }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        $projectDir = [string]$payload.cwd
    }
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        exit 0
    }

    $uiRulesPath = Join-Path $projectDir "docs\UI_RULES.md"
    if (-not (Test-Path -LiteralPath $uiRulesPath)) {
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

    $flagPath = Join-Path $flagDir "ui-rules-nudge-$sessionId.flag"
    if (Test-Path -LiteralPath $flagPath) {
        exit 0
    }

    New-Item -ItemType File -Path $flagPath -Force | Out-Null

    # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI and would
    # garble non-ASCII literals (repo convention: script output stays ASCII).
    $context = "[harness ui-rules] A UI/style file was edited. Verify now that docs/UI_RULES.md section 1 hard rules were followed " +
        "(design tokens only - no hardcoded colors, no arbitrary px values, no reimplementing shared components, " +
        "no restyling outside the requested scope), and check every row of the section 5 checklist before reporting completion. " +
        "(This reminder fires at most once per session.)"

    @{
        hookSpecificOutput = @{
            hookEventName = "PostToolUse"
            additionalContext = $context
        }
    } | ConvertTo-Json -Compress | Write-Output
    exit 0
}
catch {
    exit 0
}
