# PrintForge Summon Lab 0.1.0

Godot 4.7.1 prototype for selecting a rarity base, strength rank, and creature animation. Windows is the primary target; the Android arm64 package is the phone demo.

## Included behavior

- Six rarity/base materials: reclaimed wood, carved stone, cast bronze, forged steel, carbon composite, and arcane resin.
- Weak, Normal, and Elite strength ranks represented by one, two, or three illuminated chevrons on a small rim-mounted shield badge.
- Horizontal layer-print summon with an empty-base lead-in, moving filament ring, hot print band, cooling layer lines, and sparks.
- Seven embedded goblin clips: Alert Turn Left, Fall, Run, Stand Up, Sword Slash, Walk, and Walk Backward.
- Mouse and touch drag rotation outside the controls panel.
- Rigid-bound character shield so it does not bend during animation.

## Builds

- `PrintForge-Summon-Lab-0.1.0-arm64.apk`
  - Size: 157,866,809 bytes
  - SHA-256: `546DE99B47A90D073C6B31110AB2394371CA6726B9434A36A6E6FD3E9FCC6AC1`
- `PrintForge-Summon-Lab-0.1.0.exe`
  - Size: 232,460,072 bytes
  - SHA-256: `3B3665FD14F2DC29AB21EB697202E14CD9C0D8455B51201AB5A50170FE1D659B`

## Android install

The APK is debug-signed for direct testing. Install with `adb install -r PrintForge-Summon-Lab-0.1.0-arm64.apk`.

Validated on a Pixel 9 Pro in landscape mode. The package ID is `com.tak.printforge.summonlab`.
