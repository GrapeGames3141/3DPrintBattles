# PrintForge physical UI M3 intact blueprint family checkpoint v3

> **Superseded visual direction (2026-09-01):** The user rejected the v1/v3
> blueprint-card grammar after this historical checkpoint. Its 24-image ledger is
> retained as provenance only and is not runtime art authority or an allowed fallback.
> `printforge-physical-ui-m6-visual-correction-v1.md` and the reviewed
> `creature-blueprints-v2/README.md` pilot now govern blueprint presentation. The
> deterministic route/state contracts below remain authoritative only where they do
> not depend on the superseded v1/v3 visual grammar.

Status: decision-complete integration contract; runtime evidence pending

Date: 2026-08-31

Authority: the approved PrintForge intact-creature blueprint family v3,
`docs/checkpoints/printforge-physical-ui-m1-corrections-v1.md`,
`docs/checkpoints/printforge-physical-ui-m2-battle-v1.md`, and
`docs/checkpoints/printforge-physical-ui-m3-management-v1.md`. This checkpoint changes
presentation only. The v3 catalog, profile/save schema, ownership, deck, Pre-Print,
printing, battle, reward, economy, and accessibility rules remain authoritative and
unchanged.

## Approved family and boundary

The runtime representation for an available creature blueprint is the complete
authored navy blueprint card, not a crop of its creature and not an exploded diagram.
The approved source ledger is:

`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v1/provenance-v3.json`

The hash authority is:

`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v1/SHA256SUMS-v3.txt`

All 24 approved masters are `1254x1254` PNGs. The approved prompt/runtime contract
requires one intact, fully assembled canonical creature in one natural three-quarter
pose on deep navy grid paper with warm cream technical linework, restrained cyan
layer accents, a worn rounded card edge, and quiet cream perimeter. It forbids
exploded parts, detached components, alternate views, duplicates, baked labels/text,
full-color character renders, mechanical reinterpretation, and unrelated redesign.

| Creature ID | Approved master | SHA-256 |
| --- | --- | --- |
| `aquafin` | `aquafin-blueprint-master-v3.png` | `FCEEC460283FD3BA281F8CEA995322E95AC06ABF8EF6FFE1205B6B82BA599D97` |
| `aurorawing` | `aurorawing-blueprint-master-v3.png` | `4DAA4A6E780A391AEDE47387F4C866FB91879942690B1F6EB6D46D8696551550` |
| `brambleowl` | `brambleowl-blueprint-master-v3.png` | `C436870B593A872CD40B2A09D57F51FF0A3E07622666F7DDBB2654325A79F722` |
| `cinderpaw` | `cinderpaw-blueprint-master-v3.png` | `DD9DAB71FB82AADAB222152FC1E7A098BC8C17FAF9A0B687EEE4342CEBA56034` |
| `coalgriffin` | `coalgriffin-blueprint-master-v3.png` | `420525F960DF4D44B13D79058026263D93EA6668FC565D4E718DCEA1F004DEC4` |
| `coralisk` | `coralisk-blueprint-master-v3.png` | `7DAC95BA407CE3D8722CF05FFE6668A551A015FC01B7672000025D30969D44F9` |
| `frostling` | `frostling-blueprint-master-v3.png` | `889E0379F8BD1A0E97309A758749251283F157484CE3D1B1B860A32E64AF2F0B` |
| `galehopper` | `galehopper-blueprint-master-v3.png` | `4603CA865CAF0DDE368EA838D994505E6953E4B85C39346B71A19C3E7F94538D` |
| `glassdrake` | `glassdrake-blueprint-master-v3.png` | `1D0AD144EAC8DC5ECEE616651763E98BD08491CEAA0B961AE97E3A0DA703FEA8` |
| `ironmaw` | `ironmaw-blueprint-master-v3.png` | `7D742266D81967E9C03A0C6B718984A440209729C565921A935E2117E44C6D30` |
| `miragefox` | `miragefox-blueprint-master-v3.png` | `E0DEABCE6ECD779AF93ADA169431A6FC4E0EACC762BC790163EDFE154023471C` |
| `mossmunk` | `mossmunk-blueprint-master-v3.png` | `B716AC9A444E584E6F1BB11C6AD241B95367B206E7B4BCED38649FCC841EFC82` |
| `pyraxis` | `pyraxis-blueprint-master-v3.png` | `16E5D4330F6897BA697DFBB234B203C7FE214F46F99E9DE5C455A36C4C4DA7A5` |
| `runestag` | `runestag-blueprint-master-v3.png` | `520356824A3731F993A3B1295C9EF961FD22B4CF397EBD49E853DBA8F7DACAFC` |
| `skyforge` | `skyforge-blueprint-master-v3.png` | `FF03B57F040A7438A5A59E1047646B890075ADDEE524E2B5A26A6F3EA3512987` |
| `sparkotter` | `sparkotter-blueprint-master-v3.png` | `339932D89466F2B2DF784AA0502BA99F0872B2B48EF30B4E23E677F7666F5092` |
| `starloom` | `starloom-blueprint-master-v3.png` | `01470078E9399D72E254D4958A64F2A0F7D61E181ACC90F9FBA3838FADE4B536` |
| `stoneback` | `stoneback-blueprint-master-v3.png` | `5F7653BDF04DAD0173926DED0547A6D85A7F63D25723E182CFE753F2D14333CE` |
| `thunderelk` | `thunderelk-blueprint-master-v3.png` | `2E1AB546929322DF884B743C2E7FE4B508B92DF3BAB419AC583D3F2A692D4EC6` |
| `tidewhale` | `tidewhale-blueprint-master-v3.png` | `3D1D959107DC30819D023A36FB376DC6AEC393A8CA731DD1EC500C7889DEEBC6` |
| `verdantitan` | `verdantitan-blueprint-master-v3.png` | `F882FAA1CF57A3CB9CBDF8D1F1C0B636030B6E293DD44DEAA6A99B719DDEA682` |
| `voidmanta` | `voidmanta-blueprint-master-v3.png` | `445DD67BA07514A25CCE320E13C150F624D899AC1B838D12EBED44517DB3DF58` |
| `voltwig` | `voltwig-blueprint-master-v3.png` | `6D907878EEF36E5731EECD7D5DCBA705857451E8D60F44FED5F20BB1989046AE` |
| `worldcoil` | `worldcoil-blueprint-master-v3.png` | `18115CD514ABD1CCC9AFF0F56843B0092C6B69A4AFA5B2E2C7B69DC90AF2E69C` |

