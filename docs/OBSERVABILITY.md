# Observability

AI와 사람이 실패 원인을 빠르게 찾을 수 있도록 로그와 디버깅 신호를 정리합니다.

## Log Format

```text
[ComponentName] action status { metadata }
```

예시:

```text
[OrderService] fetch start { userId }
[OrderService] fetch success { count }
[OrderService] validation failed { reason }
```

## Log Policy

- 로그는 실패 위치나 중요한 결정을 좁히는 데 도움이 될 때 남깁니다.
- 의미 없는 로그(`here`, `test`)나 반복 루프의 과도한 로그는 남기지 않습니다.
- 식별자, 개수, 선택된 경로처럼 원인 분석에 필요한 맥락을 포함합니다.
- 비밀값, 토큰, 개인 식별 정보는 로그에 직접 남기지 않습니다.

## Required Log Points

| 상황 | 로그 |
|---|---|
| 외부 API 요청 | 시작, 성공, 실패 |
| 중요한 분기 | 선택된 경로와 이유 |
| 상태 변경 | 변경 전후의 핵심 식별자 |
| 재시도 | 시도 횟수와 실패 원인 |
| 예외 | 원본 에러와 작업 맥락 |

## Debugging Notes

자주 보는 로그 위치, 대시보드, 브라우저 확인 방법을 여기에 기록합니다.
