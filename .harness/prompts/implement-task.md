# Prompt: Implement Task

```text
아래 계획에 따라 구현해줘.

규칙:
- 디버깅 가능성을 짧은 코드보다 우선해줘.
- 기존 구조를 유지해줘.
- 관련 없는 리팩터링은 하지 마.
- 실패를 조용히 무시하지 마.
- 함수는 작은 책임으로 나누고 입력과 출력이 드러나게 해줘.
- 중요한 입력은 일찍 검증해줘.
- 필요한 로그와 에러 맥락을 남겨줘.
- 긴 API 작업이나 자동 파이프라인은 계획에 적힌 checkpoint, resume, time budget, candidate limit를 지켜줘.
- 기능 추가 또는 기능 동작 변경이라면 코드 변경 전에 관련 active exec-plan이 있는지 확인해줘.
- 관련 active exec-plan이 없거나 현재 plan의 `Scope`에 없는 새 기능이면 바로 구현하지 말고 `docs/exec-plans/README.md`의 Plan Creation 규칙에 따라 plan을 먼저 만들거나 갱신해줘.
- plan 없이 구현해도 되는 경우는 단순 오탈자, 문구 수정, 이미 plan의 `Steps`에 명시된 구현 세부사항으로 제한해줘.
- 구현 전에 계획의 `Depends On`, `Blocks`, `Parallel Work`를 먼저 확인해줘.
- 선행 plan의 데이터 구조, API, 계약이 미완료이면 `Independent scope`만 구현해줘.
- `Independent scope`가 없으면 코드 변경 없이 `Blocked`로 보고해줘.
- 일부만 구현했다면 `Partial`로 보고하고 완료 범위, 보류 범위, 보류 이유, 재개 조건을 적어줘.
- 계약 없이 가능한 mock UI나 shell 작업은 계획의 `Independent scope`에 명시된 경우에만 진행해줘.
- 기능 동작, UI 흐름, API/data, 권한/네비게이션이 바뀌었다면 구현 후 테스트 전에 `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract`를 최신화해줘.
- 전체 PRD 기능 테스트는 `Contract status=Current`인 기능만 기준으로 실행하고, 수정된 기능이 `Needs update`이면 완료로 보고하지 마.
- 구현 후 변경 대상 기능뿐 아니라 `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract` 기준으로 영향받은 기존 기능의 대표 시나리오도 검증해줘.
- 자동 테스트가 없으면 `docs/TESTING.md`의 `Manual Scenario Template`으로 기존 기능 Expected/Observed를 기록해줘.
- 구현 후 관련 검증을 실행하고 결과를 요약해줘.

계획:
TODO
```
