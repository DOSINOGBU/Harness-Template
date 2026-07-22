# UI Rules

UI를 만들거나 수정할 때 에이전트가 **반드시 먼저 읽고 그대로 따라야 하는** 프로젝트 UI 규칙입니다.
일반 원칙(로딩·빈 상태·오류 상태, 컴포넌트 책임)은 [`docs/FRONTEND.md`](FRONTEND.md)를 함께 따릅니다.

> **[하네스 적용 안내 — 프로젝트에 맞게 이 문서를 수정하세요]**
>
> 이 문서의 규칙 구조(강제 규칙, 토큰 계약, 컴포넌트 스펙, 체크리스트)는 하네스의 표준이고,
> 구체 값(색상 hex, 폰트, 컴포넌트 패키지명)은 **TradePilot에서 가져온 기본값 예시**입니다.
> 새 프로젝트에 하네스를 도입할 때:
>
> 1. `PROJECT-CUSTOMIZE`로 표시된 섹션의 값을 프로젝트의 실제 디자인 시스템으로 교체합니다. 구조(토큰 키셋·시맨틱 이름·규칙 형식)는 유지합니다.
> 2. 공유 컴포넌트 패키지명(기본 `@yourproject/ui`), 아이콘 라이브러리, 폰트를 프로젝트 것으로 바꿉니다.
> 3. 이 문서는 `AGENTS.md` Required Reading 표에서 링크되어야 합니다. 링크가 끊기면 에이전트가 읽지 않아 규칙이 무력화됩니다.
> 4. 이후 UI 규칙이 바뀌면 **이 문서만** 갱신합니다. 이 문서가 UI 규칙의 단일 정답지(source of truth)입니다.

## 1. 강제 규칙 (위반 금지)

**UI 파일을 수정하기 전에 반드시 이 문서를 먼저 읽습니다.** 읽지 않고 UI 코드를 작성하지 않습니다.

1. **요청 범위 밖 재스타일 금지.** 사용자가 요청하지 않은 화면·컴포넌트의 색, 간격, 구조, 스타일을 "개선"하지 않습니다. 기존 화면의 룩을 바꾸는 결정은 사용자 확인 후에만 진행합니다.
2. **문서에 없는 스타일 결정 금지.** 이 문서에 없는 새 패턴(새 컴포넌트 변형, 새 색, 새 레이아웃 규칙)이 필요하면, 먼저 이 문서에 추가안을 적고 사용자 확인을 받은 뒤 구현합니다.
3. **단일 테마.** 프로젝트가 정한 테마 하나로 통일합니다. (기본값: 다크)
4. **하드코딩 색 금지.** `#5fbb61`, `bg-white`, `emerald-700`, `red-500` 같은 리터럴 금지. 토큰만 사용합니다.
5. **임의 px 금지.** `text-[13px]`, `px-[18px]`, `gap-2.5` 금지. 8px 그리드(4의 배수) 스케일을 사용하고, 불가피하면 사유를 주석으로 남깁니다.
6. **재구현 금지.** 카드·배지·버튼·입력·탭·모달·빈 상태·스피너·차트는 공유 컴포넌트를 사용합니다. 공유 컴포넌트가 없으면 이 문서의 클래스 스펙을 그대로 따르고, 재사용 후보로 보고합니다.
7. **아이콘 라이브러리 단일.** 다른 아이콘 패키지를 혼용하지 않습니다.
8. **폰트 단일.** 본문·제목·숫자·차트(SVG 포함)까지 동일 폰트. 숫자는 `tabular-nums`.
9. **의미색은 시맨틱 토큰으로.** 긍정/상승=`profit`(`up`,`success`), 부정/하락=`loss`(`down`), 경고=`warning`, 에러=`destructive`, 정보/강조=`primary`.

## 2. 디자인 토큰 (PROJECT-CUSTOMIZE — 값 교체 대상)

`globals.css`(Tailwind v4 `@theme`)에 정의된 토큰만 사용합니다. 멀티앱이면 모든 앱이 동일한 토큰 키셋을 가집니다(토큰 계약).

| 용도 | 토큰/유틸리티 | 기본값 예시(다크 워밍뉴트럴) |
|------|--------------|------------------------|
| 페이지 배경 | `bg-background` | `#1c1b19` |
| 표면/카드 | `bg-card` `text-card-foreground` | `#2a2926` |
| 본문 텍스트 | `text-foreground` | `#ecebe4` |
| 보조 텍스트 | `text-muted-foreground` | `#a4a299` |
| 흐린 표면 | `bg-muted` | `#2a2925` |
| 테두리/입력 | `border-border` `border-input` | `#35332e` |
| 강조(primary) | `bg-primary` `text-primary` | `#868dfa` |
| primary 위 글자 | `text-primary-foreground` | `#16151a` |
| 위험/삭제 | `text-destructive` | `#e8675c` |
| 포커스 링 | `ring-ring` | `#7c83f5` |
| 긍정/상승 | `text-profit` `text-up` (=`success`) | `#5fbb61` |
| 부정/하락 | `text-loss` `text-down` | `#e8675c` |
| 경고 | `text-warning` | `#d97706` |
| 정보 | `text-info` | `#868dfa` |
| 차트 그리드 | `--color-chart-grid` (=border) | `#35332e` |

