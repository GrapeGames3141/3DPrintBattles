# M9A root review ledger

Root review, 2026-09-04. **HOLD: P0 Forge scene-identity regression.** This is an
in-progress gate, not release sign-off.

## User correction overrides the incomplete visual pass

The user identified `parity1080-active_forge-text150-hc-rm.png` as the old UI and
clarified that the old Workshop scene itself is wrong. Root and UI re-review traced
the actual production route: only starter IDLE uses the approved enclosed M1-R4
printer; routine IDLE and all active states use `workshop_overview_portrait_v4.png`
plus the old `arcane_forge_printer_frame_01..04.png` open gantry. It therefore swaps
machine, camera, room and instrument language immediately after Start. Prior input,
scaling and mask tests remain useful but **do not constitute material-direction
approval**. Their Active Forge visual pass is withdrawn.

The route-wide repair contract is
`evidence/m9-forge-scene-continuity-correction.md`. Matching text-free derived layer
candidates are in `docs/art/m9-forge-continuity-20260904/`; they are not runtime
promotion. The build remains held pending the art/integration/review gates. Terra
completed and cleaned the already-running 1080 matrix before the hold, then stopped
without speculative route edits or export. No task-owned Godot processes remained.

## Authority and implementation

The existing approved portrait atlas/Plan -> Run Cycle remain authority. M9A adds
Founder onboarding, explicit durable pack receipts, visible/system Back, and faithful
native card/price facts. User approved the M9 pacing and animal-barding direction.
Terra is the sole runtime writer; root reviews and owns final Git operations.

## First diff pass: substantive fixes requested

- Keep equipment blueprint offers at exactly four when primordial injection has no
  equipment candidates; preserve eight creature slots across days/levels.
- Sanitize receipt callers/context, reset page/inspector for each new receipt, and
  restore callers consistently on Back/Keep. All paid buy paths must enter Pack.
- Separate bounded browsing metadata from profile authority. Preserve previous
  sidecar on failure; allow local browsing even when its persistence fails.
- Apply effective frozen pack prices, real Spool level, Bend rather than nonexistent
  ATK, and exact native support-card facts.
- Converge visible/WM/KEY Back through one debounce owner; no duplicate foreground
  Back or background control activation behind confirmation.
- Expand tests beyond pure Founder happy paths: legitimate ready-profile factory,
  legacy flow, save failures, duplicate/open/Keep rejection, all receipt pages, and
  actual viewport mouse/touch hits with isolated storage before any startup writes.
- Retain exact Godot console/worker PID and cleanup evidence, not test logs alone.

## Rendered Market gate: initial failure and correction history

Evidence: `build/evidence/m9a-runtime-20260904/gpu-market-576x1024.png`.
The Forward+ GPU run produced a capture, but root and read-only UI review both found
P0 readability failures: Back/category/page controls disappear, PURCHASE sits below
its hardware, and names/blueprints cannot reliably identify offers. P1 findings are
weak selection and pale ownership text on cream.

Preserve the cabinet master and approved creature sources. Use one consistent
warm-parchment slip behind all transparent blueprint art, readable material-specific
native ink, a real visible 56px Back, equal >=48px category targets, explicit selected
state, visible page chevrons, and PURCHASE centered inside its 56px hardware. Recheck
576px first, then the complete portrait/accessibility matrix. No export until closed.

## Source-art and input gates

The shared-control root cause was incorrect grid cropping of the older atlas:
binding_tab included neighboring ornament and large margins; other crop bounds were
clipped. A new six-object ImageGen master and measured per-object crops replaced the
source candidates. Calibration v7 passes root and read-only UI review at exact 72x56,
56x56 and 48x64 targets on light/dark fields with RGB identity and a 2px transparent
guard band. The earlier white-matte proof failure was a compositor bug (`blit_rect`
instead of alpha blending), now corrected. This closes asset/compositing only, not
runtime text placement, nine-slice states, touch routing or the Market gate.

