# PrintForge M9A release acceptance checklist

Status: **OPEN — not release PASS. The normal 576x1024 Forge Start/60% and selector
first gate passed root and read-only UI review in `first-gate-v3`. The full phase and
accessibility map, candidate-commit tests, Android audit/device evidence, and Drive
delivery are not yet claimed.**

Date: 2026-09-04

Authority: `printforge-m9-playable-progression-v1.md` M9A only,
`printforge-m9a-review-ledger.md`, `m8-pat-print-back-regression-design.md`,
`m9-forge-scene-continuity-correction.md`, and the active M5 no-AdMob delivery
contract. This checklist neither reduces nor enlarges those contracts.

## Scope and present hold

- [ ] Release scope is limited to M9A Founder onboarding, durable/pageable pack
  receipts, faithful native card/price facts, visible/system Back, and the approved
  route-wide Forge continuity correction.
- [ ] M9B battle pacing/queue/rewards/XP/mastery/mods is recorded **NOT INCLUDED / NOT
  COMPLETE**. M9C printable creature/equipment models are recorded **NOT INCLUDED /
  NOT COMPLETE**. Neither may be represented as delivered by this M9A artifact.
- [x] The exact matching two-PNG enclosed Forge source family is HUMAN APPROVED and
  its source UI review has no P0/P1. Do not ask for the same art approval again.
- [x] The narrow normal-size runtime Forge first gate passes in `first-gate-v3`:
  root and UI review found no P0/P1 for actual Start/60%, attached carriage/head,
  bed-anchored raw raft, and native cream-face ink. `first-gate/` and
  `first-gate-v2/` remain superseded failed visual evidence, not release proof.
- [x] The same correction closes the observed IDLE false `100%`, duplicate-percent
  pseudo-ETA, sub-48px selector targets, and legacy shader contamination of authored
  v2 blueprint ink. These are implementation/capture checks, not a new art gate.

## Candidate-commit logic gate

Every checked result below must identify the clean full commit hash, exact command,
console/worker PIDs, exit code, retained log, and task-owned process/dialog cleanup.
Earlier runs remain useful evidence but are not a substitute if their exercised code
differs from the release candidate.

- [ ] `test_m9_founder_progression` proves rule/profile authority for all three
  starters from empty isolated storage. Choice grants one card/license and a one-card provisional
  deck with new-profile-only `founder_v1`; First Print grants no hidden deck fill.
  Claims 1/2/3 each atomically grant and append the ordered 13 cards, persist the
  pending receipt, and advance `opened`, yielding exact deck/owned counts 14/27/40.
  Keep grants/appends nothing, increments `kept` once, and clears pending. Battle
  remains gated until `opened == kept == 3` and the exact authored 40-card deck is
  legal. Back/reload, duplicate press, fourth claim, rejected save, repair, and
  complete/in-progress unmarked legacy profiles grant nothing extra. A separate
  rendered coordinate-input fixture must choose each starter and complete this same
  flow through the visible controls; the rule test alone is not usability evidence.
- [ ] `test_unified_card_acquisition_ui` proves acquisition/receipt authority, and a
  rendered coordinate-input fixture uses actual Market controls to buy
  Basic/Forge/Arcane/Primordial/Champion at the frozen displayed
  debit; every committed base/bonus card is reachable in stable order at five per
  page. Back preserves receipt, page, selected card, and sanitized caller; Resume Pack
  reopens the same receipt; Keep acknowledges once. Pending, insufficient-funds,
  double-submit, reload, and sidecar-persistence failure cannot reroll, hide, duplicate,
  or partially grant cards. A new receipt resets its local page/inspector state.
- [ ] Native facts use authoritative normalized aliases (`cost`/`print_ticks` from
  `filament_cost`/`print_turns`), real Spool level and exact effective price. Creatures
  show HP/Bend/element/ability, not invented ATK; support/equipment facts and
  creature/equipment license coupling match catalog/rules authority.
