# Validation: report style upgrade

Base commit: `ca9478b`

## Scope

보고 위젯 실행 버튼 의무화(sendPrompt, 라벨 끝 ↗) + reporting.json `styleGuide` 슬롯 신설.
tradepilot은 `analysis/references/analysis-engines/엔진-비주얼라이즈-가이드.md`를 표준 스타일로 지정(커밋 e58d6cd).

## Commands / Scenarios

- `validate-harness.ps1 -Mode Template` → `errors=0; warnings=0`
- `run-prompt-contract-tests.ps1` → `checks=23; failures=0`
- 반영 지점 교차 확인: AGENTS.md 보고 언어 규칙 ④⑤ / pre-completion 체크리스트 / self-verify 27번 /
  CLAUDE.md(양쪽) / reporting.json(양쪽, tradepilot은 styleGuide 경로 지정) / session-rules 훅(styleGuide 주입)
- 가이드 원문 2종 정독: 엔진-비주얼라이즈-가이드.md + indicator-plugins/비주얼라이즈-가이드.md(하드 룰)
  → 골격·컴포넌트·언어 규율을 메모리에도 보존

## Results (Expected / Observed)

- Expected: 검사 0 실패, 규칙이 진입점(AGENTS·체크리스트·훅)에 배선. Observed: 일치.
- 첫 실물 적용: 이 변경의 완료 보고 자체를 가이드 골격(결과 배지→메트릭→검사표→정직 콜아웃→로드맵+버튼)으로 렌더.

## Not Verified (+reason)

- 가이드의 Chart.js 차트 규칙(§3)은 이번 보고에 차트가 없어 미검증 — 다음 수치 보고에서 첫 적용
- 실세션 버튼 클릭 동작은 사용자의 클릭으로 확인됨(에이전트가 사전 검증 불가)

## Verdict

Pass — 규칙 배선 완료, 첫 실물 보고로 즉시 적용.
