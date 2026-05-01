# Execution Plans

긴 작업은 바로 구현하지 말고 실행 계획으로 쪼갭니다.

## Workflow

1. `active/`에 계획 파일을 만듭니다.
2. 목표, 범위, 의존성, 품질 게이트, 검증 방법, 체크리스트를 작성합니다.
3. 작업 중 발견한 결정과 리스크를 업데이트합니다.
4. 기능 동작 완료와 품질 승인 완료를 분리해서 기록합니다.
5. 완료 후 `completed/`로 이동합니다.

## Status

active plan의 표준 상태는 `Ready`, `Active`, `Blocked`, `Partial`, `Completed`만 사용합니다.

| 상태 | 의미 |
|---|---|
| `Ready` | 구현 가능한 계획이지만 아직 시작하지 않았습니다. |
| `Active` | 현재 진행 중인 계획입니다. |
| `Blocked` | 외부 결정, 의존성, 환경 문제로 진행할 수 없습니다. |
| `Partial` | 일부 결과는 완료됐지만 scope, validation, follow-up이 남았습니다. |
| `Completed` | 완료 이동 기준을 만족했고 `completed/`로 옮길 수 있습니다. |

## Dependency Order

- active 계획을 만들 때 `Depends On`, `Blocks`, `Quality Gate`를 기록합니다.
- 어떤 계획이 다른 기능의 입력 품질을 결정하면 downstream 계획보다 먼저 실행합니다.
- completed 이동 기준에는 기능 동작 완료와 품질 승인 완료를 분리해서 남깁니다.
- 품질 미달이면 기능 작업을 completed로 옮기더라도 후속 `quality-repair` 계획을 `active/`에 반드시 만듭니다.
- 품질 승인 전에는 카드, 퀴즈, UI 같은 downstream 기능의 품질 완료로 간주하지 않습니다.

## Priority Order

- active plan은 파일명 오름차순으로 우선순위를 판단합니다.
- `00`, `01`, `18a`, `20d`처럼 숫자와 보조번호가 섞여도 의미를 따로 파싱하지 않습니다.
- 선행 작업을 명시해야 하면 파일명 순서에만 의존하지 말고 `Depends On`, `Blocks`, `Quality Gate`에 기록합니다.

## Completion Rule

`completed/`로 이동하기 전에 아래 조건을 모두 만족해야 합니다.

- `Goal`, `Scope`, `Steps`, `Validation`, `Result`가 채워져 있습니다.
- `Steps`는 완료, 취소, 분리 중 하나로 정리되어 있습니다.
- 검증 결과와 실행하지 못한 검증의 이유가 `Validation`에 남아 있습니다.
- 남은 후속 작업은 별도 active plan 또는 `tech-debt-tracker.md`에 기록되어 있습니다.

## Empty Active Flow

`active/`에 실행 계획이 없으면 아래 순서로 다음 단계를 판단합니다.

1. 최근 사용자 요청, 실패한 검증, 미완료 run log를 확인합니다.
2. `tech-debt-tracker.md`에서 즉시 실행 가능한 항목이 있는지 확인합니다.
3. `scripts/validate-harness.ps1 -Maintenance` warning 중 계획이 필요한 항목을 확인합니다.
4. 실행 가능한 작업이 있으면 `active/`에 새 plan을 만들고 상태를 `Ready`로 둡니다.
5. 실행 가능한 작업이 없으면 억지 plan을 만들지 말고 현재 active가 비어 있음을 보고합니다.

## Plan Template

```md
# Plan: 작업 이름

## Status

Ready

## Goal

## Scope

## Depends On

- None

## Blocks

- None

## Quality Gate

- Required: yes/no
- Criteria:
- Representative sample:
- Approval:

## Steps

- [ ] 

## Validation

- Pipeline connection:
- Product quality:

## Risks

## Result

- Functional status:
- Quality approval:
- Follow-up repair plan:
```
