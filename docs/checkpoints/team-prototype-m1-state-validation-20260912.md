# M1 State and startup checkpoint

Status: **verified foundation only; Battle Core, bot, coordinator and playable UI
are not yet accepted.** No APK export or Google Drive release was produced here.

The sole Terra writer implemented the additive Data/State domain and the internal
read-only startup selector. Primary reviewed the source and independently ran the
engine. The gameplay designer's independent review found two additional defects:
uncommitted current-cycle FIFO jobs could restore, and effect values were not fully
centralized. Both were corrected; settled jobs now require created cycle <= committed
revision, and Data owns the prototype numeric effects with pinned assertions.

## Passing evidence

Godot 4.7.1 `a13da4feb`, direct hidden/headless process, isolated E-based app/user/
temp/cache and QA-save directories. Evidence root is `build/evidence/team-battle/`.

| Case | Evidence directory | Engine PID | Result |
|---|---|---:|---|
| State/Data final audit | `20260912-173444-eb489ab1914f4d58b306b36a9a2a0c2a` | 98140 | 6/6 groups, 60 assertions, zero failures |
| Invalid legacy deck/ownership | `20260912-173548-5a99c6b0af004e0096e6fc37b7c63c58` | 68032 | startup ready; every fixture byte preserved |
| Future schema | `20260912-173551-6df36e28ed834c718cd6c6c2005a7632` | 98820 | read-only future_schema; bytes preserved |
| Backup recovery | `20260912-173554-685e0604eb9d4845b5c39d7b0ef16833` | 108724 | backup_recovered; primary/backup/sidecars preserved |
| Invalid backup, no primary | `20260912-173557-f01343ea50f84e3a9c6b4d80fb3a8f9c` | 74196 | corrupt_backup; no replacement profile created |

All listed engine exits were zero with clean logs, the expected exact startup/test
markers, no task-process survivors, and unchanged SHA-256/size/file-set manifests.
Primary independently checked each root PID and descendants after completion; all
were absent. No task-owned window was observed and no unrelated process was stopped.
These are invented fixtures, never actual player saves. Device behavior is not tested.

The earlier State attempt `20260912-172418-27b087d493594d2db0cf9661392a8c78`
(PID 109216) failed a GDScript type inference check. Godot still returned zero and
the incomplete suite printed failures=0; the harness correctly rejected its script
errors. The source was fixed and test groups now mark completion internally only
after reaching their end. The subsequent 44-assertion pass was superseded by the
60-assertion independent-audit corrections above. Failure evidence is retained.

## Remaining M1 work

- Rules/core fixtures: atomic Plans, FIFO print/awaken/enter, supports, simultaneous
  damage and traits, swaps/replacement, once-only team defeat and Draw.
- Bot projection/policy, coordinator persistence/cursor idempotence and resume.
- 45 seeded pacing traces; no timeout result and no invented pacing target.
- Independent final gameplay/maintainability review and exact-file commit.

M2 Collection Link and M3 native portrait screens/animation/Android delivery follow
the already approved milestone order. The existing shipped build remains unchanged.
