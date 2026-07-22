# Validation: naming delegation rules

Base commit: `b200518`

## Scope

buildproof 규칙 제정 2건 — ① 파일·폴더 이름 통일 규칙(docs/NAMING.md + hygiene-naming 기계 검사),
② 작업 위임 규칙(가벼운 작업=하위 에이전트 병렬 위임, 무거운 작업=메인 상위 모델 직접 — docs/WORKFLOW.md Delegation Policy).
+ tradepilot 이식 리뷰에서 나온 원본 결함 패리티 수정(quotepath·-uall·hex 확대·줄내 다중 카운트·docs 제외 확대).

## Commands / Scenarios

- validate-harness -Mode Template → errors=0; warnings=0
- validate-harness -Maintenance → hygiene-naming 첫 실전 검출 1건(.github/ISSUE_TEMPLATE 대문자 폴더)
  → GitHub 플랫폼 표준으로 판정, 허용 목록 등재 후 재실행 → success(scanned=164, legacyAllowed=2)
- run-prompt-contract-tests → checks=35; failures=0 (NAMING·Delegation 조항 등록)
- run-validator-fixtures / run-version-control-fixtures → 전체 passed
- main 병합·push: b8e531d..b200518

## Results (Expected / Observed)

- Expected: 새 규칙이 문서+기계 검사+계약 시험 3중으로 배선되고 기존 검사 무회귀. Observed: 일치.
- 레거시 이름("Harness Template Use Docs")은 규칙 문서의 예외 절차대로 config 허용 목록에 등재.

## Not Verified (+reason)

- 위임 규칙의 실효(하위 에이전트 활용률)는 기계 측정 대상이 아님 — 운영 관찰로 확인
- tradepilot에는 이번 2규칙 미이식(요청 범위가 buildproof 한정) — 백포트는 별도 결재

## Verdict

Pass — 규칙 2건 제정·배선 완료, 패리티 결함 5종 해소.