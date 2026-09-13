# Collection native UI — accepted checkpoint

2026-09-13, `codex/printforge-team-prototype`. Primary reviewed the sole Terra
implementation, its diff, isolated behavior and the read-only UI review. This accepts
Collection presentation, not native Battle, default launch or an Android export.

## Behavior and cleanup

Final independent run:
`build/evidence/team-battle/20260913-024903-55f157ed5be04f598719058bbc32c772`.
469 assertions, zero failures; PID147868, exit0, empty stderr, no task windows or
surviving processes, isolated QA bytes unchanged. The writer's preceding clean run
was `20260913-024814-6e5330d04bcc44fabcccdcf641001545`, PID137104.

Coverage includes actual-pointer first session, exactly-once grants/printing,
active Forge Back/reentry, finite raw/awaken/depart sequence, Team uniqueness and
priority, all five Support types/Kit15 bounds, retained request retries, Settings
type safety/persistence, modal Back/focus, Recovery zero-write behavior, and
576/720 all-inset minimum48px/primary56px target checks.

The earlier469 runs024248 and024423 passed assertions but emitted a CanvasItem and
ObjectDB leak warning. They are **not clean completion evidence**. A verbose run
024601 identified an unattached Control in the safe-area test; the test now frees
it. No production workaround was added. The audited runner now rejects RID/ObjectDB
leak warnings and offers engine-level `-EngineVerbose` for bounded diagnosis.

## Visual acceptance

Read-only UI reviewer found no remaining P0/P1 across these capture directories
under `build/evidence/team-battle`:

| Fixture | Evidence directory | PID |
| --- | --- | --- |
| 576×1024 normal | `20260913-024255-3209c861ebff4eec89f5ffd2f98ca305` |116636|
| 576×1024 150%, no high contrast | `20260913-024039-4a9b9fad372d4e87a75f53f322ac280b` |140512|
| 720×1280 synthetic all-inset | `20260913-024113-3833c02486d942d98f00fad4bab653f3` |147272|
| 720×1600 synthetic all-inset,150%/HC/RM | `20260913-024147-88cde34df6a24d7f9389cc7b45823e48` |134772|

All capture ledgers exit0, unchanged QA bytes, empty stderr, no task windows or
survivors. Synthetic insets are left24/top48/right24/bottom48; they are not physical
Android measurements or an ad reserve. Native game-content AdMob reserve is zero.
The final normal Recovery Details copy supersedes the earlier longer generic copy
in large/tall frames; it is shorter and keeps identical geometry. Pointer-null and
test-teardown fixes are nonvisual. No further capture was required for those changes.

Reviewed states include Starter/inspect/confirm, voucher/0/60/raw/awaken/depart,
Grant, populated and empty Team, selector page2, priority, both Kit pages/inspector,
Settings, Recovery/Details/Leave, real Apply/Settings/Forge save Retry and restored
Back/Apply focus. Previously accepted minor Grant caption-border proximity remains
nonblocking. No art direction changed and no new ImageGen asset was required.

## Maintainability audit

Shell retains route/draft/request lifetime and the persistent FirstPrintController.
Collection, onboarding and system presenters own their actual compositions; shared
Chassis and NativeWidgets own contain-fit, safe conversion and target/text mechanics.
Dead duplicate route renderers were removed. Native settings use checked numeric
types before conversion; request IDs combine timestamp and cryptographic entropy.
Blueprint mipmaps and sprite atlases are cached. Forge per-frame work updates its
existing compositor rather than rebuilding the tree or reopening runtime storage.
Route clearing now nulls only ephemeral compositor/button references, preserving
the controller across Back/reentry. Runtime/Collection remain transaction authorities.

## Next gate

Implement `team-prototype-native-battle-implementation-20260913.md` and its14-case
native acceptance plan, then normal-entry/Android delivery. Do not export historical
Main as the new prototype. No physical Android device evidence is claimed here.
