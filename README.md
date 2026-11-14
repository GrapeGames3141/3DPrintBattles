# 3D Print Arena

A card battler where you fight with 3D-printed creatures. Your Printer is your
hero and Filament is what everything costs, but it works like a real printer:
one Spool for the whole battle, a few Filament a turn off it, and big prints
that sit on the bed for several turns while your opponent watches them grow.

Built with Godot 4.7.1 (GDScript, Forward+). No accounts, no chat, no network
services: everything runs locally, and two-player games connect directly.

## Play

Open `project.godot` in Godot 4.7.1 and press Play, or run:

```
godot --path .
```

On first launch you pick a starter print (Cinderpaw, Aquafin or Voltwig). That
gives you its Printer, a 20-card starter deck (decks can grow to 60), 150 Forge Coins and three packs,
and drops you into a guided tutorial battle.

The game plays in landscape or portrait and re-lays itself out live when the
window or phone turns. The main menu is the painted workshop itself: tap the
arena to battle, the printer for the Workshop, the monitor for your collection,
the card stack for packs and the shelf of figures and armour for Blueprints.

## The game

| | |
|---|---|
| **Battles** | 20-Health Printers, decks of 20 to 60 cards. Play prints, tools and upgrades; attack with prints; destroy the enemy Printer. A hand below 3 cards is topped up each turn. |
| **Filament** | A Spool of 40 for the whole battle. The Printer lays down 3 a turn. A card that costs more goes on the Printer as a long print: it takes what is left of this turn, the rest on your next turns, and is deployed for free when finished. Both players can see it. A shattered print puts 1 Filament back on its owner's Spool. |
| **Prints** | 172 creatures across 8 elements, every element in every rarity, with Guard, Rush, Brim, Siphon, Twin Nozzle, Scorch and Filament Thief keywords plus On Print and Shatter effects. **Heat** (a Heated print takes 1 damage each turn) and **theft** (a thief takes Attack and Health from a print, doubled against a Heated one, and wears its victim's colours) are the newest mechanics. |
| **Tools** | 67 one-shot cards, each a real 3D-printing tool: Heat Gun, Calipers, Soldering Station, Kiln, Plasma Cutter, Print Farm, Master Slicer and so on. |
| **Equipment** | 43 pieces of printed equipment (helms, wings, a jet pack, a crown, Spiked Gauntlets, Omega Core) that bolt onto a print for the rest of the battle; some grant Scorch or Filament Thief. |
| **Printers** | 12 heroes, each with its own Power (Filament cost, once a turn). Prints that share their Printer's element get +1 Health. Bought with coins once your Maker Rank is high enough. |
| **Card packs** | Blueprint Pack (150 coins) and Golden Spool Pack (400): foil pouches you rip open with a swipe, then flick through the cards one at a time. Spare copies pay a little and are kept for Blueprints. Any card can also be printed directly for coins. |
| **Maker Rank** | Battles give XP (rank 1 to 30). Rank gates the Printers, Printer mods, Blueprint tiers, card mods and paints you can buy, and winning pays little, so there is a lot to play for. |
| **Printer mods** | 41 mods. Each copy you buy fits one Printer at a time (move it whenever you like; you can buy one copy per Printer you own), a Printer carries one copy of each mod, and every copy can be upgraded with coins and Maker Rank: level L to L+1 costs the mod's price times L and asks for 3 more ranks per level (Stepper Motors reaches +4 Filament a turn at level 4; all-or-nothing mods have one level). Each Printer shows a Tune number from its mods, and ranked opponents are built to the same Tune. Mods include (Stepper Motors for more Filament a turn, Bigger Spool, Failsafe, Plating, Quantum Slicer and more; build-reward mods such as Guard Frame, Spring-Loaded Bed and Twin Gantry make Guard, Rush and Twin Nozzle prints stronger). Some mods need others: Dual Extruder needs Stepper Motors, Direct Drive needs Dual Extruder and a Hot End; a mod only works while its parents are fitted, and taking a parent off takes its dependants too. Every mod has a rarity and a modelled part that shows on the machine, in the Workshop and on the battlefield; epic and legendary mods make it glow. A Mod Crate (Workshop) and a 12% chance after a win hand out a random mod, picked by rarity. |
| **Blueprints** | Every card you own can go Mk I, II, III (coins, a spare copy and rank), carry a mod from Mk II and a second one at Mk III (56 to choose from; each gives something and takes something) and be painted. Every copy you print has it, in every mode including PvP. |
| **Arenas** | Six themed benches (workshop, maker lab, print farm, hobby shop, neon night shift, forge), each with its own look and props, in landscape and portrait. |
| **Handbook** | A player handbook (from the `?` popup and the in-battle Menu) explaining turns, Filament, every keyword, Heat, Jam, Armor, card types, elements, rarity and Blueprints. |
| **Deck identity** | Every deck gets an automatic name from its cards ("Fire Rush", "Stone Wall", "Mixed Swarm", "Water Heavy"...), a cost-curve chart and a card sleeve you pick (more unlock with Maker Rank). Names, pictures and sleeves are all fixed choices, never typed text. |
| **Tutorial** | A guided first battle with on-screen tips that follow what you do. Replay it from the Battle menu or How to Play. |
| **Vs computer** | A 10-rival campaign with first-win pack rewards, and Quick Battle at Apprentice, Craftsman or Master. |
| **Profile & ranked** | Tap the coin pill on the menu (or Ranked on the Battle screen). Your profile has an anonymous player id, a name built from two fixed word lists and a number, a picture (one of your prints), earned titles, a Maker Rating with leagues (Spool to Print Master), your record and recent games. Ranked finds an opponent near your rating, shows who it is and what you stand to win or lose, and plays your active deck. There is no typed text. Until an online server is deployed the opponents are built-to-measure computer players; the rating and matchmaking code is the same that a server will run (`backend/src/rating.ts`). |\n| **Vs a friend** | Pass & Play on one screen, or Host / Join over the local network (port 24842; over the internet the host must forward that port). In a network game each player sees the other's name, league and picture; they travel as numbers and the name is built from the receiving side's own word lists, so no text ever crosses the wire. |

The arena is a workbench: your Printer stands in the near corner and builds
each print layer by layer before it hops onto your lane; the enemy's Printer
faces it from the far corner.

Controls: drag a card onto your lane (or your Printer) to play it, or tap the
card and then tap the lane. Tap a finished long print on your Printer to send
it out. Drag a print onto a target to attack, or tap it and then tap the
target. Tap any print on the bench to read its card. Right-click or Esc
cancels. Space ends your turn. F11 toggles fullscreen.

## Layout

```
scripts/core/game_data.gd       every card, printer, upgrade, pack and rival (the catalog)
scripts/core/battle_engine.gd   deterministic integer rules; state is a plain Dictionary
scripts/core/battle_ai.gd       computer opponent (three levels)
scripts/core/battle_session.gd  one battle: vs AI, pass-and-play, or network host/guest
scripts/core/profile.gd         local save: coins, cards, decks, printers, progress
scripts/net/net_link.gd         direct-connect networking (host runs the rules)
scripts/ui/                     screens and widgets, laid out on a 1280x720 or 720x1280 stage
scripts/ui/arena_layout.gd      battlefield positions shared by the game and the arena render
assets/                         creature sheets, raw prints, armor, printers, tool renders
tools/                          art and balance scripts (not shipped)
tools/catalog/                  the card and mod tables; build.py writes scripts/core/catalog/*.gd
tests/                          automated checks (not shipped)
backend/                        authoritative-server scaffolding only; not used by the game
```

To add or rebalance a card, edit `CARDS` in `scripts/core/game_data.gd`. The
rules engine, AI, deck builder and packs all read from that one list.

## Tests

```
godot --headless --path . --import                         # once, after cloning
godot --headless --path . -s tests/check_scripts.gd        # every script compiles
godot --headless --path . -s tests/test_rules.gd           # rules, catalog, AI-vs-AI matches
PRINTFORGE_PROFILE=smoke godot --path . --disable-vsync -s tests/ui_smoke.gd   # real mouse input + full matches through the UI
PRINTFORGE_PROFILE=tour  godot --path . --disable-vsync -s tests/tour.gd -- <dir>   # screenshots of every screen
# add --resolution 720x1280 to the tour for the portrait layouts
```

Network match between two copies on one machine:

```
PRINTFORGE_PROFILE=neta godot --headless --path . -s tests/net_smoke.gd -- host &
PRINTFORGE_PROFILE=netb godot --headless --path . -s tests/net_smoke.gd -- join
```

`tools/card_winrates.gd` plays thousands of computer-vs-computer games with random legal decks and prints each card's win rate (`godot --headless --path . -s tools/card_winrates.gd -- 5000 100`); a card more than a few points off 50% at its cost is a balance suspect.

`PRINTFORGE_PROFILE` points the game at a throwaway save so tests never touch
your real one. `tools/sim_balance.gd` prints win rates of stand-in players
against every campaign rival.

## Art

Creature sheets, raw prints, armor, the base printer and the room backgrounds
come from earlier work on this project (see `docs/ART_GENERATION_LEDGER.md`).
The Test Bot token is modelled and rendered in Godot like the tools.
New art in this version was made with open-source tools only:

- **Tool cards** (`assets/tools/`): modelled from primitives with bevelled edges
  and rendered in Godot by `tools/render_art.gd`, using a printed-plastic shader
  that draws the layer lines (`assets/shaders/printed_plastic.gdshader`).
- **Elemental ambience**: each print on the battlefield sheds a few soft
  particles for its element (`BoardUnit._make_ambient`).
- **More cards**: ten more tools and six more pieces of equipment are modelled
  and rendered by `tools/render_art2.gd`; sixteen more creatures are recoloured
  from existing sprite sheets by `tools/make_creature_variants.py`.
- **The battle arenas** (`assets/ui/arena/`): six themed benches, their glowing
  lanes and the tools lying on them, rendered by `tools/render_arena.gd`.
- **Creatures** (`tools/make_creatures.py`): the 112 newer creatures are base
  creatures printed in a *filament finish* (silk gradient, marble, glow, carbon
  fibre, wood, metal, translucent glass, glitter, stripes, lava/volt cracks;
  `tools/creature_finish.py`), with their element's silhouette effects on rare
  and better ones (`tools/creature_fx.py`). Nine are designs cut out of reference
  photos (`tools/creature_sources/`). Edit `tools/catalog/creatures.py`, run
  `python3 tools/catalog/build.py`, then the art script.
- **More tools and equipment**: 27 tools and 20 pieces of equipment are modelled and
  rendered by `tools/render_art3.gd`.
- **Mod parts** (`assets/printer_mods/`): one small modelled gadget per Printer
  mod, rendered by `tools/render_mod_parts.gd` and bolted onto the machine picture
  by `scripts/ui/printer_rig.gd` (where each one sits is its `LOOKS` entry).
- **Printer colourways** (`assets/printers/`): recoloured from the base printer
  by `tools/make_printer_variants.py` (`uv run --with numpy --with pillow python
  tools/make_printer_variants.py`). The six newest Printers add their own parts
  on top: a resin bottle, a pellet hopper and a cyclone turbine rendered by
  `tools/render_printer_parts.gd` (into `tools/printer_parts/`), plus glass and
  icicles, delta arms and hazard-striped braces drawn by the script.
- **The print-in animation**: a shader (`assets/shaders/print_reveal.gdshader`),
  not extra frames.
- **Card packs**: the foil pouch, its creases, its gloss and the tear are all
  one shader (`assets/shaders/foil_pack.gdshader`); the figure on the front is
  existing creature art.

Audio is all synthesised from oscillators and filtered noise (no samples):
`tools/make_music.py` composes five looping tracks (menu, shop, workbench and two
battle themes), each battle theme in three layers that fade in as the fight
heats up, and `tools/make_sfx.py` renders about 50 effects and jingles. Both use
`tools/audiolib.py` (numpy + soundfile) and are deterministic, so
`uv run --with numpy --with soundfile python tools/make_music.py` regenerates
them. `scripts/core/audio.gd` crossfades tracks, mixes the battle layers by how
the fight is going, and ducks the music under the win and lose jingles.
The Arvo font is under the SIL Open Font License (`assets/fonts/Arvo-OFL.txt`).

## Builds

`.github/workflows/build.yml` exports the `Windows Steam`, `Linux` and `Android`
presets from `export_presets.cfg`. No credentials, Steam app IDs or keys belong
in this repository.
