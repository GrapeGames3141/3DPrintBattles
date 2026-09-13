# Voltwig facing milestone — accepted

2026-09-12. **Genuine Voltwig front/rear art is cleaned, integrated and verified.**
No side-view release exception remains in the battle-facing cache. This is a shared
art/presentation milestone, not a new-prototype APK or Android/Drive delivery claim.

## Selected art and approval

User explicitly authorized checkerboard cleanup: “Yes—clean up Voltwig and continue.”
Primary and read-only UI reviewer accepted cleaned-v3 with no P0/P1 asset findings.
The unchanged ImageGen source, prompt/provenance, full RGBA, light/navy proofs and
exact-scale/root proofs are indexed in
[the asset record](../art/team-prototype-20260912/voltwig-neutral-facing/README.md).
Rejected v1/v2 derivatives remain local evidence and are not runtime resources.

Promoted asset: `assets/creatures/2d/battle-facing/voltwig_battle_facing_2x1.png`.
768x512 RGBA, 262,755 bytes, SHA-256
`80883C09C69B52E296152C56E14C3E61DFECDB4031B84100487EB6C8915F9280`.
The primary independently reproduced that hash using the committed extractor into
`build/evidence/voltwig-alpha-primary-v3-20260912`. The sandbox initially denied
folder creation (Windows error5); the same scoped command succeeded in the approved
desktop context. Source RGB is byte-identical in the full-resolution alpha derivative.
All pixels in the four eyes/muzzle/rear-tail interior ROIs are alpha255; eight real
negative-space samples are alpha0. Each complete cell uses the same .454 scale and
is translated to planted-foot y455; top clearance is front35/rear28 pixels.

## Runtime and maintenance

- Rival/front is actual cell0; friendly/rear is actual cell1. Raw, idle and finite
  attack/deploy motion never switch to a side image or a fabricated eight-pose sheet.
- The cache owns explicit species geometry and validates imported size once. The
  23 existing 4x2 sheets retain their original frame/cadence semantics.
- All five battlefield source-region writes consume the species-aware API. Invalid
  frame requests use a transparent 1x1 sentinel, not Godot's whole-atlas zero region.
- Primary restored unrelated idle/windup/recovery/invalid-seat test guards, corrected
  a double-gutter offset in the shader test, and required real partial-alpha samples.
  No rule, profile, win-condition or save-schema change belongs to this milestone.
- Offline mask code has a source SHA guard; runtime performs no mask generation,
  per-frame PNG read, atlas assembly or duplicate texture loading.

## Evidence

All paths below are under `build/evidence/team-battle/`. Every listed Godot run
finished exit0, exact success marker, no unexpected errors, no process survivors,
and an unchanged isolated startup-save manifest. Direct hidden engine, no console
wrapper or pointer capture. Final read-only Godot/WerFault process audit was empty.

| Check | Evidence directory | PID |
| --- | --- | ---: |
| Writer import | `20260912-211828-fdfacfa9303b4529be72ee6e07ce97af` | 50188 |
| Primary final cache | `20260912-212552-96ce93a08f9f458385b11dc014404586` | 99868 |
| Primary final all-24 roster/both seats | `20260912-212558-759a5290e6904e2aa6006b3945efd5be` | 54900 |
| Primary rendered 576x1024 | `20260912-211953-ec3962090a4d4d90a83da888d647337b` | 126532 |
| Primary rendered 720x1280 | `20260912-212200-d7395813abf442c5b9baf7d51e215930` | 76848 |
| Primary tall720x1600, text150/HC/RM | `20260912-212259-e6be3ea99548498c91078919d99787dd` | 125020 |
| Primary raw-filament shader | `20260912-212355-c58280776e374a65b0e4b7c82d184473` | 105288 |

Commands use `tools/run_team_battle_tests.ps1` suites `import`, `facing`,
`facing-capture` (with the named size/accessibility options) and `raw-render`.
Raw shader source/import partial-alpha parity: Aquafin1336, Runestag834,
Voltwig rear1149/front1229; every sampled partial pixel matches source/import and
render/import tolerance. Primary reviewed normal/larger/tall captures at original
resolution. Read-only UI reviewer inspected all eight normal lifecycle captures
and found no P0/P1 art-runtime issue: correct directions, clean alpha/filtering,
unclipped ears/tail, grounded return and raw material separate from living color.

## Explicit remaining scope

The rendered fixture above still uses the historical presenter to test the shared
cache; its printer HP, six floor slots and contact-caption overlap are **not** the
approved new team UI. No claim is made that this fixture implements BA-R1. Attack
contact pictures are deterministic presentation frames, not timing evidence.

M1 battle rules/Coordinator and M2 Collection are accepted separately. Match Session,
file adapter and native team screens remain to be implemented and verified using
the prepared bounded plans. Default app/export entry still points at the old mode.
Do not ship that mode as the new prototype. No Android device was connected during
the read-only ADB check; native phone input/lifecycle/performance remains unverified.
H: Google Drive was mounted, but no new APK/README has yet been copied this milestone.
