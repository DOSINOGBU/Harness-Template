# Execution Plans

긴 작업은 바로 구현하지 말고 실행 계획으로 쪼갭니다.

## Workflow

1. `active/`에 계획 파일을 만듭니다.
2. 목표, 범위, 의존성, 병행 가능 경계, 품질 게이트, 검증 방법, 체크리스트를 작성합니다.
3. 작업 중 발견한 결정과 리스크를 업데이트합니다.
4. 긴 API 작업이나 자동 파이프라인이면 checkpoint, resume, time budget, candidate limit를 기록합니다.
5. 기능 동작 완료와 품질 승인 완료를 분리해서 기록합니다.
6. 완료 후 `completed/`로 이동합니다.

## Plan Creation

새 기능 plan을 만들기 전에 `active/`와 `completed/`의 기존 plan 내용을 먼저 확인합니다.

- 기능 추가나 기능 변경은 코드 구현보다 exec-plan 생성 또는 갱신이 먼저입니다.
- 작업 중 새 기능 범위가 발견되면 바로 해결하지 말고, 먼저 기존 active plan에 포함되는지 확인합니다.
- 기존 active plan의 `Scope`에 없는 기능이면 구현을 멈추고 관련 parent plan의 하위 plan을 만들거나 기존 plan의 `Scope`, `Steps`, `Depends On`, `Parallel Work`를 갱신합니다.
- 작은 문구 수정, 단순 오탈자, 이미 plan의 `Steps`에 명시된 구현 세부사항은 별도 plan을 만들지 않아도 되지만, 기능 동작이나 사용자 흐름이 바뀌면 반드시 plan을 먼저 남깁니다.
- 새 exec-plan은 반드시 `docs/exec-plans/template.md`를 복사해서 만듭니다.
- template의 heading 이름, 순서, depth를 바꾸거나 삭제하지 않습니다.
- 해당 없는 항목도 heading은 유지하고 `- None` 또는 빈 항목으로 남깁니다.
- 기존 plan과 같은 기능 흐름, 사용자 작업, 데이터 파이프라인, 화면, API, 품질 게이트, 후속 보완 범위 중 하나라도 연결되면 관련 parent plan으로 봅니다.
- 관련 parent plan이 있으면 새 top-level 번호를 만들지 않고 parent의 숫자 prefix에 다음 알파벳 suffix를 붙입니다.
- 예: `01-auth.md`와 관련된 후속 plan은 `01a-auth-session.md`, 다음 관련 plan은 `01b-auth-roles.md`로 만듭니다.
- `01a` 아래에 `01aa`처럼 다시 중첩하지 않고 같은 숫자 root의 다음 suffix를 사용합니다.
- 기존 plan과 연결되지 않는 완전히 새로운 기능일 때만 다음 top-level 번호를 사용합니다.
- 새 top-level 번호를 사용하는 경우 `Scope`에 기존 plan과 분리되는 이유를 적습니다.
- 관련성을 판단하기 어렵다면 새 번호를 만들지 말고 가장 가까운 후보 parent의 하위 plan으로 둔 뒤 후보 parent와 애매한 이유를 `Depends On`, `Blocks`, `Scope`에 명시합니다.
- 큰 기능은 한 plan에 몰지 않고, 한 AI가 맡을 수 있는 독립 기능 단위 plan으로 나눕니다.

## Status

active plan의 표준 상태는 `Ready`, `Active`, `Blocked`, `Partial`, `Completed`만 사용합니다.

| 상태 | 의미 |
|---|---|
| `Ready` | 구현 가능한 계획이지만 아직 시작하지 않았습니다. |
| `Active` | 현재 진행 중인 계획입니다. |
| `Blocked` | 외부 결정, 의존성, 환경 문제, 선행 plan 계약 미완료로 독립 구현 범위가 없습니다. |
| `Partial` | 독립 구현 범위는 완료됐지만 의존 범위, 검증, follow-up이 남았습니다. |
| `Completed` | 완료 이동 기준을 만족했고 `completed/`로 옮길 수 있습니다. |

## Dependency Order

- active 계획을 만들 때 `Depends On`, `Blocks`, `Quality Gate`를 기록합니다.
- 어떤 계획이 다른 기능의 입력 품질을 결정하면 downstream 계획보다 먼저 실행합니다.
- completed 이동 기준에는 기능 동작 완료와 품질 승인 완료를 분리해서 남깁니다.
- 품질 미달이면 기능 작업을 completed로 옮기더라도 후속 `quality-repair` 계획을 `active/`에 반드시 만듭니다.
- 품질 승인 전에는 카드, 퀴즈, UI 같은 downstream 기능의 품질 완료로 간주하지 않습니다.

