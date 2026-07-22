# AGENTS.md

이 파일은 AI 에이전트가 작업을 시작할 때 가장 먼저 읽는 작업 지도입니다.
자세한 규칙을 이 파일에 모두 넣지 말고, 필요한 문서를 찾아가도록 안내합니다.
이 하네스의 이름은 **buildproof**(빌드프루프 — 증거로 짓는다)입니다.

## Working Mode

- 가능하면 `scripts/bootstrap-agent-context.ps1`로 시작 컨텍스트를 받은 뒤 Required Reading 범위를 좁힙니다.
- 저장소 마크다운은 UTF-8이며, IDE·에이전트 파일 도구는 일반적으로 그대로 읽습니다. 매 세션마다 “UTF-8로 다시 읽겠습니다”, “PowerShell 출력이 깨져서…” 같은 **장문의 인코딩·터미널 선언은 하지 않습니다**; `docs/ONBOARDING.md`의 터미널 권장만 따릅니다.
- 부트스트랩 첫 줄 근처의 ASCII 로그 `[AgentContext] io encoding { console_output=utf8 }`는 스크립트가 콘솔 UTF-8 출력을 요청했음을 뜻합니다. 한글 로그가 터미널에서 깨지면 `pwsh`로 동일 스크립트를 실행하거나 출력을 UTF-8 파일로 리다이렉트해 확인합니다.
- 기존 구조를 먼저 파악한 뒤 최소 변경으로 작업합니다.
- 모호한 요구사항은 구현 전에 질문하거나 `docs/exec-plans/active/`에 가정을 명시합니다.
- 대화 중간에 사용자가 기능을 추가·확장하더라도, 먼저 짧은 계획(범위·접근·영향 파일·검증)을 사용자에게 보여 주고, 불명확한 점은 질문한 뒤, 사용자가 그 계획과 답에 대해 확인한 다음에만 코드·문서 본문 수정을 진행합니다(상세는 `docs/AGENT_BEHAVIOR.md`, `docs/WORKFLOW.md`).
- 작업 중 새 기능 범위·새 라이브러리·큰 구조 변경·삭제 작업이 보이면 바로 구현하지 말고 active exec-plan을 먼저 만들거나 갱신합니다(상세 규칙은 `docs/exec-plans/README.md`, `docs/AGENT_BEHAVIOR.md`).
- 체크리스트·프롬프트 목록은 `.harness/README.md`에서 확인합니다.
- **작업 위임**: 가벼운 읽기성 작업(탐색·조사·반복 스캔·독립 검증)은 하위 에이전트에 병렬 위임하고, 무거운 작업(설계·규칙 결정, 상호 의존 수정, 커밋·병합, 사용자 결재)은 메인 상위 모델이 메인 채팅에서 직접 수행합니다(상세: `docs/WORKFLOW.md`의 Delegation Policy).
- **이름 규칙**: 새 파일·폴더는 `docs/NAMING.md`의 통일 표를 따릅니다(공백·버전 접미·표기 혼용 금지).

## Intent Routing

- 기능 추가, 구현, 생성 요청은 Build 흐름으로 처리합니다.
- 오류, 버그, 동작 안함, 원인 분석, 수정 요청은 Debug 흐름으로 처리합니다.
- 의도가 불명확하면 Build 흐름을 기본값으로 두되, 요구사항이 두 가지 이상으로 해석되면 구현 전에 확인합니다.
- 상세한 구현 원칙은 이 파일에 반복하지 않고 `docs/WORKFLOW.md`, `docs/PROJECT_RULES.md`, `docs/CODE_STYLE.md`, `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md`를 따릅니다.

## Required Reading

작업 종류에 따라 아래 문서를 먼저 확인합니다.
동일 문서가 여러 행에 있으면, **해당 작업과 맞는 행**을 기준으로 읽습니다.


