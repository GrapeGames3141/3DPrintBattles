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

## Checkpoint 4 staging validation

- 2026-08-14 final direct E: validation used Godot 4.7.1 with isolated app-data roots under `E:/CodexCache/printforge-validation/checkpoint4-final-e/`. Parser worker PID 21180, profile PID 25420, progression PID 16080, battle PID 22468, and checkpoint-4 PID 24264 each exited 0. The last test covers settings migration/rejection, reduced-motion/event frame selection, catalog sprite fallback, armor stat mapping/damage reduction, AI opening/low-HP decisions, and the one-claim reward latch.
- Fresh Forward+ captures used `capture_checkpoint2.tscn` in separate processes and were written under `E:/CodexCache/printforge-validation/`: `battle_1280x720_checkpoint4-alpha-crop.png`, `battle_1920x1080_checkpoint4-alpha-crop.png`, `settings_1280x720_checkpoint4-final.png`, `settings_1920x1080_checkpoint4-repeat.png`, `high_contrast_battle_1280x720_checkpoint4-alpha-crop.png`, and `high_contrast_battle_1920x1080_checkpoint4-alpha-crop.png`. They were inspected for visible headers, readable controls, stable alpha-union sprite crops, equipped-armor labels, high-contrast borders, and non-cropped actions.
- Direct visual invocations emitted known environment-only root-certificate/user-storage warnings plus a renderer cache warning on orderly exit. They still saved the requested PNGs and exited 0. The final process audit found no Godot console or worker process remaining.

## Checkpoint 3 validation

- 2026-08-14: direct E: parser scan (PID 13152), profile migration/onboarding test (PID 18540), progression regression test (PID 23196), and battle regression test (PID 14148) each exited 0. Direct runs used isolated app-data paths under `E:/CodexCache/printforge-validation/` and bounded `--quit-after 300` scene runs.
- 2026-08-14 visual QA: fresh-process Forward+ captures were written under `E:/CodexCache/printforge-validation/` for `shop`, `collection`, `team`, `armor`, and `deck` at both 1280x720 and 1920x1080, with a deterministic fixture containing Cinderpaw, a printed Mossmunk, a learned/printed unequipped Layered Helm, and an extra support card. Final 1280 PIDs: 13848, 22160, 3304, 13420, 11420. Final 1920 PIDs: 13736, 24272, 11968, 26596, 23744.
- Shop grid width, collection printing, multi-creature team controls, armor target choices, deck count controls, and scroll behavior were visually inspected. No task-started Godot console or worker process remained at final audit.
- Follow-up visual QA: `team_1920x1080_teamstable.png` was captured in a fresh process (PID 10904) after the harness polled the named workshop header for a visible y-position and 80px minimum height, then waited three settling frames. It was individually inspected at original detail with the full title, subtitle, coins, and spool readout visible.
- Follow-up direct E: parser smoke: PID 4916 exited 0 after the capture-harness update; the final process audit found no Godot console or worker process.

## Checkpoint 2 validation

The checkpoint adds `test_profile_rules.tscn` for version migration, one-time starter selection, bound-instance metadata, and pure onboarding routing. `capture_checkpoint2.tscn` is a reusable visual-QA scene that writes onboarding and workshop captures to `E:/CodexCache/printforge-validation/`; it must run with a non-headless Windows display driver because Godot's headless dummy renderer has no viewport texture to save.

- 2026-08-14 checkpoint 2 direct E: verification: parser PID 24656 exited 0; bounded profile/onboarding test PID 7016 exited 0; bounded battle regression PID 18272 exited 0; bounded OpenGL visual capture PID 24988 exited 0. No Godot console processes remained.
- 2026-08-14 checkpoint 2 transition follow-up: parser PID 15652, profile rules test PID 17056, and battle rules test PID 19712 each exited 0. Fresh-scene OpenGL capture runs PID 11420 (1280×720) and PID 6200 (1920×1080) wrote four inspected PNGs to `E:/CodexCache/printforge-validation/`; no Godot process remained.
- 2026-08-14 header-layout correction: isolated-mode capture PIDs 12700, 9448, 12436, and 21792 generated tagged onboarding/workshop files at 1280×720 and 1920×1080. The exact `workshop_*_headerfix.png` files were visually inspected at original detail and show the full `PRINTFORGE LEGENDS` title, subtitle, and ~20px top margin. Final parser PID 23756, profile test PID 23292, and battle test PID 26296 exited 0; no Godot process remained.
