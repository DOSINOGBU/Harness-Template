# Validation: incubator lifecycle

Base commit: `2a9c92e`

## Scope

인큐베이터-승격 체계(범용) 구현 + 보고 규칙 결함 2건 수정(유형 조항·EVIDENCE 허용값).

## Commands / Scenarios

- e2e: 스캐폴드 생성 -> 게이트 사유 5개로 정확 거부 -> 보완 -> 통과 -> modules/로 승격 -> 카탈로그 행 추가(실측)
- 격리 감지: 심어둔 위반(../../src 참조) 검출, 오탐 1건(계약 시험 파일) 발견 즉시 제외 처리
- validate-harness Template: errors=0; warnings=0 / 계약 시험 44/44 / 픽스처 2종 전부 통과
- 사고 기록: 시험 청소 중 'git checkout -- .'로 미커밋 수정 전량 유실 -> 전량 재적용 후 재검증(계약 44로 복원 확인).
  같은 턴에서 PreToolUse 커밋 감시원이 실전 첫 발화(수동 커밋 차단) -> 공식 우회 절차로 진행

## Results (Expected / Observed)

- Expected: 게이트가 조건 미달을 정확 거부하고 통과 시 승격 자동화. Observed: 일치.

## Not Verified (+reason)

- 실제 프로젝트 규모의 인큐베이터 운영(첫 실전 소규모 프로젝트에서 확인 예정)

## Verdict

Pass - 체계 구현 완료, 사고 2건(유실/오탐) 정직 기록 및 해소.
