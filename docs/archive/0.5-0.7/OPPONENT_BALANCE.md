# Opponent Contract Balance (archived 0.5–0.7)

> Historical active-unit balance notes. v3 AI and encounters use the canonical
> queue-based battle snapshot instead.

Daily Training freezes the first time the Proving Door opens for a calendar day. The snapshot records the day, player team size and rating, progression band, rival teams, decks, loadouts, rewards, claims, and selected policy. Later team changes never reroll it.

| Contract | AI | Target rating | First victory |
| --- | --- | --- | --- |
| Apprentice Spar | Apprentice | 92% | 15 Forge Coins, 20 XP |
| Element Circuit | Craftsman | 100% | 20 Forge Coins, 30 XP |
| Masterwork Challenge | Master | 108% | 30 Forge Coins, 40 XP |

`OpponentRules.BAND_POLICIES` is the single data table for every contract/band combination. Each row declares suit tier, Core coverage, element-counter cadence, rating edge, offense preference, deck override, rival spool cap, prepared starting filament, and (where used) opening order or a named tactics cadence. The exact matrix is intentionally visible in source so designers can change a policy without adding hidden generation conditionals. Prepared filament is written to the frozen contract and shown before launch; it is a visible setup resource, not an unlisted stat modifier. The daily builder never repeats an identical creature-ID lineup when another policy-legal squad exists; three-unit contracts prefer at most one shared print where a comparable policy-legal alternative exists.

- Apprentice: B1 has a lowest-legal-rating allowance and at most one counter; B2 uses one counter every fourth day; B3-B4 allow at most one counter; B5 uses one counter daily and a Masterwork-to-Legendary fallback only when the latter is rating eligible.
- Circuit: B1 neutral/lower; B2 at most one counter; B3 at most one/lower; B4-B5 at least one counter and upper-edge equipment.
- Masterwork: pressure-oriented progression, with B4 upper-edge Masterwork, matching Cores, and at least one counter. B5 names the visible Overdrive tactics cadence: the Master may spend one useful setup card during the battle before returning to normal Master evaluation.

The snapshot is honest about matching. `within_target` means the selected rival is within five percent of the displayed integer target. `rating_fallback` is `closest_legal` otherwise. `equipment_reason` states whether the primary equipment policy or an explicitly allowed fallback supplied the team.

The explainable rating is `HP + 3*Attack + 2*Speed + suit HP + 8*guard + 2*suit Speed + 2*signature damage + signature effect units + Core value + floor(deck utility / 3)`. Deck utility is the ordered effect total plus card cost. Candidate changes must preserve fixed integer combat rules; tune team choice, deck templates, equipment, or deterministic AI policy before changing base combat values.

`test_opponent_balance_audit` runs 600 deterministic representative matches: five bands, four player archetypes, five daily seeds, three contracts, and paired openings. It requires legal intents, termination in at most 160 intents, no stalls, contract aggregate targets, per-band rates within 15 points, and opening delta at most eight points. Turns one and two form a symmetric setup round: either side may play cards, Defend, or End Turn, but attacks and signature abilities unlock only after both prints have acted. A Defend on the second setup action visibly grants an 8-shield reply guard (ordinary Defend is 4), compensating the first combat initiative without altering creature stats. `AIOpponent.choose_intent_for` is the pure mirrored simulation seam; Apprentice is a deterministic signature-first policy, Craftsman scores legal options, and Master adds its lookahead weighting.

## Recorded deterministic audit

The final paired-opening audit (600 matches) reported player win rates of **68%**
for Apprentice Spar, **59%** for Element Circuit, and **44%** for Masterwork
Challenge. The paired opening totals were 174/300 and 168/300, a **2-point**
delta; all contracts terminated legally within 160 intents with **zero stalls**.

| Progression band | Apprentice target 70% | Circuit target 55% | Masterwork target 40% |
| --- | ---: | ---: | ---: |
| B1 | 55% | 42% | 55% |
| B2 | 67% | 62% | 37% |
| B3 | 60% | 67% | 37% |
| B4 | 75% | 70% | 40% |
| B5 | 82% | 52% | 50% |

Every band is within the published 15-point contract tolerance. The audit uses
the same shuffle seed for both openings in each pair; only `active_player` and
`opening_player` differ, so the opening result is not confounded by a different
deck order.
