# Validation Records

검증(테스트·수동 시나리오·회귀 확인) 실행 결과를 남기는 폴더입니다. 위치·네이밍 규칙은 [`docs/ARTIFACTS.md`](../ARTIFACTS.md)를 따릅니다.

이 폴더는 `.harness/config.json`의 `versionControl.workUnitPaths.validation`에 등록되어 있어,
기능/테스트 커밋과 분리된 문서 커밋(`docs(validation): record <topic>`)의 대상입니다.

## Naming

- `YYYY-MM-DD-topic.md` (예: `2026-07-22-checkout-regression.md`)
- 파일명은 소문자 kebab-case, 날짜는 항상 맨 앞.

## What To Record

- 실행한 검증 명령과 결과(성공/실패), 검증 표면(CLI/UI/둘 다)
- 수동 시나리오의 Expected/Observed (`docs/TESTING.md`의 Manual Scenario Template)
- 실행하지 못한 검증과 이유, 대체 확인 방법
