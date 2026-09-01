# PrintForge physical UI M3 live correction checkpoint v1

Status: decision-complete correction brief; implementation and live evidence pending

Date: 2026-08-31

Authority: `docs/checkpoints/printforge-physical-ui-m3-management-v1.md`,
`docs/checkpoints/printforge-physical-ui-m1-corrections-v1.md`, the approved M1/M3
physical concept family, and the unchanged v3 catalog/profile/save mechanics. This
checkpoint supersedes static-capture acceptance only where live interaction or
runtime material integration is contradicted below. It does not reopen gameplay
values, economy, save schema, portrait scope, or the approved text-free composition
masters.

## Correction boundary

The static M3 gallery proved that required states could be composed at the named
portrait sizes. It did not prove that a player could activate every visible control,
that a control gave visible response when activated, or that catalog art read as ink,
print, or a card seated in the physical object. This correction closes those gaps.

The runtime writer must preserve the existing character art, support-card art/back,
catalog values, deterministic transactions, and native dynamic text. Generated
masters remain composition references and physical surface owners; they do not make a
generic native panel, generic rounded button, or opaque catalog image acceptable when
placed over a folio aperture.

No Android, AdMob load, device, build, signing, Drive, or cloud-sync evidence is
claimed here. Production Godot bottom reserve remains exactly `0`; a positive bottom
obstruction remains a labeled synthetic stress fixture only.

## Read-only audit findings

Files inspected:

- `scripts/ui/main.gd`
- `scripts/ui/m1_physical_ui_component.gd`
- `scripts/ui/m3_physical_ui_component.gd`
- `scripts/ui/physical_archive_workbench_component.gd`
- `scripts/ui/physical_supply_reward_component.gd`
- `scripts/ui/physical_settings_recovery_component.gd`
- `scripts/ui/physical_result_receipt_component.gd`
- `tests/test_m1_physical_navigation.gd`
- `tests/test_m3_physical_management.gd`
- `tests/test_ui_workshop_nav.gd`

### Classification

- **NF — nonfunctional:** a visible or required action cannot currently reach its
  promised result through the presented control.
- **WF — weak feedback/material:** the callback is statically connected, but the
  control has absent, ambiguous, stock, or composition-breaking feedback.
- **LP — live proof gap:** tests call a controller method or emit `pressed` directly,
  so actual pointer hit testing, focus activation, and post-action feedback are not
  proved.
- **PI — passive-looking-interactive:** a node is implemented with button styling but
  intentionally ignores input, so a player can reasonably read it as broken.
- **OK-S — statically wired:** the callback path exists in source; it still requires
  the live acceptance named in the ledger.

### Locked findings

1. **NF/P0 — Pre-Print placement has no reachable control.**
   `main._m3_add_preprint(card_id)` exists, but the current physical Workbench does not
   connect it to an owned creature, inspector action, or empty clamp. The UI can remove
   and save existing Pre-Prints but cannot build the promised ordered rack.
2. **NF/P0 — Recovery Back does not reach Title.** `RecoveryBack` sets
   `main.screen = "title"`, but `main.render()` immediately replaces every read-only
   route with Recovery. The visible action promises a result the route guard forbids.
   The correction removes this false action while unsafe and supplies truthful
   state-specific recovery actions; it must not weaken read-only protection.
3. **NF/PI/P1 — persisted pack cards cannot be inspected.** `PackReceiptTile` is a
   `Button` with `focus_mode = NONE` and `mouse_filter = IGNORE`. This contradicts the
   M3 contract that persisted cards remain inspectable and makes a button-shaped card
   appear dead.
4. **NF/P1 — inspection cannot hand off to Deck.** The current Archive detail exposes
   Close and creature Forge routing, but no creature/support `Open Deck` action even
   though M3 requires the inspected stable ID to be focusable in a draft context.
5. **WF/P1 — Archive detail is a generic overlay.** The CO-02 detail master is loaded,
   but the runtime then places a generic `PanelContainer` drawer and generic visual
   buttons over it. The detail screen must seat native facts and physical actions in
   CO-02 apertures rather than present an app modal over a folio.
6. **WF/P1 — repeated generic button language remains.** Archive tabs/wells, Deck
   occurrence rows/slots, Market cubbies/tabs, Settings controls, the Deck dirty
   prompt, and one Result return use independent rounded `StyleBoxFlat` faces. They
   are functional-looking app controls, not the lever, tab, clamp, stamp, drawer,
   card, and plaque objects pictured by the approved family.
7. **WF/P1 — catalog art is pasted rather than integrated.** Archive, Deck, Market,
   Pack, and Result directly place `TextureRect` art with
   `STRETCH_KEEP_ASPECT_CENTERED`. No paper mask, alpha cleanup, ink treatment, printed
   edge, or card-seat shadow is required by the current tests, so opaque rectangles
   and halos can float above paper.
8. **LP/P0 — current tests are not a complete live interaction proof.** M1 Workshop
   tests mostly emit `pressed`; M3 tests frequently call `_m3_*` methods directly and
   assert geometry/existence. Those are useful transaction and composition checks but
   do not prove actual center-point taps, keyboard activation, z-order, or visible
   feedback for every control.

