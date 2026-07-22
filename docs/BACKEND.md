# Backend Guide

백엔드가 있는 프로젝트에서 서버 작업의 기준을 기록합니다.

## Local Server and Agent Verification

- AI 에이전트가 서버 측 코드를 수정한 작업을 끝낼 때는, **수정 완료 후 개발·로컬 서버를 재시작**한 다음 API·통합·수동 시나리오로 동작을 확인합니다. 백그라운드로 이미 띄운 프로세스가 있으면 같은 방식으로 재시작합니다.
- 재시작 명령·포트·환경변수는 `docs/TESTING.md`의 Commands 표에 맞춥니다. 이 저장소 템플릿만 쓰는 경우 표가 `TODO`이면, 실제 프로젝트에 맞게 표를 채운 뒤 그 명령을 기준으로 합니다.

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
