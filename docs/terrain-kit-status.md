# Enchanted terrain kit status

The supplied Meshy GLB is preserved at `source_assets/Meshy_AI_Enchanted_Terrain_Kit_0804010559_texture.glb`.

Inspection found a single 1,122,784-polygon mesh containing a 3×3 atlas and 973 disconnected pieces. The first automatic reconstruction assigned every loose island by its center point. That mixed wide tree and rock geometry across the row boundaries, so the original runtime candidate was correctly rejected.

The second pass confirms that the intended models are spatially separate. Three-dimensional bounding-box proximity recovers eight natural clusters; seven map directly to an asset, while the eighth contains only the neighboring stream and bridge because their broad bounds overlap. Dividing that final cluster across the visible gap produces nine complete assets with all 973 islands assigned exactly once.

The verified full-resolution outputs are under `source_assets/enchanted_terrain_split_v2/` as one combined GLB with nine named meshes and nine individually centered GLBs. `previews/enchanted-terrain-kit-split-v2.png` shows the successful reconstruction, while `docs/terrain-kit-split-v2-report.json` and `docs/terrain-kit-split-v2-validation.json` record the grouping and clean re-import checks.

The combat runtime now uses `assets/models/enchanted_terrain_kit_runtime.glb`. `tools/prepare_terrain_runtime.py` performs the reproducible mobile preparation pass:

- centers every asset at ground level;
- corrects the source atlas's 45-degree diamond presentation to match the orthogonal combat grid;
- reduces 1,122,784 source polygons to 74,497 runtime polygons;
- reduces the four shared 2048px texture maps to 1024px;
- exports one 2.79 MB GLB containing all nine named meshes; and
- preserves exact grid-based obstacle rules while adding primitive collision bodies to trees and boulders.

The road, two-square stream, and bridge use fitted repeated modules over the existing authoritative grid tiles. Grass remains the lightweight procedural underlay, preventing gaps at map edges and keeping movement highlighting legible. `docs/terrain-kit-runtime-report.json` records per-asset budgets and bounds, and `previews/enchanted-terrain-kit-runtime-v2.png` shows the optimized library.
