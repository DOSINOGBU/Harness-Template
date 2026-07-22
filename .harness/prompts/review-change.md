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

완료 주장 검증(반증 의무):
- 작성자의 DoneClaim(완료 주장)은 신뢰하지 않는 입력으로 취급해줘.
- 완료 보고의 `EVIDENCE_RECORDED:` 경로가 있으면 `scripts/verify-evidence.ps1 -Path <경로>`로 증거가 현재 코드와 맞는지(fresh/stale) 먼저 확인해줘. stale이면 증거를 신뢰하지 말고 재실행을 요구해줘.
- 증거 파일에 기록된 핵심 검증 명령을 기록된 출력을 믿지 말고 **직접 다시 실행**해 결과를 대조해줘.
- 최소 1회 반증을 시도해줘: 이 변경이 처리해야 하지만 놓쳤을 법한 입력·상태를 하나 골라 실제로 실행해보고 결과를 남겨줘.

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
