# PrintForge Legends mechanics v3.1

This is the implementation authority for the v3 replacement. Catalog data is
the source for card costs, print times, market prices, rewards, and effects.
The earlier 0.7 three-phase/15-card rules are retired for the unified modes.

## Locked match rules

- A printer begins at 2,000 HP; reducing it to zero is the only loss condition.
- Players begin with 200 filament and a 400 maximum. Workshop Spool Capacity I
  and II raise that maximum to 500 and 700; filament never regenerates by turn.
- The five phases are Draw, Main, Print, Attack, and Collect. The starting
  player draws zero and cannot attack on its first turn; the other player draws
  two. Empty decks are not a loss. The hand limit is eight after Collect.
- Decks have a 40-card minimum, no maximum, and may contain only copies owned.
- The FIFO print queue starts at three items. Only its head advances. Base speed
  is one; Speed Spool adds one and Turbo Spool adds two. Unused speed carries to
  the next item. Dual Queue adds two capacity per installation.
- Finished creatures ask for an open field slot and attack/defense mode; a full
  field sends them to staging. Creature equipment holds until it can use an
  open armor or gem slot. A creature has one of each slot. Filament Ring is a
  separate public player battle effect, never an equipment slot.
- Pre-prints consume matching active-deck copies, deploy in Defense Mode, and
  cannot act or switch mode on their owner's first turn.
- Attack damage is `max(1, floor((ceil(Bend/4)+gem bonus) × element ×
  modifiers))`. Arcane is neutral. Armor HP absorbs damage before base HP.
- Scrap is based on combined creature/equipment cost. Base recovery is
  25/30/35/40/50 percent for Common through Legendary+; Spooler is +10 points
  per installed card, capped at 80 percent. Smelter multiplies recovered
  filament by 110 percent, capped at original cost.

## Data boundaries

`owned_cards`, `owned_blueprints`, and `printed_models` are separate. Cards do
not grant a Workshop blueprint or model. SaveService writes only the clean
`printforge_v3_*` namespace and does not migrate the 0.7 profile.

All randomness is seeded from profile RNG state or an injected entropy payload;
pending pack grants are committed before their reveal. Local authority exposes
redacted opponent snapshots, hiding hand, deck, and trap identity.

## Current implementation scope

The authoritative Godot layer implements five phases, queues, staging/holding,
modes, deterministic combat, equipment, traps, upgrades, pre-print consumption,
40-card validation, starter deck ownership, five catalog-driven Market shops,
Daily Deals, wishlists, newcomer claims, packs/pity, quests, drops, Season
claims, and the v3 save namespace. The TypeScript boundary validates matching
explicit intent shapes, including installed Emergency Reprint charges, and
revision/seat handling.

The fake local Spark storefront is an offline seam only. Steam purchase
validation, hosted authority, cloud time/entropy, matchmaking, telemetry, and
server-side economy remain external deployment dependencies; they must not
silently fall back to the retired 0.7 economy.

## Equipment normalization

- Armor is exactly five complete, recolorable suit cards in the single armor
  slot: Standard (+8 armor HP, Common), Reinforced (+14, Uncommon), Arcane
  (+20, Rare), Masterwork (+28, Epic), and Legendary Full Suit (+36,
  Legendary). They use the existing full-suit tier palette/master and measured
  socket renderer; modular Helm, Chest Plate, and Leg Guards are retired.
- Arcane Full Suit keeps the authored deterministic ward: super-effective
  incoming damage uses 120% rather than 150%. No suit grants legacy speed,
  guard, or Core battle behavior.
- Gems replace weapons in the one gem slot and use the same shared socket
  recolor presentation: Iron Gem (+5); Ember Gem (+4 and two owner-Draw burn);
  Frost Gem (+4 and next mode-change lock); Storm Gem (+3 and first damaging
  hit locks the next Attack Phase); Arcane Gem (+5 and bypasses armor HP).
- Filament Ring is the only remaining non-creature equipment. It resolves
  immediately when played, costs its listed filament, goes to the graveyard,
  and sets a public, non-stacking player battle effect for the remainder of the
  match. It grants 20 filament each Collect subject to capacity, never prints,
  holds, attaches, or is destroyed with a creature. A second Ring is rejected
  while active. Tidal Core and Arcane Sigil are retired active v3 cards.

## Economy and lifecycle details

- Blueprint Stall gates are Common 1–5, Uncommon 6–10, Rare 11–20, Epic
  21–35, Legendary 36–50, Mythic 51–70, Prismatic 71–90, and Primordial
  91–100, with a deterministic 0.2% Primordial injection.
- The Card Shop uses 40/28/18/9/4/1 Common through Mythic+ weighting.
  Market epochs are persisted and never move backward when a local clock rolls
  back. The Newcomer Shelf explicitly presents three half-price Common
  blueprints, its free Basic pack, discounted Speed Spool, and Forge Boost
  introductory Spark price.
- Match drops use 300/500/700/1,000/1,200 bp win chances, +5 bp per ten
  lifetime wins capped at +200, 50 bp loss consolation, and a 41st-win drop.
- Spool Level is a 1–100 collection gate, not battle filament capacity. It uses
  the `level × 100` XP curve. Battle, quest, and qualifying Academy XP feed
  both Spool and Season progress. Battle filament remains 400/500/700.
- Seasons begin on first local use, last 90 days, and reject expired claims.
