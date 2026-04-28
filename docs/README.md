# Docs Index

이 폴더는 AI 에이전트가 프로젝트 맥락을 빠르게 이해하기 위한 Code Wiki입니다.
문서는 길게 쓰기보다, 코드만 보고 알 수 없는 이유와 제약을 기록합니다.

## Core Documents

| 문서 | 목적 |
|---|---|
| `WORKFLOW.md` | 작업 수명 주기와 컨텍스트 로딩 절차 |
| `PROJECT_RULES.md` | 작업 규칙, 금지 사항, 승인 필요 작업 |
| `PRODUCT_CONTEXT.md` | 제품 목적, 사용자, 성공 기준 |
| `GLOSSARY.md` | 도메인 용어 사전 |
| `CODE_STYLE.md` | 도구가 잡지 못하는 코드 판단 기준 |
| `TESTING.md` | 테스트, 린트, 타입체크, 수동 검증 |
| `OBSERVABILITY.md` | 로그, 에러 메시지, 디버깅 신호 |
| `RELIABILITY.md` | 실패 처리, 재시도, 복구 원칙 |
| `SECURITY.md` | 권한, 민감정보, 보안 체크 |
| `DATA.md` | 데이터, 마이그레이션, 되돌릴 수 없는 작업 |
| `DEPENDENCIES.md` | 의존성 추가, 제거, 갱신 정책 |
| `VERSION_CONTROL.md` | 커밋 단위, 메시지, 커밋 전 확인 기준 |
| `PULL_REQUESTS.md` | PR 생성, 리뷰, 머지 전 확인 기준 |
| `PERFORMANCE.md` | 성능 예산과 흔한 함정 |
| `ONBOARDING.md` | 신규 합류자(사람·AI) 출발점 |
| `QUALITY_SCORE.md` | AI 작업 결과 품질 평가 기준 |

## Document Tiers

모든 문서를 처음부터 채워야 한다는 뜻이 아닙니다.
필수 문서로 작업을 시작하고, 작업 종류와 프로젝트 성숙도에 따라 필요한 문서를 점진적으로 읽고 보강합니다.

| 단계 | 문서 | 사용 시점 |
|---|---|---|
| Essential | `../AGENTS.md`, `../ARCHITECTURE.md`, `WORKFLOW.md`, `PROJECT_RULES.md`, `TESTING.md` | 템플릿 도입과 모든 작업의 기본 진입점 |
| Common | `PRODUCT_CONTEXT.md`, `QUALITY_SCORE.md`, `VERSION_CONTROL.md`, `PULL_REQUESTS.md`, `.harness/checklists/feature-change.md`, `.harness/checklists/bug-fix.md` | 기능 추가, 버그 수정, 커밋, PR처럼 자주 반복되는 작업 |
| Conditional | `SECURITY.md`, `DATA.md`, `DEPENDENCIES.md`, `PERFORMANCE.md`, `FRONTEND.md`, `BACKEND.md` | 해당 영역을 실제로 변경할 때 |
| Mature / Optional | `adr/`, `generated/`, `references/`, `exec-plans/`, `exec-plans/tech-debt-tracker.md` | 결정 기록, 생성 문서, 외부 참고, 장기 계획이 필요한 단계 |

`Optional`은 중요하지 않다는 뜻이 아닙니다.
프로젝트가 아직 그 정보를 만들 만큼 성숙하지 않았거나, 현재 작업에 필요하지 않다면 초기 컨텍스트에서 제외해도 된다는 의미입니다.

## Subdirectories

| 폴더 | 목적 |
|---|---|
| `design-docs/` | 큰 설계 방향과 핵심 신념 |
| `product-specs/` | 기능별 제품 요구사항 |
| `exec-plans/` | 긴 작업 계획과 진행 기록 |
| `adr/` | 기술 의사결정 기록 |
| `generated/` | 자동 생성된 참고 문서 |
| `references/` | 외부 자료 요약과 링크 |