Read-only catalog audit finds all 24 stable IDs in the current creature catalog. Art
mapping remains presentation data and must not be serialized into the profile or used
to decide ownership, legality, cost, availability, print completion, placement, or
rewards.

## Cross-route creature state language

| Authoritative/presentation state | Required representation | Allowed locations | Forbidden reading |
| --- | --- | --- | --- |
| Blueprint known, offered, selected, held, Pre-Printed, or publicly queued; no extrusion started | Complete intact navy blueprint card under the route-owned mask/clips, with native dynamic facts | Starter, Archive, Deck, Pre-Print clamps, Forge cartridge before Start, player's face-up creature hand, public creature print queue, accepted blueprint/card reward | No detached/exploded parts; no raw model; no finished or animated creature; the image alone does not grant a license/model |
| Accepted print is extruding | Cyan wireframe seed and progressively solid raw-print layers inside the correct printer | Forge bed and acting battle printer only | No blueprint card on the bed as the material being printed; no field sprite; no wrong-side printer |
| Accepted print is physically complete but not awakened/placed | Solid raw print with layer lines; awakening pulse may begin | Correct printer/holding stage only | No animated battlefield idle; no duplicate blueprint/raw/sprite representations claiming separate units |
| Accepted awakening and placement complete | Existing catalog-matched animated 2D sprite | Player/rival battlefield anchor and existing awakened Forge presentation only | Blueprint card never replaces the living field unit; raw print does not remain as a second unit |

The transition is one-way in presentation for a single accepted print event:

`intact blueprint card -> wireframe/layered raw print -> solid raw print -> awakened animated sprite`

Presentation skip and reduced motion may shorten the sequence, but they retain at
least one meaningful blueprint, raw/wireframe, and awakened state and cannot advance
authority.

## Shared mapping, fallback, and action-state contract

### Blueprint family resolver

- **Entry:** Any affected route requests presentation for a stable creature catalog
  ID and current viewer context.
- **Player decision:** None; this is deterministic route presentation.
- **Result:** A known mapped ID returns exactly its hash-approved complete v3 card.
  The same ID resolves to the same card on every route. Support and noncreature IDs
  bypass this resolver and keep their existing art/back.
