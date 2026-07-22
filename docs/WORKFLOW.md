# Workflow

AI 에이전트가 작업을 받았을 때 어떤 순서로 컨텍스트를 모으고 결과를 내는지 정의합니다.
모델이 강해도 절차가 없으면 같은 실수를 반복합니다.

## Task Lifecycle

| 단계 | 행동 | 산출물 |
|---|---|---|
| 1. Intake | 요청을 한 문장으로 다시 적고 Build/Debug 의도를 분류합니다. | 명확한 목표 문장 |
| 2. Bootstrap | `scripts/bootstrap-agent-context.ps1`를 실행해 환경 요약을 확인합니다. Windows에서는 `pwsh` 실행을 권장합니다. 매 세션 UTF-8·터미널을 장황히 설명하지 않고 `AGENTS.md` Working Mode와 `docs/ONBOARDING.md`만 따릅니다. 이어지는 읽기 순서는 아래 **Context Bootstrap Order**를 따릅니다. | 시작 컨텍스트 |
| 3. Context | `AGENTS.md` Required Reading 표를 따라 관련 문서를 읽습니다. | 참고 파일 목록 |
| 4. Survey | 관련 코드와 테스트 위치를 확인합니다. | 변경 후보 경로 |
| 5. Plan | 기존 exec-plan을 확인하고 기능 단위 분리, 의존성, 병행 가능 경계를 판단한 뒤 기능 구현 전에 실행 계획을 만들거나 갱신합니다. **대화 중간에 요청이 늘어나도** 사용자에게 계획(범위·접근·영향·검증)을 먼저 보여 주고, 불명확한 점은 질문한 뒤 **사용자 확인 후**에만 다음 단계로 넘어갑니다. `docs/exec-plans/README.md`의 Plan Creation에 해당하는 소규모 변경(문구만, 오탈자, 이미 관련 exec-plan의 `Steps`에 적힌 구현 세부)은 별도 exec-plan 없이 짧은 메모로 대체할 수 있습니다. | `docs/exec-plans/active/` 또는 짧은 메모 |
| 6. Quality Gate | 핵심 산출물이 다른 기능의 입력이거나 기존 PRD 기능에 닿으면 품질 기준과 회귀 시나리오를 먼저 확인합니다. | 품질 게이트 기준 |
| 7. Implement | 사용자가 Plan 단계의 계획·질문 답에 대해 확인한 뒤, 최소 변경으로 구현합니다. | 코드 변경 |
| 8. Pipeline Verify | 산출물이 다음 단계로 연결되는지 확인합니다. | 연결 검증 로그 |
| 9. Product Verify | 대표 샘플로 실제 사용 품질을 확인합니다. | 품질 검증 로그 |
| 10. Self-Verify | `.harness/checklists/pre-completion.md`로 요구사항과 검증을 다시 확인합니다. | 완료 전 점검 |
| 11. Version Control | 검증 상태에 맞춰 커밋 분리와 push 가능 여부를 판단합니다. | 커밋/push 추천 또는 실행 결과 |
| 12. Report | 변경 요약, 검증 결과, 남은 리스크를 `AGENTS.md`의 Completion Standard 순서로 보고합니다. 시각화 위젯 도구가 있으면 핵심 요약과 `리스크와 다음 판단`·`추천 작업`을 **비쥬얼라이즈 위젯으로 함께** 보고합니다. | 완료 보고 |

## Pipeline Verify와 Product Verify (8~9)

- **Pipeline Verify**: `docs/TESTING.md`의 Commands에 적힌 테스트·린트·타입체크·빌드 등 자동 검증과, 산출물이 다음 모듈·스테이지·API로 넘어가 데이터·이벤트가 끊기지 않는지 확인하는 검증입니다.
- **Product Verify**: `docs/TESTING.md`의 Regression Verification Policy와 수동 시나리오를 포함해, 로딩·빈 상태·오류·대표 사용자 흐름 등 실제 사용 품질을 확인하는 검증입니다.
- 서버 기반 코드를 바꾼 작업이라면 Product Verify 전에 **개발·로컬 서버를 재시작**해 변경분이 프로세스에 올라간 뒤 확인합니다. 상세는 `docs/AGENT_BEHAVIOR.md`의 Goal-Driven Execution과 `docs/BACKEND.md`를 따릅니다.

## Intent-Specific Flow

| 의도 | 흐름 | 확인할 기준 |
|---|---|---|
| Build | 맥락 확인 → 최소 계획 → PRD 영향 범위 확인 → 품질 게이트 확인 → 구현 → 파이프라인 연결 검증 → 제품 품질/회귀 검증 | 로딩, 빈 상태, 오류 상태, 입력 검증, 필요한 로그, 대표 샘플 품질 |
| Debug | 재현 확인 → 가능한 원인 3~5개 정리 → 근거로 원인 확정 → 최소 수정 → 재검증 | 수정 전 실패, 수정 후 성공, 원인 근거, 남은 리스크 |

## Delegation Policy (작업 위임)

