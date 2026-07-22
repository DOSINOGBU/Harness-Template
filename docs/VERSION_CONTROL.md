# Version Control

커밋은 나중에 원인을 추적하고 되돌릴 수 있는 작업 단위입니다.
작은 커밋보다 중요한 것은 하나의 목적과 검증 가능한 상태입니다.

관련 문서: [`docs/PULL_REQUESTS.md`](PULL_REQUESTS.md), [커밋 체크리스트](../.harness/checklists/commit.md).

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

- 단일 API 엔드포인트 버그 수정
- 한 화면의 레이아웃·스타일만 조정
- 스케줄 파서 로직 추가
- `docs/TESTING.md`에 테스트 명령만 보강

나쁜 커밋 단위:

- UI, DB, 상태 관리, 사용자 문구를 한 번에 포함
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

## Configuration (`.harness/config.json`)

아래 키는 저장소마다 조정할 수 있습니다. 기본값은 `scripts/harness-version-control/shared.ps1`과 동기화되어 있습니다.

| 영역 | 키 | 설명 |
|---|---|---|
| 자동 커밋 | `versionControl.autoCommitWorkUnit` | `false`이면 `Commit: hold`, 이유 `auto_commit_disabled`로 자동 커밋 추천이 나오지 않습니다. |
| 작업 단위 경로 | `versionControl.workUnitPaths.*` | 코드·테스트·완료된 exec-plan·validation 문서 glob (표준 분리 대상). |
| 차단 경로 | `versionControl.blockedPathPatterns` | 키·원시 데이터 등이 스테이징되면 추천이 `hold`(`blocked_path`)입니다. |
| 대용량 | `versionControl.largeFileBytes`, `largeOriginalDataPatterns` | `largeOriginalDataPatterns`에 해당하는 파일이 `largeFileBytes` 이상이면 차단(`large_original_data`)됩니다. |
| Push·브랜치 | `versionControl.autoPushBranches`, `protectedBranches`, `autoPushAfterFeatureCommits` | 자동 push 허용 브랜치, 보호 브랜치, push 전 필요한 기능 커밋 수. |
| 기능 커밋 판별 | `versionControl.featureCommitTypes` | 자동 push 시 “기능 커밋”으로 세는 커밋 메시지 타입 접두사입니다. |

## Scripts

### `recommend-version-control.ps1`

- `-VerificationStatus`: `Passed` / `Partial` / `Failed` / `Unknown` — 추천과 push 판단에 사용합니다.
- `-NoAutoCommit`: 사용자가 자동 커밋을 끈 것으로 간주하고 `Commit: hold`(`user_disabled_auto_commit`)를 냅니다.
- `-PushRequested`: push가 명시적으로 요청된 경우 push 권장 여부에 반영합니다.
- `-AutoPush`: 권장이 나오면 즉시 `git push`를 시도합니다(그 외 조건은 Auto Push Policy와 동일).

### `commit-work-unit.ps1`

- 메시지는 `-Type`, `-Scope`, `-Summary` 조합 또는 기능 커밋만 `-CodeMessage`로 지정할 수 있습니다. 문서 커밋은 `-DocsMessage`로 덮어쓸 수 있습니다.
- `-DryRun`을 주면 `git add`/`git commit`을 하지 않고, 만들 커밋 수와 경로만 로그합니다.
- 다음이면 스크립트가 중단됩니다: 차단 경로 포함, 표준 작업 단위에 속하지 않는 변경(`Other`)이 섞임, 기능·work unit 문서와 **그 밖의** 문서 변경이 동시에 있음, `VerificationStatus=Failed`, 기능/테스트 변경인데 검증이 `Passed`가 아님, `VerificationStatus=Partial`인데 exec-plan/validation이 아닌 문서(`DocsOther`)만 변경됨, 작업 단위 커밋 후에도 스테이징된 변경이 남음(`-DryRun`이 아닐 때).