- 옅은 틴트는 알파 유틸리티로: `bg-profit/15`, `bg-primary/10`, `border-destructive/30`.
- 폰트 기본값 예시: Pretendard 단일(self-host, CDN `@import` 금지), 숫자 `tabular-nums`.
- 아이콘 기본값 예시: lucide-react 단일, 크기 16/18/20, `strokeWidth 1.8`, 색은 토큰.

## 3. 레이아웃/간격 (PROJECT-CUSTOMIZE)

- **페이지 래퍼**: `w-full px-5 py-6` — 풀폭(max-width 없음).
- **섹션 간격**: 기본 `gap-4`(16px). 정보 밀집 화면만 `gap-3` 허용.
- **8px 그리드**: 간격·패딩은 4의 배수(`gap-2/3/4/6`, `p-3/4/5`). off-grid 금지.
- 셸(사이드바·헤더)은 공유 `AppShell`을 그대로 사용합니다.

## 4. 컴포넌트 스펙 (PROJECT-CUSTOMIZE)

| 컴포넌트 | 캐노니컬 스펙 |
|---|---|
| PageHeader | 아이콘 칩(`h-9 w-9 rounded-[10px] bg-primary/12 text-primary`) + eyebrow(`text-sm font-medium text-muted-foreground`) + 제목 `text-2xl font-semibold tracking-tight` + 우측 액션. 컨테이너 `flex items-center justify-between gap-3 mb-6` |
| Card | `rounded-xl border border-border bg-card p-5 shadow-sm` — 메트릭 카드·패널·테이블 컨테이너 공통 |
| 타이포 | 제목 `text-2xl font-semibold tracking-tight`, 섹션 `text-lg font-semibold`, 본문 `text-sm`, 보조 `text-sm text-muted-foreground`, 수치 `tabular-nums` |
| Button | `h-9 rounded-md px-3 text-sm font-medium gap-2`. variant: default/outline/soft/destructive. size sm/md/lg/icon(aria-label 필수). **ghost 금지**, 원시 `<button>` 직접 스타일 금지 |
| Input/Field | `h-9 w-full rounded-md border border-border bg-background px-3 text-sm`, 포커스 `focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-ring`, 라벨은 칸 위, 에러 `text-xs text-destructive` |
| Select | 닫힘 트리거는 Input과 동일 + 우측 chevron-down. 열린 메뉴 `rounded-[10px] border border-border bg-card p-1.5 z-50 shadow-lg`, 선택 항목 `text-primary` + Check |
| Badge | `rounded-md px-2 py-0.5 text-[11px] font-medium`, 배경 `<tone>/15` + 글자 `<tone>`. 알약(rounded-full) 배지 금지 |
| DataTable | 래퍼 `rounded-xl border border-border bg-card overflow-hidden`, 헤더 `bg-muted/40 text-[11px]` **대문자 변환 금지**, 행 `divide-y`, 셀 `px-3 py-2.5`, 숫자열 `text-right tabular-nums` |
| Tabs | 밑줄형(`border-b-2`, 활성 `border-primary text-primary`), `role=tablist`/`aria-selected` 필수. 짧은 토글은 SegmentedControl |
| EmptyState | 중앙 정렬 `rounded-xl border border-border bg-card p-8 text-center`, 아이콘 칩 + 제목 + 설명 + outline CTA |
| 로딩 | 라우트 전환 = 얇은 상단 진행바 + 스켈레톤(`loading.tsx`). 인라인 = 공유 Spinner. **풀스크린 딤 오버레이 + "로딩 중" 알약 금지** |
| Dialog | 스크림 `bg-black/40 z-50`, 패널 `rounded-xl border border-border bg-card p-5 shadow-lg` 중앙, 포커스 트랩·ESC 내장 |
| Alert/Toast | 배너 `rounded-md border border-<tone>/30 bg-<tone>/10 p-3 text-sm` + 아이콘, 토스트 우하단 `bg-card`, `aria-live` 필수 |
| 차트 | 색은 `--color-up`/`--color-down`/`--color-chart-grid`/시리즈 토큰. 인라인 SVG 하드코딩 hex 금지 |

## 5. UI 변경 체크리스트 (완료 전 전부 1줄씩 점검)

한 축만 보고 끝내지 않습니다. 각 항목을 캐노니컬 스펙과 위반 신호로 대조합니다.

