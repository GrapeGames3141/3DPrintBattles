# M11 pacing follow-up — evidence gate

Status: **BREAKTHROUGH INSUFFICIENT AND WITHDRAWN; NO REPLACEMENT RULE APPROVED**

Date: 2026-09-08

This records the corrected 200-HP pacing result and a read-only counterfactual. It
authorizes no runtime, balance, card, AI, save, or reward change.

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
