# Architecture

프로젝트의 구조와 데이터 흐름을 AI가 빠르게 이해하기 위한 문서입니다.
코드가 말해주지 않는 의도, 경계, 금지된 의존성을 중심으로 작성합니다.

## System Overview

이 저장소는 **AI 코딩 에이전트가 따를 운영 체계**(어디를 읽고, 어떻게 검증하고, 언제 멈출지)를 재사용 가능한 형태로 담습니다.
본문은 문서(`docs/`), 프롬프트·체크리스트(`.harness/`), 검증 스크립트(`scripts/`), CI(`.github/`)로 구성되며 **애플리케이션 런타임이나 단일 서비스 코드베이스를 전제로 하지 않습니다**.
다른 저장소에 이 템플릿을 복사한 뒤에는 아래 **애플리케이션 레이어**·**Main Flow (애플리케이션)**를 제품 스택에 맞게 바꾸고, `docs/PRODUCT_CONTEXT.md`·`docs/TESTING.md`와 함께 채웁니다.
하네스 구조와 문서 계층의 상세 목록은 [`docs/README.md`](docs/README.md)를 참고합니다.

## Repository layout (이 템플릿 저장소)

| 영역 | 역할 |
|---|---|
| [`docs/`](docs/README.md) | 작업 규칙, 제품 맥락, 테스트·배포 등 Code Wiki |
| [`.harness/`](.harness/README.md) | 공통 체크리스트, 프롬프트, `config.json` |
| [`scripts/`](README.md#main-entry-points) | 부트스트랩, 하네스 검증, 버전 관리 보조 |
| `.github/` | PR·이슈 템플릿, 검증 워크플로 |

로컬 검증 진입점: [`scripts/validate-harness.ps1`](scripts/validate-harness.ps1).

## Main Flow

### 하네스(이 저장소 유지·검증)

에이전트와 사람이 템플릿을 쓸 때의 읽기·검증 흐름입니다.

```text
AGENTS.md (의도 라우팅)
→ docs/*, ARCHITECTURE.md (맥락·경계)
→ .harness/* (체크리스트·프롬프트)
→ scripts/validate-harness.ps1 / CI (구조·문서 검증)
```

### 애플리케이션 (이 템플릿을 제품 저장소에 도입한 뒤)

제품 코드가 있을 때의 대표 요청 처리 흐름입니다. 스택에 맞게 단계 이름을 조정합니다.

```text
User Input
→ Validation
→ Business Logic
→ Data Access / External API
→ Response / UI Rendering
```

## Layer Rules

**도입한 애플리케이션 코드베이스**에 적용할 때의 기본 책임 분리입니다. 모놀리스·모듈·마이크로서비스 모두 이 방향을 유지하는 쪽을 권장합니다.

| Layer | Responsibility | Must Not |
|---|---|---|
| UI / Presentation | 화면 표시, 사용자 입력 전달 | 비즈니스 규칙 직접 처리 |
| Application / Service | 사용 사례 조합, 흐름 제어 | DB 세부 구현 직접 노출 |
| Domain / Business | 핵심 규칙, 검증, 계산 | UI나 외부 API에 의존 |
| Infrastructure | DB, 파일, 외부 API, 환경 설정 | 도메인 규칙 결정 |

## Dependency Direction

애플리케이션 레이어 간 허용 의존 방향입니다.

```text
UI → Application → Domain
Application → Infrastructure
Domain → no framework dependency
```

## Forbidden Patterns

애플리케이션 코드에 해당할 때:

- UI 컴포넌트에서 직접 DB나 외부 API를 호출하지 않습니다.
- 도메인 로직을 라우터, 컨트롤러, 화면 컴포넌트 안에 숨기지 않습니다.

공통(하네스·앱 모두):

- 설정값, 토큰, 비밀키를 코드에 하드코딩하지 않습니다.
- 실패를 빈 `catch`나 무의미한 기본값으로 숨기지 않습니다.

## Open Questions

제품·플랫폼에서 아직 고정되지 않은 결정만 적습니다. 템플릿 저장소에는 보통 행이 없습니다. 도입 프로젝트에서 필요할 때 행을 추가하고, 아래 안내 행은 삭제합니다.

| 질문 | 현재 결정 | 다음 확인 |
|---|---|---|
| *(미결 사항이 있으면 이 행을 지우고 실제 질문으로 교체)* | | |
