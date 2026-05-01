# Workflow

AI 에이전트가 작업을 받았을 때 어떤 순서로 컨텍스트를 모으고 결과를 내는지 정의합니다.
모델이 강해도 절차가 없으면 같은 실수를 반복합니다.

## Task Lifecycle

| 단계 | 행동 | 산출물 |
|---|---|---|
| 1. Intake | 요청을 한 문장으로 다시 적고 Build/Debug 의도를 분류합니다. | 명확한 목표 문장 |
| 2. Context | `AGENTS.md` Required Reading 표를 따라 관련 문서를 읽습니다. | 참고 파일 목록 |
| 3. Survey | 관련 코드와 테스트 위치를 확인합니다. | 변경 후보 경로 |
| 4. Plan | 모호한 부분과 가정을 표시한 실행 계획을 만듭니다. | `docs/exec-plans/active/` 또는 짧은 메모 |
| 5. Implement | 최소 변경으로 구현합니다. | 코드 변경 |
| 6. Verify | 관련 테스트, 린트, 타입체크, 수동 검증을 실행합니다. | 검증 로그 |
| 7. Version Control | 검증 상태에 맞춰 커밋 분리와 push 가능 여부를 판단합니다. | 커밋/push 추천 또는 실행 결과 |
| 8. Report | 변경 요약, 검증 결과, 남은 리스크를 보고합니다. | 완료 보고 |

## Intent-Specific Flow

| 의도 | 흐름 | 확인할 기준 |
|---|---|---|
| Build | 맥락 확인 → 최소 계획 → 구현 → 상태 처리 확인 → 검증 | 로딩, 빈 상태, 오류 상태, 입력 검증, 필요한 로그 |
| Debug | 재현 확인 → 가능한 원인 3~5개 정리 → 근거로 원인 확정 → 최소 수정 → 재검증 | 수정 전 실패, 수정 후 성공, 원인 근거, 남은 리스크 |

Build 작업은 기능을 완성하는 것이 목표지만, 기존 구조를 깨지 않는 작은 변경을 우선합니다.
Debug 작업은 원인 확인이 목표이며, 확인되지 않은 추측으로 코드를 고치지 않습니다.

## Completion Version Control

작업 완료 단계에서는 검증 결과를 숨기지 않고 버전관리 판단에 반영합니다.

기본 흐름:

1. 관련 테스트, 린트, 타입체크, 빌드 또는 수동 검증을 실행합니다.
2. `scripts/recommend-version-control.ps1 -VerificationStatus Passed`를 실행해 커밋 분리와 push 가능 여부를 확인합니다.
3. `Commit: auto_split_recommended`이면 `scripts/commit-work-unit.ps1 -VerificationStatus Passed -Type <type> -Scope <scope> -Summary "<summary>"`로 기능/테스트 커밋과 exec-plan/validation 문서 커밋을 분리합니다.
4. 커밋 후 `scripts/recommend-version-control.ps1 -VerificationStatus Passed`를 다시 실행해 working tree와 push 정책을 확인합니다.
5. `Push: auto_recommended`이면 topic branch 안전 조건을 만족할 때만 push합니다.

예외:

- 사용자가 "커밋하지 마"라고 명시하면 자동 커밋하지 않습니다.
- 검증이 `Failed`이면 자동 커밋과 자동 push를 하지 않습니다.
- 검증이 `Partial`이면 코드 커밋은 금지하고 exec-plan/validation 기록만 허용합니다.
- `main`, `master`, protected branch에서는 자동 push하지 않습니다.
- PR 생성은 사용자가 요청할 때만 진행합니다.

## Context Bootstrap Order

1. `AGENTS.md` — 작업 종류별 진입 문서 확인
2. `ARCHITECTURE.md` — 경계와 금지된 의존성 확인
3. 작업 종류에 해당하는 도메인 문서 (`PRODUCT_CONTEXT.md`, `SECURITY.md` 등)
4. 관련 코드 (테스트 파일을 함께 읽으면 의도가 명확해집니다)
5. 최근 변경 이력 (필요 시)

## Escalate To User When

| 상황 | 이유 |
|---|---|
| 요구사항이 두 가지 이상으로 해석됨 | 구현 후 되돌리기 비용이 큼 |
| 새 의존성, 큰 구조 변경, 데이터 삭제 | 영향 범위가 작업 단위를 넘음 |
| 외부 서비스, 비용, 보안 정책 변경 | 사용자 승인 필요 |
| 검증을 실행할 수 없는 환경 | 완료 선언 불가 |

## Anti Patterns

- 문서를 건너뛰고 코드부터 수정합니다.
- "아마 이게 맞을 것"으로 검증 없이 완료합니다.
- 요청에 없는 정리, 포맷, 리네이밍을 함께 섞습니다.
- 실패 로그를 요약만 하고 원본을 버립니다.
- Debug 작업에서 재현이나 근거 확인 없이 전체 구조를 다시 씁니다.
