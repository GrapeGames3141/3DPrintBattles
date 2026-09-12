# M1 Coordinator acceptance and maintenance review

Primary reviewed and accepted the frozen Coordinator slice on 2026-09-12.
This completes the isolated M1 battle-domain/session checkpoint, not the playable
UI, Collection Link, Android or release milestone. The shipped build is unchanged.

## Verified behavior

The Rules engine remains the only combat authority. The Coordinator persists a
candidate before publication, retains canonical input/receipt identity, rejects
changed duplicates and pending/terminal transitions, and presents checked viewer
projections. Automatic animation acknowledgements write a small separate cursor.
Partial Skip failure preserves completed acknowledgements. JSON restore validates
settled states, transient receipt shapes, hashes, ordered revision chains and
monotonic current cursor overlays without rerunning combat or settlement.

Primary independent command:
`& .\tools\run_team_battle_tests.ps1 -Suite coordinator -TimeoutSeconds 45`

- Evidence: `build/evidence/team-battle/20260912-185124-30ed0afa1e6c4ab5a961e2a7553edc6c`.
- Godot 4.7.1, PID 62740, exit 0; seven groups, 70 assertions, zero failures.
- Empty stderr, no task-owned windows or surviving processes, isolated save file
  set/bytes unchanged. No editor/game window, live player save or mouse capture.
- Full 3v3 seed47: normal, reduced, Skip and JSON-resumed sessions each finish in
  18 cycles with identical ordered receipt hashes, terminal State and final cursor.
- Reduced/normal here mean identical automatic acknowledgement schedules; this is
  not yet evidence of native animation duration, input feel or device presentation.

Writer final dependent regressions (primary inspected output and cleanup ledgers):

| Suite | Evidence suffix under `build/evidence/team-battle/` | Result |
| --- | --- | --- |
| Core | `20260912-184630-58134ff46c7744548b826aefaed07972` | 84 assertions, 0 failures |
| Bot | `20260912-184646-8970f712b5c047a88d7c0232c89d2cf5` | 40 assertions, 0 failures |
| Pacing | `20260912-184700-b1cabcad707b43d895ceaa03eb55aa38` | 45 matches, 2279 assertions, 0 failures |

Pacing remains the user-accepted median16 cycles, p95=18, max19. First print and
contact median1; first replacement median10. No invented match cap or printer-HP
victory was added. Earlier State/startup preservation evidence remains referenced
by the M1 first-run and Rules/Bot validation checkpoints.

## Maintainability and performance boundary

The 476-line Coordinator owns only session/cursor integrity and injected storage.
Rules, State, projection and bot responsibilities remain separate. No additional
abstraction/refactor is needed for this slice. Primary checked the final diff and
tests, including the original minimal Plan hash shape and transient-stage guards.

One completed 18-cycle session is 1,082,771 serialized bytes. Primary desktop run
measured Run total 1,816,397us, max154,617us; acknowledgement max643us; cumulative
restore 11,262,047us across 18 deliberate JSON reloads. These include harness/store
copying and are descriptive, not Android frame-performance acceptance.

M3 must not call full `snapshot()` every animation frame. Use projected receipts
and small cursor acknowledgements; show a busy state before Run/restore, then
measure actual Android latency and frame pacing. The adapter must not rewrite the
whole history/profile for each stage. Retain receipt history for idempotency;
do not prematurely prune or weaken integrity checks to chase these harness times.

## Next bounded work

1. User-authorized deterministic EQ-R1 armor alpha cleanup and read-only edge review.
2. M2 pure collection projection/session from the two decision-complete M2 plans.
3. M2 persistence/reward adapter, then approved portrait UI/native animation checks.
4. Android review export and non-overwriting Google Drive delivery only after the
   remaining visual/runtime gates. Voltwig front/rear art remains a separate asset
   issue documented in the M3 readiness record; no silent release exception.