- [ ] `test_m8_route_back_contract` executes all 18 stable rows and every named
  semantic subcase twice from identical serialized fixtures: visible Back versus dispatcher
  `go_back_requested`, with exact caller/modal/draft/job/receipt/profile/focus/callback
  parity. Title opens Exit confirmation; live Battle opens Concede/Stay; background
  controls stay shielded; receipt Back preserves pending content; locked commit states
  expose the same reason. Every visible owner is unique, focusable, reachable and at
  least 48x48 logical pixels.
- [ ] `test_m8_back_transaction_atomicity` proves one debounce/transition under
  repeated visible/WM/KEY Back, rebuild/replacement and persistence rejection. No
  partial Deck + Pre-Print save, purchase dismissal, result replay, accepted-job
  cancellation, or deferred stale callback is possible.
- [ ] `test_m9_real_input_navigation` first proves a known-good target and the
  original STOP-overlay negative control, then obtains each real control rect and
  injects pointer/touch press and release through `Viewport.push_input` at its coordinates.
  It covers First Print, active Forge, Founder paging/recovery, Archive, Deck, Market,
  Settings, Result, and Battle exit. Direct handlers, `pressed.emit()`, private
  callbacks, or captured mouse do not count; keyboard focus activation is a separate
  input fixture. A rendered `Input.parse_input_event` fixture independently repeats
  the release-critical Founder/pack/Back path; headless or viewport injection does
  not stand in for that rendered input proof.
- [ ] `test_m8_progressive_first_print_reveal` preserves the existing 0/1/25/60/99,
  RAW_COMPLETE, awaken and departure authority/mask contract in normal and reduced
  motion. Pre-100 never reveals a full figure; the scan-adjacent preview band remains
  at most 8% of printable height.
- [ ] Forge continuity validation proves one persistent parent-owned stage and one
  job/subject/generation across caller exit, pause and resume; no orphan/duplicate
  stage, texture, callback or authority owner is created. Frozen browse/render and
  nonboundary visual advance mutate no profile, RNG, receipt, ownership, progress or
  revision. Skip introduces no grant or bypass; if it lawfully reaches existing
  `RAW_COMPLETE`, the ordinary exactly-once completion commit may run once.
- [ ] `test_game_manager_atomicity`, `test_save_recovery`, `test_m3_live_controls`,
  `test_ui_workshop_nav`, `test_unified_ui_layout`, `test_m5_android_no_ad`,
  `test_export_boundary`, and `test_runtime_asset_manifest` pass as candidate-commit
  regressions. Invalid QA storage is rejected before any autoload profile load; final
  verbose lifecycle/real-input logs contain no ObjectDB, CanvasItem, resource or
  detached-owner leak. The known Windows certificate-store diagnostic and renderer
  shader-cache write diagnostic are reported separately, not relabeled UI failures.

## Render and capture gate

### First gate before the full map

- [x] At 576x1024, real Start input produces replacement `before-start`,
  `after-start`, and normalized `print-60` frames. They close the three P1s above,
  preserve the enclosed brass/navy star-gem station, keep the M8 progressive mask,
  and receive root plus read-only original-resolution UI review with P0 none/P1 none.
- [ ] Approved carriage/head crops retain alpha, registration and stable bounds.
  Runtime dependency and rendered-pixel scans reject every old Workshop overview,
  old printer closeup/theme fallback, and `arcane_forge_printer_frame_01..04` path.

### Required Forge capture map — unchanged

Do not omit, merge, substitute, or add rows to this map. Each PNG manifest records
exact dimensions, fixture/state, authority hash, visible texture paths, file bytes and
SHA-256. Visual fixtures freeze authority except for the separately traced legal
completion boundary.

