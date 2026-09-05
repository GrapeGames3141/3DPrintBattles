# PrintForge M9 playable progression checkpoint v1

Status: decision-complete gameplay and acceptance contract; x10 direct-printer pacing
and corrected animal-barding v2 art direction approved; implementation and new
printable/runtime-alpha evidence pending

Date: 2026-09-04

Entry baseline: `8eac477` on `spike/printforge-physical-ui`

Authority: the committed v3.2 catalog/profile rules, M2 Plan -> Run Cycle battle
contract, M3 management contract, M7 approved creature-blueprint family, and M8
progressive-print/Back contract. The user has already approved the portrait physical
UI atlas and simplified automatic battle loop; M9 does not reopen either approval.

Current-thread decision addendum (2026-09-04): the user stated, “Approve and approve
the art too.” This approves (1) exactly x10 damage for legal direct exposed-printer
strikes, with base printer HP and all other stats unchanged and no fatigue, and (2)
the exact corrected animal-barding direction at
`docs/art/m9-equipment-20260904/standard-barding-completed-concept-v2.png`, SHA-256
`8A6DE969B4950E24F7480B2F2D9C32D35E20C54C1DFB9EDA5CE2E095AAAC82B8`.
The concept's painted checkerboard is opaque; art-direction approval is not runtime-
alpha approval. Neither exact approval should be requested again.

## Outcome and boundaries

M9 turns the approved vertical slice into one complete offline progression loop:
choose and print a starter, assemble a legal 40-card deck from visible free pack
receipts, fight a deterministic bot through Plan -> Run Cycle, earn Forge Coins and
XP, buy packs/cards/fitting equipment/printer mods, and spend XP on bounded creature
and equipment mastery.

M9 is portrait-only. All dynamic names, values, rules, prices, progress, disabled
reasons, focus, and accessibility text remain native controls. Static generated art
is never a text container. Touch targets remain at least 48 logical pixels and primary
actions at least 56. Production game-content bottom reserve remains zero: M9 adds no
AdMob SDK, identifier, permission, request path, placeholder, rewarded mechanic, or
duplicate disclosure. If the separately approved native-bottom host contract is used
later, the native host owns the creative and bottom safe inset outside the resized
Godot surface.

M9 adds no IAP, real-money store, server requirement, player trading, freeform chat,
humans, or mechs. It does not revive manual MTG-style phases. The authority may still
internally resolve Draw, Main, Print, Attack, and Collect, but the player sees Plan,
one Run Cycle action, required physical decisions, finite presentation, and Result.

## Audit: what exists, what is broken, and what is absent

### Compact roster and asset inventory

`data/v3/catalog.json` contains 57 cards:

| Type | Count | M9 disposition |
| --- | ---: | --- |
| Creature | 24 | Complete whimsical animal/fantasy launch roster; add no creature IDs |
| Equipment | 11 | Five full suits, five gems, and Filament Ring; all remain printable/fitting items |
| Filament | 4 | Physical non-spell cards; queue in battle under M9 |
| Spell | 6 | The only immediate-play card type |
| Trap | 4 | Physical non-spell cards; queue before setting |
| Upgrade Card | 8 | In-battle hardware; queue before installation and remain distinct from permanent printer mods |

The 24 creature IDs already have distinct sprite sheets, raw-print images, and the
human-approved coherent v2 blueprint family. Each of the 33 noncreature IDs has a
distinct catalog art reference. There are no `.blend`, `.glb`, `.gltf`, `.stl`, or
`.obj` model files under `assets/` or `art-source/`. The 11 equipment IDs have card
art but no complete per-ID blueprint/raw-print/3D-model presentation family. The
retired `full_suit_raw_print_alpha_v2.png` is a floating humanoid breastplate, helmet,
arms, gloves, and boots; it violates the no-human roster and is explicitly rejected
as M9 equipment authority.

### Actual bugs at the entry baseline

| ID | Observable defect | Why this is a bug rather than new scope |
| --- | --- | --- |
| `M9-BUG-01` | The physical pack receipt renders `mini(5, cards.size())` and provides no receipt paging, so an 8-, 10-, 30-, pity-bonus, or combined reveal hides committed cards. | Existing pack definitions already award more than five cards; the receipt fails to expose the persisted result. |
| `M9-BUG-02` | A nonempty pending pack replaces the displayed route with the pack surface, but that surface has no visible Back and the central dispatcher still reasons from the obscured caller. | Existing M8 promises caller-safe visible/system Back and pending-receipt persistence. |
| `M9-BUG-03` | Workshop printing accepts equipment definitions, but card grants and blueprint offers unlock printable licenses only for creatures, leaving the normal equipment-print path unreachable. | Eleven live equipment cards already advertise print costs/turns and the rule accepts their type. |
| `M9-BUG-04` | Physical Market/Pack rails display `profile.level` although the authoritative field is `spool_level`; the XP label shows only the spool remainder without naming it. | The saved profile and progression rules already define the correct fields. |
| `M9-BUG-05` | The physical Pack drawer constructs base-price offers instead of the frozen market snapshot's effective Daily Deal/Newcomer price; confirmation can show a different debit from the accepted receipt. | M3 requires the exact displayed price and settled snapshot to match the purchase transaction. |
| `M9-BUG-06` | Shared creature cards display nonexistent `attack` as `ATK 0`, while several known support types fall back to generic copy instead of their authoritative rule. | `V3Catalog` supplies `bend` but no `attack`; the card face therefore misreports or omits live battle facts. |
| `M9-BUG-07` | Completing a creature pauses Print for placement; `_print_continue()` calls `_print()` with a newly calculated full speed budget, and the later Print-phase advance can call `_print()` again. One Run Cycle can therefore replenish print work after a required decision. | M2 requires one deterministic Print resolution with finite speed/carryover per owner cycle; a presentation pause cannot create authority budget. |

`V3Catalog.cards()` intentionally normalizes `cost = filament_cost`, `print_ticks =
print_turns`, `bend = bend_score`, and creature `ability_effects = effects`. Consumers
using those normalized aliases receive authoritative values and are not bugs. M9 tests
must verify alias equality at the catalog boundary rather than require every UI caller
to read the raw JSON field name.

