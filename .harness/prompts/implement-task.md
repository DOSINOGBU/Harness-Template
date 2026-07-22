# Prompt: Implement Task

```text
아래 계획에 따라 구현해줘.

규칙:
- 디버깅 가능성을 짧은 코드보다 우선해줘.
- 기존 구조를 유지해줘.
- 관련 없는 리팩터링은 하지 마.
- 실패를 조용히 무시하지 마. 검증이나 빌드가 실패했을 때 로그 마지막 한 줄만 보지 말고 원인 맥락까지 확인해줘.
- 함수는 작은 책임으로 나누고 입력과 출력이 드러나게 해줘.
- 중요한 입력은 일찍 검증해줘.
- 필요한 로그와 에러 맥락을 남겨줘.
- 자동 생성 파일은 직접 수정하지 말고, 민감정보를 코드나 문서에 넣지 마. 권한·시크릿·환경변수는 `docs/SECURITY.md`, `docs/INFRASTRUCTURE.md`를 따른다.
- 긴 API 작업이나 자동 파이프라인은 계획에 적힌 checkpoint, resume, time budget, candidate limit를 지켜줘.
- 기능 추가 또는 기능 동작 변경이라면 코드 변경 전에 관련 active exec-plan이 있는지 확인해줘.
- 관련 active exec-plan이 없거나 현재 plan의 `Scope`에 없는 새 기능이면 바로 구현하지 말고 `docs/exec-plans/README.md`의 Plan Creation 규칙에 따라 plan을 먼저 만들거나 갱신해줘.
- 사용자가 대화 중간에 기능을 덧붙인 경우에도, 짧은 계획을 사용자에게 보여 주고 궁금한 점을 물은 뒤 사용자가 확인하기 전에는 구현(코드·본문 수정)을 시작하지 마.
- plan 없이 구현해도 되는 경우는 단순 오탈자, 동작·PRD 계약·API에 영향 없는 순수 문서 수정, 이미 plan의 `Steps`에 명시된 구현 세부사항으로 제한해줘.
- 구현 전에 계획의 `Depends On`, `Blocks`, `Parallel Work`를 먼저 확인해줘.
- 선행 plan의 데이터 구조, API, 계약이 미완료이면 `Independent scope`만 구현해줘.
- `Independent scope`가 없으면 코드 변경 없이 `Blocked`로 보고해줘.
- 일부만 구현했다면 `Partial`로 보고하고 완료 범위, 보류 범위, 보류 이유, 재개 조건을 적어줘.
- 계약 없이 가능한 mock UI나 shell 작업은 계획의 `Independent scope`에 명시된 경우에만 진행해줘.
- 기능 동작, UI 흐름, API/data, 권한/네비게이션이 바뀌었다면 구현 후 테스트 전에 `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract`를 최신화해줘.
- 전체 PRD 기능 테스트는 `Contract status=Current`인 기능만 기준으로 실행하고, 수정된 기능이 `Needs update`이면 완료로 보고하지 마.
- 구현 후 변경 대상 기능뿐 아니라 `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract` 기준으로 영향받은 기존 기능의 대표 시나리오도 검증해줘.
- 자동 테스트가 없으면 `docs/TESTING.md`의 `Manual Scenario Template`으로 기존 기능 Expected/Observed를 기록해줘.
- UI·스타일 파일을 수정해야 하면 수정 전에 `docs/UI_RULES.md`를 읽고 §1 강제 규칙을 따르고, 요청 범위 밖 화면을 재스타일하지 마.
- 구현 후 관련 검증을 실행하고 결과를 요약해줘.
- 긴 작업이면 exec-plan의 top-level 항목 하나가 검증을 통과할 때마다 `scripts/recommend-version-control.ps1`을 실행해 작업 단위 중간 커밋을 만들어줘. 커밋되지 않은 변경을 세션 끝까지 쌓아 두지 마.
- 검증 결과와 변경 범위를 바탕으로 `scripts/recommend-version-control.ps1`의 `Commit` 판단을 확인하고, exec-plan 없이 처리한 direct work unit이면 자동 커밋 대상인지와 `hold` 여부를 기록해줘.

계획:
TODO
```
