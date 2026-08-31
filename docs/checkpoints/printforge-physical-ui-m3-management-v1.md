# PrintForge physical UI M3 management checkpoint v1

Status: decision-complete; M3 atlas gate PASS; implementation authorized under the
approved portrait physical-Workshop and Plan → Run Cycle direction; runtime-art
integration and runtime capture review remain pending

Date: 2026-08-31

Entry baseline: M1 `ecb0c0a`; M2 `8e9ad3d`

Authority: `docs/design/printforge-legends-mechanics-v3.1.md` (document title
mechanics v3.2), `docs/design/printforge-screen-first-gameplay-v1.md`,
`docs/checkpoints/printforge-physical-ui-preproduction-v1.md`, and the completed M1
and M2 checkpoints. This checkpoint specifies M3 presentation, routing, and
transaction orchestration only. It does not change the v3 catalog, profile/save
schema, economy, ownership rules, deck rules, pre-print rules, rewards, accessibility
values, or card identities.

## Milestone boundary and gate

M3 completes the portrait non-battle workflow surrounding the implemented Workshop,
Forge, and Battle loop: Collection/Archive, creature and support-card inspection,
Deck Workbench and Pre-Print loadout, the five-category Market/Supply cabinet, pack
receipts and reveals, battle-result settlement, Settings, and save recovery.

The eight text-free `m3-atlas-r2` masters passed the required original-resolution
read-only composition review with no P0/P1 finding. Together with the user's already
approved portrait physical-Workshop and simplified battle-loop direction, that gate
authorizes one bounded M3 implementation. The eight masters are the only M3 physical
owner sources authorized for integration; their presence here does not claim that
runtime integration, responsive layout, or capture review has occurred. Runtime
integration must record source, prompt/provenance, dimensions, hash,
crop/derivation, intended role, and approval. Names, values, counters, rules, focus,
disabled states, receipts, and accessibility text remain native Godot controls.

This checkpoint does not claim Android, native AdMob, physical-device, build, signing,
Google Drive, or cloud-synchronization validation. Those remain later delivery gates.

## M3 atlas gate result

Gate result: **PASS** on 2026-08-31. Read-only UI review inspected all eight opaque
RGB masters at their original `941x1672` resolution and reported P0: none and P1:
none. The durable candidates and identity hashes are:

| Authorized M3 master | SHA-256 |
| --- | --- |
| `m3-atlas-r2/CO-01-archive-folio-grid-text-free-v4.png` | `CB86C63DAB77D6F6CF028426CC0A98F6B74B01ED926A98A35A4C1EBD301D2B16` |
| `m3-atlas-r2/CO-02-archive-folio-detail-text-free-v3.png` | `F89CB8F9CAF84B292BE12E2422A66F0464A3CEC1EE2A0E7A9A7B12786D3E2CBC` |
| `m3-atlas-r2/DK-01-deck-workbench-text-free-v2.png` | `886F548F6CDF87FEA7BBCFC38FDAAF80A216430D7AF7345B50DD6FF6005B27CD` |
| `m3-atlas-r2/MK-01-supply-cabinet-text-free-v2.png` | `FCD4B0A045DEEF2C701C5EF07D5E376E47CB570A9F9CB9A96735EC5D4E15D8B2` |
| `m3-atlas-r2/RW-02-pack-opening-v3.png` | `88100CB06C41E3E9C7996757EC118A4BAE56CF35DD65E633EDCD3FB42F103C25` |
| `m3-atlas-r2/BA-05-result-receipt-v4.png` | `9E436AAF7780EE93EFD62F9B142793BD169E340E02D3F8B4D8789A8EEEDB9D4F` |
| `m3-atlas-r2/ST-01-settings-instrument-text-free-v3.png` | `AA10B51A1DF930BC8032EA4D2A4AF3766E1EF0FDDF55926D61C16AD25CACFE2B` |
| `m3-atlas-r2/SY-02-recovery-ledger-text-free-v2.png` | `9D3673D3D8328B40A7746E9EA5C746E9B25FC30BFEF6D366A0CEECC2ED724F0E` |

The source ledger, generation briefs, normalization note, byte sizes, and rejected
sources remain in `docs/art/printforge-physical-ui-spike-20260830/m3-atlas-r2/README.md`.
This gate proves composition suitability of those original masters only. Runtime-art
integration, target-resolution captures, responsive/accessibility behavior, package
inclusion, runtime visual review, and any device/native-ad claim remain pending.

## Locked domain and presentation boundaries

- Preserve the clean `printforge_v3_*` namespace, schema 31 profile shape, stable card
  IDs, existing aliases, fixed currencies, existing market epochs, RNG nonce, pity,
  claim receipts, pending pack reveal, deck/pre-print records, settings record, and
  primary/backup save files. Do not add a second M3 save or receipt namespace.
- `owned_cards`, `owned_blueprints`, and `printed_models` remain distinct. Creature
  card ownership permanently unlocks its printable blueprint under the existing
  rules. Extra card copies do not create additional licenses. Printed models do not
  imply card ownership. Support cards never become printable creature licenses.
- Decks use exactly the existing fixed slots: Forge Deck (`starter-deck`), Queue Deck
  (`deck-slot-2`), and Arcane Deck (`deck-slot-3`). A legal deck has at least 40 cards,
  no maximum, known catalog IDs only, and no more copies of an ID than are owned.
  Slot names are fixed native copy; M3 introduces no freeform naming.
- The Pre-Print rack always communicates three physical positions, but only the
  existing unlocked count is usable: one base slot, two with Pre-Print Slot I, and
  three with Pre-Print Slot II. Every selected item must be a creature copy present
  in the active deck, duplicates cannot exceed deck copies, and battle deployment
  remains Defense Mode with the existing first-owner-turn restrictions.
