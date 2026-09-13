# M2 Match Session accepted

Primary review, 2026-09-12. This is the injected-store match lifecycle boundary,
not file-storage, native UI, physical-device, or Android release acceptance.

## Verified outcome

- Collection Apply freezes the next 3-companion/15-support match; changing a future
  loadout leaves the current match unchanged.
- Start and Run publish only after literal successful persistence. Run alone owns
  deterministic bot resolution; terminal authority and fixed reward share one write.
- Exact retries do not duplicate writes or rewards. Presentation acknowledgements
  use only the small cursor; partial Skip failure retains earlier accepted steps.
- Real JSON reload restores the checked Coordinator. Player-facing receipts exclude
  the rival's private hand/Plan. Missing and invalid/future state differ.
- Production five-field profile compatibility is accepted without weakening literal
  ready/Boolean checks. Unknown ledger fields remain rejected.

Final writer run: `build/evidence/team-battle/20260912-222901-44465890f33543b4bf25cd487cbca8f6`,
PID134572. Independent primary run:
`build/evidence/team-battle/20260912-223027-e3a52943080444c7ba17975b8b5ea095`.
Both ran `tools/run_team_battle_tests.ps1 -Suite match -TimeoutSeconds 60` and
reported66 checks,6 test groups,0 failures, exit0, no task-process survivors,
empty stderr and unchanged isolated startup saves. Per-run process ledgers retain
exact commands/identities and cleanup; no player save was opened by these fixtures.

Real outcomes cover Win(seed0), Loss(seed14), Draw(seed44) as ordinary sequence2
matches after completing sequence1. Terminal write failure and identical retry,
exact terminal replay, historical Start replay, nonterminal rollback, JSON restore,
and future Collection Apply are explicit fixtures. Older-cursor safe-ignore behavior
also relies on previously accepted Coordinator coverage; not every historical
corruption permutation is a new M2 fixture.

## Maintainability review

Two small responsibility owners: strict ledger envelope/reward binding and lifecycle
session. Existing Collection, State, Coordinator, Rules and Bot remain authoritative.
Weak persistence proxy avoids a Coordinator/session reference cycle. Views are narrow;
full snapshots occur at transactions/tests, not animation frames. Historical maps
are indexed during validation. No file paths, native controls, legacy wallet mutation,
ads, backend, printer-health win condition, or40-card requirement was introduced.

Primary enables this accepted suite in runner `all`. Next: the already-reviewed
file-adapter plan, then approved native Team UI, followed by APK and Drive checks.
