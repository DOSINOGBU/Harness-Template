# Modules — 소규모 프로젝트의 격리 개발과 모듈 승격

메인 프로젝트 안에서 새 기능을 소규모 프로젝트로 키울 때, 경로가 지저분해지고 이식이 고통스러워지는 문제의 정본 해법입니다.
원리: **정리를 시키는 게 아니라, 어지럽힐 수 있는 위치를 없앱니다** — 격리 구획에서 키우고, 게이트를 통과해야 모듈 창고로 승격됩니다.

## Lifecycle

```
incubator/<slug>/  →  승격 게이트(promote-module.ps1 -DryRun)  →  modules/<slug>/  →  본관에서 재사용
   격리 개발              조건 전부 기계 검사                        창고 등록            공개 진입점만 import
```

## 1. 인큐베이터 (격리 구획)

- 새 소규모 프로젝트는 **반드시** `scripts/new-artifact.ps1 -Type incubator -Slug <kebab-이름>`으로 시작합니다.
  `incubator/<slug>/`에 표준 뼈대가 생성됩니다: `README.md`(목적·완료 기준·공개 API 초안), `module.json`(모듈 명세), `src/`, `tests/`, `deploy/`(배포·운영 스크립트 — 외부 실행 환경용 자산도 여기 동봉해 승격 시 함께 이동).
- 실행 계획은 기존 체계를 씁니다: `docs/exec-plans/`에 plan을 만들면 진행 감지 자동 재개(Stop 훅)가 완주를 유도합니다.
- **격리 규칙(기계 검사, `hygiene-incubator`)**:
  - 인큐베이터 코드는 본관 소스(`modules.mainSourceRoots` 설정: src, app, lib 등)를 참조하지 않습니다. 공용 코드가 필요하면 그 코드를 먼저 모듈로 승격한 뒤 씁니다.
  - 본관 코드는 `incubator/` 경로를 참조하지 않습니다. 승격 전의 기능을 본관에 배선하지 않습니다.
- 인큐베이터 안은 자유도가 높지만, 스크래치 스프롤·이름 규칙 검사는 동일하게 적용됩니다.
- `modules.incubatorStaleDays`(기본 21일) 이상 변경이 없으면 위생 검사가 방치 경고를 냅니다 — 완주시키거나 철거합니다.

## 2. 승격 게이트

`scripts/promote-module.ps1 -Slug <이름> -DryRun`으로 조건을 검사하고, 전부 통과하면 `-DryRun` 없이 실행해 승격합니다.

| 조건 | 검사 |
|---|---|
| 사용법 문서 | `README.md` 존재·비어 있지 않음 |
| 모듈 명세 | `module.json`의 `name`·`purpose`·`entry` 채워짐 |
| 공개 진입점 | `entry`가 가리키는 파일 실존 — 외부는 이 파일만 import |
| 자체 검증 | `tests/`에 테스트 파일 존재 + 증거 파일(`-EvidencePath docs/validation/...`) 지정 |
| 격리 준수 | 본관 소스 참조 0건 (grep) |
| 청소 완료 | 스크래치 패턴 파일 0건 |

통과 시 스크립트가 수행: `incubator/<slug>` → `modules/<slug>` 이동(git mv), `modules/README.md` 카탈로그에 행 추가.
이동 후 검증·커밋은 표준 흐름(`recommend-version-control.ps1` → `commit-work-unit.ps1`)을 따릅니다.

## 3. 모듈 창고와 재사용

- `modules/<slug>/`는 완제품입니다: 본관은 **공개 진입점만** import하고, 내부 파일을 직접 참조하거나 재구현하지 않습니다(UI 규칙의 "재구현 금지"와 동일 철학).
- `modules/README.md`가 카탈로그(창고 목록)입니다 — 승격 스크립트가 자동 갱신하며, **새 기능을 짓기 전에 카탈로그부터 검색**합니다(feature-change 체크리스트 항목).
- 모듈 수정은 일반 기능 작업과 동일한 규칙(plan·검증·증거)을 따릅니다.

## 4. 설정 (`.harness/config.json` `modules` 섹션)

| 키 | 기본값 | 의미 |
|---|---|---|
| `targetDir` | `modules` | 승격 목적지 폴더 |
| `mainSourceRoots` | src, app, lib, components, server, api | 격리 검사가 "본관 소스"로 간주하는 최상위 폴더들 |
| `incubatorStaleDays` | 21 | 인큐베이터 방치 경고 임계(일) |
