# Contributing

이 저장소는 작은 변경, 명확한 검증, 되돌리기 쉬운 커밋을 우선합니다.

## Workflow

1. 현재 브랜치와 변경 범위를 확인합니다.
2. 관련 문서를 읽습니다: `AGENTS.md`, `docs/WORKFLOW.md`, 작업 유형별 checklist.
3. 변경을 한 목적에 맞게 작게 유지합니다.
4. 관련 검증을 실행합니다.
5. `type(scope): summary` 형식으로 커밋합니다.
6. PR은 `[type] summary` 제목과 `.github/PULL_REQUEST_TEMPLATE.md` 본문을 사용합니다.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Mode Template
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -Maintenance
powershell -ExecutionPolicy Bypass -File scripts/validate-harness.ps1 -CodeHealth -Mode Project
```

실제 프로젝트에 템플릿을 적용한 뒤에는 `docs/TESTING.md`의 TODO 명령을 채우고 `-Mode Project`를 통과시킵니다.

## Branches

- `main`: 안정 상태
- `feature/*`: 기능 추가
- `fix/*`: 버그 수정
- `refactor/*`: 동작 변경 없는 구조 개선

## Review

리뷰는 `docs/QUALITY_SCORE.md` 기준을 따릅니다. 요구사항 충족, 변경 범위, 검증, 디버깅 가능성, 유지보수성을 확인합니다.