No other callback is declared broken solely because its presentation is weak. A
statically connected action remains **OK-S/WF/LP** until its named live test either
passes or demonstrates a functional defect.

## Global live-control contract

Every ledger entry below is mandatory.

- Each visible interactive surface is a native focusable control aligned to one
  pictured physical object or clearly authored native physical material. A control
  may use a transparent hit target over art, but it may not use a generic floating
  rounded rectangle unrelated to the surface beneath it.
- Secondary controls are at least `48x48` logical pixels; transaction, destructive,
  Save, Apply, Buy, Keep, Continue, Retry, and confirmation controls are at least
  `56x56`.
- Dynamic names, prices, counts, reasons, values, receipts, labels, tooltips, and
  accessibility names remain native. No generated art contains changing copy.
- Normal, hover/touch-focus, pressed, focus, disabled, in-flight, accepted, and
  rejected states are distinguishable by shape/position/outline/text as well as hue.
  A tap shows a pressed response before a route rebuild; accepted and rejected
  actions leave a native receipt or reason after rebuild.
- Browse/select/filter/inspect/scroll/close/cancel paths are zero-mutation. Each
  transaction uses the already authoritative exactly-once path and expected revision
  count from M3.
- Disabled controls neither emit their transaction nor appear enabled. Their native
  tooltip/accessibility description gives the first deterministic reason.
- Live tests dispatch a pointer press/release at the control's visible global center
  and a keyboard/controller accept while focused. Direct controller calls and
  `emit_signal("pressed")` may remain unit seams but cannot satisfy this checkpoint.
- Every route is exercised at `576x1024` and `720x1280`, including 150% text. High
  contrast and reduced motion must preserve the same activation results.

## Artwork integration contract

Existing creature and card art is retained, but its runtime presentation changes from
“image over page” to “artifact on/in page.”

- **Paper illustration:** creature art in Archive detail and blueprint-like Deck or
  Market surfaces uses an alpha-aware mask and deterministic ink/pigment treatment.
  Paper grain remains visible through light areas; no opaque source rectangle, white
  box, dark halo, or unmasked corner may survive. The illustration remains recognizably
  the existing character.
- **Physical card:** when a complete card is meant to be present, it is clipped to the
  authored card recess, preserves the existing card silhouette/back, and receives a
  restrained contact shadow/edge seat. It must not be recolored into illegibility or
  float beyond its dock.
- **Aperture ownership:** every art node is clipped or masked by the named paper/card
  aperture. Scaling is deterministic, aspect-preserving, and based on an authored
  safe region; the same definition cannot overlap native name/cost/status bands.
- **Fallback:** missing/invalid art uses the approved native blueprint fallback mark
  and card name inside the same aperture. It never exposes a checkerboard, empty
  `TextureRect`, file path, or generic placeholder panel.
- **Accessibility:** artwork is passive. Its containing card/inspection control owns
  the native accessible name and full fact text. High contrast adds a boundary/focus
  treatment without flattening the character into a solid block.
- **Deterministic material test:** each required art seat exposes a stable aperture
  node, clip/mask/material marker, and passive art input state. Original-resolution
  capture review remains required because structural tests cannot approve visual
  compositing quality.

Acceptance test: `tests/test_m3_live_art_integration.tscn`.

## Route and control ledger

Repeated controls named in parentheses are separate visible elements. The shared
contract applies to every instance, not merely the first one found.

### Title

#### Completed/fresh primary plaque — `TitleContinue`

- **Entry:** Title is visible with a loaded fresh, starter-selected, or completed
  profile and no New Maker transaction in flight.
- **Player decision:** Activate the central physical plaque once.
- **Result:** Fresh enters choose-starter onboarding; starter-selected resumes its
  saved first-print setup; completed enters the six-hotspot Workshop.
- **Failure:** Invalid profile/onboarding state remains on Title with a native reason
  and no mutation.
- **Disabled:** Disabled during a blocking confirmation, persistence transaction, or
  read-only recovery.
- **Feedback:** Plaque visibly depresses/latches, focus is complete, and the next route
  owns focus after transition.
- **Progression:** Route activation is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_title_controls.tscn [primary_plaque]`.

#### Completed-profile New Maker plaque — `TitleNewMaker`

- **Entry:** A compatible completed profile is loaded at Title.
- **Player decision:** Request New Maker.
- **Result:** A zero-mutation confirmation state replaces the normal Title actions;
  Cancel receives default focus.
- **Failure:** Repeated activation cannot skip confirmation or mutate storage.
- **Disabled:** Absent on fresh Title and disabled while another title transaction is
  active.
- **Feedback:** The physical plaque unlatches into a native consequence/confirmation
  receipt, not a generic modal.
- **Progression:** Request is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_title_controls.tscn [request_new_maker]`.

#### Title Settings plaque — `TitleSettings`

- **Entry:** Compatible Title state, no blocking confirmation.
- **Player decision:** Open Settings.
- **Result:** Physical Settings opens with caller `Title`; Cancel/Back returns to the
  exact Title state.
- **Failure:** Missing Settings component leaves Title visible with a reason.
- **Disabled:** Disabled in read-only recovery and during New Maker persistence.
- **Feedback:** Press state precedes the route change and Settings announces its Title
  return destination.
