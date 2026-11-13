# PrintForge Legends

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
gives you its Printer, a 20-card starter deck, 150 Forge Coins and three packs,
and drops you into a guided tutorial battle.

The game plays in landscape or portrait and re-lays itself out live when the
window or phone turns.

## The game

| | |
|---|---|
| **Battles** | 20-Health Printers, 20-card decks. Play prints, tools and upgrades; attack with prints; destroy the enemy Printer. A hand below 3 cards is topped up each turn. |
| **Filament** | A Spool of 40 for the whole battle. The Printer lays down 3 a turn. A card that costs more goes on the Printer as a long print: it takes what is left of this turn, the rest on your next turns, and is deployed for free when finished. Both players can see it. A shattered print puts 1 Filament back on its owner's Spool. |
| **Prints** | 24 creatures across 8 elements, with Guard, Rush, Brim, Siphon and Twin Nozzle keywords plus On Print and Shatter effects. |
| **Tools** | 16 one-shot cards, each a real 3D-printing tool: Heat Gun, Calipers, Bed Scraper, Hex Keys, Emergency Stop and so on. |
| **Upgrades** | 7 pieces of printed armor that bolt onto a print for the rest of the battle. |
| **Printers** | 6 heroes, each with its own Power (2 Filament, once a turn). Prints that share their Printer's element get +1 Health. |
| **Card packs** | Blueprint Pack (100 coins) and Golden Spool Pack (250): foil pouches you rip open with a swipe, then flick through the cards one at a time. Spare copies are recycled into coins. Any card can also be printed directly for coins. |
| **Workshop upgrades** | Reinforced Frame, Heated Bed, Bigger Spool and Coin Sorter: permanent bonuses bought with coins. |
| **Tutorial** | A guided first battle with on-screen tips that follow what you do. Replay it from the Battle menu or How to Play. |
| **Vs computer** | A 10-rival campaign with first-win pack rewards, and Quick Battle at Apprentice, Craftsman or Master. |
| **Vs a friend** | Pass & Play on one screen, or Host / Join over the local network (port 24842; over the internet the host must forward that port). |

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

`PRINTFORGE_PROFILE` points the game at a throwaway save so tests never touch
your real one. `tools/sim_balance.gd` prints win rates of stand-in players
against every campaign rival.

## Art

Creature sheets, raw prints, armor, the base printer and the room backgrounds
come from earlier work on this project (see `docs/ART_GENERATION_LEDGER.md`).
The Test Bot token is modelled and rendered in Godot like the tools.
New art in this version was made with open-source tools only:

- **Tool cards** (`assets/tools/`): modelled from primitives and rendered in
  Godot by `tools/render_art.gd`, using a printed-plastic shader that draws the
  layer lines (`assets/shaders/printed_plastic.gdshader`).
- **The battle arena** (`assets/ui/arena/`): the workbench, its glowing lanes
  and the tools lying on it are rendered the same way by `tools/render_arena.gd`.
- **Printer colourways** (`assets/printers/`): recoloured from the base printer
  by `tools/make_printer_variants.py` (Pillow + numpy).
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
