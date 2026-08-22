# PrintForge Legends — 0.8.0 v3 Canonical Refactor

PrintForge Legends is a Godot 4.7.1 card battler built around live 3D-print
queues. The active implementation is the v3.1 ruleset: 2,000 HP printers,
five phases, public FIFO queues, 40-card-minimum decks, Attack/Defense modes,
pre-prints, tiered full suits, combat gems, and player-worn Filament Rings.

## Current implementation

- The Workshop routes Daily Training, Workshop Trials, and local hot-seat play
  through the deterministic v3 battle snapshot.
- Cards, blueprints, Workshop models, and cosmetics have separate ownership.
- The Filament Market, packs, quests, drops, season rewards, and Spark seam
  are local deterministic profile transitions pending hosted authority.
- Full suits are creature armor overlays; gems are combat equipment; the Ring
  is an immediate match-long player effect and consumes no equipment slot.

The canonical rules reference is
[docs/design/printforge-legends-mechanics-v3.1.md](docs/design/printforge-legends-mechanics-v3.1.md).
Historical 0.5–0.7 material is indexed in [docs/archive/0.5-0.7](docs/archive/0.5-0.7).

## Run and validate

Open `project.godot` in Godot 4.7.1, or use a console build of Godot:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --log-file tmp/godot-test.log res://tests/test_v3_smoke.tscn
Godot_v4.7.1-stable_win64_console.exe --headless --path . --log-file tmp/godot-assets.log res://tests/test_runtime_asset_manifest.tscn
```

The TypeScript authority scaffold is checked with:

```powershell
Set-Location backend
npm test
```

Runtime artwork lives under `assets/`. Source masters and review captures live
under `art-source/` and are editor-ignored; they are retained for provenance and
offline art tooling, never for an exported game package. Dynamic asset paths
are listed in `assets/runtime_asset_manifest.json` and validated by the smoke
suite.

## Repository policy

Do not commit build output, Godot `.godot/` import caches, local saves, receipts,
credentials, Steam IDs, or backend deployment configuration. Review builds are
versioned externally and must be hash-verified before release delivery.
Committed runtime asset `.import` settings are intentionally tracked; only
editor-generated `.godot/` import cache data is ignored.
