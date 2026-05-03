# Learning Log

반복되는 AI/개발 실수를 기록하고, 메모에서 체크리스트와 자동화로 승격시키는 공간입니다.

## Entries

| 날짜 | 반복된 실수 | 발생 작업 | 원인 | 현재 대응 | 자동화 후보 |
|---|---|---|---|---|---|
| 예시 | 검증 없이 완료 보고 | 기능 구현 | 완료 전 점검 부재 | checklist | pre-completion hook |
| 2026-05-01 | 결과 확인 위치와 CLI/UI 검증 범위 누락 | 기능 구현 완료 보고 | completion 보고 항목이 검증 결과 중심으로만 구성됨 | pre-completion checklist/prompt | completion report hook |
| 2026-05-01 | 긴 API 작업의 재개 기준과 부분 완료 기준 누락 | 자동 파이프라인 | checkpoint, resume, budget, acceptance mode가 계획 기본값이 아님 | reliability/plan checklist | long-job plan validator |

## Input Sources

- `docs/agent-runs/`의 반복 실패와 검증 누락 기록을 확인합니다.
- 코드 리뷰에서 같은 지적이 반복되면 이 문서에 먼저 기록합니다.
- 같은 항목이 두 번 이상 반복되면 관련 checklist에 반영합니다.

## Promotion Rule

- 한 번 발생하면 메모합니다.
- 두 번 반복되면 checklist에 반영합니다.
- 세 번 반복되면 자동화나 검증 스크립트 후보로 올립니다.