## Parallel Work

여러 AI가 병행 작업할 수 있도록 plan은 기능 단위와 소유 경계를 명확히 둡니다.

- 한 active plan 파일은 한 AI가 맡을 수 있는 실행 단위여야 합니다.
- 병행 가능한 plan은 서로 다른 `Scope`, `Ownership boundary`, `Depends On`, `Blocks`를 가져야 합니다.
- 같은 파일, API 계약, 데이터 구조를 동시에 바꾸면 병행 가능으로 보지 않습니다.
- 실행 전에는 `Depends On`, `Blocks`, `Parallel Work`를 먼저 확인합니다.
- 선행 plan의 데이터 구조, API, 계약이 미완료이면 `Independent scope`만 구현합니다.
- `Independent scope`가 없으면 코드 변경 없이 `Blocked`로 보고합니다.
- 일부만 구현했다면 `Partial`로 보고하고 `Blocked scope`, 보류 이유, `Resume after`를 남깁니다.
- 계약 없이 가능한 mock UI나 shell 작업은 `Independent scope`에 명시된 경우에만 병행 구현합니다.

## Priority Order

- active plan은 파일명 오름차순으로 우선순위를 판단합니다.
- `00`, `01`, `18a`, `20d`처럼 숫자와 보조번호가 섞여도 의미를 따로 파싱하지 않습니다.
- 선행 작업을 명시해야 하면 파일명 순서에만 의존하지 말고 `Depends On`, `Blocks`, `Quality Gate`에 기록합니다.

## Completion Rule

`completed/`로 이동하기 전에 아래 조건을 모두 만족해야 합니다.

- `Goal`, `Scope`, `Steps`, `Validation`, `Result`가 채워져 있습니다.
- `Steps`는 완료, 취소, 분리 중 하나로 정리되어 있습니다.
- 검증 결과와 실행하지 못한 검증의 이유가 `Validation`에 남아 있습니다.
- 기능 동작이 바뀐 Feature ID는 `PRD Feature Contract`의 현재 기대 동작, 회귀 시나리오, 계약 상태가 최신입니다.
- 전체 PRD 기능 테스트는 `Contract status=Current`인 기능 계약을 기준으로 실행했습니다.
- 수정된 기능 계약이 `Needs update`이면 전체 PRD 기능 정상 작동을 완료로 선언하지 않습니다.
- 변경이 기존 PRD 기능 계약에 닿는다면 영향받은 기능과 회귀 시나리오 결과가 `Validation`에 남아 있습니다.
- `Result`는 표준 완료 보고 섹션 순서로 정리되어 있습니다: 요청 확인, 변경 사항, 검증, 결과 확인, CodeHealth, 리스크와 다음 판단.
- 기능 상태와 품질 승인 결과는 `Result`의 `검증`에, 후속 보완 계획은 `리스크와 다음 판단`에 남깁니다.
- `Partial` 또는 `Blocked`이면 독립 완료 범위, 보류 범위, 보류 이유, 재개 조건이 `Result`에 남아 있습니다.
- `docs/exec-plans/template.md`의 heading 이름, 순서, depth를 유지했습니다.
- 남은 후속 작업은 별도 active plan 또는 `tech-debt-tracker.md`에 기록되어 있습니다.

## Empty Active Flow

`active/`에 실행 계획이 없으면 아래 순서로 다음 단계를 판단합니다.

1. 최근 사용자 요청, 실패한 검증, 미완료 run log를 확인합니다.
2. `tech-debt-tracker.md`에서 즉시 실행 가능한 항목이 있는지 확인합니다.
3. `scripts/validate-harness.ps1 -Maintenance` warning 중 계획이 필요한 항목을 확인합니다.
4. 실행 가능한 작업이 있으면 `active/`에 새 plan을 만들고 상태를 `Ready`로 둡니다.
5. 실행 가능한 작업이 없으면 억지 plan을 만들지 말고 현재 active가 비어 있음을 보고합니다.

## Plan Template

표준 템플릿은 `docs/exec-plans/template.md`입니다.

새 plan을 만들 때는 이 파일을 복사하고, heading 이름, 순서, depth를 그대로 유지합니다.
Maintenance 검증은 `active/`와 `completed/`의 plan이 이 구조를 지키는지 확인합니다.
