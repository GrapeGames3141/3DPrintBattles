# M9 Forge continuity implementation handoff

Root plan, 2026-09-04. Sole runtime writer: `terra_implementer`.
The exact candidate art gate is satisfied by the human approval recorded in
`docs/art/m9-forge-continuity-20260904/approval-20260904.md`; implementation is active.
The narrow normal-size Start/60% and selector review passes in `first-gate-v3`.
The complete phase/accessibility and release gates remain open. Existing M9A work
must be preserved; no parallel runtime writer.

## Bounded change

Repair the actual production `screen == printer` presentation, not only the capture
fixture or the legacy `render_printer()` facade. All existing creature, armor and
core entry paths receive one physical enclosed station. Do not alter catalog,
economy, print eligibility, sequence thresholds/timing, profile or save authority.

### Ownership

- Add one `scripts/ui/physical_forge_screen_component.gd` presentation component.
  It consumes Main's existing selected subject, definition/cost projection,
  sequence, settings, recorded caller and callbacks. It does not mutate gameplay.
- Main delegates every printer state to it without a starter-only or armor bypass.
  Move the old setup/active UI implementation behind this single owner; remove
  obsolete reachable branches rather than keeping two production renderers.
- Keep `ArcaneForgeScreenComponent` and its persistent `ArcaneForgeStage` as the
  one chamber/animation owner. Ordinary detach retains it; Main final dispose
  remains the destructive owner. New geometry inputs do not recreate a job.
- Promote only approved deterministic crops/layers to
  `assets/ui/physical_ui/forge-continuity/`. Source candidates, prompts and
  review evidence remain in `docs/art/m9-forge-continuity-20260904/`.

### Station and chamber

- Use one opaque `enclosed-forge-static-master-v1.png` for all states, including
  starter and routine IDLE. It is the exact M1 enclosed machine with only moving
  hardware removed, not a new room. Use PhysicalPortraitPlatePresenter so static
  art, chamber geometry and native labels share one fitted content coordinate frame.
- Derive separately cropped rail and nozzle from the actual-alpha carriage atlas.
  Preserve source RGBA and generous transparent guards; record measured pixel crop
  bounds, source/hash, target geometry and on-light/on-dark proofs. No drawn stand-in,
  matte flood fill or opacity threshold that destroys metallic highlights.
- Measure the actual dark chamber, fixed vertical rails and cream bed on the 941x1672
  plate. Store one named design-space geometry contract used by the compositor and
  test fixtures. Raw feet/raft and living feet must meet that same bed surface.
- ArcaneForgeStage receives external station geometry and draws only dynamic raw,
  living, narrow preview, scan/sparks and movable hardware. In this mode it neither
  loads nor draws the old printer frames. Remove those dependencies from the
  production Forge path; do not delete unrelated assets globally.
- Rails stay horizontally registered to the cabinet's fixed vertical guides. Nozzle
  tip follows the scan datum and its legal horizontal stroke; use the existing
  presentation time and reduced-motion setting, never another independent timer.
  Park the carriage clear of the complete subject during raw hold/awakening.
- Preserve the tested M8 alpha-aware progressive clipping and fixed canonical print
  bounds. Raw source, existing living sprite, finite awaken/depart and exactly-once
  callbacks are unchanged. The chamber clips its own content and never clips native
  Back or the outside blueprint cartridge. Terminal bed is empty after departure.

### Physical native UI

- Retain the external cartridge's approved paper aperture/ink treatment and selected
  blueprint identity. Routine selection uses a compact native physical cartridge
  selector within the same station, not the old room-scale selector panel.
- Use the three existing circular faces for recipe/subject/price, layer count and
  progress, and ETA/state. Use their existing cream surfaces and dark native ink.
  Use the lower three wells for Back, the current primary action (Start/Skip/Return)
  and a current status or existing eligible terminal action. Do not overlay generated
  hardware on hardware already baked in this station.
