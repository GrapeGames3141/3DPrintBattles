# PrintForge M9 battle pacing audit v1

Status: **APPROVED M9B balance decision; implementation and full-match evidence
pending; no runtime rule changed by this document**

Date: 2026-09-04

## Existing authoritative behavior

This section is description, not a proposed change.

- `UnifiedBattleState._player()` starts each printer at `2000/2000` HP.
- `UnifiedBattleRules._check_win()` finishes only when a printer reaches zero;
  explicit Concede is the other terminal path.
- The approved M2 contract explicitly says an empty deck is not a loss. A failed draw
  deals no fatigue, and there is no round limit, tie, or sudden-death terminal.
- A direct printer attack is legal only when all three rival creature slots are empty.
- Normal damage is `max(1, ((bend + ability_bend_bonus + 3) / 4 + gem_bonus) *
  multiplier)`. With no defender, the element multiplier is neutral. Cinderpaw B18
  therefore deals exactly 5 direct printer damage; Aquafin B17 deals 5, Voltwig B16
  deals 4, and Mossmunk B13 deals 4.
- Attack-trigger `ability_damage_bonus` and target effects apply only to a creature
  target (`target >= 0`), not to a direct printer strike.
- Each ready Attack-mode unit attacks once per own Attack phase, in slot order. The
  first player cannot attack on turn one.

The strongest impossible-to-dispute lower-bound case is an already established,
unopposed three-Cinderpaw field: it deals `3 * 5 = 15` printer damage per own Attack
phase, so `ceil(2000 / 15) = 134` exposed phases are required. Two need 200; one needs
400. Real starter matches add printing, defender clearance, animations, and required
decisions before those exposed phases.

## Existing evidence gap

Current tests do not refute this result:

- `tests/test_battle_static_catalog.gd`, `tests/test_offline_qa.gd`, and
  `tests/test_opponent_balance_audit.gd` run the legacy `BattleState` / `BattleRules`,
  not `UnifiedBattleState` / `UnifiedBattleRules` used by the M2/M9 battle.
- The archived 600-match termination statement therefore describes the legacy battle
  and cannot qualify unified v3.1 pacing.
- `tests/test_m2_battle_cycle.gd` proves checked intents, ordered attacks, pending
  decisions, and a bounded single rival turn. It does not run a complete match.
- `tests/test_unified_rules.gd` proves one exposed printer hit lowers 2000 HP, but does
  not measure match length or terminal reachability.

This is not an implementation bug against the approved M2 rules: 2000 HP and no deck
fatigue were explicitly locked. It is a feature/balance gap exposed by M9's requirement
for repeatable bot matches that settle XP/coin rewards in a practical play session.

## Approved decision: printer-strike scale

Keep base printer HP `2000`, Reinforced Chassis `+500`, all creature HP/Bend/element/
equipment values, defender-first targeting, the empty-deck rule, automatic slot-order
attacks, and printer-zero victory. Change only direct exposed-printer damage:

`applied_printer_damage = normal_damage * 10`

The receipt and native damage feedback show the exact applied value. The multiplier
is deterministic, consumes no RNG, and does not affect creature-versus-creature
combat. Resulting starter bounds are:

| Unopposed field | Damage per own Attack phase | Exposed phases to 2000 |
| --- | ---: | ---: |
| 1 Cinderpaw | 50 | 40 |
| 2 Cinderpaw | 100 | 20 |
| 3 Cinderpaw | 150 | 14 |
| 3 Aquafin | 150 | 14 |
| 3 Voltwig | 120 | 17 |
| 3 Mossmunk | 120 | 17 |

Do not add empty-deck fatigue in the same slice. Fatigue changes an explicitly locked
draw rule, requires an additional damage schedule, and may introduce opening-seat bias.
If the exact full-match gate below fails after the single multiplier change, stop and
return with match traces for a separate fatigue/sudden-death decision; do not silently
stack a second rule.

### Human approval record

- **Entry:** The existing 2000-HP/no-fatigue behavior, 134-phase three-Cinder lower
  bound, x10 direct-printer-only formula, preserved values, and full-match matrix were
  presented in the current thread.
- **Player decision:** On 2026-09-04 the user replied, “Approve and approve the art
  too,” approving the x10 exposed-printer damage decision.
- **Result:** M9B may implement `applied_printer_damage = normal_damage * 10` only
  when an attack legally targets the exposed printer. The full-match matrix below
  remains mandatory acceptance; this approval is not a test PASS.
- **Failure:** Any creature-target multiplier, base-HP change, fatigue, overtime,
  hidden defender bypass, mismatched receipt damage, or unapproved stat change falls
  outside this authority.
- **Disabled:** No additional pacing/fatigue rule may be stacked without a new traced
  design decision. Reward settlement remains disabled until a real Result.
