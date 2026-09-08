# PrintForge M10 UI alignment repair checkpoint v1

Status: **Android 0.8.9 / code 105 built, verified, and delivered to DriveFS;
cloud synchronization unconfirmed; physical-device acceptance not performed**

Date: 2026-09-08

Authority: `docs/design/printforge-screen-first-gameplay-v1.md`,
`docs/design/printforge-legends-mechanics-v3.1.md` (document title mechanics v3.2),
`docs/checkpoints/printforge-m9a-review-ledger.md`, and the approved physical UI,
blueprint, Forge-continuity, control-family, title, and card-back assets already in the
repository.

This checkpoint repairs registration, spacing, typography, scaling, clipping, focus,
and touch geometry only. It creates no new art and changes no gameplay rule, catalog
value, deck, ownership, print, battle, economy, reward, profile, receipt, or save
schema. Gameplay changes belong to the separate unapproved proposal document
`docs/design/m10-gameplay-proposals-v1.md`.

## Locked boundaries

- Portrait only. The production logical reference remains 576x1024. Supplemental
  review uses 720x1280 and the existing tall fixtures. A 24-logical-pixel OS safe-top
  inset is validated only for Workshop and Starter; other tall/aspect captures are
  layout stress evidence and make no OS-inset claim.
- Reuse the existing approved illustrated atlas, title, Workshop, Forge enclosure,
  transparent blueprint family, physical controls, character art/sprites, and exact
  card back. No ImageGen generation, art replacement, runtime-art promotion, or
  aesthetic redirection is in scope.
- One visible element has one owner. Static scenery stays in its approved plate;
  names, values, labels, status, focus, accessibility, hit regions, and state remain
  native Godot controls. A native layer may not duplicate a baked object or title.
- Preserve the existing Plan -> Run Cycle presentation and all deterministic
  Draw/Main/Print/Attack/Collect authority. Preserve the shipped Founder, Deck,
  Market, print, Back, receipt, and save behavior. Neither the previously approved
  but unfinished x10 exposed-printer rule nor the newly proposed, unapproved
  200-HP/+50-Chassis replacement is part of this alignment implementation.
- Preserve the current no-ad review flavor. No ad-shaped spacer is added. If a future
  native-bottom host banner flavor is restored under separate authority, the native
  host owns its creative and bottom safe inset and the Godot game-content reserve
  remains zero.
- Every touch target remains at least 48 logical pixels; primary actions and Back are
  at least 56. Every focused target shows an unclipped four-edge state. All full
  accessibility names remain native even when visible copy abbreviates.

## M10-A1 — shared portrait registration

- **Entry:** Any Title, onboarding, Workshop, Forge, management, reward, recovery, or
  battle route renders or rerenders after a viewport or safe-area change.
- **Player decision:** Inspect or activate any existing route control; layout itself
  adds no decision.
- **Result:** The approved static plate and native layer share the route's existing
  safe content rect and authored transform. Native text, images, controls, scroll
  rails, and state marks register to their measured illustrated seats. Repeated rows
  share visually consistent alignment and spacing appropriate to that specific plate.
- **Failure:** If the content cannot fit, the route uses its existing deterministic
  wrap, abbreviation, reflow, scroll owner, or approved tall-surface presenter. It
  does not cross a metal/paper rim, clip a required action, distort a foreground
  object independently from its plate, or add an overlapping fallback.
- **Disabled:** Hidden or disabled controls retain their physical seats without
  creating invisible hit surfaces over another target. Gameplay-disabled controls
  keep their existing reason and transaction behavior.
- **Feedback:** Resize/safe-area response is visually stable; focus, hover, pressed,
  selected, disabled, warning, high-contrast, and reduced-motion states remain aligned
  to the same seat.
- **Progression:** Layout and rerender are zero-mutation. Existing accepted callbacks
  remain the sole source of progression.

Acceptance:

