# AGENTS.md

이 파일은 AI 에이전트가 작업을 시작할 때 가장 먼저 읽는 작업 지도입니다.
자세한 규칙을 이 파일에 모두 넣지 말고, 필요한 문서를 찾아가도록 안내합니다.

## Working Mode

- 기존 구조를 먼저 파악한 뒤 최소 변경으로 작업합니다.
- 모호한 요구사항은 구현 전에 질문하거나 `docs/exec-plans/active/`에 가정을 명시합니다.
- 새 기능 실행 계획은 `docs/exec-plans/README.md`의 계획 생성 규칙을 따라 기존 plan과의 관계, 기능 단위 분리, 병행 가능 여부를 먼저 확인합니다.
- 작업 중 새 기능 범위가 생기면 바로 구현하지 말고 active exec-plan을 먼저 만들거나 갱신합니다.
- 기능 동작 또는 UI/shared state/API/data/navigation 변경은 `docs/PRODUCT_CONTEXT.md`의 PRD 기능 계약을 최신화하고 `docs/TESTING.md`의 회귀 검증 기준을 확인합니다.
- 실패를 숨기지 말고 원인, 재현 방법, 검증 결과를 남깁니다.
- 새 라이브러리, 큰 구조 변경, 삭제 작업은 먼저 이유와 영향을 설명합니다.
- 체크리스트·프롬프트 목록은 `.harness/README.md`에서 확인합니다.

## Intent Routing

- 기능 추가, 구현, 생성 요청은 Build 흐름으로 처리합니다.
- 오류, 버그, 동작 안함, 원인 분석, 수정 요청은 Debug 흐름으로 처리합니다.
- 의도가 불명확하면 Build 흐름을 기본값으로 두되, 요구사항이 두 가지 이상으로 해석되면 구현 전에 확인합니다.
- 상세한 구현 원칙은 이 파일에 반복하지 않고 `docs/WORKFLOW.md`, `docs/PROJECT_RULES.md`, `docs/CODE_STYLE.md`, `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md`를 따릅니다.

## Required Reading

작업 종류에 따라 아래 문서를 먼저 확인합니다.
동일 문서가 여러 행에 있으면, **해당 작업과 맞는 행**을 기준으로 읽습니다.

| 상황 | 먼저 읽을 문서 |
|---|---|
| 작업 시작 절차 | `docs/WORKFLOW.md`, `scripts/bootstrap-agent-context.ps1`, `.harness/README.md` |
| 전체 구조 파악 | `ARCHITECTURE.md`, `docs/README.md` |
| 도메인 용어 | `docs/GLOSSARY.md` |
| 템플릿 도입·검증·신규 합류 | `docs/ONBOARDING.md`, `scripts/validate-harness.ps1` |
| 실행 계획·장기 작업 | `docs/exec-plans/README.md`, `docs/exec-plans/active/` |
| 에이전트 행동 기준 | `docs/AGENT_BEHAVIOR.md`, `.harness/checklists/pre-completion.md` |
| 완료 품질·자체 검증 기준 | `docs/QUALITY_SCORE.md` |
| 정기 유지보수/드리프트 정리 | `docs/MAINTENANCE.md`, `.harness/checklists/maintenance.md` |
| 기능 추가 | `docs/PRODUCT_CONTEXT.md`, `.harness/checklists/feature-change.md` |
| 버그 수정 | `docs/TESTING.md`, `.harness/checklists/bug-fix.md` |
| 리팩터링 | `ARCHITECTURE.md`, `.harness/checklists/refactor.md` |
| 프론트엔드·백엔드 영역 변경(해당 시) | `docs/FRONTEND.md`, `docs/BACKEND.md` |
| 보안/권한·인프라/환경변수/시크릿 | `docs/INFRASTRUCTURE.md`, `docs/SECURITY.md` |
| 로그/에러 처리 변경 | `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md` |
| 데이터/마이그레이션 | `docs/DATA.md`, `.harness/checklists/migration.md` |
| 의존성·라이선스/외부 에셋 | `docs/DEPENDENCIES.md`, `docs/LICENSING.md`, `.harness/checklists/dependency-add.md` |
| 성능 작업 | `docs/PERFORMANCE.md` |
| 배포/롤백 | `docs/DEPLOYMENT.md`, `docs/RUNBOOK.md` |
| 릴리스 전 | `.harness/checklists/release.md` |
| 비용 영향 | `docs/COST.md` |
| 접근성 | `docs/ACCESSIBILITY.md` |
| 국제화/시간대/로케일 | `docs/INTERNATIONALIZATION.md` |
| 코드 스타일 판단 | `docs/CODE_STYLE.md` |
| 문서 갱신 | `.harness/checklists/doc-update.md` |
| 장애 대응 | `.harness/checklists/incident.md`, `docs/RELIABILITY.md` |
| 커밋/푸시 | `docs/VERSION_CONTROL.md`, `.harness/checklists/commit.md` |
| PR 생성/리뷰/머지 | `docs/PULL_REQUESTS.md`, `.harness/checklists/pull-request.md` |
| 기술 선택 | `docs/adr/README.md` |

## Hard Constraints

| 제약 | 이유 |
|---|---|
| 자동 생성 파일은 직접 수정하지 않습니다. | 다음 생성 과정에서 덮어써질 수 있습니다. |
| 검증 없이 완료를 선언하지 않습니다. | AI 출력이 실제 동작을 보장하지 않습니다. |
| 관련 없는 파일을 정리하거나 리팩터링하지 않습니다. | 변경 범위를 추적하기 어렵습니다. |
| 민감정보를 코드나 문서에 직접 기록하지 않습니다. | 보안 사고로 이어질 수 있습니다. |

위의 “관련 없는 정리·리팩터링 금지”는 **기능·버그 작업에 끼워 넣는 정리**를 뜻합니다. 드리프트 정리와 문서·인덱스 보강은 `docs/MAINTENANCE.md`와 `.harness/checklists/maintenance.md`에 따른 유지보수 작업으로 수행합니다.

## Completion Standard

작업 완료 시 `.harness/checklists/pre-completion.md`로 자체 확인한 뒤 아래 표준 완료 보고 섹션을 같은 순서로 사용합니다.

- 요청 확인
- 변경 사항
- 검증
- 결과 확인
- CodeHealth
- 리스크와 다음 판단

검증을 실행하지 못했거나 해당 없는 항목이 있으면 생략하지 말고 이유, 대체 확인, 남은 리스크를 해당 섹션에 적습니다.
