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

## Standard Work Unit Split

기능/테스트 변경과 실행 계획 완료 문서가 함께 남는 것은 하네스의 표준 작업 단위입니다.
이 조합은 혼합 변경으로 `hold`하지 않고, 검증 통과 후 자동 분리 대상입니다.

표준 분리 대상:

- 기능 또는 테스트 변경: `.harness/config.json`의 `versionControl.workUnitPaths.code`, `versionControl.workUnitPaths.tests`
- 실행 계획 완료 문서: `versionControl.workUnitPaths.execPlansCompleted`
- 검증 기록: `versionControl.workUnitPaths.validation`

커밋 순서:

1. `feat|fix|refactor|test|perf(scope): summary` 형식의 기능/테스트 커밋
2. `docs(exec-plans): complete <plan-id>` 또는 `docs(validation): record <topic>` 형식의 문서 커밋

`scripts/recommend-version-control.ps1 -VerificationStatus Passed`가 `Commit: auto_split_recommended`를 출력하면 `scripts/commit-work-unit.ps1`로 분리 커밋할 수 있습니다.
코드 변경의 목적을 확정할 수 없으면 메시지를 추측하지 않고 커밋을 중단합니다.

검증 상태별 기준:

- `Passed`: 기능/테스트 커밋과 문서 커밋 모두 허용
- `Partial`: 기능/테스트 커밋 금지, 실행 계획 또는 validation 기록만 허용
- `Failed`: 자동 커밋과 자동 push 모두 금지

## Auto Push Policy

자동 push는 topic branch에서만 허용합니다.
`main`, `master`, protected branch에서는 자동 push하지 않습니다.

자동 push 조건:

- `.harness/config.json`의 `versionControl.autoPushBranches`에 맞는 branch
- upstream이 있음
- upstream보다 behind 상태가 아님
- working tree가 clean
- 검증 상태가 `Passed`
- 마지막 push 이후 `feat|fix|refactor|test|perf` 커밋이 `versionControl.autoPushAfterFeatureCommits`개 이상

docs-only 커밋은 기능 커밋 카운트에 포함하지 않습니다.
사용자가 push를 명시적으로 요청한 경우에도 protected branch와 실패한 검증은 우선 차단합니다.
PR 생성은 자동화하지 않고 사용자가 요청할 때만 진행합니다.