### Feature and content gaps

- Fresh onboarding currently grants a finished legal deck directly and then offers
  three unrelated five-card Basic packs. It does not visibly build the chosen
  blueprint into a deck using enough free pack contents to reach 40.
- Live battle queues creatures and ordinary equipment, but filament, traps, and
  Upgrade Cards resolve immediately. There is no unified physical non-spell queue.
- There is no spendable XP wallet, lifetime-XP ledger, or creature/equipment mastery
  tier transition.
- Permanent Workshop upgrades can be purchased, but printer-mod tracks, tier caps,
  complete effects, and upgrade feedback are not coherent; some purchased entries do
  not affect the bot battle printer.
- The repository lacks real 3D printable models for all 35 printable creature/
  equipment IDs and lacks the 11-item equipment blueprint/raw family.
- Title, Workshop root, and live battle intentionally consume/no-op Back in some
  states under M8; the new user requirement supersedes that presentation rule and
  requires a visible Back owner on every full-screen state.

## Locked deterministic economics

### Currencies and battle awards

- Forge Coins buy packs, individual cards, printable blueprints, Workshop prints,
  and permanent printer mods. No M9 action converts XP to coins or coins to XP.
- A completed offline bot victory awards exactly `100` Forge Coins and `50` XP; a
  completed defeat awards exactly `40` Forge Coins and `25` XP. Conceding is a defeat.
- One immutable battle result ID settles the award once. Duplicate settlement returns
  the stored result and changes no wallet, lifetime, Season, Spool, drop, win, or
  receipt field.
- The same XP amount is added once to `upgrade_xp`, `lifetime_xp`, existing
  `season.xp`, and the existing `grant_spool_xp` transition. Spending changes only
  `upgrade_xp`. Season and Spool behavior otherwise remains unchanged.
- Existing deterministic battle-drop and quest rewards remain additional rewards;
  UI lists base battle award and extras separately and never predicts a drop.

### Existing shop values retained

| Pack | Cards | Price | Existing guarantee retained |
| --- | ---: | ---: | --- |
| Basic | 5 | 200 coins | Common-Uncommon pool |
| Forge | 5 | 500 coins | At least one Rare+ |
| Arcane | 8 | 1,100 coins | At least two Rare+ |
| Primordial | 10 | 2,500 coins | At least one Epic+ |
| Champion | 30 | 6,000 coins | At least three Epic+ and one Legendary+ |

Paid pack RNG remains deterministic from persisted nonce/entropy, and existing pity
records remain separate per pack ID. The current rule threshold is authoritative:
the bonus/forced slot occurs when the persisted counter reaches `51`; the UI must say
`next guarantee at 51`, not display `/50`. Basic grants its existing five-card Rare
Reward bonus; other packs replace the lowest-rarity slot with Legendary+. Any natural
Legendary+ resets the relevant counter. New Founder packs below do not use RNG, pity,
Daily Deal, Newcomer Shelf, or coins.

Individual card prices by rarity remain `80 / 200 / 480 / 1,000 / 2,200 / 5,000 /
10,000 / 25,000` coins from Common through Primordial. Blueprint prices remain `50 /
120 / 300 / 600 / 1,200 / 2,500 / 5,000 / 12,000`. Workshop print prices remain `20 /
40 / 70 / 110 / 160 / 220 / 300 / 500`. Dismantling returns the existing integer
quarter of card price. All accepted debits and grants are atomic and receipt-backed.
The daily Blueprint drawer contains exactly 12 deterministic slots: eight creature
and four equipment licenses, each filtered by the existing Spool rarity gate and
priced by the same table. Buying either printable type also grants its first matching
card copy when none is owned, preserving the card/license invariant.

## Requirement 1 — complete cards and printable roster

- **Entry:** The player opens Archive, a pack receipt, Market, Deck Workbench, or
  Forge for any of the 57 catalog IDs.
- **Player decision:** Inspect a real card; for one of the 35 creature/equipment IDs,
  inspect its card, coherent blueprint, raw print, and 3D model, then print when its
  license and price are valid.
- **Result:** All 57 IDs render a distinct card identity with native facts and no
  generic placeholder. The launch creature roster stays exactly the existing 24
  whimsical animal/fantasy creatures. Every creature and equipment card grants one
  permanent printable license on first ownership. All 35 printable IDs resolve a
  matching approved blueprint, raw fused-filament state, and full-volume mesh `.glb`
  model; a flat sprite plane or billboard does not qualify as a 3D model. Creatures
  additionally retain the approved animated 2D battlefield sprite sheet.
- **Failure:** Unknown ID, missing/mismatched asset, generic art substitution, human/
  mech addition, text baked into art, card/license/model conflation, or an equipment
  card whose normal print path is unreachable shows a native unavailable reason and
  performs no debit/grant/print.
- **Disabled:** Print is disabled until the player owns that ID's license, has enough
  coins, has no conflicting in-flight print, and all required runtime assets passed
  the visual/package gate. Spells, filament, traps, and Upgrade Cards have no
  Workshop-model Print action.
- **Feedback:** Archive shows card copies, license, printed-model count, asset state,
  rarity, print price, and Back. Blueprint/raw/model views preserve native labels,
  150% text, high contrast, reduced motion, and 48-pixel navigation.
- **Progression:** First owned creature/equipment copy unlocks exactly one license;
  extra copies do not duplicate it. Each accepted Workshop print creates one model
  receipt. Inspection and art-mode switching are zero-mutation.

### Printable-asset completeness and approval gate

M9C requires one manifest row for each of the 35 printable IDs, keyed by the catalog
ID and exact SHA-256, covering card-art source, blueprint ink, raw-print image, `.glb`,
editable source/provenance, triangle/material counts, full-volume/billboard check,
bounds/scale, pivots, fitting anchors, and intended route. Existing approved creature
v2 blueprints are reused unchanged. New creature models and the 11 equipment blueprint/
raw/model families cannot be promoted into runtime until original-resolution evidence
has read-only UI review P0 none/P1 none and explicit human approval. This is a new
asset-family gate, not a request to reapprove the already accepted UI atlas or battle
loop. Battle remains the approved sprite-sheet presentation: the GLB is the real
printable model/inspection artifact, not authority to replace the battle art family.