- Preserve all five existing Market categories and values: Blueprint Stall, Card
  Shop, Pack Emporium, Upgrade Forge, and Cosmetic Atelier, including deterministic
  epochs, level gates, prices, Daily Deal, Newcomer Shelf, wishlist, upgrade
  prerequisites/uniqueness, currencies, pack contents, and pity. M3 creates no new
  shop, offer, currency, exchange, sale, daily grant, purchase source, or real-money
  storefront.
- The first-print reward is exactly three sequential five-card Basic packs. Pack
  cards and ownership are committed before reveal, only one reveal may be pending,
  normal Basic pity applies, and a fourth starter pack is impossible. Paid/existing
  packs retain their existing counts, guarantees, prices, and pity behavior.
- Battle-result settlement retains its existing result ID, victory/loss values,
  caller-supplied coins, Spool XP, Season XP, wins/streak, quest/trial context, and
  drop rules. Presentation may summarize only the returned receipt; it never computes
  or predicts a reward.
- AI/Training difficulty remains a saved compatibility-only field. M3 Settings does
  not display, preview, select, or modify it. Every accepted Settings transition
  preserves its previously loaded value verbatim.
- Portrait only. Reuse existing creature art and the exact support-card back. No human
  or mech characters, no freeform player-authored text, and no landscape duplicate.
- The common hierarchy is a compact level/XP/coin instrument rail, one dominant
  physical work object, a native status/receipt region, and reachable physical
  actions. Secondary drawers or sheets may scroll; the primary action cannot be
  hidden behind an unlabeled gesture.
- All touch targets are at least 48 logical pixels. Primary Save, Buy, Keep, Apply,
  Continue, Retry, and destructive confirmations are at least 56 logical pixels.
  Keyboard/controller focus is a complete visible four-edge rectangle in reading
  order. Pointer mode remains visible and unrestricted.
- 100%, 125%, and 150% text use existing supported settings. High contrast and
  reduced motion preserve information and interaction. Reduced motion replaces
  cabinet, card, stamp, token, and receipt movement with finite state changes; it
  never skips a transaction or acknowledgement.
- Under the approved native-bottom Android contract, the native host owns banner
  creative and bottom navigation/gesture inset outside Godot. Production Godot game
  reserve is zero. A positive bottom reserve is allowed only in a capture explicitly
  labeled `SYNTHETIC AD OVERLAY STRESS`.

## Transaction and mutation contract

Every M3 mutation uses the existing pure rule transition followed by the one
GameManager journal/snapshot mutation path. The UI holds a single in-flight token,
disables duplicate submission, and refreshes from the accepted profile/revision
before enabling another mutation. Browse, filter, sort, page, inspect, preview,
selection draft, tab change, focus, and route return are presentation-only and must
produce a byte-identical profile and unchanged revision.

| Operation | Accepted result | Duplicate/retry rule | Rejection/failure |
| --- | --- | --- | --- |
| Save deck slot | Replaces one fixed slot's card array, makes that slot active under the existing rule, journals once, increments profile revision once | Disable double-submit; after ambiguous persistence, reload the latest valid profile before offering Retry; never replay blindly | Illegal count/ID/ownership/slot or read-only save leaves profile/revision unchanged and names the reason |
| Select active deck | Selects one existing legal fixed slot, journals once, increments once | Selecting while in flight is blocked; refreshed active state is the receipt | Missing or illegal slot stays inactive and unchanged |
| Save Pre-Prints | Replaces the ordered list with zero through the unlocked maximum, journals once, increments once | Disable duplicate submission and reread active deck after any competing deck save | Too many, absent, noncreature, or over-duplicated selections leave profile unchanged |
| Wishlist update | Applies the existing add/remove transition once | Accepted returned membership is authoritative | Invalid ID, capacity, stale/read-only, or save failure leaves the prior list visible |
| Market purchase | Debits the exact returned price and grants exactly the existing item/ownership once in one accepted transition | One confirmation token; duplicate activation cannot submit a second buy; render the returned receipt/profile before re-enabling | Stale offer/epoch, prerequisite, ownership, level, currency, storefront, or storage failure performs no partial debit/grant |
| Pack purchase/claim | Commits exact generated cards, ownership, RNG/pity changes, receipt, and `pending_pack_reveal` before animation | A nonempty pending reveal blocks another pack; reload resumes the same IDs/order/receipt; no reroll | Unavailable, unaffordable, fourth starter pack, existing pending reveal, entropy/authority, or save failure grants nothing new |
| Keep pack reveal | Clears only the already committed pending reveal and journals once | Disable double Keep; refreshed empty pending record is final; next starter pack appears only after accepted Keep | Missing/read-only pending reveal remains unchanged and cannot fabricate cards |
| Settle battle result | Existing result ID is claimed once and returned rewards are persisted in one settlement | Duplicate result ID returns the existing duplicate outcome with no extra reward; never regenerate a receipt client-side | Missing context, read-only save, or settlement/persistence failure holds the result screen and exposes Retry/Recovery without granting twice |
| Apply settings | Validated text/contrast/motion/audio values update their existing settings fields while preserving compatibility-only difficulty verbatim, journal once, increment once | Apply disables until response; reopening reads accepted settings | Unsupported value or save failure retains the last accepted settings; Cancel discards only the draft |
| Recovery/new profile | Uses existing primary/backup/compatibility and confirmed New Maker paths | Confirmation is single-submit and rereads storage before overwrite | Cancel or failed storage preserves every recoverable file and enters no gameplay route |