1. The runtime plate covers the full usable portrait surface without unintended
   letterboxing, a bottom void, or duplicate inset.
2. No visible sibling rectangles overlap unless the approved composition explicitly
   layers them; hit rectangles never overlap unrelated controls.
3. Header, content, status, and action zones remain in the same reading order at all
   required sizes, including 150% text.

## M10-A2 — native copy seated in physical hardware

- **Entry:** A physical plate, plaque, tab, dial, receipt, book label, clipboard row,
  card caption, or printer instrument owns dynamic native copy.
- **Player decision:** Read, focus, inspect, select, or activate the existing control.
- **Result:** Copy is centered on its intended face or deliberately left-aligned to
  its paper text column. Text respects the measured seat-specific inset, uses a
  consistent baseline within repeated rows, and never crosses a rim, screw, card art
  aperture, image, or adjacent control.
- **Failure:** Long copy wraps to its declared line count, abbreviates only approved
  visible units, or moves into the route's existing scroll/detail owner. It does not
  shrink below the route's readable type floor or silently ellipsize authoritative
  values.
- **Disabled:** Disabled captions retain readable contrast and remain centered within
  the same hardware; they do not acquire active hover/press treatment.
- **Feedback:** Selected and warning states use shape/outline plus native copy, not
  color alone. The full value and reason remain available through the accessibility
  name or tooltip when visible copy is abbreviated.
- **Progression:** Reading, wrapping, focus, and overflow handling are zero-mutation.

Acceptance:

1. Text baselines and optical centers in a repeated row visibly align to the same
   authored seat at the 576 reference size.
2. Control copy remains inside its measured physical face clearance at normal and
   150% text.
3. `Back`, primary actions, page controls, category tabs, `Run Cycle`, and receipt
   actions are optically centered, not merely centered in a larger transparent crop.
4. Dynamic labels never paint light ink on light parchment or dark ink on dark wood;
   high contrast remains distinguishable without relying only on color.

## M10-A3 — image containment and card/blueprint registration

- **Entry:** Existing creature art, blueprint ink, support-card art, equipment art,
  reward art, or card back is placed into a card, folio, clipboard, Forge cartridge,
  print bed, hand rail, or battlefield seat.
- **Player decision:** Browse, focus, select, queue, inspect, page, or dismiss through
  the existing legal action.
- **Result:** The source keeps aspect ratio, is centered within the intended aperture,
  and is clipped by that aperture before labels or controls are layered. Transparent
  blueprint ink reads as printed on the owning paper. A living battlefield creature
  uses one existing animated sprite at its legal anchor; the rival concealed hand
  uses the exact card back.
- **Failure:** Missing or malformed art uses the existing truthful native unavailable
  state. It never stretches, substitutes another creature, falls back to rejected
  blueprint art, or spills onto a book margin/control face.
- **Disabled:** Unavailable or gameplay-illegal actions cannot show an active action
  state. Existing legal inspection of unowned cards and blueprints remains available;
  inspection never implies ownership or permission to print, equip, or add a copy.
- **Feedback:** Focus and selection stay outside the image aperture and respect the
  existing measured native-label clearance. Clipping produces no alpha fringe,
  neighboring-atlas bleed, or card-art overlap.
- **Progression:** Image fit, paging, focus, and inspection are zero-mutation; existing
  starter, Deck, print, purchase, and Keep transactions remain exactly once.

Acceptance:

1. No character/card image is non-uniformly scaled; no art crosses its paper, card,
   bed, socket, or field aperture.
2. Archive and Deck folios integrate blueprint/card images into the page instead of
   floating opaque rectangles over it.
3. Hand cards remain individually reachable; a partial next-card affordance may be
   shown only when it does not clip the active card's name, cost, or hit target.
4. Blueprint, extrusion, raw/awakening, and living-sprite representations remain
   distinct under the existing approved state-ownership contract.

## M10-A4 — battle information hierarchy alignment

