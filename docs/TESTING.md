# Testing

변경 후 무엇을 실행해야 하는지 AI가 추측하지 않도록 기록합니다.

## Commands

| 목적 | 명령 | 비고 |
|---|---|---|
| 설치 | `TODO` | 프로젝트 스택에 맞게 작성 |
| 개발 서버 | `TODO` | 포트와 환경변수 기록 |
| 단위 테스트 | `TODO` | 관련 테스트 우선 실행 |
| 린트 | `TODO` | 자동 수정 명령과 구분 |
| 타입체크 | `TODO` | 타입 시스템이 있는 경우 |
| 빌드 | `TODO` | 배포 전 확인 |
| 하네스 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1` | 구조 확인, TODO 명령은 warning |
| 하네스 엄격 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Strict` | 실제 프로젝트 도입 후 TODO를 실패로 처리 |
| 하네스 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance` | 드리프트 감지, 기본은 warning |
| 하네스 엄격 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance -Strict` | 유지보수 finding을 실패로 처리 |
| 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth` | 큰 코드 파일 감지, 기본은 warning |
| 엄격 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Strict` | 1200줄 이상 코드 파일을 실패로 처리 |

## Verification Policy

- 기능 변경은 관련 테스트 또는 수동 시나리오를 반드시 기록합니다.
- 버그 수정은 재현 방법과 수정 후 확인 방법을 함께 기록합니다.
- 테스트를 실행하지 못한 경우 이유와 대체 검증을 남깁니다.
- 템플릿 원본은 기본 하네스 검증을 사용하고, 실제 프로젝트에 적용한 뒤에는 엄격 검증을 통과시킵니다.

## Manual Scenario Template

```text
Scenario:
1. 
2. 
3. 

Expected:

Observed:
```
