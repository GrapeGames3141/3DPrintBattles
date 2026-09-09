# Original Reboot vs current PrintForge — gameplay audit

Date: 2026-09-08
Status: **READ-ONLY AUDIT / NEW HYBRID NOT APPROVED**
Source PDF: `docs/reference/reboot-original-20260908/3D-Print-Battles-original.pdf`

This document compares the 25-page Drive/Reboot PDF with the current branch. It
does not change the approved M11 presentation work, current deterministic rules,
saves, catalog, portrait layout, ad/platform contract, or visual gate. The preferred
battle contract below is a major redesign proposal and requires explicit user
approval before runtime implementation.

## Source reliability and conflicts

The PDF is useful direction, not a single internally consistent specification.

- Physical pages 1–8 mix user prompts with earlier AI summaries; the section labeled
  `Claude Plan` begins on page 8. The `Code` blocks on pages 12 and 14–16 are literal
  missing-content placeholders, not rules or executable authority.
- The raw request rejects classroom-style math and stat homework (pp. 5 and 7),
  while the expanded Academy section returns to overt educational exercises
  (pp. 23–24). Preserve simple readable numbers; do not add lessons without a new
  product decision.
- One active creature plus two bench creatures appears on pp. 8 and 14, while
  earlier passages imply a less bounded collection/battlefield. The bounded roster
  is the clearer mobile game, but it is not current authority.
- The PDF says Steam-first (p. 8). The current product direction is portrait mobile;
  this audit does not reopen platform or layout scope.
- The file ends at physical page 25 although its contents promise later material.
  Missing sections cannot be treated as approved rules.

## What each version gets right

| Area | Best of the original PDF | Best of the current game | Audit recommendation |
|---|---|---|---|
| Product fantasy | A learned blueprint becomes a permanent license; the player pays coins to make a collectible living toy (pp. 3–5, 8, 14). | Card copies, permanent blueprint licenses, and Workshop model receipts are already separate, durable facts (`scripts/core/unified_rules.gd:81-111`; `docs/design/printforge-legends-mechanics-v3.1.md:34-39`). | Keep the current save boundaries and Workshop transactions. Make a **printed companion** the battle-team member rather than using a pile of creature-card copies. |
| Battle readability | One active creature, two reserves, four-card hand, and a 15-card support deck are legible on a phone (pp. 8, 14–16). | Visible FIFO printing, animated print-to-life deployment, deterministic intent checking, equipment fitting, and public/private state are working foundations (`scripts/battle/unified_battle_rules.gd:33-71,261-324`; `scripts/battle/unified_battle_state.gd:57-71`). | Prototype a three-print roster plus small support deck while retaining the current printer sequence and authority. Do not pretend the roster alone proves good pacing. |
| Collection breadth | Eight elements, eight rarities, rotating offers, discovery states, and permanent armor/model collecting provide long-term goals (pp. 12–14, 19–23). | The current catalog already has 57 cards: 24 creatures, 11 equipment, 6 spells, 4 filament, 4 traps, and 8 upgrades across all eight rarity tiers (`data/v3/catalog.json`; rarity order at `scripts/core/unified_rules.gd:19`). The market already rotates blueprints, cards, packs, upgrades, cosmetics, and a daily deal (`scripts/core/unified_rules.gd:305-336`). | Keep the current catalog/economy. Restore `glimpsed / known / owned / printed` as a **second-stage** collection feature in the existing folio; current v3 persists only owned cards, licenses, and models (`scripts/core/v3_profile_state.gd:7-22`). |
| Combat depth | Creature identity and elemental matchups matter without manual phase bookkeeping (pp. 5, 12–16). | Current deterministic damage uses Bend, armor, gems, attack abilities, and 150%/60% element relationships, with Arcane neutral (`scripts/battle/unified_battle_rules.gd:8,176-207,325-360,406`). | Keep deterministic integer authority and automatic abilities as foundations. Do not promise every current value/support rule: the new command and resource economy needs an explicit balance table. |
| Progression | The Workshop and market make new blueprints/prints feel like owned objects (pp. 19–23). | Battle settlements are receipt-protected and award current XP/drop progression once (`scripts/core/unified_rules.gd:628-638`); packs and the starter path already produce a legal collection (`scripts/core/unified_rules.gd:13-16,68-80,509-538`). | Preserve exactly-once progression and all inventory. Do not consume, damage, or delete a permanent print because it falls in battle. |

## Precise current gap

The current battle is a 40-card-minimum card game: the authored starter contains 12
copies of the selected starter, eight Mossmunk, and 20 support cards
(`scripts/core/unified_rules.gd:157-163`); validation has no maximum or copy cap beyond
ownership (`scripts/core/unified_rules.gd:224-230`). Battle creates three field slots,
an eight-card hand ceiling, a FIFO print queue, staging, holding, and printer HP
(`scripts/battle/unified_battle_state.gd:23-57`; `scripts/battle/unified_battle_rules.gd:231-243`).
Creatures can return through Emergency Reprint and Blueprint Thief
(`scripts/battle/unified_battle_rules.gd:83-115`). Printed Workshop models are proof of
a completed collection print, but do not gate battle eligibility.

