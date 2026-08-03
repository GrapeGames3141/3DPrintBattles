# PrintForge Summon Lab

Windows-first Godot prototype for reviewing a creature, its rarity base, strength badge, and selectable animations. An Android landscape build is retained as the mobile demo target.

## Current controls

- **Model:** selects the active creature. The initial build contains Ironbound Goblin Warrior; additional model resources can be added to `MODELS` in `scripts/summon_lab.gd`.
- **Rarity / base:** selects one of six extracted base materials.
- **Strength:** lights one, two, or three chevrons on the separate shield badge.
- **Animation:** plays the layer-print summon, shows the model immediately, or plays one of the seven embedded goblin animations.
- **Print / Play:** runs the selected mode.
- Drag the 3D area to rotate the display.

The summon begins with the empty selected base and rank badge. After a short pause, the goblin is revealed from its feet upward using a world-height shader, a bright filament scan ring, cooling horizontal layer lines, and mobile-safe sparks.

The rank badge is deliberately rim-height and tilted 12 degrees backward so it reads as a small physical marker instead of obscuring the miniature. The goblin's round shield is rigid-bound to its left hand during asset preparation to prevent auto-weight deformation in action clips.

## Replacing the goblin GLB

1. Preserve the animated source separately.
2. Export or copy its prepared runtime version over `assets/models/ironbound_goblin_animated_v3.glb`.
3. Ensure the model stands on local Y=0 after Godot import.
4. Reopen the project and let Godot reimport it.
5. Embedded `AnimationPlayer` clips appear automatically in the Animation selector; `RESET` is hidden.
6. The summon shader is applied to every `MeshInstance3D` surface, including skinned meshes.

Animation discovery is automatic. Friendly labels are supplied for the current seven clips, while any newly added clips still appear using their embedded names.

## Source and optimized assets

- Original Meshy files live in `source_assets/` and are ignored by Godot via `.gdignore`.
- Runtime GLBs live in `assets/models/`.
- `tools/prepare_mobile_assets.py` splits the combined base sheet into six centered objects plus its source crest.
- `tools/prepare_merged_animated_goblin.py` turns the supplied all-in-one Meshy animation GLB into the grounded runtime model and normalizes clip names.
- The separate shield crest geometry is darkened at runtime and receives three procedural emissive chevrons so rank can change without regenerating the base model.

## Validation

Use the console build of Godot 4.7.1:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit-after 5
Godot_v4.7.1-stable_win64_console.exe --headless --path . -- --smoke-test
```

The smoke test exercises all six rarity bases, all three strength ranks, the summon shader, and animation discovery. Success prints `SUMMON_LAB_SMOKE_TEST_OK`.

The release was also exercised on a Pixel 9 Pro: full-width landscape rendering, selector input, summon playback, and touch-drag rotation were confirmed on-device.

## Exports

The repository contains a Windows Desktop preset as the primary target and an arm64 Android demo preset targeting SDK 35.

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-debug "Windows Desktop" builds/windows/PrintForge-Summon-Lab-0.1.1.exe
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-debug "Android Demo" builds/android/PrintForge-Summon-Lab-0.1.1-arm64.apk
```