- **Progression:** Open/return are zero-mutation.
- **Deterministic acceptance:** `test_m3_live_title_controls.tscn [settings_round_trip]`.

#### New Maker confirmation — `TitleConfirmNewMaker`

- **Entry:** The explicit first confirmation is visible.
- **Player decision:** Confirm once.
- **Result:** The existing profile replacement persists exactly once before assigning
  the new in-memory profile, then opens onboarding.
- **Failure:** Persistence failure keeps the prior profile/files byte-identical and
  leaves an actionable native retry reason on the confirmation state.
- **Disabled:** Disabled and labeled in-flight after first activation.
- **Feedback:** Physical writing/stamp state, then accepted receipt or exact error.
- **Progression:** One success is one revision/write; duplicate input adds none.
- **Deterministic acceptance:** `test_m3_live_title_controls.tscn [confirm_new_maker]`.

#### New Maker cancellation — `TitleCancelNewMaker`

- **Entry:** Confirmation visible and not in flight.
- **Player decision:** Cancel.
- **Result:** Restore the prior Title actions and focus without changing the profile.
- **Failure:** If persistence is already in flight, Cancel is disabled and cannot
  produce an ambiguous state.
- **Disabled:** Disabled only while the accepted confirmation is in flight.
- **Feedback:** Confirmation hardware retracts and central plaque regains focus.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_title_controls.tscn [cancel_new_maker]`.

### Workshop physical hotspots

#### Six object targets — `WorkshopHotspotPrinter`, `WorkshopHotspotBattleArena`,
`WorkshopHotspotCardArchive`, `WorkshopHotspotDeck`, `WorkshopHotspotSupplies`, and
`WorkshopHotspotSettings`

- **Entry:** Completed profile at the portrait Workshop overview with all six pictured
  objects unobscured.
- **Player decision:** Tap or focus/accept exactly one physical object.
- **Result:** Printer opens Forge; Battle Dais opens the challenge preflight; Archive
  Folio opens Archive; Deck Clipboard opens Deck; Supply Cabinet opens Supplies;
  Settings Instrument opens Settings with caller `Workshop`.
- **Failure:** Missing route/component leaves Workshop visible, preserves state, and
  shows the exact native reason; a tap must never fall through to another hotspot.
- **Disabled:** A route blocked by a pending receipt, recovery, or transaction is
  visibly unavailable and names the blocking object/receipt.
- **Feedback:** The exact object gets a tight four-edge or silhouette focus treatment,
  a pressed mechanical response, and route-change sound/haptic only after activation.
- **Progression:** Navigation is zero-mutation except any already-authoritative battle
  preflight preparation; no hotspot grants currency, cards, prints, or rewards.
- **Deterministic acceptance:**
  `test_m3_live_workshop_hotspot_hit_paths.tscn [all_six_center_taps]`.

### Archive and inspection

#### Archive Back — `ArchiveArchBack`

- **Entry:** Archive grid or detail folio is active with no blocking receipt.
- **Player decision:** Activate the physical arch return tab.
- **Result:** Return to the same Workshop overview.
- **Failure:** Unavailable Workshop leaves Archive stable with a reason.
- **Disabled:** Disabled only for a blocking transaction/receipt.
- **Feedback:** Arch tab depresses; Workshop hotspot focus returns to Archive.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_controls.tscn [back]`.

#### Archive card wells — every `ArchiveBlueprintCard*`

- **Entry:** A catalog card occupies a visible folio well.
- **Player decision:** Inspect the creature or support card.
- **Result:** CO-02 becomes the sole physical detail owner for that stable ID, with
  integrated art and native catalog/ownership facts.
- **Failure:** Unknown/missing art uses the approved fallback in the same well/detail
  folio and keeps Close/Back reachable.
- **Disabled:** No catalog entry is shown as enabled if its stable ID cannot resolve.
- **Feedback:** The selected paper/card lifts or gains an inked selection boundary;
  the detail folio announces the selected name.
- **Progression:** Inspect is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_controls.tscn [card_wells]`.

#### Category tabs and rail shuttles — `ArchiveCategoryAll`,
`ArchiveCategoryCreature`, `ArchiveCategoryFilament`, `ArchiveCategorySpell`,
`ArchiveCategoryEquipment`, `ArchiveCategoryTrap`, `ArchiveCategoryUpgrade`,
`ArchiveCategoryRailPrevious`, `ArchiveCategoryRailNext`

- **Entry:** Archive grid loaded from a stable catalog/profile snapshot.
- **Player decision:** Select one metal index tab or move the tab rail.
- **Result:** The selected tab mechanically latches, page resets to one, and the
  stable filtered set appears; a shuttle moves only the tab rail.
- **Failure:** Empty category shows a truthful empty folio with Clear and Back.
- **Disabled:** A shuttle is disabled at its actual boundary; tabs remain inspectable
  even when their result is empty.
- **Feedback:** Latch position/shape and native category/count change; not color alone.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_controls.tscn [category_bank]`.

#### Page rocker — `ArchivePagePrevious`, `ArchivePageNext`

