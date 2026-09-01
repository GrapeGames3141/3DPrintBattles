# PrintForge physical UI M1 correction checkpoint v1

Status: M1 R10 gate PASS at `ecb0c0a`; M3 physical Title/navigation addendum PASS;
complete front-door gallery admitted under the screen-first production workflow

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

- **Entry:** Launch after platform and usable portrait safe area are known. The Title
  reads and classifies the valid clean-v3 save as completed, resumable onboarding,
  fresh/no persisted progress, or recovery/read-only without creating, advancing,
  resetting, or overwriting a profile.
- **Player decision:** With a completed profile, choose central primary Continue,
  lower secondary New Maker, or lower secondary Settings. The first New Maker
  activation opens a separate consequence confirmation only; the player must then
  explicitly Confirm New Maker or Cancel. With a fresh/no-progress profile, choose
  the truthful central primary New Maker to begin onboarding or open Settings. A
  resumable incomplete onboarding profile may Continue its exact saved onboarding
  step.
- **Result:** Completed-profile Continue performs zero profile/save mutation and
  enters the physical Workshop with printer, battle dais, archive folio, deck
  clipboard, supply cabinet, and settings instrument all present as six canonical
  hotspots. Confirm New Maker, and only that second explicit activation, performs one
  existing confirmed-new-profile transaction and enters starter/onboarding with no
  completed print or reward. Fresh New Maker creates/accepts the initial v3 profile
  exactly once and enters the same onboarding route without destructive-reset copy.
  Settings retains Title as caller; returning restores the same save classification,
  action availability, and onboarding eligibility and never opens Workshop directly.
- **Failure:** Missing, malformed, stale, unsupported, or read-only saves enter the
  existing recovery presentation. A failed New Maker persistence/promotion leaves the
  prior primary/backup profile and revision authoritative, remains on Title/Recovery,
  and does not enter onboarding. Failed settings load/apply leaves Title, profile,
  progression, and the caller unchanged and reports the exact failure.
- **Disabled:** Continue is absent or disabled without a valid resumable save. On a
  completed profile, New Maker can only open confirmation; background Continue,
  New Maker, and Settings are disabled while that confirmation or its transaction is
  active. Confirm New Maker is disabled while persistence is in flight and cannot be
  submitted twice. The destructive confirmation is never initial/default focus.
  Settings return is disabled only while an existing settings transaction requires a
  decision.
- **Feedback:** On a completed profile, Continue owns the central activation plaque
  and New Maker and Settings own two separate lower physical actions; neither lower
  action overlaps, masquerades as, or shares Continue's target. On a fresh profile,
  the central plaque truthfully reads New Maker rather than a false Continue. All
  labels, consequence/confirmation copy, version, loading/recovery status, disabled
  reasons, accessibility names, and focus are native and readable at 150%. Continue
  is at least 56 logical pixels; New Maker and Settings are at least 48; every target
  has a complete four-edge focus ring. Reading/focus order is central action, lower
  New Maker when present, then lower Settings.
- **Progression:** Title inspection, Continue, Settings, first-step New Maker,
  confirmation Cancel, failed persistence, and Settings return are zero-mutation.
  Only one accepted fresh-profile creation or second-step Confirm New Maker may write
  the v3 profile/reset onboarding. It cannot mark onboarding complete, create a
  printed model, grant a pack/reward, or bypass starter selection/first print.

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
2. Completed-profile Title exposes central Continue plus separate lower New Maker and
   Settings actions. Continue enters the six-hotspot Workshop without mutation.
   First-step New Maker and Cancel preserve the exact serialized profile/revision;
   only second-step Confirm writes once. Persistence failure preserves the existing
   profile. Fresh Title truthfully starts onboarding. Title Settings returns to Title
   with its prior classification/onboarding eligibility unchanged and never lands
   directly in Workshop.
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

## M3 real-launch Title navigation addendum

### R1 evidence disposition

- Evidence root: `build/evidence/m3-navigation-r1`.
- `M3-NV-02-576x1024.png` and `M3-NV-02-720x1280.png` pass the physical Workshop
  launch composition: all six canonical hotspots are present and physically owned.
- `M3-NV-01-576x1024.png` and `M3-NV-01-720x1280.png` are held for correction. They
  prove a readable central Continue and lower Settings action, but omit the required
  completed-profile New Maker action and therefore do not satisfy the authoritative
  front-door decision.