| 상황                    | 먼저 읽을 문서                                                                                                                           |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 작업 시작 절차              | `docs/WORKFLOW.md`, `scripts/bootstrap-agent-context.ps1`, `.harness/README.md`, `docs/PROJECT_RULES.md`, `docs/AGENT_BEHAVIOR.md` |
| 전체 구조 파악              | `ARCHITECTURE.md`, `docs/README.md`                                                                                                |
| 도메인 용어                | `docs/GLOSSARY.md`                                                                                                                 |
| 템플릿 도입·검증·신규 합류       | `docs/ONBOARDING.md`, `scripts/validate-harness.ps1`                                                                               |
| 실행 계획·장기 작업           | `docs/exec-plans/README.md`, `docs/exec-plans/active/`                                                                             |
| 에이전트 행동 기준            | `docs/AGENT_BEHAVIOR.md`, `.harness/checklists/pre-completion.md`                                                                  |
| 완료 품질·자체 검증 기준        | `docs/QUALITY_SCORE.md`                                                                                                            |
| 정기 유지보수/드리프트 정리       | `docs/MAINTENANCE.md`, `.harness/checklists/maintenance.md`                                                                        |
| 기능 추가                 | `docs/PRODUCT_CONTEXT.md`, `.harness/checklists/feature-change.md`                                                                 |
| 버그 수정                 | `docs/TESTING.md`, `.harness/checklists/bug-fix.md`                                                                                |
| 리팩터링                  | `ARCHITECTURE.md`, `.harness/checklists/refactor.md`                                                                               |
| UI·화면·스타일 변경           | `docs/UI_RULES.md`(필수 선행), `docs/FRONTEND.md`                                                                                    |
| 프론트엔드·백엔드 영역 변경(해당 시) | `docs/FRONTEND.md`, `docs/BACKEND.md`                                                                                              |
| 분석·보고서·기록 문서 생성        | `docs/ARTIFACTS.md`                                                                                                                |
| 새 파일·폴더 이름 짓기          | `docs/NAMING.md`                                                                                                                   |
| 결과 보고 작성(비쥬얼라이즈)      | `docs/REPORTING.md`                                                                                                                |
| exec-plan 없는 즉석 수정 요청   | `.harness/prompts/quick-task.md`                                                                                                   |
| 보안/권한·인프라/환경변수/시크릿    | `docs/INFRASTRUCTURE.md`, `docs/SECURITY.md`                                                                                       |
| 로그/에러 처리 변경           | `docs/OBSERVABILITY.md`, `docs/RELIABILITY.md`                                                                                     |
| 데이터/마이그레이션            | `docs/DATA.md`, `.harness/checklists/migration.md`                                                                                 |
| 의존성·라이선스/외부 에셋        | `docs/DEPENDENCIES.md`, `docs/LICENSING.md`, `.harness/checklists/dependency-add.md`                                               |
| 성능 작업                 | `docs/PERFORMANCE.md`                                                                                                              |
| 배포/롤백                 | `docs/DEPLOYMENT.md`, `docs/RUNBOOK.md`                                                                                            |
| 릴리스 전                 | `.harness/checklists/release.md`                                                                                                   |
| 비용 영향                 | `docs/COST.md`                                                                                                                     |
| 접근성                   | `docs/ACCESSIBILITY.md`                                                                                                            |
| 국제화/시간대/로케일           | `docs/INTERNATIONALIZATION.md`                                                                                                     |
| 코드 스타일 판단             | `docs/CODE_STYLE.md`                                                                                                               |
| 문서 갱신                 | `.harness/checklists/doc-update.md`                                                                                                |
| 장애 대응                 | `.harness/checklists/incident.md`, `docs/RELIABILITY.md`                                                                           |
| 커밋/푸시                 | `docs/VERSION_CONTROL.md`, `.harness/checklists/commit.md`                                                                         |
| PR 생성/리뷰/머지           | `docs/PULL_REQUESTS.md`, `.harness/checklists/pull-request.md`                                                                     |
| 기술 선택                 | `docs/adr/README.md`                                                                                                               |


## Hard Constraints


| 제약                                              | 이유                                                                                                                     |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 자동 생성 파일은 직접 수정하지 않습니다.                         | 다음 생성 과정에서 덮어써질 수 있습니다.                                                                                                |
| 검증 없이 완료를 선언하지 않습니다.                            | AI 출력이 실제 동작을 보장하지 않습니다.                                                                                               |
| 관련 없는 파일을 정리하거나 리팩터링하지 않습니다.                    | 변경 범위 추적이 어렵습니다. 드리프트 정리·문서 인덱스 보강은 `docs/MAINTENANCE.md`·`.harness/checklists/maintenance.md`에 따른 별도 유지보수 작업으로 수행합니다. |
| 민감정보를 코드나 문서에 직접 기록하지 않습니다.                     | 보안 사고로 이어질 수 있습니다.                                                                                                     |
| 시스템·사용자가 계획만·읽기 전용을 명시한 경우 파일을 수정·생성·삭제하지 않습니다. | 명시된 모드와 실제 변경이 어긋나면 검토·재현을 망칩니다.                                                                                       |
| `docs/UI_RULES.md`를 읽지 않고 UI·스타일 파일을 수정하지 않으며, 요청 범위 밖 화면을 재스타일하지 않습니다. | UI 규칙 무시와 임의 재스타일은 디자인 드리프트의 최대 원인입니다.                                                                       |
| 문서 산출물을 `docs/ARTIFACTS.md`의 위치·네이밍 규칙 밖에 만들지 않습니다.       | 산출물이 흩어지면 다시 찾을 수 없고 같은 분석을 반복하게 됩니다.                                                                             |
| 검증 통과한 변경을 남긴 채 커밋 판단 없이 턴을 끝내지 않습니다(사용자가 커밋 보류를 명시한 경우 제외). | `scripts/recommend-version-control.ps1` 실행이 자동 커밋의 유일한 진입점입니다.                                                    |