The five Full Suit designs are animal/fantasy-creature barding kits: saddle, neck,
back, flank, and belly shells with no human head, torso, arm, hand, leg, or boot
silhouette. Each tier has one standalone printable GLB plus catalog-driven fitted
adapter/anchor metadata for every creature body guide; gems anchor to the authored
collar/gem socket, and Filament Ring is a printer fixture. Commission one
animal-barding pilot and its light/dark portrait evidence before final promotion of
the controlled broad equipment family. The exact v2 direction is already human-
approved, so controlled family generation may proceed without another concept vote.
Its opaque checkerboard cannot ship; each runtime derivative still needs machine-
verified RGBA and route evidence. Rejected humanoid armor remains retired and is
absent from runtime and package scans.

## Requirement 2 — visible Back everywhere

- **Entry:** Any full-screen state, inspector, receipt, confirmation, required battle
  decision, or error/recovery surface is foremost.
- **Player decision:** Activate the visible Back control once; if leaving would lose a
  local draft, live battle, or application session, choose Stay/Discard-or-Concede/
  Exit from the native confirmation.
- **Result:** Every state has exactly one visible, focusable Back owner with a named
  destination or consequence. Inspectors close first. Pack-receipt Back returns to its
  recorded caller while preserving the committed pending receipt and exposes a
  persistent `PACK READY` route back to it. Workshop Back returns to Title. Title Back
  opens Exit confirmation. Live-battle Back opens Concede/Stay confirmation. Required
  decisions close only if their authority permits; otherwise Back is visibly locked.
- **Failure:** Missing/dead Back, two competing Back owners, wrong/root fallback,
  hidden receipt, state loss, automatic concede/exit, accepted-job cancellation,
  transaction mutation, duplicate transition, stale callback, or focus loss keeps M9
  open. A route error leaves the current state visible with a native reason.
- **Disabled:** Back is disabled only during a noninterruptible exactly-once commit or
  when the current required decision cannot be safely abandoned. The control remains
  visible and names the reason; background controls cannot receive input.
- **Feedback:** Labels use destinations (`BACK TO WORKSHOP`, `BACK TO TITLE`) or
  consequences (`BACK / CONCEDE`, `BACK / EXIT`). Pressed, focus, locked, dismissal,
  and confirmation states are finite physical feedback, not color-only cues.
- **Progression:** Ordinary Back and Stay are zero-mutation. Explicit Discard changes
  local draft only. Explicit Concede settles one defeat. Exit never fabricates a save
  or cancels an accepted print/receipt.

### M9 route-owner additions

M8's detailed inspector/draft/in-flight ordering remains authoritative except for the
explicit root/live additions below. `caller` means a recorded route plus focus/filter/
page context, never an inferred generic fallback.

| Foremost screen | Visible Back result |
| --- | --- |
| Title root | Open Exit/Stay docket; Exit is platform quit, Stay returns focus |
| Workshop root | Title |
| Starter gallery before commit | Title; inspector still closes first |
| First Print / general Forge | Recorded caller under existing M8 transaction locks |
| Archive root/detail | Workshop / same preserved Archive folio |
| Deck Workbench | Recorded caller; existing dirty Save/Discard/Stay docket first |
| Market root/order | Workshop / cancel pending nonexecuting order first |
| Pack receipt | Persisted receipt caller; leave `PACK READY` visible without Keep |
| Settings | Recorded Title or Workshop caller; discard unapplied draft |
| Challenge board / preflight | Workshop / same Challenge board |
| Live battle | Open Concede/Stay docket; never concede on the first Back |
| Result | Workshop only after committed/duplicate settlement; pending/error remains locked as in M8 |
| Recovery | Title when a safe Title route exists; otherwise visible locked reason |

Every `pending_pack_reveal` receipt records `return_route` and the minimal serializable
return context before the purchase/claim commit. Reload uses that record. Missing or
invalid legacy context falls back to Workshop, never to an obscured screen. Back does
not clear the receipt; `PACK READY` reopens the identical card order and page. Only
the actual Keep control clears the committed pending record.

## Requirement 3 — Android native Back equivalence

- **Entry:** Android emits `go_back_requested` while any state in Requirement 2 is
  foremost.
- **Player decision:** Press native/system Back once and, where opened, choose the same
  confirmation choice offered by visible Back.
- **Result:** One central dispatcher produces byte-equivalent route, caller, modal
  depth, draft, pending receipt/job, battle state, focus return, profile revision, and
  callback count for visible and Android Back.
- **Failure:** App/OS fallthrough while an in-game owner exists, visible/system
  mismatch, double event, direct screen fallback, mutation on dismissal, or Android
  bypass of a locked visible Back is a blocking regression.
- **Disabled:** Android Back is consumed with the exact visible locked reason during a
  commit/required-decision lock. It cannot exit the app, dismiss the route, or invoke
  a second action.
- **Feedback:** The same native confirmation, toast/reason, destination label, and
  returned focus are used for both input sources. No Android-only overlay is added.
- **Progression:** System Back changes progression only after an explicit confirmed
  Concede/Discard/Exit choice, under the same exactly-once rule as visible Back.

## Requirement 4 — starter choice builds a legal deck through free packs

- **Entry:** A genuinely fresh profile is in `choose_starter`; old complete saves are
  never re-enrolled or granted retroactive Founder packs.
- **Player decision:** Inspect and choose Cinderpaw, Aquafin, or Voltwig; print that
  starter free; then open and Keep Founder receipts 1, 2, and 3, with Back allowed
  between receipts.
- **Result:** Choice grants one card and its blueprint license and creates a provisional
  `starter-deck` containing that chosen ID. Free First Print creates its starter model.
  Exactly three deterministic 13-card Founder packs then deliver the remaining 39
  copies of the established starter list. Each pack claim atomically grants its 13
  owned copies, appends the same ordered 13 IDs to the provisional deck, advances the
  opened counter, and persists the pending receipt. Keep only acknowledges that
  already committed receipt, advances the kept counter, and clears pending. After
  receipt 3 is Kept, Forge Deck is exactly 40 known owned cards, contains 12 copies of
  the chosen starter, 8 Mossmunk, and the existing 20-card support multiset; it becomes
  active and legal without hidden grants.