No screen infers success from animation. A receipt is shown only from an accepted
transition or a persisted pending record. An error remains visible until dismissed or
superseded by a successful retry. Route exit cancels presentation callbacks but never
rolls back an accepted transition or clears a pending reveal.

## Portrait physical-object hierarchy

### Collection / Archive folio

The common instrument rail stays at top. A hinged blueprint folio is the dominant
object. Native metal index tabs provide All, Creatures, Filament, Spells, Equipment,
Traps, and Upgrades without pretending disabled categories are missing. The folio
page owns a full-width responsive card grid. A selected card opens a pull-out lower
inspection drawer; it does not stack a generic centered app modal over a second copy
of the same card. Ownership count, license state, printed-model count, rarity, and
actions remain native. Filters and empty-state copy may reflow above the drawer at
150% text.

### Deck Workbench

A physical deck clipboard is dominant. Three fixed slot medallions sit near its top;
the active one is mechanically latched. The owned-card tray is below/alongside the
clipboard within the portrait width, and the drafted list is a clipped paper stack
with native count and legality. Three Pre-Print clamps are visible as a distinct rack,
with locked clamps showing the exact existing upgrade requirement. Card inspector,
filter, duplicate count, add/remove, slot selection, Pre-Print selection, validation,
and Save have one unambiguous reading order.

### Supply cabinet / Market

A maker's supply cabinet is dominant. Its five labeled physical drawers select the
existing categories; only one drawer is open at a time. Offer cards/blueprint tubes,
the Daily Deal tag, Newcomer Shelf, wishlist pin, price plate, ownership status, and
purchase confirmation use native text. A purchase receipt emerges from the selected
drawer. The cabinet never becomes a generic tab bar or adds a decorative merchant
that competes with product information.

### Pack and result receipts

Pack opening uses the text-free five-dock station at
`docs/art/printforge-physical-ui-spike-20260830/m3-atlas-r2/RW-02-pack-opening-v3.png`
and the exact card back. After the committed receipt is loaded, all five Basic cards
occupy five distinct docks in deterministic order and can be inspected without
mutating ownership. Existing packs larger than five page through those same five docks
without reordering, omitting, or regranting cards. Keep is the station's physical
stamp/filing action that clears the pending receipt; it does not grant the cards a
second time. The rejected three-card diorama is not a composition or runtime source.

The battle result is owned by the dedicated text-free receipt station at
`docs/art/printforge-physical-ui-spike-20260830/m3-atlas-r2/BA-05-result-receipt-v4.png`.
It is a standalone physical filing instrument, not a baked battle diorama and not a
generic modal over a duplicated battlefield. Its blank receipt and instrument bays
host native outcome, XP, coin, drop, level, quest, season, duplicate, and save status
from the settlement receipt. Decorative dials and frames never compute or imply a
reward. Continue returns to Workshop only after settlement is accepted or an explicit
duplicate receipt is confirmed. The rejected `BA-05-battle-result-v3.png` is not a
composition or runtime source.

### Settings / recovery instruments

Settings is a brass calibration board with physical stepped dials/toggles, a native
live preview, Apply, Cancel, and caller-specific Back. Save recovery is a repair folio
showing the available primary/backup/read-only state, not a frightening generic error
dialog. Recovery actions use explicit native consequences and separate confirmation.
Neither screen invents a terminal, password field, account editor, or freeform input.

## Feature contracts

### M3 route entry and return

- **Entry:** Activate Archive, Deck, Supplies, Settings, a pending pack notice, or the
  completed-battle handoff from the existing Workshop/Battle routes with a validated
  profile snapshot and known return destination.
- **Player decision:** Enter exactly one route, return to its caller, or resolve a
  blocking pending reveal/recovery/result receipt before navigating elsewhere.
- **Result:** The canonical physical screen opens with the latest accepted profile.
  Back returns to Workshop, except Settings opened from Title returns to Title and a
  blocking receipt returns to the route recorded by the existing flow.
- **Failure:** Missing route, unavailable authority, invalid save, or stale callback
  leaves the current route visible, changes nothing, and gives the exact reason.
- **Disabled:** Repeated route activation is disabled while transition, modal receipt,
  or storage validation is in flight. A pending blocking reveal/recovery cannot be
  bypassed through background controls.
- **Feedback:** Native route title, Back/accessibility name, current profile status,
  focus, and any blocking receipt remain readable at 150% text.
- **Progression:** Entry, return, and route browsing are zero-mutation.

### Collection archive and filters

- **Entry:** Open Archive from Workshop, Deck inspector, Forge selection, or a kept
  pack receipt using the current catalog and profile.
- **Player decision:** Choose a native category/index tab, filter owned/printable/all,
  page or scroll, focus a card, clear filters, or return.
- **Result:** The folio deterministically shows catalog entries in stable catalog
  order with truthful owned-copy, creature-license, and printed-model counts. Empty
  results keep the folio and offer Clear Filters/Back.
- **Failure:** Missing art, unknown saved ID, or catalog load error uses the reviewed
  fallback and native unavailable reason; it never hides other valid records or
  displays a finished creature as proof of an unowned print.
- **Disabled:** Nonapplicable filters remain visible with a reason where necessary.
  Browsing is disabled only during a route transition or blocking persisted receipt.
- **Feedback:** Native result count, filter state, card name/type/rarity, ownership,
  license/model indicators, focus, empty state, and screen-reader order.
- **Progression:** Every archive/filter/page/focus path is zero-mutation.

### Creature blueprint inspection

- **Entry:** Focus a catalog creature from Archive or an awarded creature card from a
  persisted reveal.