- Read-only UI review reported no unresolved P0. The hold is a bounded title
  hierarchy/navigation contract correction; it does not invalidate the approved
  Workshop proof or authorize any gameplay/save-schema change.

### Deterministic correction acceptance

1. At `576x1024` and `720x1280`, a completed-profile Title contains exactly one
   central 56-pixel-or-larger Continue action and two distinct lower 48-pixel-or-larger
   actions: New Maker and Settings. All three are physically seated, nonoverlapping,
   natively labeled, accessibility named, reachable, and four-edge focused.
2. Activating Continue once dispatches one canonical Title→Workshop route, changes no
   profile field/revision/journal/save byte, and exposes the six live Workshop targets:
   printer, battle dais, archive folio, deck clipboard, supply cabinet, and settings.
   Repeated activation while routing cannot dispatch a second transition.
3. On a completed profile, one New Maker activation changes no profile/save state and
   opens an explicit confirmation with native consequence copy, 56-pixel Confirm New
   Maker, and Cancel. Cancel, Back, focus movement, outside dismissal where supported,
   and route rebuild preserve the exact serialized profile and revision.
4. Confirm New Maker is a separate second activation. One accepted confirmation uses
   the existing confirmed-new-profile path exactly once, invalidates late callbacks,
   and enters starter/onboarding without completed state, model, deck reward, pending
   pack, or battle reward. Double tap cannot produce a second write/reset.
5. A forced snapshot/journal/promotion failure during Confirm preserves the prior
   valid primary/backup and in-memory profile, does not enter onboarding, and gives a
   native retry/recovery result. Retry first rereads current storage; it never blindly
   replays an ambiguous destructive transition.
6. With no compatible persisted progress, Title does not offer a misleading Continue.
   The central primary is truthful New Maker; one accepted initial-profile creation
   enters the first onboarding/starter decision and no later progression state.
   Recovery/read-only saves retain their existing recovery route and cannot be reset
   by an unconfirmed title activation.
7. Title Settings opens without mutation and returns to the same Title classification,
   same completed/fresh/incomplete actions, same onboarding eligibility, and same
   profile revision. It never routes directly to Workshop or starter selection.
8. Reduced motion removes only finite plaque/confirmation movement. High contrast and
   150% text preserve all three completed-profile actions, confirmation consequences,
   focus edges, safe-area clearance, and bottom production reserve zero. Pointer mode
   remains visible and unrestricted.

The R1 hold required a deterministic completed Title, New Maker confirmation, fresh
Title, Settings return, and Continue→six-hotspot Workshop at both portrait sizes,
plus the existing profile-before/after acceptance for first activation, Cancel,
persistence failure, accepted Confirm, Settings return, and Continue. The physical
replacement gallery requirement is satisfied by the R2/R3 closeout below. Rendered
captures establish the visible route outcomes and geometry; the deterministic
mutation criteria above remain the rule/test authority and are not inferred from
pixels alone.

### R2/R3 physical Title gallery closeout

- Evidence roots: `build/evidence/m3-title-navigation-r2` and
  `build/evidence/m3-title-navigation-r3`.
- Read-only original-resolution UI review: **PASS**, P0 none, P1 none, across
  `M3-NV-01` through `M3-NV-05` from R2 and `M3-AX-03` from R3 at both
  `576x1024` and `720x1280`.
- `M3-NV-01` admits the corrected completed-profile Title: central Continue plus
  separate lower New Maker and Settings physical actions.
- `M3-NV-02` admits Continue's six-hotspot Workshop outcome: printer, battle dais,
  archive folio, deck clipboard, supply cabinet, and settings instrument.
- `M3-NV-03` admits the explicit second-step Confirm New Maker/Cancel state and its
  native consequence copy; no one-tap destructive action is visually exposed.
- `M3-NV-04` admits the truthful fresh-profile Title with central New Maker and
  Settings, without a misleading Continue.
- `M3-NV-05` admits the Settings caller-safe round trip back to the completed-profile
  Title hierarchy.
- `M3-AX-03` admits the accessibility stress presentation at both portrait sizes,
  preserving the three completed-profile actions, native labels, physical seating,
  safe bounds, and complete focus treatment.

The completed Title/navigation gallery is admitted and the R1 visual hold is closed.
This closeout does not claim Android/device behavior, native AdMob geometry, build or
signing acceptance, Google Drive delivery, or cloud synchronization; those remain M4.
