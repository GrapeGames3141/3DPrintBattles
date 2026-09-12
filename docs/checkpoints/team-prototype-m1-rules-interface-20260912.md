# M1 Rules and presentation interface

Primary implementation decision, under the already approved M1 contract. This is
not a new gameplay proposal or a claim of passing tests. Data/State is validated
first; the sole Terra writer then replaces the incompatible draft Rules module.

## Checked commands

Public Plan keys are `expected_revision` (required integer), `fabrication_id`,
`support_copy_id`, `equipment_target_id`, and `swap_id` (optional strings, empty
means no choice). IDs are canonical seat-scoped identity/copy IDs, not catalog IDs.
Unknown keys, coercion of malformed types, stale revisions, Support plus swap,
target without equipment, and explicit illegal fabrication all reject atomically.
An omitted fabrication selects the highest-priority Unspent F6 default only when
Active and Ready are both empty and the entire resulting composite is legal. If
that default is resource/capacity blocked, only a no-choice Plan (all optional
choices empty) may advance work/regeneration. Selected aid plus affordable default
resolves together; other selected choices plus an illegal default reject unchanged.
Never silently drop an explicit player choice to make a Plan legal.

Rules public functions:

- `validate_plan(state, seat_id, plan, test_1v1=false)` returns `ok`, normalized
  `plan`, and `forecast`, or `ok=false,error`; it never changes arguments.
- `run_cycle(state, player_plan, rival_plan, test_1v1=false)` validates the opening
  state and both Plans, resolves into a deep candidate, validates the settled
  candidate, and returns `ok,state,receipt`, or an atomic failure.
- `view_for_seat(state, seat_id, test_1v1=false)` returns an own-private/rival-public
  projection only. `check_view_plan(view, plan)` uses the same own-seat arithmetic
  for bot/preview, but never publishes authority; Run always revalidates.
- `eligible_equipment_targets(view, card_id, fabrication_id="")` returns Active,
  Ready by priority, then Printing/same-Plan by priority. Player replacement is
  legal; bot filtering for an empty slot remains separate.
- `project_receipt(receipt, seat_id)` projects every opening/stage snapshot using
  one explicit schema projection, never a top-level-only key deletion.

Production calls restore only 3v3; test-only 1v1 is an explicit final argument.
Rules does not persist, mutate a profile, accept presentation callbacks, or use RNG.
Bot receives the view, never a full authority snapshot or the player's Plan. The
view has exact keys `view_schema,viewer,cycle,revision,result,roster_count,
filament_cap,own,opponent`; bot-facing APIs reject full authority/raw receipts.
Opponent contains only seat identity, filament, members, priority, Active/Ready,
public FIFO jobs and hand/draw/discard counts. No rival unplayed copy IDs, seed,
original Kit, draw order, or pending Plan is exposed. Snapshot projection also
omits seed-bearing internal terminal receipt IDs. Nested sentinel tests cover the
opening view, every stage, events and forecast. Bot chooses before the player's
Plan is supplied to Run.

## Forecast

Return opening filament, aid gain, capped available filament, complete cost,
post-spend filament, next regeneration, ordered new jobs, current head/one-work
completion, default-fabrication reason, selected target or swap, and explicit
hidden-rival-choice uncertainty. Show replacement/refresh without claiming another
eight armor stacks. Forecast is read-only and is not a guaranteed combat outcome.

## Resolution and receipt

Use the F4 cycle order, stable player/rival seat order, and integer arithmetic.
Create IDs `seat:job:cycle:companion|equipment`, append companion before equipment,
consume exactly one work unit from each head without carry. Equipment card copies
remain in FIFO until fit/fizzle, then enter discard. Immediate copies enter discard
at commit. Each member's state transition preserves its canonical identity.

The raw internal receipt stores cycle, opening revision, final revision, opening
state, and ordered stages. Each stage has a stable name, ordered structured events,
and a deep state snapshot for presentation. Public event fields contain no hidden
hand, draw order, or original Kit; draw feedback exposes counts only. Gear/play
events may reveal the card actually played. State snapshots are projected for the
viewer before leaving the coordinator. Intermediate snapshots are presentation
records, not independently restorable settled authority.

Stages are Queue, Print, Awaken, Enter/Fit, Swap, Spell, AttackLock, Damage, Traits,
Defeat, Replace, Result, then Plan when nonterminal. The Print snapshot retains the
pre-work head and Printing member status, with `head_before`, work-before/after,
work-total, kind, identity/target, and intended destination in its event. Awaken
retains the completed zero-work head in its printer and the member as Printing;
Enter removes that head and moves the same identity to Active/Reserve. These are
explicit nonrestorable presentation snapshots, distinct from settled State. Gear
uses Print then Fit/fizzle, never an Awaken or creature Enter event.
Do not expose the final Active state as the snapshot for the 60% Print stage. A
queued non-head companion never appears in the chamber. A gear head is gear art.

AttackLock events identify both sources/targets, incremented landed counters,
integer locked damage, and one shared beat ID. Damage records HP and armor before/
after for each target; both hits use the same lock snapshot. Trait events occur
only for a legal landed hit, obey survival requirements, and preserve capped values.
Mark all defeats and replace before evaluating the one terminal result. Draw is
derived only from both teams being entirely Defeated. No cycle cap creates a result.

## Coordinator contract for the following slice

Coordinator owns request ID, payload fingerprint, persistence and presentation
cursor, not combat. A Run request prepares a candidate plus receipt; one injected
store callback must succeed before publication. The same ID/payload returns the
original receipt; reused ID/different payload rejects. Any pending presentation
blocks another Run. Cursor acknowledgement is bound to receipt ID and expected
cursor, ignores stale duplicates, persists before publication, and never reruns Rules.
Skip advances only this cursor; reduced motion changes only durations in the UI.
Save/resume retains authority, request receipts and cursor and validates all of them.
The follow-on [session interface](team-prototype-m1-session-interface-20260912.md)
specifies a small cursor-only persistence update for automatic stage acknowledgements;
it must not rewrite the full growing match/profile on every animation stage.
Stage completion/acknowledgement is an internal automatic callback, never a player
phase button. Nonempty stages auto-play/ack, inapplicable stages auto-skip, and a
nonterminal cycle automatically opens the next Plan. Skip consumes the same ordered
callbacks with zero remaining duration. There is no Continue, Confirm, Awaken, or
Fit control and no blank stage awaiting input.

No M1 reward mutation, live-save access, runtime-art promotion, export, or UI release
is added by this interface checkpoint.