That implementation is deeper than the PDF's most readable loop and is visually at
odds with “prints come alive and fight”: a large creature-copy deck makes the living
creatures feel like expendable cards. It is also not meeting the current pacing target.
The corrected 30-case evidence is 41/64/98/100 rounds min/median/p95/max, 0/30 at or
below 30; first legal printer contact is median round 48
(`build/evidence/m11-a-20260908/pacing-r4/qa-save/m11-pacing-results.json`, summarized
in `docs/design/m11-pacing-followup-v1.md:16-37`). Lower printer HP cannot repair games
that do not expose the printer.

## Preferred NEW hybrid: three living prints, not a creature-copy deck

This is the one recommended direction to test. It borrows the original's readable
roster while retaining the current game's strongest systems. It **replaces** the
current 200-HP printer-race win rule for this prototype; it is not an interpretation of
the PDF and it is not approved by the existing M11 checkpoint.

### H1 — roster and support loadout

- **Entry:** After the free starter print, one-versus-one lesson, and three Founder
  rewards, a new profile receives the separately specified, receipt-protected common-
  companion and first-print voucher guarantees. An existing profile opens a reversible
  prototype-loadout preview; its current 40+ deck remains intact.
- **Player decision:** Choose and order exactly three eligible **printed companion**
  instances and exactly 15 compatible owned support cards; choose reserve priority and
  any re-authored Pre-Print assignment; then Apply or Cancel the preview.
- **Result:** The team is made of collection prints, not creature-card copies. New
  guarantees make the first legal team deterministic rather than luck-dependent.
  Existing users keep every card/license/model and receive no inferred or replayed
  entitlement; the preview uses their actual compatible collection.
- **Failure:** Missing printed companions, fewer than 15 compatible supports, unknown
  IDs, stale ownership, incompatible Pre-Prints, or commit failure leaves team, deck,
  receipts, ownership, models, progression, and active mode unchanged.
- **Disabled:** Apply remains disabled until all three printed companions and 15 legal
  supports are present. Incompatible cards are filtered with a named reason, never
  deleted or silently rewritten.
- **Feedback:** Show `Team 3 / 3`, `Support 15 / 15`, print eligibility, reserve order,
  excluded-card reasons, entitlement/voucher receipts, and a complete before/after
  preview.
- **Progression:** The proposed common companions/vouchers are a **NEW**, idempotent
  first-session guarantee that needs explicit content/economy approval. Preview and
  Cancel grant nothing; no battle consumes a permanent collection print.

The earlier license-only roster idea is retained only as a lower-disruption
alternative and is **NOT SELECTED** by the primary proposal. It avoids new starter
entitlements, but does not make the Workshop print itself the creature the player
cares about.

### H2 — visible one-active battle loop

- **Entry:** Both checked loadouts and one deterministic seed create a battle with
  three unspent roster identities, one active anchor, two reserve racks, one printer,
  and a four-card support hand per side.
- **Player decision:** During the automatic Plan boundary, choose an unspent roster
  companion to queue; choose reserve priority and at most one legal tactical support
  or swap command; choose a post-print equipment recipient; inspect the forecast; or
  Run Cycle. There are no manual phase buttons or per-attacker target chores.
- **Result:** A selected printed companion's match incarnation can enter the printer
  once per match. It progresses
  through the existing blueprint, layers, raw print, awakening, and step-off sequence.
  The first completed creature becomes active; later completions occupy the two
  reserves. When the active creature falls, the highest-priority ready reserve steps
  in at the approved visible replacement boundary; exact swap timing still needs to
  be locked. If no completed creature is available,
  the next roster print continues and opposing creatures visibly hold at the printer
  boundary because there is no legal creature target; they do not damage a hidden HP
  pool or secretly alter print progress.
  Equipment still prints, then asks once for a compatible active/reserve creature and
  remains held if none is legal. Deterministic integer authority, elements, armor,
  equipment, and automatic abilities remain foundations, but exact command costs,
  replenishment, healing, swap timing, and support values require a new balance table.
- **Failure:** Invalid queue choice, insufficient filament, full queue, interrupted
  completion, dead/stale equipment target, authority revision mismatch, or safety
  rejection changes nothing beyond an already accepted atomic intent. Print Interrupt
  and other queue denial require an explicit compatible rule; no silent extra life,
  loss, refund, or retry is assumed by this audit.
- **Disabled:** A spent roster identity cannot be queued again. Support cards cannot
  create a fourth creature in the initial prototype. Illegal targets, full equipment
  sockets, and actions outside the Plan boundary stay disabled with the authority
  reason.
- **Feedback:** Show each roster member as Blueprint, Printing, Reserve, Active, or
  Defeated; show public queue identity/progress, printer motion, awakening, reserve-to-
  field movement, legal equipment sockets, and the expected next-cycle order. Living
  battlefield entities use animated creature sprites, never upright card faces.
