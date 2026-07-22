# Artifact Organization

에이전트가 만드는 모든 문서 산출물(분석, 보고서, 계획, 기록)의 **고정 위치와 네이밍 규칙**입니다.
산출물이 저장소 곳곳에 흩어지면 다시 찾을 수 없고, 같은 분석을 반복하게 됩니다.

## Hard Rules

- 문서 산출물은 아래 표의 위치 **밖에 만들지 않습니다.** 저장소 루트, 임의 폴더, `docs/` 루트 바로 아래에 새 문서를 만들지 않습니다.
- `docs/` 루트에 새 상설 문서(규칙·가이드)를 추가해야 한다면, 같은 변경에서 `docs/README.md` 인덱스에 등록합니다. 미등록 문서는 `scripts/validate-harness.ps1 -Maintenance`가 warning으로 잡습니다.
- 날짜가 붙는 산출물은 파일명을 `YYYY-MM-DD-kebab-case-topic.md` 형식으로 통일합니다. 날짜는 항상 앞에 둡니다(정렬을 위해).
- 같은 주제의 반복 실험·연속 분석(v2, v3, ROUND2 …)은 루트에 파일을 늘리지 않고 **시리즈 폴더로 묶습니다**: `docs/analysis/<series-name>/YYYY-MM-DD-<detail>.md`.
- 날짜형 산출물(analysis, validation, run log)은 손으로 만들지 말고 `scripts/new-artifact.ps1 -Type <analysis|validation|run-log> -Slug <topic>`으로 생성합니다. 네이밍을 기억에 맡기지 않습니다.
- 네이밍 위반은 `scripts/validate-harness.ps1 -Maintenance`가 `maintenance-artifact-naming` warning으로 잡습니다.

## Where Things Go

| 산출물 종류 | 위치 | 네이밍 | 근거 문서 |
|---|---|---|---|
| 분석·조사·비교·실험 보고서 | `docs/analysis/` | `YYYY-MM-DD-topic.md`, 시리즈는 `<series>/` 하위 폴더 | [`docs/analysis/README.md`](analysis/README.md) |
| 실행 계획 | `docs/exec-plans/active/` → 완료 시 `completed/` | `01-topic.md`, 하위 plan `01a-topic.md` | [`docs/exec-plans/README.md`](exec-plans/README.md) |
| 검증 기록 | `docs/validation/` | `YYYY-MM-DD-topic.md` | [`docs/validation/README.md`](validation/README.md) |
| 에이전트 실행 기록(run log) | `docs/agent-runs/` | `YYYY-MM-DD-short-task.md` | [`docs/agent-runs/README.md`](agent-runs/README.md) |
| 기술 의사결정 | `docs/adr/` | `NNNN-title.md` | `docs/adr/README.md` |
| 제품 요구사항 | `docs/product-specs/` | `feature-name.md` | `docs/product-specs/index.md` |
| 설계 방향·핵심 신념 | `docs/design-docs/` | `topic.md` | `docs/design-docs/index.md` |
| 자동 생성 문서 | `docs/generated/` | 생성기가 결정 | `docs/generated/README.md` |
| 외부 자료 요약·링크 | `docs/references/` | `topic.md` | `docs/references/README.md` |

## Decision Guide

어디에 둘지 애매하면 아래 순서로 판단합니다.

1. **다음에 무엇을 할지 정하는 문서인가?** → exec-plan (`docs/exec-plans/active/`)
2. **무엇을 조사·비교·측정한 결과인가?** → 분석 (`docs/analysis/`)
3. **검증(테스트·수동 시나리오) 실행 결과 기록인가?** → `docs/validation/`
4. **작업 과정에서 있었던 일(실패·반복·판단)의 기록인가?** → run log (`docs/agent-runs/`)
5. **앞으로도 계속 유효한 규칙·기준인가?** → 기존 `docs/*.md` 상설 문서에 병합(새 파일보다 기존 문서 보강 우선)

그래도 애매하면 `docs/analysis/`에 두고 완료 보고에 위치 판단 근거를 남깁니다.

## Anti Patterns

- 저장소 루트에 `REPORT.md`, `NOTES.md`, `PLAN-v2.md` 같은 파일을 만듭니다.
- `docs/` 루트에 `PREREG-X-V21.md` … `PREREG-X-V34H.md`처럼 시리즈 파일을 평평하게 쌓습니다. (시리즈 폴더로 묶어야 합니다)
- 같은 주제의 분석을 새 이름으로 다시 만듭니다. (기존 파일을 갱신하거나 시리즈 폴더에 잇습니다)
- 날짜 없는 분석 파일명(`ui-audit-final-final.md`)을 만듭니다.
