# Agent Runs

에이전트 작업의 실행 기록을 남겨 반복 실패를 데이터로 개선하기 위한 공간입니다.
모든 작업을 기록할 필요는 없지만, 실패 분석, 반복 검증 실패, 중요한 판단 변경, 새 자동화 후보가 생긴 작업은 짧게 남깁니다.

## When To Record

- 같은 검증이 두 번 이상 실패했습니다.
- 같은 파일을 여러 번 수정하며 접근을 바꿨습니다.
- 사용자 결정, 보안, 데이터, 비용, 배포처럼 나중에 추적해야 할 판단이 있었습니다.
- 검증을 실행하지 못해 대체 확인으로 완료했습니다.
- 하네스 프롬프트, 체크리스트, 스크립트 개선 후보가 생겼습니다.

## Naming

파일명은 `YYYY-MM-DD-short-task.md` 형식을 사용합니다.
민감정보, 토큰, 개인 식별 정보, 전체 원본 로그 덤프는 기록하지 않습니다.

## Run Log Template

```md
# Agent Run: short task name

## Request

## Intent

Build 또는 Debug 중 하나로 분류하고 이유를 적습니다.

## Context Read

읽은 문서와 확인한 코드 위치를 적습니다.

## Commands

실행한 명령, 성공 여부, 핵심 출력만 적습니다.

## Changes

변경 파일과 변경 의도를 적습니다.

## Verification

검증 결과, 실패 원인, 대체 확인 방법을 적습니다.

## Loop Signals

반복 수정, 반복 실패, 접근 전환 여부를 적습니다.

## Risks

남은 리스크와 사용자가 판단해야 할 사항을 적습니다.

## Promotion

반복될 가능성이 있으면 `docs/LEARNING_LOG.md` 또는 `docs/AUTOMATION_EVOLUTION.md`에 반영합니다.
```
