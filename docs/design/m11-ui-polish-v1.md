# M11 UI polish contract v1

Status: **AUTHORIZED PRESENTATION REPAIR; GAMEPLAY UNCHANGED**

Date: 2026-09-08

This contract applies the user's latest alignment and material-ownership request to
the existing approved portrait UI. It authorizes no new art, layout theme, gameplay,
catalog, economy, balance, AI, save, reward, or navigation rule. Existing character
art, blueprints, sprites, card back, r7 battle atlas, facing-inward direction, and
native dynamic controls remain authoritative.

## Shared screen rules

- Portrait reference is 576x1024 with supplemental 720x1280 and 150% text review.
- One visible physical frame has one control owner and one hit owner. Never stack a
  generic Godot frame over an illustrated keycap, plaque, tab, card, clamp, lever, or
  dial; never leave a second invisible control over a neighboring object.
- Dynamic names, values, counts, status, progress, legality, prices, HP, focus,
  disabled reasons, and accessibility text remain native and sit wholly inside their
  intended authored face. No caption crosses hardware, binding, art, or another seat.
- Every control reads as the physical object that is clickable. Decorative art has no
  hit owner or fake pressed state. Clickable art has visible focus, pressed, selected,
  and disabled states on that same object.
- Touch targets are at least 48 logical pixels; primary actions and canonical Back are
  at least 56. Visible keycap ink may be smaller than its hit area only when the hit
  area does not overlap an unrelated control and the focus outline still encloses the
  intended object.
- At 150% text, required decisions and values reflow, wrap, page, or scroll within the
  route's existing owner. They do not shrink below the readable floor, clip, or paint
  over hardware.
- Preserve the current native-bottom host contract: the host owns any real banner and
  bottom safe inset; Godot content reserves zero duplicate ad space and shows no fake
  ad-shaped spacer in the current no-ad review flavor.

## Title

- **Entry:** Launch, return from Workshop, or recover a valid profile.
- **Player decision:** Continue, New Maker confirmation, Settings, or canonical exit.
- **Result:** Logo, profile status, and physical action objects each occupy one authored
  seat with one visible frame and aligned native caption.
- **Failure:** Load/recovery copy stays in its existing readable plate with retry or
  recovery route; it never displaces the primary actions.
- **Disabled:** Unavailable Continue/New Maker states show their existing reason and
  cannot retain a hidden hit owner.
- **Feedback:** Focus/press/confirmation remains on the selected physical object.
- **Progression:** Layout and title interaction add no profile mutation beyond the
  existing confirmed New Maker/recovery transaction.

## Starter selection and first print

- **Entry:** New Maker reaches starter selection or the selected starter's first Forge.
- **Player decision:** Inspect/swipe, choose one starter, confirm, print, skip only where
  already legal, or Back.
- **Result:** Focused blueprint/creature art stays inside its aperture; name, traits,
  selection state, and action caption remain native and registered to their own faces.
- **Failure:** Missing art uses the truthful existing fallback without moving selection
  or fabricating a finished creature during printing.
- **Disabled:** Unselected/locked actions retain visible reasons and no overlapping hit
  region; transaction playback locks only its existing controls.
- **Feedback:** Carousel focus, chosen blueprint, print layers, status, and destination
  agree at normal and 150% text.
- **Progression:** Existing choose-starter and exactly-once first-print receipts remain
  the sole mutations.

## Workshop and drawers

- **Entry:** Continue, Back from a child route, or reopen a Workshop drawer/view.
- **Player decision:** Activate printer, battle dais, Archive, Market, Settings, or an
  existing drawer object.
- **Result:** Each hotspot is seated on its illustrated object; HUD values and drawer
  labels occupy their own plaques without duplicate frames or captions over scenery.
- **Failure:** A locked/missing destination remains in Workshop with a native reason;
  safe-area or long copy never creates a dead overlay.
- **Disabled:** Decorative tools/shelves are noninteractive; locked hotspots retain the
  existing visible disabled treatment.
- **Feedback:** Hover/focus/press and drawer-open state identify the same physical owner.
- **Progression:** Workshop layout is zero-mutation; only existing destination actions
  and transactions change state.

