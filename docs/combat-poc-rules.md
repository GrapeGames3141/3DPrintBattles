# Combat POC rules lock — 0.3.5

This is the implementation contract for the first Windows combat proof of concept.

## Round flow

1. Both printers gain 2 filament, capped at 10 (round one starts at 6).
2. Each faction may spawn one affordable reserve unit into its printer deployment zone or skip.
3. All living units enter one Initiative queue; ties favor the round's first faction, which alternates each round.
4. Each unit moves once and takes one attack, ability, or Wait action.
5. Cooldowns, regeneration, and temporary effects tick on that unit's own activation.

## Terrain and objectives

- Grid: 25×33, orthogonal movement, Manhattan ranges.
- Grass, road, hills, and bridge cost 1 movement.
- The two-cell shallow river costs 3 movement.
- Trees and boulders are impassable and block line of sight.
- Printers occupy 2×2 cells, have 50 HP and 8 DEF, and are valid enemy attack targets.
- A faction loses when its printer reaches 0 HP or it has no living units and no reserve units.

## Combat formulas

- Basic damage: `max(1, effective Offense - floor(effective Defense / 2))`.
- Healers use that same normal damage formula.
- Healing: `2 × effective Offense`, capped at the target's effective maximum HP.
- Range 0 is implemented as adjacency range 1.

## Support identities

- **Bloodlust Pulse (Goblin):** caster and adjacent allies gain +3 OFF and +2 MOV through their next activations.
- **Forest Shield (Elf):** caster and adjacent allies gain +6 temporary HP and +3 DEF through their next activations.

## Art handoff

`assets/concepts/combat/` contains ten unit turnarounds, two printer turnarounds, one three-panel battlefield concept, and one isolated 3×3 environment generation kit.

`assets/concepts/combat/four-view-v2/` contains separate `front.png`, `back.png`, `left.png`, and `right.png` files for all ten units and both printers. Character references use a relaxed A-pose with props held outside the body silhouette and no crossed-body equipment. The corrected Hobgoblin has one cleaver only and an empty off-hand.

The supplied Moonlit Elf Duelist is assigned to Moonshadow Rogue. Its nine embedded clips include idle, movement, dodge, two attacks, death, and alternate walk animations.

The supplied Verdant Alchemist is assigned to Bogbrew Stitchdoc. Its six embedded clips include casual walk, running, walking, spell cast, thrust/slash, and death. Healing uses the spell-cast clip; basic attacks use thrust/slash.