- **Entry:** Filtered Archive has a known page count.
- **Player decision:** Move one page backward or forward.
- **Result:** Exactly the previous/next stable six-card slice is seated.
- **Failure:** Stale page is clamped after a filter/catalog refresh without mutation.
- **Disabled:** Previous at first page; Next at last page.
- **Feedback:** Rocker tilts toward the activated side and native page count updates.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_controls.tscn [page_rocker]`.

#### Lower filter wells — `ArchiveWellOwned`, `ArchiveWellPrintable`,
`ArchiveWellClear`

- **Entry:** Archive filter wells are visible.
- **Player decision:** Toggle Owned, toggle Printable, or clear all filters.
- **Result:** Wells latch independently, Clear resets category/filter/page, and the
  exact profile remains unchanged.
- **Failure:** Empty intersection shows the native empty-state reason and reachable
  Clear.
- **Disabled:** Printable is disabled only if the catalog exposes no printable class,
  with a native reason; Clear is disabled when already clear.
- **Feedback:** Inserted/ejected well state plus native result count.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_controls.tscn [filter_wells]`.

#### Detail Close — `Close`

- **Entry:** CO-02 detail folio owns the screen.
- **Player decision:** Close inspection.
- **Result:** Restore the exact Archive category/filter/page and focus the originating
  card well.
- **Failure:** Missing origin restores the stable Archive page and first valid focus.
- **Disabled:** Disabled only while an accepted route transition is in flight.
- **Feedback:** Detail leaf closes physically; no generic panel disappears abruptly.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_inspection.tscn [close_restore]`.

#### Creature Print action — `ArchivePrintBlueprint`

- **Entry:** A creature detail has a learned permanent blueprint.
- **Player decision:** Open Forge for that stable creature ID.
- **Result:** Forge opens with the exact blueprint selected; no print starts.
- **Failure:** Stale/unlearned license keeps detail open and names the reason.
- **Disabled:** Disabled for unlearned creature blueprints and absent for support
  cards.
- **Feedback:** Blueprint cartridge/docket visibly routes toward Forge.
- **Progression:** Route is zero-mutation; printing remains a separate transaction.
- **Deterministic acceptance:** `test_m3_live_archive_inspection.tscn [open_forge]`.

#### Creature/support Deck handoff — `ArchiveOpenDeck`

- **Entry:** CO-02 detail owns a known creature or support stable ID.
- **Player decision:** Open Deck with that card focused.
- **Result:** Deck Workbench opens with the same accepted active-slot draft and the
  inspected stable ID selected; no copy is automatically added.
- **Failure:** Unknown ID or unavailable Workbench leaves detail open with a native
  reason.
- **Disabled:** Disabled when the card is not owned or cannot legally participate in
  the existing Deck rules; the first reason remains accessible.
- **Feedback:** The inspected paper/card seats into a physical clipboard handoff and
  the Workbench inspector announces the same native name.
- **Progression:** Route and focus handoff are zero-mutation.
- **Deterministic acceptance:** `test_m3_live_archive_inspection.tscn [open_deck]`.

### Deck Workbench

#### Workbench Back — `UnifiedFoundryWorkshopReturn`

- **Entry:** Deck is visible with a clean or dirty local draft.
- **Player decision:** Return to Workshop.
- **Result:** Clean returns immediately; dirty opens the physical Save/Discard/Cancel
  docket without changing the draft.
- **Failure:** A stale save response leaves the docket and exact reason visible.
- **Disabled:** Disabled while a deck/pre-print save is in flight.
- **Feedback:** Clipboard return tab depresses; dirty docket slides into a dedicated
  paper slot rather than a generic modal.
- **Progression:** Clean Back and prompt entry are zero-mutation.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [back_dirty_gate]`.

#### Deck slot medallions — every `ArchiveDeckSlot*`

- **Entry:** Three fixed slots and the current local draft are loaded.
- **Player decision:** Focus/select Forge, Queue, or Arcane slot.
- **Result:** Clean selection loads that slot; dirty selection opens the same
  Save/Discard/Cancel docket for the requested destination.
- **Failure:** Missing/invalid saved slot remains on the current slot with a reason.
- **Disabled:** Current slot is latched/no-op; all slots disabled during save.
- **Feedback:** Exactly one medallion is mechanically latched and exposes native
  count/legality.
- **Progression:** Browsing is zero-mutation; an accepted Save/Activate follows M3's
  exactly-once revision contract.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [slot_medallions]`.

#### Folio/owned/occurrence selection — every `DeckFolioCard*`,
`DeckOwnedCard*`, and `DeckSelect*`

- **Entry:** A known owned card or current draft occurrence is visible.
- **Player decision:** Select it for inspection/editing.
- **Result:** One stable card ID owns the integrated inspector and all three card
  views agree on selection.
- **Failure:** Stale/unknown ID uses fallback and cannot mutate the draft.
- **Disabled:** Unresolvable entries are passive fallback records, not enabled cards.
- **Feedback:** Selected card seats forward/receives an ink boundary; inspector facts
  update natively.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [card_selection]`.

#### Occurrence steppers — every `DeckMinus*` and `DeckPlus*`

