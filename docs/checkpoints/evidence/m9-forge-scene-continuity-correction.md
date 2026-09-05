# M9 Forge scene continuity correction

Status: **decision-complete presentation correction; replacement layer family,
runtime integration, captures, read-only review, and human art approval pending**

Date: 2026-09-04

Authority: the user rejection of the current active-Forge screenshot in the current
thread; the approved M1-R4 First Print composition; the M8 progressive-print and Back
contracts; and the M5 no-ad decision. This document approves no new art.

## Finding and correction boundary

The reported screenshot is a real presentation regression, not a gameplay defect.
`render_feedback_printer()` selects the approved M1 First Print plate only while the
profile is `starter_selected` and the presentation sequence is `IDLE`. Routine IDLE
and every non-IDLE state instead use the old Workshop overview behind
`ArcaneForgeStage`, whose four printer frames are the older open-frame machine. One
route therefore changes room, printer silhouette, material language, and scale as
soon as the player starts or revisits a print.

The correction is route-wide visual continuity. It does not add a printer mechanic,
state, phase, currency, reward, ownership rule, or print-time rule. The existing
`IDLE`, `PRINTING`, `RAW_COMPLETE`, `RAW_HOLD`, `AWAKENING`, `DEPARTING`, `AWAKENED`,
and `FAILED` meanings remain unchanged. “Paused” means the player has left an already
accepted visual presentation under the existing M8 Back behavior; “resumed” means
that same phase/generation is rendered again. Neither is a new sequence phase.

## Locked visual authority

- The composition authority is the approved M1-R4 plate at
  `res://assets/ui/physical_ui/m1-r2/first-print-empty-printer-v2.png`: a dominant,
  portrait, enclosed navy-enamel printer; worn brass structure; cream instrument
  faces; restrained cyan work light; central cyan star-gem/compass emblem; one clear
  chamber and build bed; three lower physical instruments; and three lower physical
  control seats.
- All existing Forge entry paths and sequence states must read as the same machine in
  the same close, frontal station. A state may move its nozzle, scan light, raw print,
  living creature, meter needles, status lights, or physical control feedback. It may
  not replace the machine or reveal a different room.
- Background depth is limited to the close, subdued workshop glimpsed around the
  approved enclosure. A full-room establishing view, long empty floor aisle, distant
  battle dais, display shelves, desk/monitor scene, or tiny printer in a room is not a
  Forge surface.
- The M8 progressive mask is retained exactly: before completion the bed never shows
  a full creature silhouette. At progress below 100%, solid/raw pixels are strictly
  below the scan datum, any preview is one contiguous scan-adjacent band no taller
  than 8% of printable height, and everything above that band is transparent. The
  retired whole-upper-creature wireframe must not return.
- Portrait is the only production orientation. Native bottom reserve is zero. No ad
  SDK, placeholder, disclosure, creative, reserved strip, reward, permission, or
  configuration is introduced by this correction.

## Player-facing continuity contract

- **Entry:** Enter the Forge from starter setup, the Workshop printer, Archive/
  Collection, or an existing equipment-workbench caller; or re-enter an accepted
  presentation from its recorded caller. The route receives the existing selected
  subject, price projection, sequence phase/progress, generation, caller, and profile
  projection without altering them.
- **Player decision:** Select an already eligible blueprint/item during routine IDLE,
  start the existing valid print, watch or legally skip its finite presentation, use
  visible Back or Android Back, return to resume a paused presentation, open an
  entitled starter pack after completion, print another, or return to the recorded
  caller. The player makes no aesthetic, reveal-geometry, or new phase decision.
- **Result:** Every state remains inside one coherent M1-R4 enclosed-printer station.
  The chamber tells the existing blueprint -> progressive raw -> raw hold -> awaken
  -> depart story, while native instruments and controls truthfully show the current
  state. A completed subject departs once and the terminal receipt/actions remain on
  the same station.
- **Failure:** Any old-room or old-printer fallback, machine swap between states,
  pre-completion full silhouette, baked dynamic fact, obscured/absent Back, duplicate
  parent/stage, mismatched resume frame, repeated commit/grant, or visual layer that
  changes authority keeps this correction open. Missing replacement art shows a
  native, caller-safe unavailable presentation on a neutral navy/brass emergency
  surface; it never loads a forbidden old asset or displays a false completed print.
