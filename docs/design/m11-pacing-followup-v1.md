# M11 pacing follow-up — evidence gate

Status: **BREAKTHROUGH INSUFFICIENT AND WITHDRAWN; NO REPLACEMENT RULE APPROVED**

Date: 2026-09-08

This records the corrected 200-HP pacing result and a read-only counterfactual. It
authorizes no runtime, balance, card, AI, save, or reward change.

The separately approved facing-inward visual direction—friendly backs aimed up-board,
rival fronts aimed down-board—does not approve Guard-only blocking, target-policy
changes, or any other pacing rule.

## Final evidence

Source: `build/evidence/m11-a-20260908/pacing-r4/qa-save/m11-pacing-results.json`.
The r4 matrix includes the corrected full-attack-before-staged-deploy timing.

- Actual 30-case result: 41 minimum / 64 median / 98 p95 / 100 maximum rounds
  started; 0/30 meet the <=30-round gate.
- First creature defeat occurs at median round 4, while first legal printer strike is
  median round 48.
- The final trace records median 263.5 defender hits versus 39 printer hits and median
  1,127.5 defender damage versus 250 printer damage.
- Adding each recorded defeated defender's `neutral_printer_damage` to the recorded
  baseline as a fixed-policy, trace-only Breakthrough estimate yields 27 minimum /
  58.5 median / 88 p95 / 89 maximum rounds; only 2/30 are <=30.

The estimate is diagnostic arithmetic, not a runtime simulation: it does not model
earlier termination feeding back into later authority or policy. It is still strong
evidence that one normal printer strike per creature defeat is too weak to justify as
the 12–22/<=30 solution. The earlier Breakthrough recommendation is withdrawn, remains
unapproved, and must not be implemented or combined with a silent retune.

Printer HP alone cannot fix the measured delay because current authority forbids a
printer target while any defender exists. Nineteen of the initial 30 traces did not
reach their first legal printer strike by round 30; reducing post-exposure HP cannot
move that opening contact.

## Policy coverage and limits

The r4 result is an actual result for the current shipped bot policy, but it is not a
balanced sample of every legal player tactic:

- `_main_intent` never returns a spell. Across the 30 recorded traces, 1,888 card-play
  intents include 1,167 creatures, 181 equipment, 360 filament, 90 traps, and 90
  upgrades, but **zero spells**. Every authored Founder deck includes Layer Melt,
  Print Jam, Spool Drain, Forge Surge, Emergency Reprint, and Blueprint Thief. Layer
  Melt can deal 150 creature damage and Forge Surge can strengthen a living attacker;
  the others can alter queue, filament, or creature supply. Some would accelerate
  clearance and some could add delay, so their net pacing effect is unmeasured.
- The AI emits zero `activate_ability` intents, but this does not currently omit a live
  catalog option: all 24 catalog creatures use automatic `attack`-trigger abilities
  and none has a `main` trigger. Those authored attack abilities already resolve
  through normal attacks.
- All 1,167 recorded creature plays omit a stance and therefore use default Attack;
  the traces contain zero Guard queues and zero `switch_mode` intents. `_attack_intent`
  always targets the first occupied defender before the printer.

These limits do not invalidate the slow result: this is the real bot policy players
currently face, and that policy produces 41–100-round games. They do mean the matrix
cannot by itself establish how a player or representative policy using offensive
spells and Guard choices would pace. Changing spell use, stance choice, or target
priority is an AI-policy change and is not authorized by this diagnostic.

## Next product decision — separate bounded rule experiment

- **Entry:** The corrected 200-HP authority is deterministic and the pacing matrix has
  failed; approved UI/presentation integration does not depend on selecting a new
  combat rule.
- **Player decision:** Explicitly approve one separately specified, player-readable
  pressure rule for measurement, defer balance work, or explicitly revise the pacing
  benchmark. Examples such as Guard-based shielding or spatial lane pressure are only
  design candidates, not recommendations or authority.
- **Result:** Only the exact approved candidate may receive a bounded deterministic
  experiment and the same 30-case report. No candidate is promoted merely for
  outperforming Breakthrough.
- **Failure:** If an experiment misses the gate or weakens the printed-creatures-fight
  vision, stop at evidence and return for a product decision. Do not stack HP changes,
  multipliers, fatigue, AI policy changes, or additional mechanics.
- **Disabled:** Until an exact rule is approved, all new balance implementation and
  release pacing sign-off remain disabled. The corrected 200-HP rule is the comparison
  baseline.
- **Feedback:** Any future pitch must state its plain-language rule, automatic target
  order, Guard/Attack interaction, staged timing, forecast copy, and deterministic
  acceptance before code changes. Results must distinguish simulation from trace-only
  estimation.
- **Progression:** A design choice or diagnostic grants nothing. Existing exactly-once
  rewards, saves, settlements, ownership, decks, and print receipts remain unchanged.

The current candidate awaiting the user's response is a reversible **Guard-only
blocking** comparison: a living Guard shields the printer; without a Guard, automatic
printer pressure may occur while Attack creatures remain on the field. It is not
approved. Its central risk is reducing creature-on-creature combat into a printer race,
so any authorized comparison must report creature hits and printer hits as well as
round count and must be discarded if it undermines the living-creature fight promise.
With the current bot unchanged, the comparison also has no clean interpretation: if
its explicit first-defender target remains authoritative, Guard-only blocking changes
nothing; if the new rule forces printer targeting whenever no Guard exists, both bots'
all-Attack policy removes nearly all creature fights. Teaching the bot to choose Guard
would be a second, separate policy decision. Therefore Guard-only blocking should not
be endorsed or measured until its target semantics and policy boundary are explicitly
approved together.

The nonnegotiable design boundary is unchanged: printed whimsical creatures awaken
and visibly fight, combat remains an automatic cycle without extra manual phases, and
the solution cannot be an arbitrary damage multiplier or fatigue clock.

## Independent UI and release boundary

The failed pacing gate does not revoke approval of the r7 battle atlas, living-creature
composition, visible printing/awakening/attack presentation, alignment, Back behavior,
deck assistance, or tutorial work. Those UI and presentation changes may proceed and
be reviewed independently. Final balance acceptance and release/Drive APK approval
remain blocked until a pacing direction is explicitly chosen and measured successfully,
or the user explicitly changes the benchmark.
