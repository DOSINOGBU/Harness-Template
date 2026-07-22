# buildproof Harness

이 폴더는 AI 에이전트를 운영하기 위한 반복 가능한 작업 절차(buildproof 하네스의 체크리스트·프롬프트·설정)를 담습니다.

작업 흐름은 [`docs/WORKFLOW.md`](../docs/WORKFLOW.md), 실행 계획은 [`docs/exec-plans/README.md`](../docs/exec-plans/README.md), 에이전트 지도는 [`AGENTS.md`](../AGENTS.md)와 함께 참고합니다.

## Contents

| 경로 | 목적 |
|---|---|
| `checklists/` | 작업 유형별 완료 기준 |
| `prompts/` | 반복 사용 가능한 프롬프트 템플릿 |
| `config.json` | 하네스 검증 기준과 제외 경로 |
| `config.schema.json` | `config.json` 편집 시 키·타입 검증(JSON Schema) |
| `reporting.json` | 결과 보고 비유(analogy) 상태 — 사용자가 바꿔 달라고 할 때만 갱신 |
| `exceptions.json` | 수용된 예외 장부(커밋 게이트의 `-Accept*` 사유가 만료일과 함께 기록됨) — 만료 항목은 `-Maintenance` 위생 검사가 잡습니다 |

체크리스트·프롬프트 파일을 추가하거나 이름을 바꿀 때는 아래 표와 [`scripts/validate-harness.ps1`](../scripts/validate-harness.ps1)가 기대하는 문서 인덱스·연결을 함께 맞춥니다.

## Checklists

| 파일 | 사용 시점 |
|---|---|
| `feature-change.md` | 기능 추가·변경 |
| `bug-fix.md` | 버그 수정 |
| `refactor.md` | 동작 변경 없는 구조 개선 |
| `release.md` | 릴리스 전 점검 |
| `dependency-add.md` | 새 의존성 도입 |
| `migration.md` | 데이터·스키마 마이그레이션 |
| `incident.md` | 장애 대응과 사후 기록 |
| `doc-update.md` | 문서 갱신 |
| `commit.md` | 커밋 전 점검 |
| `pull-request.md` | PR 생성·머지 전 점검 |
| `maintenance.md` | 드리프트 정리 전 점검 |
| `pre-completion.md` | 완료 보고 직전 자체 검증 |

## Prompts

필요한 템플릿 내용을 에이전트 대화에 붙여 넣거나, 파일 경로를 짚어 주고 그 안의 지시를 따르게 합니다.

| 파일 | 사용 시점 |
|---|---|
| `plan-task.md` | 구현 전에 계획부터 받고 싶을 때 |
| `implement-task.md` | 합의된 계획으로 구현 |
| `quick-task.md` | exec-plan 없는 즉석 수정(분류→최소 검증→자동 커밋) |
| `review-change.md` | 변경 자체 리뷰 |
| `fix-failing-check.md` | 검증 실패 분석·수정 |
| `debug-issue.md` | 증상에서 원인까지 단계 분석 |
| `write-tests.md` | 신뢰할 만한 테스트 작성 |
| `update-docs.md` | 변경에 맞춰 문서 갱신 |
| `explain-code.md` | 모르는 코드 빠르게 파악 |
| `commit-change.md` | 변경 검토 후 커밋 |
| `prepare-pr.md` | PR 제목과 본문 초안 작성 |
| `cleanup-drift.md` | 유지보수 감지 결과 정리 |
| `pre-completion-self-verify.md` | 종료 전 요구사항·검증·루프 신호 확인 |

## Validation

`scripts/validate-harness.ps1` 스크립트는 문서 인덱스와 체크리스트·프롬프트 연결이 실제 파일과 맞는지 확인합니다.
템플릿 원본에서는 `-Mode Template`을 사용하고, 실제 프로젝트 도입 후에는 `-Mode Project`로 `docs/TESTING.md`의 TODO 명령까지 실패로 처리합니다.
기존 `-Strict` 옵션은 호환용이며 `-Mode Project`와 같은 수준으로 동작합니다.
검증 기준은 `.harness/config.json`에서 조정합니다.
`-Maintenance`를 함께 사용하면 오래된 계획(초안 방치 포함), 등록 누락(체크리스트·프롬프트·docs 루트 문서), 산출물 네이밍 위반(`docs/analysis`·`docs/agent-runs`·`docs/validation`), generated 문서 placeholder, 과도한 TODO를 warning으로 보고합니다.
여기에 **드리프트 위생 검사**(`hygiene` 설정)가 함께 돕니다: 미커밋·미추적 파일 적체, upstream 없는 브랜치의 커밋 누적, 스크래치 파일 스프롤, 만료된 예외 장부 항목, 기능 커밋 대비 실행 계획 갱신 부재(플랜 커버리지 드리프트)를 감지합니다 — 실제 운영 프로젝트에서 관측된 사고 유형의 재발 방지 장치입니다.
`-CodeHealth`는 파일 크기·긴 함수·반복 라인 검사에 더해, `validation.uiConformance` 설정(하드코딩 색·팔레트 리터럴·CDN 폰트 import 등 금지 패턴)을 UI 파일에 대해 검사합니다. 금지 패턴의 단일 정답지는 `docs/UI_RULES.md`이며, 프로젝트에 맞게 `config.json`에서 조정합니다.
날짜형 산출물 문서는 `scripts/new-artifact.ps1`로 생성해 `docs/ARTIFACTS.md`의 네이밍 규칙을 자동으로 지킵니다.

`scripts/bootstrap-agent-context.ps1` 스크립트는 작업 시작 전에 저장소 구조, 필수 문서, 테스트 명령, 런타임, git 상태, placeholder 현황을 읽기 전용으로 요약합니다.
이 출력은 에이전트가 환경 탐색을 건너뛰지 않도록 돕는 시작 컨텍스트입니다.

## Principle

프롬프트는 일회성 지시입니다.
하네스는 반복 가능한 작업 시스템입니다.
체크리스트는 사람과 에이전트가 공유하는 완료 기준이며, 완료를 선언하기 직전에는 `pre-completion.md`를 거칩니다.
같은 실수가 두 번 나오면 체크리스트로, 세 번 나오면 자동화로 옮깁니다.