- **Entry:** Owned card row visible with draft/owned counts.
- **Player decision:** Remove or add exactly one occurrence.
- **Result:** Local draft changes by exactly one and all counts/legality refresh.
- **Failure:** Stale ownership/unknown ID leaves the draft unchanged and names the
  reason.
- **Disabled:** Minus at zero; Plus at owned count; Save remains disabled when draft
  is illegal.
- **Feedback:** Physical counter wheel/stepper moves one notch and changed count is
  announced.
- **Progression:** Local editing is zero profile mutation.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [occurrence_steppers]`.

#### Occurrence and owned-tray shuttles — `DeckOccurrencePrevious`,
`DeckOccurrenceNext`, `DeckOwnedPrevious`, `DeckOwnedNext`

- **Entry:** The corresponding clipped tray has overflow.
- **Player decision:** Scroll one deterministic increment.
- **Result:** Tray advances without changing selected card or draft.
- **Failure:** Layout refresh clamps scroll to valid bounds.
- **Disabled:** Boundary shuttle disabled; both disabled when there is no overflow.
- **Feedback:** Physical shuttle moves and newly visible card receives no false
  selection.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [tray_shuttles]`.

#### Save deck — `SaveActiveDeck`

- **Entry:** Selected fixed-slot draft is legal under unchanged 40+ ownership rules.
- **Player decision:** Save once.
- **Result:** Existing transaction replaces that slot, makes it active as defined,
  journals/revises once, and shows a native accepted docket.
- **Failure:** First deterministic legality/storage/stale reason remains visible and
  prior saved slot/active deck remains unchanged.
- **Disabled:** Illegal, read-only, unchanged no-op if rules reject it, or in-flight.
- **Feedback:** Physical stamp enters in-flight then accepted/rejected position.
- **Progression:** One accepted Save is one existing mutation; duplicate activation
  adds none.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [save_exactly_once]`.

#### Pre-Print placement — selected eligible creature and empty `PrePrintClamp*`

- **Entry:** An unlocked empty clamp and a creature occurrence present in the active
  legal deck are visible.
- **Player decision:** Choose `Place in next clamp` from the integrated inspector or
  choose an empty unlocked clamp then an eligible creature occurrence.
- **Result:** Exactly one local ordered Pre-Print entry is added; no automatic choice
  is made. This is the required reachable binding to `_m3_add_preprint` or its bounded
  replacement.
- **Failure:** Noncreature, absent deck occurrence, duplicate overuse, stale deck, or
  full rack leaves the draft unchanged and names the reason.
- **Disabled:** Locked/full clamps and ineligible copies cannot accept placement.
- **Feedback:** The existing creature/card art seats beneath the chosen clamp; native
  slot/order and deck-copy usage update.
- **Progression:** Local placement is zero profile mutation.
- **Deterministic acceptance:** `test_m3_live_preprint_controls.tscn [place_ordered]`.

#### Pre-Print removal — populated `PrePrintClamp1..3`

- **Entry:** An unlocked clamp holds an ordered draft entry.
- **Player decision:** Remove that exact clamp entry.
- **Result:** Local list removes that index and later entries retain deterministic
  order according to the existing list behavior.
- **Failure:** Stale/empty/locked clamp is unchanged.
- **Disabled:** Empty or locked clamps are disabled and do not look tappable.
- **Feedback:** Clamp opens and native empty/locked state replaces the art.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_preprint_controls.tscn [remove]`.

#### Save Pre-Prints — `SavePrePrintLoadout`

- **Entry:** Ordered draft is valid against the active legal deck and unlocked count.
- **Player decision:** Save once.
- **Result:** Existing transaction replaces the ordered list once and shows a native
  receipt.
- **Failure:** Invalid/stale/storage rejection preserves the accepted list and names
  the first reason.
- **Disabled:** Invalid, read-only, deck save in-flight, or pre-print save in-flight.
- **Feedback:** Clamp-bank stamp shows in-flight then accepted/rejected state.
- **Progression:** One acceptance is one mutation/revision; duplicates add none.
- **Deterministic acceptance:** `test_m3_live_preprint_controls.tscn [save_exactly_once]`.

#### Dirty docket — `M3DeckDirtySave`, `M3DeckDirtyDiscard`,
`M3DeckDirtyCancel`

- **Entry:** Back/slot switch requested with a dirty draft.
- **Player decision:** Save, Discard, or Cancel.
- **Result:** Save validates and commits before routing; Discard restores accepted
  state then routes; Cancel closes the docket and retains the draft.
- **Failure:** Failed Save keeps the current route/draft and exact reason.
- **Disabled:** All submit paths lock during Save; Discard/Cancel cannot race it.
- **Feedback:** One physical paper docket with distinct stamp/tear/retract outcomes,
  not a generic three-button panel.
- **Progression:** Save may mutate once; Discard/Cancel mutate zero times.
- **Deterministic acceptance:** `test_m3_live_deck_controls.tscn [dirty_docket]`.

### Supplies and Pack

#### Supplies Back — `UnifiedFoundryWorkshopReturn`

