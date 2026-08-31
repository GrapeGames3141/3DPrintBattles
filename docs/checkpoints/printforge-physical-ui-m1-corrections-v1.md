# PrintForge physical UI M1 correction checkpoint v1

Status: M1 runtime and visual correction gate PASS; M2 authorized under the
screen-first production workflow

Date: 2026-08-31

Authority: `docs/checkpoints/printforge-physical-ui-preproduction-v1.md` and
`docs/design/printforge-screen-first-gameplay-v1.md` remain the approved product
and deterministic-rule authorities. This checkpoint narrows M1 acceptance only; it
does not authorize gameplay, economy, catalog, save-schema, art-direction, or
orientation changes.

## Shared M1 interaction contract

- Portrait only. Preserve the approved physical Workshop materials and hierarchy,
  native dynamic text, 48-logical-pixel minimum targets, 56-logical-pixel primary
  actions, 150% text, high contrast, reduced motion, safe-area handling, and the
  approved no-P0 visual gate.
- Keyboard/controller focus on every M1 target is a complete visible rectangle with
  top, right, bottom, and left edges. No edge may be constructed but omitted, zero
  sized, clipped, or hidden by generated art.
- M1 runtime, capture, and automated-test code must never set captured or confined
  pointer mode. Pointer mode remains visible and unrestricted after launch, route
  changes, captures, failures, and test cleanup.
- Rejections and unavailable routes preserve the exact profile, onboarding, Forge,
  reward, and save state. A legacy route may be used only when it is the intended
  destination; there is no silent fallback to Workshop.

## Title / resume / New Maker / Settings

- **Entry:** Launch after platform and usable portrait safe area are known. The title
  reads the valid-clean-v3 save state without creating, advancing, or overwriting a
  profile.
- **Player decision:** Choose Continue when a valid resumable profile exists, choose
  New Maker to enter fresh onboarding, or open Settings and return.
- **Result:** Continue restores the saved stable route. New Maker enters the first
  Workshop-arrival/onboarding route through the existing confirmed-new-profile flow.
  Settings opened from Title retains Title as its return destination; returning from
  Settings restores the same title/onboarding eligibility state and never opens
  Workshop directly.
- **Failure:** Missing, invalid, stale, or unsupported saves enter the existing
  recovery presentation. Failed settings load/apply leaves the title route and
  progression unchanged and reports the failure.
- **Disabled:** Continue is disabled without a valid resumable save. New Maker is
  disabled while overwrite confirmation or a profile transaction is pending.
  Settings return is disabled only while an existing settings transaction requires a
  decision.
- **Feedback:** Native title, version, loading, recovery, disabled reason, focus, and
  return-state text remain readable at 150%. Every title target shows the complete
  four-edge focus ring.
- **Progression:** Title inspection and Settings are zero-mutation. Only the existing
  confirmed New Maker transaction may create/reset onboarding state; Settings return
  cannot mark onboarding complete or bypass starter selection/first print.

## Workshop physical navigation

- **Entry:** Enter after onboarding completion or from an existing stable primary
  return. The physical Workshop loads all six accessible targets: printer, battle
  dais, archive folio, deck clipboard, supplies cabinet, and settings instrument.
- **Player decision:** Activate exactly one physical target by touch, mouse,
  keyboard, controller, or accessibility action.
- **Result:** Printer opens the Forge/print route; battle dais opens the challenge
  board/preflight route; archive folio opens Collection; deck clipboard opens the
  deck/preprint workbench; supplies cabinet opens Supply/Market; settings instrument
  opens Settings with Workshop as its return destination. Each of the six physical
  controls dispatches through the canonical destination callback, including deck,
  supplies, and settings; none depends on a mismatched legacy hotspot identifier.
- **Failure:** An unavailable, unimplemented, stale, or rejected destination leaves
  the player in Workshop, changes no profile state, and gives the route-specific
  reason. It never silently does nothing and never redirects to an unrelated route.
- **Disabled:** A locked destination remains visible, focusable, and non-activating,
  with a native reason. Input is disabled during an accepted route transition or
  blocking modal so double activation cannot dispatch twice.
- **Feedback:** Each object has a distinct physical silhouette, native short label,
  accessibility name, visible touch affordance, 48-logical-pixel target, complete
  four-edge focus ring, and appropriate status/badge. Ambient motion never obscures
  focus or captures/confines the pointer.
- **Progression:** Inspecting, focusing, or opening navigation routes is zero-mutation.
  Progression occurs only inside the authoritative destination transaction.

## Starter carousel / inspect / confirm

- **Entry:** Fresh onboarding exposes exactly the catalog starters Cinderpaw,
  Aquafin, and Voltwig with one valid focused artifact.