| ID | Required state | Required size/mode |
| --- | --- | --- |
| `M9-FC-01-StarterIdle` | Docked starter, empty bed, Start and Back | 576x1024 and 720x1280 |
| `M9-FC-02-RoutineIdle` | Routine creature selection and physical selector | 576x1024 and 720x1280 |
| `M9-FC-03-RoutineAlternateCaller` | Routine IDLE from Archive/Collection; exact caller | 720x1280 |
| `M9-FC-04-Print00` | Accepted 0%, local seed only | 576x1024 and 720x1280 |
| `M9-FC-05-Print25` | M8 progressive mask at 25% | 576x1024 and 720x1280 |
| `M9-FC-06-Print60` | M8 progressive mask at 60% | 576x1024 and 720x1280 |
| `M9-FC-07-Print99` | Incomplete top; no full silhouette | 576x1024 and 720x1280 |
| `M9-FC-08-RawComplete` | First legal full raw; visibly disabled Back | 720x1280 |
| `M9-FC-09-RawHold` | Committed dormant hold | 576x1024 and 720x1280 |
| `M9-FC-10-Awakening` | Mid finite handoff | 576x1024 and 720x1280 |
| `M9-FC-11-Departing` | One subject leaving; no duplicate | 576x1024 and 720x1280 |
| `M9-FC-12-Done` | Clear bed and terminal receipt/actions | 576x1024 and 720x1280 |
| `M9-FC-13-Failed` | Truthful native error, Back and recovery | 576x1024 and 720x1280 |
| `M9-FC-14-PausedCaller` | Active Back at normalized 60%; caller visible | 720x1280 |
| `M9-FC-15-ResumedSameJob` | Same subject/60%/generation/caller; one parent | 720x1280 |
| `M9-FC-16-Text150` | Routine IDLE, 60%, done and failed, with focus | 576x1024 and 720x1280; 150% text |
| `M9-FC-17-HighContrast` | Starter IDLE, 60%, RAW_COMPLETE and failed | 720x1280; high contrast |
| `M9-FC-18-ReducedMotion` | 0/25/60/99, raw hold, awaken, depart and done held | 720x1280; reduced motion |
| `M9-FC-19-Tall` | Starter IDLE, routine IDLE, 60% and done | 1080x2400; production reserve 0 |
| `M9-FC-20-MissingLayerSafe` | Injected missing layer; native safe state, no old fallback | 576x1024 and 720x1280 |

- [ ] Original-resolution review of the complete map reports P0 none/P1 none for
  enclosure continuity, material family, crop/registration, no detached head/raft,
  native ink containment, exact one Back/control owner, 100%/150% text, high contrast,
  reduced motion, and reachable 48/56px controls.
- [ ] Previously reviewed non-Forge M9A route captures remain bound to unchanged
  candidate inputs, or the existing route matrix is rerun before sign-off. Prior
  Market/Archive/Deck/Founder/Workshop/Starter/recovery/Battle-exit/Settings/Result
  visual passes are retained evidence, never proof of changed pixels. Stress captures
  that changed logical canvas size do not replace production-base parity captures.

## Desktop evidence versus physical Android evidence

### Local desktop/input contract

- **Entry:** Run the candidate in isolated E:-scoped storage at the production
  576x1024 logical base and the required physical render sizes.
- **Player decision:** Use real pointer/touch-coordinate events, keyboard focus, and
  local WM/KEY/system-Back fixtures through the central dispatcher.
- **Result:** Deterministic route, authority, hit-testing, accessibility, captures,
  teardown, and dispatcher equivalence are evidenced locally.
- **Failure:** Direct signal/callback substitution, obstructed/dead targets, stale
  timers, mismatched visible/system traces, leaked processes, or wrong logical scale.
- **Disabled:** Desktop WM/KEY Back and injected `go_back_requested` cannot be called
  proof that Android delivered a native OS Back event.
- **Feedback:** Logs identify input source, hit control/rect, before/after snapshot,
  transitions/revisions, surface transform, PID/exit and cleanup.
- **Progression:** Navigation/render fixtures are zero-mutation except explicitly
  accepted Founder/pack/commit actions.

### Physical Android contract

- **Entry:** The audited candidate APK exists and `adb devices -l` shows exactly one
  authorized physical device, or the user has selected one serial.
- **Player decision:** Install/launch in portrait with isolated review data; use real
  touch and the device/system Back control through Title/Workshop, a pending Founder
  receipt with Resume Pack, Forge IDLE and active pause/resume, and live Battle's
  Concede/Stay shield; also visit representative management and six-hotspot Workshop
  routes.