- **Feedback:** The implementation must expose exact pre/post printer HP and applied
  x10 damage in the authoritative receipt/native UI.
- **Progression:** Approval itself changes no match, profile, XP, coins, save, build,
  or delivery state. Only an accepted exactly-once battle Result grants progression.

## Player-facing pacing contract

- **Entry:** A legal fresh-founder 40-card deck begins an offline bot match through
  the actual Battle/Begin controls, and the match reaches automatic attacks.
- **Player decision:** Choose legal Plan cards/targets and required print placement,
  then pull the existing Run Cycle; Concede remains an explicit defeat choice.
- **Result:** Creature combat remains unchanged. When every rival slot is empty, each
  direct strike applies ten times its normal integer damage to the printer; printer
  zero settles the existing result/reward transaction.
- **Failure:** A defender remains, stale intent, wrong phase/seat, missing attacker,
  duplicated callback, or rejected cycle applies zero printer damage. A pacing-matrix
  overrun is a failed balance gate, not an invented winner.
- **Disabled:** Printer focus is unavailable while any rival slot is occupied. Manual
  phase/Attack buttons, fatigue, sudden death, round-limit victory, and damage RNG
  remain absent.
- **Feedback:** Native printer HP, exact damage receipt, attacker/target contact,
  result, visible Back, and reduced-motion marker agree with the authoritative state.
- **Progression:** Only an exactly-once completed result grants the locked M9 coins/XP.
  Damage presentation, retry, Back, replay, and a failed/aborted audit grant nothing.

## Unified full-match fixture contract

This contract prevents a legacy-engine match, an unused accessibility difficulty
label, or a harness timeout from being reported as M9 pacing evidence.

### Authority and exact matrix

1. Build the player deck by taking a new profile through the public Founder v1
   choice, starter print, three ordered pack claims, and three Keep acknowledgements.
   Assert the resulting active deck is legal and has exactly 40 cards. Do not inject
   a hand, queue, field, printer HP, upgrade, or reward directly.
2. Launch the actual first playable bot route, Workshop Trial `first_layers_1`
   (`Warm Nozzle`), through `GameManager.create_unified_battle`. Supply a unique
   fixture-only `result_id` so launch does not consume a live launch sequence, and
   never call settlement. Assert the source active deck is the fresh-Founder deck and
   the player's opening hand plus remaining deck preserve its exact 40-card multiset.
   Assert the rival's opening hand, remaining deck, and preprinted slot preserve the
   route-generated encounter multiset; do not substitute a mirror or legacy opponent.
   The player has a base printer, no preprint, and no workshop mod.
3. Drive both seats for simulation through the current coordinator
   `next_ai_intent(active_seat)` -> `submit_checked(...)` path, which delegates to
   `UnifiedAIOpponent.next_legal_intent(state, seat)`. The current unified AI has one
   policy and accepts no difficulty argument;
   `AccessibilityRules.ai_difficulty` and legacy `BattleRules`/`SoloBattleFactory`
   results are not matrix dimensions or qualifying evidence.
4. Use the exact launcher seed inputs `[11, 23, 37, 53, 71]`. The launch route hashes
   mode/source/day/input into the authoritative battle seed, so report both the
   launcher input and returned `state.seed`; do not label the input as the battle
   seed. For each input, launch a fresh state, then force the opening pair before the
   first intent by setting both `starting_seat` and `active_seat` to `0`, and repeat
   from another fresh launch with both set to `1`. Do not swap them after play begins.
5. The required matrix is therefore exactly 30 full matches (`3 * 2 * 5`):
   Cinderpaw, Aquafin, and Voltwig; opener 0 and opener 1; and the five seeds above.
   Any future genuinely distinct unified AI policy requires a new
   named matrix dimension, but it is not invented for this M9 gate.
6. Apply every action through the checked unified rules/coordinator path used by the
   battle UI. Placement, attachment, overflow, and other pending choices must be
   resolved through legal intents. Calling legacy rules, mutating a queue/slot/HP to
   advance play, or invoking a UI callback directly invalidates the run. When a
   checked intent returns a presentation receipt, acknowledge that receipt exactly
   once before requesting the next intent; never disable the coordinator guard by
   editing `presentation_active`.

### Round and seat-turn accounting

`UnifiedBattleState.turn` is a **round number**, despite its name. It begins at 1 and
increments only after the second seat accepts Collect -> Draw and control returns to
`starting_seat`. A printer can reach zero during Attack before that round completes.
Record these separate counters:

- `rounds_started`: the maximum authoritative `state.turn` observed, including the
  terminal snapshot. The 30-round maximum and 12-22 median use this counter.
- `rounds_completed`: increment only on an accepted Collect -> Draw transition whose
  resulting active seat is `starting_seat`; for an unmodified match it equals
  `state.turn - 1` at the terminal snapshot.
