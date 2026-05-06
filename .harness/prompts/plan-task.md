# Prompt: Plan Task

```text
이 작업을 바로 구현하지 말고 먼저 계획해줘.

1. 관련 파일과 문서를 찾아 현재 구조를 요약해줘.
2. `docs/exec-plans/active/`와 `docs/exec-plans/completed/`의 기존 plan을 확인하고 관련 parent plan이 있는지 판단해줘.
3. 기능 추가 또는 기능 동작 변경이면 구현 전에 active exec-plan을 만들거나 기존 active plan을 갱신하는 것을 계획 산출물로 둬.
4. 새 exec-plan을 만들거나 갱신한다면 `docs/exec-plans/template.md`를 그대로 사용하고 heading 이름, 순서, depth를 바꾸지 마.
5. 기존 사용자 작업, 데이터 흐름, 화면, API, 품질 게이트, 후속 보완 범위와 연결되면 새 top-level 번호가 아니라 `01a`, `01b` 같은 하위 plan으로 계획해줘.
6. 완전히 새로운 기능일 때만 새 top-level 번호를 사용하고, 그 경우 `Scope`에 기존 plan과 분리되는 이유를 적어줘.
7. 연결 여부가 애매하면 새 번호를 만들지 말고 가장 가까운 parent의 하위 plan으로 계획해줘.
8. 큰 기능이면 한 AI가 맡을 수 있는 기능 단위 plan으로 나누고, 각 plan의 소유 경계를 적어줘.
9. 각 plan에 `Parallel Work`를 포함하고 `Can run in parallel`, `Independent scope`, `Blocked scope`, `Depends on contract`, `Resume after`, `Ownership boundary`, `Coordination notes`를 채워줘.
10. 선행 plan 계약이 미완료이면 독립 가능한 범위와 보류할 범위를 분리해줘.
11. 독립 범위가 없으면 구현 계획이 아니라 `Blocked` 보고 계획으로 둬.
12. 요구사항에서 모호한 부분을 표시해줘.
13. 최소 변경으로 해결하는 실행 계획을 작성해줘.
14. 이 작업이 다른 기능의 입력 또는 전제 조건인지 확인해줘.
15. `docs/PRODUCT_CONTEXT.md`의 `PRD Feature Contract`를 확인하고 영향받을 수 있는 기존 PRD 기능과 회귀 시나리오를 계획에 적어줘.
16. 기능 동작, UI 흐름, API/data, 권한/네비게이션이 바뀌면 관련 Feature ID의 `Current expected behavior`, `Regression scenario`, `Last updated by`, `Contract status`를 어떻게 최신화할지 계획해줘.
17. 전체 PRD 기능 테스트가 필요하면 `Contract status=Current`인 기능만 대상으로 삼고, `Needs update` 기능은 먼저 계약 갱신 계획에 포함해줘.
18. UI, shared component/state, API, data model, navigation, auth/permission을 바꾸면 기존 기능 대표 시나리오를 최소 1개 이상 검증 계획에 포함해줘.
19. 핵심 산출물 품질 기준이 필요한 경우, downstream 기능보다 먼저 품질 게이트 계획을 만들어줘.
20. mock/fake 검증과 실제 샘플 품질 검증을 분리해서 계획해줘.
21. 긴 API 작업이나 자동 파이프라인이면 checkpoint, resume, time budget, candidate limit를 기본 설계 항목으로 포함해줘.
22. 후보 처리 작업이면 acceptance mode를 `all candidates completed` 또는 `minimum valid candidates secured` 중 하나로 명시해줘.
23. 검증 방법과 리스크를 포함해줘.
24. 기존 구조를 깨는 선택지는 별도 대안으로 분리해줘.
```