- **Result:** The installed version `0.8.7-founder-navigation` / code `103` receives
  OS Back once per press with the same visible-Back consequence, retains accepted job
  and receipt state, launches/resumes without crash or ANR, and fills the usable
  portrait surface with no ad strip, blank reserve, overlap or clipped control.
- **Failure:** Wrong metadata/hash, install/launch/resume failure, landscape, crash/
  ANR, Back bypass/double callback, lost receipt/job, covered target, blank bottom
  band, or any ad initialization/request fails the affected device gate.
- **Disabled:** With no authorized physical device, record install, launch, touch,
  OS-Back, screenshot and live-log checks as `BLOCKED — no adb device`. An emulator,
  desktop capture, or injected event cannot turn them into PASS. The statically
  audited review APK may still be delivered with that truthful blocked status under
  the existing M5 rule.
- **Feedback:** Retain attributed device/API/orientation, install/launch commands and
  exits, portrait screenshots, focused Back traces and logcat without publishing
  unnecessary device identifiers.
- **Progression:** Device review uses isolated data and never overwrites a player's
  durable save or external/cloud data.

## No-AdMob Android and delivery gate

Locked candidate identity: portrait Android debug/review APK; package
`com.tak.printforge.legends.playtest`; display name
`PrintForge Legends Physical UI No-Ad Review`; version
`0.8.7-founder-navigation`; code `103`; ABI `arm64-v8a` only; additional production
bottom reserve `0`.

- [ ] Build/export begins only from the clean reviewed M9A commit. Record full commit
  hash, branch, Godot 4.7.1/template/Android tool identities, exact export command,
  task-owned PIDs, exit and cleanup. The APK and README use non-overwriting names
  `PrintForge-Legends-0.8.7-founder-navigation-arm64-<commit12>.apk` and
  `README-0.8.7-founder-navigation-<commit12>.md`.
- [ ] No-AdMob means absence. Source, dependency graph, resolved manifest, archive,
  resources, DEX/classes/strings and native-library scans contain no Google Mobile
  Ads/mediation/ad-services library, Godot ad addon/plugin/bridge, app/unit ID
  (including `ca-app-pub-` samples), ad metadata/component/provider/service/receiver,
  `AD_ID`/ad-only permission, request path, consent/telemetry path, placeholder or
  reserved band. `test_m5_android_no_ad` and archive audit pass.
- [ ] Static APK audit verifies package/version/code, portrait MAIN/LAUNCHER,
  arm64-only archive, approved launcher/adaptive resources, debug/review signature,
  required runtime assets, and exclusion of docs/tests/tools/source/evidence/secrets/
  credentials/keystores/logs. Record local bytes and SHA-256.
- [ ] When an authorized device exists, prove the installed APK is the same local
  byte/hash-qualified artifact and record the physical results above. Otherwise keep
  each physical-only claim explicitly BLOCKED.
- [ ] Copy only after all available gates to the observed studio folder
  `H:\My Drive\AI Projects\PrintForge`. Refuse an existing destination filename;
  never overwrite, delete, rename, or replace an earlier release. Verify local versus
  DriveFS APK bytes and SHA-256 exactly and verify the companion README copy.
- [ ] README binds the same full commit, metadata, ABI/orientation, debug signing,
  no-AdMob audit, tests/captures, device PASS/FAIL/BLOCKED outcomes, local/Drive paths,
  bytes/SHA and launch scope. Report `DriveFS copy: VERIFIED` only after comparison;
  report cloud visibility independently as `CONFIRMED` or `PENDING` and never infer it
  from the filesystem copy. The already-staged approved art receipt is not an APK or
  release-delivery receipt.

## Completion boundary

M9A may be reported complete only when the current Forge P1 hold is closed, the exact
candidate-commit logic and unchanged capture map above are reviewed, the clean
commit-qualified no-AdMob APK passes static audit, and the non-overwriting DriveFS
copy is hash verified with cloud status reported separately. Any unavailable physical
device evidence stays explicitly BLOCKED and cannot support a native-Android claim.
This checklist records requirements only; no unchecked item is a predicted PASS.