- **Player decision:** Swipe or use previous/next to change focus, inspect the focused
  artifact, dismiss inspection, or confirm the focused starter through a separate
  explicit action.
- **Result:** Navigation changes presentation focus only. Inspect displays the
  focused catalog values. One accepted Confirm grants the selected first creature
  card and its permanent printable blueprint exactly once, then enters First Print
  setup with that same selected artifact.
- **Failure:** Invalid focus, stale selection, duplicate confirmation, catalog
  mismatch, save failure, or rejected revision leaves the profile and current
  selection transaction unchanged and reports the failure.
- **Disabled:** Confirm is disabled without a valid focused starter or while confirm
  is pending. Inspect cannot confirm. A nonfocused artifact cannot be confirmed.
  Carousel input is disabled only during its accepted route transaction.
- **Feedback:** Native name, element, HP, Bend, cost, duration, ability information,
  position, inspection state, disabled reason, accessibility name, and complete
  four-edge focus ring remain legible at 150% text. Generated art contains no dynamic
  values or interactive state.
- **Progression:** Browse and Inspect are zero-mutation. Exactly one accepted Confirm
  performs the existing starter grant; it does not create a printed model, complete
  onboarding, or grant packs. Automated starter tests must set isolated test-local
  SaveService/profile paths before any mutation and must prove the real player save
  path is untouched.

## First Print setup

- **Entry:** Enter immediately after accepted starter confirmation with the selected
  starter blueprint, an empty printer bed, no completed creature on the bed, and no
  print transaction committed.
- **Player decision:** Inspect the native recipe/status, start the affordable valid
  first print, return before commit when legal, or use presentation skip only after a
  print presentation is running.
- **Result:** The approved text-free ImageGen blueprint cartridge master is shown as
  the selected starter's docked physical cartridge outside the printer chamber. Start
  invokes the existing exactly-once print flow: cyan wireframe seed, solid layers
  below the scan line, wireframe above, raw hold, awakening, and departure. Raw
  completion commits exactly one model, one debit, and one revision before onboarding
  completion and the existing three-pack entitlement sequence.
- **Failure:** Unaffordable, stale, duplicate, catalog, asset-load, or save failure
  adds no model, debit, revision, onboarding completion, or reward. Failure remains
  visible and retryable under existing authority. A missing decorative asset falls
  back to a truthful native unavailable state, never to a finished creature.
- **Disabled:** Start is disabled while unaffordable, invalid, unselected, pending, or
  already committed. Skip is disabled before presentation starts and cannot bypass a
  required decision, failure, debit, commit, or save. Return is disabled only where
  the authoritative first-print transaction already forbids leaving.
- **Feedback:** Use
  `docs/art/printforge-physical-ui-spike-20260830/runtime-masters/blueprint-cartridge-text-free-v1.png`
  as the approved source; runtime integration uses approved crop
  `Rect2i(96, 0, 584, 2172)`, keeps aspect ratio, ignores pointer input, remains
  outside the printer chamber, and exposes native accessibility text
  `Docked blueprint: <selected starter name>`. Recipe, layers, ETA, status, receipt,
  errors, focus, and dynamic starter name remain native. Promotion requires the
  runtime-art manifest to record source dimensions 724x2172, SHA-256
  `66F50A5B85B45762C602556FF32A847D2BE72D03D59443845460C0DEA5AF4367`,
  generator prompt/provenance, crop, approval, and rejected alternatives.
- **Progression:** Setup and inspection are zero-mutation. The existing raw-completion
  boundary alone commits the model/debit/revision. Awakening/departure presentation
  completes onboarding and exposes exactly three sequential five-card Basic
  entitlements under existing receipt rules; repeated completion or reload cannot
  grant a fourth.

## Native-bottom AdMob boundary

- **Entry:** An approved Android review build initializes a native bottom banner with
  Google test configuration only after the native host owns the usable portrait
  surface. Desktop/editor/plugin-absent/config-blocked builds initialize no ad
  request.
- **Player decision:** There is no gameplay, reward, or progression decision. Any
  required consent remains native and separate from Godot gameplay.
- **Result:** The native Android view owns the creative height and bottom navigation
  or gesture inset outside Godot. Godot receives the resized usable surface and uses
  production reserve zero. All M1 controls remain within the Godot surface.
- **Failure:** Load failure, no-fill, offline state, SDK absence, or config block
  collapses the native view and restores the usable surface without a blank band,
  covered control, duplicated disclosure, or gameplay mutation.