- **Entry:** Battle Preflight, player Plan, rival resolution, Run Cycle presentation,
  placement/attachment/overflow choice, Back confirmation, or Result is visible.
- **Player decision:** Use only existing legal hand, target, queue, mode, required
  choice, Back, or Run Cycle controls.
- **Result:** Rival printer/HP/queue occupy the upper instrument group; the battlefield
  and three anchors remain central; player printer/HP/filament/queue form the lower
  instrument group; the event/status rail sits above the hand; the hand and selected
  action occupy one non-overlapping bottom rail; Run Cycle remains a separate primary
  lever. Current-turn and pending-choice copy has one obvious owner.
- **Failure:** If copy or hand width exceeds the available area, the declared rail
  scrolls or reflows while printers, HP, legal targets, status, Back, and Run Cycle
  remain visible and reachable. It never covers a creature, target anchor, card, or
  another control.
- **Disabled:** During Run Cycle or a modal/required choice, Plan controls remain
  visibly locked with the current reason; background Back is excluded from focus and
  hit testing while its confirmation owns input.
- **Feedback:** The selected hand card, its legal action, legal targets, queued head,
  current status/event, and Run Cycle state are spatially distinct. Printer HP and
  applied damage remain readable before, during, and after attack contact.
- **Progression:** This checkpoint changes presentation only. It does not implement
  the separately approved but unfinished x10 exposed-printer damage rule or any new
  battle cadence.

Acceptance:

1. No battle text or control intersects a creature anchor, printer body, printer HP
   instrument, card art, hand rail, event rail, Back shield, or Run Cycle lever.
2. Selected-card art/copy and action controls form one aligned group; target anchors
   do not activate until the current authoritative state declares them legal.
3. Rival hand remains concealed and noninteractive; player cards remain face-up and
   reachable in horizontal scrolling at eight-card hand limit.
4. At 150% text, the exact selected-card name/cost/type, current status, both printer
   HP values, Back, and Run Cycle remain visible without clipping.

## M10-A5 — navigation, focus, and state continuity

- **Entry:** A player enters a route with an existing Back/return action, changes a
  filter/page/selection, opens a confirmation, or receives a validation error.
- **Player decision:** Activate the route's existing visible exit (Back, Continue, Keep,
  Stay, or other canonical action), use native Android Back where already defined,
  dismiss a modal, or retry.
- **Result:** Each visible exit and native Android Back retain the existing route owner,
  destination, debounce, lock, and confirmation. Return restores the caller's relevant
  focus, scroll, page, selection, Forge stage, pending receipt, or battle state. Result
  keeps Continue as its canonical sole exit; M10 does not add a redundant Back.
- **Failure:** A missing destination, rejected transaction, save failure, or invalid
  state remains on the safe current route with native reason and reachable retry/Back.
  It never silently does nothing or advances through a layout fallback.
- **Disabled:** A route exit is disabled only under its existing commit or
  required-decision lock and shows the exact reason. A modal shields all background
  hit and focus owners.
- **Feedback:** Every target has a complete four-edge focus outline and a visible
  pressed/selected/disabled treatment seated on its physical object.
- **Progression:** Back, focus restoration, dismissal, and retry presentation are
  zero-mutation unless the player separately confirms an existing Concede, Discard,
  Exit, or other authoritative transaction.

Acceptance:

1. Every route retains its existing visible canonical exit and native Android Back
   behavior; this repair adds no redundant Result Back or changed navigation rule.
2. Focus order follows visual reading order and never lands on hidden, background,
   rival-private, or disabled controls.
3. No route loses a pending pack, Deck edit, print stage, battle snapshot, or caller
   selection merely because the viewport changes or the player returns.

## Required evidence and release gate

The sole runtime writer must first make the smallest shared-helper/layout correction
that satisfies the contracts, then capture actual runtime screens. No new art is
required or authorized.

Required evidence begins with a read-only baseline review of all current routes. The
implementation manifest then identifies every route whose runtime layout changed.

