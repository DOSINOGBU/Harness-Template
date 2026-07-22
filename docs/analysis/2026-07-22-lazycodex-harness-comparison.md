# Analysis: lazycodex harness comparison

## Question

lazycodex(code-yeongyu, OpenAI Codex CLI용 에이전트 하네스)와 이 Harness Template을 비교해,
흡수할 가치가 있는 메커니즘과 tradepilot 운영에서 드러난 5가지 고통 지점(커밋 자동화 부재,
즉석 수정 무자동화, UI 규칙 미준수, 산출물 중구난방, 코드 헬스 붕괴)의 해법을 도출한다.

## Method

- lazycodex 저장소(README, 파일 트리, plugins/omo 훅·스킬·디렉티브, 문서 사이트) 원문 분석
- 이 하네스의 문서·체크리스트·프롬프트·검증 스크립트·CI 전수 분석
- tradepilot `docs/ui-*.md` 6종 분석 (규칙이 있었는데도 위반이 누적된 원인 규명)

## Findings

핵심 구조 차이:

| 축 | Harness Template | lazycodex |
|---|---|---|
| 강제 방식 | 문서·체크리스트 신뢰 (에이전트가 읽고 따른다고 가정) | 라이프사이클 훅 6종이 규칙을 기계적으로 재주입 |
| 완료 판정 | 산문 자기 보고 | `EVIDENCE_RECORDED: <path>` 기계 판독 계약 + git tree hash 바인딩 |
| 계획 상태 | exec-plan 문서 (판단 기반 완료) | 체크박스 상태가 곧 프로세스 상태, Stop 훅이 전부 `- [x]`까지 자동 재개 |
| 커밋 | 정교한 추천·분리 스크립트가 있으나 실행은 문서 지시뿐 | 검증된 작업 단위마다 커밋, 수치 하한(3+ 파일이면 2+ 커밋), 스타일 자동 감지 |
| UI 규칙 | 범용 원칙 27줄, 강제 장치 없음 | "No design system = no UI work", 모든 값이 토큰으로 추적, 스크린샷=계약 |
| 프롬프트 품질 | 수기 유지 | 프롬프트 자체를 CI에서 유닛 테스트 (계약 검사) |

tradepilot 실증 — UI 규칙이 있었는데도 위반 242곳이 누적된 원인:

1. AGENTS.md Required Reading에 ui-*.md 미연결 → 에이전트가 읽을 트리거 없음
2. 하드코딩 색·임의 px를 잡는 grep/lint 게이트 부재
3. "컴포넌트 존재 ≠ 배선됨"을 typecheck가 못 잡음 (미배선 컴포넌트 사건)

이식 불가 항목: 훅 런타임 자체(컴파일된 Node CLI + Codex 플러그인), 멀티에이전트
오케스트레이션(spawn_agent API), npm 배포 계층, CodeGraph/LSP MCP 서버.
단, 그 밑의 패턴(기계 판독 계약, 이벤트 배선, 게이트)은 이식 가능하다.

## Conclusion

"규칙이 없어서"가 아니라 "규칙과 강제 지점이 배선되지 않아서"가 5개 고통 지점의 공통 원인.
2026-07-22에 다음을 이식·구현했다:

1. **UI 규칙**: `docs/UI_RULES.md` 신설(tradepilot 규칙을 기본값으로, `PROJECT-CUSTOMIZE` 슬롯 구조) +
   AGENTS.md Required Reading/Hard Constraints 배선 + `validation.uiConformance` grep 게이트
   (`scripts/harness-validation/ui-conformance.ps1`) + Cursor 규칙(`.cursor/rules/ui-rules-gate.mdc`) +
   Claude Code PostToolUse 훅(`.claude/hooks/posttool-ui-rules.ps1`)
2. **커밋 자동화**: Stop 훅(`.claude/hooks/stop-commit-guard.ps1`, 세션당 1회 nudge) +
   AGENTS.md Hard Constraint("커밋 판단 없이 턴 종료 금지") + WORKFLOW 중간 커밋 트리거
3. **즉석 수정**: `.harness/prompts/quick-task.md` (READ-ONLY/LIGHT/HEAVY/GIT-OP 분류, LIGHT도 증거 1개 필수,
   자동 커밋 생략 금지) + AGENTS.md 라우팅 등록
4. **산출물 정리**: `docs/ARTIFACTS.md` 위치·네이밍 규칙 + `docs/analysis`/`docs/validation` 신설 +
   `scripts/new-artifact.ps1` 스캐폴드 + `-Maintenance` 네이밍·미등록 문서 검사
5. **코드 헬스**: CI paths 필터 제거(도입 프로젝트의 제품 코드 PR도 게이트 통과 필수)
6. **보고**: 완료 보고는 항상 비쥬얼라이즈 위젯 동반 (AGENTS.md Completion Standard)

## Follow-up

- 미이식 후보(다음 단계): EVIDENCE_RECORDED 계약, commit-work-unit atomicity 수치 하한(ceil(files/3))과
  메시지 스타일 자동 감지, code-health `-DiffOnly`(800+줄 파일 증가분 차단), 프롬프트 계약 테스트,
  draft-승인-plan 분리, PreToolUse raw `git commit` 차단 훅
- 상설 규칙 반영 위치: `docs/UI_RULES.md`, `docs/ARTIFACTS.md`, `AGENTS.md`, `docs/WORKFLOW.md`
