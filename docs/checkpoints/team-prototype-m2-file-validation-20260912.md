# File-backed Team runtime accepted

Primary review2026-09-12. This accepts the explicit-path file boundary and thin
runtime facade, not native screens or an Android release.

## Evidence

Writer parser runs: store
`build/evidence/team-battle/20260912-225632-20fdd573fa92496b8c8c65f965f18ba6`
(PID151280); runtime
`build/evidence/team-battle/20260912-225635-fb97f0f09b584f0c849ef0aa49441f72`
(PID142936).

Writer behavior run:
`build/evidence/team-battle/20260912-225650-199799590a5344fcb0f023a33ace75b4`
(PID124804). Independent primary behavior run:
`build/evidence/team-battle/20260912-225831-766cc57d12ac434ba4dbe919181a18a9`.
Both behavior runs used `tools/run_team_battle_tests.ps1 -Suite adapter
-TimeoutSeconds 60`:66 assertions,5 groups,0 failures, engine exit0, empty stderr,
no task-owned windows/process survivors, unchanged isolated startup save manifest.
Exact process identities/commands live in each run's process ledger.

Actual synthetic files live only in sibling `adapter-fixtures`. Verified: clean
zero-write open; missing/null/future/corrupt state; orphan and backup/staging
recovery; five explicit starter-to-Applied actions; real Start/Run/cursor JSON reload;
one complete deterministic match; terminal reward unchanged on replay/reload;
profile/ledger/cursor separation; immutable request replay after future Apply.

Faults include temp open/write/validation, backup and promotion, post-read with
successful/failed rollback, first-ever uncertain promotion plus reopen, repeated
identical failed retries, backup staging retry/recovery, and changed profile or
ledger during the dependent transaction. Final generation check follows the
promotion hook and precedes replacement. Cursor has no version field; unknown or
invalid cursor shape rejects instead of a fictitious cursor-version migration.

Legacy journal/pack paths are excluded by the store's three explicit path owners
and were reviewed in source. This new fixture does not claim a device crash/power-
loss experiment or exhaustive fault combinations across every OS/filesystem.

## Primary corrections and maintainability

- Exact-byte generations and dependent read-set checks protect Start/acknowledgement.
- Repeated backup/temp attempts no longer permanently block Retry. Unknown incomplete
  staging is preserved and opens read-only; rollback failure locks mutation.
- First uncertain promotion retains evidence instead of silently accepting a
  request previously reported failed. No automatic player-data repair/reset occurs.
- Accepted Collection/Match authorities own all transitions. Facade resolves
  immutable original request freshness for duplicate actions without changing rules.
- Weak callback owners and explicit close avoid session cycles. Narrow collection
  views expose voucher/ownership/receipt without profile/request history. UI must
  cache these at route/action boundaries, never call them per animation frame.
- Existing legacy profile values are preserved; no wallet/journal/pack/ads/backend
  mutation or new gameplay schema was introduced by the adapter.

Primary adds accepted adapter suite to `all`. Explicit future `ui-collection` and
`ui-collection-capture` runner entries are preparation only, not passing evidence.
Next: approved native Collection UI, then Battle UI, source launch/APK and Drive.