Required changed-route source-gate captures use the 576 reference width:

- The normal state that exposed each reported alignment defect.
- The same route's selected/focused, longest-copy, disabled, or error state when that
  state exercises the changed geometry.

Supplemental accessibility/stress review, which does not reopen the passed source
gate unless it exposes a P0/P1 regression, is underway:

- Changed routes at 150% text + high contrast + reduced motion, including 720x1280.
- Tall/aspect layout stress with zero Godot bottom reserve. Only Workshop and Starter
  currently qualify as safe-top-24 OS-inset evidence.
- Existing focused tests plus one representative unchanged capture verify that Forge
  continuity, 60% print state, awakening, battle contact, card back, and animation
  ownership did not regress; a new full animation/state atlas is not required.

The evidence manifest records route/state, logical viewport, physical viewport, safe
insets, text scale, contrast, motion, expected plate/art identity, and screenshot path.
Automated geometry checks must assert target minimums, non-overlap, rim clearance,
focus clearance, image aspect preservation, safe-rect containment, and Back parity.
Focused deterministic gameplay/save/receipt suites must remain unchanged where the
checkpoint does not intentionally change presentation metadata. Retired suites whose
assertions encode superseded UI/art are classified separately and cannot be reported
as current acceptance failures or as passing current evidence.

The source and changed-route visual gate is complete: Sol and read-only UI review
report no P0/P1 in the admitted original-resolution set, and the named focused input
and deterministic gates below pass. Android release remains blocked on packaging. The
next candidate is 0.8.9 / code 105 using a new versioned non-overwriting filename;
metadata, signing, portrait, no-ad, package-content, launch, and artifact hash checks
remain required before copying it to the established Google DriveFS release folder.
DriveFS copy verification and cloud-visible synchronization must be reported
separately.

## Source and changed-route visual gate closeout — 2026-09-08

Root's focused core regression batch passes eight suites: `unified_rules`,
`catalog_contract`, `founder_progression`, `upgrade_profiles`,
`missing_grant_upgrade`, `m2_cycle`, `forge_lifecycle`, and `progressive_reveal`.
Detailed process and suite records are under
`build/evidence/m10-ui-alignment-20260908/root-core`.

The final read-only UI review reports PASS with no P0/P1 for the admitted final set:

- `root-final/battle-contain-final/capture.png`;
- `root-final/settings-hc576-final/capture.png`;
- `root-final/deck-hc576-final/capture.png`; and
- `root-final/workshop-hc576-final/capture.png`.

The battle containment capture is an accepted 576x1152 contain-fit case. Its neutral
top/bottom margins preserve the approved plate's aspect; they are not an ad reserve,
native banner, gameplay spacer, or failure to fill a 576x1024 production surface.
Supplemental 720 accessibility and tall review also passes. The synthetic 24px
safe-top claim remains limited to Workshop and Starter.

`root-final/m2-status-r4` supersedes the earlier focused M2 battle UI pass. It also
checks equipment, spells, Emergency Reprint, raw filament, and the Filament Ring's
instant-use exception against the compact action rail. Selected support instructions
remain inside the status parchment, while full names/costs/types/details remain native
tooltip/accessibility metadata. The corrected test compares complete metadata instead
of searching for an empty optional description. No card effect or targeting rule changed.
`root-final/deck-input-576-final` passes real paging through all 40 edits, Save/Activate,
reload, and bot consumption. `root-final/back-parity-final` passes all 18/18 route
subcases; its Godot PID 69100 exited 0.

The legacy M3 suite fails stale assertions for uppercase `BACK`, retired route state,
and old art. The M7 suite requires retired open-gantry Forge nodes. These results are
preserved as legacy incompatibilities; this checkpoint does not claim that all
repository tests are green. Standalone `--script` probes that lack project autoloads
are not valid runtime gates and contribute no acceptance claim.