- **Entry:** Supply cabinet visible and no purchase submit in flight.
- **Player decision:** Return to Workshop.
- **Result:** Return to the same Workshop overview.
- **Failure:** A blocking committed pack receipt opens Pack instead of being bypassed.
- **Disabled:** Disabled during submit and while a blocking receipt owns navigation.
- **Feedback:** Cabinet latch closes before route change.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [back]`.

#### Five drawer selectors — `MarketTabBlueprints`, `MarketTabCards`,
`MarketTabPacks`, `MarketTabUpgrades`, `MarketTabCosmetics`

- **Entry:** Frozen authoritative Market snapshot loaded.
- **Player decision:** Open exactly one existing category drawer.
- **Result:** One drawer latches open, page/selection reset deterministically, and
  existing offers/values appear.
- **Failure:** Unavailable category shows its truthful empty/locked state without a
  fabricated offer.
- **Disabled:** Current drawer is latched/no-op; all selectors lock during submit.
- **Feedback:** Physical drawer depth/handle state plus native category/revision.
- **Progression:** Browse is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [drawer_bank]`.

#### Offer cubbies — every `MarketOffer*Slot*`

- **Entry:** A frozen offer occurrence occupies a visible cubby.
- **Player decision:** Select that occurrence for inspection.
- **Result:** Stable slot key, not catalog ID alone, owns the detail/price/consequence
  bays; repeated offers select only the chosen occurrence.
- **Failure:** Stale/unresolvable offer disables Purchase and keeps snapshot facts.
- **Disabled:** Invalid/expired offer cannot appear as purchasable.
- **Feedback:** Selected object slides forward or receives a physical pin, with native
  name/price/ownership.
- **Progression:** Selection is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [offer_cubbies]`.

#### Market page shuttle — `MarketPagePrevious`, `MarketPageNext`

- **Entry:** Current drawer has a known page count.
- **Player decision:** Move exactly one page.
- **Result:** Stable next/previous six-offer slice; selection becomes a valid visible
  occurrence.
- **Failure:** Snapshot refresh clamps stale page without mutation.
- **Disabled:** Previous/Next at boundary or both when no overflow.
- **Feedback:** Brass shuttle moves and native page value updates.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [page_shuttle]`.

#### Wishlist pin for eligible existing offer

- **Entry:** Selected offer is eligible under the existing wishlist rule.
- **Player decision:** Pin or unpin its stable catalog ID.
- **Result:** Existing wishlist transaction returns authoritative membership and one
  physical pin state updates.
- **Failure:** Capacity/stale/read-only/invalid ID preserves prior membership and shows
  the returned reason.
- **Disabled:** Ineligible categories/IDs and in-flight transaction.
- **Feedback:** Physical pin inserted/removed plus native wishlist status.
- **Progression:** One accepted existing wishlist update is one mutation; inspection
  adds none.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [wishlist_pin]`.

#### Purchase request — `MarketPurchaseSelected`

- **Entry:** Valid selected offer, current snapshot, no transaction in flight.
- **Player decision:** Request Purchase.
- **Result:** A physical confirmation receipt shows exact item, source, price,
  currency, and consequence before mutation.
- **Failure:** Stale/invalid selection leaves cabinet visible with a reason.
- **Disabled:** Unavailable, owned-unique, gated, unaffordable, read-only, or in-flight,
  with native reason.
- **Feedback:** Purchase lever depresses and receipt feeds into the confirmation bay.
- **Progression:** Request is zero-mutation.
- **Deterministic acceptance:** `test_m3_live_market_controls.tscn [purchase_request]`.

#### Purchase Confirm/Cancel — `M3MarketConfirmPurchase`,
`M3MarketCancelPurchase`

- **Entry:** Exact confirmation receipt visible.
- **Player decision:** Confirm once or Cancel.
- **Result:** Confirm uses the existing typed transaction and renders returned
  receipt/profile; Cancel closes confirmation unchanged.
- **Failure:** Stale, insufficient, prerequisite, unique-owned, or storage rejection
  performs no partial debit/grant and leaves an exact error.
- **Disabled:** Both lock during submit; background cabinet controls cannot submit.
- **Feedback:** Confirm stamp shows submitting then accepted/rejected; Cancel retracts
  the receipt.
- **Progression:** Confirm acceptance is one existing mutation; Cancel/rejection zero.
- **Deterministic acceptance:**
  `test_m3_live_market_controls.tscn [confirm_cancel_exactly_once]`.

#### Persisted pack cards — every `UnifiedPackCardView*`

- **Entry:** A committed pending reveal supplies stable card IDs/order.
- **Player decision:** Inspect any visible persisted card without changing receipt.
- **Result:** Physical inspection shows integrated art and native catalog/ownership
  facts, then closes back to the exact dock/order.
- **Failure:** Missing art/unknown ID uses fallback and never rerolls/regrants.
- **Disabled:** Cards are not disabled after reveal; only transaction controls are
  blocked. If product direction intentionally removes inspection, these must be
  passive `Control` objects with no button affordance and the M3 contract must be
  explicitly superseded—an inert `Button` is forbidden.
- **Feedback:** Chosen card lifts from its dock and focus returns to that dock.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_pack_controls.tscn [inspect_docks]`.

#### Keep receipt — `UnifiedPackRevealKeepCards`

