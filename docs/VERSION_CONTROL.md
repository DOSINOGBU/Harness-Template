# Version Control

커밋은 나중에 원인을 추적하고 되돌릴 수 있는 작업 단위입니다.
작은 커밋보다 중요한 것은 하나의 목적과 검증 가능한 상태입니다.

## Commit Principles

- 한 커밋은 하나의 목적만 가집니다.
- 기능 추가, 버그 수정, 리팩터링, 문서 수정, 설정 변경을 섞지 않습니다.
- 되돌리기 쉬운 최소 단위로 커밋합니다.
- 실행 불가능한 상태에서는 커밋하지 않습니다.
- 자동 포맷 변경과 기능 수정은 별도 커밋으로 분리합니다.

## Before Commit

| 확인 | 기준 |
|---|---|
| 실행 가능 상태 | 앱, 빌드, 테스트 중 작업에 맞는 검증을 통과 |
| 타입 검사 | 타입 시스템이 있으면 타입 에러 없음 |
| 린트 | 린트가 있으면 통과, 자동 수정은 기능 변경과 분리 |
| 회귀 확인 | 기존 핵심 흐름이 깨지지 않음 |
| 디버그 코드 | 임시 로그, 테스트 코드, 주석 제거 |
| 민감정보 | `.env`, 토큰, API 키, 계정 정보가 포함되지 않음 |

검증을 실행할 수 없으면 커밋 메시지로 숨기지 말고 완료 보고에 이유와 대체 확인 방법을 남깁니다.

## Commit Message Format

```text
type(scope): summary
```

예시:

```text
feat(chat): add button-based goal suggestion flow
fix(dnd): prevent drop sync error
refactor(project): split logic into utils
docs(prd): update recurring automation spec
style(ui): adjust card spacing
test(task): add schedule parser test
chore(repo): update gitignore
```

## Types

| type | 의미 |
|---|---|
| `feat` | 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 기능 변화 없는 구조 개선 |
| `docs` | 문서 수정 |
| `style` | UI 또는 스타일 수정 |
| `test` | 테스트 추가 또는 수정 |
| `chore` | 설정, 의존성, 저장소 관리 |
| `perf` | 성능 개선 |

## Message Rules

- 첫 줄은 짧고 명확하게 씁니다.
- `update`, `fix stuff`처럼 범위와 목적을 알 수 없는 표현은 쓰지 않습니다.
- 무엇을 바꿨는지와 왜 하나의 커밋인지 드러나게 씁니다.
- 한 커밋에 여러 의미가 보이면 커밋을 나눕니다.

## Split Criteria

좋은 커밋 단위:

- 드래그 버그 수정
- 목표 카드 UI 수정
- 반복 로직 추가
- 테스트 명령 문서화

나쁜 커밋 단위:

- UI, DB, 상태관리, 문구 수정을 한 번에 포함
- 자동 포맷과 기능 변경을 한 번에 포함
- 미완성 기능과 관련 없는 정리를 함께 포함
