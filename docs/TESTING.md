# Testing

변경 후 무엇을 실행해야 하는지 AI가 추측하지 않도록 기록합니다. 이 파일의 **Commands** 표가 로컬·에이전트 검증의 기준 목록입니다.

템플릿 원본에서는 표 상단의 설치·개발 서버·단위 테스트·린트·타입체크·빌드가 `TODO`로 남아 있는 것이 정상입니다. 실제 스택에 맞게 채우거나, 감지만 하려면 `init-testing-commands.ps1`(dry-run), 확인 후 `init-testing-commands.ps1 -Apply`로 이 표를 갱신합니다.

Windows가 아니면 PowerShell Core로 동일 스크립트를 실행합니다. 예: `pwsh -File scripts/validate-harness.ps1 -Mode Template`

## Related documents

| 문서 | 용도 |
|---|---|
| [PRODUCT_CONTEXT.md](PRODUCT_CONTEXT.md) | PRD 기능 계약, 회귀 시나리오 출처 |
| [QUALITY_SCORE.md](QUALITY_SCORE.md) | 완료 품질·자체 검증 기대치 |
| [VERSION_CONTROL.md](VERSION_CONTROL.md) | 커밋 전 확인, CI와 로컬 역할 구분 |
| [../.harness/checklists/pre-completion.md](../.harness/checklists/pre-completion.md) | 완료 직전 체크리스트 |

## Commands