- **Player decision:** Inspect its existing art and catalog facts; choose Print only
  when its blueprint is learned; choose Deck to open a draft context; close/return.
- **Result:** One inspection drawer shows existing creature art and native name,
  rarity, element, HP, Bend, filament cost, print time, abilities/effects, owned card
  copies, permanent blueprint state, and printed-model count. Print/Deck routes pass
  only the stable card ID and do not mutate the profile.
- **Failure:** Unknown ID, missing optional art, or malformed catalog fields show a
  truthful native fallback and keep Close/Back reachable.
- **Disabled:** Print is disabled with `Blueprint not learned` or any existing Forge
  restriction. Deck add is disabled when no owned copy remains outside the draft.
  Disabled actions remain inspectable.
- **Feedback:** Native action reasons and all dynamic facts remain legible at 150% and
  high contrast; focus does not obscure art or counts.
- **Progression:** Inspect and route handoff are zero-mutation. Actual print or deck
  save remains its separate existing transaction.

### Support-card inspection

- **Entry:** Focus a filament, spell, armor suit, gem, Filament Ring, trap, or Upgrade
  Card from Archive, Market, Deck, or a persisted reveal.
- **Player decision:** Read the existing catalog effect and ownership; optionally open
  Deck with that stable ID focused; close/return.
- **Result:** The drawer uses existing card art/card back language and native name,
  type, rarity, filament cost, timing/target, complete catalog effect, owned copies,
  and equipment slot where applicable. Armor, gem, Ring, trap, and upgrade semantics
  match the current catalog and mechanics.
- **Failure:** Missing art or catalog content uses the reviewed fallback without
  inventing an effect, printable license, target, stat, or flavor rule.
- **Disabled:** Support cards never expose Print. Deck add is disabled when ownership
  is exhausted or the card is otherwise unavailable, with the exact reason.
- **Feedback:** Native type-specific facts, ownership count, disabled reason, focus,
  and accessible card description; rival/private battle data never appears here.
- **Progression:** Inspection and Deck handoff are zero-mutation.

### Deck slot selection and draft editing

- **Entry:** Open Deck Workbench with the three ensured fixed slots and the latest
  accepted active deck, owned-card counts, and saved Pre-Prints.
- **Player decision:** Select Forge/Queue/Arcane slot, filter/inspect owned cards,
  add/remove copies, inspect duplicate usage, revert to saved, or request another
  slot/Back while the draft is dirty.
- **Result:** Editing changes only a local draft. Counts show `draft / owned` for each
  ID, total card count, and the first current legality reason. Switching/Back from a
  dirty draft requires Save, Discard, or Cancel; no freeform deck name is offered.
- **Failure:** Unknown saved ID, ownership changed by another accepted transaction, or
  missing slot refreshes validation against the latest profile without silently
  deleting the saved slot.
- **Disabled:** Adding beyond owned copies is disabled; remove is disabled at zero;
  Save remains disabled while invalid or in flight. Empty fixed slots remain editable
  but cannot become active.
- **Feedback:** Native active latch, dirty marker, fixed slot name, total, type curve,
  owned duplicates, legality, filter result, and complete focus order.
- **Progression:** Slot selection, draft editing, inspect, filter, revert preview, and
  dirty confirmation are zero-mutation.

### Deck validation, save, and activation

- **Entry:** A fixed-slot draft is stable and the latest profile/ownership revision is
  available.
- **Player decision:** Save the selected slot, activate another already legal slot,
  or correct the named validation problem.
- **Result:** Save accepts only 40+ known owned cards, replaces exactly that fixed
  slot, makes it active under the existing rule, journals once, and refreshes its
  receipt. Select activates one already legal saved slot in one separate transition.
- **Failure:** Fewer than 40, unknown ID, ownership overage, invalid slot, read-only
  profile, storage failure, or concurrent change preserves the prior saved slot and
  active deck and reports the first deterministic reason.
- **Disabled:** Save/Activate are at least 56 logical pixels and disabled while
  invalid, unchanged where a no-op is presented, or in flight. A second tap cannot
  submit the same transition.
- **Feedback:** Native `Legal` or exact reason, card count, accepted fixed slot, active
  latch, revision/receipt status, save failure, Retry after reread, and Discard.
- **Progression:** One accepted Save or Select produces one profile mutation/revision;
  rejection, inspection, and no-op produce none.

### Pre-Print rack

- **Entry:** The Workbench has a legal active deck and the existing unlocked Pre-Print
  slot count. Saved selections are validated against the full active deck, not a
  fixed first-three slice.
- **Player decision:** Place zero through the unlocked maximum creature copies into
  ordered clamps, remove/reorder them, inspect battle consequences, or save.
- **Result:** One accepted Save replaces the ordered Pre-Print list. Up to three
  clamps remain visible; locked clamps show Pre-Print Slot I/II requirements. Battle
  consumption, Defense Mode, and first-owner-turn restrictions remain unchanged.
- **Failure:** Selection exceeds unlocked slots, is noncreature, absent from active
  deck, overuses a duplicate, or becomes stale after a deck change; save rejects with
  no mutation and refreshes the available creature-copy tray.
- **Disabled:** Locked clamps and invalid copies cannot accept a drop/tap. Save is
  disabled while invalid/in flight; deck Save and Pre-Print Save cannot overlap.
- **Feedback:** Native `selected / unlocked`, ordered slot number, card name, active
  deck copy usage, Defense/first-turn note, lock requirement, legality, and focus.
- **Progression:** Rack editing is zero-mutation. One accepted Save is one profile
  mutation/revision and creates no card, blueprint, or model.