## Forge

- **Entry:** Open a licensed blueprint, first print, resumed print, or active print.
- **Player decision:** Start/continue/skip where legal, inspect instruments, or use the
  existing return route.
- **Result:** Blueprint, empty bed, scan line, raw layers, progress, ETA/cost/status, and
  action keycaps remain distinct and aligned with the approved Forge enclosure.
- **Failure:** Missing presentation uses the finite native fallback; it never shows the
  finished creature throughout printing, duplicates a button frame, or strands Back.
- **Disabled:** Commit/animation locks retain exact reasons and exclude hidden controls
  from hit/focus.
- **Feedback:** Native progress/status and physical animation describe one authoritative
  print stage, including reduced motion and 150% text.
- **Progression:** Existing exactly-once print authority, persistence, and return
  behavior remain unchanged.

## Challenge board and battle preflight

- **Entry:** Workshop battle dais opens browse state, then the legal preflight.
- **Player decision:** Review, Begin, return to Workshop, or repair an illegal deck via
  the existing route.
- **Result:** Deck legality, Pre-Print count, both printer summaries, Begin, and return
  each own a readable physical seat and nonoverlapping hit region.
- **Failure:** Illegal deck/Pre-Print state shows the exact native reason and repair
  route without implying battle launch.
- **Disabled:** Begin remains disabled until existing authority declares launch legal.
- **Feedback:** Focus, legality, and chosen action share the same visible object.
- **Progression:** Browse/preflight is zero-mutation; Begin uses the existing checked
  battle launch only.

## Living battle and required decisions

- **Entry:** Plan, Run Cycle, rival resolution, print/awaken/deploy/attack playback,
  fitting, overflow, pause, or terminal state renders.
- **Player decision:** Use only existing legal hand, stance, focus, required choice,
  Run Cycle, Stay, Concede, and Back actions. No new combat rule is introduced here.
- **Result:** Facing-inward living sprites own the field; printers/HP, forecast/status,
  hand, queue, fitting/overflow choice, Back, and Run Cycle each remain in distinct
  physical seats. Friendly backs face up-board and rival fronts face down-board.
- **Failure:** Missing animation uses the existing finite fallback without replaying
  authority; stale/illegal input remains with an exact reason and reachable exit.
- **Disabled:** Playback/modal shields exclude background targets; rival-private and
  illegal targets remain inaccessible. Guard-only blocking remains unapproved.
- **Feedback:** Selection, legal target, print progress, contact, HP receipt, focus,
  pause, and reduced motion align with the same authoritative event.
- **Progression:** Polish and facing direction are presentation-only; checked battle
  intents and exactly-once Result settlement remain authoritative.

## Archive and inspection

- **Entry:** Open Collection, change an existing filter/page, or inspect a record.
- **Player decision:** Filter, page, inspect, open Deck/Forge where already legal, or
  Close/Back.
- **Result:** Blueprint/card art is clipped into its paper aperture with transparency;
  native name, ownership, facts, filters, paging, and actions occupy separate folio
  seats and never float as opaque rectangles over the book.
- **Failure:** Unknown/missing art uses the existing truthful folio fallback and a real
  Close route without exposing the grid beneath.
- **Disabled:** Ownership/print legality disables only the action, not permitted
  inspection; decorative page marks own no hit area.
- **Feedback:** Page, filter, selection, focus, and detail state stay on their physical
  folio objects.
- **Progression:** Browse/inspection is zero-mutation; existing Forge/Deck transitions
  retain their rules.

## Deck Builder and dirty docket

- **Entry:** Open a fixed deck slot, change card/Pre-Print draft, preview approved deck
  help, change slot, or Back with a dirty draft.
- **Player decision:** Edit, preview/apply/cancel, Save, Discard, Stay, switch slot, or
  Back under the approved atomic deck/Pre-Print contract.
- **Result:** Cards, counts, legality, Pre-Print clamps, page/selection, and actions each
  occupy one workbench recess. The dirty docket is the sole input owner while visible.
- **Failure:** Invalid deck/Pre-Print or commit failure preserves both drafts and exact
  reason; no caption overlaps clamps/cards or falsely reports a partial save.