The progressive-reveal run retains an `AudioStreamGeneratorPlayback` exit leak after
WASAPI falls back to the Dummy audio host. The focused behavior passes, but validation
is not stderr/teardown-clean and M10 includes no runtime audio fix. Android delivery
followed the source gate and is recorded below; it does not erase these limitations.

Maintainability review: native Battle seats now share the existing portrait composition
transform; secondary Battle actions share one width/font/accessibility helper; Settings
parchment ink has one local override helper; the Deck owns exactly five measured paper
cells per page. No duplicate gameplay authority, save schema, asset family, or per-frame
texture allocation was introduced by this repair. Other untracked art/import files are
preserved outside this checkpoint.

## Android and Drive delivery — 2026-09-08

Source commit: `9ae3cb63b84f515f148432b338d2450cb36b202c` on
`spike/printforge-physical-ui`. Final read-only review also passes the frozen
`root-final/battle-equipment-hc576-r4/capture.png` and
`root-final/battle-creature576-release/capture.png`.

Artifact: `PrintForge-Legends-0.8.9-ui-alignment-arm64-9ae3cb63b84f.apk`.

- Version `0.8.9-ui-alignment`, code 105, package
  `com.tak.printforge.legends.playtest`, arm64 only, portrait, no ads.
- 241,317,617 bytes; SHA-256
  `E068A9B9E9D5CB89AEFA7961EFF0F0046DC9E294A9FE96F3123750B37704F381`.
- Same signing certificate as 0.8.8; v2/v3 signatures and 16 KB ZIP alignment pass.
- Static metadata, launcher, expected runtime art, exclusion/ad scan, and all 15
  stock DEX/native dependencies pass. Legacy AAPT cannot parse a template-injected
  feature boolean; AAPT2 succeeds. The optional themed-icon resource warning also
  occurs in the previous 0.8.8 APK and remains recorded, not silently repaired.
- Six actual source/shipped-runtime package probes pass. Both expose 57 face-up
  catalog cards; both rendered 576x1024 and 720x1280 flows complete real Deck edits,
  owned-card paging, save/activate/reload, and bot opening with the exact multiset.
  All 611 extracted runtime entries (211,100,855 bytes) remain unchanged by size/SHA
  after testing; the signed APK hash also remains unchanged.
- Export PID 52860 exited 0. Probe PIDs 46392, 1608, 68052, 58416, 67252, and 65276
  all exited 0; no task-owned Godot or error-dialog survivors remained. The first
  restricted export (PID 69660) failed cache-directory access and was cleaned;
  the authorized retry used the existing E: portable tool cache, without ACL edits.

APK and `README-0.8.9-ui-alignment-9ae3cb63b84f.md` were copied without overwriting
any prior release to `H:\My Drive\AI Projects\PrintForge`. Both destination sizes
and SHA-256 values equal their E: originals. README: 4,066 bytes, SHA-256
`5D7F14BBD509552A106629DA88EBD7589C6868A390BD5B0DA9A065E545C92076`.

Evidence: `build/evidence/m10-ui-alignment-20260908/release-9ae3cb63b84f`,
`build/evidence/m10-apk-9ae3cb6/post-run-integrity.json`, and the capture index
`build/evidence/m10-ui-alignment-20260908/INDEX.md`.

Cloud-visible synchronization is unconfirmed: local DriveFS verification is not an
upload confirmation. No phone installation, phone save mutation, or physical Android
acceptance result is claimed. Printer HP and damage remain unchanged.

## Explicit non-goals

No new ImageGen work; no new UI theme; no phase/rule/economy/catalog/deck/save change;
no landscape work; no sprite/model/blueprint/card-back replacement; no x10 printer
damage implementation; no unapproved 200 base printer HP or +50 Reinforced Chassis
replacement; no M9B mastery/mod/queue implementation; no production ad SDK, identifier,
request, banner, disclosure, or reserved strip; and no physical-device or cloud-sync
claim without corresponding evidence.