- **Failure:** Missing file, failed import, unknown ID, invalid texture, or incomplete
  mapping returns a noncrashing intact-blueprint fallback within the same physical
  bounds and emits diagnostics. It never substitutes another creature, raw print, or
  animated sprite.
- **Disabled:** Art absence never changes gameplay availability. If an action is
  unavailable for rule reasons, its hit target is disabled/removed independently of
  the fallback art.
- **Feedback:** Native name/type/reason remains truthful and accessible; fallback is
  visibly generic without exposing paths or error codes.
- **Progression:** Resolution and fallback are zero-mutation and consume no RNG.

Deterministic acceptance:
`tests/test_intact_blueprint_family_v3.tscn [resolver_24_plus_missing]`.

### Hidden and disabled action language

- **Entry:** Any blueprint card is visible in a route with an associated inspect,
  select, add, print, queue, place, or collect action.
- **Player decision:** Focus/tap an available action or inspect an unavailable reason.
- **Result:** Available cards have one clear physical focus/pressed state and execute
  only their route's existing callback. A hidden action has no hit target or focus
  node. A disabled action has a native locked/inactive treatment and exact reason.
- **Failure:** A stale callback is rejected unchanged and refreshes authority; it
  cannot infer success from card animation.
- **Disabled:** Hidden/disabled cards never keep hover, pressed, pointer cursor, or
  focus behavior that makes them look actionable. Decorative cards are passive.
- **Feedback:** Shape/lock/position and native text distinguish state in addition to
  color; 150% text and high contrast do not cover the creature or reason.
- **Progression:** Inspect/focus/rejection are zero-mutation; valid actions retain their
  existing transaction boundary.

Deterministic acceptance:
`tests/test_intact_blueprint_family_v3.tscn [action_state_truth]`.

## Route acceptance contracts

### Starter carousel and starter inspection

- **Entry:** Fresh onboarding presents Cinderpaw, Aquafin, and Voltwig from the current
  starter catalog with no starter committed.
- **Player decision:** Swipe/page, inspect one intact card, select it, confirm the
  starter, or return from inspection.
- **Result:** Each starter uses its exact complete v3 navy card in carousel and detail
  apertures. Focused ID, native name/element/facts, and selected state agree. The
  existing confirmation commits only the chosen starter; first-print setup receives
  its stable ID.
- **Failure:** Missing card art uses the safe intact fallback and leaves inspect/select
  functional. Unknown starter ID cannot confirm and shows a native reason.
- **Disabled:** Confirm is disabled until one valid starter is selected and while its
  existing transaction is in flight. Unavailable choices look locked, not tappable.
- **Feedback:** Card physically focuses/seats forward; selection uses native copy and
  non-color latch. No finished, raw, or animated creature appears before printing.
- **Progression:** Browse/inspect/select are zero-mutation. Existing Confirm is the sole
  starter mutation and remains exactly once.

Deterministic acceptance:
`tests/test_intact_blueprint_starter_routes.tscn`.

### Archive grid and creature inspection

- **Entry:** Archive receives the stable catalog/profile snapshot and current
  category/owned/printable filters.
- **Player decision:** Browse, filter, page, inspect a creature blueprint, open Forge
  when licensed, open Deck when eligible, or close/return.
- **Result:** Every creature entry and detail uses the same complete v3 blueprint card
  under the folio's authored mask/clips. Native facts continue to distinguish owned
  card copies, permanent blueprint state, and printed-model count. Support entries
  retain their exact existing support art.
- **Failure:** Missing blueprint mapping uses the fallback without crashing or hiding
  Close/Back. Unknown catalog IDs render a truthful native unavailable record and
  cannot route.
- **Disabled:** Print, Deck, or other rule-gated actions use native disabled reasons
  and no interactive-looking hover/press. Browsing the card itself remains available
  when its facts can be inspected.
- **Feedback:** Selected blueprint leaf/card is physically seated; native focus and
  ownership/license/model facts remain readable. No exploded art or premature living
  sprite is shown.
- **Progression:** Browse/filter/page/inspect/route handoff are zero-mutation; later
  Print/Deck Save remains its separate existing transaction.

Deterministic acceptance:
`tests/test_intact_blueprint_archive_routes.tscn`.

### Deck Workbench and Pre-Print rack

- **Entry:** Workbench loads the selected fixed slot, owned-card counts, local draft,
  and ordered Pre-Print draft under existing legality rules.
