# Prompt-contract tests (ported from lazycodex): governance markdown is a tested
# artifact. Each file below must keep its load-bearing phrases; silent drift fails CI.
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$failureCount = 0
$checkCount = 0

# Korean phrases must be built from code points: PS 5.1 reads BOM-less scripts
# as ANSI and garbles literal Hangul (observed failure: this very check).
$glossPhrase = [string]([char]0xAD04) + [char]0xD638

function Write-ContractLog {
    param(
        [string]$Status,
        [hashtable]$Metadata = @{}
    )

    $metadataText = ($Metadata.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "

    Write-Host "[PromptContractTest] $Status { $metadataText }"
}

$contracts = @(
    @{ Path = "AGENTS.md"; Phrases = @(
        "EVIDENCE_RECORDED",
        "quick-task.md",
        "UI_RULES.md",
        "ARTIFACTS.md",
        "recommend-version-control.ps1"
    ) },
    @{ Path = ".harness/checklists/pre-completion.md"; Phrases = @(
        "EVIDENCE_RECORDED",
        "UI_RULES.md",
        "ARTIFACTS.md"
    ) },
    @{ Path = ".harness/prompts/pre-completion-self-verify.md"; Phrases = @(
        "EVIDENCE_RECORDED"
    ) },
    @{ Path = ".harness/prompts/quick-task.md"; Phrases = @(
        "READ-ONLY",
        "HEAVY",
        "recommend-version-control.ps1",
        "EVIDENCE_RECORDED"
    ) },
    @{ Path = ".harness/prompts/review-change.md"; Phrases = @(
        "verify-evidence.ps1",
        "DoneClaim"
    ) },
    @{ Path = ".harness/prompts/implement-task.md"; Phrases = @(
        "UI_RULES.md",
        "recommend-version-control.ps1"
    ) },
    @{ Path = "docs/UI_RULES.md"; Phrases = @(
        "PROJECT-CUSTOMIZE"
    ) },
    @{ Path = "docs/ARTIFACTS.md"; Phrases = @(
        "new-artifact.ps1"
    ) },
    @{ Path = "docs/REPORTING.md"; Phrases = @(
        "data-prompt",
        "sendPrompt",
        "EVIDENCE_RECORDED",
        "reporting.json",
        $glossPhrase
    ) },
    @{ Path = "AGENTS.md"; Phrases = @(
        "REPORTING.md",
        "NAMING.md",
        "Delegation Policy"
    ) },
    @{ Path = "docs/NAMING.md"; Phrases = @(
        "kebab-case",
        "YYYY-MM-DD",
        "namingLegacyAllowed"
    ) },
    @{ Path = "docs/WORKFLOW.md"; Phrases = @(
        "Delegation Policy"
    ) },
    @{ Path = "docs/exec-plans/README.md"; Phrases = @(
        "drafts",
        "- [ ]"
    ) },
    @{ Path = "docs/VERSION_CONTROL.md"; Phrases = @(
        "commit-work-unit.ps1"
    ) }
)

foreach ($contract in $contracts) {
    $fullPath = Join-Path $repoRoot ($contract.Path -replace "/", [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $fullPath)) {
        $failureCount += 1
        Write-ContractLog -Status "failed" -Metadata @{ path = $contract.Path; reason = "missing_file" }
        continue
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $fullPath

    foreach ($phrase in $contract.Phrases) {
        $checkCount += 1

        if ($content.Contains($phrase)) {
            continue
        }

        $failureCount += 1
        Write-ContractLog -Status "failed" -Metadata @{
            path = $contract.Path
            missingPhrase = $phrase
        }
    }
}

# Reporting style contract: the analogy state file must exist with a non-empty analogy.
$checkCount += 1
$reportingPath = Join-Path $repoRoot ".harness\reporting.json"

if (-not (Test-Path -LiteralPath $reportingPath)) {
    $failureCount += 1
    Write-ContractLog -Status "failed" -Metadata @{ path = ".harness/reporting.json"; reason = "missing_file" }
}
else {
    try {
        $reporting = Get-Content -Raw -Encoding UTF8 -LiteralPath $reportingPath | ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace([string]$reporting.analogy)) {
            $failureCount += 1
            Write-ContractLog -Status "failed" -Metadata @{ path = ".harness/reporting.json"; reason = "empty_analogy" }
        }
    }
    catch {
        $failureCount += 1
        Write-ContractLog -Status "failed" -Metadata @{ path = ".harness/reporting.json"; reason = "invalid_json" }
    }
}

if ($failureCount -gt 0) {
    Write-ContractLog -Status "complete" -Metadata @{ checks = $checkCount; failures = $failureCount }
    exit 1
}

Write-ContractLog -Status "complete" -Metadata @{ checks = $checkCount; failures = 0 }
exit 0
