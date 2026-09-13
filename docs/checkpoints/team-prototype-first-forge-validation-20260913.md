# First Forge native checkpoint

2026-09-13. Internal, non-default prototype scene. This is a bounded First Forge
checkpoint, **not** complete Collection/Battle UI, an Android build, or Drive delivery.

## Verified outcome

- Available voucher/0% has an empty bed and cyan seed, no finished creature.
- Front-view Cinderpaw/Aquafin/Voltwig share a measured bed root. Raw solid below
  an alpha-aware moving scan, cyan contours above, moving/parked carriage.
- Raw neutral material remains through save and RAW COMPLETE; living material only
  begins during Awaken. The finite departure moves down/forward with its soft shadow,
  then fades to an empty-bed handoff. Reduced motion has a grounded handoff.
- Begin persists before printing. Failed Begin/Complete retain their request IDs;
  a real file-store failure leaves a retryable voucher/raw print, not a false grant.
- Reopening after durable completion shows the existing receipt, and an acknowledged
  voucher does not loop back through that grant. No later visual phase grants again.
- The12-second normal print clock was exercised at30/60/144FPS; focus pause clears
  presentation accumulation and an exceptional foreground delta is bounded.
- Shared raw/wire shaders have backward-compatible default uniforms; prototype
  overrides do not change the historical default rendering contract.

## Evidence

All directories below are under `build/evidence/team-battle/`.

| Check | Evidence directory | Exact Godot PID | Result |
| --- | --- | --- | --- |
| Writer48-assertion UI suite | `20260913-001626-32a51605de7f430387e34af4620370bc` |133940|exit0|
| Primary independent48-assertion UI suite | `20260913-001801-93613975aaa54170b254a396452e5b43` |139616|exit0|
| Shared raw-render regression | `20260913-001214-a4b565d8b8eb420992bfdee79e2a650f` |69316|exit0|
| Final576 rendered sequence fixtures | `20260913-001642-2506ddc2d26c453da3e1372876b80332` |23568|exit0|

Audited process ledgers report no task survivors or remaining windows and unchanged
isolated qa-save bytes. Mutable UI fixtures live in their separate sibling directory.
Captures use actual controller/Sequence transitions and persist metadata for phase,
voucher and material; they do not assign a fake phase to manufacture the screenshot.

[Final capture collection](../../build/evidence/team-battle/20260913-001642-2506ddc2d26c453da3e1372876b80332/captures/)
contains all3 voucher/0/60/raw states and Cinderpaw Awaken/depart midpoint/terminal.
Earlier231216,233626,235722,001228 runs are superseded diagnostics, not final sign-off.

Read-only UI reviewer returned **PASS, no remaining P0/P1 in First Forge576** after
reviewing these final original-resolution images and JSON sidecars. Primary also
inspected the final departure, reviewed source/diff and independently ran the tests.
Fine blueprint stipple is the documented nonblocking mipmap follow-up below.

## Maintainability and remaining scope

First Print controller owns Sequence/persistence gate; passive compositor owns visual
registration only. Alpha bounds are cached per texture/region, not scanned every frame.
The accepted shared shader defaults remain stable. No Rules, Store, old Main, default
entry or export settings changed here.

The shell outside Forge is still explicitly unaccepted scaffolding. Its route
rendering, logical request lifetime, safe areas, Back/modal behavior, Team/Kit and
Settings are corrected in `team-prototype-collection-native-completion-20260913.md`.
Current basic scaffold assertions do not imply those features have full acceptance.
Actual mipmap preparation for fine blueprint linework is part of that next checkpoint.
No150/tall layout, physical Android input/performance or full new battle is claimed.

Exact approved TM-R1 master was copied to the internal runtime family:2390727 bytes,
SHA-256 `585346089AFA79794752A8B79B98A83A2F1FBD6D68C87C10A59287FFA89EEB60`,
matching the approved durable source. Other new art was not generated or substituted.
