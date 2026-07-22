# Validation: ui plan five star hardening

Base commit: `57fea8b`

## Scope

UI 규칙·계획 관리 5점 마감 공사 — 커밋 시점 UI 위반 차단 게이트, 전후 사진 비교 의무화 규칙,
진행 감지형 플랜 자동 재개(설정 노출), 공정표 체크박스 공식화, 초안 방치 감시.
tradepilot의 옛 위반 청소(279곳·미배선 12개)는 하네스 규칙이 아닌 프로젝트 작업으로 분리(별점 산정 제외).

## Commands / Scenarios

- `scripts/validate-harness.ps1 -Mode Template` → `errors=0; warnings=0`
- `scripts/validate-harness.ps1 -Maintenance -CodeHealth` → `errors=0`, `maintenance-stale-draft-plan success` 포함
  (warnings 17 = 템플릿 기존 placeholder 13 + 검증·커밋 스크립트 3파일 500줄 초과 — 의도적 수용)
- `scripts/tests/run-prompt-contract-tests.ps1` → `checks=23; failures=0`
- `scripts/tests/run-validator-fixtures.ps1`, `run-version-control-fixtures.ps1` → 전체 passed
- UI 커밋 게이트 수동 시나리오(스크래치 저장소): 새 위반 추가 커밋 → 차단(0→1) /
  `-AcceptUiConformance` → 예외 기록 후 커밋 / 옛 위반 파일의 무해한 수정 → 통과 / 위반 1→2 추가 → 차단
- 진행 감지 재개 시나리오(Stop 훅 stdin 시뮬레이션): 미완료 2개 → 독촉 1/20 → 무진행 → 독촉 2/20(stall 1/2) →
  무진행 → 침묵(정체 판정) → 진행(2→1) → 독촉 재개 3/20 → 전부 완료 → 침묵·상태 초기화
- prompt-quicktask 훅: 초안 존재 시 미승인 초안 경고 문구 포함 확인

## Results (Expected / Observed)

- Expected: 새 UI 위반만 차단하고 기존 위반 파일 수정은 허용. Observed: 일치(0→1 차단, 1→1 통과, 1→2 차단).
- Expected: 진행 중에는 재개 지속, 정체 2회면 중단, 진행 재개 시 다시 독촉. Observed: 일치.
- Expected: 전체 검증·계약·픽스처 0 실패. Observed: 일치.

## Not Verified (+reason)

- Claude Code 실세션 훅 발화(다음 세션 승인 후 확인 가능 — stdin 시뮬레이션으로 대체)
- tradepilot 실화면 기준 사진 촬영·279곳 청소(별도 프로젝트 작업으로 분리, 사용자 지시 대기)

## Verdict

Pass — 하네스 규칙 범위의 UI·계획 관리 5점 항목 전부 구현·검증됨.
