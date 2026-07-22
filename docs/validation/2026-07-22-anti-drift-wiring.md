# Validation: anti drift wiring

Base commit: `a0cb3bd`

## Scope

tradepilot 감사(docs/analysis/2026-07-22-harness-compliance-audit.md, tradepilot 저장소)에서 관측된 사고 유형 5종의
재발 방지 배선 — 위생 검사 모듈(hygiene.ps1) 5종, 예외 장부(exceptions.json, 만료일 의무), Stop 훅 격상 알림.

## Commands / Scenarios

깨끗한 현장(하네스 템플릿 자체):

- `validate-harness.ps1 -Mode Template` → `errors=0; warnings=0`
- `validate-harness.ps1 -Maintenance` → hygiene 5종 전부 success
  (working-tree modified=8/untracked=1, branch-backup unpushed=0, scratch=0, exceptions=0, plan-coverage feature=4/plan=3)
- `run-prompt-contract-tests.ps1` → `checks=23; failures=0`
- `run-validator-fixtures.ps1`, `run-version-control-fixtures.ps1` → 전체 passed

사고 현장 재현(스크래치 픽스처 — tradepilot 사고 유형 재현):

- 미추적 35개 → `hygiene-untracked-backlog` warning 발화
- 추적 수정 6개(임계 5로 낮춘 설정) → `hygiene-uncommitted-backlog` warning 발화
- upstream 없는 브랜치 + 커밋 6개 → `hygiene-branch-backup` warning 발화
- `_tmp_*` 파일 12개 → `hygiene-scratch-sprawl` warning 발화
- 만료일 지난 예외 장부 항목 → `hygiene-expired-exception` warning 발화
- feat 커밋 6개 + exec-plan 변경 0 → `hygiene-plan-coverage` warning 발화
- Stop 훅 격상: 임계 초과 시 BACKLOG ALERT 1/3 → 2/3 → 3/3 → 침묵(무한 차단 방지)
- 예외 장부 왕복: `-AcceptUiConformance` 커밋 → `exception_recorded`(만료 2026-08-21) → 장부가 해당 기능 커밋에 동승
  (`.harness/exceptions.json` + 코드 파일이 한 커밋) → 트리 클린

## Results (Expected / Observed)

- Expected: 깨끗한 현장 오탐 0, 사고 현장 5종 전부 검출, 훅 격상은 3회 상한. Observed: 전부 일치.
- 발견·수정 버그 1건: `.harness` 폴더가 없는 저장소에서 장부 기록이 DirectoryNotFound로 실패 → 폴더 자동 생성으로 수정 후 재검증.

## Not Verified (+reason)

- Claude Code 실세션에서의 격상 알림 발화(다음 세션 훅 승인 후 확인 — stdin 시뮬레이션으로 대체)

## Verdict

Pass — 사고 유형 5종 모두 기계 감지·차단 배선 완료.