- **Failure:** Invalid starter, save/read-only failure, missing asset, duplicate receipt,
  hidden card, wrong order, append without ownership, ownership/deck append without
  the same pending receipt/opened commit, mutation during Keep,
  fourth pack, under/over-40 final deck, or reload reroll leaves the current safe state
  visible and grants nothing extra.
- **Disabled:** Battle and editable deck Save/Activate stay disabled until all three
  Founder receipts are Kept and the final deck validates. Next Founder pack is disabled
  while one receipt is pending. Starter choice is locked after its accepted commit;
  New Maker is the only destructive restart path.
- **Feedback:** Native progress reads `STARTER CHOSEN`, `FIRST PRINT`, then `FOUNDER
  PACK n/3`, with receipt pages `1/3`, `2/3`, `3/3` for 13 cards at five per page.
  Deck count advances visibly `1 -> 14 -> 27 -> 40`; the chosen blueprint/card is
  visibly first. Back preserves pending content and returns to its caller.
- **Progression:** Founder contents are the exact catalog-authored table below, not
  random. Claim atomically commits receipt, ownership, provisional-deck append, and
  opened count once. Keep is an acknowledgement-only transaction: increment `kept`
  once and clear pending, with no ownership/deck grant. These packs cost zero and
  change no RNG nonce, pity, coins, XP, Season, or Spool field.

### Exact Founder pack contents

`starter` below means the one accepted starter ID. Order shown is receipt/deck order.

| Receipt | Exact 13-card ordered contents |
| --- | --- |
| Founder 1 | `starter` x4, `mossmunk` x3, `raw_filament` x2, `heated_spool`, `layer_melt`, `standard_full_suit`, `iron_gem` |
| Founder 2 | `starter` x4, `mossmunk` x3, `raw_filament`, `heated_spool`, `print_jam`, `spool_drain`, `reinforced_full_suit`, `counter_strike` |
| Founder 3 | `starter` x3, `mossmunk` x2, `raw_filament`, `forge_surge`, `emergency_reprint_spell`, `blueprint_thief`, `filament_ring`, `print_interrupt`, `speed_spool`, `reinforced_chassis` |

Together with the initial chosen-starter card, this is the same multiset as the
existing 40-card starter composition: starter x12, Mossmunk x8, and the established
20 support copies. Its ordering is intentionally the new interleaved receipt order.
The varied partition makes every free receipt teach creatures, material, spells, and
fitting/hardware cards without changing the final deck balance.

Every card face reads authoritative normalized catalog data. Using `cost`,
`print_ticks`, `bend`, or `ability_effects` is valid because `V3Catalog` supplies them
from `filament_cost`, `print_turns`, `bend_score`, and `effects`. A creature face shows
HP, Bend, Print, element, cooldown, and authored ability/effects; it labels Bend as
`BEND` and does not invent an unsupported `ATK` field. Filament, spell, trap,
equipment, and Upgrade Card faces expose the exact effect/trigger/cap text used by the
battle authority. Generic `Tactical printer effect` copy is not acceptable for a
known ID.

This requirement intentionally supersedes M3's three five-card Basic starter reward
only for a profile born with `onboarding.founder_version = "founder_v1"`. Its stable
reward record is `{"kind":"founder_v1","entitled":3,"opened":0,"kept":0}` plus the
pending receipt owned by the existing pending-reveal boundary; receipt IDs are
`founder-v1-1`, `founder-v1-2`, and `founder-v1-3`. The marker is written by
`new_profile()` only, never by general save ensure/migration. Paid Basic packs and
their Newcomer/Daily Deal rules remain unchanged. Existing complete profiles and
in-progress unmarked onboarding saves retain the legacy path and all loaded decks/
cards/claims/pending receipts; they are never converted or granted Founder content.
Automatic starter-deck repair must skip a marked Founder profile until `kept == 3`;
afterward ordinary legal-deck repair may run.

## Requirement 5 — bot battle and the physical non-spell print queue

- **Entry:** The player starts an offline bot match with a legal active 40+ card deck,
  legal Pre-Prints, and a deterministic seed. Plan is settled and the player's hand is
  interactive.
- **Player decision:** During Plan, play zero or more legal cards/targets, inspect or
  cancel queued work, make optional existing mode/ability/focus choices, then pull Run
  Cycle once. Spells resolve immediately. Every non-spell card enters the player's FIFO
  printer queue before its effect can resolve.
- **Result:** Creature, equipment, filament, trap, and Upgrade Card all pay/reserve
  their authoritative cost and enter FIFO. A non-spell with catalog `print_turns == 0`
  uses one turn; authored data should be normalized to at least one. Each Print step
  advances only the head with one deterministic finite budget per owner cycle. A
  required placement/attachment/replacement pause persists the unspent remainder and
  never recalculates or replenishes it. On completion: a creature
  pauses for an open slot and Attack/Defense choice, then the finite raw -> awaken ->
  walk-to-slot presentation runs; equipment enters equip-ready holding and pauses for
  a compatible target; filament grants its authored amount; a trap becomes set after
  Keep Existing/Replace if needed; an Upgrade Card installs after its reserved caps
  validate. Run Cycle then automatically resolves legal attacks in slot order, Collect,
  and the bot through the same authority until the next player Plan or Result. A
  direct attack remains illegal while any rival slot is occupied. When the printer is
  legally exposed, applied printer damage is exactly `normal_damage * 10` using the
  existing deterministic integer damage result;
  base printer HP remains `2000`, Reinforced Chassis remains `+500`, creature combat
  is unchanged, and empty draws cause no fatigue.
- **Failure:** Immediate non-spell effect, spell queued, out-of-order completion,
  progress without cost/reservation, duplicate effect, missing required decision,
  creature teleport/no finite walk, equipment auto-attached without the required
  choice, hidden bot authority, stale generation, or manual phase buttons is blocking.
  Applying x10 to a creature target, bypassing a defender, changing base printer HP,
  adding fatigue/overtime, or displaying damage different from the applied receipt is
  also blocking. Rejection preserves the exact serialized state/revision and reason.
