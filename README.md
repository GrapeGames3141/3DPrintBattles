# PrintForge Legends

A single-player collectible creature-battle game set in **Forgeholm**, a magical high-tech
workshop city where arcane energy powers giant 3D printers. Collect magical "Prints,"
battle AI trainers, run educational math quests, and grow your Forge.

- **Engine:** Godot 4.3 (.NET / GDScript)
- **Platform target:** PC / Steam (v1.0). Mobile & Switch are future updates.
- **Audience:** All ages. Educational quests for kids; battle depth for adults.
- **Save:** Local JSON (no backend / no internet required at launch).

Design source of truth: `PrintForge_Legends_GDD_v2.docx`
Build instructions / phase plan: `CURSOR_HANDOFF.md`

---

## Current Status

**Phase 1 complete** — core game loop playable with polished placeholder UI.

**Phase 2 in progress** — generating real starter creature sprites (needs PixelLab API key).

See `CURSOR_HANDOFF.md` → **CURRENT BUILD STATUS** for the live progress log.

---

## How to Run (Developer)

1. Install **Godot 4.3 (.NET)** from https://godotengine.org/download
2. Open Godot → **Import** → select this folder's `project.godot` → **Import & Edit**
3. Press **F5** (Run Project). The game boots into `Main.tscn`, which routes to
   Starter Selection on first run, or the Workshop if a starter is already chosen.

To wipe save data and test first-run flow again, delete the Godot user save
(`user://` — on Linux: `~/.local/share/godot/app_userdata/PrintForge Legends/`).

---

## Project Structure

```
project.godot                 Godot config + autoloads + global theme
data/
  GameData.gd                 All creatures, abilities, cards, equipment, trainers, rarities
scripts/
  Main.gd                     Entry router (save-state based)
  SceneTransition.gd          Autoload — fade transitions + data passing
  SaveManager.gd              Autoload — local JSON save/load
  BattleManager.gd            Autoload — battle engine + signals
  AudioManager.gd             Autoload — music/SFX (guards missing files)
  SteamManager.gd             Autoload — achievements (guards missing Steam)
  StarterSelection.gd         Pick one of 3 starters
  Workshop.gd                 Hub navigation + HUD + daily login
  TrainerSelect.gd            Choose AI trainer + 3-print team
  Battle.gd                   Battle UI wiring
  Shop.gd                     Filament Market (buy blueprints / print)
  Academy.gd                  Math mini-game quests
  Forgedex.gd                 Creature discovery log
  PrintYard.gd                Owned prints wander a diorama
  GearLocker.gd / Settings.gd Phase 3/4 (scenes not built yet)
scenes/
  Main / StarterSelection / Workshop / TrainerSelect / Battle /
  Shop / Academy / Forgedex / PrintYard   (.tscn — built in Phase 1)
assets/
  ui/PrintForgeTheme.tres     Global UI theme (purple/amber workshop look)
  sprites/  audio/  steam/    Populated in Phases 2–4
```

## Build Phases (summary)

| Phase | Goal | Status |
|-------|------|--------|
| 0 | Environment setup (tools, keys, MCP, GitHub) | partial — PixelLab key next |
| 1 | Core game loop, placeholder art | **complete** |
| 2 | Starter sprites + blueprint art (PixelLab/Scenario) | **in progress** |
| 3 | All 15 creatures, equipment, Print Yard, full content | not started |
| 4 | Audio (ElevenLabs), Steam integration, store page, QA | not started |
| 5 | Post-launch: multiplayer, trading, mobile | future |

## Art / Audio Tooling (later phases)

Connected to Cursor via MCP and gated behind API keys set as environment variables:
`PIXELLAB_API_KEY`, `AUTOSPRITE_API_KEY`, `SCENARIO_API_KEY`, `ELEVENLABS_API_KEY`.
No key is ever committed to git.
