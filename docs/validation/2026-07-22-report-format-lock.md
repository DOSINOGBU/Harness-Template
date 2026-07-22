# Validation: report format lock

Base commit: `4f4fe3d`

## Scope

확정 보고 양식(요약+펼치기·헤드라인·카드 그리드·대비형)을 계약 시험으로 고정.

## Commands / Scenarios

- run-prompt-contract-tests: 고정 조항 4개(19px/500, minmax(180px,1fr), 15px/500, 12px muted) 추가 후 39/39 통과
- main push: 9a6165e..4f4fe3d

## Results (Expected / Observed)

- Expected: 정본에서 규격 문구가 지워지면 CI 실패. Observed: 조항 등록·전체 통과 확인.

## Not Verified (+reason)

- 없음

## Verdict

Pass — 양식 3중 고정(정본+시험+기억) 완료.
