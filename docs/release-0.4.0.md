# PrintForge Combat POC 0.4.0

This Android arm64 build integrates the recovered Enchanted Terrain Kit and retains the tactical camera controls introduced in 0.3.6.

## Terrain integration

- Replaces procedural trees, boulders, hills, road surfacing, stream surfacing, and bridge detailing with the nine recovered Meshy assets.
- Reduces the terrain library from 1,122,784 source polygons to 74,497 runtime polygons.
- Reduces four shared textures from 2048px to 1024px and packages the nine meshes in a 2.79 MB runtime GLB.
- Corrects the source atlas's 45-degree display rotation for clean orthogonal-grid placement.
- Preserves exact grid movement/obstacle rules and adds lightweight primitive collisions to trees and boulders.
- Uses a procedural grass/grid underlay so movement highlights and map edges stay legible.

## Camera controls

- One-finger drag pans.
- Two-finger twist rotates.
- Two-finger vertical slide tilts.
- Pinch zooms.
- Reset View restores the default framing.

## Build

- `PrintForge-Combat-POC-0.4.0-arm64.apk`
- Package: `com.tak.printforge.combatpoc`
- Version code: 11
- Minimum SDK: 24
- Target SDK: 36
- Architecture: Android arm64
- Signing: Godot debug certificate; APK Signature Schemes v2 and v3 verified
- Size: 337,389,100 bytes
- SHA-256: `EE70442C70FCF62B5B1B20CB062ADFC22C57FFB91D74DD0B9ADF91058F4BD0C6`

Validation passed: Godot parse/import, strengthened terrain coverage assertions, the full combat smoke simulation, and a 1280x720 rendered map inspection.