| # | 항목 | 위반 신호 |
|---|------|-----------|
| 1 | 헤더 | 인라인 h1, 크기/굵기 제각각, 아이콘 칩 없음 |
| 2 | 레이아웃 | 임의 px 패딩, 인라인 maxWidth |
| 3 | 카드 | 라디우스 혼용, `bg-white`, 그림자 누락 |
| 4 | 타이포 | 임의 `text-[Npx]`, 별도 monospace, tabular-nums 누락 |
| 5 | 색 토큰 | 하드코딩 hex, 팔레트 리터럴(emerald-*/red-*) |
| 6 | 버튼 | 원시 `<button>`, 높이 제각각, 하드코딩 hover |
| 7 | 폼/입력 | 라벨 없음, 포커스 링 누락/변형 |
| 8 | 배지 | 알약형, 하드코딩색, 크기 제각각 |
| 9 | 테이블 | 대문자 헤더, 숫자 좌측정렬 |
| 10 | 탭 | 알약 탭, 클릭 안 되는 가짜(span) 탭 |
| 11 | 빈 상태 | 좌측정렬, 아이콘/CTA 없음 |
| 12 | 로딩 | 풀스크린 딤 오버레이, 스피너 아이콘 혼용 |
| 13 | 간격 | off-grid(`gap-2.5`, `px-[18px]` 등) |
| 14 | 아이콘 | 타 라이브러리 혼용, 임의 크기, 하드코딩색 |
| 15 | 모달 | 스크림 농도/z-index 제각각, 포커스 트랩 없음 |
| 16 | 피드백 | 하드코딩색, aria-live 누락 |
| 17 | 차트 | 하드코딩 hex 선/그리드 |
| 18 | 포커스 | `focus-visible:ring-2 ring-ring` 누락, 기본 외곽선 |

## 5a. 시각 QA — 전후 사진 비교 (룩이 바뀌는 작업 필수)

화면의 룩이 바뀌는 UI 작업은 코드 검사만으로 완료로 보지 않습니다.

- 변경 **전** 대상 화면을 3개 화면 크기(375/768/1280px)로 캡처해 기준본(control)으로 저장합니다.
- 변경 **후** 같은 화면을 다시 캡처해 픽셀 비교(diff)를 만들고, 결과를 `docs/validation/ui-qa/<작업-슬러그>/`(control·current·diff 하위 폴더)에 남깁니다.
- diff가 의도한 변경만 담고 있는지 확인한 결과를 완료 보고의 `검증`에 포함합니다. 의도된 변경이면 기준본을 갱신합니다.
- 캡처 도구는 프로젝트별로 준비합니다(PROJECT-CUSTOMIZE — 예: Playwright 기반 스크린샷·픽셀 diff 스크립트). 도구가 아직 없는 프로젝트는 수동 스크린샷으로 대체하고 완료 보고에 그 사실을 남깁니다.

## 6. 적합성 검증 (재발 방지)

**"컴포넌트가 존재한다" ≠ "결정대로 구현·배선됐다."** typecheck는 미배선(만들었지만 마운트/사용 안 됨)을 잡지 못합니다.

- 공유 컴포넌트 도입·수정 시 실제 라이브 페이지에서 import·마운트·사용까지 grep/코드로 확인합니다.
- 상태는 5단계로 기록합니다: 적용(완전 채택·배선) / 클래스만(시각 정합, 공유 컴포넌트 미채택) / 미배선(존재하나 사용 안 됨 — 즉시 수정) / 누락 / 보류.
- 검증용 grep 예: 하드코딩 hex(`#[0-9a-fA-F]{6}`), 팔레트 리터럴(`emerald-|red-[0-9]|bg-white`), off-grid(`\[\d+px\]|gap-2\.5`), 금지 아이콘 패키지 import.

## 7. 작업 순서 (UI 작업 표준 절차)

1. 이 문서(특히 §1 강제 규칙)를 읽습니다.
2. 비슷한 기존 페이지 1~2개를 찾아 실제 패턴을 확인합니다.
3. 레이아웃·컴포넌트 구성을 한 줄로 요약해 사용자 확인을 받습니다(신규 화면·룩 변경 시).
4. 구현합니다.
5. §5 체크리스트를 전부 자가 점검하고, 룩이 바뀌었으면 §5a 전후 사진 비교를 수행합니다.
6. §6 배선 확인을 수행하고, 체크 결과를 완료 보고의 `검증`에 포함합니다.

참고: 커밋 단계에서도 지켜집니다 — `scripts/commit-work-unit.ps1`이 이 문서의 금지 패턴(`validation.uiConformance` 설정) 기준으로 **새 위반이 추가된 커밋을 차단**합니다(기존 위반이 남은 파일의 무해한 수정은 통과, 의도적 예외는 `-AcceptUiConformance "<사유>"`로 기록).