- **Disabled:** Save remains disabled under existing legality rules; background and
  unavailable clamps have no active hit/focus owner.
- **Feedback:** Selection, count changes, invalid clamp, dirty state, and joint save
  receipt remain native and aligned at 150% text.
- **Progression:** Browsing and previews grant nothing; only the existing atomic joint
  save changes configuration.

## Market and purchase confirmation

- **Entry:** Open Market, change existing category/page, inspect an offer, or open its
  confirmation.
- **Player decision:** Browse, inspect, Buy/confirm, cancel, or Back.
- **Result:** Offer art, name, price, stock/ownership, category, and purchase key occupy
  their intended physical stalls/receipts with one visible frame per control.
- **Failure:** Stale/unaffordable/unavailable offers remain with exact reason and no
  false ownership or receipt.
- **Disabled:** Unavailable purchase targets retain readable contrast and cannot be
  activated through artwork outside their frame.
- **Feedback:** Selected offer, price, confirmation, success/failure receipt, and
  restored focus agree.
- **Progression:** Only the existing confirmed market transaction changes currency or
  ownership.

## Pack reveal

- **Entry:** A persisted pending pack receipt opens or resumes.
- **Player decision:** Page, inspect, Keep, or use the existing allowed return behavior.
- **Result:** Exact card art/card backs, page state, inspector, receipt facts, and Keep
  key are aligned to separate physical seats without stacked frames.
- **Failure:** Missing/stale receipt remains recoverable with truthful native copy and
  never loses or duplicates cards.
- **Disabled:** Keep/return stays locked under the existing pending-receipt rules;
  unrevealed/private cards retain the exact card back.
- **Feedback:** Reveal sequence, paging, focus, inspection, Keep acknowledgement, and
  return destination agree at normal/reduced motion.
- **Progression:** Only the existing exactly-once Keep receipt changes ownership.

## Settings and tutorial replay control

- **Entry:** Open Settings from its existing caller or return after a failed save.
- **Player decision:** Change supported accessibility/audio values, Save/Cancel, Back,
  or use approved Replay Tutorial when eligible.
- **Result:** Labels, current values, option controls, replay state, and Save/Back sit on
  their own physical rows/faces with consistent baselines and full accessibility names.
- **Failure:** Invalid or failed settings save remains on the prior durable values and
  names the rejected field; no unrelated marker is dropped.
- **Disabled:** Unsupported values and ineligible replay states are visible but not
  activatable; decorative hardware owns no focus.
- **Feedback:** Selected, focused, saved, cancelled, high-contrast, reduced-motion, and
  150%-text states remain visually registered.
- **Progression:** Only the existing journaled settings/tutorial-marker transition may
  mutate profile settings; it changes no battle history or rewards.

## Result and recovery

- **Entry:** Battle settlement, reward/duplicate/error state, or save recovery renders.
- **Player decision:** Continue, Retry, acknowledge recovery, or use the existing
  confirmed destructive recovery choice.
- **Result:** Outcome, reward/error facts, and the canonical action each own one visible
  physical seat. Continue remains the sole normal Result exit; no redundant Back is
  added.
- **Failure:** Commit/recovery failure stays readable and retryable without showing a
  success receipt or exposing a dead button.
- **Disabled:** Continue remains locked until existing settlement authority permits it;
  confirmation shields all background input.
- **Feedback:** Pending/committed/duplicate/error focus and copy align to the same
  receipt object.
- **Progression:** Only existing settlement/recovery transactions mutate; layout never
  repeats rewards, deletes saves, or changes a winner.

## Acceptance evidence

For each changed route, capture its normal state and the changed selected/disabled/
error or longest-copy state at 576x1024; review the same geometry at 720x1280 and 150%
text with high contrast and reduced motion where relevant. Automated checks assert
48/56 target minimums, one hit owner per object, no unrelated overlap, native copy
inside measured seats, image aspect/alpha containment, complete four-edge focus, and
canonical Back parity. A route fails polish if a caption crosses hardware, a generic
frame duplicates illustrated material, decorative art behaves clickable, or an
invisible target captures a neighbor.
