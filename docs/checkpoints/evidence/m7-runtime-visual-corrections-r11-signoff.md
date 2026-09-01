# M7 runtime visual corrections r11 sign-off

Status: **PASS - static runtime visual review; P0 none / P1 none; regression, exact-
commit export, device, and Drive evidence pending**

Date: 2026-09-01

This non-overwriting sign-off closes the visual HOLD states defined in
`m7-runtime-visual-corrections-hold-v1.md`. The HOLD document remains the historical
problem/acceptance contract.

## Exact r11 evidence

- Manifest:
  `build/evidence/m7-blueprint-runtime-promotion/captures-r11-final/manifest.json`
- Manifest SHA-256:
  `7F2A6FF9A1FA8994FAB4CAC66FFF91EDB45C7B26A001AD498148247BEBC3AC04`
- Runner ledger:
  `build/evidence/m7-blueprint-runtime-promotion/captures-r11-final/runner-ledger.json`
- Runner-ledger SHA-256:
  `DA672BEF4A332A1F99B926AB3230788BF1D73EBEABD886517BF2EACD44A1CFB1`

The manifest records **20/20** fresh nonzero Forward+ PNGs: ten at 576x1024 and ten
at 720x1280. Requested dimensions and per-capture SHA-256 matched; semantically
distinct states have unique hashes; all 20 fixture consoles exited `0`; retained
log/stdout/stderr inspection was clean; expected profile mutation is `0` for every
entry; production bottom reserve is `0`; and no synthetic host inset is used.

| Closed HOLD area | r11 capture IDs | Coverage |
| --- | --- | ---: |
| First Print cartridge | `M7-RV-01-FirstPrintCartridge`, `M7-RV-01-FirstPrintCartridge-150Text` | 3 |
| Deck parchment/targets | `M7-RV-02-DeckWorkbench`, `M7-RV-03-DeckWorkbench-150Text` | 4 |
| Workshop hit/focus | `M7-RV-04-WorkshopHotspots`, `M7-RV-05-WorkshopFocusTraversal` | 4 |
| Active Print instruments | `M7-RV-06-ActivePrint60`, `M7-RV-07-ActivePrint60-150Text`, `M7-RV-08-ActivePrint60-HighContrast` | 6 |
| Reduced-motion battle end | `M7-RV-09-BattleEndReducedMotion`, `M7-RV-10-BattleEndReducedMotion-HighContrast` | 3 |
| **Total** | | **20/20** |

The source field is `f9d1934+working r10 correction diff`. This is valid static visual
evidence, but it is not clean exact-commit export evidence.

## Closed visual contracts

### First Print cartridge blueprint legibility/material

- **Entry:** Deterministic First Print fixtures show an empty bed and docked Cinderpaw
  blueprint at 576x1024, 720x1280, and 150% text.
- **Player decision:** Read-only review evaluates the existing inspect/continue/back
  presentation; it adds no gameplay choice.
- **Result:** PASS. The intact Cinderpaw blueprint is legible as ink integrated with
  the physical cartridge/paper, not a pasted opaque card; native labels and controls
  retain hierarchy at default and 150% text.
- **Failure:** The HOLD failures—washed-out ink, opaque sticker, clipped identity,
  baked label, finished creature, or unreadable value—are not present in the admitted
  r11 frames. Any future recurrence invalidates this visual closure.
- **Disabled:** This visual result does not alter first-print prerequisites or enable
  unavailable actions.
- **Feedback:** Cartridge material, blueprint contour/datum, native labels, and focus
  read as one physical pre-print object at both sizes.
- **Progression:** All three fixtures declare zero expected profile mutation; exactly-
  once first-print progression remains outside static review.

Deterministic fixture/test closure: `m1_first_print_setup` and
`m1_first_print_text150`, three recorded exit-0 entries.

### Deck parchment-consistent thumbnails and target hierarchy

- **Entry:** Legal saved-deck fixtures with three populated Pre-Print clamps run at
  both sizes under default and 150% text.
- **Player decision:** Review existing blueprint inspection, Back, Save, and Pre-Print
  seats without changing deck state.
- **Result:** PASS. Blueprint thumbnails share the physical parchment language, remain
  readable, and Back/Save/Pre-Print targets preserve the required >=48-logical-pixel
  physical hierarchy and label-safe focus.
- **Failure:** No mismatched sticker, clipped thumbnail, focus/label collision,
  undersized/dead target, or premature Save mutation is visible in the admitted set;
  recurrence reopens the HOLD.
- **Disabled:** Illegal/invalid actions retain noninteractive treatment; Back remains
  zero-mutation.
- **Feedback:** Default and 150% states keep native legality/count/selection labels
  and physical control ownership readable.
- **Progression:** All four deck fixtures expect zero profile mutation; save semantics
  are unchanged and require separate regression evidence.

