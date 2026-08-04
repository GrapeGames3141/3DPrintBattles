# PrintForge Combat POC 0.4.1

This Android arm64 build includes the modular combat architecture and four-sided cardboard concept units introduced after 0.4.0.

## Installation fix

- Raises the Android version code from 11 to 12.
- Retains the same `com.tak.printforge.combatpoc` package and signing certificate for in-place updates.
- Stops packaging six unused 4K PNG sidecars whose textures are already embedded in the three animated GLBs.
- Excludes model-inspector base textures and unused combat turnaround/printer concept sheets.
- Retains all animated models, terrain assets, and unit four-view images required by the live combat app.

## Validation

- Combat smoke simulation passed.
- Model-inspector boundary smoke test passed.
- APK manifest, arm64 ABI, and v2/v3 signatures verified.

## Build

- File: `PrintForge-Combat-POC-0.4.1-arm64.apk`
- Package: `com.tak.printforge.combatpoc`
- Version: `0.4.1` (code 12)
- Minimum SDK: 24
- Target SDK: 36
- Architecture: Android arm64 only
- Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`
- Size: 86,457,103 bytes (82.5 MiB)
- SHA-256: `8C38E6D8942E9138B0C828A3C1DA2908E28921830C0E5DD19B9DE8B23C8D06D4`
