# Prompt: Review Change

```text
이 변경을 코드 리뷰 관점으로 검토해줘. `docs/PULL_REQUESTS.md`와 `.harness/checklists/pull-request.md`의 기대치가 있으면 함께 맞춰본다.

우선순위:
1. 버그 또는 동작 회귀
2. 보안과 권한 문제
3. 테스트 누락 또는 검증 증거 부족
4. 관측 가능성: 로그·에러 맥락·운영 시나리오 (`docs/OBSERVABILITY.md`, `docs/RELIABILITY.md` 관점)
5. 문서·PRD·exec-plan과 코드의 불일치 (`docs/PRODUCT_CONTEXT.md`, 관련 exec-plan)
6. 유지보수성 저하
7. 접근성·국제화·성능에 대한 명백한 퇴보 (`docs/ACCESSIBILITY.md`, `docs/INTERNATIONALIZATION.md`, `docs/PERFORMANCE.md` 해당 시)
8. `docs/QUALITY_SCORE.md` 최소 기준 미달

발견사항 표기:
- 각 항목에 심각도를 붙여줘: 차단(머지 보류), 주요, 경미, 사소.
- 파일 경로와 대략적 위치(함수·섹션·라인 대역)를 적어줘.

출력:
- 심각도 순서의 발견사항 목록
- 각 항목: 심각도, 파일과 위치, 왜 문제인지, 최소 수정 제안
- 테스트: 자동·수동 중 무엇이 있고 무엇이 빠졌는지
- 문서: 갱신이 필요한 문서나 누락된 사용자/운영 안내
- 계약·계획: PRD Feature Contract 또는 exec-plan과 어긋난 점이 있는지
- 품질 점수 관점에서 부족한 항목
```