## Direct Work Unit Commit

exec-plan 없이 구두로 처리한 작은 수정도 변경 목적이 하나이고 검증이 통과하면 자동 커밋 대상입니다.
자동 커밋은 자동 push와 다르며, push는 Auto Push Policy를 따릅니다.

추천 결과별 처리:

- `Commit: no_changes`: 작업 트리가 비어 있으면 커밋할 것이 없습니다.
- `Commit: auto_recommended`: `scripts/commit-work-unit.ps1 -VerificationStatus Passed -Type <type> -Scope <scope> -Summary "<summary>"`로 단일 기능/테스트 커밋을 만듭니다(또는 `-CodeMessage`로 한 줄 메시지).
- `Commit: auto_split_recommended`: 기능/테스트 커밋과 exec-plan/validation 문서 커밋을 분리합니다.
- `Commit: docs_recommended`: docs-only 커밋을 만듭니다. 기본 메시지는 `docs: refine project documentation`이고, 더 구체적인 메시지가 있으면 `-DocsMessage`로 넘깁니다.
- `Commit: hold`: 자동 커밋하지 않고 `CommitReason`(예: `unrelated_changes_present`, `mixed_work_unit_and_other_docs`, `partial_verification_blocks_other_docs`, `blocked_path`, `auto_commit_disabled`)을 완료 보고에 남깁니다.

구두 수정이라도 여러 목적이 섞였거나 code/test 변경과 일반 문서 변경이 함께 있으면 자동 커밋하지 않습니다.
사용자가 "커밋하지 마", "수정만 해", "커밋은 내가 할게"라고 명시하면 추천 결과와 무관하게 자동 커밋하지 않습니다.

검증 상태별 기준:

- `Passed`: 기능/테스트 커밋과 문서 커밋 모두 허용(자동 push 조건도 충족할 수 있음)
- `Partial`: 기능/테스트 커밋 금지, 실행 계획 또는 validation 기록만 허용(일반 문서·`.editorconfig` 등 `DocsOther`만 바뀐 경우 `recommend-version-control.ps1`은 `Commit: hold`, `CommitReason: partial_verification_blocks_other_docs`이고 `commit-work-unit.ps1`도 중단합니다)
- `Failed`: 자동 커밋과 자동 push 모두 금지
- `Unknown`: 기능/테스트 변경이 있으면 `Passed`와 같이 자동 커밋·자동 push에 쓰이지 않습니다. 문서-only 변경만 있을 때는 `commit-work-unit.ps1`이 문서 커밋을 수행할 수 있지만, 운영상 검증 결과를 확정한 뒤 `Passed`를 쓰는 것을 권장합니다.

자동 push는 검증이 `Passed`일 때만 고려됩니다. `Partial`, `Failed`, `Unknown`은 push 권장에서 제외됩니다.

## Auto Push Policy

자동 push는 topic branch에서만 허용합니다.
보호 브랜치는 `versionControl.protectedBranches`(기본 `main`, `master`)에 맞으면 자동 push하지 않습니다.

자동 push 조건:

- `.harness/config.json`의 `versionControl.autoPushBranches`에 맞는 branch
- upstream이 있음
- upstream보다 behind 상태가 아님
- working tree가 clean
- 검증 상태가 `Passed`
- 마지막 push 이후 `versionControl.featureCommitTypes`에 해당하는 커밋 제목(예: 기본값 `feat|fix|refactor|test|perf`)이 `versionControl.autoPushAfterFeatureCommits`개 이상

docs-only 커밋은 기능 커밋 카운트에 포함하지 않습니다.
사용자가 push를 명시적으로 요청한 경우에도 protected branch와 실패한 검증은 우선 차단합니다.
PR 생성은 자동화하지 않고 사용자가 요청할 때만 진행합니다. PR 작성·리뷰 흐름은 [`docs/PULL_REQUESTS.md`](PULL_REQUESTS.md)를 따릅니다.
