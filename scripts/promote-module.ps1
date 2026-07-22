<#
.SYNOPSIS
    Promotes a finished incubator project into the module warehouse (docs/MODULES.md).

.DESCRIPTION
    Machine-checks the promotion gate (README, module.json spec, entry file,
    tests, evidence, isolation, no scratch), then moves incubator/<slug> to the
    configured target dir (default modules/) via git mv and appends the module
    to the modules/README.md catalog. -DryRun reports gate results only.

.EXAMPLE
    pwsh -File scripts/promote-module.ps1 -Slug data-export -DryRun
    pwsh -File scripts/promote-module.ps1 -Slug data-export -EvidencePath docs/validation/2026-07-30-data-export.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [string]$EvidencePath,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$scriptBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptBase)) {
    $scriptBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptBase "..")).Path

if ($Slug -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Host "[Promote] failed { reason=slug_not_kebab; slug=$Slug }"
    exit 1
}

# --- config ---
$targetDir = "modules"
$mainSourceRoots = @("src", "app", "lib", "components", "server", "api")
$scratchPatterns = @("_tmp_*", "tmp_*", "*.tmp", "scratch-*", "_validate_*", "_verify_*")
$configPath = Join-Path $repoRoot ".harness\config.json"

if (Test-Path -LiteralPath $configPath) {
    try {
        $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
        if ($config.modules.targetDir) { $targetDir = [string]$config.modules.targetDir }
        if ($config.modules.mainSourceRoots) { $mainSourceRoots = @($config.modules.mainSourceRoots) }
        if ($config.hygiene.scratchPatterns) { $scratchPatterns = @($config.hygiene.scratchPatterns) }
    }
    catch {
    }
}

$incubatorPath = Join-Path $repoRoot ("incubator" + [IO.Path]::DirectorySeparatorChar + $Slug)

if (-not (Test-Path -LiteralPath $incubatorPath)) {
    Write-Host "[Promote] failed { reason=incubator_missing; path=incubator/$Slug }"
    exit 1
}

$gateFailures = @()

# Gate 1: README exists and is non-trivial (placeholders filled).
$readmePath = Join-Path $incubatorPath "README.md"
if (-not (Test-Path -LiteralPath $readmePath)) {
    $gateFailures += "readme_missing"
}
elseif ((Get-Content -Raw -Encoding UTF8 -LiteralPath $readmePath) -match '<!--') {
    $gateFailures += "readme_placeholders_left"
}

# Gate 2: module.json spec filled.
$moduleJsonPath = Join-Path $incubatorPath "module.json"
$entryRelative = $null

if (-not (Test-Path -LiteralPath $moduleJsonPath)) {
    $gateFailures += "module_json_missing"
}
else {
    try {
        $spec = Get-Content -Raw -Encoding UTF8 -LiteralPath $moduleJsonPath | ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace([string]$spec.name)) { $gateFailures += "module_json_name_empty" }
        if ([string]::IsNullOrWhiteSpace([string]$spec.purpose)) { $gateFailures += "module_json_purpose_empty" }

        $entryRelative = [string]$spec.entry
        if ([string]::IsNullOrWhiteSpace($entryRelative)) {
            $gateFailures += "module_json_entry_empty"
        }
    }
    catch {
        $gateFailures += "module_json_invalid"
    }
}

# Gate 3: public entry file exists (extension optional in spec).
if ($entryRelative) {
    $entryBase = Join-Path $incubatorPath ($entryRelative -replace "/", [IO.Path]::DirectorySeparatorChar)
    $entryMatches = @()

    if (Test-Path -LiteralPath $entryBase) {
        $entryMatches += $entryBase
    }
    else {
        $entryDir = Split-Path -Parent $entryBase
        $entryName = Split-Path -Leaf $entryBase

        if (Test-Path -LiteralPath $entryDir) {
            $entryMatches = @(Get-ChildItem -LiteralPath $entryDir -File -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -eq $entryName })
        }
    }

    if ($entryMatches.Count -eq 0) {
        $gateFailures += "entry_file_missing($entryRelative)"
    }
}

