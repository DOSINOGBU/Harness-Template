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
| 하네스 템플릿 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template` | 템플릿 원본 검증, 프로젝트별 TODO 명령은 허용 |
| 하네스 프로젝트 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Project` | 실제 프로젝트 도입 후 TODO를 실패로 처리 |
| 하네스 호환 엄격 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Strict` | 기존 명령 호환용, Project mode처럼 동작 |
| 하네스 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance` | 드리프트 감지, 기본은 warning |
| 하네스 프로젝트 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance -Mode Project` | 유지보수 finding을 실패로 처리 |
| 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth` | 큰 코드 파일 감지, 기본은 warning |
| 프로젝트 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Mode Project` | 1200줄 이상 코드 파일을 실패로 처리 |
| 테스트 명령 감지 | `powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1` | 감지 결과만 출력, 파일 변경 없음 |
| 테스트 명령 적용 | `powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1 -Apply` | 확인 후 `docs/TESTING.md` 명령 표 갱신 |
| 에이전트 컨텍스트 부트스트랩 | `powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1` | 작업 시작 전 읽기 전용 환경 요약 |
| validator 자기 테스트 | `powershell -ExecutionPolicy Bypass -File scripts/tests/run-validator-fixtures.ps1` | fixture 기반 하네스 검증 |
| 버전관리 자동화 자기 테스트 | `powershell -ExecutionPolicy Bypass -File scripts/tests/run-version-control-fixtures.ps1` | 추천, 분리 커밋, push 판단 fixture 검증 |

## Verification Policy

- 기능 변경은 관련 테스트 또는 수동 시나리오를 반드시 기록합니다.
- 버그 수정은 재현 방법과 수정 후 확인 방법을 함께 기록합니다.
- 테스트를 실행하지 못한 경우 이유와 대체 검증을 남깁니다.
- 템플릿 원본은 `-Mode Template`을 사용하고, 프로젝트별 테스트 명령 `TODO`는 허용합니다.
- 실제 프로젝트에 적용한 뒤에는 `-Mode Project`를 통과시킵니다.
- `-Strict`는 기존 사용자를 위한 호환 옵션이며 `-Mode Project`와 같은 수준으로 처리합니다.
- `init-testing-commands.ps1`는 자동 적용 전에 반드시 dry-run 출력으로 명령을 확인합니다.
- `bootstrap-agent-context.ps1`는 읽기 전용이어야 하며, 출력은 작업 시작 컨텍스트로만 사용합니다.
- 완료 전에는 `.harness/checklists/pre-completion.md`로 원래 요청과 검증 결과를 다시 비교합니다.

## CodeHealth Warning Policy

- `code-health-repeated-line` warning은 제품 코드에서는 helper 추출을 우선 검토합니다.
- 테스트 setup, fixture, table-driven case의 반복은 독립적인 실패 위치와 읽기 쉬움을 보존하는 경우 수용할 수 있습니다.
- warning을 수용할 때는 완료 보고의 `CodeHealth` 섹션에 `intentionally accepted warnings`로 남기고, 수용 이유를 한 줄로 적습니다.
- `code-health-large-file` warning은 `docs/CODE_STYLE.md`의 분리 후보 단위를 기준으로 책임 분리 필요성을 판단합니다.

## Manual Scenario Template

```text
Scenario:
1. 
2. 
3. 

Expected:

Observed:
```