- **Entry:** Valid committed pending receipt loaded and no Keep in flight.
- **Player decision:** File/Keep once.
- **Result:** Existing transaction clears only the pending receipt, preserves already
  committed cards/order, and reveals the next authorized route/entitlement.
- **Failure:** Missing/read-only/storage rejection keeps the same receipt visible and
  cannot fabricate or duplicate cards.
- **Disabled:** Until valid receipt loaded and during submit.
- **Feedback:** Physical filing lever/stamp moves, then native accepted/error receipt.
- **Progression:** One accepted Keep is one existing mutation; duplicate input adds
  none.
- **Deterministic acceptance:** `test_m3_live_pack_controls.tscn [keep_exactly_once]`.

### Settings and Recovery

#### Settings caller Back and Cancel — `UnifiedFoundryWorkshopReturn`,
`SettingsCancel`

- **Entry:** Settings opened from Title or Workshop with a local draft.
- **Player decision:** Cancel/Back.
- **Result:** Discard only the draft and return to the exact caller.
- **Failure:** Invalid caller falls back to Workshop without mutating settings.
- **Disabled:** Disabled only while Apply is in flight.
- **Feedback:** Calibration board resets visibly to accepted positions before return.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_settings_controls.tscn [caller_cancel]`.

#### Text scale positions — `SettingsText10000`, `SettingsText12500`,
`SettingsText15000`

- **Entry:** Settings draft visible.
- **Player decision:** Select 100%, 125%, or 150%.
- **Result:** Local draft and live native preview update; no profile write.
- **Failure:** Unsupported value is rejected locally with accepted value retained.
- **Disabled:** Current position is latched/no-op; controls lock during Apply.
- **Feedback:** Physical dial points to one position and preview reflows immediately.
- **Progression:** Zero-mutation until Apply.
- **Deterministic acceptance:** `test_m3_live_settings_controls.tscn [text_scale_dial]`.

#### Audio steppers — every `SettingsLower*` and `SettingsRaise*`

- **Entry:** Master/Music/SFX draft row visible.
- **Player decision:** Move one existing fixed level down/up.
- **Result:** Draft changes one step and native numeric/sample feedback updates.
- **Failure:** Unsupported current value normalizes only in the draft and never writes
  until Apply.
- **Disabled:** Lower at minimum, Raise at maximum, both during Apply.
- **Feedback:** Dial/lever moves exactly one notch; not merely a color change.
- **Progression:** Zero-mutation until Apply.
- **Deterministic acceptance:** `test_m3_live_settings_controls.tscn [audio_steppers]`.

#### Accessibility toggles — `SettingsHighContrast`,
`SettingsReducedMotion`

- **Entry:** Settings draft visible.
- **Player decision:** Toggle the selected property.
- **Result:** Local preview changes without touching compatibility-only AI difficulty.
- **Failure:** Preview failure retains the accepted/draft value and names the issue.
- **Disabled:** Disabled during Apply.
- **Feedback:** Physical switch position plus native ON/OFF and non-color cue.
- **Progression:** Zero-mutation until Apply.
- **Deterministic acceptance:** `test_m3_live_settings_controls.tscn [accessibility_toggles]`.

#### Apply — `SettingsApply`

- **Entry:** Valid local draft, no save in flight.
- **Player decision:** Apply once.
- **Result:** Existing settings transaction persists player-facing values once,
  preserves compatibility-only difficulty verbatim, and refreshes the board.
- **Failure:** Save/validation failure preserves accepted values and keeps the draft
  with an exact error.
- **Disabled:** Invalid, read-only, or in-flight.
- **Feedback:** Calibration seal shows applying then accepted/rejected receipt.
- **Progression:** One acceptance is one revision; no gameplay/economy/ad value
  changes.
- **Deterministic acceptance:** `test_m3_live_settings_controls.tscn [apply_exactly_once]`.

#### Recovery state Retry/refresh

- **Entry:** Storage-unavailable or state-may-have-changed recovery ledger is the
  blocking route.
- **Player decision:** Re-read existing primary/backup/compatibility once.
- **Result:** A now-valid authoritative state resumes safely; otherwise the same
  truthful ledger remains. No “Back to Title” control is shown while the global
  read-only guard would immediately reject that result.
- **Failure:** Read/validation failure preserves all files and reports the same or new
  returned recovery reason.
- **Disabled:** During revalidation and for immutable future-schema state unless the
  environment can actually change.
- **Feedback:** Physical ledger refresh indicator, then native state/preservation
  receipt.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_recovery_controls.tscn [retry_truthful]`.

#### Backup acknowledgement — `RecoveryAcknowledgeBackup`

- **Entry:** Validated backup is loaded read-only and no newer primary has won a
  reread.
- **Player decision:** Acknowledge once.
- **Result:** Existing recovery path safely promotes/resumes the authoritative record
  without changing its gameplay values.
- **Failure:** Reread race or persistence failure preserves the newer/backup authority
  and names the result.
- **Disabled:** Any other recovery state or in-flight.
- **Feedback:** Physical acknowledgement stamp and accepted/race/error receipt.
- **Progression:** Zero gameplay mutation; no fabricated revision/reward.
- **Deterministic acceptance:**
  `test_m3_live_recovery_controls.tscn [acknowledge_backup]`.

#### Recovery New Maker — `RecoveryNewMaker`