### Supply cabinet browse, offers, and wishlist

- **Entry:** Open Supplies with one caller-supplied time snapshot after the existing
  monotonic market-epoch transition has settled.
- **Player decision:** Open one of five drawers; inspect current offers, Daily Deal,
  Newcomer Shelf, ownership, level/prerequisite state, pack pity, or add/remove an
  existing eligible wishlist ID; return.
- **Result:** Offers, epochs, gates, prices, discounts, currencies, ownership, and pity
  are rendered directly from the current snapshot/profile. Changing drawers and
  inspecting offers never regenerates the snapshot.
- **Failure:** Clock rollback retains persisted epochs. Offline clock/store/catalog or
  unavailable offer shows a native cabinet notice and keeps Back/other valid drawers
  usable; it does not substitute a retired shop.
- **Disabled:** Expired, level-locked, prerequisite-blocked, already-owned unique,
  storefront-only, or invalid offers remain visible with exact reasons. Wishlist
  mutation respects the existing eligibility/capacity.
- **Feedback:** Native drawer title, refresh epoch/time description, item facts,
  ownership, price/currency, Daily/Newcomer tag, wishlist pin, disabled reason, and
  accessible reading order.
- **Progression:** Drawer, page, inspect, and purchase preview are zero-mutation.
  Wishlist changes only through its existing accepted transition.

### Market purchase and receipt

- **Entry:** A still-current offer is selected from the settled Market snapshot and
  no purchase/reveal/save transaction is in flight.
- **Player decision:** Review the exact item, price, currency, ownership consequence,
  and prerequisite; Confirm once or Cancel.
- **Result:** One accepted existing purchase atomically applies the exact debit and
  grant, journals one mutation/revision, and shows a native receipt. Creature
  blueprint purchases grant the defined card/license relationship; other categories
  retain their existing ownership behavior.
- **Failure:** Stale/absent offer, insufficient currency, gate/prerequisite, duplicate
  unique ownership, fake/local storefront unavailability, read-only state, or storage
  failure performs no partial debit/grant and keeps the offer inspectable.
- **Disabled:** Confirm is 56 logical pixels and disabled when blocked or in flight.
  Background cabinet controls cannot trigger a second purchase.
- **Feedback:** Native item, source drawer, price/currency, before/after ownership,
  accepted receipt or exact rejection, and Retry only after a fresh snapshot.
- **Progression:** Preview/Cancel are zero-mutation. One accepted purchase is exactly
  one existing economy/profile mutation; no M3 bonus or ad reward is added.

### Exactly-three starter packs and general pack receipt

- **Entry:** A committed `pending_pack_reveal` exists, or onboarding is complete with
  `entitled == 3`, `opened < 3`, and no pending reveal. A Market pack purchase enters
  the same receipt-first reveal surface after its own accepted purchase.
- **Player decision:** Claim the next eligible starter pack, reveal/inspect the exact
  persisted cards, Keep them, then claim the next starter pack when offered; or return
  after a nonstarter reveal is kept.
- **Result:** Starter claim commits one sequential receipt
  `starter-basic-1`/`2`/`3`, exactly five Basic cards plus only any existing pity bonus
  payload, ownership, RNG/pity, opened count, and pending reveal before animation.
  Reload shows identical IDs/order/receipt. Keep clears only that pending reveal.
  After Keep 1/2, the next entitlement is offered; after Keep 3, the chain ends.
- **Failure:** No entitlement, fourth claim, receipt already claimed, nonempty pending
  reveal, unaffordable/unavailable Market pack, read-only state, or save failure adds
  no ownership, pity, RNG, opened count, or replacement reveal.
- **Disabled:** Open/Claim is disabled while a reveal exists or transaction runs.
  Keep is disabled until persisted receipt data is loaded; card inspection remains
  available. Skip/reduced motion cannot clear the reveal.
- **Feedback:** Exact card back, native pack type, `pack 1/3` counter, receipt, five
  card names/rarities/ownership changes, pity/bonus notice when returned, Keep status,
  save error, focus, and screen-reader reveal order.
- **Progression:** Each Claim/Purchase and each Keep are separate accepted profile
  transitions. Starter chain grants exactly three normal Basic entitlements and never
  a fourth; inspection/reveal animation adds nothing.

### Battle result settlement and progression receipt

- **Entry:** M2 hands off a finished authoritative battle with winner/outcome,
  immutable result ID, settlement context, and latest accepted battle snapshot.
- **Player decision:** Review the outcome while settlement is pending; after accepted
  or duplicate settlement, inspect reward lines and Continue to Workshop. On failure,
  Retry after rereading the profile or open Recovery.
- **Result:** Exactly one existing settlement applies the returned win/loss record,
  coins, Spool XP/level, Season XP, quest/daily/trial progress, and drop payload for
  that result ID. A duplicate result ID produces no extra reward and is presented as
  already filed. Continue cannot resubmit settlement.
- **Failure:** Missing result ID/context, read-only profile, authority rejection, or
  persistence error freezes the truthful battle outcome, grants nothing extra, and
  keeps Retry/Recovery reachable. It never invents consolation or rerolls a drop.
- **Disabled:** Continue, reward filing, and background Battle/Workshop controls are
  disabled until accepted/duplicate receipt is loaded. Retry is disabled while a
  settlement/storage check is in flight.
- **Feedback:** Native Victory/Defeat, printer outcome, result ID status, each returned
  reward line, old/new XP and level when available, drop/none, quest/season progress,
  duplicate notice, save status, focus, high-contrast icons plus text.
- **Progression:** The settlement transaction is the sole M3 result mutation. Result
  animation, receipt inspection, and Continue are zero-mutation.