메인 채팅의 상위 모델은 설계·결정·통합에 맥락을 집중하고, 병렬화 가능한 가벼운 일은 하위 에이전트에 위임합니다.

| 구분 | 담당 | 예 |
|---|---|---|
| **가벼운 작업 → 하위 에이전트 위임** | 서브에이전트(백그라운드·병렬) | 대량 파일 탐색·읽기 요약, 독립적 조사·리서치, 반복 스캔(위반 목록화·현황 실측), 독립 검증·반증 리뷰, 외부 자료 수집 |
| **무거운 작업 → 메인 상위 모델(메인 채팅)** | 메인 에이전트 직접 | 아키텍처·규칙 결정, 상호 의존적인 다중 파일 수정, 커밋·병합·push 등 상태 변경, 하네스 규칙 변경, 사용자 결재·질문이 걸린 일, 최종 보고 작성 |

- 판단 기준: **실수의 되돌리기 비용이 크거나 턴 간 맥락 연속성이 필요하면 메인**, 결과 요약만 받으면 되는 읽기성 작업이면 위임.
- 위임 지시는 자족적으로 씁니다 — 경로, 기대 산출물 형식, 완료 기준을 지시문 안에 전부 담아 하위 에이전트가 이 대화 없이도 수행 가능해야 합니다.
- 하위 에이전트의 결과는 신뢰하지 않은 입력으로 취급합니다(리뷰의 DoneClaim 원칙과 동일) — 결론에 쓰이는 핵심 수치·주장은 메인이 재확인합니다.
- quick-task 분류와 정합: READ-ONLY성 조사·검증은 위임 우선, LIGHT·HEAVY 구현은 메인 담당.
- 서로 독립인 위임 작업은 순차가 아니라 **병렬로** 띄웁니다.

## Quick Task Flow (즉석 수정)

exec-plan 없이 채팅에서 바로 처리하는 요청은 12단계 전체 대신 `.harness/prompts/quick-task.md`의 축약 루프를 따릅니다.

1. **분류**: READ-ONLY / LIGHT / HEAVY / GIT-OP 중 하나로 선언합니다. HEAVY 트리거(보안·스키마·동시성·새 모듈·공용 인터페이스·기능 동작 변경)에 해당하면 즉석 수정하지 않고 Plan 단계로 전환합니다.
2. **실행**: 한 줄 계획 후 최소 범위로 수정합니다. UI·스타일 파일이면 `docs/UI_RULES.md`를 먼저 확인합니다.
3. **검증**: LIGHT여도 증거 1개(테스트·빌드·수동 확인)는 실제로 실행합니다.
4. **자동 커밋**: `scripts/recommend-version-control.ps1`을 실행하고 추천에 따라 direct work unit 커밋을 만듭니다. 이 단계는 생략하지 않습니다 — 즉석 수정에서 커밋 판단 없이 턴을 끝내는 것이 자동화가 무너지는 지점입니다.
5. **축약 보고**: 요청 확인 / 변경 사항 / 검증 / 커밋 결과 + 비쥬얼라이즈 위젯.

Build 작업은 기능을 완성하는 것이 목표지만, 기존 구조를 깨지 않는 작은 변경을 우선합니다.
Build 작업 중 새 기능 범위가 보이면 바로 구현하지 말고 `docs/exec-plans/README.md`의 Plan Creation 규칙에 따라 active plan을 먼저 만들거나 갱신합니다.
대화 도중 요청이 추가되어도, 사용자에게 갱신된 계획을 보여 주고 질문·확인을 받은 뒤에만 구현을 이어갑니다.
기능 동작, UI, shared component/state, API, data model, navigation, auth/permission 변경은 `docs/PRODUCT_CONTEXT.md`의 PRD 기능 계약을 최신화한 뒤 `docs/TESTING.md`의 회귀 검증 기준에 따라 기존 기능 시나리오를 확인합니다.
Debug 작업은 원인 확인이 목표이며, 확인되지 않은 추측으로 코드를 고치지 않습니다.

## Quality Gate For Downstream Inputs

- Pipeline first는 가능하지만, downstream 기능 전에 핵심 입력 산출물의 품질 기준과 승인 기준을 먼저 고정합니다.
- 어떤 기능의 산출물이 다른 산출물의 입력이 되면 downstream 구현 전에 품질 기준을 검증합니다.
- 예: 노트가 카드, 퀴즈, UI의 입력이면 카드, 퀴즈, UI 품질을 판단하기 전에 노트 품질 승인 기준을 확인합니다.
- "파이프라인 연결 성공"은 데이터가 다음 단계로 흐르는지 보는 검증이고, "제품 품질 통과"는 대표 샘플 기준으로 사람이 사용할 수 있는지 보는 검증입니다.
- 핵심 산출물 품질이 승인되지 않았으면 후속 기능의 품질 완료로 보지 않고 repair 작업을 분리합니다.

## Completion Version Control