- **Entry:** Corrupt-primary/corrupt-backup state with recoverable evidence.
- **Player decision:** First request preservation, then separately confirm.
- **Result:** First step mutates nothing; second rereads storage, preserves corrupt
  evidence, commits a clean v3 profile once, and opens onboarding.
- **Failure:** Preservation/storage/race failure retains recoverable authority and
  confirmation with exact reason.
- **Disabled:** Future schema, backup-ready, storage-unavailable, or in-flight.
- **Feedback:** Two distinct physical states: `PRESERVE + NEW MAKER`, then
  `CONFIRM NEW MAKER`; accepted/error receipt remains native.
- **Progression:** Only accepted second step writes once; request/rejection zero.
- **Deterministic acceptance:** `test_m3_live_recovery_controls.tscn [new_maker_two_step]`.

### Result receipt

#### Physical Continue — `ResultContinue`

- **Entry:** Authoritative committed or duplicate nonlocal result receipt loaded.
- **Player decision:** Continue once.
- **Result:** Return to Workshop without resettling or granting again.
- **Failure:** Missing/unsafe receipt holds Result and names the reason.
- **Disabled:** Pending/error/local result or in-flight.
- **Feedback:** Physical filing dial/lever moves and Workshop receives focus.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_result_controls.tscn [continue]`.

#### Result retry — `ResultRetry`

- **Entry:** Settlement is in a truthful error state.
- **Player decision:** Retry after rereading current authority.
- **Result:** Existing result ID settles once or returns duplicate, then unlocks
  Continue.
- **Failure:** Error remains with no reroll, partial grant, or changed reward facts.
- **Disabled:** During retry or when storage is read-only; recovery then owns screen.
- **Feedback:** Retry mechanism shows in-flight and accepted/duplicate/error status.
- **Progression:** At most the sole existing settlement mutation; repeats add none.
- **Deterministic acceptance:** `test_m3_live_result_controls.tscn [retry_exactly_once]`.

#### Result HUD Back — `ResultReceiptBack`

- **Entry:** Result receipt visible.
- **Player decision:** None in the corrected hierarchy: this duplicate generic Back is
  removed as an interactive control. The single physical Continue owns accepted exit.
- **Result:** No second exit target competes with the receipt station.
- **Failure:** If retained for accessibility compatibility, it must be the same
  physical Continue action, same disabled state, and same acceptance—not a stock HUD
  button.
- **Disabled:** Pending/error/local states remain locked.
- **Feedback:** One unambiguous physical exit.
- **Progression:** Zero-mutation.
- **Deterministic acceptance:** `test_m3_live_result_controls.tscn [single_exit_owner]`.

## Acceptance and evidence gate

Implementation is not complete until all of the following pass:

1. The three confirmed functional gaps pass their named live tests: reachable
   Pre-Print placement, truthful recovery actions with no false Back, and persisted
   pack-card inspection (or an explicitly approved passive non-button supersession).
2. Every ledger control passes center-point pointer press/release and focused accept
   at `576x1024` and `720x1280`; each test asserts route/local-state result, expected
   mutation count, and post-action native feedback. No case is satisfied only by
   direct method call or signal emission.
3. A deterministic overlap audit proves the topmost control at each target center is
   the named action, no decorative node consumes the event, and no hidden/obscured
   route control remains focusable.
4. Browse/inspect/filter/select/scroll/cancel/back tests preserve a byte-equivalent
   profile and revision. Existing transactions retain M3 exactly-once/retry behavior.
5. Structural material tests prove named clip/mask/material seats and passive art
   input. Original-resolution captures prove no opaque rectangles/halos, no pasted-on
   look, no generic detail/dirty modal, and no generic floating button face.
6. Capture the corrected Title, six-hotspot Workshop, Archive grid/detail, Deck with
   Pre-Print placement, Supplies/confirmation, Pack inspection, Settings, each
   recovery action state, and Result at both portrait sizes. Add 150% text and high
   contrast for Archive, Deck, Settings, and Recovery; reduced motion must not suppress
   pressed/accepted state cues.
7. Read-only UI review must report P0 none and P1 none for interaction hierarchy,
   physical material ownership, artwork integration, native dynamic text, target
   size, focus, and portrait clipping. Generated masters or automated tests cannot
   self-approve visual quality.
8. Existing M1/M2/M3 deterministic regression remains green. The correction adds no
   catalog/profile/save/economy/battle value and does not alter Android/native AdMob
   ownership.

## Explicit non-goals

- No landscape implementation or landscape capture matrix.
- No new catalog entries, creature/card art identity, card back, stat, cost, deck
  minimum/maximum, ownership, Pre-Print rule, market offer/value, pack grant/pity,
  reward, difficulty, currency, save schema, or progression rule.
- No automatic deck construction, automatic Pre-Print choice, freeform deck names,
  user-authored text, chat, human/mech cast, reroll, dismantle, or new economy.
- No generic modal/panel/button redesign detached from the approved physical objects.
- No baked dynamic copy or values in generated art.
- No production AdMob ID, Godot-side banner reserve, Android export, device claim,
  signing, Drive delivery, or cloud-sync claim in this correction checkpoint.
