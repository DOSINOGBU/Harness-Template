# Checklist: Commit

- [ ] 변경 범위가 하나의 목적에 맞습니다.
- [ ] 기능 추가, 버그 수정, 리팩터링, 문서, 설정 변경이 섞이지 않았습니다.
- [ ] 자동 포맷 변경과 기능 변경을 분리했습니다.
- [ ] 기능/테스트 변경과 exec-plan/validation 문서가 함께 있으면 자동 분리 커밋 대상인지 확인했습니다.
- [ ] 자동 분리 대상이면 feature/test 커밋과 exec-plan/validation 커밋을 분리했습니다.
- [ ] exec-plan 없이 구두로 처리한 direct work unit도 `recommend-version-control.ps1` 결과에 따라 자동 커밋 대상인지 확인했습니다.
- [ ] `Commit: auto_recommended`, `auto_split_recommended`, `docs_recommended`, `hold` 중 어떤 판단인지 확인하고 `hold`이면 이유를 기록했습니다.
- [ ] 작업에 맞는 테스트, 린트, 타입체크, 빌드 또는 수동 검증을 실행했습니다.
- [ ] 실행하지 못한 검증과 대체 확인 방법을 기록했습니다.
- [ ] 임시 로그, 디버그 코드, 불필요한 주석을 제거했습니다.
- [ ] `.env`, 토큰, API 키, 계정 정보가 포함되지 않았습니다.
- [ ] 커밋 메시지가 `type(scope): summary` 형식을 따릅니다.
- [ ] 메시지가 변경 목적을 구체적으로 설명합니다.
