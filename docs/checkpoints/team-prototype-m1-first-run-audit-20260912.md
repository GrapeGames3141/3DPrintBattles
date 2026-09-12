# M1 first-run failure and cleanup

The initial foundation run was **not a test pass**. Primary inspection found the
headless engine still alive after the test scene failed to parse. The writer's
exit-zero claim was retracted; no build or gameplay acceptance relies on it.

- Engine: Godot 4.7.1 `a13da4feb`.
- Engine PID 123504, parent 103544; created 2026-09-12 16:44:07 America/Chicago.
- Executable: `E:/CodexCache/godot-android-4.7.1/godot/Godot_v4.7.1-stable_win64.exe`.
- Arguments: `--headless --path "E:/AI Projects/games/3d print battler" --log-file "E:/AI Projects/games/3d print battler/build/evidence/team-battle-foundation.log" res://tests/team_battle/test_team_battle_core.tscn -- "--qa-save-root=E:/AI Projects/games/3d print battler/build/evidence/team-battle-foundation" --team-prototype`.
- Preserved log: `build/evidence/team-battle-foundation.log`.
- Failure: could not preload TeamBattleRules; test script parse errors; no success marker.
- Startup log confirms isolated project QA profile/journal/sidecar paths and the
  prototype early read-only branch. OS engine user-data still used C:, failing the
  full E-based user/cache isolation requirement.
- Primary CIM inspection found no descendants of PID 123504. Its window handle was
  zero and title empty; no task-owned dialog was shown.
- Primary rechecked exact PID, creation timestamp, executable and command before
  stopping only PID 123504. Follow-up root/child/window queries were empty. No
  unrelated Godot process was stopped.

Missing launch-time records remain an evidence gap, not a reconstructed pass.
Further runs pause until the runner records launch identity, isolates E-based user/
cache/temp paths, bounds actual engine wait, checks success markers and script errors,
and records exact task-process cleanup. This is a test-runner/script failure with
explicit parse evidence, not an inconclusive native-engine crash diagnosis.

## Repaired runner negative-path verification

After repeated incomplete delegated harness corrections, primary took ownership of
the non-runtime verification tool; Terra remains the sole gameplay runtime writer.
The repaired tool has readable functions, mandatory clean-log/success checks, fresh
per-case E-based environment/storage, and identity-checked bounded cleanup.

- Helper checks passed: PowerShell AST, CRT path quoting, live CIM identity and
  descendant traversal, exact success-marker matching; those checks launched no game.
- A deliberate three-second negative-path probe of the incomplete core test failed
  as expected with explicit parse errors, not a claimed gameplay pass.
- Evidence: `build/evidence/team-battle/20260912-170724-8bba9c79128c4aac91501cc08331bde7/`.
- Exact root PID 115736, parent 41924, created 2026-09-12 17:07:24.888228 local.
  Started/observed/final ledgers record command, identity, logs and cleanup.
- Runner stopped only 115736 after timeout. Window handle was zero, no descendants
  were observed, survivors were empty, and primary's independent CIM check found no
  remaining Godot process.
- Startup logged the isolated E-based OS user-data and QA roots; the fresh QA-save
  folder remained empty. This confirms clean-install read-only startup for this
  negative fixture, not existing-save preservation or complete Battle Core behavior.