- `seat_turns_started[seat]`: increment once when that seat's Draw phase is first
  advanced for a `(state.turn, seat)` pair.
- `seat_turns_completed[seat]`: increment once when that seat legally advances from
  Collect and passes control. An overflow discard in Collect does not complete the
  seat-turn; the later accepted advance does.
- `accepted_intents`: increment after each successful authoritative intent. Rejected
  intents are failures, not turns. Also record terminal revision so the repeated-run
  trace can detect duplicate or missing transitions. With a new revision-zero state,
  final revision must equal `accepted_intents`.
- `accepted_intents_this_seat_turn`: reset only when accepted Collect passes control;
  retain its maximum per seat. The current real rival loop allows 48 accepted checked
  actions during one continuous seat ownership. If seat 1 still owns priority after
  accepted action 48, classify the next required action as a UI step-budget failure;
  do not let the headless fixture silently continue as though the route could.

A match ending during the opener's Attack in round 30 has `rounds_started = 30` and
may have only 29 completed rounds; it passes the maximum. Calling this “30 complete
rounds” would undercount that terminal round and is forbidden in reports.

### Termination, overrun, and stalemate reporting

- The 30 matrix cases do not author Concede. A qualifying terminal has
  `state.finished == true`; the harness classifies `terminal_reason` as
  `printer_zero` only when exactly one printer is at or below zero and `winner` is
  the opposite seat. No further authority transition may be accepted. The state does
  not currently store a terminal-reason field, so the harness must not claim that it
  read one. A test/harness guard is never a game terminal.
- Crossing into `rounds_started == 31` while unfinished records
  `pacing_overrun_at_31`. Continue diagnostic simulation only up to the fixed
  `4096 accepted_intents` guard. A later printer-zero terminal is reported
  `terminated_late`; exhaustion while unfinished is reported
  `stalemate_or_guard_exhausted`. Both fail M9 pacing acceptance.
- An empty AI intent while its seat owns priority is `no_legal_intent`; a rejected
  intent is `rejected_intent`; an unresolved pending choice is `pending_stall`.
  Report the starter, launcher seed, authority seed, opener, last authoritative
  snapshot/revision, proposed intent, counters, and recent accepted-intent trace.
  None becomes a draw, win, loss, Result, reward, or profile settlement.
- `ui_step_budget_exhausted` means seat 1 remains active and unfinished after its
  48th accepted checked action in one seat-turn. It is a recoverable route pause in
  current UI behavior but fails this unattended playable-bot acceptance; it is not a
  match timeout or authority terminal.
- Separately create an isolated unified-rules state with empty decks through
  `UnifiedBattleState.create([], [], 11)`; do not empty a live matrix deck by
  mutation. Accept its legal Draw advance and assert that the empty draw changes
  neither printer HP nor `finished`/`winner`. Repeat through at least one later empty
  draw. This is the explicit no-fatigue regression; a timeout, guard, or deck
  exhaustion must never synthesize damage.

### Required evidence

1. Every one of the 30 non-Concede cases terminates at printer zero with
   `rounds_started <= 30`; the median `rounds_started` across the 30 is 12-22.
2. Report min/median/p95/max for `rounds_started`, `rounds_completed`, seat-turns,
   accepted intents, maximum accepted intents per seat-turn, attacks, defender hits,
   printer hits, and damage by target, plus each case's starter, launcher/authority
   seeds, opener, winner, terminal revision, and final HP.
   Sort each 30-value sample ascending: median is the arithmetic mean of zero-based
   indexes 14 and 15, and p95 is nearest-rank zero-based index 28.
3. Repeat all 30 cases and require byte-equivalent per-case authority traces and
   aggregate results. Presentation enabled/disabled and reduced motion produce the
   same authority traces.
4. In a separate route smoke, actual coordinate pointer/touch and keyboard-focus
   controls start a real offline bot match, play one Plan action, pull Run Cycle,
   resolve one required placement, and reach one direct printer hit. Direct callback
   or emitted-signal invocation is not interaction acceptance. This smoke confirms
   routing and input; it does not replace the 30-case unified pacing matrix.

The approval already authorizes the x10-only bounded M9 pacing rule. If any case
fails the 30-round maximum, the matrix median falls outside 12-22, or any case
produces a stall, implementation acceptance is blocked and the change is not
broadened: Sol returns the traces to design for one new human decision. Fatigue,
overtime, HP, AI policy, or another multiplier must not be selected automatically.

## Non-goals

- No base-HP change, creature damage rebalance, defender targeting change, manual
  phase, new reward, deck-size change, matchmaking, server, ad, IAP, or trading.
- No claim that legacy full-match logs qualify unified v3.1.
- No wall-clock guarantee from headless simulation; runtime presentation remains a
  separate finite-animation/accessibility gate.
- No physical-model, art, Android, build, device, DriveFS, or cloud claim.
