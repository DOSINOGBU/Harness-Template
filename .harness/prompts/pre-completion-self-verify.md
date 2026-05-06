# Prompt: Pre-Completion Self-Verify

```text
작업을 끝내기 전에 완료 선언을 잠시 멈추고 자체 검증을 해줘.

절차:
1. 원래 요청을 한 문장으로 다시 적고, 현재 결과가 그 요청을 충족하는지 비교해줘.
2. 변경한 파일과 변경 이유를 요약해줘.
3. 실행한 검증 명령과 결과를 적어줘.
4. 실행하지 못한 검증이 있다면 이유와 대체 확인 방법을 적어줘.
5. 결과물을 사용자가 어디서 확인하는지 적어줘. CLI 산출물은 preview path, export command, UI location 중 해당 항목을 포함해줘.
6. Streamlit/CLI 등 혼합 프로젝트라면 현재 검증이 CLI 검증인지, UI 검증인지, 둘 다인지 명시해줘.
7. 기능 추가 또는 기능 동작 변경이라면 코드 변경 전에 active exec-plan을 만들거나 갱신했는지 확인해줘.
8. 작업 중 발견한 새 기능 범위를 plan 없이 바로 구현하지 않았는지 확인해줘.
9. exec-plan의 `Depends On`, `Blocks`, `Parallel Work` 기준으로 독립 완료 범위, 보류 범위, 보류 이유, 재개 조건을 확인해줘.
10. `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract` 기준으로 영향받은 기존 기능과 회귀 시나리오 검증 결과를 확인해줘.
11. 기능 동작, UI 흐름, API/data, 권한/네비게이션 변경이 `PRD Feature Contract`의 최신 기대 동작과 회귀 시나리오에 반영됐는지 확인해줘.
12. 전체 PRD 기능 테스트를 실행했다면 `Contract status=Current`인 기능만 기준으로 삼았는지 확인해줘.
13. UI, shared component/state, API, data model, navigation, auth/permission을 바꿨는데 기존 기능 회귀 검증이 없으면 완료로 선언하지 마.
14. CodeHealth 결과를 errors, warnings, intentionally accepted warnings로 나눠 정리해줘.
15. 같은 파일 반복 수정, 같은 실패 반복, 같은 접근 재시도가 있었는지 확인해줘.
16. 반복 루프 신호가 있었다면 기존 접근을 고집하지 말고 원인 가설과 다음 접근을 다시 세워줘.
17. run log에 남길 가치가 있는 실패, 결정, 검증 결과가 있는지 판단해줘.

완료 조건:
- 검증 없이 "완료"라고 말하지 마.
- 실패를 숨기거나 성공처럼 요약하지 마.
- 원래 요청이 아니라 내가 작성한 코드 기준으로만 판단하지 마.
- 기능 변경을 plan 없이 구현했다면 완료로 선언하지 말고 exec-plan을 먼저 보완해줘.
- 변경이 기존 PRD 기능 계약에 닿는데 회귀 시나리오를 확인하지 않았다면 완료로 선언하지 마.
- 수정된 기능 계약이 `Needs update`이면 전체 PRD 기능 테스트 완료로 선언하지 마.
- 미검증 영역이 남아 있으면 남은 리스크로 명시해줘.

출력은 아래 한국어 섹션명과 순서를 그대로 사용해줘:
- 요청 확인
- 변경 사항
- 검증
  - 실행한 검증
  - 실행하지 못한 검증
  - 검증 표면: CLI/UI/둘 다
  - 독립 완료 범위
  - 보류 범위
  - 보류 이유
  - 재개 조건
  - exec-plan 선행 여부
  - 기능 계약 최신화
  - 기존 PRD 기능 회귀 확인
- 결과 확인
- CodeHealth
  - errors
  - warnings
  - intentionally accepted warnings
- 리스크와 다음 판단
  - 남은 리스크 또는 미검증 영역
  - 반복 루프 신호
  - run log 필요 여부
  - 사용자 결정 사항
```
