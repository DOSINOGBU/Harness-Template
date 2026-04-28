# AGENTS.md

이 파일은 AI 에이전트가 작업을 시작할 때 가장 먼저 읽는 작업 지도입니다.
자세한 규칙을 이 파일에 모두 넣지 말고, 필요한 문서를 찾아가도록 안내합니다.

## Working Mode

- 기존 구조를 먼저 파악한 뒤 최소 변경으로 작업합니다.
- 모호한 요구사항은 구현 전에 질문하거나 `docs/exec-plans/active/`에 가정을 명시합니다.
- 실패를 숨기지 말고 원인, 재현 방법, 검증 결과를 남깁니다.
- 새 라이브러리, 큰 구조 변경, 삭제 작업은 먼저 이유와 영향을 설명합니다.

## Intent Routing

- 기능 추가, 구현, 생성 요청은 Build 흐름으로 처리합니다.
- 오류, 버그, 동작 안함, 원인 분석, 수정 요청은 Debug 흐름으로 처리합니다.
- 의도가 불명확하면 Build 흐름을 기본값으로 두되, 요구사항이 두 가지 이상으로 해석되면 구현 전에 확인합니다.
- 상세한 구현 원칙은 이 파일에 반복하지 않고 `docs/WORKFLOW.md`, `docs/PROJECT_RULES.md`, `docs/CODE_STYLE.md`, `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md`를 따릅니다.

## Required Reading

작업 종류에 따라 아래 문서를 먼저 확인합니다.

| 상황 | 먼저 읽을 문서 |
|---|---|
| 작업 시작 절차 | `docs/WORKFLOW.md` |
| 전체 구조 파악 | `ARCHITECTURE.md`, `docs/README.md` |
| 템플릿 도입/검증 | `docs/ONBOARDING.md`, `scripts/validate-harness.ps1` |
| 기능 추가 | `docs/PRODUCT_CONTEXT.md`, `.harness/checklists/feature-change.md` |
| 버그 수정 | `docs/TESTING.md`, `.harness/checklists/bug-fix.md` |
| 리팩터링 | `ARCHITECTURE.md`, `.harness/checklists/refactor.md` |
| 보안/권한 변경 | `docs/SECURITY.md` |
| 로그/에러 처리 변경 | `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md` |
| 데이터/마이그레이션 | `docs/DATA.md`, `.harness/checklists/migration.md` |
| 의존성 추가/제거 | `docs/DEPENDENCIES.md`, `.harness/checklists/dependency-add.md` |
| 성능 작업 | `docs/PERFORMANCE.md` |
| 코드 스타일 판단 | `docs/CODE_STYLE.md` |
| 장애 대응 | `.harness/checklists/incident.md`, `docs/RELIABILITY.md` |
| 커밋/푸시 | `docs/VERSION_CONTROL.md`, `.harness/checklists/commit.md` |
| PR 생성/리뷰/머지 | `docs/PULL_REQUESTS.md`, `.harness/checklists/pull-request.md` |
| 신규 합류 | `docs/ONBOARDING.md` |
| 기술 선택 | `docs/adr/README.md` |

## Hard Constraints

| 제약 | 이유 |
|---|---|
| 자동 생성 파일은 직접 수정하지 않습니다. | 다음 생성 과정에서 덮어써질 수 있습니다. |
| 검증 없이 완료를 선언하지 않습니다. | AI 출력이 실제 동작을 보장하지 않습니다. |
| 관련 없는 파일을 정리하거나 리팩터링하지 않습니다. | 변경 범위를 추적하기 어렵습니다. |
| 민감정보를 코드나 문서에 직접 기록하지 않습니다. | 보안 사고로 이어질 수 있습니다. |

## Completion Standard

작업 완료 시 다음을 보고합니다.

- 변경 요약
- 실행한 검증
- 남은 리스크 또는 확인하지 못한 부분
- 사용자가 이어서 판단해야 할 사항
