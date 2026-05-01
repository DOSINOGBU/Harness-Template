# Agent Run: harness engineering improvements

## Request

LangChain harness engineering 글과 비교해 정리한 개선 계획을 Harness Template에 구현합니다.

## Intent

Build. 새 하네스 기능을 문서, 프롬프트, 체크리스트, 읽기 전용 스크립트로 추가하는 작업입니다.

## Context Read

- `AGENTS.md`
- `docs/WORKFLOW.md`
- `docs/PRODUCT_CONTEXT.md`
- `.harness/checklists/feature-change.md`
- `docs/PROJECT_RULES.md`
- `docs/CODE_STYLE.md`
- `docs/TESTING.md`
- `scripts/init-testing-commands.ps1`

## Commands

- `git status --short`: 기존 untracked 파일 `Harness Template Use Docs/0. Create New Project Github.txt` 확인, 변경하지 않음.
- `powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1`: 첫 실행에서 PowerShell 백틱 trim 파서 오류 확인 후 수정, 재실행 성공.
- `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template`: 성공, 템플릿 테스트 명령 placeholder warning 유지.
- `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance`: 성공, 기존 템플릿 placeholder와 active plan 없음 warning 유지.
- `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Mode Template`: 성공.
- `git diff --check`: 성공, 줄 끝 변환 warning만 출력.

## Changes

- 완료 전 self-verification checklist와 prompt를 추가했습니다.
- 작업 시작 context bootstrap 스크립트를 추가했습니다.
- agent run log 문서 구조와 이번 실행 기록을 추가했습니다.
- loop recovery, reasoning budget, 모델별 하네스 노트를 문서화했습니다.
- README, workflow, testing, harness index, 사용자용 running prompt를 새 흐름에 맞게 갱신했습니다.

## Verification

주요 하네스 검증과 새 bootstrap 스크립트 dry-run이 성공했습니다.
Maintenance warning은 기존 템플릿 placeholder 문서와 exec plan 없음에서 발생한 것으로, 이번 변경의 등록 누락이나 스크립트 실패는 아닙니다.

## Loop Signals

`scripts/bootstrap-agent-context.ps1` 첫 실행에서 백틱 문자를 문자열로 trim하는 코드가 PowerShell 파서 오류를 냈습니다.
문자 코드 기반 trim으로 접근을 바꾼 뒤 같은 명령이 성공했습니다.

## Risks

현재 구현은 로컬 문서와 스크립트 기반입니다.
LangSmith 같은 외부 trace store나 실제 tool hook 수준의 강제 middleware는 아직 포함하지 않았습니다.

## Promotion

Pre-completion self-verify, context bootstrap, loop detection, agent run log 후보를 `docs/AUTOMATION_EVOLUTION.md`에 등록했습니다.