Founder, acquisition, M3 controls and M8 Back regressions have passing runs recorded
in the E: process ledger. The expanded real-input test also passes mouse/touch hits
for First Print, active Forge, Founder paging/recovery and Battle exit. Remaining
Archive/Deck/Settings/Result capture-owner assertions also pass. Debug QA
storage parsing now lives in SaveService and must reject invalid roots before any
autoload profile load. `qa-storage-invalid.stdout.log` contains no profile-load or
profile-ready marker; stderr reports the explicit rejected-root error. The process
exit code and cleanup still belong in the final process ledger.

## Stable 576px input and visual recheck

The first full 576px matrix revealed runtime semantic-layer defects even after the
source atlas passed: opaque binding styles covered card art, and direct children of
a pager PanelContainer overlapped. These were not new art failures. New transparent
hit surfaces and a dedicated pager content wrapper close those P0 findings.

Root and read-only UI reviewed the stable `matrix-market-clean3-576x1024.png`,
`matrix-archive-clean2-576x1024.png`, and `matrix-deck-clean2-576x1024.png`: no
remaining P0. Six P1 corrections were sent to Terra as one bounded batch: center
Purchase/Save/Pre-Print on their hardware faces, preserve the Market selected-offer
outline, restore light Archive/Deck-inspector parchment, and clip Deck palette art
inside each card. The fresh `matrix-market-p1-576x1024.png`,
`matrix-archive-p2-576x1024.png` and `matrix-deck-p1-576x1024.png` close these P1s.

`matrix-founder-p1-clean2-576x1024.png` passes root and UI with no P0/P1: real
Mossmunk selection has a persistent cyan outline, native facts are readable in two
lines, receipt and page status have separate strips, and Back/Keep/pager states are
visible. Inline selection is not a modal: one Back returns to the caller and keeps
the selected card/page for Resume Pack. Do not introduce a clear-selection-first
Back trap. Fine source stippling is a P2 watch, not a request for replacement art.

The full 576 matrix found three further P1s: Workshop Back overlapped Spool HUD,
Starter used pale text on cream, and Resume Pack overlapped Settings. Dedicated
`matrix576-workshop-recap.png`, `matrix576-starter-recap.png` and
`matrix576-founder_recovery-recap.png` close those findings. The recovery action
subsequently received the shared generated parchment hardware. The Battle exit
harness initially clicked a background control after opening its shield; that was
test ordering, not permission to weaken the modal shield. Actual background Back
then foreground dismissal is covered and `matrix576-battle_exit-fixed.png` passes.

## Production-parity and teardown review

The earlier `matrix720-*` and `matrix1080-*` runs changed logical content size and
are retained as stress evidence only. Official `parity720-*`/`parity1080-*` captures
preserve the production 576x1024 base and change only physical Window size. At
720x1280 the logged transform is 1.25 with a 576x1024 visible logical viewport.
Tall 1080x2400 expands the visible logical height instead of changing base width.

Read-only UI review passes 13 of 14 official 720 routes. Battle Exit still needs
its background focus highlight removed and Stay focused while the shield owns
input. Initial tall Active Forge with 150% text/high contrast/reduced motion passes
layout; a still image alone is not reduced-motion behavioral evidence. Full tall
matrix, final modal recaptures and accessibility tests remain release gates.

Verbose actual-input PID 38820 and its later diagnostic run exposed detached
Node ownership leaks, not just static caches. RefCounted Forge, Battle and Workshop
components now have idempotent final `dispose()` methods called by Main teardown;
ordinary detach still preserves stage/animation continuity. Lifecycle PID 47088
exit 0 covers detach/resume and all three final owner releases. Fresh verbose
actual-input console PID 53060 / worker 44016 passes with no ObjectDB, CanvasItem
or resource leak lines. The remaining Windows certificate-store diagnostic is
environmental. `_save_to_cache` at `shader_rd.cpp:696` is a renderer shader-cache
write issue, not a missing UI font. Preserve that classification and exact logs.

OS-delivered Android Back is still not established by desktop input evidence.

- Remaining final diff/test/render review and maintainability refactor.
- Actual Android device Back/launch evidence: no device was attached at inventory.
- Milestone commit, Android export, package/signing/hash verification, DriveFS copy
  and separately cloud-visible synchronization. None is claimed by this ledger.
- M9B battle/progression and M9C actual models are subsequent milestones, not done
  merely because M9A or an art source passes.