- **Progression:** Roster and support state reset after the match. Defeat never erases
  or damages a card, blueprint license, Workshop model, equipment item, or saved
  loadout. Only the existing checked Result settlement may mutate durable progression.

### H3 — one explicit terminal rule

- **Entry:** Resolve a checked attack/support/print action completely, including its
  ordered triggered effects, then evaluate each roster.
- **Player decision:** None at resolution; before committing a cycle, the forecast
  identifies any final roster member at risk.
- **Result:** A player loses when all three of their once-per-match roster members are
  defeated. Their printer visibly jams as the defeat result, but numeric
  printer HP is not a second win system in this prototype. If both final roster
  members fall in the same fully resolved action, the result is a draw. Support supply
  is finite with no indefinite reshuffle or unlimited resurrection, and surviving
  roster members must have an eventual legal queue/deployment path.
- **Failure:** The match may not settle before the accepted action and all triggered
  effects finish. Duplicate Result, reload, late animation, or simultaneous terminal
  signals cannot award twice or change the recorded outcome. A seeded case that can
  loop through healing, recovery, queue denial, harmless Guard, or empty hands fails
  prototype acceptance; it is not masked by a timer.
- **Disabled:** All battle input is disabled after Win/Loss/Draw authority exists;
  presentation may finish or Skip to the same Result. No timeout win/draw, damage
  multiplier, hidden fatigue, sudden HP loss, or off-screen tiebreak is selected.
- **Feedback:** The third defeat visibly travels back to the printer, the printer jams,
  and Result names `Roster exhausted`. A simultaneous final fall shows both outcomes
  before Draw. The proposed median 12–22 / maximum 30 rounds is an acceptance target,
  not an authority timer.
- **Progression:** Win/Loss/Draw must settle exactly once. Draw schema, rewards,
  streak, and drop behavior require explicit approval: current settlement accepts a
  victory boolean (`scripts/core/unified_rules.gd:628-638`) and current snapshots allow
  only seat 0/1 or unfinished (`scripts/battle/unified_battle_state.gd:71-79`). No
  implementation may silently record Draw as a loss or reuse unfinished authority.

A hard round-30 Draw is a possible anti-stall alternative but is **NOT SELECTED**. It
would need separate approval and could hide an unfun or nonterminating rules loop.
Before promotion, deterministic comparisons must report Win/Loss/Draw, first print,
first contact, creature contacts, support usage, deployability, and median/p95/max
rounds. Any softlock or high draw rate fails review.

## Migration and first-session risks

1. **New save shape:** printed-team/support/preprint mapping and Draw need versioned,
   reversible state. Existing decks, active slot, receipts, ownership, licenses,
   models, progression, RNG, and battle snapshots cannot be overwritten by a preview.
2. **Pre-Print meaning changes:** current Pre-Prints consume creature copies from the
   active deck and deploy into three slots (`scripts/core/unified_rules.gd:244-250`).
   Mapping them to roster members is part of the proposed bundle and needs explicit
   approval.
3. **Three live card effects conflict with the cap:** Emergency Reprint spell/upgrade
   and Blueprint Thief currently enqueue extra creatures. They require explicit
   prototype exclusion or re-authoring approval; ownership stays intact either way.
4. **Printer upgrades:** Reinforced Chassis and printer repair/damage effects have no
   authority value under roster-exhaustion victory. Preserve ownership but mark them
   incompatible in the prototype until a separate rework is approved; do not convert
   their value silently.
5. **Resource/support compatibility:** current numbers, healing, recovery, resource
   denial, queue denial, Guard, swaps, and equipment cannot be carried over by
   implication. Finite support and eventual deployment need an explicit table and
   deterministic termination evidence.
6. **First session:** the selected proposal requires named common-companion and print-
   voucher guarantees after the free starter print/lesson and Founder rewards. Their
   identities, quantities, receipts, and existing-player boundary must be approved;
   no fake battle, forced purchase, or luck gate is permitted.
7. **Bot policy:** the current bot selects upgrades, filament, creatures, equipment,
   and traps but no spell branch (`scripts/battle/unified_ai_opponent.gd:122-144`). A
   prototype comparison therefore needs a checked roster/support policy; current slow
   bot-v-bot evidence cannot be relabeled as the proposed loop's measured outcome.

## Recommendation and fallback

Ask for one explicit approval decision on the primary proposal's bounded prototype:
three **printed companions**, one active plus two reserves, once-per-match match
incarnations, a 15-support/four-hand loadout, automatic combat, roster-exhaustion
victory, simultaneous-final-KO Draw, and deterministic first-session companion/print-
voucher guarantees. Exact command/resource values and incompatible-card re-authoring
must be locked before implementation. This restores the original's “small team of
living prints” while keeping the current animated printing and deterministic base.

Until that approval exists, the fallback is the current three-slot, 40+-card,
200-printer-HP rules with the already approved M11 presentation work only. Do not mix
individual roster rules into that baseline, claim the one-active layout solves pacing,
or treat this audit as implementation authority.
