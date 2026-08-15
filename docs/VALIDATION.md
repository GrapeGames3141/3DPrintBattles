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