### Settings and accessibility preview

- **Entry:** Open from Title or Workshop with the caller retained and the accepted
  settings loaded: text scale, high contrast, reduced motion, and fixed-step
  master/music/SFX levels. Saved AI/Training difficulty is compatibility-only and is
  not exposed by this screen.
- **Player decision:** Draft 100/125/150% text; high contrast on/off; reduced motion
  on/off; and existing audio steps 0/25/35/50/75/100%. Preview, Apply, Cancel, or Back.
- **Result:** Preview changes only the screen draft. One accepted Apply validates and
  persists only those player-facing settings, preserves compatibility-only difficulty
  verbatim, journals once, refreshes the shell, and returns only when the player
  chooses Back. Cancel restores the accepted values.
- **Failure:** Unsupported text/audio value, read-only state, or storage
  failure retains the last accepted settings and shows the exact reason.
- **Disabled:** Apply is disabled when the draft is invalid, unchanged where a no-op
  is presented, or in flight. Preview cannot activate a route or gameplay action.
- **Feedback:** Native current/draft values, sample heading/body/button/card/status,
  contrast conveyed by more than hue, reduced-motion explanation, audio percentage,
  caller-specific Back, four-edge focus, and 150% wrapping.
- **Progression:** Preview, Cancel, and Settings navigation are zero-mutation. One
  accepted Apply is one profile mutation/revision and alters no gameplay value, RNG,
  reward, battle state, or ad behavior.

### Save compatibility, backup recovery, and confirmed New Maker

- **Entry:** Startup or a failed M3 persistence check evaluates only the clean v3
  primary, validated temporary/backup evidence, current compatibility, and journal
  using existing SaveService behavior.
- **Player decision:** Continue a valid primary; acknowledge a loaded valid backup;
  remain read-only for an unsupported newer schema; Retry storage validation; return
  when safe; or separately confirm New Maker when no compatible profile should be
  preserved.
- **Result:** Valid primary resumes its stable route. Valid backup recovery reports
  `backup_recovered` and preserves the recovered profile. Newer schema stays unchanged
  and read-only with its existing compatibility message. Confirmed New Maker uses the
  existing v3 profile path and onboarding route only after explicit confirmation.
- **Failure:** Malformed/missing primary, malformed backup, inaccessible storage,
  failed promotion, journal write failure, or repeated validation failure preserves
  every last valid/recoverable file and visible evidence; it never opens the retired
  0.7 save or silently enters Workshop as a new completed maker.
- **Disabled:** Mutating management actions are disabled while read-only or recovery
  is unresolved. Continue is disabled without a valid compatible profile. New Maker
  requires a separate 56-pixel confirmation and is disabled while storage is checked.
- **Feedback:** Native recovery state, supported/current schema context without raw
  secrets, last valid source, what will be preserved/replaced, exact failure, Retry,
  Cancel/Back, and accessible focus. No freeform path or save-name field.
- **Progression:** Inspect, Retry validation, backup acknowledgement, and Cancel are
  zero-mutation. Only confirmed New Maker or an accepted retried transition may write;
  recovery fabricates no ownership, deck, pack, reward, or onboarding completion.

### Native-bottom AdMob management boundary

- **Entry:** Any M3 screen receives the usable portrait Godot surface after the
  approved native Android host has laid out its bottom banner, if present.
- **Player decision:** None; there is no ad-derived management action, reward, pack,
  currency, discount, reroll, save, or progression choice.
- **Result:** Production Godot reserve remains zero. Every 48/56-pixel action, drawer,
  sheet, modal, receipt, and recovery control stays within the resized surface.
- **Failure:** Native load failure/no-fill/offline/SDK absence collapses the native
  view and restores the usable surface without a blank band or gameplay mutation.
- **Disabled:** Production identifiers, rewarded ads, ad-gated Keep/Retry/Continue,
  and duplicate game-owned disclosure remain out of M3.
- **Feedback:** Native disclosure belongs only to the native creative. Any positive
  capture reserve is visibly labeled `SYNTHETIC AD OVERLAY STRESS`.
- **Progression:** Banner state, height, load, failure, and inset change affect no
  profile field, timer, offer epoch, RNG, pity, receipt, reward, or input decision.

## Deterministic acceptance criteria

1. Archive All/category/owned/printable filters and empty/fallback states preserve a
   byte-identical profile and revision. Creature and support inspectors use catalog
   fields only and never conflate card, blueprint, and printed-model ownership.
2. The Workbench exposes exactly three fixed named slots. A draft under 40, with an
   unknown ID, or with any duplicate count above ownership cannot Save/Activate.
   Legal 40+ and legal no-maximum fixtures save exactly once. Double activation,
   rejection, Discard, and inspection do not create a second journal event.
3. The Pre-Print rack shows all three positions while enforcing the existing one/two/
   three unlocked count. Zero selections is legal. Noncreature, absent active-deck
   creature, over-duplicate, stale-deck, and fourth-selection fixtures reject with no
   mutation. One accepted ordered Save mutates once.
4. Market browsing reuses one settled snapshot. Clock rollback does not move an epoch
   backward. Every category renders its existing values. A successful purchase has
   one exact debit/grant/receipt; stale, insufficient, locked, unique-owned,
   storefront-unavailable, read-only, and double-submit paths have no partial or
   duplicate mutation. M3 adds no economic value.
5. Starter reward captures/tests prove receipts 1, 2, and 3 each persist exactly five
   Basic cards before reveal, reload preserves IDs/order/ownership/pity/opened count,
   Keep clears only the pending reveal, only one reveal exists at a time, and a fourth
   claim is rejected unchanged. Existing pity bonus data is displayed but not
   reinterpreted.
