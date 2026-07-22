# Stop hook with two nudges, both fail-open:
# 1) commit guard - once per session when the turn ends with uncommitted changes
# 2) plan resume  - progress-aware auto-continue (lazycodex port with a safety
#    valve): keeps nudging while the number of unchecked "- [ ]" items in active
#    exec-plans DECREASES between stops; stops after planResume.stallLimit stops
#    without progress (default 2) or planResume.maxNudges total (default 20).
#    Thresholds come from .harness/config.json "planResume".
# Any error exits 0 so sessions never break.
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

    # --- Nudge 1: uncommitted changes ---
    # Normal backlog: once per session. Backlog at or over hygiene.maxUncommittedFiles
    # (default 20): escalated - up to 3 nudges per session. Lesson from a project
    # where 253 uncommitted files sat for 16 days past a single polite reminder.
    $backlogThreshold = 20
    $configPath = Join-Path $projectDir ".harness\config.json"

    if (Test-Path -LiteralPath $configPath) {
        try {
            $earlyConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
            if ([int]$earlyConfig.hygiene.maxUncommittedFiles -ge 1) {
                $backlogThreshold = [int]$earlyConfig.hygiene.maxUncommittedFiles
            }
        }
        catch {
        }
    }

    # Native stderr under EAP=Stop throws in Windows PowerShell; relax around git.
    $previousEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $gitStatus = & git -C $projectDir status --porcelain 2>$null
    $gitExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousEap

    if ($gitExitCode -eq 0) {
        $dirtyLines = @($gitStatus | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $commitFlagPath = Join-Path $flagDir "stop-commit-nudge-$sessionId.flag"

        if ($dirtyLines.Count -ge $backlogThreshold) {
            $escalationPath = Join-Path $flagDir "stop-commit-escalation-$sessionId.txt"
            $escalationCount = 0

            if (Test-Path -LiteralPath $escalationPath) {
                [int]::TryParse((Get-Content -LiteralPath $escalationPath -ErrorAction SilentlyContinue | Select-Object -First 1), [ref]$escalationCount) | Out-Null
            }

            if ($escalationCount -lt 3) {
                Set-Content -LiteralPath $escalationPath -Value ([string]($escalationCount + 1)) -Encoding ASCII

                # ASCII only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.
                Write-BlockDecision -Reason ("[harness stop-commit-guard] BACKLOG ALERT: " + $dirtyLines.Count +
                    " uncommitted files (threshold $backlogThreshold). This is how work gets lost - stop accumulating. " +
                    "Classify the changes now: commit completed work units via scripts/commit-work-unit.ps1, " +
                    "gitignore generated outputs, and report anything intentionally held. " +
                    "(escalated nudge " + ($escalationCount + 1) + "/3 this session)")
                exit 0
            }
        }
        elseif ($dirtyLines.Count -gt 0 -and -not (Test-Path -LiteralPath $commitFlagPath)) {
            New-Item -ItemType File -Path $commitFlagPath -Force | Out-Null

            Write-BlockDecision -Reason ("[harness stop-commit-guard] Uncommitted changes remain in the working tree. " +
                "Per AGENTS.md Hard Constraints, run scripts/recommend-version-control.ps1 -VerificationStatus <Passed|Partial|Failed> " +
                "and, if recommended, commit via scripts/commit-work-unit.ps1 before ending the turn. " +
                "If the user explicitly asked to hold commits or the changes are intentionally left, state that in the completion report and finish. " +
                "(This reminder fires at most once per session.)")
            exit 0
        }
    }

    # --- Nudge 2: progress-aware plan resume ---
    $maxNudges = 20
    $stallLimit = 2
    $configPath = Join-Path $projectDir ".harness\config.json"

    if (Test-Path -LiteralPath $configPath) {
        try {
            $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json

            if ($config.planResume) {
                if ([int]$config.planResume.maxNudges -ge 1) { $maxNudges = [int]$config.planResume.maxNudges }
                if ([int]$config.planResume.stallLimit -ge 1) { $stallLimit = [int]$config.planResume.stallLimit }
            }
        }
        catch {
        }
    }

    $activePlanDir = Join-Path $projectDir "docs\exec-plans\active"
    if (-not (Test-Path -LiteralPath $activePlanDir)) {
        exit 0
    }

    $totalUnchecked = 0
    $firstPlanName = $null

    foreach ($planFile in @(Get-ChildItem -LiteralPath $activePlanDir -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $planFile.FullName
        $uncheckedCount = [regex]::Matches($content, '(?m)^\s*-\s\[\s\]\s').Count

        if ($uncheckedCount -gt 0 -and $null -eq $firstPlanName) {
            $firstPlanName = $planFile.Name
        }

        $totalUnchecked += $uncheckedCount
    }

    $statePath = Join-Path $flagDir "plan-resume-state-$sessionId.txt"

    if ($totalUnchecked -eq 0) {
        if (Test-Path -LiteralPath $statePath) {
            Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue
        }
        exit 0
    }

    $nudgeCount = 0
    $stallCount = 0
    $lastUnchecked = -1

    if (Test-Path -LiteralPath $statePath) {
        $stateParts = ((Get-Content -LiteralPath $statePath -ErrorAction SilentlyContinue | Select-Object -First 1) -split '\|')

        if ($stateParts.Count -ge 3) {
            [int]::TryParse($stateParts[0], [ref]$nudgeCount) | Out-Null
            [int]::TryParse($stateParts[1], [ref]$stallCount) | Out-Null
            [int]::TryParse($stateParts[2], [ref]$lastUnchecked) | Out-Null
        }
    }

    if ($nudgeCount -ge $maxNudges) {
        exit 0
    }

    $progressNote = "first nudge"

    if ($lastUnchecked -ge 0) {
        if ($totalUnchecked -lt $lastUnchecked) {
            $stallCount = 0
            $progressNote = "progress detected ($lastUnchecked -> $totalUnchecked items)"
        }
        else {
            $stallCount += 1
            $progressNote = "no progress since last stop ($lastUnchecked -> $totalUnchecked items, stall $stallCount/$stallLimit)"

            if ($stallCount -ge $stallLimit) {
                Set-Content -LiteralPath $statePath -Value "$nudgeCount|$stallCount|$totalUnchecked" -Encoding ASCII
                # Stalled: stop auto-resume and let the turn end so a human can look.
                exit 0
            }
        }
    }

    $nudgeCount += 1
    Set-Content -LiteralPath $statePath -Value "$nudgeCount|$stallCount|$totalUnchecked" -Encoding ASCII

    Write-BlockDecision -Reason ("[harness plan-resume] Active exec-plan '" + $firstPlanName + "' still has " + $totalUnchecked +
        " unchecked '- [ ]' items (" + $progressNote + "). Do not stop here: continue the next unchecked item now, " +
        "or mark the plan Blocked/Partial with reasons and resume conditions per docs/exec-plans/README.md. " +
        "(auto-resume " + $nudgeCount + "/" + $maxNudges + "; stops after " + $stallLimit + " stops without progress)")
    exit 0
}
catch {
    exit 0
}
