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
7. CodeHealth 결과를 errors, warnings, intentionally accepted warnings로 나눠 정리해줘.
8. 같은 파일 반복 수정, 같은 실패 반복, 같은 접근 재시도가 있었는지 확인해줘.
9. 반복 루프 신호가 있었다면 기존 접근을 고집하지 말고 원인 가설과 다음 접근을 다시 세워줘.
10. run log에 남길 가치가 있는 실패, 결정, 검증 결과가 있는지 판단해줘.

완료 조건:
- 검증 없이 "완료"라고 말하지 마.
- 실패를 숨기거나 성공처럼 요약하지 마.
- 원래 요청이 아니라 내가 작성한 코드 기준으로만 판단하지 마.
- 미검증 영역이 남아 있으면 남은 리스크로 명시해줘.

출력:
- Requirement Check
- Changed Files
- Verification
- Result Access
- Verification Surface
- CodeHealth
  - errors
  - warnings
  - intentionally accepted warnings
- Loop Signals
- Run Log Decision
- Remaining Risks
```
