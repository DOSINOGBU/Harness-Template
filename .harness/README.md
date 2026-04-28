# Harness

이 폴더는 AI 에이전트를 운영하기 위한 반복 가능한 작업 절차를 담습니다.

## Contents

| 폴더 | 목적 |
|---|---|
| `checklists/` | 작업 유형별 완료 기준 |
| `prompts/` | 반복 사용 가능한 프롬프트 템플릿 |

## Checklists

| 파일 | 사용 시점 |
|---|---|
| `feature-change.md` | 기능 추가·변경 |
| `bug-fix.md` | 버그 수정 |
| `refactor.md` | 동작 변경 없는 구조 개선 |
| `release.md` | 릴리스 전 점검 |
| `dependency-add.md` | 새 의존성 도입 |
| `migration.md` | 데이터·스키마 마이그레이션 |
| `incident.md` | 장애 대응과 사후 기록 |
| `doc-update.md` | 문서 갱신 |

## Prompts

| 파일 | 사용 시점 |
|---|---|
| `plan-task.md` | 구현 전에 계획부터 받고 싶을 때 |
| `implement-task.md` | 합의된 계획으로 구현 |
| `review-change.md` | 변경 자체 리뷰 |
| `fix-failing-check.md` | 검증 실패 분석·수정 |
| `debug-issue.md` | 증상에서 원인까지 단계 분석 |
| `write-tests.md` | 신뢰할 만한 테스트 작성 |
| `update-docs.md` | 변경에 맞춰 문서 갱신 |
| `explain-code.md` | 모르는 코드 빠르게 파악 |

## Principle

프롬프트는 일회성 지시입니다.
하네스는 반복 가능한 작업 시스템입니다.
같은 실수가 두 번 나오면 체크리스트로, 세 번 나오면 자동화로 옮깁니다.
