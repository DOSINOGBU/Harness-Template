# Architecture

프로젝트의 구조와 데이터 흐름을 AI가 빠르게 이해하기 위한 문서입니다.
코드가 말해주지 않는 의도, 경계, 금지된 의존성을 중심으로 작성합니다.

## System Overview

> 이 프로젝트가 어떤 문제를 해결하는지 3~5문장으로 설명합니다.

## Main Flow

```text
User Input
→ Validation
→ Business Logic
→ Data Access / External API
→ Response / UI Rendering
```

## Layer Rules

| Layer | Responsibility | Must Not |
|---|---|---|
| UI / Presentation | 화면 표시, 사용자 입력 전달 | 비즈니스 규칙 직접 처리 |
| Application / Service | 사용 사례 조합, 흐름 제어 | DB 세부 구현 직접 노출 |
| Domain / Business | 핵심 규칙, 검증, 계산 | UI나 외부 API에 의존 |
| Infrastructure | DB, 파일, 외부 API, 환경 설정 | 도메인 규칙 결정 |

## Dependency Direction

```text
UI → Application → Domain
Application → Infrastructure
Domain → no framework dependency
```

## Forbidden Patterns

- UI 컴포넌트에서 직접 DB나 외부 API를 호출하지 않습니다.
- 도메인 로직을 라우터, 컨트롤러, 화면 컴포넌트 안에 숨기지 않습니다.
- 설정값, 토큰, 비밀키를 코드에 하드코딩하지 않습니다.
- 실패를 빈 `catch`나 무의미한 기본값으로 숨기지 않습니다.

## Open Questions

| 질문 | 현재 결정 | 다음 확인 |
|---|---|---|
| 예: 인증 방식 | 미정 | 제품 요구사항 확정 후 ADR 작성 |
