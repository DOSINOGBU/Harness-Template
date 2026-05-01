# Harness Template

AI coding agents are most useful when they inherit a clear operating system: where to look, how to decide, how to validate, and when to stop. This repository is a reusable harness for that workflow.

The template favors debuggability, small changes, explicit failure handling, and repeatable validation over clever or compressed output.

## 10 Minute Quick Start

1. Copy this template into a project repository.
2. Read `AGENTS.md`, `ARCHITECTURE.md`, and `docs/README.md`.
3. Fill the first project-specific blanks in `docs/PRODUCT_CONTEXT.md` and `ARCHITECTURE.md`.
4. Preview detected test commands:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1
```

5. Preview the agent start context:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1
```

6. If the detected commands are correct, apply them to `docs/TESTING.md`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1 -Apply
```

7. Run the template validation:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template
```

8. After project-specific commands are filled, run project validation:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Project
```

## First Hour Adoption

Fill only the minimum context needed for safe work:

- Product purpose and primary users in `docs/PRODUCT_CONTEXT.md`
- Current architecture summary in `ARCHITECTURE.md`
- Install, test, lint, typecheck, and build commands in `docs/TESTING.md`
- Any hard project rules in `docs/PROJECT_RULES.md`

Do not try to complete every optional document on day one. The template is tiered so teams can adopt it gradually.

## Validation Modes

| Mode | Use When | Behavior |
|---|---|---|
| `Template` | Maintaining this reusable template | Allows template placeholders as warnings |
| `Project` | After applying the template to a real project | Treats required project TODOs as failures |

`-Strict` is kept for compatibility and behaves like `-Mode Project`.

Additional checks:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Mode Project
```

## Main Entry Points

- `AGENTS.md`: routing guide for AI agents
- `docs/README.md`: document index and adoption tiers
- `.harness/README.md`: reusable checklists and prompts
- `.harness/config.json`: validation thresholds and exclusions
- `scripts/bootstrap-agent-context.ps1`: read-only startup context for agents
- `scripts/validate-harness.ps1`: local validation entrypoint
- `scripts/harness-validation/`: validation modules split by responsibility

## CI

The GitHub Actions workflow in `.github/workflows/harness-validation.yml` runs lightweight harness validation on pull requests. Template repositories should keep the default template-oriented checks. Projects that have filled their TODO commands can tighten CI to use `-Mode Project`.