- **Disabled:** A card is disabled for insufficient filament, full effective queue,
  incompatible/reserved target, occupied equipment socket, trap/unique/upgrade cap,
  wrong seat, stale revision, or active presentation. Run Cycle is disabled outside a
  settled Plan or during a required choice/commit. Battle Back remains visible but
  opens Concede only when the authority is safe.
- **Feedback:** Queue cards show type, cost, total/remaining turns, FIFO position, and
  completion destination. One physical printer animation, raw completion, awaken/walk
  or equip-ready tray, event rail, and native reason reflect accepted snapshots only.
  Reduced motion uses finite held states and never skips authority. An exposed-printer
  hit shows the exact x10 applied damage and authoritative HP before/after.
- **Progression:** Each accepted intent increments battle revision once. Print
  presentation and walking do not grant collection models or XP. Only immutable Result
  settlement awards profile progression once. Print budget initialization, spending,
  pause, resume, exhaustion, and resolved state are serialized battle authority.

### Finite once-per-cycle print budget

At the first resolution entry for one seat/turn's Print phase, authority creates a
stable `print_cycle_id`, `print_budget_total`, `print_budget_remaining`, and
`print_cycle_resolved = false`. Total is calculated exactly once from the permanent
printer-speed snapshot plus installed Speed Spool/Turbo Spool card effects. Each unit
of budget reduces only the current FIFO head by one turn. Completion may consume less
than the remaining budget, so carryover advances the next head.

If completion opens a required decision, remaining budget and cycle ID persist while
paused. Accepting that decision resumes with the saved remainder only. When the budget
reaches zero or no queued job remains, authority sets `print_cycle_resolved = true`;
the subsequent Print -> Attack transition cannot invoke print work again. Repeated
resume, presentation acknowledgement, reload, stale callback, or phase advance cannot
increase total/remaining budget. At minimum print time one, ordinary completed jobs
per cycle cannot exceed `print_budget_total`.

An authored effect that grants print progress is a separately receipted bonus, not a
base-budget reset. In particular, completed Heated Spool grants its existing one
bonus progress to the then-current head once. The receipt records base total/spent/
remaining and bonus progress separately so tests never infer authority from animation.

### Stable per-job print-event presentation

Entry-baseline gap: `_presentation_after()` compares only the before/after queue head
and queue lengths. It cannot distinguish duplicate card IDs or describe print work
performed when `_place()`/`_attach()` resumes `_print_continue()` inside the same
accepted intent. A speed batch can therefore mutate a second job without producing
its own visible work/completion sequence. This is presentation incompleteness coupled
to `M9-BUG-07`, not authority to replay `_print()`.

Every accepted enqueue stores an immutable `job_id` on the queue item and carries it
unchanged through pending, staging, holding, deploy, graveyard, or completion. The ID
is deterministic metadata: `p{seat}-r{accepted_revision}-n{enqueue_ordinal}`, where
the zero-based ordinal distinguishes any jobs created by one accepted intent. It is
not derived from `card_id`, queue position, art, or RNG. An M9-created job without an
ID is invalid. If recovery ever receives a pre-M9 in-progress snapshot, a versioned
adapter assigns `legacy-p{seat}-{container}{stable_index}-r{snapshot_revision}` in
seat/container/FIFO order once and persists the migrated snapshot without a battle or
profile revision; it never renames a migrated job.

The rules result for each accepted intent returns an immutable ordered
`print_events[]` batch rather than asking presentation to infer work from snapshots.
The batch ID is `r{accepted_revision}` and event IDs are
`r{accepted_revision}-e{zero_based_index}`. Each event contains `job_id`, actor seat,
public type, authority revision, event kind, remaining before/after, base or authored-
bonus budget spent, and completion destination. `card_id`, target, slot, and mode are
included only when public to that viewer. Required event order is:

1. `print_work` for the FIFO head, including partial progress even when it does not
   complete;
2. `print_complete` for that same job before any destination event;
3. creature `await_place`/`staged`, or equipment `equip_ready`/`holding`, or the exact
   completion event for filament/trap/Upgrade Card;
4. after a later accepted placement, `deploy` for that same creature job. Its finite
   raw-hold -> awaken -> 2D walk presentation completes before events for subsequent
   jobs returned by `_print_continue()` are shown;
5. repeat work/completion/destination in actual FIFO and budget-consumption order for
   every subsequent job. Equal `card_id` values never collapse events.

An accepted state revision and its event batch are captured together before UI
playback. Presentation owns a serialized `batch_id`, immutable events, and
`next_event_index`; acknowledging one event advances only that cursor and never the
battle revision. While an event remains unacknowledged, the next authoritative intent
is latched except for the exact required decision exposed after its preceding event
batch completes. Interruption, route exit/re-entry, or reload resumes at the first
unacknowledged event. Duplicate acknowledgement is idempotent. If animation/art fails,
the native reduced-motion fallback still presents and acknowledges each event in order;
it never reruns authority, jumps the cursor over a second print, or invents a job.

Public event projection preserves M2 privacy. A public creature/equipment/filament/
Upgrade job may expose the identity already revealed by its legal play. A rival queued
or set trap exposes only `job_id`, card back, and `type = trap` until the existing
trigger reveals identity; rival hand/deck index and face-down trap `card_id` never
enter the public batch. The owning private view may show its own identity. Redaction
changes fields only, never event count/order/IDs or authority state.

- **Entry:** Run Cycle enters Print with one or more FIFO jobs and a finite serialized
  budget; or an accepted required placement/attachment resumes saved budget.
- **Player decision:** Watch/skip only presentation, or use the actual required-choice
  control after its preceding batch is acknowledged.
- **Result:** Every accepted unit of work and every completion has one stable job-bound
  event in exact authority order; each creature deploy and equipment hold is shown once.
- **Failure:** Missing/duplicate/renamed job or event ID, snapshot-inferred completion,
  collapsed duplicate card, out-of-order deploy, hidden trap leak, skipped later job,
  cursor loss, or authority replay blocks the presentation gate without another
  gameplay mutation.
- **Disabled:** New intents and required-choice hit targets remain latched until the
  preceding event batch reaches its allowed decision boundary. Presentation controls
  never call `_print()`, `_print_continue()`, placement, attachment, or effects.
