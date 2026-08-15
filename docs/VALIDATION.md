# Validation record

Run from project root with the Godot 4.7.1 Windows console executable:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --editor --quit
Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/test_battle_rules.tscn
```

## Implementation validation

- 2026-08-14: Godot 4.7.1 `--headless --editor --quit` completed with exit code 0 against the delivered E: project (console PID 23324). The project scan and asset import reported no GDScript parse errors.
- 2026-08-14 correction pass: final direct E: parser smoke (console PID 20252) and bounded game-scene tests (console PIDs 1380 and 21056) exited 0. The game-scene command used `--headless --scene res://tests/test_battle_rules.tscn --quit-after 8` with isolated E: user-data/log paths and emitted `PASS: battle rules, starter deck, cards, switching, catalog counts, and weights`.
- 2026-08-14 AI/Cooling correction: direct E: parser smoke (console PID 21180) and bounded regression test (console PID 7448) exited 0. The regression suite covers AI coin-flip opening defense, forced-replacement Cooling/basic attack, and shield absorption to zero damage.
- The validation environment emitted only non-project warnings about the Windows root certificate store and unavailable local `user://` persistence; the save layer now handles unavailable storage safely for test runs.

No Godot editor processes are required for the test scene.

## Checkpoint 2 validation

The checkpoint adds `test_profile_rules.tscn` for version migration, one-time starter selection, bound-instance metadata, and pure onboarding routing. `capture_checkpoint2.tscn` is a reusable visual-QA scene that writes onboarding and workshop captures to `E:/CodexCache/printforge-validation/`; it must run with a non-headless Windows display driver because Godot's headless dummy renderer has no viewport texture to save.

- 2026-08-14 checkpoint 2 direct E: verification: parser PID 24656 exited 0; bounded profile/onboarding test PID 7016 exited 0; bounded battle regression PID 18272 exited 0; bounded OpenGL visual capture PID 24988 exited 0. No Godot console processes remained.
- 2026-08-14 checkpoint 2 transition follow-up: parser PID 15652, profile rules test PID 17056, and battle rules test PID 19712 each exited 0. Fresh-scene OpenGL capture runs PID 11420 (1280×720) and PID 6200 (1920×1080) wrote four inspected PNGs to `E:/CodexCache/printforge-validation/`; no Godot process remained.
- 2026-08-14 header-layout correction: isolated-mode capture PIDs 12700, 9448, 12436, and 21792 generated tagged onboarding/workshop files at 1280×720 and 1920×1080. The exact `workshop_*_headerfix.png` files were visually inspected at original detail and show the full `PRINTFORGE LEGENDS` title, subtitle, and ~20px top margin. Final parser PID 23756, profile test PID 23292, and battle test PID 26296 exited 0; no Godot process remained.
