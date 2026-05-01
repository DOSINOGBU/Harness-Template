# Model Harness Notes

모델마다 잘 따르는 지시와 약한 지점이 다를 수 있으므로, 하네스 운영 중 발견한 차이를 기록합니다.
이 문서는 모델 우열을 정하는 곳이 아니라 같은 작업을 더 안정적으로 반복하기 위한 운영 노트입니다.

## Source Notes

- Link: https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering
- Summary: LangChain은 deep agent 성능을 높이기 위해 system prompt, tools, middleware, trace analysis, self-verification, context injection, loop detection, reasoning budget 조절을 반복 실험했습니다.
- Project Impact: 이 템플릿은 우선 로컬 문서, 프롬프트, 스크립트로 같은 원칙을 가볍게 적용합니다.

## Common Baseline

- 작업 시작 전 context bootstrap 출력과 필수 문서를 확인합니다.
- 구현 후 pre-completion self-verify를 거칩니다.
- 같은 실패가 반복되면 더 오래 밀어붙이지 않고 원인 가설과 접근을 다시 세웁니다.
- 검증 결과와 미검증 영역을 완료 보고에 남깁니다.

## Codex Notes

- 코드베이스 탐색, 작은 수정, 검증 루프를 명시하면 안정적으로 따르는 편입니다.
- 파일 소유권, 관련 없는 변경 금지, 검증 명령을 구체적으로 주면 변경 범위가 줄어듭니다.
- 긴 작업은 실행 계획과 run log로 나누면 컨텍스트 드리프트를 줄일 수 있습니다.

## Claude Notes

- 긴 요구사항과 제품 판단을 잘 요약할 수 있으므로 intent, non-goal, tradeoff를 먼저 정리하게 합니다.
- 구현 단계에서는 검증 명령과 변경 범위를 더 명시적으로 제한합니다.
- 성공 기준을 모호하게 두면 설명은 좋아도 완료 조건이 느슨해질 수 있습니다.

## Gemini Notes

- 큰 컨텍스트를 다룰 때 관련 파일과 제외 파일을 명확히 구분해 줍니다.
- 출력 형식과 검증 기준을 고정하면 결과 비교가 쉬워집니다.
- 탐색 결과를 구현 전에 짧게 요약하게 하면 불필요한 변경을 줄일 수 있습니다.

## Update Rule

같은 모델에서 같은 실패가 두 번 반복되면 이 문서에 모델별 노트를 추가합니다.
세 번 반복되면 `.harness/checklists/` 또는 `.harness/prompts/`로 승격합니다.
