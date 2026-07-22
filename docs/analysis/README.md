# Analysis

분석·조사·비교·실험 보고서를 모으는 폴더입니다. 위치·네이밍 규칙은 [`docs/ARTIFACTS.md`](../ARTIFACTS.md)를 따릅니다.

## Naming

- 단발 분석: `YYYY-MM-DD-topic.md` (예: `2026-07-22-harness-comparison.md`)
- 연속 실험·시리즈(v2, ROUND2 등으로 이어지는 작업): `<series-name>/YYYY-MM-DD-detail.md`
  (예: `load-benchmarks/2026-07-20-run-03-overfit.md`)
- 파일명은 소문자 kebab-case, 날짜는 항상 맨 앞.

## Rules

- 분석 문서를 저장소 루트나 `docs/` 루트에 만들지 않습니다.
- 같은 주제를 새 이름으로 다시 분석하지 않고, 기존 파일을 갱신하거나 시리즈 폴더에 잇습니다.
- 결론이 상설 규칙이 되면 해당 규칙 문서(`docs/*.md`)에 반영하고, 분석 문서에는 반영 위치를 남깁니다.