- **Feedback:** Native event rail names public job/type, remaining work, completion,
  destination, and replay/reduced-motion state; the physical printer/raw/awake/walk or
  equip-ready visual matches the current event ID.
- **Progression:** Job IDs, batches, playback, acknowledgement, replay, and redaction
  grant nothing and consume no RNG. Only the original accepted intent owns its one
  battle revision and any eventual immutable Result owns coins/XP.

### Non-spell completion and reservation table

| Type | Enqueue validation | Completion |
| --- | --- | --- |
| Creature | Filament, effective queue capacity | Required open-slot + mode; otherwise public staging |
| Armor/Gem | Filament, queue, at least one potentially compatible owned field target or allowed holding | Equip-ready; player chooses a living friendly creature with that empty socket |
| Filament | Filament/card legality and queue | Gain authored filament, capped by printer capacity, then graveyard |
| Trap | Queue and one pending/set trap reservation | Set if empty; otherwise required Keep Existing/Replace, then displaced card to graveyard |
| Upgrade Card | Queue, one play/turn reservation, five installed-or-reserved cap, unique-key reservation | Install; reserved slot/key is released exactly once on cancel/failure |
| Filament Ring | Equipment queue and one player-effect reservation | Equip-ready target is the player's printer; activation sets the nonstacking public Ring effect |

Armor and gems never silently replace an occupied socket. Equipment may remain in
holding until a compatible living creature exists. Its card and paid cost remain in
battle state across Run Cycle/reload; it cannot be replayed or duplicated.

## Requirement 6 — rewards and the useful Market

- **Entry:** A bot Result is unsettled, or the player opens Market from Workshop with a
  frozen snapshot and no in-flight purchase.
- **Player decision:** Settle/Continue; browse Packs, Cards, Fitting Equipment, or
  Printer Mods; inspect exact contents/effects; confirm one purchase or Back/cancel.
- **Result:** Result grants the exact win/loss coins and XP above plus returned extras.
  Market sells all five existing paid packs, rotating individual cards of every live
  type, the 11 equipment fitting items through card offers, printable creature/
  equipment licenses, and permanent mods below. Purchase shows and debits the same
  effective frozen price once, grants one exact item/license, then refreshes.
- **Failure:** Stale offer, price mismatch, unavailable type, insufficient coins,
  prerequisite/cap/ownership failure, unresolved receipt, read-only save, or persistence
  rejection performs no partial debit/grant and keeps a retryable native error.
- **Disabled:** Confirm is disabled without funds, while another receipt/reveal is
  pending, when a unique license/mod is owned, when a prerequisite is missing, or
  during the commit latch. Back remains visible and shares the latch reason.
- **Feedback:** Native rail separately labels `LEVEL` (`spool_level`), `SPOOL XP`
  (remainder/next threshold), `UPGRADE XP`, `LIFETIME XP`, and `COINS`. Offers show
  type, ownership, exact effective price, guarantee/meter, compatibility, and result
  receipt. All awarded pack cards are reachable by five-card pages.
- **Progression:** Browsing is zero-mutation. Settlement, purchase, Keep, and wishlist
  each use their existing or new isolated exactly-once receipt. Acquiring a creature or
  equipment card unlocks its printable license once; support-only types never do.

## Requirement 7 — spend XP on creature/equipment mastery

- **Entry:** The player owns the creature/equipment card, its printable license, and at
  least one printed model; the selected catalog ID is below its rarity cap.
- **Player decision:** Inspect the exact next-tier cost and battle effect, then confirm
  `UPGRADE` or Back.
- **Result:** One atomic transaction subtracts the exact next-tier cost from
  `upgrade_xp` and increments `card_mastery[id]` by one. Creature mastery adds
  `ceil(base_hp * 5 * tier / 100)` max/current HP at battle construction. Armor mastery
  adds `ceil(base_armor_hp * 10 * tier / 100)` armor HP when fitted. Gem mastery adds
  `2 * tier` armor HP when fitted without changing authored attack/effect values.
  Filament Ring mastery grants `25 * tier` one-time printer shield when its equip-ready
  activation resolves; it does not change base printer HP or stack a second Ring.
- **Failure:** Unknown/nonprintable ID, wrong type, unowned/unprinted item, cap reached,
  insufficient wallet, repeated/stale confirmation, overflow, or save rejection leaves
  wallet/tier/profile revision unchanged. Battle snapshots never change retroactively.
- **Disabled:** Upgrade is disabled until requirements and wallet pass, at the rarity
  cap, during a save, or while viewing a battle-owned transient instance. No downgrade,
  refund, respec, or per-copy upgrade exists in M9.
- **Feedback:** Native panel shows current/next tier, cap, exact XP cost, base and
  resulting integer stat, wallet balance, and `applies next battle`. HP and armor
  receipts distinguish base, mastery, and fitted contributions.
- **Progression:** Mastery is per catalog design ID and applies to every future copy/
  model of that ID. Lifetime, Season, and Spool XP never decrease. Spending is
  receipt-backed and increments profile revision once.

### XP costs and caps

| Next tier | XP cost | Creature HP | Armor defense | Gem defense | Ring shield |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 100 | +5% base | +10% base | +2 | +25 |
| 2 | 250 | +10% base | +20% base | +4 | +50 |
| 3 | 500 | +15% base | +30% base | +6 | +75 |
| 4 | 900 | +20% base | +40% base | +8 | +100 |
| 5 | 1,500 | +25% base | +50% base | +10 | +125 |

Rarity caps are Common `2`, Uncommon `3`, Rare `4`, and Epic or higher `5`.
All percentage math uses positive integer ceiling `(base * percent + 99) / 100`, then
adds the result to the unchanged catalog base. Tier cost is paid only for the next
tier, not cumulative again.

### XP save migration

Add `upgrade_xp`, `lifetime_xp`, `card_mastery`, and an idempotent `xp_migration_v1`
marker without renaming or deleting any existing field. For a profile without the
marker, reconstruct earned Spool XP as:

`legacy_spool_total = 50 * spool_level * (spool_level - 1) + spool_xp`

