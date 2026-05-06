# Product Context

AI가 기능의 목적을 오해하지 않도록 제품 맥락을 기록합니다.

## Problem

> 사용자가 겪는 핵심 문제를 설명합니다.

## Target Users

| 사용자 | 목표 | 불편 |
|---|---|---|
| 예: 일반 사용자 | 빠르게 작업 완료 | 복잡한 설정 |

## Product Principles

- 사용자는 가능한 한 적은 단계로 핵심 작업을 끝낼 수 있어야 합니다.
- 오류 상황에서는 다음 행동이 분명해야 합니다.
- 내부 구현의 복잡함이 사용자에게 노출되지 않아야 합니다.

## PRD Feature Contract

PRD의 핵심 기능은 아래 표에 기능 계약으로 요약합니다.
기능 자체를 수정하지 않더라도 공유 UI, state, API, data model, navigation, auth/permission을 바꾸면 관련 feature를 영향 범위로 봅니다.
전체 PRD 기능 테스트는 원본 PRD 문장이 아니라 이 표에서 `Contract status`가 `Current`인 최신 기능 계약을 기준으로 실행합니다.
기능 수정, UI 흐름 변경, API/data 변경, 권한/네비게이션 변경이 있으면 관련 Feature ID의 현재 기대 동작과 회귀 시나리오를 먼저 갱신합니다.

`Contract status`는 아래 값만 사용합니다.

- `Current`: 현재 구현과 테스트 기준이 일치합니다.
- `Needs update`: 구현 또는 계획이 바뀌었지만 기능 계약과 회귀 시나리오가 아직 최신이 아닙니다.
- `Deprecated`: 더 이상 전체 PRD 기능 테스트 대상이 아닙니다.

| Feature ID | Core flow | Current expected behavior | Must keep working | Regression scenario | Verification source | Last updated by | Contract status |
|---|---|---|---|---|---|---|---|
| 예: PRD-F001 | 사용자가 핵심 작업을 시작하고 완료함 | 현재 구현 기준의 기대 동작 | 기존 입력, 저장, 결과 확인 흐름 | 대표 사용자로 핵심 작업을 끝까지 수행 | 자동 테스트 또는 `docs/TESTING.md` 수동 시나리오 | plan id, PR, commit, or date | Current |

## Success Criteria

| 기준 | 설명 | 확인 방법 |
|---|---|---|
| 기능 성공 | 사용자가 핵심 작업을 완료함 | 수동 시나리오 또는 테스트 |
| 안정성 | 실패 시 원인 파악 가능 | 로그와 에러 메시지 확인 |
| 유지보수성 | 변경 범위가 예측 가능 | 구조와 테스트 확인 |
