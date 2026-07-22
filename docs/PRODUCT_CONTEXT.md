# Product Context

AI가 기능의 목적을 오해하지 않도록 제품 맥락을 기록합니다.

## 이 문서의 역할

- 이 저장소는 **하네스 템플릿**입니다. `Problem`, `Target Users`, `Out of scope`, `PRD Feature Contract`는 **실제 제품 저장소로 포크·도입할 때** 채웁니다.
- 긴 서술형 PRD는 [`docs/product-specs/index.md`](product-specs/index.md)와 기능별 명세에 두고, 이 파일의 **기능 계약 표**는 구현·회귀 테스트의 단일 요약 기준으로 유지합니다.
- 회귀 검증 절차는 [`docs/TESTING.md`](TESTING.md)의 Regression Verification Policy를 따릅니다.
- 도메인 용어는 [`docs/GLOSSARY.md`](GLOSSARY.md)와 충돌하지 않게 맞춥니다.

## Problem

다음을 **최소 1~3문장**으로 적습니다. 인용 블록 안에 바로 써도 됩니다.

- 누가 어떤 상황에서 무엇이 어렵거나 비용이 큰지
- 지금 쓰는 대안(수동, 다른 도구)의 한계
- 이 제품이 없을 때 빠지는 기회나 리스크(선택)

> 사용자가 겪는 핵심 문제를 설명합니다.

## Target Users

| 사용자 | 목표 | 불편 |
|---|---|---|
| 예: 일반 사용자 | 빠르게 작업 완료 | 복잡한 설정 |

## Product Principles

- 사용자는 가능한 한 적은 단계로 핵심 작업을 끝낼 수 있어야 합니다.
- 오류 상황에서는 다음 행동이 분명해야 합니다.
- 내부 구현의 복잡함이 사용자에게 노출되지 않아야 합니다.

## Out of scope

의도적으로 하지 않는 일을 적어 AI·기획의 범위 확대를 줄입니다. 아래는 **형식 예시**이며, 실제 제품에 맞게 바꿉니다.

- 예: 이번 제품 버전에서 지원하지 않는 플랫폼·역할·지역
- 예: 연동하지 않는 외부 시스템, 저장하지 않는 데이터 범주
- 예: “나중에 할 수도 있다” 수준이 아니라 **명시적으로 제외**하는 정책·기능

## PRD Feature Contract

PRD의 핵심 기능은 아래 표에 기능 계약으로 요약합니다.
기능 자체를 수정하지 않더라도 공유 UI, state, API, data model, navigation, auth/permission을 바꾸면 관련 feature를 영향 범위로 봅니다.
전체 PRD 기능 테스트는 원본 PRD 문장이 아니라 이 표에서 `Contract status`가 `Current`인 최신 기능 계약을 기준으로 실행합니다.
기능 수정, UI 흐름 변경, API/data 변경, 권한/네비게이션 변경이 있으면 관련 Feature ID의 현재 기대 동작과 회귀 시나리오를 먼저 갱신합니다.

**원본·상세 명세**: [`docs/product-specs/index.md`](product-specs/index.md)에서 기능 목록을 유지합니다. 표가 길어지면 행은 유지하되, 긴 서술은 기능별 명세 파일로 옮기고 표에는 요약·링크만 둡니다.

**Feature ID 규칙**

- 기본: `PRD-F001`, `PRD-F002`처럼 **`PRD-F` + 세 자리 숫자**(필요 시 더 긴 번호)를 권장합니다.
- 비기능 요구(성능, 보안, 감사 등)를 표에 넣을 때는 `PRD-N001` 같은 별도 접두어를 두고, **같은 접두어 안에서만** 번호를 올립니다.
- 외부 이슈·요구 ID와 매핑할 때는 `Last updated by` 또는 기능 명세에 그 ID를 적어 추적합니다.

**Verification source** 열에는 아래 중 하나 이상을 구체적으로 적습니다.

- 자동: 테스트 파일 경로와 테스트 이름(또는 스위트 이름)
- 수동: [`docs/TESTING.md`](TESTING.md)에 적힌 시나리오 제목·절차 구역
- 계획: `docs/exec-plans/active/` 또는 `completed/`의 plan id와 검증 단계(예: `Validation`에 정의된 항목)

`Contract status`는 아래 값만 사용합니다.

- `Current`: 현재 구현과 테스트 기준이 일치합니다.
- `Needs update`: 구현 또는 계획이 바뀌었지만 기능 계약과 회귀 시나리오가 아직 최신이 아닙니다.
- `Deprecated`: 더 이상 전체 PRD 기능 테스트 대상이 아닙니다.

| Feature ID | Core flow | Current expected behavior | Must keep working | Regression scenario | Verification source | Last updated by | Contract status |
|---|---|---|---|---|---|---|---|
| 예: PRD-F001 | 사용자가 핵심 작업을 시작하고 완료함 | 현재 구현 기준의 기대 동작 | 기존 입력, 저장, 결과 확인 흐름 | 대표 사용자로 핵심 작업을 끝까지 수행 | 예: `tests/foo.spec.ts`의 `completes core flow` 또는 `docs/TESTING.md` 수동 시나리오 「핵심 작업」 | plan id, PR, commit, or date | Current |

## Success Criteria

| 기준 | 설명 | 확인 방법 |
|---|---|---|
| 기능 성공 | 사용자가 핵심 작업을 완료함 | 수동 시나리오 또는 테스트 |
| 안정성 | 실패 시 원인 파악 가능 | 로그와 에러 메시지 확인 |
| 유지보수성 | 변경 범위가 예측 가능 | 구조와 테스트 확인 |