Set both new XP ledgers to `max(0, existing value if present, season.xp,
legacy_spool_total)`, preserve `spool_level`, `spool_xp`, the full `season` dictionary,
coins, revisions, receipts, ownership, decks, and every other save value verbatim,
then set the marker. Because no prior mastery spending existed, the reconstructed
amount is legitimately unspent. Repeated ensure/load never grants it again. Fresh
profiles start both ledgers at zero.

## Requirement 8 — buy and upgrade permanent printer mods

- **Entry:** The player opens Market -> Printer Mods with a frozen price snapshot.
- **Player decision:** Inspect a mod track, prerequisite, next-tier price, and exact
  effect; confirm Buy/Upgrade or Back.
- **Result:** The accepted tier is appended once to `workshop_upgrades`, debits coins,
  and affects newly constructed battles. Permanent mods are not deck cards and do not
  consume the in-battle five-Upgrade-Card cap.
- **Failure:** Unknown tier, out-of-order purchase, owned tier, insufficient coins,
  stale price, duplicate submit, or persistence rejection leaves coins/mods/revision
  unchanged and keeps the exact reason visible.
- **Disabled:** A tier is disabled until its prior tier is owned and coins suffice; a
  capped track shows `MAX`. Mods cannot be sold, refunded, respecced, queued as cards,
  or changed during a live match.
- **Feedback:** A native printer schematic shows current/next tier, exact coins,
  prerequisite, before/after integer capacity/speed/slots/discount, installed stamp,
  and Back. Battle preflight lists all applied permanent mod effects separately from
  deck-based Upgrade Cards.
- **Progression:** Purchase is permanent and receipt-backed. Battle construction reads
  a snapshot; buying later never mutates an existing battle. Old recognized IDs keep
  their owned tier/effect after migration.

### Printer-mod tracks and exact values

| Track / stable ID | Cost | Prerequisite | Effect in newly created battle/profile |
| --- | ---: | --- | --- |
| `forge_speed_i` | 300 | none | Printer speed 2 (base 1) |
| `forge_speed_ii` | 900 | Speed I | Printer speed 3 |
| `forge_speed_iii` | 1,800 | Speed II | Printer speed 4 |
| `spool_capacity_i` | 400 | none | Filament maximum 500 (base 400) |
| `spool_capacity_ii` | 1,000 | Capacity I | Filament maximum 700 |
| `print_yard_expansion` | 600 | none | Base FIFO capacity 4 (base 3) |
| `print_yard_expansion_ii` | 1,600 | Yard I | Base FIFO capacity 5 |
| `preprint_slot_i` | 800 | none | Two Pre-Print slots (base one) |
| `preprint_slot_ii` | 2,000 | Slot I | Three Pre-Print slots |
| `blueprint_discount` | 1,200 | none | Existing 5% blueprint-price reduction |
| `daily_quest_slot` | 3,000 | none | Existing fourth daily quest slot |

Speed Spool/Turbo Spool Upgrade Cards add their existing `+1/+2` speed only after
their queued installation. Dual Queue adds its existing `+2` to the permanent base
capacity only after installation. Multiple authored card copies behave under the
existing five-installed cap. Permanent mods do not shorten the separate finite Forge
cinematic or bypass a transaction; they change authoritative battle print progress.

## Equipment compatibility contract

- Every one of the 24 creatures has exactly one `armor` socket and one `gem` socket.
- The five Full Suit IDs are nonhumanoid barding shells and fit any creature's empty
  armor socket through that creature's authored body-guide adapter. The five Gem IDs
  fit any creature's empty collar/gem socket. M9 adds no species/element exclusion.
- Filament Ring targets the player printer as a public nonstacking battle effect and
  never occupies a creature socket.
- Equipment is paid and queued before a target decision. Completion produces an
  equip-ready holding record; target selection reads the current living field. If no
  compatible socket exists, holding persists. It cannot silently replace, refund,
  retarget, disappear, or attach to a rival.
- Mastery tier belongs to the equipment catalog ID. The completion/attachment receipt
  records the exact tier snapshot used so reload and later upgrades cannot alter an
  already constructed battle.

## Delivery slices

### M9A — input, receipt, and starter guarantee

One bounded runtime implementation may cover only `M9-BUG-01` through `M9-BUG-06`,
visible/system Back ownership, real coordinate-driven input, and Requirement 4's
Founder receipt/deck construction. It changes no battle values, XP, mods, or art.
M9A is complete when a fresh profile reaches an exact legal 40-card deck through
three visible 13-card receipts, every pack size is fully pageable, and every involved
route has visible/system Back parity.

### M9B — battle, rewards, mastery, and mods

After Sol reviews M9A, one bounded implementation may add the all-non-spell queue,
bot settlement values, XP migration/wallet/mastery, equipment compatibility, and
permanent mod tracks, including closure of `M9-BUG-07` with the serialized finite
print budget. It preserves Plan -> Run Cycle and uses catalog/profile/rule authority
rather than UI-computed values.

### M9C — printable asset completeness

Creature models and the 11 equipment card/blueprint/raw/model families are a separate
approved-asset batch. Start with one nonhumanoid animal-barding pilot; expand only
after that pilot clears review. No generated candidate is a runtime asset until
manifest, original-resolution review, human approval, catalog mapping, package
inclusion, and fallback evidence pass. M9A/M9B must use truthful unavailable states
rather than inventing or promoting placeholder printable art.

## End-to-end measurable acceptance

1. **Inventory:** A catalog-driven ledger enumerates exactly 57 unique IDs and the
   counts `24/11/4/6/4/8`. It rejects humans/mechs, duplicate IDs/art identities, and
   any missing required presentation mapping. A 35-row printable manifest proves
   creature/equipment blueprint/raw/full-volume-GLB completeness, fitting anchors,
   bounds, and hash identity after M9C gate. Package scans reject the retired humanoid
   armor and any sprite-plane substitute.
2. **Real input:** Interaction tests obtain each actual visible control's global rect,
   send pointer press/release at its center through `Input.parse_input_event`, and
   assert the resulting route/transaction. They do not call private handlers, direct
   callbacks, or `pressed.emit()` as proof that a control is usable. Keyboard focus
   activation and Android `go_back_requested` are separate real input fixtures.