- **Disabled:** Start is disabled under its existing eligibility/cost/in-flight
  rules. Back remains visible in every state and is disabled only during the existing
  noninterruptible `RAW_COMPLETE` commit window, with the same native reason for
  visible and Android Back. Skip cannot bypass a commit or failure. Background and
  hidden controls cannot receive input. No new action or phase is enabled here.
- **Feedback:** Selected subject, element/type, price/free state, owned count, upgrades,
  recipe, layer/progress value, ETA, active/paused/secure/failed/done status, error,
  Back destination, button copy, tooltip, accessibility name, focus, and receipt are
  native controls. The authored plates/layers contain no names, numbers, status copy,
  progress, button text, or accessibility content. Physical lamps, scan light, meter
  motion, pressed depth, and focus treatment reinforce rather than replace native
  facts.
- **Progression:** Selection, rendering, capture, accessibility variants, Back,
  pause, resume, and presentation skip are zero-authority operations. The existing
  raw-completion transaction alone may commit its debit/model/revision exactly once;
  the existing terminal starter-pack action alone may claim its entitlement exactly
  once. This correction changes neither boundary nor its payload.

## Single-owner composition

One route-owned Forge surface owns the complete visual stack for every row below:

1. **Static station owner:** one approved or later human-approved text-free close
   printer plate. It owns enclosure, navy enamel, brass, star-gem, chamber, bed,
   instrument housings, control seats, and restrained close-background material.
2. **Chamber presentation owner:** one clipped stateful layer inside the approved bed/
   chamber aperture. It alone owns footprint seed, progressive raw mask, narrow M8
   preview band, scan line, raw form, living sprite, sparks, and departure transform.
3. **Native instrument owner:** one safe-area-aware layer owns every changing fact,
   progress control, status, error, tooltip, accessibility description, and receipt.
   Native content sits in authored blank faces and never redraws the printer.
4. **Native interaction owner:** one layer owns blueprint/item selection, Start,
   Skip, Back, post-completion actions, disabled reasons, pointer targets, and complete
   four-edge focus. Targets are at least 48 logical pixels; primary actions are at
   least 56.

No visible object has two owners. In particular, generated art must not contain a
second creature, completed raw form, progress bar, readable label, action plaque, or
button state beneath its native owner.

The presentation controller, selected subject, caller, and generation outlive a
transient rendered tree. Leaving an interruptible active state destroys only the
current visual children. Re-entry creates exactly one new Forge surface parent and
attaches exactly one chamber layer and one native overlay to it. It does not reparent
a child still owned by the prior tree, allocate a second sequence, restart a timer,
or replace the recorded caller. After resume, `(subject_id, phase, progress_bps,
phase_elapsed_bps, generation, caller)` exactly matches the paused snapshot. Stale
callbacks from the prior visual parent are inert.

## Existing-state presentation map

Percentages in this table are normalized `layer_reveal_bps`; they do not introduce a
new authoritative progress model.

| Stable state ID | Existing state/fixture | Chamber and station result | Native actions and Back |
| --- | --- | --- | --- |
| `FC-ST-01` | Starter `IDLE` | Approved enclosed station, intact starter blueprint docked outside chamber, empty bed with only the allowed local seed | Start free print; visible Back to recorded starter caller |
| `FC-ST-02` | Routine creature/item `IDLE` | Same station and empty bed; eligible selection is seated in a physical cartridge/instrument rail, never in a room-scale browser | Select, Start at projected cost, offers/recovery if already supported, visible Back to exact caller |
| `FC-ST-03` | `PRINTING`, 0% | Same station; accepted presentation has local footprint seed only, no body | Skip where already legal; visible Back pauses safely |
| `FC-ST-04` | `PRINTING`, 25% | Solid raw layers below scan; at most one narrow adjacent preview band; no upper body | Same active controls and native 25% fact |
| `FC-ST-05` | `PRINTING`, 60% | Same mask rules and canonical printable bounds; printer identity unchanged | Same active controls and native 60% fact |
| `FC-ST-06` | `PRINTING`, 99% | Final top remains absent; full raw/wireframe/living silhouette still forbidden | Same active controls and native 99% fact |
| `FC-ST-07` | `RAW_COMPLETE` | First legal complete raw frame, on the same bed; securing is visibly in progress | Back remains visible but disabled with native reason; no second commit input |
| `FC-ST-08` | `RAW_HOLD` after successful commit | Complete dormant raw form holds on the same bed without resizing/popping | Skip where already legal; visible Back pauses; receipt says record is secure |
| `FC-ST-09` | `AWAKENING` | Existing finite raw-to-living handoff remains wholly in the chamber | Skip/Back as already legal; native secure status |
| `FC-ST-10` | `DEPARTING` | One living subject leaves the bed along the existing finite path; no duplicate remains | Skip/Back as already legal; native departure status |
| `FC-ST-11` | `AWAKENED` (“done”) | Bed is clear after departure; same station remains behind terminal receipt/actions | Existing pack/Print Another/Return actions as eligible; visible Return/Back |
| `FC-ST-12` | `FAILED` | Same station, no false living/completed substitute; chamber truthfully retains only the last safe visual state | Native error and existing caller-safe recovery/Return; visible Back |
| `FC-ST-13` | Paused outside an interruptible active state | Forge is not visually duplicated behind caller; sequence snapshot remains owned by the Forge controller | Caller remains interactive; returning is the existing resume choice |
| `FC-ST-14` | Resumed from `FC-ST-13` | Same subject, machine, mask, phase, percent, generation, and caller as pause; one visual parent | Continue/Skip/Back use the restored generation; no duplicate callback |

