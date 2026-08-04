# PrintForge project rules

- Keep the durable project and delivery artifacts in this repository.
- Target Godot 4.7 with the Compatibility renderer: Windows and Android arm64 for combat, plus Android arm64 for the separately installed model inspector.
- Preserve `combat_main.tscn` as the desktop entry and `main.tscn` as the mobile inspector entry.
- Preserve `mobile_router.tscn` as the Android entry; it routes to the one app scene included by each Android export preset.
- Preserve `source_assets/` as immutable input; regenerate optimized runtime GLBs with `tools/prepare_mobile_assets.py`.
- Keep the runtime creature path stable at `assets/models/ironbound_goblin_animated_v3.glb` so an animated replacement can be swapped in without rewriting either app.
- Keep the combat Moonshadow Rogue model at `assets/models/moonlit_elf_duelist_animated.glb`; the Android inspector export deliberately excludes combat-only models and concept art.
- Keep the combat Bogbrew Stitchdoc model at `assets/models/verdant_alchemist_animated.glb`.
- Validate combat smoke plus all inspector rarity, strength, and animation selector modes before committing a release build.
- Never commit signing keys or credentials.
