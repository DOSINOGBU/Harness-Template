# Stop hook with two bounded nudges, both fail-open:
# 1) commit guard  - once per session when the turn ends with uncommitted changes
# 2) plan resume   - up to twice per session when an active exec-plan still has
#                    unchecked "- [ ]" items (capped port of lazycodex auto-continue)
# Total possible blocks per session: 3. Any error exits 0 so sessions never break.
$ErrorActionPreference = "Stop"

function Write-BlockDecision {
    param([string]$Reason)

    @{ decision = "block"; reason = $Reason } | ConvertTo-Json -Compress | Write-Output
}

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json

    $sessionId = [string]$payload.session_id
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        exit 0
    }

    $projectDir = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        $projectDir = [string]$payload.cwd
    }
    if ([string]::IsNullOrWhiteSpace($projectDir)) {
        exit 0
    }

    $flagDir = Join-Path $env:TEMP "claude-harness-hooks"
    if (-not (Test-Path -LiteralPath $flagDir)) {
        New-Item -ItemType Directory -Path $flagDir -Force | Out-Null
    }

    # --- Nudge 1: uncommitted changes (once per session) ---
    $commitFlagPath = Join-Path $flagDir "stop-commit-nudge-$sessionId.flag"

    if (-not (Test-Path -LiteralPath $commitFlagPath)) {
        # Native stderr under EAP=Stop throws in Windows PowerShell; relax around git.
        $previousEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $gitStatus = & git -C $projectDir status --porcelain 2>$null
        $gitExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousEap

        if ($gitExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace(($gitStatus -join ""))) {
            New-Item -ItemType File -Path $commitFlagPath -Force | Out-Null

            # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
            Write-BlockDecision -Reason ("[harness stop-commit-guard] Uncommitted changes remain in the working tree. " +
                "Per AGENTS.md Hard Constraints, run scripts/recommend-version-control.ps1 -VerificationStatus <Passed|Partial|Failed> " +
                "and, if recommended, commit via scripts/commit-work-unit.ps1 before ending the turn. " +
                "If the user explicitly asked to hold commits or the changes are intentionally left, state that in the completion report and finish. " +
                "(This reminder fires at most once per session.)")
            exit 0
        }
    }

    # --- Nudge 2: active exec-plan with unchecked items (max 2 per session) ---
    $resumeCountPath = Join-Path $flagDir "plan-resume-count-$sessionId.txt"
    $resumeCount = 0

    if (Test-Path -LiteralPath $resumeCountPath) {
        $parsedCount = 0
        if ([int]::TryParse((Get-Content -LiteralPath $resumeCountPath -ErrorAction SilentlyContinue | Select-Object -First 1), [ref]$parsedCount)) {
            $resumeCount = $parsedCount
        }
    }

    if ($resumeCount -ge 2) {
        exit 0
    }

    $activePlanDir = Join-Path $projectDir "docs\exec-plans\active"
    if (-not (Test-Path -LiteralPath $activePlanDir)) {
        exit 0
    }

    foreach ($planFile in @(Get-ChildItem -LiteralPath $activePlanDir -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $planFile.FullName
        $uncheckedCount = [regex]::Matches($content, '(?m)^\s*-\s\[\s\]\s').Count

        if ($uncheckedCount -eq 0) {
            continue
        }

        Set-Content -LiteralPath $resumeCountPath -Value ([string]($resumeCount + 1)) -Encoding ASCII

        Write-BlockDecision -Reason ("[harness plan-resume] Active exec-plan '" + $planFile.Name + "' still has " + $uncheckedCount +
            " unchecked '- [ ]' items. Do not stop here: either continue working the next unchecked item now, " +
            "or mark the plan Blocked/Partial with reasons and resume conditions per docs/exec-plans/README.md. " +
            "(auto-resume nudge " + ($resumeCount + 1) + "/2 this session)")
        exit 0
    }

    exit 0
}
catch {
    exit 0
}
