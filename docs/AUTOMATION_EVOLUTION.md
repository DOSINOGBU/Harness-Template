# Automation Evolution

하네스가 문서에서 자동화로 진화하는 단계를 기록합니다.

## Stages

| 단계 | 예시 | 도입 기준 |
|---|---|---|
| Prompt | 반복 지시문 | 같은 요청이 반복됨 |
| Checklist | 완료 기준 | 같은 누락이 두 번 발생 |
| Script | 로컬 검증/생성 | 사람이 매번 같은 확인을 수행 |
| CI | PR/정기 검증 | 공유 브랜치 안정성에 영향 |
| Hook | PreToolUse, pre-commit | 실행 전 자동 차단 필요 |
| Agent/Subagent | 독립 탐색, 리뷰, 검증 | 병렬화할 가치가 있는 반복 작업 |

## Candidates

| 후보 | 현재 단계 | 다음 단계 | 근거 |
|---|---|---|---|
| Pre-completion self-verify | Prompt / Checklist | Hook | 완료 직전 검증 누락을 줄이기 위해 종료 전 점검을 강제할 수 있습니다. |
| Context bootstrap | Script | Middleware | 작업 시작 시 환경 탐색을 자동 주입하면 문서·명령 누락을 줄일 수 있습니다. |
| Loop detection | Checklist | Tool hook | 같은 파일 반복 수정과 같은 검증 반복 실패를 감지하면 접근 재검토를 유도할 수 있습니다. |
| Agent run log | Document | Trace store | 반복 실패를 수동 감이 아니라 기록 기반으로 분석할 수 있습니다. |