6. Finished battle settlement uses the immutable result ID. Win and loss receipts
   render only returned values. Duplicate settlement, Continue, route re-entry, and
   reload grant nothing extra. Missing context and persistence failure hold a truthful
   retryable result and do not reroll a drop.
7. Settings Preview is local draft only. Apply accepts only existing text, contrast,
   motion, and fixed audio values, persists exactly once, preserves saved compatibility-
   only AI/Training difficulty verbatim, retains the Title/Workshop caller, and does
   not modify gameplay/economy/ad state.
8. Valid primary, valid-backup recovery, missing/invalid saves, unsupported future
   schema, read-only management, storage failure, and separately confirmed New Maker
   are covered with isolated test-local save paths. Tests prove the real player save
   is untouched and the retired 0.7 namespace is never read or migrated.
9. Every relevant target is at least 48 logical pixels and every primary transaction
   target at least 56. Four-edge focus, 150% text, high contrast, reduced motion,
   safe-area resize, empty/error states, and modal reachability pass at both portrait
   widths. Pointer remains visible/unrestricted.
10. Production layout reports game reserve zero. The positive-reserve fixture is
    visibly labeled synthetic and cannot be cited as native AdMob/device evidence.
11. Read-only UI review compares every original-resolution capture with the approved
    physical Workshop family and reports no P0/P1 before Sol marks M3 complete.
    Generated concepts or first-pass runtime art cannot self-approve.

## Original-resolution capture matrix

Every standard state below must be captured at both `576x1024` and `720x1280` using
deterministic fixtures and its exact capture ID. Captures are original resolution,
not screenshots rescaled after rendering. A manifest records fixture inputs, route,
profile revision, expected mutation count, source concept, and output file.

| Capture ID | Required state | Composition target |
| --- | --- | --- |
| M3-CO-01 | Archive populated, All tab, mixed owned/unowned creature/support cards | M3 atlas CO-01 folio-grid v4 |
| M3-CO-02 | Owned + printable filters and a truthful empty-filter state | M3 atlas CO-01 folio-grid v4 |
| M3-CO-03 | Owned creature inspector: card copies, license, models, native catalog facts | M3 atlas CO-02 folio-detail v3 |
| M3-CO-04 | Unowned creature inspector with disabled Print reason | M3 atlas CO-02 folio-detail v3 |
| M3-CO-05 | Support inspector for armor/gem/Ring with no Print action | M3 atlas CO-02 folio-detail v3 |
| M3-CO-06 | Missing-art/catalog fallback with Archive/Back still reachable | M3 atlas CO-01/CO-02 folio family |
| M3-DK-01 | Legal active 40-card Forge Deck with owned duplicate counts | M3 atlas DK-01 workbench v2 |
| M3-DK-02 | Queue/Arcane fixed-slot switch with dirty Save/Discard/Cancel | M3 atlas DK-01 workbench v2 |
| M3-DK-03 | Invalid empty/under-40 deck with exact validation reason | M3 atlas DK-01 workbench v2 |
| M3-DK-04 | Ownership-overage duplicate and disabled add/save | M3 atlas DK-01 workbench v2 |
| M3-DK-05 | Three-clamp rack with one unlocked and two upgrade-locked | M3 atlas DK-01 workbench v2 |
| M3-DK-06 | Three legal ordered Pre-Prints with both upgrades | M3 atlas DK-01 workbench v2 |
| M3-DK-07 | Stale/invalid Pre-Print after active-deck change | M3 atlas DK-01 workbench v2 |
| M3-DK-08 | Deck Save in flight with duplicate submission locked | M3 atlas DK-01 workbench v2 |
| M3-DK-09 | Accepted deck or Pre-Print receipt on the refreshed Workbench | M3 atlas DK-01 workbench v2 |
| M3-MK-01 | Supply cabinet overview with all five physical drawers | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-02 | Blueprint drawer: Daily Deal/Newcomer/level gate/wishlist | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-03 | Card drawer and native support-card inspection | M3 atlas MK-01 cabinet v2 / CO-02 detail v3 |
| M3-MK-04 | Pack drawer with prices and persisted pity | M3 atlas MK-01 cabinet v2 / RW-02 five-dock v3 |
| M3-MK-05 | Upgrade drawer with prerequisite/owned-unique states | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-06 | Cosmetic drawer with existing currency choices, no gameplay claim | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-07 | Purchase confirmation with exact price/consequence and 56-pixel Confirm | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-08 | Accepted physical purchase receipt on the refreshed cabinet | M3 atlas MK-01 supply cabinet v2 |
| M3-MK-09 | Stale/insufficient/offline purchase failure with zero mutation | M3 atlas MK-01 supply cabinet v2 |
| M3-RW-01 | Battle Victory before settlement, Continue disabled | BA-05 text-free result receipt station v4 |
| M3-RW-02 | Accepted Victory reward/progression/drop receipt | BA-05 text-free result receipt station v4 / RW-03 level-up |
| M3-RW-03 | Accepted Defeat/consolation receipt using returned values | BA-05 text-free result receipt station v4 |
| M3-RW-04 | Duplicate-result receipt with no additional reward | BA-05 text-free result receipt station v4 |
| M3-RW-05 | Settlement save failure with Retry/Recovery | BA-05 text-free result receipt station v4 / SY-02 |
| M3-RW-06 | Starter pack counter at 0/3 with first persisted parcel | M3 atlas RW-02 text-free five-dock station v3 |
| M3-RW-07 | Five-card Basic reveal from persisted receipt, all five docks occupied | RW-02 text-free five-dock station v3 |
| M3-RW-08 | Kept pack 1/3 with the second claim now available | RW-01 / RW-02 text-free five-dock station v3 |
| M3-RW-09 | Kept pack 3/3 with the starter chain complete and no fourth claim | RW-01 / RW-02 text-free five-dock station v3 |
| M3-RW-10 | Pending reveal restored after reload with identical order | RW-02 text-free five-dock station v3 |
| M3-ST-01 | Settings calibration board at accepted defaults | M3 atlas ST-01 settings instrument v3 |
| M3-ST-02 | 150% text draft and live preview without Apply | M3 atlas ST-01 settings instrument v3 |
| M3-ST-03 | High-contrast preview with non-color state cues | M3 atlas ST-01 settings instrument v3 |
| M3-ST-04 | Reduced-motion preview and accepted Apply receipt | M3 atlas ST-01 settings instrument v3 |
| M3-ST-05 | Invalid settings/save failure preserving accepted values | M3 atlas ST-01 settings instrument v3 |
| M3-SY-01 | Valid backup recovered acknowledgement | M3 atlas SY-02 recovery ledger v2 |
| M3-SY-02 | Unsupported future schema, read-only management actions | M3 atlas SY-02 recovery ledger v2 |
| M3-SY-03 | Missing/invalid saves with separate New Maker confirmation | M3 atlas SY-02 recovery ledger v2 |
| M3-SY-04 | Persistence failure with prior valid snapshot preserved | M3 atlas SY-02 recovery ledger v2 |
| M3-AX-01 | 150% text, four-edge focus, and 56-pixel primary action on Workbench | M3 atlas DK-01 v2 / ST-01 v3 |
| M3-AX-02 | High contrast + reduced motion on pack receipt/result | M3 atlas RW-02 v3 / BA-05 v4 / ST-01 v3 |