3. **All-screen Back:** A route inventory fails if any rendered full-screen state,
   receipt, modal, confirmation, required decision, or error lacks exactly one visible
   >=48-pixel Back owner or visible locked Back reason. Visible and Android traces from
   identical serialized fixtures are byte-equivalent. Title Exit and live Concede
   require confirmations; pack Back preserves its pending receipt/caller.
4. **Fresh onboarding:** From empty storage, actual controls choose each of the three
   starter variants in independent fixtures, prove the initial one-card provisional
   deck/license and `founder_v1` marker, complete First Print once, then claim/Back/
   reload/Keep all three 13-card Founder receipts. Each successful claim atomically
   advances deck/ownership/pending/opened and produces count `14`, `27`, or `40`;
   its Keep preserves deck/ownership byte-for-byte, increments only kept, and clears
   pending. The flow finishes only at `opened == kept == 3` with the exact authored
   40-card owned/active/legal deck. Duplicate presses, fourth claim, interrupted saves,
   and automatic deck repair grant nothing extra. Complete and in-progress unmarked
   legacy profiles remain byte-equivalent and never receive the marker.
5. **Paid packs:** Actual Market controls buy Basic/Forge/Arcane/Primordial/Champion
   fixtures with exact displayed debit, then page through every committed card at five
   per page. Combined bonus, reload, Back/reopen, Keep, insufficient funds, pending
   reveal, exact 51 meter, and double-submit traces prove no hidden/rerolled/duplicate
   card. Every card's displayed normalized `cost`/`print_ticks` equals the source
   `filament_cost`/`print_turns`; creature cards read HP/Bend/element/ability rather
   than nonexistent `attack`, and known support cards show exact authoritative rules
   instead of generic copy.
6. **Queue:** Seeded duplicate battles play each of the five non-spell types and one
   spell through actual cards/targets. The spell is immediate; every non-spell appears
   in FIFO before effect. Print progress, cancellation reservation release, pause,
   completion, creature raw/awaken/walk, equipment holding/attachment, filament gain,
   trap replacement, Upgrade install, stale token, reload, and reduced-motion traces
   end in identical authoritative snapshots. A speed-greater-than-one fixture pauses
   on the first creature completion, accepts placement, and proves the same serialized
   cycle ID/remainder resumes; the later Print-phase advance performs zero additional
   work. Repeated resume/reload never exceeds the initial budget plus separately
   receipted authored bonus progress. A speed-batch fixture queues two duplicate
   Cinderpaws followed by equipment and proves three distinct stable job IDs plus
   ordered work/completion/destination events. Actual placement/equip-ready controls
   acknowledge the first batch, then expose every `_print_continue()` event without
   resubmitting authority. Interruption/reload at every event cursor and full/reduced-
   motion playback preserve the same event IDs/order, one revision per original intent,
   and no duplicate effect. Owner/rival projections retain identical event shape while
   a rival queued/set trap keeps its card identity, hand source, and deck source hidden.
7. **Automatic bot loop:** Starting from a legal deck, actual Begin/Plan/Run Cycle/
   required-decision controls reach a settled Result without any phase or manual
   Attack button. Both seats use the same checked rules. Privacy, revision increments,
   finite presentations, queue ordering, and one living sprite per deployed unit hold.
   A unified-authority matrix uses each fresh Founder starter, every M9 bot difficulty,
   both opening seats, and at least five fixed seeds per combination. Every non-Concede
   match finishes at printer zero within 30 complete rounds, median length is 12-22,
   and repeated runs reproduce winners/revisions. Reports include min/median/p95/max,
   intents, creature/printer hits, damage by target, opening seat, winner, and final HP.
   Direct printer hits apply exactly x10 normal damage only after all defenders clear;
   creature damage, HP 2000, Chassis +500, and no-fatigue behavior remain unchanged.
   Any stall/overrun blocks acceptance and returns traces for a separate decision; it
   does not authorize silent fatigue, overtime, base-HP, or other stat changes.
8. **Rewards:** One seeded victory adds exactly `100` coins and `50` to each XP ledger;
   one defeat/concede adds `40` and `25`. Duplicate result IDs, Continue, reload, and
   retry add zero. Existing Season/Spool/drop/quest outputs remain separately correct.
9. **XP migration/mastery:** Old-save fixtures at Spool levels 1, 2, 37, and 100 prove
   the reconstruction formula, idempotent marker, and byte preservation of old fields.
   Actual Upgrade confirmation proves each cost/cap and resulting integer creature,
   armor, gem, and Ring value; rejection and save failure change neither tier nor
   wallet. A live battle never changes after an out-of-battle upgrade.
10. **Printer mods:** Actual Market controls buy each track in order, reject skipped/
    duplicate/unaffordable tiers, and create new battles with exact speed, filament
    cap, FIFO cap, and Pre-Print count. Existing mod IDs migrate unchanged. In-battle
    Upgrade Cards remain queued and separate from permanent mods.
11. **Portrait/accessibility:** Required states pass at `576x1024`, `720x1280`, and one
    tall Android fixture at 100% and representative 150% text, high contrast, reduced
    motion, keyboard/controller focus, safe-area resize, and production bottom reserve
    zero. No control/receipt card is clipped, obscured, or unreachable.
12. **Visual/package gate:** New M9C assets have exact dimensions/bounds/hash manifests,
    read-only UI review P0 none/P1 none, human approval, catalog-resolution tests, and
    package presence. Existing approved atlas/creature blueprint hashes remain
    unchanged. No M9 acceptance claim implies Android export/device/Drive sync unless
    those are separately evidenced by the owning delivery milestone.

## Completion boundary

M9 is complete only when M9A, M9B, and M9C each have reviewed diffs/evidence; the
end-to-end fresh-profile path succeeds using actual controls; all seven baseline bugs
are closed; all eight feature contracts pass deterministic acceptance; the new
printable family clears its visual gate; and full regression preserves the approved
portrait physical UI, automatic Plan -> Run Cycle combat, save atomicity, and native-
bottom zero-reserve boundary. This checkpoint authorizes implementation planning; it
does not itself claim runtime, Android, build, device, or Drive completion.
