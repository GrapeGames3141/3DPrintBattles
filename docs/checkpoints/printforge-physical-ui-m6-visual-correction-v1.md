# PrintForge physical UI M6 visual correction checkpoint v1

Status: scoped layout/state implementation and UI review PASS; complete v2 blueprint
family, human approval, and runtime promotion pending

Date: 2026-09-01

Authority: `docs/design/printforge-legends-mechanics-v3.1.md`,
`docs/checkpoints/printforge-physical-ui-m2-battle-v1.md`,
`docs/checkpoints/printforge-physical-ui-m3-blueprint-family-v3.md`,
`docs/checkpoints/printforge-physical-ui-m5-no-ad-delivery-v1.md`, and the accepted
pilot ledger at
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/README.md`.
This checkpoint changes presentation only. It changes no catalog value, ownership,
deck, Pre-Print, print, battle, reward, economy, profile, or save rule.

## Supersession and gate

The user-rejected v1/v3 blueprint images and their exploded, detached-part, multiple-
view, navy-card, or baked-card grammar are historical evidence only. They are not
runtime candidates and must not be used as a fallback. The UI-reviewed v2 pilot is
the current visual authority:

- exactly one complete, intact creature;
- a clean right-facing orthographic/profile print-plan elevation;
- one build-plane baseline;
- no more than four sparse supports, each physically connected from the build plane
  to a real overhang;
- one restrained horizontal scan datum; and
- warm ivory/pale-cyan ink on a genuinely transparent RGBA field so the owning paper
  surface remains visible.

The accepted Cinderpaw, Aurorawing, and Worldcoil pilots prove quadruped, winged, and
coiled grammar only. They do not constitute a reviewed 24-creature family. Every
remaining catalog creature must be authored to the same grammar and receive
original-resolution, read-only UI review before runtime promotion. Unavailable or
unreviewed mappings use a clearly noninteractive native placeholder; they never fall
back to a rejected v1/v3 image and never crash.

M6 implementation is authorized only for the decision-complete layout and state
corrections below. Runtime promotion of a complete blueprint family remains gated on
the complete reviewed set. Generated mockups remain composition references until
reviewed; native Godot owns all dynamic names, values, state, labels, focus, and
accessibility text.

## Locked product boundaries

- Portrait is the only supported presentation. Required evidence is 576x1024 and
  720x1280, plus the explicitly named 1080x2400 tall fixture below.
- The no-AdMob M5 contract is authoritative. The Godot usable surface has zero ad
  reserve at every size; no ad strip, creative placeholder, or simulated ad-safe
  band may consume authored content.
- Battle remains Plan -> Run Cycle. Draw, Main, Print, Attack, and Collect retain
  their deterministic order and values, but are not restored as manual phase
  buttons.
- Blueprint is the pre-print state; solid/raw plus wireframe is the extrusion state;
  the existing animated creature sprite is the awakened battlefield state. These
  representations are never substituted for one another.
- Existing character art, animated sprites, support-card art, and card back remain
  unchanged.
- Touch targets remain at least 48 logical pixels; primary actions remain at least
  56. Native focus must show all four edges. The 150% text, high-contrast, and
  reduced-motion contracts remain mandatory.

## Decision-complete feature contracts

### M6-BP-01: intact transparent blueprint representation

- **Entry:** A route requests a creature blueprint before extrusion in Starter,
  Archive, Deck/Pre-Print, Forge, player battle hand/queue, or a blueprint reward.
- **Player decision:** Inspect, focus, select, queue, or dismiss the blueprint through
  the route's existing legal action; the image itself introduces no new decision.
- **Result:** The route presents exactly one intact right-facing profile creature on
  one build plane, with only necessary connected supports and one scan datum. The
  transparent ink is integrated into the route's physical paper surface. All names,
  values, selection state, and action labels remain native.
- **Failure:** Missing, malformed, opaque-background, rejected-version, or unreviewed
  art produces a native unavailable placeholder and a diagnostic; browsing and route
  exit continue with zero mutation. No substitute creature or old v1/v3 card appears.
- **Disabled:** An unavailable mapping and any action illegal under existing
  ownership/deck/print rules are visibly disabled and do not resemble an active
  physical control.
- **Feedback:** The intact silhouette, connected support contact points, single scan
  datum, transparent paper integration, native state label, and complete four-edge
  focus remain legible at 100% and 150% text, high contrast, and reduced motion.
- **Progression:** Inspection and focus are zero-mutation. Only the existing accepted
  transaction changes starter, deck, print, or reward state, exactly once.

Deterministic acceptance: `test_m6_blueprint_v2_route_contract`; capture
`M6-BP-01-SelectedBlueprint` at both standard sizes. The capture fails for detached
parts, duplicate views, a figurine pedestal, unsupported floating supports, baked
paper/checkerboard/text, or any finished/animated creature before awakening.

### M6-TL-01: authored tall surface with zero no-ad reserve

- **Entry:** Any accepted M6 route is laid out in the named 1080x2400 tall fixture
  with zero bottom reserve and the fixture's declared system safe insets.
- **Player decision:** Use the bottom-most visible physical action or navigate by
  keyboard/controller focus to prove that the full authored surface is usable.
- **Result:** Authored scenery, floor, plate, tray, or control composition reaches the
  bottom boundary of the usable game surface. No empty black/navy letterbox, ad-sized
  spacer, phantom safe band, or double inset remains below it.
- **Failure:** If geometry cannot fit, the route uses its deterministic reflow or
  scrolling contract while keeping the bottom physical termination and required
  action reachable; it never restores an ad reserve or clips the control.
- **Disabled:** No hidden overlay or invisible control occupies the bottom band.
  Controls disabled by gameplay retain their visible physical seat and disabled
  treatment.
- **Feedback:** A diagnostics-only fixture label may report `bottom reserve: 0`; it
  cannot alter layout. Focus, pressed, disabled, and screen-reader states remain
  native and visible at the bottom boundary.
- **Progression:** Layout, safe-area response, and fixture interaction do not mutate
  gameplay, economy, profile, or save data.

Deterministic acceptance: `test_m6_tall_zero_reserve_bottom_reach`; capture
`M6-TL-01-ZeroReserveBottom` at 1080x2400. This supersedes all earlier synthetic
positive-reserve/ad-stress composition fixtures; those remain historical evidence
only.

### M6-PR-60: exact 60% active-print split

- **Entry:** The deterministic print fixture is paused at exactly 60% progress before
  raw completion or awakening.
- **Player decision:** Observe, inspect native progress/instrument values, or use the
  existing skip/reduced-motion affordance; no new print decision is added.
- **Result:** Relative to the creature's printable vertical bounds, geometry below
  the scan plane is solid raw fused-filament with visible layer treatment, geometry
  above it is blueprint-like wireframe only, and exactly one scan plane separates the
  two. No awakened sprite or battlefield duplicate exists.
- **Failure:** Missing geometry or art shows a native recoverable print-state error
  without granting, completing, awakening, or duplicating the creature. Retry resumes
  from authoritative transaction state rather than replaying a grant.
- **Disabled:** Completion/claim actions remain disabled until authoritative print
  completion. Battle Plan and Run Cycle controls remain governed by their existing
  state and cannot bypass the queue.
- **Feedback:** Native progress reads 60%; the scan plane and solid/wireframe boundary
  are visually coincident. Reduced motion holds the same semantic frame without a
  sweep; high contrast distinguishes solid, wireframe, and scan datum without color
  alone.
- **Progression:** Pausing, capture, inspection, and presentation retry are
  zero-mutation. The existing exactly-once print transaction alone advances the job.

Deterministic acceptance: `test_m6_active_print_sixty_percent_split`; capture
`M6-PR-60-ActivePrint` at both standard sizes. Any solid material above the plane,
wireframe-only material below it, second scan line, finished creature, or field
duplicate is a failure.

### M6-BA-CT-01: named attack contact frame

- **Entry:** In Run Cycle's authoritative Attack resolution, the deterministic fixture
  selects a known ordered attacker and target and pauses at `BattleContactPeak`.
- **Player decision:** Watch the accepted cycle or enable reduced motion; no target or
  phase choice is added at contact.
- **Result:** At `BattleContactPeak`, the attacker's animated battlefield sprite is
  visibly at the target's field position/contact boundary. The target remains
  identifiable, while both printer bodies, both native printer HP readouts, the
  player's hand, and the rival concealed hand/count remain simultaneously readable.
- **Failure:** A missing animation degrades to a finite contact pose/flash at the
  target, records a diagnostic, applies the already accepted deterministic outcome
  once, and returns the sprite to its legal anchor. It never stalls Run Cycle or
  re-applies damage.
- **Disabled:** Plan, hand actions, and Run Cycle reactivation remain visibly locked
  during contact resolution. Rival concealed cards remain card backs and cannot be
  inspected.
- **Feedback:** Wind-up, `BattleContactPeak`, native HP/armor event, and recovery are
  ordered and finite. Reduced motion uses the held contact pose plus event emphasis;
  high contrast does not hide either combatant or HP change.
- **Progression:** Presentation does not choose or alter combat results. The accepted
  attack intent advances the authoritative battle revision once and only once.

Deterministic acceptance: `test_m6_battle_contact_peak_readability`; capture
`M6-BA-CT-01-BattleContactPeak` at both standard sizes. A motion trail without the
attacker at the target, cropped printer/HP, unreadable hand zones, or a manual Attack
button fails.

### M6-HUD-01: tall printer instruments seated in brass

- **Entry:** Forge or Battle is shown in the 1080x2400 fixture with both normal and
  longest catalog/native diagnostic values, including the 150% text state.
- **Player decision:** Inspect printer status and, where already legal, activate the
  associated physical instrument control.
- **Result:** Every native printer value is seated wholly inside its intended brass
  plate aperture. Text baselines, progress marks, HP/max values, and state labels do
  not cross rims, screws, adjacent wood, or another instrument.
- **Failure:** Overflow uses the route's deterministic wrap, abbreviation, or
  reflow rule while preserving the full accessibility name; it never paints over the
  brass edge or silently hides an authoritative value.
- **Disabled:** An unavailable printer action remains visibly disabled inside its
  plate and does not gain active hover/press treatment.
- **Feedback:** Plate ownership is unambiguous for player/rival printers; focus,
  pressed, warning, high-contrast, and 150% states remain within the same physical
  seat and do not rely on color alone.
- **Progression:** Reading, focus, overflow handling, and fixture substitution are
  zero-mutation. Existing print/battle transactions alone change the displayed
  values.

Deterministic acceptance: `test_m6_tall_printer_hud_plate_seating`; capture
`M6-HUD-01-TallPrinterPlates` at 1080x2400 and
`M6-HUD-02-TallPrinterPlates-150Text` at 1080x2400.

### M6-FC-01: selected blueprint focus respects label padding

- **Entry:** A blueprint card with a native label is focused/selected in every route
  that presents one, at 100% and 150% text.
- **Player decision:** Move focus between cards, select the legal card, or cancel back
  without committing.
- **Result:** The complete four-edge focus/selection treatment stays inside the card's
  image aperture and outside the native label's padded rectangle. Scaling, lift, glow,
  or brass clamps never cross the label padding or obscure its text.
- **Failure:** If the available geometry cannot preserve both regions, focus uses a
  non-scaling inset outline and native state cue; it never clips the label or moves
  another card's hit target.
- **Disabled:** Hidden or illegal cards do not show the active selection treatment.
  Disabled cards retain readable labels and a distinct noninteractive physical state.
- **Feedback:** Focus entry/exit, selection, disabled state, and accessibility name are
  native, deterministic, and visible at high contrast and 150% text. Clearance from
  the expanded native label rectangle is at least 4 logical pixels on every edge.
- **Progression:** Focus, inspect, cancel, and failed selection are zero-mutation. Only
  an existing accepted starter/deck/queue/reward transaction advances state.

Deterministic acceptance: `test_m6_blueprint_focus_label_clearance`; capture
`M6-FC-01-BlueprintFocus` and `M6-FC-02-BlueprintFocus-150Text` at both standard
sizes.

## State ownership table

| State | Visual owner | Required representation | Forbidden substitution |
| --- | --- | --- | --- |
| Available / selected / queued blueprint | Physical paper surface plus transparent blueprint ink; native labels above it | One intact profile, build plane, connected supports, one scan datum | Rejected v1/v3 card, exploded parts, finished creature, awakened sprite |
| Active extrusion | Printer-bed runtime presentation | Solid raw print below scan plane; wireframe above | Finished-color creature, animated field sprite, full solid model before completion |
| Raw complete / awakening | Existing Forge/battle animation sequence | Completed raw fused-filament form, then finite awakening handoff | Early field duplicate or exactly-once grant replay |
| Awakened battlefield creature | Existing animated sprite | Living animated creature at its legal field anchor | Blueprint card, wireframe, static finished-print stand-in |
| Rival concealed hand | Existing card back | Face-down card backs and native count | Blueprint identity or creature reveal |

## Bounded original-resolution capture matrix

| Capture ID | State | 576x1024 | 720x1280 | 1080x2400 |
| --- | --- | --- | --- | --- |
| `M6-BP-01-SelectedBlueprint` | Accepted v2 blueprint grammar, transparent paper integration | required | required | - |
| `M6-PR-60-ActivePrint` | Exact solid-below/wireframe-above 60% print | required | required | - |
| `M6-BA-CT-01-BattleContactPeak` | Named attack contact with printers/HP/hands readable | required | required | - |
| `M6-FC-01-BlueprintFocus` | Focus clear of native label padding | required | required | - |
| `M6-FC-02-BlueprintFocus-150Text` | Focus/label clearance at 150% | required | required | - |
| `M6-TL-01-ZeroReserveBottom` | Authored content reaches zero-reserve bottom | - | - | required |
| `M6-HUD-01-TallPrinterPlates` | Tall printer values seated in brass | - | - | required |
| `M6-HUD-02-TallPrinterPlates-150Text` | Tall brass seating at 150% | - | - | required |

All captures are original-resolution PNGs from deterministic fixtures. The evidence
manifest records fixture, seed/state, viewport, safe insets, reserve `0`, text scale,
contrast, reduced-motion state, asset provenance, and SHA-256. Read-only UI review
must report no P0/P1 before visual sign-off. Source tests or generated mockups cannot
substitute for runtime captures.

## Scoped implementation evidence closeout

The bounded layout/state implementation in this checkpoint is complete. This is a
closeout of the scoped corrections, not whole-M6, release, Android, build, or Drive
completion.

The following deterministic suites passed:

- `test_m6_visual_correction`
- `test_m2_battle_ui`
- `test_m2_battle_cycle`
- `test_checkpoint6`
- `test_presentation`
- `test_m5_android_no_ad`

The evidence root is `build/evidence/m6-visual-correction`. Its `manifest.json`
records 11 Forward+ PNG captures, production bottom reserve `0`, exact viewport
dimensions, byte sizes, and SHA-256 hashes. The admitted set comprises two 60% print
captures, two `BattleContactPeak` captures, three 1080x2400 zero-reserve/tall-printer
captures, and four blueprint-focus geometry captures at 100% and 150% text. Manifest
dimension and hash verification passed for all 11 entries.

Formal read-only UI review reports zero P0 and zero P1 for the scoped corrections.
The first contact review raised one P2 because the impact emphasis could obscure the
target. That P2 is resolved: the contact overlay now sits up and left of the target
using target-relative placement, and the affected contact frame was recaptured and
accepted. Both printers, native HP readouts, player hand, and rival concealed hand
remain readable in the admitted contact evidence.

The blueprint-focus fixture PNGs prove only card/focus/label geometry. They are
non-approval fixtures and are not evidence that any blueprint illustration, the
complete 24-creature v2 family, or runtime art promotion is approved. The family and
its route captures remain subject to the gate in **Supersession and gate**.

One Windows root-certificate-store warning appeared on stderr during the scoped
run. It is attributed environment noise: the named deterministic suites completed
successfully and no corresponding game assertion, renderer failure, capture failure,
or state mutation was observed. This attribution does not waive future runtime stderr
review if the warning changes or is accompanied by an actual failure.

Task process accounting is clean. The user's pre-existing PID `46048` was not
started, controlled, or terminated by this work. No task-owned Godot console, worker,
or popup remained after capture and test cleanup.

## Acceptance and non-goals

Acceptance requires all named deterministic tests to pass; all matrix images to match
their exact dimensions; v2 blueprint transparency and physical support connectivity
to pass original-resolution review; the 60% split and `BattleContactPeak` to be
visually unambiguous; tall content/plates to reach and fit the zero-reserve surface;
and focus to clear native label padding at 100% and 150%.

The scoped non-blueprint layout/state acceptance above is satisfied by the recorded
tests, 11-image manifest, and zero-P0/P1 UI review. Whole-M6 acceptance remains
pending because the complete v2 blueprint family has not received human approval or
runtime promotion. Geometry-only blueprint fixture evidence cannot close that gate.

Non-goals are gameplay-value changes, new phase controls, new economy, save migration,
support-card replacement, creature/sprite redesign, landscape support, AdMob or any
ad-shaped reserve, Android/device/build/Drive claims, and runtime promotion of the
remaining blueprint family without its complete reviewed evidence.