- **Player decision:** Inspect/select a creature copy, add/remove deck occurrences,
  place/remove an eligible ordered Pre-Print, save, discard, cancel, or switch slots.
- **Result:** Creature entries in folio, owned tray, inspector, and populated
  Pre-Print clamps use the same intact v3 card. Support entries keep existing support
  art. Counts, 40+ legality, duplicate ownership, clamp order, and unlock state remain
  native and authoritative.
- **Failure:** Missing mapping falls back visually without changing draft legality.
  Unknown ID, noncreature Pre-Print, absent deck copy, over-duplicate, stale ownership,
  or save failure preserves the accepted profile and names the reason.
- **Disabled:** Plus/minus, Save, locked/empty clamps, and Pre-Print placement reflect
  existing rules. A disabled clamp/card has no enabled-looking hover/press or hidden
  focus target.
- **Feedback:** Selected card seats forward; populated clamp visibly grips the intact
  card; locked clamp and legal/illegal Save differ by more than color. No raw print or
  awakened sprite substitutes for a plan.
- **Progression:** Local edit/inspection are zero profile mutation. Existing Deck and
  Pre-Print Saves remain distinct exactly-once transactions.

Deterministic acceptance:
`tests/test_intact_blueprint_deck_preprint_routes.tscn`.

### Forge selection and pre-extrusion

- **Entry:** Forge opens for an existing learned creature blueprint before Start, or
  the player selects among learned printable creature IDs while the bed is empty.
- **Player decision:** Inspect/select a blueprint cartridge, Start the existing print,
  or return before Start.
- **Result:** The selected complete v3 card is docked as the plan/cartridge under the
  Forge's physical clips; the build bed remains empty before accepted Start. Native
  cost/material/time/licensing facts remain unchanged. After accepted Start, the bed
  changes to wireframe/layered raw-print presentation while the docked plan may remain
  as a reference outside the bed.
- **Failure:** Missing mapping uses the intact fallback and cannot crash Forge. Missing
  license, invalid ID, insufficient currency, stale profile, or persistence failure
  leaves the bed/transaction authoritative and names the reason.
- **Disabled:** Start is disabled for every existing rule reason and during print. It
  cannot look enabled or accept input while disabled. Selection locks after Start.
- **Feedback:** Selected cartridge latches; Start produces the existing accepted
  transaction/animation feedback. No finished or animated creature occupies the bed
  before extrusion/awakening.
- **Progression:** Select/inspect/return are zero-mutation. Existing accepted print is
  the sole print mutation; presentation adds none.

Deterministic acceptance:
`tests/test_intact_blueprint_forge_routes.tscn`.

### Player battle hand and selected-card inspector

- **Entry:** The player's private face-up hand is rendered from the authorized viewer
  snapshot during its existing interactive Plan opportunity.
- **Player decision:** Inspect/focus a card, select a legal creature blueprint to
  queue, choose any required target, cancel, or play a support card under existing
  rules.
- **Result:** Creature hand cards and creature inspector use the intact v3 blueprint
  card; support cards retain their current support fronts/art. Native filament cost,
  type, rules, legal targets, and disabled reason remain authoritative. Selecting art
  never submits an intent by itself unless the existing control contract explicitly
  defines that tap.
- **Failure:** Missing mapping uses fallback without hiding legal actions or exposing
  another identity. Stale/illegal intent is rejected unchanged with the existing
  reason and latest snapshot.
- **Disabled:** Insufficient filament, wrong phase/owner, queue/target restriction, or
  in-flight intent is visibly disabled and not pointer/focus actionable as enabled.
- **Feedback:** Selected blueprint rises from the physical hand and its native
  inspector/targets update. No raw print or field sprite appears merely because a hand
  card is selected.
- **Progression:** Inspect/focus/cancel are zero battle mutation. Each accepted play
  remains one existing battle intent/revision.

Deterministic acceptance:
`tests/test_intact_blueprint_battle_hand.tscn`.

### Public player/rival print queues

- **Entry:** An accepted creature play has created a public FIFO print job in either
  side's printer; the public viewer snapshot legally exposes that job ID.
- **Player decision:** Inspect public queue status; the current player may use only
  existing cancel/target actions when legal.
- **Result:** Creature jobs use the intact v3 blueprint card/thumbnail and native owner,
  position, progress, cost, and status. Equipment/support jobs retain their existing
  representation. The same stable ID maps consistently on both sides once public.
