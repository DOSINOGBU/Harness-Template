# Pull Requests

Pull Request는 공유 브랜치에 변경을 합치기 전에 목적, 영향, 검증을 리뷰 가능한 형태로 정리하는 단위입니다.
작은 PR보다 중요한 것은 하나의 목적과 빠른 이해 가능성입니다.

## PR Principles

- 한 PR은 하나의 목적만 가집니다.
- 리뷰어가 15분 안에 목적과 영향 범위를 이해할 수 있어야 합니다.
- 대규모 변경은 기능, 리팩터링, 문서, 설정 변경으로 분리합니다.
- 불필요한 파일 정리, 포맷 변경, 문구 수정은 본 변경과 섞지 않습니다.

## Before Opening

| 확인 | 기준 |
|---|---|
| 실행 가능 상태 | 앱 또는 핵심 흐름이 정상 실행됨 |
| 타입 검사 | 타입 시스템이 있으면 통과 |
| 린트 | 린트가 있으면 통과 |
| 테스트 | 관련 테스트 통과 또는 수동 검증 완료 |
| 변경 목적 | PR 설명만 보고 목적을 이해할 수 있음 |
| 변경 범위 | 관련 없는 변경 제거 완료 |
| 민감정보 | 토큰, API 키, 계정 정보가 포함되지 않음 |

검증을 실행할 수 없으면 PR 본문에 이유와 대체 확인 방법을 남깁니다.
GitHub에서는 `.github/PULL_REQUEST_TEMPLATE.md`가 이 문서의 본문 템플릿을 노출합니다.

## PR Title

```text
[type] summary
```

예시:

```text
[feat] add goal suggestion chatbot flow
[fix] resolve drag drop sync bug
[refactor] split project page structure
```

type은 `docs/VERSION_CONTROL.md`의 커밋 type과 같은 의미로 사용합니다.

## PR Body Template

```markdown
## 목적
- 이 PR의 목적

## 변경 사항
- 변경 1
- 변경 2
- 변경 3

## 영향 범위
- affected page:
- affected components:
- affected state / api:

## 검증 방법
- [ ] 실행 확인
- [ ] 타입체크 통과
- [ ] 린트 통과
- [ ] 주요 기능 테스트 완료

## 테스트 메모
- 테스트한 시나리오 작성

## 리스크
- 영향 가능 영역
- 주의할 부분

## Quality Score
- [ ] 요구사항 충족
- [ ] 변경 범위 제한
- [ ] 검증 기록
- [ ] 디버깅 가능성
- [ ] 유지보수성

## UI 변경
- 스크린샷 첨부 (있을 경우)
```

## Merge Blockers

- 타입 에러가 있습니다.
- 테스트 또는 빌드가 실패했습니다.
- 충돌이 해결되지 않았습니다.
- 목적, 변경 사항, 검증 방법 설명이 부족합니다.
- 민감정보가 포함되어 있습니다.
- `main` 안정성을 해칠 가능성이 확인되었습니다.

## Review Criteria

- 요구사항을 충족하는가?
- 기존 기능에 의도하지 않은 영향을 주는가?
- 예외 처리와 실패 경로가 충분한가?
- 코드 구조가 기존 경계와 책임을 지키는가?
- 불필요한 코드, 로그, 파일 변경이 포함되어 있지 않은가?
- `docs/QUALITY_SCORE.md`의 최소 통과 기준을 만족하는가?

## Branch Strategy

| 브랜치 | 용도 |
|---|---|
| `main` | 항상 안정 상태를 유지하는 공유 기본 브랜치 |
| `feature/*` | 기능 개발 |
| `fix/*` | 버그 수정 |
| `refactor/*` | 기능 변화 없는 구조 개선 |

공유 기본 브랜치는 PR을 통해 변경합니다.
프로젝트가 명시적으로 예외를 정하지 않았다면 `main`에 직접 push하지 않습니다.
프로젝트에 명확한 소유자가 생기면 `.github/CODEOWNERS`를 선택적으로 추가합니다.
