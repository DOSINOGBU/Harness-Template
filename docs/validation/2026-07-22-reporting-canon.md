# Validation: reporting canon

Base commit: `53894b7`

## Scope

비쥬얼라이즈 보고 체계 정본화 — docs/REPORTING.md(다섯 기둥) 신설, AGENTS/색인/reporting.json/계약 시험 배선, tradepilot 이식(엔진 가이드는 상위 우선).

## Commands / Scenarios

- 버튼 배선 실측: 사용자 진단 위젯 테스트로 data-prompt + script 바인딩 작동 확인(인라인 onclick 불발 실측)
- validate-harness -Mode Template: errors=0; warnings=0
- run-prompt-contract-tests: 최초 29건 중 1건 실패(한글 문구 인코딩) → 코드포인트 조립로 수정 → 29/29 통과
- buildproof main push: 07a1e3e(정본) + 53894b7(인코딩 수정), tradepilot 커밋 1건

## Results (Expected / Observed)

- Expected: 계약 시험 전체 통과, 정본이 진입점(AGENTS·색인·설정·훅)에 배선. Observed: 일치.
- 사고 1건 정직 기록: 계약 시험 1건 실패 상태로 커밋·push했다가 사후 발견·수정 — 커밋 전 시험 확인 원칙을 스스로 어긴 사례.

## Not Verified (+reason)

- 새 체계의 차트(Chart.js) 규칙 부분은 이번 보고에 차트가 없어 미검증

## Verdict

Pass(사후 수정 포함) — 체계 정본화 완료, 인코딩 함정 재발 방지 조치 반영.