Only these tall fixtures are required; do not duplicate the whole matrix at a third
size:

| Capture ID | Size | Required state | Claim boundary |
| --- | --- | --- | --- |
| M3-TALL-01 | `1080x2400` | Tall host-resized management shell with safe top/bottom insets and production game reserve `0` | Synthetic layout evidence only; not physical-device evidence |
| M3-TALL-02 | `1080x2400` | Pack/Deck primary actions above a positive bottom obstruction labeled `SYNTHETIC AD OVERLAY STRESS` | Stress geometry only; not native banner, SDK, or AdMob validation |

## Composition ownership ledger

The eight hash-locked `m3-atlas-r2` masters recorded in the atlas gate are the
authorized M3 physical owners: CO-01 grid folio, CO-02 detail folio, DK-01 workbench,
MK-01 supply cabinet, RW-02 five-dock machine, BA-05 result receipt, ST-01 settings
instrument, and SY-02 recovery ledger. Older CO/DK/MK/RW/ST/SY/BA drafts may explain a
state requirement but are not runtime-art sources. In particular, the v4 receipt
station and v3 five-dock station replace rather than supplement the rejected baked
BA-05 diorama and three-card RW-02 concept.

Runtime capture review must reject or revise integration that behaves as a generic
app panel, bakes changing copy or values, conflicts with the approved warm wood/worn
brass/navy enamel/restrained cyan Workshop family, loses the physical-object action
hierarchy, duplicates an existing card/creature, clips at portrait widths, or cannot
support 150% native text and 48/56-pixel targets.

## Explicit non-goals

- No landscape screens, responsive landscape branch, or duplicate landscape art.
- No catalog stat/cost/effect, battle, deck-minimum, ownership, pre-print, pack,
  pity, market, reward, progression, settings-value, economy, or save-schema change.
- No new currencies, shop categories, offers, pack types, grants, discounts, rerolls,
  dismantle flow, crafting economy, trading, auction, subscription, rewarded ad,
  ad-gated action, or production real-money storefront.
- No custom/freeform deck names, player text, chat, account editing, save naming, or
  user-authored labels.
- No persistent Forge filament inventory and no conflation of Forge Coins, Sparks,
  battle filament, card copies, licenses, or printed models.
- No automatic deck construction, recommended card substitutions, hidden duplicate
  cap, 40-card maximum, automatic Pre-Print selection, or change to battle deployment.
- No reward prediction, client-side drop roll, animation-based grant, pack reroll,
  fourth starter pack, duplicate Keep grant, or result re-settlement.
- No legacy 0.7 migration/fallback, destructive recovery without confirmation, or
  silent overwrite of a valid/backup/newer save.
- No human or mech cast, tavern/storefront drift, generic flat dashboard, or tactical
  battlefield-card-holder redesign.
- No generated readable text in runtime art and no runtime use of generated M3 drafts
  outside the eight gate-passed, hash-locked `m3-atlas-r2` masters.
- No production AdMob IDs, duplicate ad disclosure, Godot-side production banner
  reserve, Android export, signing, APK/AAB claim, device acceptance, Drive delivery,
  or cloud-sync claim in M3.
- No player-facing AI/Training difficulty selector, preview, or mutation; the existing
  saved compatibility field is preserved unchanged.

## Completion gate

The atlas approval gate is complete and authorizes implementation. M3 can be marked
complete only after one bounded sole-writer implementation, deterministic
management/save tests, all named original-resolution
captures, read-only UI review with no P0/P1, Sol's maintainability audit and any
bounded refactor, focused regression across M1/M2/M3, and a requirement-to-evidence
audit. The evidence record must distinguish domain-test, rendered-capture, human
approval, and unavailable device/native-ad claims. Until then, this document is the
decision-complete implementation brief, not evidence that M3 is built or validated.