- **Failure:** Missing mapping uses fallback; stale queue/cancel action is rejected
  unchanged. Presentation never hides an authoritative job or fabricates completion.
- **Disabled:** Non-head jobs cannot look like they are printing; rival and otherwise
  unavailable queue actions are passive/disabled with no interactive hover/focus.
- **Feedback:** FIFO head is mechanically latched to the printer and native progress
  identifies the acting side. A queued blueprint is still a plan, not a living unit.
- **Progression:** Queue inspection is zero-mutation; accepted queue/cancel actions
  keep their existing one-intent revision/refund rules.

Deterministic acceptance:
`tests/test_intact_blueprint_battle_queue.tscn`.

### Battle extrusion, awakening, and battlefield handoff

- **Entry:** The existing print cycle advances the public FIFO head in the correct
  printer and later receives accepted placement/mode resolution.
- **Player decision:** Watch or use presentation-only skip/reduced motion; resolve only
  the existing required placement/mode choice.
- **Result:** The blueprint job transitions to wireframe seed, layered raw print,
  solid raw print, awakening, then exactly one catalog-matched animated sprite at the
  accepted field anchor. The blueprint card never becomes the battlefield unit and
  does not remain on the field as a duplicate.
- **Failure:** Missing optional raw/sprite art uses the existing deterministic
  presentation fallback while authority remains truthful. Interrupted animation,
  stale choice, or rejected placement cannot fabricate a unit or wrong-side print.
- **Disabled:** Non-head queue items cannot animate as active; field anchors/modes are
  enabled only when the existing authority requests them. Skip never resolves rules.
- **Feedback:** Native job name, owner, progress, holding/placement/mode, and event
  receipt accompany the finite state changes; reduced motion retains meaningful
  blueprint/raw/awake markers.
- **Progression:** Each accepted battle intent/revision remains unchanged. Every
  animation and representation swap is presentation-only.

Deterministic acceptance:
`tests/test_intact_blueprint_print_to_living_sprite.tscn`.

### Rival concealed hand and privacy

- **Entry:** The viewer is not authorized to see rival private hand identity.
- **Player decision:** None; observe public count and later public actions.
- **Result:** Rival concealed hand uses only the exact approved card back and truthful
  native count. No blueprint mapping, filename, accessible name, tooltip, metadata,
  or hidden node reveals private creature identity. A creature's v3 blueprint becomes
  visible only after the existing public action/queue receipt reveals it.
- **Failure:** Missing card-back resource uses a nonidentifying fallback back; it never
  falls through to a blueprint face or source art.
- **Disabled:** Rival concealed cards are passive and have no player hover/press/focus
  behavior that suggests inspection.
- **Feedback:** Public queue/print receipt supplies only legally revealed identity;
  private cards remain consistently face-down.
- **Progression:** Privacy presentation is zero-mutation. Rival intents keep their
  existing deterministic revisions.

Deterministic acceptance:
`tests/test_intact_blueprint_rival_privacy.tscn`.

### Blueprint/card rewards and receipts

- **Entry:** An accepted pack, Market purchase, first-print starter pack, battle
  result/drop, or other existing receipt returns a creature card/blueprint fact.
- **Player decision:** Inspect the accepted receipt/card, Keep where the existing pack
  flow requires it, open Archive/Forge when legally available, or continue.
- **Result:** A creature reward uses its intact v3 blueprint card after acceptance;
  support rewards retain their exact support art. Native receipt facts separately
  state owned card-copy delta, whether a permanent blueprint was newly unlocked, and
  printed-model count when relevant. Duplicate creature copies do not look like new
  licenses or finished prints.
- **Failure:** Missing mapping uses fallback and cannot suppress, duplicate, reroll, or
  reinterpret the authoritative grant. Missing/failed receipt remains retryable under
  existing exactly-once rules.
- **Disabled:** Continue/Keep/Open Forge follows existing persisted-receipt and license
  rules. Hidden/unavailable actions have no enabled-looking hit target.
- **Feedback:** Accepted receipt seats the intact card in its physical dock/bay with
  native copy/license/model facts; no animated creature implies it was already
  printed or deployed.
- **Progression:** The existing grant/Keep/settlement transaction is sole authority.
  Showing, inspecting, or falling back the card adds zero mutation.

Deterministic acceptance:
`tests/test_intact_blueprint_reward_receipts.tscn`.

### Support-art isolation

