# Prompt: Update Docs

```text
이번 변경에 따라 영향받는 문서를 갱신해줘.

확인 대상:
- ARCHITECTURE.md (경계, 의존성 변경)
- docs/PRODUCT_CONTEXT.md (PRD Feature Contract, 현재 기대 동작, 계약 상태)
- docs/PROJECT_RULES.md (새 규칙, 폐기 규칙)
- docs/GLOSSARY.md (새 용어, 의미 변경)
- docs/TESTING.md (명령, 검증 절차, 회귀 시나리오)
- docs/SECURITY.md, OBSERVABILITY.md, RELIABILITY.md (관련 변경 시)
- docs/adr/ (큰 결정이면 새 ADR)
- docs/exec-plans/ (진행 중 계획이라면 결과 반영)

규칙:
- 코드만 보고 알 수 있는 내용은 적지 마.
- 같은 규칙을 두 곳에 중복으로 적지 마.
- 옛 정보는 지우거나 옮기고, 그대로 남기지 마.
- exec-plan을 만들거나 갱신할 때는 `docs/exec-plans/template.md`의 heading 이름, 순서, depth를 유지해줘.
- 기능 동작, UI 흐름, API/data, 권한/네비게이션이 바뀌었다면 `PRD Feature Contract`의 `Current expected behavior`, `Regression scenario`, `Last updated by`, `Contract status`를 최신화해줘.
- 수정된 기능 계약이 최신이 아니면 `Contract status`를 `Needs update`로 두고 전체 PRD 기능 테스트 완료로 보고하지 마.

변경 요약:
TODO
```
