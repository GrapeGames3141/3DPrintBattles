# Bestiary: where new creatures come from

Most of the first 170 prints are recolours of about 25 painted bodies. From now
on a new creature should be its own design: a body, a mechanic and a story that
belong together, borrowing the best ideas of Yu-Gi-Oh! (YGO), Pokémon (PKMN),
Digimon (DIGI) and Magic: The Gathering (MtG), always told through 3D printing.

New creatures are modelled and posed in `tools/render_art6.gd`: each is built
from printed parts on joints and rendered in all eight poses (stand, crouch,
stride, proud, wind-up, strike, low, hurt), so it really animates on the bench.

## Built

| Line | Stages | Idea | From |
|---|---|---|---|
| **Nozzlet → Extrudrake → Infernozzle** (Fire) | 1/3, then 3/5 Scorch after 2 turns, then 6/7 Scorch Hover after 3 more | A salamander whose head is a hot end. It grows heat-sink fins and horns, then fan-blade wings and a crown of nozzles. At the top it breathes 2 on the enemy Printer every turn. | PKMN starter lines, DIGI digivolution |
| **Bytelet → Voxelion → Teravox** (Arcane) | 0/2 that draws a card, then 3/4 Menace, then 5/6 Hover Ward that draws when it attacks | A program that printed itself: a floating cube with a pixel face, then a voxel lion with a cube mane, then a winged voxel king. | DIGI (In-Training to Champion), PKMN |

Evolution rules (`evolve` on a card): the stage changes at the start of its
owner's turn once it has stood on the bench that many turns. It keeps its damage,
the Attack and Health it gained, and any keyword it was given. Later stages are
never in packs.

## Next, in the order I would build them

| Idea | What it is | From |
|---|---|---|
| **The Forbidden Printer** | Five Legendary parts: Left Rail, Right Rail, Hot End, Frame and Mainboard. Hold all five in your hand and you win. Each part is weak on its own. | YGO Exodia |
| **Swarmlings** | A tribe of small printed bugs. Each gives every Swarmling you control its keyword (one has Rush, one Guard, one Twin). | MtG Slivers |
| **Fusion Nozzle** | A tool: scrap two prints of the same element and print their fusion. Spool Snail plus Cube Crab becomes Shellforge, for example. | YGO Fusion, DIGI DNA digivolve |
| **Dual-filament prints** | Two-element creatures printed in two colours that count as both elements (Fire and Water is Steamwyrm). | MtG gold cards, PKMN dual types |
| **Mega Print** | One per battle, a Printer Power can push an evolved print to a Mega stage for the rest of the battle. | PKMN Mega Evolution, DIGI Mega |
| **Failed prints** | Spaghetti and stringing monsters that get stronger when your own prints are destroyed. | MtG graveyard decks |
| **Tribute giants** | 0 Filament, but you scrap one or two of your prints to print them. | YGO tribute summons |
| **Regional forms** | The same creature printed in another element's filament, with a different ability (an Ice Nozzlet line). | PKMN regional forms |
| **Calibration Cube** | A token that copies the stats of whatever it touches first. | PKMN Ditto, MtG Clone |
| **Benchy, the Unsinkable** | A Legendary that cannot be destroyed while you control another Water print. | MtG indestructible, YGO protection |

Each one needs a model in `render_art6.gd`, a card in
`tools/catalog/creatures.py` and, where it is new, a rule in
`BattleEngine` with a test in `tests/test_rules.gd`.
