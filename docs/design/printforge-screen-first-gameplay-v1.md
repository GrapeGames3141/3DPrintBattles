# PrintForge screen-first gameplay v1

Status: approved preproduction authority for the portrait physical-Workshop UI spike
Date: 2026-08-30
Related authority: docs/design/printforge-legends-mechanics-v3.1.md (document title mechanics v3.2).

Supersession note (2026-08-31): the later approved M5 goal requires a completely
no-AdMob Android review build. The Bottom AdMob region and AdMob geometry ownership
sections below remain the historical record of the earlier review-banner direction,
but they are no longer implementation or delivery authority. Current authority is
`docs/checkpoints/printforge-physical-ui-m5-no-ad-delivery-v1.md`: no AdMob SDK,
plugin, identifiers, permissions/metadata, request path, native banner, or reserved ad
strip is permitted, and the portrait Godot surface uses the full available host area.

## Product promise

PrintForge is a portrait game about choosing whimsical animal/fantasy-creature blueprints, printing visible layered objects, watching them awaken, and sending their living animated print sprites into a small battlefield. The interface is a maker’s Workshop made of physical instruments, drawers, printer chambers, ceramic field plates, cards, folios and clipboards—not a generic app, tavern, or manual trading-card phase simulator.

Player-facing turns are Plan, then Run Cycle. The deterministic authority still owns Draw, Main, Print, Attack and Collect; UI removes routine phase buttons without removing or rewriting those rules.

## Locked boundaries

Portrait only; review at 576x1024, 720x1280 and tall Android. Printer HP 2,000. Three creature slots and FIFO queue capacity three, head only advances. Start battle filament 200, base max 400, Workshop upgrades 500/700; no turn regeneration. Starting player draws zero/cannot attack turn one; other draws two; later draw one if deck nonempty; empty deck not loss. Hand max eight after Collect with deterministic overflow discard. Completed creature needs open slot and Attack/Defense mode or waits staging. One legal mode switch per Main. Printed armor/gem targets a creature; incompatible full slot waits holding; one armor and one gem slot each. Filament Ring is public immediate player effect, never queues/equips/stacks. Preprints consume matching active-deck copies, deploy Defense, cannot act/switch first owner turn. Traps private; public shows set only; replacement confirmed. One upgrade play/turn and max five installed. Preserve all existing FIFO speed/carryover/capacity/pause/cancel/refund, Emergency Reprint, damage/armor/element/gem/ability/destruction/scrap/recovery. Deck min 40 owned; ownership/licenses/models/preprints/rewards/saves remain distinct. Rival hand/deck private. Reuse existing creature art/sheets/card back. One animated sprite per living battlefield unit, no lasting duplicate. Generated art is text-free composition/material only; all dynamic copy/state/focus/accessibility native Godot.

## Plan to Run Cycle state machine

Entering Plan: coordinator validates revision, presents Draw, submits exactly one existing advance intent to Main; no Begin Main button. Local hot-seat privacy handoff precedes owner hand reveal; AI/remote hand never revealed. Battlefield stays visible with player printer, HP, filament, three FIFO spots, hand and Run Cycle lever. Optional actions live by physical owner objects.

Planning actions: zero or more existing legal Main intents—queue creature after catalog filament cost; queue armor/gem with friendly target; play filament/spell/trap/effect/upgrade; inspect/cancel queue with existing floor-half refund and graveyard; switch eligible creature once; activate eligible Main ability/target; Emergency Reprint; optional transient focus target for next cycle. Explain every disabled reason including phase, filament, queue, target, equipment, cooldown, first-turn restriction, upgrade cap and active Ring.

Run Cycle orchestrates existing intents, never a new transaction: lock plan/retain revision; advance Main→Print once; resolve Print once; pause for each placement/attachment and resume only after one accepted decision; in Attack inspect friendly slots 0,1,2 and skip null/Defense/not-ready/attacked/locked/forbidden; legal focus target else lowest occupied rival slot else printer only if rival field empty; one attack intent and finite animation before next; advance Attack→Collect once; resolve recovery/Ring; pause for exact overflow discard; advance Collect once/save settled revision/pass control. AI uses same public presentation and authority. Watchdog may restore latest valid snapshot but never fabricate/repeat intent. Skip/reduced motion completes presentation only, never authority/Forge/reward. Each success increments revision once; rejection preserves exact serialized snapshot and explains.

