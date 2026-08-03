# PrintForge Summon Lab project rules

- Keep the durable project and delivery artifacts in this repository.
- Target Godot 4.7 with the Compatibility renderer and Android arm64.
- Preserve `source_assets/` as immutable input; regenerate optimized runtime GLBs with `tools/prepare_mobile_assets.py`.
- Keep the runtime creature path stable at `assets/models/ironbound_goblin_mobile.glb` so an animated replacement can be swapped in without rewriting the viewer.
- Validate all rarity, strength, and animation selector modes before committing a release build.
- Never commit signing keys or credentials.

