# Enchanted terrain kit status

The supplied Meshy GLB is preserved at `source_assets/Meshy_AI_Enchanted_Terrain_Kit_0804010559_texture.glb`.

Inspection found a single 1,122,784-polygon mesh containing a 3×3 atlas and 973 disconnected pieces. The first automatic reconstruction assigned every loose island by its center point. That mixed wide tree and rock geometry across the row boundaries, so the original runtime candidate was correctly rejected.

The second pass confirms that the intended models are spatially separate. Three-dimensional bounding-box proximity recovers eight natural clusters; seven map directly to an asset, while the eighth contains only the neighboring stream and bridge because their broad bounds overlap. Dividing that final cluster across the visible gap produces nine complete assets with all 973 islands assigned exactly once.

The verified full-resolution outputs are under `source_assets/enchanted_terrain_split_v2/` as one combined GLB with nine named meshes and nine individually centered GLBs. `previews/enchanted-terrain-kit-split-v2.png` shows the successful reconstruction, while `docs/terrain-kit-split-v2-report.json` and `docs/terrain-kit-split-v2-validation.json` record the grouping and clean re-import checks.

These full-resolution sources total 1,122,784 polygons and are not yet referenced by the combat runtime. The current procedural terrain remains active until a deliberate optimization and collision pass is approved; this avoids silently adding the full source density to the Android build.