## Feature contracts

### Title/resume/new maker
Entry launch after platform/safe area. Decision Continue valid clean v3/New Maker/Settings. Result restores stable route or arrival; settings no progression. Invalid/missing save enters recovery, no retired migration. Continue disabled without valid save; overwrite separately confirmed. Native title/version/focus/loading/recovery. Zero progression.

### Starter
Entry carousel Cinderpaw/Aquafin/Voltwig from catalog. Decision swipe/previous-next/inspect/confirm one. Result grants first creature card+permanent printable blueprint exactly once then first-print setup. Invalid/stale rejects unchanged. Confirm disabled without valid focus/pending; nonfocus cannot confirm. Native name/element/HP/Bend/cost/time/abilities and 150% states. No printed model/onboarding completion yet.

### First Forge print
Entry chosen docked blueprint, empty bed. Decision inspect recipe/start/legal presentation skip/return before commit. Result persistent stage wireframe seed, solid below scan, wire above, raw hold, awakening, departure; raw completion commits one model/debit/revision. Failure truthful/zero extra mutation. Start disabled unaffordable/pending; skip cannot bypass failure/unstarted. Native recipe/layers/ETA/status/receipt/errors; reduced motion keeps states. Success completes onboarding and grants exactly three sequential five-card Basic entitlements, never fourth.

### Workshop
Entry onboarding completion/primary return. Decision physical printer, battle dais, archive folio, deck clipboard, supplies cabinet, settings instrument, pending reward. Result corresponding Forge, challenge, Collection, deck/preprint, Supply/Market, Settings, or reward route through canonical callbacks. All six controls dispatch; unavailable destinations explain and remain in Workshop, never silently do nothing or use a retired fallback. Locked visible/reasoned, no invisible overlap. Ambient/focus/touch/short native label/badge/screen reader; focus is a complete four-edge rectangle. Zero progression on inspect.

### Routine Forge
Entry owned printable picker then empty-bed review. Decision filter/select/inspect/start/legal skip/print another/return. Persistent stage to one model/debit. Affordability/stale/license/save failures truthful, no duplicates. Disabled reasons; no persistent Forge filament inventory. Native all dynamic data. Existing zero/exactly-once guarantees.

### Battle preflight
Entry Challenge Board then active deck/preprints/printer/public rival summary. Decision inspect/change deck/begin/return. Legal seeded match with current upgrades/capacity/preprints. Invalid 40-card ownership/preprints/revision/authority blocks. Rival privacy. Preflight zero mutation; preprints affect battle state only.

### Battle Plan
Entry after visible Draw/internal Main. Show both printers/fields/queues/public effects, hidden rival hand count, player hand. Decision legal cards/targets/cancel queue/switch/abilities/Emergency Reprint/focus/inspect/Run Cycle. Each accepted existing intent refreshes public state/revision. Rejections preserve state/explain. Rival noninteractive/private. Run Cycle disabled during pending/modal/handoff/save/required decision. Native event text. Battle state only.

### Run Cycle
Entry settled Main. Decision watch/legal speed-skip and contextual placement/attachment/overflow only. Result internal phases in order; queue head prints in correct printer, raw awakens, one living sprite deploys, eligible attackers sequential, collect and rival follow. Failure restores latest valid snapshot/no repeat. Plan locked; skip cannot bypass decisions. Finite animations, native event rail, reduced motion cuts. Battle revisions until separate result.

### Contextual decisions
Entry placement/held equipment/overflow. Decision open slot+mode, compatible socket, or exact discard. One existing intent clears pending and resumes. Invalidated choice rejects unchanged/refreshes. Background unreachable. Awaiting print visible, legal targets highlighted, native consequence/focus. One battle revision success, no collection model.

### Battle result
Entry authority finished by zero HP/concede. Decision review/Workshop/persisted reward. One result transaction existing outcome/XP/Coin/quest/season/drop. Duplicate/stale no mutation; save failure retains receipt. Continue/reward wait for settlement. Native receipt. Seeded rewards exactly once.

