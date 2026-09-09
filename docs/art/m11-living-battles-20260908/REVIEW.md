# M11 concept review record

These are offline HTML composition reviews, not Godot or gameplay test results.
The user approved the exact selected r7 supplement on 2026-09-08. Runtime integration
and its evidence remain pending.

## Floor master v1

Read-only UI review: no P0. Continuous navy workshop floor replaces all six raised
cream platforms. Printer, instrument, hand, and material architecture is preserved.
No fixed ground slots need to be baked. A short awakened-creature hop followed by
a grounded walk is acceptable if launch, airborne clearance and landing are explicit.

## Earlier composites — not approval targets

- Initial captures: rejected for text on rims, tiny labels, absent rival backs,
  print over the roof, and a step-off crossing the status plaque.
- r2/r2b: material and print containment improved. Remaining P1: fake HC150 scaling,
  friendly captions on the mat rim, unreadable small copy and a black top band.
- r3-critical: normal scene, 60% split, awakening and landing direction pass.
  HC labels/turn, launch continuity and physical lever treatment still needed fixes.
- r3 full set: primary review additionally found that awakening retained both raw
  and living layers, launch was already over the roof, creature contact remained in
  the attacker's home position, printer contact incorrectly retained defenders,
  and some HC text was enlarged by less than 150%. These are rejected examples,
  not evidence that the game or final composition works.
- r5 full set: all 15 states reviewed at original and 576x1024, with 720x1280
  checks for contact/equipment/accessibility. No P0; the floor, public rival print,
  single-owner awakening and chamber -> hop -> mat route passed. Three P1s remained:
  friendly HC captions touching the brass rim, HC lever copy too close to the bottom,
  and equipment target/readiness text too small. Hand-copy overlap was a P2.
- r6: only direct printer-contact composition changed. Voltwig was moved to reach
  the rival printer casing; rival defenders remain absent and no invented damage
  is shown. This does not prove a working runtime impact animation.

## Final review requirements

Review the corrected full set at original resolution and phone scale. Every named
state must show what its label claims; critical-frame review alone is insufficient.
Verify actual 150% computed text sizes and contained reflow, one creature owner,
mouth -> airborne clearance -> landing -> joined continuity, visible attack contact,
empty defender field for a direct printer hit, truthful public queue information,
and readable hands/instruments/Back/Run Cycle. No P0/P1 may remain before visual
sign-off. This does not waive later actual Godot, authority, Android or device tests.

## Selected r7 — 2026-09-08

Read-only UI reviewer verdict: **PASS for user battle-art approval; P0 none, P1 none.**
Human approval: **PASS on 2026-09-08 for the exact r7 battle-only supplement shown in
chat.** Controlled floor promotion and runtime integration may proceed under M11; this
is not approval for another art revision or a broader full-game redesign.

The reviewer carried forward the complete 15-state review, accepted the r6 printer
contact correction, then inspected r7 equipment/HC at all three sizes plus populated
and Print60 hand spot-checks. Root independently checked the corrected phone images,
the source/renderer diff, and hashes for all 39 inherited PNGs (zero mismatches).

- Friendly HC captions now clear the floor rim by 28 design pixels; the lever caption
  ends at design y1612 of 1672, with no fabricated ad reserve.
- Unit, hand, Back, lever, resource and status font ratios are each 1.5 in the
  offline DOM checks. Back's design hit height is 80 and lever's is 157.
- Equipment's primary native status names both the ready item and eligible creature.
- Floor, print20/60, public rival print, raw completion, single-owner awakening,
  launch, airborne clearance, mat landing, living field and both contact types are
  compositionally coherent. Existing characters and card back are preserved.
- Non-blocking P2s: normal hand guidance grazes the lower thumbnail edge; gear-tray
  detail is small but redundant. Refine these native placements during integration.

Selected evidence: 45 PNGs in `captures/r7/`, 39 hash-verified inheritances and six
recaptures. The current render ledger records Node 71432 and Edge 70184; Edge exited,
the PID query was known/empty after close, and its exact E:-based profile was removed.
No Godot process or game/editor window was launched for this concept checkpoint.

No runtime files, game settings, Android version or APK were changed. Animation
timing, safe-area behavior, interactions, native accessibility, deterministic state
and shipped Android behavior remain mandatory later tests, not claims of this review.
