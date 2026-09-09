# M11 UI1 scene alignment audit

Scope: the user's scene-by-scene text/art alignment request, specifically the
bottom-right battle control. Preserve the approved visual family, native controls,
gameplay, saves, and facing direction. No new balance rule or Android review build.

Contract: [UI polish](../design/m11-ui-polish-v1.md).
Baseline index: [13 actual routes](../../build/evidence/m11-ui-scene-audit-20260908/index.html).
Baseline is current worktree at65ec86a, before UI1 changes, not the generated concept.
All13 Forward+576x1024 runs exited0 with isolated E:QA and OS data and exact-PID
cleanup. NoP0 in read-only review. Captures prove rendered states only; their fixture
also activates each route's Back/Continue owner, not all screen actions.

## Corrections accepted for implementation

| Route | Observed defect | Correction |
| --- | --- | --- |
| Battle Plan | Generic button adds a second frame to the existing lever mount; hand title crosses bevels; Idle0t reaches gauge rim | Single baked mount owner, inner mechanism/native text seat, measured card/gauge text |
| Workshop | Dais text crosses ring; Printer on rail/glass; Supplies on seam; Settings on reflective knob | Native captions seated on attached physical faces, same hotspot owners |
| First/Active Print | READY/READY NOW duplicate; currency resembles active action; action copy/focus not centered on whole plate | STATUS/READY, explicit inert balance instrument, full-face labels and focus |
| Archive | Two paging glyphs float at circular control edges | Coherent page dial/readout with measured directional hit zones |
| Deck | PRE/SAVE overflows tiny keycap | One wider physical Save Preprints face; preserve separate save callbacks |
| Market | Categories detached from selector wells; price/status left-biased | Labels and selected/focus state tied to each selector; one centered status block |
| Founder pack1/3 | KEEP on knob, CARDS below it | One contained native label/hit owner |
| Result | Continue above face center; optional reward wells blank | Whole-face centered Continue; deliberate neutral absent-reward state |
| Title | Text-only focus box detached from larger action face | One full-face focus owner |
| Starter | Confirm150 has insufficient rim clearance | Measured centered native text, unchanged selection |
| Settings | No fresh576P1; Back small but contained | Preserve behavior; verify consistency after shared helper edits |

P2 follow-ups: consistent HUD seating, full tooltips for truncated Deck names,
Archive filter-rail baselines. Do not claim these all resolved without reviewing
the actual captures. Missing baseline states (inspectors, preflight, recovery and
dirty exits) need fixture coverage before whole-game visual sign-off.

## Art selection and gate

[Lever correction record](../art/m11-living-battles-20260908/LEVER-CORRECTION.md)
contains all prompts and source links. Two failed RGB checkerboards are rejected.
The deliberately opaque inner-aperture derivative has compatible material and no
new outer frame. Read-only review requires an aspect-preserving crop that removes
its worn perimeter and fits only the existing dark aperture. Primary selects this
narrow derivative for a runtime proof; final mounted576/150HC review remains open.

## Validation gate — original implementation plan

Re-capture altered scenes at576normal and150HC/reduced motion,720portrait and
tall-safe. Review actual labels against their art faces, not just control rectangles.
Run focused actual viewport-input checks for relocated owners, especially Run Cycle,
Archive paging, Market selectors, Founder Keep and independent Deck save actions.
Keep physical-device touch/lifecycle, native ads, pacing, directional sprite playback,
and final Android export as separately unverified work.

### Early UI1 review (historical; superseded by the final checkpoint below)

Battle lever/hand r4 normal and150HC captures pass read-only visual review with
noP0/P1. Evidence: `build/evidence/m11-ui1-20260908/writer/battle-lever-r4-576/`
and `battle-lever-r4-576-hc150/`. NativeRUN fits the small aperture at12/18px;
full Run Cycle description remains accessible. Focus/pressed/720/tall remain open.
Workshop r5 normal/150HC nameplates fit after widening the mounted faces. The 150%
progress heading still needs compact copy. Other route corrections remain open.