# Gate 4: tests present.
$testFiles = @(Get-ChildItem -LiteralPath (Join-Path $incubatorPath "tests") -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne ".gitkeep" })

if ($testFiles.Count -eq 0) {
    $gateFailures += "tests_missing"
}

# Gate 5: evidence file provided and existing.
if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $gateFailures += "evidence_path_required"
}
elseif (-not (Test-Path -LiteralPath (Join-Path $repoRoot ($EvidencePath -replace "/", [IO.Path]::DirectorySeparatorChar)))) {
    $gateFailures += "evidence_file_missing($EvidencePath)"
}

# Gate 6: isolation - no references to main source roots.
$rootAlternation = ($mainSourceRoots | ForEach-Object { [regex]::Escape($_) }) -join "|"
$isolationPattern = "(\.\./)+($rootAlternation)/"
$codeFiles = @(Get-ChildItem -LiteralPath $incubatorPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ps1", ".psm1", ".mjs", ".js", ".ts", ".tsx", ".py", ".go", ".rs", ".cs", ".sh") })

foreach ($file in $codeFiles) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName -ErrorAction SilentlyContinue

    if ($content -and $content -match $isolationPattern) {
        $gateFailures += "isolation_violation($($file.Name))"
        break
    }
}

# Gate 7: no scratch files inside.
foreach ($file in @(Get-ChildItem -LiteralPath $incubatorPath -Recurse -File -ErrorAction SilentlyContinue)) {
    $isScratch = $false

    foreach ($pattern in $scratchPatterns) {
        if ($file.Name -like $pattern) { $isScratch = $true; break }
    }

    if ($isScratch) {
        $gateFailures += "scratch_left($($file.Name))"
        break
    }
}

if ($gateFailures.Count -gt 0) {
    Write-Host "[Promote] gate_failed { slug=$Slug; failures=$($gateFailures -join ', ') }"
    Write-Host "[Promote] hint { fix the failures above, then re-run; conditions are documented in docs/MODULES.md }"
    exit 1
}

Write-Host "[Promote] gate_passed { slug=$Slug; tests=$($testFiles.Count) }"

if ($DryRun) {
    Write-Host "[Promote] dry_run { wouldMoveTo=$targetDir/$Slug }"
    exit 0
}

# --- promote: git mv + catalog update ---
$targetRoot = Join-Path $repoRoot $targetDir
$targetPath = Join-Path $targetRoot $Slug

if (Test-Path -LiteralPath $targetPath) {
    Write-Host "[Promote] failed { reason=target_exists; path=$targetDir/$Slug }"
    exit 1
}

if (-not (Test-Path -LiteralPath $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
}

$previousEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& git -C $repoRoot mv "incubator/$Slug" "$targetDir/$Slug" 2>$null
$gitExit = $LASTEXITCODE
$ErrorActionPreference = $previousEap

if ($gitExit -ne 0) {
    # Untracked incubator content: plain move, git add happens at commit time.
    Move-Item -LiteralPath $incubatorPath -Destination $targetPath -Force
}

$catalogPath = Join-Path $targetRoot "README.md"
$utf8 = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $catalogPath)) {
    $header = "# Modules - warehouse catalog`n`n" +
        "Promoted, reusable modules (docs/MODULES.md). Import only each module's public entry.`n`n" +
        "| module | purpose | entry |`n|---|---|---|`n"
    [System.IO.File]::WriteAllText($catalogPath, $header, $utf8)
}

$specForRow = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $targetPath "module.json") | ConvertFrom-Json
$row = "| ``$targetDir/$Slug`` | $([string]$specForRow.purpose) | ``$([string]$specForRow.entry)`` |`n"
[System.IO.File]::AppendAllText($catalogPath, $row, $utf8)

Write-Host "[Promote] promoted { from=incubator/$Slug; to=$targetDir/$Slug; catalog=$targetDir/README.md }"
Write-Host "[Promote] next { update main-code imports to the public entry, run verification, then commit via scripts/commit-work-unit.ps1 }"
exit 0
