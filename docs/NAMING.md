# Naming — 파일·폴더 이름 통일 규칙

저장소 안의 모든 이름이 예측 가능해야 사람과 에이전트가 위치를 추측할 수 있고, 산출물이 흩어지지 않습니다.
위치 규칙은 [`ARTIFACTS.md`](ARTIFACTS.md), 이 문서는 **이름 짓는 법**의 단일 정답지입니다.
위반은 `scripts/validate-harness.ps1 -Maintenance`의 위생 검사(`hygiene-naming`)가 warning으로 잡습니다.

## 통일 표

| 대상 | 규칙 | 예 |
|---|---|---|
| 폴더 | 소문자 kebab-case 영문, 공백 금지 | `docs/exec-plans`, `harness-validation` |
| 스크립트·소스 파일 | 소문자 kebab-case + 확장자 | `commit-work-unit.ps1`, `new-artifact.ps1` |
| 상설 규칙 문서(docs 루트) | 대문자 UPPER_SNAKE.md | `UI_RULES.md`, `VERSION_CONTROL.md` |
| 루트 고정 문서 | 관례명 고정 | `README.md`, `AGENTS.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md` |
| 날짜형 산출물(분석·검증·기록) | `YYYY-MM-DD-kebab-topic.md` — 날짜 맨 앞 | `2026-07-22-harness-comparison.md` |
| 실행 계획 | `NN[a]-kebab-topic.md` | `01-auth.md`, `01a-auth-session.md` |
| 시리즈(반복 실험) | 시리즈 폴더 + 날짜형 파일 | `analysis/load-benchmarks/2026-07-20-run-03.md` |
| 설정 파일·표준 폴더 | 생태계 표준명 그대로(예외 허용) | `config.json`, `.gitignore`, `.github/ISSUE_TEMPLATE` |

## 금지

- **공백 든 이름** — 경로 인용 사고와 도구 오작동의 단골 원인입니다.
- **대문자 폴더명** — 폴더는 항상 소문자 kebab-case.
- **버전 접미 파일명** (`-final`, `-v2`, `-새버전`, `-복사본`) — 버전은 git(형상 관리)이 담당합니다. 반복 실험은 시리즈 폴더로.
- **같은 개념의 표기 혼용** — 한 저장소에서 `ui-rules` / `uiRules` / `UI-Rules`를 섞지 않습니다. 먼저 쓰인 표기를 따릅니다.
- **무의미한 이름** (`temp.ps1`, `test2.md`, `새 폴더`) — 스크래치는 저장소 밖 작업 폴더에.

## 레거시 예외

규칙 제정 이전의 이름은 `.harness/config.json`의 `hygiene.namingLegacyAllowed`에 등재해 검사를 면제합니다(예: `Harness Template Use Docs`).
**신규 생성물은 예외를 등재할 수 없습니다** — 처음부터 규칙대로 짓습니다. 레거시 이름을 바꿀 때는 참조를 함께 갱신하고 등재를 삭제합니다.