작업 완료 단계에서는 검증 결과를 숨기지 않고 버전관리 판단에 반영합니다.
커밋 단위·메시지·브랜치·push 정책의 상세는 `docs/VERSION_CONTROL.md`를 따릅니다.

커밋은 완료 단계에서만 하는 이벤트가 아닙니다. 긴 작업에서는 exec-plan의 top-level 항목(체크박스) 하나가 검증을 통과할 때마다 `scripts/recommend-version-control.ps1`을 실행해 **작업 단위 중간 커밋**을 만듭니다. 세션이 길어질수록 커밋되지 않은 변경을 쌓아 두지 않습니다.

기본 흐름:

1. 관련 테스트, 린트, 타입체크, 빌드 또는 수동 검증을 실행합니다.
2. `scripts/recommend-version-control.ps1 -VerificationStatus Passed`를 실행해 커밋 분리와 push 가능 여부를 확인합니다.
3. exec-plan 없이 구두로 처리한 작은 수정은 direct work unit으로 보고, `Commit: auto_recommended`이면 `scripts/commit-work-unit.ps1 -VerificationStatus Passed -Type <type> -Scope <scope> -Summary "<summary>"`로 단일 기능/테스트 커밋을 만듭니다.
4. `Commit: auto_split_recommended`이면 같은 스크립트로 기능/테스트 커밋과 exec-plan/validation 문서 커밋을 분리합니다.
5. `Commit: docs_recommended`이면 `scripts/commit-work-unit.ps1 -VerificationStatus Passed -DocsMessage "<message>"` 또는 기본 docs 메시지로 docs-only 커밋을 만듭니다.
6. `Commit: hold`이면 커밋하지 않고 `CommitReason`을 완료 보고에 남깁니다.
7. 커밋 후 `scripts/recommend-version-control.ps1 -VerificationStatus Passed`를 다시 실행해 working tree와 push 정책을 확인합니다.
8. `Push: auto_recommended`이면 topic branch 안전 조건을 만족할 때만 push합니다.

예외:

- 사용자가 "커밋하지 마"라고 명시하면 자동 커밋하지 않습니다.
- 사용자가 "수정만 해", "커밋은 내가 할게"처럼 커밋 보류를 명시해도 자동 커밋하지 않습니다.
- 검증이 `Failed`이면 자동 커밋과 자동 push를 하지 않습니다.
- 검증이 `Partial`이면 코드 커밋은 금지하고 exec-plan/validation 기록만 허용합니다.
- `main`, `master`, protected branch에서는 자동 push하지 않습니다.
- PR 생성은 사용자가 요청할 때만 진행합니다.

## Context Bootstrap Order

1. `scripts/bootstrap-agent-context.ps1` — 저장소 구조, 필수 문서, 테스트 명령, 런타임, git 상태 확인(출력 선두 ASCII `io encoding` 줄은 UTF-8 콘솔 출력 요청 신호)
2. `AGENTS.md` — 작업 종류별 진입 문서 확인
3. `ARCHITECTURE.md` — 경계와 금지된 의존성 확인
4. 작업 종류에 해당하는 도메인 문서 (`PRODUCT_CONTEXT.md`, `SECURITY.md` 등)
5. 관련 코드 (테스트 파일을 함께 읽으면 의도가 명확해집니다)
6. 최근 변경 이력 (필요 시)

## Loop Recovery

| 신호 | 행동 |
|---|---|
| 같은 검증이 2회 이상 같은 이유로 실패 | 실패 원인 가설을 다시 쓰고 접근을 바꿉니다. |
| 같은 파일을 3회 이상 수정 | 파일 책임, 요구사항 해석, 테스트 신호를 재검토합니다. |
| 같은 명령을 반복 실행해도 새 정보가 없음 | 다음 실행 전에 무엇을 확인하려는지 적습니다. |
| 계획과 결과가 어긋남 | 구현을 멈추고 Plan 단계로 돌아갑니다. |

## Escalate To User When

| 상황 | 이유 |
|---|---|
| 대화 도중 기능·범위가 추가됨 | 계획 공유·질문·사용자 확인 없이 구현하면 의도와 어긋날 수 있음 |
| 요구사항이 두 가지 이상으로 해석됨 | 구현 후 되돌리기 비용이 큼 |
| 새 의존성, 큰 구조 변경, 데이터 삭제 | 영향 범위가 작업 단위를 넘음 |
| 외부 서비스, 비용, 보안 정책 변경 | 사용자 승인 필요 |
| 검증을 실행할 수 없는 환경 | 완료 선언 불가 |

## Anti Patterns

- 자동 생성 파일을 직접 수정합니다. 다음 생성 과정에서 덮어써지거나 추적이 깨집니다.
- 문서를 건너뛰고 코드부터 수정합니다.
- "아마 이게 맞을 것"으로 검증 없이 완료합니다.
- 요청에 없는 정리, 포맷, 리네이밍을 함께 섞습니다.
- 실패 로그를 요약만 하고 원본을 버립니다.
- Debug 작업에서 재현이나 근거 확인 없이 전체 구조를 다시 씁니다.
