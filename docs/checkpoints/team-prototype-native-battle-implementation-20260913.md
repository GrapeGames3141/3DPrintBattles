# Native Battle implementation batch

Primary decision-complete task. Begin after the Collection correction checkpoint
is frozen and accepted; no new art direction, mechanics or balance is authorized.
The accepted deterministic core, Collection, MatchSession and file adapter remain
the transition authorities. This batch creates the playable native view, not an APK.

## Inputs and owned files

The sole Terra writer owns new Battle presentation/controller modules under
`scripts/team_ui`, their narrow shell route/lifecycle integration, passive print
compositor display inputs, and these fixtures:

- `tests/team_battle/test_team_native_battle_ui.gd/.tscn` with exact success marker
  `TEAM_NATIVE_BATTLE_UI failures=0`.
- `tests/team_battle/capture_team_native_battle_ui.gd/.tscn` with exact marker
  `TEAM_NATIVE_BATTLE_UI_CAPTURE failures=0`.

Main has added audited runner suites `ui-battle` and `ui-battle-capture`. They retain
isolated paths, exact process cleanup, normal60second bounds, and standard capture
dimensions/text/HC/RM arguments. Main owns tools and final staging/commit. Do not
alter the default main scene, export settings or legacy Main during this batch.

Read these complete authorities before implementation:

- `team-prototype-native-ui-plan-20260912.md` and native-copy companion.
- `team-prototype-battle-ui-registration-20260912.md`, including later equipment,
  hand material, seed visibility and shadow-size additions.
- `team-prototype-battle-native-acceptance-20260913.md` (14 required native cases).
- `team-prototype-sprite-root-audit-20260912.md`.

Promote only BA-R1 and quadruped EQ-R1 to their recorded runtime paths, byte-identical
to approved E: sources, verifying recorded bytes/hashes. Reuse current inward-facing
sprites including Voltwig2x1; never mirror or fall back to historical side views.

## Architecture and state boundary

Keep Plan selection/request lifetime and receipt clock in a controller, composition
in the Battle presenter, rooted finite sprite poses in a passive visual component.
Shell owns routes/runtime reference, not a new copy of the combat engine. Cache
viewer-safe projected snapshots, artwork and immutable geometry at boundaries;
per-frame work updates only existing visual transforms/materials/text as necessary.
Do not rebuild the scene tree, load images or call full Runtime.view each frame.

Production API is the Runtime facade: `start(id,sequence,seed)`,
`run_cycle(match_id,id,plan)`, `acknowledge(match_id,id,cursor)`,
`skip(match_id,id,cursor)`, `pending_receipt()`, `current_result()`.
Read `runtime.view().match.player` as the inner private-player checked projection.
Use Rules.check_view_plan and eligible_equipment_targets for every local choice.
The renderer never calls Rules.run_cycle, Bot or an authority snapshot.

Freeze Start/Run envelopes on first attempted request. Retry identical input after
storage failure; clear a failed envelope only when the player deliberately cancels
or changes its local action, issuing a fresh collision-resistant ID on later submit.
Successful duplicate callbacks must not submit a new match or cycle.

At accepted Run the authority is already final. Cursor0 renders receipt.opening;
subsequent finite stages use their projected cached snapshots and events, never
current authority to reveal future damage/creatures/results. Print snapshot is
pre-decrement; print_work alone supplies work_before/after/total. Awaken is postwork
and predequeue; Enter/Fit supplies final destination while the transient figure
hides its stationary destination copy. Gear has no creature Awaken.

Nonterminal empty Result settles immediately; terminal Result waits for visible
Continue and successful cursor acknowledgement. Read already-settled reward only.
For terminal Skip, present Result rather than silently skipping the user-visible
receipt; use bounded cursor acknowledgements up to the Result boundary if the
generic skip API would consume it. This is presentation-only, no reward replay.

## Native input and composition

Implement Preflight/Start/Resume, Plan optional fabrication + one Support OR Swap,
Clear, target sheet, valid empty Run/replenishment, queue/forecast, finite Run/Skip,
cursor Retry/Back, automatic replacement/HOLD and real Win/Loss/Draw Result.
Reuse approved masters and exact latest registered seats/materials. No legacy
printer-health/deck/market controls, generic opaque panels or extra living copies.
UI may show native status for Unspent/Printing/Defeated, but only Active/Ready has
living sprites outside the one printer subject.

Every modal disables underlying pointer/focus owners, supplies a visible Back or
Cancel above its blocker, and restores source focus. Every route shares visible,
Escape and Android Back dispatch. Back is zero-write, leaving durable match and
cursor intact. Pause only the presentation clock while backgrounded/off-route;
resume from accepted cursor with no replay of accepted stages. Preserve or safely
revalidate local Plan/focus across text/safe-size rebuilds.

Keep final hits48px/primary56px with separate authored art/text owners if enlarged.
Test at576 and720 with all-inset fixtures. Full names/effects/disabled reasons remain
accessible when approved150 copy uses short tokens. No new ImageGen is required
unless actual screenshot review finds an asset gap; do not improvise new direction.

## Evidence and refactor boundary

Implement and exercise all14 native acceptance cases with actual viewport input,
canonical IDs, store fault injection, route/focus/request/cursor/wallet checks.
Reuse real deterministic Win/Loss/Draw fixture recipes from MatchSession tests.
Exercise all4 eligible companions on both seats at Print60, Awaken, Enter, idle,
windup/contact/return, reserve replacement and reduced-motion; include Suit/Gem
printing/Fit without pasted armor or stray alpha. Inspect all5 hand faces and privacy.

Capture first576 normal states early and freeze their code identity for read-only
review; after corrections capture720normal and tall720x1600 all-inset150HC/RM plus
representative150withoutHC. Current-code evidence only. No stdout/stderr errors,
leaked caches/nodes/timers or task process survivors. Preserve Collection203+
regressions and FirstForge0/raw/retry/awaken/depart semantics.

At freeze report actual component responsibility split, per-frame cost/lifecycle,
test assertions/evidence/PIDs, current screenshot paths and remaining limitations.
Do not stage/commit or claim Android validation. Main independently reviews/tests,
then commits and dispatches the separate normal-entry/Android delivery task.

## Designer source audit

The design agent found no contract contradiction. Terminal Skip must invoke zero
generic-skip calls: that API consumes Result too. Locate the projected terminal
Result index and acknowledge only cursors below it; Continue owns its final cursor.
After reload use canonical identity/cursor from pending receipt and match presentation,
never a fresh local request. Do not restart a clock on a successful duplicate return.

Real production outcome recipes are in
`tests/team_battle/test_team_match_session.gd` `_test_sequence_two_fixed_outcomes`:
finish sequence1 seed2, then sequence2 seed0 Win /14 Loss with Cinderpaw applied,
or44 Draw with Voltwig applied. `_play_to_terminal` supplies bot Plans, but its
unconditional terminal Skip must not be copied into native UI tests. The native
matrix observes terminal reward, Skip-to-visible-Result, Back/Resume Result,
Continue failure/Retry and unchanged wallet after every presentation action.
`_test_real_terminal_reward_settlement` supplies terminal-store failure/retry
setup; the direct mutated-core Draw is not a replacement for production UI results.