| 목적 | 명령 | 비고 |
|---|---|---|
| 설치 | `TODO` | 프로젝트 스택에 맞게 작성 |
| 개발 서버 | `TODO` | 포트와 환경변수 기록. 서버 측 코드를 수정한 작업은 완료·검증 전에 이 서버를 재시작—`docs/BACKEND.md` |
| 단위 테스트 | `TODO` | 관련 테스트 우선 실행 |
| 통합·E2E 테스트 | `TODO` | 스택에 맞게 작성, 없으면 비워 두고 수동 시나리오로 대체 |
| 린트 | `TODO` | 자동 수정 명령과 구분 |
| 타입체크 | `TODO` | 타입 시스템이 있는 경우 |
| 빌드 | `TODO` | 배포 전 확인 |
| 하네스 템플릿 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template` | 템플릿 원본 검증, 프로젝트별 TODO 명령은 허용 |
| 하네스 프로젝트 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Project` | 실제 프로젝트 도입 후 TODO를 실패로 처리 |
| 하네스 호환 엄격 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Strict` | 기존 명령 호환용, Project mode처럼 동작 |
| 하네스 경고를 실패로 처리 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -TreatWarningsAsErrors` | 경고가 하나라도 있으면 종료 코드 1 |
| 하네스 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance` | 드리프트 감지, 기본은 warning |
| 하네스 프로젝트 유지보수 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance -Mode Project` | 유지보수 finding을 실패로 처리 |
| 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth` | 큰 코드 파일 감지, 기본은 warning |
| 프로젝트 코드 건강도 검증 | `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Mode Project` | 1200줄 이상 코드 파일을 실패로 처리 |
| 테스트 명령 감지 | `powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1` | 감지 결과만 출력, 파일 변경 없음 |
| 테스트 명령 적용 | `powershell -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1 -Apply` | 확인 후 `docs/TESTING.md` 명령 표 갱신 |
| 에이전트 컨텍스트 부트스트랩 | `powershell -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1` | 작업 시작 전 읽기 전용 환경 요약. Windows에서는 동일 인자로 `pwsh` 권장(유니코드 터미널). 선두 `[AgentContext] io encoding { console_output=utf8 }`는 UTF-8 콘솔 출력 요청 표시 |
| validator 자기 테스트 | `powershell -ExecutionPolicy Bypass -File scripts/tests/run-validator-fixtures.ps1` | fixture 기반 하네스 검증 |
| 버전관리 자동화 자기 테스트 | `powershell -ExecutionPolicy Bypass -File scripts/tests/run-version-control-fixtures.ps1` | 추천, 분리 커밋, push 판단 fixture 검증 |

## Recommended run order

- **빠른 피드백(반복 작업 중)**: 프로젝트 `TODO`가 채워져 있다면 린트 → 타입체크 → 변경과 연관된 단위(또는 통합) 테스트 순으로 실행합니다.
- **공유·머지 전**: 빌드가 표에 있으면 포함하고, 하네스는 템플릿이면 `-Mode Template`, 포크 프로젝트면 `-Mode Project`로 통과시킵니다.
- **PRD·기능 계약에 닿는 변경**: 아래 `Regression Verification Policy`와 [PRODUCT_CONTEXT.md](PRODUCT_CONTEXT.md)의 계약·시나리오를 먼저 맞춘 뒤, 영향 기능 회귀를 실행합니다.

CI에서 무엇을 돌리는지는 [VERSION_CONTROL.md](VERSION_CONTROL.md)와 저장소 파이프라인 설정을 기준으로 합니다. 로컬에서는 최소한 CI가 실패할 만한 동일 축(린트·타입·테스트 등)을 맞춥니다.

## Verification Policy

- 기능 변경은 관련 테스트 또는 수동 시나리오를 반드시 기록합니다.
- 버그 수정은 재현 방법과 수정 후 확인 방법을 함께 기록합니다.
- 테스트를 실행하지 못한 경우 이유와 대체 검증을 남깁니다.
- 템플릿 원본은 `-Mode Template`을 사용하고, 프로젝트별 테스트 명령 `TODO`는 허용합니다.
- 실제 프로젝트에 적용한 뒤에는 `-Mode Project`를 통과시킵니다.
- `-Strict`는 기존 사용자를 위한 호환 옵션이며 `-Mode Project`와 같은 수준으로 처리합니다.
- `init-testing-commands.ps1`는 자동 적용 전에 반드시 dry-run 출력으로 명령을 확인합니다.
- `bootstrap-agent-context.ps1`는 읽기 전용이어야 하며, 출력은 작업 시작 컨텍스트로만 사용합니다. 에이전트는 매 세션 “UTF-8로 다시 읽겠습니다”류의 장문 선언 없이 이 출력과 `AGENTS.md`를 따릅니다.
- 완료 전에는 [.harness/checklists/pre-completion.md](../.harness/checklists/pre-completion.md)로 원래 요청과 검증 결과를 다시 비교합니다.

## Regression Verification Policy

변경 대상 기능의 테스트만 통과해도 완료로 보지 않습니다.
변경이 기존 PRD 기능 계약에 닿을 수 있으면 [PRODUCT_CONTEXT.md](PRODUCT_CONTEXT.md)의 `PRD Feature Contract`에서 영향받는 기능을 고르고 대표 시나리오를 확인합니다.

- 전체 PRD 기능 테스트는 `Contract status=Current`인 기능만 대상으로 실행합니다.
- 전체 PRD 기능 테스트 전에는 수정된 기능의 `Current expected behavior`와 `Regression scenario`가 최신인지 확인합니다.
- 수정된 기능 계약이 `Needs update`이면 전체 PRD 기능 정상 작동 테스트를 완료로 선언하지 않습니다.
- UI, shared component, shared state, API, data model, navigation, auth/permission 변경은 기존 PRD 기능 회귀 검증 대상입니다.
- 영향받는 기존 기능마다 자동 테스트 또는 수동 시나리오 중 하나를 실행합니다.
- 자동 테스트가 없으면 아래 `Manual Scenario Template`으로 Expected/Observed를 남깁니다.
- 영향받는 기능이 없다고 판단한 경우에도 그 이유를 완료 보고의 `검증` 또는 exec-plan `Validation`에 남깁니다.
- 보안·권한, 접근성, 국제화·시간대·로케일 동작을 바꾼 경우 각각 [SECURITY.md](SECURITY.md), [ACCESSIBILITY.md](ACCESSIBILITY.md), [INTERNATIONALIZATION.md](INTERNATIONALIZATION.md)에 맞는 확인을 추가합니다(해당 문서가 프로젝트에 없거나 아직 비어 있으면 완료 보고에 수동 확인 범위를 명시합니다).

## CodeHealth Warning Policy

- `code-health-repeated-line` warning은 제품 코드에서는 helper 추출을 우선 검토합니다.
- 테스트 setup, fixture, table-driven case의 반복은 독립적인 실패 위치와 읽기 쉬움을 보존하는 경우 수용할 수 있습니다.
- warning을 수용할 때는 완료 보고의 `CodeHealth` 섹션에 `intentionally accepted warnings`로 남기고, 수용 이유를 한 줄로 적습니다.
- `code-health-large-file` warning은 [CODE_STYLE.md](CODE_STYLE.md)의 분리 후보 단위를 기준으로 책임 분리 필요성을 판단합니다.

## Manual Scenario Template

```text
Scenario:
1. 
2. 
3. 

Environment:
(e.g. OS, branch, feature flags, 데이터 상태)

Browser or client:
(UI가 아니면 N/A 또는 API 클라이언트/버전)

Expected:

Observed:
```
