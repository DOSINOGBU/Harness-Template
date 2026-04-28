# Prompt: Cleanup Drift

```text
하네스 유지보수 결과를 바탕으로 드리프트를 정리해줘.

절차:
1. `scripts/validate-harness.ps1 -Maintenance`를 실행하고 결과를 요약해줘.
2. 발견사항을 `safe cleanup`, `needs review`, `ignore for now`로 분류해줘.
3. 삭제나 수정 전에 정리 범위를 제안해줘.
4. 안전한 문서 인덱스 보강이나 상태 기록만 최소 변경으로 처리해줘.
5. 동작 변경 가능성이 있는 코드 삭제나 리팩터링은 하지 말고 별도 계획으로 분리해줘.
6. 정리 후 `scripts/validate-harness.ps1`를 다시 실행해줘.

규칙:
- 실제 소스 코드는 자동 삭제하지 마.
- generated 산출물과 마이그레이션은 직접 수정하지 마.
- 기능 변경, 버그 수정, 리팩터링과 유지보수 정리를 섞지 마.
- 작은 커밋/PR로 나눌 수 있게 변경 범위를 유지해줘.

대상 범위:
TODO
```
