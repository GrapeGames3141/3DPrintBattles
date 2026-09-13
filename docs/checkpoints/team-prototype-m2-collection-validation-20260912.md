# M2 pure Collection core acceptance

Primary accepted this bounded slice on 2026-09-12 after reviewing the sole Terra
writer's implementation and independently rerunning the frozen code. This is pure
Collection authority, not the storage/reward adapter, playable UI, Android build,
device test or complete M2 milestone. The shipped build remains unchanged.

## Behavior verified

- Read-only projection of relevant existing ownership plus an additive
  `team_prototype` namespace. No legacy repair, import, alias or grant helper.
- All three starter mappings, missing licenses/two common preprints, and one
  explicit starter voucher print even when the chosen creature was already Printed.
- Zero/partial/exact/excess Support ownership receives only the frozen missing
  deficits for the recommended 15-card kit. Later receipt replay grants nothing.
- Checked Begin/completion/acknowledgement/Apply, canonical duplicate identities,
  stale revision/fingerprint rejection, deep candidate isolation and failed-store
  rollback. JSON round trips retain available/printing/settled/acknowledged states.
- Exactly three distinct Printed companion IDs, their priority permutation and
  fifteen owned eligible Support copies Apply together without consuming ownership.
  Preview is zero-write; actual Back controls are a later native UI test.
- Malformed relevant ownership, namespace schemas, request history, result records
  and receipt arithmetic fail closed. Every accepted transition preserves original
  top-level data outside the namespace; failed transitions preserve the whole source.

## Independent primary evidence

Commands use `tools/run_team_battle_tests.ps1` with isolated E-based save/user/cache
roots, hidden headless Godot 4.7.1, exact PID identities and final cleanup ledgers.

| Suite | Evidence directory under `build/evidence/team-battle/` | PID | Result |
| --- | --- | --- | --- |
| Collection, final | `20260912-194123-d1c0d396f4bf437d9256f118f0e4c387` | 127072 | 10/10 groups, 176 checks, 0 failures |
| State | `20260912-193954-677c12908b3944388b27c1a98cf1ae18` | 114020 | 6/6 groups, 60 checks, 0 failures |
| Startup, invalid deck | `20260912-194131-c5186b779f994396aeb2f66ae83137ae` | 91380 | Read-only ready; 60 checks, 0 failures |
| Startup, future schema | `20260912-194134-9b064c2e0f4d4247b2cb1529234fe3d8` | 108252 | Read-only future_schema; 60 checks, 0 failures |
| Startup, recovered backup | `20260912-194136-22b62c4917ff4f639a69fb5a1d25a541` | 45780 | Read-only backup_recovered; 60 checks, 0 failures |
| Startup, corrupt backup | `20260912-194139-95010ed82d9b4bfdbc1306e6936e19e3` | 114708 | Read-only corrupt_backup; 60 checks, 0 failures |

All six runs exited 0, emitted the required suite/startup markers with clean logs,
retained the exact isolated save file set/bytes, and left no task-owned process or
window. No actual player save, editor/game window or pointer capture was used.
The writer's final independent run also passed 176 checks:
`20260912-194049-21310ce74cc14f4f94b2fd6cdbbe37ae`, PID104432, clean exit/cleanup.

## Review fixes and maintainability

Projection owns checked schema/ownership/history; Session owns the five candidate
transactions and injected persistence. Neither imports GameManager, SaveService,
UI, art, file paths or legacy normalizers. Existing battle rules remain separate.

Primary review prompted stronger history/receipt consistency tests and a final
guard for an empty historical Apply loadout: an empty *current* unsaved loadout is
valid, but an empty historical Apply result must reject before field dereference.
Both empty historical payload/result regressions are in the final 176-check run.

History lookup now constructs a revision map in one pass instead of repeatedly
scanning every request. Canonical JSON returns its normalized value as well as
text, avoiding the Session's redundant stringify/parse round trip. No further
abstraction or speculative optimization is needed for this isolated slice.

Earlier dependent-preload errors were diagnosed by a new explicit `collection-parser`
runner mode: `namespace` is a reserved identifier in Godot 4.7.1. Renaming the local
identifier/public projection key to `prototype_state` resolved that parse error;
the durable key stays `team_prototype`. Parser-only success is labeled separately
and never reported as a gameplay test. No cache reset or engine replacement was used.

## Remaining work and release hold

Next bounded work is the persistence/reward adapter, followed by the approved
portrait UI, native print/combat playback, Back/lifecycle and device validation.
Do not call full battle snapshots or revalidate collection history every frame.
The read-only [M3 reuse audit](team-prototype-m3-reuse-audit-20260912.md) records
approved masters and integration hazards; it is not native visual evidence.

The reviewed [armor alpha family](../art/team-prototype-20260912/armor-alpha-v1/README.md)
is accepted for planned integration at reviewed display sizes; actual Godot import
and chamber/reveal captures are still pending.

User decision: **hold the Android build until proper Voltwig front/rear art is
supplied, reviewed and integrated.** No temporary side-view exception, export or
Google Drive release is authorized before that gate. No ads/IAP/backend work was added.
