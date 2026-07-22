# Maintenance

AI 작업이 반복되면 작은 찌꺼기와 문서 드리프트가 쌓입니다.
유지보수의 목표는 코드를 마음대로 지우는 것이 아니라, 드리프트를 빨리 감지하고 안전하게 분류해 작은 정리 PR로 처리하는 것입니다.

## Cleanup Flow

```text
Detect
→ Classify
→ Propose safe cleanup
→ Open a small cleanup PR
→ Verify
```

## Drift Categories

| 범주 | 예시 | 기본 처리 |
|---|---|---|
| Stale placeholder | 오래 남은 `TODO`, 빈 템플릿 값 | 분류 후 채우거나 추적 |
| Stale plan | `docs/exec-plans/active/`에 오래 남은 계획 | 상태 확인 후 완료/보류/폐기 분류 |
| Index drift | README에 등록되지 않은 prompt/checklist | 인덱스 보강 후보 |
| Generated drift | generated 문서의 생성 시각 또는 출처 누락 | 재생성 필요로 표시 |
| Unused docs candidate | 더 이상 참조되지 않는 문서 | 삭제하지 말고 검토 필요로 기록 |
| AI code residue | 임시 로그, 남은 실험 코드, 미사용 helper 후보 | 실제 코드 삭제 전 근거와 검증 필요 |
| Monolithic file drift | 큰 파일, 여러 책임이 섞인 파일, 레이어 경계를 넘는 파일 | 자동 분리하지 말고 분리 계획과 작은 refactor PR로 처리 |

## Monolithic File Drift

큰 파일은 코드가 잘못됐다는 확정 증거가 아니라, 설계 책임이 흐려지고 있을 수 있다는 신호입니다. 파일 크기 기준을 넘으면 기능 추가를 계속하기 전에 책임, 레이어, 테스트 범위를 확인합니다.

| 기준 | 유지보수 판단 |
|---|---|
| 500 lines 이상 | 분리 후보로 기록합니다. |
| 800 lines 이상 | 새 기능 추가를 멈추고 분리 계획을 요구합니다. |
| 1200 lines 이상 | strict 검증에서 failure로 처리합니다. |

Monolithic file drift에는 큰 파일, 여러 책임이 섞인 파일, 레이어 경계를 넘는 파일이 포함됩니다. 자동 유지보수는 파일을 직접 쪼개지 않습니다. 파일 분리는 동작 변경과 섞지 않고 별도 refactor PR에서 처리합니다.

## Automatic Cleanup Policy

자동으로 보고해도 되는 기준:

- 유지보수 warning이 5개 이상 쌓였습니다.
- active plan이 14일 이상 방치되었습니다.
- generated 문서에 `Generated at: TODO`가 남아 있습니다.
- 등록되지 않은 prompt/checklist가 발견되었습니다.
- 같은 placeholder가 여러 문서에 반복됩니다.

자동 수정 후보:

- README 인덱스 누락 보강
- 명백히 빈 placeholder 문서의 상태 보고
- 오래된 active plan을 검토 필요로 표시하는 문서 작업
- maintenance tracker에 발견사항 기록

자동 수정 금지:

- 실제 소스 코드 삭제
- 동작 변경이 가능한 리팩터링
- 오래된 문서 내용 삭제
- 마이그레이션 또는 generated 산출물 직접 수정
- 사용자 데이터나 설정 삭제

## Maintenance PR Rules

- 기능 변경, 버그 수정, 리팩터링 PR과 분리합니다.
- 삭제보다 먼저 발견사항을 기록합니다.
- 코드 동작이 바뀔 수 있으면 정리 PR이 아니라 별도 계획을 세웁니다.
- 정리 후 `scripts/validate-harness.ps1 -Maintenance`를 실행합니다.