### Collection
Entry archive/pending reveal. Decision filter/select/Card-Stats-Print/navigate/Keep/return. Truthful ownership/license/model, BEND/HP and real support fields. Reviewed fallback and empty states. Unowned/nonprintable reason; pending reveal kept until acknowledge. Native all dynamic. Browsing zero mutation; Keep clears committed reveal only.

### Deck/preprints
Entry loads saved drafts once. Decision owned copies/active deck/up to three legal creature preprints from full draft/save/discard. Legal save existing records; cleared remains empty. Invalid <40/ownership/IDs/noncreature/absent/stale blocks and identifies. Save disabled illegal/pending; no fixed first-three slice. Native counts/legality/150%. Configuration only.

### Supply/maintenance
Entry supply/maintenance routes. Decision category/inspect/buy/wishlist/upgrades/return. Existing epochs/pricing/licenses/gates/receipts; creature purchase grants defined blueprint. Stale/currency/offer/offline/revision atomic failure. Review no real purchase. Native dynamic. Accepted exactly once; browse zero.

### Rewards
Entry persisted entitlement/reveal. Decision Open and Keep; chain starter packs. Each first-print pack exactly five Basic, normal pity, packs 2/3 after Keep. Reload same reveal; duplicate Keep/fourth no mutation. Native counts/names/rarities/pity/accessibility. Commit before reveal; no reroll.

### Settings/recovery
Entry title/Workshop or validation. Decision existing audio/text/contrast/motion/controls/save/recovery. Apply existing preferences; recover clean v3 or confirmed new profile. Settings retains its caller: Title returns to Title with onboarding eligibility unchanged and never bypasses starter/first-print by opening Workshop; Workshop returns to Workshop. Clamp unsupported, preserve failure evidence, no 0.7 migration. Reset separately confirmed. Native preview/focus/status. No progression fabrication.

### Bottom AdMob region
Entry approved Android review initializes native bottom banner with Google test configuration only; production identifiers unset. No gameplay/reward decision; consent native/separate. Native view outside Godot owns creative+bottom navigation/gesture inset; production Godot reserve=0 and receives resized surface. Load/no-fill/offline/SDK failure collapses view and restores surface without blank band; gameplay deterministic. Desktop/editor/plugin-absent/config-block builds request nothing. Positive reserve only labeled synthetic overlay stress. Native disclosure only; diagnostic native height separate. Ads affect no RNG/timer/save/currency/reward/input; no rewarded mechanic.

### M1 interaction safety
Entry any Title, Workshop, Starter, First Print, settings-return, capture, or automated-test state. Decision touch/mouse/keyboard/controller/accessibility activation without pointer ownership side effects. Result every target retains a complete top/right/bottom/left focus outline and pointer remains visible and unrestricted. Missing edge, captured/confined pointer, mismatched Workshop route identifier, real-save test path, or print-cartridge overlap with the chamber fails M1. Disabled targets remain visible and reasoned. Feedback stays native, including `Docked blueprint: <selected starter name>` for the approved text-free cartridge outside the printer chamber. Progression remains governed only by the existing authoritative transactions.

## AdMob geometry ownership

Approved native-bottom-outside-Godot contract. Native owns creative and bottom safe inset. Godot production reserve=0 and lays out only inside resized surface. All controls/modals/hand/event/Run Cycle stay inside. Native height diagnostic only. Desktop may use labeled synthetic reserve. Review uses Google test config. Production app/unit IDs absent until separately supplied/approved. No duplicate disclosure.

## Determinism/save acceptance

Every success has seat/expected revision/result/one increment. Invalid/stale/duplicate/rejected preserves exact state. Run Cycle never batches hidden authority or bypasses decisions. Forge preview/render/cancel/skip/repeated completion/failure retains zero/exactly-once. Starter, print, packs, Keep, deck/preprint, result, purchase and recovery retain namespaces/receipts. Save only stable authority boundaries or fully specified pending receipt/decision. Reload resumes without duplicate.

## Explicit non-goals

No landscape runtime/asset duplicate; no manual Draw/Print/Attack/Collect buttons; no lasting unit duplicate; no mechs/humans/tavern/tactical card-holder field; no save/economy schema change; no persistent Forge filament inventory; no freeform chat; no production AdMob IDs/rewarded ads/ad-gated progression/duplicate disclosure.
