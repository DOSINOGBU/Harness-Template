# Backend Guide

백엔드가 있는 프로젝트에서 서버 작업의 기준을 기록합니다.

## API Principles

- 입력은 경계에서 검증합니다.
- 비즈니스 로직은 라우터나 컨트롤러에 직접 넣지 않습니다.
- 외부 시스템 실패는 명확한 에러와 로그로 남깁니다.
- 응답 형식은 일관되게 유지합니다.
- 서비스와 유스케이스는 검증된 입력을 받고, 실패 지점을 호출자가 추적할 수 있게 합니다.

## Data Flow

```text
Request
→ Input Validation
→ Service / Use Case
→ Repository / External Client
→ Response Mapping
```

## Error Policy

| 오류 유형 | 처리 |
|---|---|
| Validation | 사용자 수정 가능한 메시지 반환 |
| Auth / Permission | 권한 부족을 명확히 반환 |
| Not Found | 대상 식별자를 로그에 포함 |
| Unexpected | 원본 에러와 요청 맥락을 로그에 포함 |

외부 클라이언트와 저장소 계층에서 발생한 오류는 호출 단계, 대상 식별자, 재시도 여부를 함께 전달합니다.