Primary rejected the initial Deck label-only widening: its physical keycap did not
widen, so the label crossed hardware. The replacement must own a matching physical
face and separate hit area. The UI review's alternative stacked32px faces was also
rejected because two primary56px hit areas would overlap in that band. The bounded
correction retains side-by-side actions and uses `SAVE / PRE- / PRINTS` inside a
larger right-hand plate, with the full native Save pre-print loadout description.

The first M2 test adaptation replaced line fit with whole-viewport containment;
primary rejected that weakened evidence. Font-metric checking then exposed an actual
4px queue-head overrun. Correct the measured cream-face geometry and retain that
stronger assertion. M1's retired Forge/Title/Settings node expectations need equivalent
current-route checks, not restoration of the old UI or removal of behavior coverage.

Primary independent UI1 core checks passed: `rules-shared-hp-constants-r1` PID76920,
`authority-receipts-ui1-r1` PID97512, `manifest-paths-ui1-r1` PID101420, all exit0,
no unexpected project errors, E:-isolated QA/OS data, exact PIDs gone/no new dialogs.
These check sharedHP constants (unchanged200/+50), transactions and runtime asset
paths, not UI interaction. The reviewed Iron Gem raw/blueprint filename mismatch
was corrected to the existing underscore filenames without duplicating assets.

Primary `management-input-r1` PID110572 passed on the intermediate UI1 tree: rendered
M3 pointer/focus paths for Archive, Market and Settings, with E:-isolated data, exit0,
no unexpected errors and exact-PID cleanup. It is not final-geometry evidence;
Run Cycle, independent Deck saves and pack/starter actions still need their own checks.

Primary `canonical-back-input-r1` PID109588 passed the existing M9 real mouse/touch,
KEY_BACK and window-Back routing regression on the intermediate UI1 tree. Exit0,
no unexpected errors, isolated E: paths and exact-PID cleanup. This is desktop input
evidence, not an Android handset lifecycle/touch claim. The M3 test also exercises
pack Keep through focused ui_accept and Result Continue through a real pointer.

## UI1 reviewed checkpoint evidence

The final capture collection is [runtime comparisons](../../build/evidence/m11-ui1-20260908/index.html).
It exposes the original baseline, 13 main routes at 720x1280, their normal and
150%-text/high-contrast 576x1024 proofs, and additional battle/pack states. Labels
remain native; no generated text is used. The new ImageGen lever insert is the
only new runtime raster. Workshop nameplates, Deck's wider pre-print face, Market
caption rail and corrected battle decision keys reuse approved parchment art.

The final Deck pre-print key has a real 78px-wide physical plate with 6px side
rims and 66px unscaled ink seat. Native font18 at 150% has a measured three-line
stack of 66px within 72px, with PRINTS 63px wide. The independent Save Deck and
Save Pre-Print callbacks, non-overlapping 56px-minimum owners and persisted values
remain separate. Market uses Plan/Card/Pack/Mod/Skin in five original selector
owners, full spoken category names, a passive selected/focus underline, and an
unscaled 12-to-18px native caption layer. Archive primary navigation and filters
now honor the same text scale. No inventory, category ID or progression change.

Primary independent Forward+ runs passed on the frozen core alignment tree:

| Run under `build/evidence/m11-ui1-20260908/root/` | PID | Evidence |
| --- | --- | --- |
| `m1-ui1-final` | 116456 | Workshop/Title/empty Forge navigation and profile preservation |
| `m2-ui1-final` | 119004 | Battle geometry, font metrics, privacy, disabled/recovery states |
| `m3-ui1-final` | 67744 | Real viewport pointer/focus; independent deck/pre-print persistence; pack Keep; starter Confirm; Run Cycle lock |
| `back-ui1-final` | 125252 | Mouse/touch, KEY_BACK and window-Back dispatcher parity |
| `manifest-ui1-final` | 124044 | Promoted asset identity and corrected existing Iron Gem paths |
| `integration-ui1-final` | 71576 | Ordered FIFO deployment and attack contact through coordinator/Main/stage |

