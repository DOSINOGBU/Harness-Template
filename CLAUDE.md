# CLAUDE.md

@AGENTS.md

- UI·스타일 파일을 수정하기 전에는 `docs/UI_RULES.md`를 먼저 읽습니다.
- 문서 산출물은 `docs/ARTIFACTS.md`의 위치·네이밍 규칙을 따릅니다(날짜형 산출물은 `scripts/new-artifact.ps1`로 생성).
- 결과 보고는 시각화 위젯 도구가 있으면 항상 비쥬얼라이즈 위젯으로 함께 보고하고, `리스크와 다음 판단`·`추천 작업`도 각각 위젯으로 표현합니다(`AGENTS.md` Completion Standard).
- 보고 언어: 위젯마다 한 줄 제목, 어려운 용어는 쉬운 말로, 전문 용어·변수명은 괄호 한글 병기, 비유는 `.harness/reporting.json`의 `analogy`를 사용자가 바꿔 달라고 할 때까지 유지합니다.
- 다음 판단·추천 작업 위젯의 각 안건에는 실행 버튼(`sendPrompt`, 라벨 끝 ↗)을 반드시 넣고, `reporting.json`의 `styleGuide` 가이드가 있으면 그 골격을 따릅니다.
- 검증이 있는 작업은 완료 보고 마지막 줄을 `EVIDENCE_RECORDED: <docs/validation 경로>`로 끝냅니다.
- 검증 통과한 변경을 남긴 채 커밋 판단(`scripts/recommend-version-control.ps1`) 없이 턴을 끝내지 않습니다.