- **Entry:** Any affected route renders a noncreature/support card or the rival's
  concealed card back.
- **Player decision:** Inspect/play/queue only under its existing support-card rules.
- **Result:** Existing support fronts/art and exact concealed card back are unchanged;
  the creature blueprint resolver is never used for support, equipment, spell, trap,
  filament, Ring, gem, or upgrade identity.
- **Failure:** Missing support art uses the existing support fallback, never an intact
  creature blueprint or another support identity.
- **Disabled:** Existing support legality determines action state; blueprint mapping
  availability has no effect.
- **Feedback:** Native type/rules/cost/target and privacy remain truthful.
- **Progression:** No gameplay/save mutation comes from art selection.

Deterministic acceptance:
`tests/test_intact_blueprint_support_isolation.tscn`.

## Gameplay-semantic findings

- **P0:** None in the approved family inputs. All 24 master IDs match current creature
  catalog IDs, and the required state sequence preserves the existing print/awaken/
  battlefield authority.
- **P1 gate:** Reward presentation must not collapse three distinct facts—owned
  creature-card copies, permanent blueprint license, and printed-model count—into the
  presence of the intact blueprint image. A first creature-card acquisition may unlock
  its blueprint under existing rules; duplicates do not create new licenses, and no
  reward image creates a printed model. Runtime evidence must prove native receipt
  copy reflects returned authority rather than inference from art.

## Deterministic integration gate

1. Manifest/hash validation proves all 24 promoted runtime copies match the approved
   master bytes or a documented deterministic export derivative; stable ID-to-card
   mapping is complete and has no duplicate/wrong-species entry.
2. A table-driven test resolves all 24 IDs on every affected route and injects unknown,
   missing, failed-import, and support IDs. No case crashes, substitutes another
   creature, changes rules, or leaks a path.
3. Starter, Archive, Deck/Pre-Print, Forge pre-extrusion, player hand, public queue,
   and creature reward use intact navy cards. Automated source/runtime scans reject
   raw-print/sprite textures in those blueprint seats.
4. Forge and battle print tests prove empty bed before accepted Start, then
   wireframe/layered raw print, then solid raw, then awakened sprite only after the
   existing accepted completion/placement boundary.
5. Battlefield tests reject any card-shaped living unit, lasting raw duplicate,
   preplacement animated sprite, wrong creature, or wrong-side printer.
6. Privacy tests prove rival private snapshots and node trees contain no hand identity;
   concealed cards use only the exact back. A public queue may reveal the approved
   blueprint only after its canonical public event.
7. Support-art tests cover each existing support type and prove exact support art/back
   remains selected; creature-blueprint promotion cannot mass-replace support assets.
8. Disabled/hidden action tests use real pointer/focus input and prove unavailable
   actions do not look or behave enabled, while missing art alone never disables a
   legal action.
9. Original-resolution captures at `576x1024` and `720x1280` cover starter carousel,
   Archive grid/detail, Deck with populated Pre-Print clamps, Forge pre-Start and active
   extrusion, selected player creature hand, public queue, awakened battlefield,
   concealed rival hand, and creature/support reward pair. Include 150% text, high
   contrast, and reduced-motion print transition.
10. Read-only UI review rejects exploded/detached imagery, incomplete card crop,
    duplicated cards, finished/animated creature before print, blueprint battlefield
    units, support-art replacement, opaque/uncropped seat overflow, stock actionable
    overlays, and unreadable disabled states. Required result is P0 none/P1 none.
11. Existing M1/M2/M3 gameplay, transaction, save, privacy, battle, reward, and
    accessibility regressions remain green with byte-equivalent deterministic outcomes
    under full motion, reduced motion, missing blueprint art, and presentation skip.

## Explicit non-goals

- No gameplay, balance, catalog, save-schema, ownership, deck, Pre-Print, print,
  battle, reward, pack, Market, economy, accessibility-value, or orientation change.
- No exploded/detached-part predecessor, full-color replacement, new creature
  identity, human, mech, text-baked blueprint, alternate-view sheet, or second card.
- No blueprint card used as raw extrusion material, awakened field unit, attack
  sprite, destroyed-unit remnant, or rival concealed face.
- No replacement of support-card fronts/art or the approved card back.
- No mapping-dependent legality, reward, ownership, or save field.
- No landscape duplicate, Android/build/signing/device claim, production AdMob ID,
  Godot-side banner reserve, Drive delivery, or cloud-sync claim.