All six exited0, recorded isolated E: QA and OS user data, no unexpected project
ERROR, exact process cleanup and no new error-dialog process. M3 proves a real
Run Cycle press begins a checked cycle and rejects a stale disabled press; it
does not prove an entire button-to-rival-match session. Integration separately
proves receipt playback, not a full match or physical Android device.

13 normal 720 captures and four tall captures completed with the same strict
runner. Read-only UI review passes the changed label/control geometry at normal,
150% HC, 720 and the tested tall layouts. Battle focus/disabled states pass.
The first pressed-state image was identical to idle: adding a post-draw wait and
asserting actual native pressed/hover ownership still reproduced the failure, so
the final correction darkens the inner mechanism and native caption while held. It does
not add an outer frame or change the action. Extended capture QA also corrected
oversized Workshop pack tickets and Concede/Queue/Cancel material mismatches.

### Evidence limits and remaining release work

- Battle's direct full-screen renderer bypasses the existing synthetic top-inset
  boundary. Its `final-tall-safe-hc150` filename describes requested fixture flags,
  not proof that the 24px inset was applied. It proves tall composition only.
  Forge/Deck/Market visibly apply that synthetic inset. Battle safe-area handling
  and Android device verification remain release work; do not mark them passed.
- Unchanged legacy card microcopy/HUD styling and the full set of inspector,
  dirty-exit, failure and long-copy combinations are not whole-game visual approval.
- Preserve no-AdMob/reserve0 configuration. No banner geometry is certified here.
- Full facing-inward animated resources, B2 performance/art coverage, pacing,
  M11-C and final Android validation remain separate. Guard-only is not approved.
- This is a source/UI checkpoint. No version bump, Android export, new review APK
  or new Drive APK was produced. The shipped APK remains 0.8.9/code105.

Maintainability review: native ink is separate from decorative raster transforms;
existing callback/transaction ownership is preserved; no new per-frame UI polling,
ad dependency, timer, save schema or combat rule is introduced by this pass. The
large source lever raster remains provenance-quality; packaged import/GPU-cost
optimization belongs to the B2 release audit, not a claimed performance benchmark.

### Final interaction-state acceptance

Read-only r14 spot review passes held Run press, available/recovery Founder tickets,
Queue/Cancel and Stay/Concede in normal/150% HC with no remaining P1 in this bounded
set. The ineffective pressed StyleBox and its false-positive metadata assertion
were removed. The capture now checks actual hovered ownership, held native pressed
state and visible insert/caption modulation after post-draw; synthetic release is
cancelled outside the hit target before teardown.

Final primary reruns after these last source changes all passed: M1 PID124164,
M2 PID114636, M3 PID103456, held press normal PID121288 and HC150 PID91996,
Workshop recovery HC150 PID110956 and available Founder ticket HC150 PID105412.
Evidence is under `root/*-state-final*` in the UI1 collection. Each exited0 with
isolated E: data, no unexpected ERROR, exact PID gone and no new error-dialog
process. The earlier recovery-HC run was correctly rejected for a fixture guard
that expected PackKeepLabel on the Workshop; the final guard validates the actual
Workshop ticket, retained150 settings and corresponding native18 font instead.

This closes the measured UI1 main-screen and listed interaction-control alignment
defects. It does not close the release limitations above or expand approval to a
new battle rule, directional animation set, or Android build.

Final elevated process inventory found no UI1-owned Godot process or error-dialog
process. The sole visible Godot export belonged to another project and was left
untouched. Failed ImageGen checkerboard candidates remain local provenance only;
they are neither runtime assets nor part of this checkpoint's staged source set.