- Fit readable labels and truthful abbreviations/line breaks at 100% and 150%; full
  native accessibility descriptions retain unabridged facts. Do not shrink essential
  large-text copy back below normal size to make it fit. No top HUD or floating
  green/black rail over the machine. Currency must use an existing readable face,
  not a new app panel. Do not obscure the crest or chamber.
- Back always uses the shared request dispatcher/caller contract. Only RAW_COMPLETE
  uses the existing brief lock with a visible native securing reason. Skip does not
  bypass failure/commit. Existing terminal pack/Print Another/Return actions remain
  available according to the same predicates.
- High contrast improves native ink, focus and state discrimination while retaining
  physical material; do not put a target-like white rectangle around an inert bed.
  Reduced motion holds the same semantic reveal without mechanical travel/sparks.

## Validation order

1. Import/parse with isolated pre-autoload E: storage and exact PID/cleanup ledger.
2. One actual Start transition at 576x1024: capture immediately before and after
   Start and at 60%. Root/UI compare whole-scene identity against the exact approved
   enclosure, not only font/input metrics. Do not run a large matrix before this gate.
3. After no P0/P1, complete the correction contract's phase/caller/accessibility map
   with production base576 geometry, exact physical raster sizes and real pointer/
   keyboard action ownership. Include the legacy armor/core caller without changing
   its supported subject art or eligibility.
4. Assert no forbidden Forge dependencies, one persistent chamber/sequence,
   byte-equivalent authority for presentation-only frames and pause/resume, existing
   exactly-once transactions, M8 mask and M9 Founder/navigation/lifecycle regressions.
5. Fresh final verbose actual-input run must retain the clean owner teardown.
   Classify environmental certificate/shader-cache diagnostics, never suppress them.
6. Root reviews diff, texture/node churn, tests and evidence. Only then commit,
   export the next Android review and deliver non-overwriting APK/README to Drive.

Do not add M9B battle or progression rules in this bounded correction.

## Post-first-gate source audit — next bounded validation batch

Root source review identified these concrete later-phase risks, to validate and
correct while executing the existing M9-FC phase map (not a new design scope):

- `PhysicalForgeScreenComponent` currently assigns terminal `OPEN PACK` outside
  the eligible-Founder branch. Keep its text and callback paired: eligible receipt
  uses Open Pack, otherwise Print Another. Exercise both by actual input.
- The missing-layer safe screen uses cream-well dark ink without its cream plate.
  Give its one Back owner an existing physical control or contrasting native safe
  treatment, preserve the recorded caller, and freeze the accepted job. A missing
  static/guide/head/raw layer must never show an older room or substitute creature.
- `refresh_native` must not replace a FAILED reason with a generic phase string.
  Keep one truthful native failure owner and unabridged accessible reason; do not
  label a persistence error as bad input. SECURING must not claim RECORD SECURE
  before the existing commit resolves.
- Armor/core still take their legacy raw-region geometry while the new carriage
  uses creature-style alpha-aware layout. Use a single shared canonical raw bound
  and scan datum for the current subject type. Preserve existing equipment sources
  and rules; this is not promotion of the future M9C art/model work.
- Living sprite feet and dormant raw raft must both anchor to the authored bed
  using real nontransparent bounds. Inspect mid-awakening and departure, including
  large silhouettes. Keep the existing finite animation and one subject owner.
- Current continuous refresh assigns legacy minimum stage heights and loads the
  component script repeatedly. Retain the fitted station size, cache the existing
  presentation owner, and avoid unnecessary hierarchy/resource churn. Assert a
  stable parent/stage/generation through redraw, resize and caller pause/resume.

Batch the capture harness by physical resolution, keeping the production logical
base 576x1024. Every row must record its exact state, authoritative profile hash,
visible texture paths, dimensions and image hash. Do not treat a harness exit-zero
as a visual pass; root/read-only UI review owns that decision.
