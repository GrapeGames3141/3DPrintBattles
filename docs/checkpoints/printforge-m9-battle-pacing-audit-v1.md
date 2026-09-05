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

## Required decision evidence

Before implementation acceptance, run a new unified-authority full-match matrix through the same
one-intent coordinator used by the UI:

1. Use each of Cinderpaw, Aquafin, and Voltwig as fresh founder starter, the exact
   legal founder 40-card deck, all fixed bot difficulties exposed by M9, both opening
   seats, and at least five fixed seeds per starter/difficulty/opening combination.
2. Drive player and rival with deterministic legal-intent policies; exercise required
   place, attach, and overflow decisions rather than modifying state directly.
3. Require every match to finish at printer zero or an explicit test-authored Concede;
   no guard expiry, empty intent, illegal intent, pending-decision stall, duplicate
   result, or fabricated timeout winner.
4. Require every non-Concede match to finish within 30 complete rounds, with median
   length between 12 and 22 complete rounds. Report min/median/p95/max round count,
   accepted intents, attack count, defender hits, printer hits, damage by target,
   opening seat, winner, and final printer HP.
5. Repeat the matrix and require byte-equivalent aggregate results and per-seed winner/
   revision traces. Presentation on/off and reduced motion produce identical authority.
6. Real coordinate pointer/touch and keyboard focus smoke tests start one match, play
   one Plan action, pull Run Cycle, resolve one required placement, and reach one
   direct printer hit. Direct callback/emitted-signal invocation is not interaction
   acceptance.

The approval already authorizes the x10-only bounded M9 pacing rule. If its matrix
fails the 30-round maximum or produces a stall, implementation acceptance is blocked
and the change is not broadened: Sol returns the traces to design for one separately
approved fatigue/overtime contract.

## Non-goals

- No base-HP change, creature damage rebalance, defender targeting change, manual
  phase, new reward, deck-size change, matchmaking, server, ad, IAP, or trading.
- No claim that legacy full-match logs qualify unified v3.1.
- No wall-clock guarantee from headless simulation; runtime presentation remains a
  separate finite-animation/accessibility gate.
- No physical-model, art, Android, build, device, DriveFS, or cloud claim.