Deterministic fixture/test closure: `M3-DK-06` at both sizes, default and
`--m7-text150`, four recorded exit-0 entries.

### Workshop transparent physical hit regions and inset focus

- **Entry:** Completed-profile Workshop default and printer-focus traversal fixtures
  run at both sizes.
- **Player decision:** Review the six existing physical destinations and the
  keyboard/controller focus seat.
- **Result:** PASS. Hotspots read as transparent interaction regions owned by physical
  Workshop objects; the printer focus is inset, four-edged, and does not become stock
  button chrome or cross neighboring scenery.
- **Failure:** No opaque button plate, dead/misaligned visual hotspot, clipped/outset
  focus, or wrong visual ownership remains in the admitted frames; any future route/
  callback mismatch remains a regression failure even if a still looks correct.
- **Disabled:** Static review does not enable an unavailable route or prove every live
  callback; those remain governed by deterministic interaction tests.
- **Feedback:** Physical ownership and focus are clear at 576x1024 and 720x1280 with
  native destination labels/accessibility retained.
- **Progression:** All four fixtures expect zero mutation; accepted route transitions
  retain their existing one-transition semantics.

Deterministic fixture/test closure: `m1_workshop` and
`m1_workshop_focus_printer`, four recorded exit-0 entries.

### Active Print physical instruments and occupied composition

- **Entry:** Exact 60% Active Print fixtures run at both sizes under default, 150%
  text, and high contrast.
- **Player decision:** Review existing status/skip presentation; no print decision is
  added.
- **Result:** PASS. Dynamic values sit in physical workshop instrument plates, the
  printer bed remains primary, the composition has no dead glass void, and the
  solid-below/wireframe-above print state stays legible across all three modes.
- **Failure:** No floating stock label, dead glass expanse, generic panel, value/plate
  escape, covered print, finished creature, or incorrect 60% state remains; recurrence
  invalidates this closure.
- **Disabled:** Pre-completion claim remains disabled and no visual change bypasses
  authoritative print state.
- **Feedback:** Native 60% status, physical plate ownership, 150% values, and high-
  contrast semantics remain readable without relying on motion or color alone.
- **Progression:** All six fixtures expect zero mutation; the exactly-once print
  transaction is unchanged.

Deterministic fixture/test closure: `m6_active_print60`,
`m7_active_print60_text150`, and `m7_active_print60_contrast`, six recorded exit-0
entries.

### Reduced-motion battle end preserves combat readability

- **Entry:** The deterministic reduced-motion end frame is captured at both sizes,
  plus high contrast at 720x1280.
- **Player decision:** Observe Run Cycle; no manual Attack, target, damage, or phase
  choice is introduced.
- **Result:** PASS. Player Cinderpaw remains visible, damaged Aquafin remains
  identifiable, and both printers/HP plus player and rival hands remain readable in
  the held end frame.
- **Failure:** No missing creature, ambiguous damage owner, cropped HUD/hand, early
  result takeover, duplicate intent, or motion-dependent-only meaning remains; any
  recurrence reopens the HOLD.
- **Disabled:** Plan, hand actions, and Run Cycle reactivation remain visually locked
  during resolution; rival cards remain concealed.
- **Feedback:** Stable contact/damage posture, native HP/damage event hierarchy, and
  high contrast preserve the finite result handoff without requiring animation.
- **Progression:** All three fixtures expect zero mutation. Authoritative attack,
  battle-result, and reward revisions remain exactly once and require regression
  verification beyond this static gate.

Deterministic fixture/test closure: `m2_battle_reduced` and
`m7_battle_reduced_contrast`, three recorded exit-0 entries.

## Reviewer verdict and immutable scope

Formal original-resolution r11 visual review: **PASS — P0 none / P1 none** for the
five scoped HOLD corrections.

The pass preserves portrait-only presentation, zero no-AdMob reserve, native dynamic
text/accessibility, approved blueprint identity, Plan -> Run Cycle, existing print/
awaken/attack animation authority, deterministic integer gameplay, and the existing
profile/save schema. It authorizes no gameplay, deck, ownership, economy, reward, or
schema change.

## Evidence still pending

This is static runtime capture approval only. It does not claim or substitute for:

- final full deterministic/backend regression from the eventual reviewed commit;
- a staged/reviewed exact commit and clean E:-based export worktree;
- Android export, signing, package/version/arm64/portrait/archive/no-AdMob APK audit;
- physical-device install, launch, animation, safe-area, or log evidence;
- a non-overwriting APK/README copy to Google Drive with source/destination byte and
  SHA-256 equality; or
- confirmed cloud visibility, which remains separate from DriveFS copy success.

M7 release/milestone delivery remains pending until those independent gates are
truthfully completed or conditionally reported as blocked where authorized.