The map applies to every subject class already supported by the Forge route. It does
not make an unowned blueprint printable or expand the existing creature/equipment
eligibility rules.

## Forbidden Forge-route assets and fallbacks

When `screen == "printer"`, no visible Forge subtree, fallback, state transition, or
deferred rebuild may load or display any of these rejected route sources:

- `res://assets/ui/workshop/workshop_overview_portrait_v4.png`
- `res://assets/ui/workshop/workshop_overview_landscape_v4.png`
- `res://assets/ui/workshop/workshop_printer_closeup_v2.png`
- `res://assets/ui/workshop/workshop-theme-reference-fallback.jpg`
- `res://assets/ui/arcane_forge_printer_frame_01.png`
- `res://assets/ui/arcane_forge_printer_frame_02.png`
- `res://assets/ui/arcane_forge_printer_frame_03.png`
- `res://assets/ui/arcane_forge_printer_frame_04.png`

These are scoped negative assertions for the Forge route, not permission to delete
assets or alter unrelated routes. A preload elsewhere in the application is not by
itself a failure; a Forge dependency, selected fallback, visible CanvasItem, or
captured pixel contribution from one of these paths is.

Automated evidence records the texture resource path for every visible CanvasItem
under the Forge surface in every state and asserts the forbidden-set intersection is
empty. A source/dependency assertion also proves the Forge renderer and chamber
component cannot select those paths. Injected missing-layer and failed-load fixtures
must reach the native safe presentation described above with the same empty
intersection.

## Deterministic acceptance

1. Enter starter setup and routine Forge through real coordinate pointer/touch and
   keyboard-focus activation, not direct callbacks or emitted signals. Select an
   eligible routine blueprint, Start, use active Back, re-enter, Skip where legal,
   and Return using their actual controls. Android Back is injected through the
   platform Back dispatcher and produces the same route/state result as visible Back.
2. For each `FC-ST-01` through `FC-ST-14`, assert exactly one Forge surface parent,
   one static station owner, one chamber owner, one native instrument owner, one
   native interaction owner, and no forbidden texture dependency. State rebuilds and
   resize do not accumulate nodes, timers, controls, or callbacks.
3. Freeze a serialized authority/profile fixture before every visual-state capture.
   After render, frame advance, focus traversal, resize, high contrast, reduced
   motion, pause, and resume, require byte-equivalent profile, revision, currency,
   ownership, printed count, receipt count, entitlement count, save journal, and
   authoritative job data. Presentation sequence fields may change only in tests
   explicitly advancing the existing finite presentation.
4. Keep exactly-once mutation evidence separate from the zero-mutation visual cases.
   At the existing `RAW_COMPLETE` boundary, repeated commit requests, duplicate
   callbacks, Back attempts, reload, and resume yield one accepted debit/model/
   revision or one unchanged failure. `RAW_HOLD` onward never commits again. Terminal
   pack activation uses its existing unique receipt and cannot grant twice.
5. Re-run the M8 alpha/mask assertions at 0%, 25%, 60%, and 99% in normal, high-
   contrast, and reduced-motion variants. At all values below 100%, no connected mask
   spans the printable bounds, raw alpha is zero on/above scan, preview alpha is zero
   above the 8% band, and no raw-complete/living semantic node exists.
