# Reliability

실패를 예측 가능하게 만들고, 실패했을 때 빠르게 복구하기 위한 원칙입니다.

## Failure Handling

- 예상 가능한 실패는 사용자에게 이해 가능한 메시지로 반환합니다.
- 예상하지 못한 실패는 원본 에러와 맥락을 함께 기록합니다.
- 외부 API, 네트워크, 파일 시스템 작업은 실패 가능성을 전제로 처리합니다.
- 실패를 잡았다면 처리하거나, 더 많은 맥락을 붙여 다시 던집니다.
- 입력 검증 실패와 시스템 실패를 같은 방식으로 다루지 않습니다.

## Validation

- 중요한 입력은 경계에서 빠르게 검증합니다.
- 검증 실패 메시지는 사용자가 고칠 수 있는 값을 알려줍니다.
- 내부 로직은 검증된 입력을 받는다는 전제를 코드 구조로 드러냅니다.

## Retry Rules

| 상황 | 재시도 여부 | 조건 |
|---|---|---|
| 일시적 네트워크 실패 | 가능 | 제한된 횟수와 지수 백오프 |
| 입력 검증 실패 | 불가 | 사용자가 입력을 수정해야 함 |
| 권한 실패 | 불가 | 인증/권한 상태 확인 필요 |
| 멱등하지 않은 외부 호출 | 주의 | 중복 발생 영향 확인 후 결정 |

## Timeouts

- 외부 호출에는 명시적 타임아웃을 둡니다. 기본값을 그대로 두지 않습니다.
- 타임아웃은 사용자 체감 한계보다 짧게 잡습니다.
- 한 요청 안에서 여러 외부 호출이 직렬로 일어나면 누적 시간을 기준으로 잡습니다.

## Long API / Pipeline Jobs

긴 API 작업이나 자동 파이프라인은 한 번에 끝난다는 전제로 설계하지 않습니다.

- checkpoint: 중간 산출물, 성공한 후보, 실패한 후보를 어디에 저장할지 정합니다.
- resume: 재시작 명령, 이미 처리한 항목을 건너뛰는 기준, 중복 실행 영향을 정합니다.
- time budget: 호출당 timeout과 전체 실행 budget을 분리해서 정합니다.
- candidate limit: 한 번에 처리할 최대 후보 수를 정하고 무제한 실행을 피합니다.
- acceptance mode: `all candidates completed`인지 `minimum valid candidates secured`인지 계획과 완료 보고에 명시합니다.

`minimum valid candidates secured`로 완료할 때는 필요한 valid 후보 수, 확보한 valid 후보 수, 남은 후보 수, 후속 처리 계획을 함께 남깁니다.

## Timeout Analysis

타임아웃이 발생하면 아래 항목으로 원인을 분석합니다.

```text
Timeout Analysis:
- calls attempted:
- succeeded / failed / timed out:
- per-call timeout:
- total time budget:
- elapsed time:
- checkpoint written:
- resumable from:
- acceptance mode affected:
- next action:
```

## Idempotency

- 같은 작업을 두 번 실행해도 결과가 같도록 설계합니다.
- 외부 호출 측에 멱등 키 또는 중복 검출 수단을 둡니다.
- 재시도가 부수효과를 두 번 발생시킬 수 있는 지점은 명시적으로 표기합니다.

## Recovery Notes

장애 대응에 필요한 명령, 대시보드, 로그 위치를 여기에 기록합니다.
대응 절차가 정착되면 `.harness/checklists/incident.md`에 단계로 옮깁니다.