## Completion Standard

작업 완료 시 `.harness/checklists/pre-completion.md`로 자체 점검하고, 같은 문서의 "완료 보고 형식" 섹션이 정한 순서(요청 확인 / 변경 사항 / 검증 / 결과 확인 / CodeHealth / 리스크와 다음 판단)를 따릅니다. 검증을 실행하지 못했거나 해당 없는 항목이 있으면 생략하지 말고 이유와 대체 확인을 해당 섹션에 적습니다.

**완료 주장은 증거 파일로 뒷받침합니다(EVIDENCE_RECORDED 계약).** 기능·버그·검증이 있는 작업은 검증 명령과 실제 출력을 `scripts/new-artifact.ps1 -Type validation`으로 만든 `docs/validation/YYYY-MM-DD-*.md`에 기록하고, 완료 보고의 **마지막 줄**을 정확히 `EVIDENCE_RECORDED: <저장소 상대 경로>` 형식으로 끝냅니다. 증거 파일에는 생성 시점의 기준 커밋(코드 지문)이 자동 기록되며, 리뷰어는 `scripts/verify-evidence.ps1 -Path <경로>`로 그 이후 코드가 바뀌었는지(fresh/stale) 확인합니다. 검증이 없는 순수 문서 작업은 `EVIDENCE_RECORDED: N/A(docs-only)`로 표기합니다.

**결과 보고는 항상 비쥬얼라이즈로 합니다.** 시각화 위젯 도구(예: visualize `show_widget` MCP)를 쓸 수 있는 환경이면 완료 보고의 핵심(변경 요약, 검증 결과, 리스크)을 **반드시 비쥬얼라이즈 위젯으로 함께** 보고합니다. **`리스크와 다음 판단`(남은 리스크, 사용자 결정 사항)과 `추천 작업`(다음에 할 일 제안·우선순위)도 텍스트로만 나열하지 말고 항상 비쥬얼라이즈 위젯으로 표현합니다.** 텍스트 보고는 위젯을 보완할 뿐 대체하지 않습니다. 위젯 도구가 없는 환경에서만 마크다운 표·다이어그램으로 대체하고, 대체했다는 사실과 이유를 완료 보고에 한 줄 남깁니다.

**보고 언어 규칙(쉬운 말 + 비유).** 결과 보고 체계의 단일 정답지는 [`docs/REPORTING.md`](docs/REPORTING.md)이며(위젯 골격·자가 검사·버튼 패턴 포함), 아래는 그 핵심 요약입니다.

1. **위젯 제목**: 모든 비쥬얼라이즈 위젯의 맨 위에 이 위젯이 무엇을 보여주는지 한 줄 제목을 넣습니다.
2. **쉬운 말**: 어려운 기술 용어 대신 일상 단어를 씁니다. 전문 용어·변수명·스크립트명을 쓸 수밖에 없으면 **괄호를 열어 쉬운 한글 설명을 병기**합니다. 예: `tree hash(코드 지문)`, `Stop 훅(턴 종료 감시원)`, `commit-work-unit.ps1(커밋 나눠주는 도구)`.
3. **비유 유지**: 결과 보고는 항상 정해진 비유를 곁들여 설명합니다. 현재 비유는 `.harness/reporting.json`의 `analogy` 값이며, **사용자가 다른 비유로 바꿔 달라고 명시하기 전까지는 같은 비유를 계속 사용**합니다. 비유를 바꾸는 유일한 절차: 사용자가 요청하면 `analogy`와 `setAt`을 갱신하고 그 사실을 보고합니다. 임의로 비유를 바꾸거나 생략하지 않습니다.
4. **실행 버튼 의무**: `리스크와 다음 판단`·`추천 작업`(로드맵) 위젯의 각 안건에는 **반드시 실행 버튼을 넣습니다** — 클릭하면 해당 지시가 채팅에 그대로 입력됩니다(`sendPrompt`). 버튼 없는 안건 나열은 미완성 보고입니다. 구현은 반드시 `docs/REPORTING.md` §3의 패턴(`data-prompt` 속성 + 마지막 `<script>` 바인딩)을 씁니다 — 인라인 `onclick`은 불발, 이 패턴은 작동이 **실측 확인**되었습니다(2026-07-22 사용자 테스트).
5. **스타일 가이드**: `.harness/reporting.json`의 `styleGuide`에 보고 스타일 가이드 문서 경로가 지정되어 있으면 그 가이드의 골격·컴포넌트·언어 규율(비유→용어 병기→왜→숫자 순서, 정직 콜아웃, 실측/가설 구분 등)을 따릅니다.