6. At 100%/150% text, all native facts remain within their physical faces without
   covering the bed, subject, star-gem, scan datum, or each other. Every visible
   action is reachable, has truthful accessibility/destination text, and shows a
   complete focus treatment. High contrast is not color-only; reduced motion retains
   the same held semantic states without nozzle/spark motion or an early full form.
7. At 576x1024, 720x1280, and the 1080x2400 tall fixture, the enclosed printer remains
   the dominant object, the bed and all required controls remain above the usable
   bottom, production reserve is zero, and there is no blank ad band or duplicated
   safe inset. The tall fixture extends close-background material, not a room/floor
   vista.
8. Original-resolution review compares the entire family side by side. Any machine
   silhouette/material/camera jump, old-room read, fake baked control, duplicate
   creature, alpha fringe, clipping, dead expanse, or P0/P1 finding blocks promotion.
   Passing structural tests does not constitute art approval.

## Required capture map

Every PNG is original resolution and is listed with dimensions, state fixture,
authority-snapshot hash, visible texture-path inventory, and SHA-256 in the evidence
manifest.

| Capture ID | Required presentation | Required size/mode |
| --- | --- | --- |
| `M9-FC-01-StarterIdle` | `FC-ST-01`, docked starter, empty bed, Start and Back | 576x1024 and 720x1280 |
| `M9-FC-02-RoutineIdle` | `FC-ST-02`, routine creature selection and physical selector | 576x1024 and 720x1280 |
| `M9-FC-03-RoutineAlternateCaller` | Routine creature IDLE entered from Archive/Collection; exact caller and same station | 720x1280 |
| `M9-FC-04-Print00` | `FC-ST-03`, accepted 0%, local seed only | 576x1024 and 720x1280 |
| `M9-FC-05-Print25` | `FC-ST-04`, M8 progressive mask | 576x1024 and 720x1280 |
| `M9-FC-06-Print60` | `FC-ST-05`, M8 progressive mask | 576x1024 and 720x1280 |
| `M9-FC-07-Print99` | `FC-ST-06`, incomplete top/no full silhouette | 576x1024 and 720x1280 |
| `M9-FC-08-RawComplete` | `FC-ST-07`, first full raw and visibly disabled Back | 720x1280 |
| `M9-FC-09-RawHold` | `FC-ST-08`, committed dormant hold | 576x1024 and 720x1280 |
| `M9-FC-10-Awakening` | `FC-ST-09`, mid finite handoff | 576x1024 and 720x1280 |
| `M9-FC-11-Departing` | `FC-ST-10`, one subject leaving, no duplicate | 576x1024 and 720x1280 |
| `M9-FC-12-Done` | `FC-ST-11`, clear bed, terminal receipt/actions | 576x1024 and 720x1280 |
| `M9-FC-13-Failed` | `FC-ST-12`, truthful native error and Back/recovery | 576x1024 and 720x1280 |
| `M9-FC-14-PausedCaller` | `FC-ST-13` after active Back at normalized 60%; caller visible | 720x1280 |
| `M9-FC-15-ResumedSameJob` | `FC-ST-14`; same subject/60%/generation/caller, one parent | 720x1280 |
| `M9-FC-16-Text150` | Routine IDLE, 60%, done, and failed subcases with focus | 576x1024 and 720x1280, 150% text |
| `M9-FC-17-HighContrast` | Starter IDLE, 60%, RAW_COMPLETE, and failed subcases | 720x1280, high contrast |
| `M9-FC-18-ReducedMotion` | 0%, 25%, 60%, 99%, raw hold, awaken, depart, done held subcases | 720x1280, reduced motion |
| `M9-FC-19-Tall` | Starter IDLE, routine IDLE, 60%, and done subcases | 1080x2400, zero production reserve |
| `M9-FC-20-MissingLayerSafe` | Injected missing continuity layer; native safe presentation and no old fallback | 576x1024 and 720x1280 |

The paired pause/resume manifest must additionally record identical values for
`subject_id`, phase, normalized progress, phase-local progress, generation, and
caller, plus exactly one route transition in each direction. Captures establish
composition only; the manifest and deterministic traces establish zero mutation,
exactly-once behavior, Android/visible Back equivalence, and parent ownership.

## Gate

This correction is ready for a text-free layer brief and candidate production. It is
not permission to promote a candidate. Runtime integration begins only after the
replacement family covers the complete state map, original-resolution read-only UI
review reports no P0/P1, and the user approves the art family. No prior approval of
the M1-R4 composition is approval of a new derivative.
