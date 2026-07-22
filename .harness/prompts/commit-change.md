# Prompt: Commit Change

```text
현재 변경을 커밋해줘.

절차:
1. 변경 파일을 확인하고 한 커밋으로 묶어도 되는지 판단해줘.
2. 여러 목적이 섞여 있으면 커밋하지 말고 분리 기준을 제안해줘.
3. `docs/VERSION_CONTROL.md`와 `.harness/checklists/commit.md`를 기준으로 커밋 전 확인을 해줘.
4. 필요한 검증이 부족하면 커밋하지 말고 부족한 검증을 보고해줘.
5. `scripts/recommend-version-control.ps1 -VerificationStatus <Passed|Partial|Failed>`를 실행해 `Commit` 판단을 확인해줘.
6. `Commit: auto_recommended`이면 단일 기능/테스트 커밋을 만들고, `auto_split_recommended`이면 기능/테스트와 exec-plan/validation 문서 커밋을 분리해줘.
7. `Commit: docs_recommended`이면 docs-only 커밋을 만들고, `hold`이면 커밋하지 말고 `CommitReason`을 보고해줘.
8. 문제가 없으면 `type(scope): summary` 형식 또는 추천된 docs 메시지로 커밋 메시지를 작성해줘.

규칙:
- 실행 불가능한 상태에서는 커밋하지 마.
- 테스트 실패, 빌드 실패, 타입 에러가 있으면 커밋하지 마.
- 자동 포맷 변경과 기능 변경이 섞여 있으면 커밋하지 마.
- exec-plan 없이 구두로 처리한 direct work unit도 검증 통과 후 자동 커밋 대상으로 판단해줘.
- 사용자가 "커밋하지 마", "수정만 해", "커밋은 내가 할게"라고 했다면 자동 커밋하지 마.
- `.env`, 토큰, API 키, 계정 정보가 포함되어 있으면 커밋하지 마.
- `update`, `fix stuff` 같은 모호한 메시지를 쓰지 마.

요청한 커밋 범위:
TODO
```
