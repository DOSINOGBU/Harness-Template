# Prompt: Quick Task

exec-plan 없이 채팅에서 바로 처리하는 즉석 수정의 표준 절차입니다.
경량 경로는 "규칙 면제"가 아니라 "축소된 규칙"입니다 — 분류, 최소 검증, 자동 커밋, 축약 보고는 생략하지 않습니다.

```text
이 요청을 즉석 수정(quick task)으로 처리해줘.

1단계 — 분류 (요청을 아래 넷 중 하나로 분류하고 한 줄로 선언해줘):
- READ-ONLY: 조사·설명·분석만. 파일을 수정하지 않고 결과만 보고해줘.
- LIGHT: 오탈자, 문구, 스타일 미세 조정, 단일 파일의 국소 수정처럼 동작 리스크가 낮은 변경.
- HEAVY: 아래 트리거 중 하나라도 해당하면 즉석 수정하지 말고 `.harness/prompts/plan-task.md`로 전환해 exec-plan부터 만들어줘.
  - 보안·권한·인증, 데이터 스키마·마이그레이션, 동시성·비동기 흐름, 새 모듈·새 의존성,
    공용 인터페이스(API·shared component·state) 변경, 기능 동작·사용자 흐름 변경
- GIT-OP: 커밋·브랜치·push 등 git 작업만. `docs/VERSION_CONTROL.md` 절차만 수행해줘.

2단계 — 실행 (LIGHT만 해당):
- 한 줄 계획(무엇을, 어디를, 어떻게 확인할지)을 먼저 적어줘.
- UI·스타일 파일을 건드리면 수정 전에 `docs/UI_RULES.md` §1 강제 규칙을 확인해줘.
- 최소 범위로 수정해줘. 주변 정리·리팩터링을 섞지 마.

3단계 — 검증 (LIGHT도 증거 1개는 필수):
- 테스트 실행, 빌드, 또는 수동 확인 중 하나를 실제로 실행하고 결과를 기록해줘.
- 검증을 실행할 수 없으면 이유와 대체 확인 방법을 남겨줘.

4단계 — 자동 커밋 (생략 금지):
- `scripts/recommend-version-control.ps1 -VerificationStatus <Passed|Partial|Failed>`를 실행해줘.
- `Commit: auto_recommended`이면 `scripts/commit-work-unit.ps1`로 즉시 커밋해줘 (direct work unit).
- `hold`이면 CommitReason을 보고에 남겨줘. 사용자가 "커밋하지 마"라고 했으면 커밋하지 마.
- 수정이 실제로 기능 동작을 바꿨다면(사후 발견 포함) 커밋 전에 짧은 사후 exec-plan을
  `docs/exec-plans/`에 남기고 HEAVY로 재분류된 이유를 적어줘.

5단계 — 축약 보고:
- 요청 확인 / 변경 사항 / 검증 / 커밋 결과 네 줄로 보고해줘.
- 시각화 위젯 도구를 쓸 수 있으면 결과 요약을 비쥬얼라이즈 위젯으로 함께 보고해줘(AGENTS.md Completion Standard).

요청:
TODO
```
