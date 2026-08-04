# Enchanted terrain split v2

This folder contains the verified full-resolution separation of `Meshy_AI_Enchanted_Terrain_Kit_0804010559_texture.glb`.

- `enchanted_terrain_kit_split_v2.glb` preserves the original atlas placement but exposes nine named mesh objects.
- The other nine GLBs contain one asset each, centered horizontally with the lowest point at local Z zero.
- All 973 disconnected source islands are assigned exactly once.
- Total source density remains 1,122,784 polygons; optimize copies before using them repeatedly in combat, especially on Android.

Asset names: `BroadleafTree`, `PineTree`, `DeadStump`, `RoundedBoulder`, `JaggedBoulders`, `RollingHill`, `RoadTile`, `StreamTile`, and `BridgeTile`.

See `docs/terrain-kit-split-v2-report.json`, `docs/terrain-kit-split-v2-validation.json`, and `previews/enchanted-terrain-kit-split-v2.png` for validation.