- **Disabled:** Production app/unit IDs remain unset. Rewarded ads, ad-gated
  progression, ad-derived currency, and production requests are disabled. A positive
  Godot-side reserve is forbidden in production.
- **Feedback:** Native disclosure appears only with the native creative. Diagnostic
  native height remains separate from layout ownership. Any positive-reserve capture
  is explicitly and visibly labeled `SYNTHETIC AD OVERLAY STRESS`; it is never
  presented as production geometry.
- **Progression:** Ad availability, size, success, failure, and consent alter no RNG,
  Forge/battle time, revision, save, currency, reward, input, or entitlement.

## M1 correction acceptance matrix

M1 correction may pass only when evidence proves all of the following without
changing deterministic authority or save schema:

1. Automated input presses all six Workshop controls through their physical control
   nodes and observes the six canonical destinations, including deck, supplies, and
   settings. Unavailable-route coverage observes a native reason and zero mutation.
2. Title Settings opens and returns to Title with onboarding eligibility unchanged;
   no path lands directly in Workshop. Continue-disabled and confirmed-New-Maker
   states remain distinct.
3. Starter swipe/previous/next, focused inspection, separate confirm, duplicate/stale
   rejection, exactly-once grant, and test-local SaveService isolation pass. Evidence
   identifies the isolated save root and proves the player save is unchanged.
4. Focus evidence and assertions cover top, right, bottom, and left edges around a
   target at both 576x1024 and 720x1280; 150% text and high-contrast evidence remains
   unclipped.
5. First Print setup proves an empty bed; an AtlasTexture or equivalent approved crop
   of the text-free cartridge; its bounds wholly outside the printer chamber; native
   selected-starter accessibility text; and zero mutation before Start. Exactly-once
   print assertions remain green.
6. Source and test scans find no captured/confined pointer assignment in M1 runtime or
   capture code. Launch, route changes, capture completion, failure, and cleanup leave
   the pointer visible and unrestricted.
7. Production-layout assertions prove Godot ad reserve equals zero. The positive
   fixture is visibly labeled synthetic, and load/failure/resize/safe-inset states
   preserve usable controls without deterministic mutation.
8. Final portrait captures at 576x1024 and 720x1280 cover Title, Workshop, focused
   Workshop, 150% text, high contrast, Starter focused, Starter inspect, First Print
   setup, and the labeled synthetic fixture. Read-only UI review has no P0/P1 finding
   before Sol marks M1 complete.

## Gate state

### R10 evidence record

- Evidence root:
  `build/evidence/m1-portrait-shell-20260830/captures-r10`.
- Capture inventory: 43 original-resolution images: 21 at 576x1024, 21 at
  720x1280, and one tall Android-layout fixture at 1080x2400.
- Read-only UI review: PASS with no P0 or P1 finding.
- Focused Godot 4.7.1 validations all exited 0: boundary PID 44512, geometry PID
  46072, navigation PID 47308, starter PID 44468, runtime-art manifest PID 48064,
  and unified UI PID 44904.
- Pointer-safety scan found zero captured, confined, or hidden pointer assignments.
  No task-started Godot process remained active at closeout.
- Approved cartridge verification: 2,161,030 bytes; SHA-256
  `66F50A5B85B45762C602556FF32A847D2BE72D03D59443845460C0DEA5AF4367`.
- `git diff --check` passed for the reviewed correction set.
- The run is not claimed stderr-clean. Baseline environment warnings remained for
  the Windows certificate store, sandbox-user persistence, headless dummy renderer,
  and ObjectDB/RID teardown. They did not change the focused exit-0 results, but they
  remain environment/test-harness observations rather than resolved product defects.
- No real-device or native-AdMob behavior is claimed by M1. Native banner load,
  failure/no-fill, resize, safe-inset ownership, and real-device screenshot evidence
  remain mandatory M4 work. Production identifiers remain unset.

### Accepted P2 backlog

- Remove redundant visible Previous/Next text where the authored carousel arrows
  already communicate navigation; preserve native accessibility names and targets.
- Polish the starter inspector plaque so long catalog names retain the approved
  physical hierarchy at 100% and 150% text.
- Tighten focus visuals around physical-object silhouettes while preserving complete
  four-edge focus, contrast, and 48-logical-pixel targets.

Product decisions PASS. Approved atlas PASS. M1 R10 runtime corrections PASS.
Focused validations PASS. Read-only visual review PASS with no P0/P1. The accepted P2
items do not reopen M1. M2 is authorized under the existing designer → Sol → sole
runtime writer → read-only UI reviewer → Sol audit workflow. This checkpoint makes no
gameplay-rule or save-schema change and does not authorize an Android build, native
AdMob completion claim, or Drive delivery.
