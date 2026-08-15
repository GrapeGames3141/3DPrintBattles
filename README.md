# PrintForge Legends

Steam-first Godot 4.7.1 vertical slice for a cozy, winter-lit magical 3D-print workshop battler. It provides a playable solo battle loop, workshop navigation, blueprint/printing progression, Forge Coins, Forgedex, safe local trade contract, offline journal, 24-creature / 8-rarity catalog, 30 support cards, 7 armor definitions, and TypeScript Nakama-authority scaffolding.

## First-run flow

New apprentices begin with 180 Forge Coins and no creatures or blueprints. The Awakening Ceremony presents Cinderpaw, Aquafin, and Voltwig with a permanent-choice confirmation. Confirming grants exactly one bound, nontradable starter blueprint and instance, then creates a one-creature training team. Existing schema-1 profiles migrate without removing inventory and are marked complete to prevent a duplicate starter grant.

## Run

Open `project.godot` in Godot 4.7.1 or run the `tests/test_battle_rules.tscn` headlessly. The first run creates only local `user://` save data.

## Scope note

Approved creature concepts, final GLB models/animations, GodotSteam, Nakama SDK/runtime deployment, Steam App ID, and production art/audio are intentionally not bundled. The procedural UI makes the vertical slice runnable without credentials or unapproved final assets.
