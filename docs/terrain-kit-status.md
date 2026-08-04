# Enchanted terrain kit status

The supplied Meshy GLB is preserved at `source_assets/Meshy_AI_Enchanted_Terrain_Kit_0804010559_texture.glb`.

Inspection found a single 1,122,784-polygon mesh containing a 3×3 atlas and 973 disconnected pieces. The first automatic loose-part reconstruction mixed pieces between the upper tree, boulder, and hill cells, so that generated runtime candidate was rejected and is not referenced by either app. The validation image and reports remain in `previews/` and `docs/` as an audit trail.

The combat POC therefore uses the clean procedural grid terrain for its road, two-cell shallow river, bridge, rolling hills, trees, and boulders. `tools/prepare_terrain_kit.py` remains available for a future extraction pass once the atlas grouping rules are refined or the source is supplied as separate objects.
