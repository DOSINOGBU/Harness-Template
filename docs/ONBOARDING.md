# Onboarding

처음 합류한 사람과 AI 에이전트가 같은 출발점에서 작업을 시작하도록 합니다.

Windows에서는 **PowerShell 7(`pwsh`)** 로 스크립트를 실행하는 것을 권장합니다(콘솔 유니코드·UTF-8 출력이 Windows PowerShell 5.1보다 안정적입니다). `pwsh`가 없으면 `powershell`과 동일한 인자로 실행합니다.

에이전트·IDE에서 저장소 파일을 열 때는 이미 UTF-8로 해석되므로, 작업 시작마다 인코딩을 길게 설명할 필요는 없습니다.

터미널에서 한글이 깨지면 `pwsh`로 같은 스크립트를 실행하거나 Windows Terminal·호스트 UTF-8 설정을 맞춥니다. 부트스트랩은 콘솔 UTF-8 출력을 요청하며, 출력 맨 앞의 ASCII 줄 `[AgentContext] io encoding { console_output=utf8 }`가 보이면 인코딩 요청은 적용된 것입니다(이후 한글만 깨지면 글꼴·호스트 문제일 수 있음).

## First Hour

1. `README.md`(루트), `ARCHITECTURE.md`, `AGENTS.md`를 읽습니다.
2. `docs/README.md`로 문서 단계(Essential/Common 등)와 다음에 읽을 파일을 고릅니다.
3. `docs/WORKFLOW.md`로 작업 수명 주기와 부트스트랩 단계를 확인합니다.
4. `docs/AGENT_BEHAVIOR.md`로 AI 에이전트와 협업할 때의 기본 기대치를 확인합니다.
5. `docs/PRODUCT_CONTEXT.md`로 제품 목적을 파악합니다.
6. `docs/PROJECT_RULES.md`로 금지·승인 사항을 확인합니다.
7. `pwsh -ExecutionPolicy Bypass -File scripts/bootstrap-agent-context.ps1`(또는 `powershell ...`)로 환경 요약을 확인합니다(`docs/WORKFLOW.md` 2단계와 동일).
8. `pwsh -ExecutionPolicy Bypass -File scripts/init-testing-commands.ps1`(또는 `powershell ...`)로 테스트 명령 후보를 감지합니다.
9. 확인된 명령으로 `docs/TESTING.md`를 채우고 환경을 확인합니다.

## Template Adoption Checklist

새 프로젝트에 이 템플릿을 붙인 뒤 첫 1시간 안에 아래만 먼저 채웁니다.
모든 문서를 한 번에 완성하려고 하지 않습니다.

- [ ] `docs/PRODUCT_CONTEXT.md`에 제품 목적과 핵심 사용자를 적었습니다.
- [ ] `ARCHITECTURE.md`에 현재 구조와 주요 흐름을 3~5문장으로 적었습니다.
- [ ] `docs/README.md`로 문서 단계와 다음에 읽을 파일을 정했습니다.
- [ ] `docs/WORKFLOW.md`와 `docs/AGENT_BEHAVIOR.md`를 읽었습니다.
- [ ] `pwsh` 또는 `powershell`로 `scripts/bootstrap-agent-context.ps1`를 실행해 환경 요약을 확인했습니다.
- [ ] `pwsh` 또는 `powershell`로 `scripts/init-testing-commands.ps1`를 실행해 명령 후보를 확인했습니다.
- [ ] `docs/TESTING.md`의 설치, 테스트, 린트, 타입체크, 빌드 명령을 프로젝트에 맞게 채웠습니다.
- [ ] `docs/PROJECT_RULES.md`의 금지·승인 사항이 현재 프로젝트에 맞는지 확인했습니다.
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template`로 하네스 구조를 확인했습니다.
- [ ] 실제 프로젝트 도입 후 `powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Project`가 통과하는지 확인했습니다.

## First Day

- `.harness/README.md`로 체크리스트·프롬프트 위치를 확인한 뒤, 작은 기능을 골라 `.harness/checklists/feature-change.md`로 한 사이클을 돕니다.
- 막힌 지점이 있으면 같은 자리를 다시 막을 사람을 위해 문서나 체크리스트에 보강합니다.
- 자주 쓰는 명령은 `docs/TESTING.md`에 보강합니다.

## First Week

| 주제 | 다음 단계 |
|---|---|
| 도메인 용어 | `docs/GLOSSARY.md` 보완 |
| 자주 보는 로그 | `docs/OBSERVABILITY.md` 보완 |
| 외부 시스템 | `docs/references/`에 요약 추가 |
| 반복 결정 | `docs/adr/`에 ADR 작성 |
| 여러 일/병행 작업이 길어짐 | `docs/exec-plans/README.md`와 `docs/exec-plans/active/` 규칙 확인 |

## How To Help The Next Agent

- 막혔던 부분은 가능한 한 한 곳에만 적습니다(중복 문서를 만들지 않습니다).
- 새 규칙은 토론용 문장보다 행동 가능한 제약으로 적습니다.
- 한 번의 실수는 메모, 두 번이면 체크리스트, 세 번이면 자동화로 옮깁니다.
