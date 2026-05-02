# Phase 2 — Engineering standards & architecture

**Purpose:** Keep the codebase maintainable and portable as the game grows beyond MVP.

## Environment note (reconciled with this repo)

The master prompt targets **Ubuntu 24.04 + HTML5** for lab workflows. **This project currently prioritizes Windows** day-to-day (`DEVELOPMENT_PLAN.md`). Treat Linux/HTML5 as **export/readiness** goals without blocking Windows iteration; keep FUSE/AppImage notes in `README.md` for contributors on Linux.

## Architecture goals

1. **No god classes** — Split responsibilities: data (`UnitDatabase`, JSON), rules (`GameRules`, `BattleResolver`), session (`GameState`), persistence (`SaveSystem`), UI screens.
2. **Events / signals** — Use `EventBus` or direct signals for cross-screen flows; avoid hidden singleton mutation from distant callers without a clear owner.
3. **SOLID-ish GDScript** — Small functions, single responsibility, extract shared math and parsing (DRY).
4. **Responsive UI** — Anchors, containers, minimum touch targets; safe in portrait and landscape (Android later).
5. **Input isolation** — Centralize or clearly separate mouse, touch emulation, and future gamepad so battle targeting stays one code path where possible.
6. **Optional platform folders** — When Steam/Android wrappers appear, keep them at boundaries (IAP, cloud, overlay), not inside pure battle math.

## Asset pipeline

- **Scalable drop-in layout** — e.g. `res://Assets/Prints/<unit_id>/` for meshes/textures; code falls back to primitives if files missing.
- **Blueprint vs physical unit (design target)** — Long-term: **`PrintInstructionResource`** (shop blueprint / owned recipe) vs **`PrintUnitResource`** (spawned combat entity). MVP may implement this implicitly via JSON + runtime dictionaries; formalize resources when Stage 2+ adds inventory depth.

## Checklist (incremental)

- [ ] Document folder conventions under `res://Assets/` when art pipeline stabilizes.
- [ ] When splitting blueprint vs unit, add tests for load/save and shop grants.
- [ ] Revisit HTML5 export preset when gameplay is stable enough to justify web QA.

## Implementation checklist (living)

- [x] Modular split: `GameRules`, `BattleResolver`, `SaveSystem`, screens — no single god script for gameplay
- [x] Signals for screen flow (`HubScreen`, `BattleScreen`, `TitleScreen`, `Main`)
- [x] Title Options persist audio prefs; runtime **Music** / **SFX** buses (`Systems/AudioSettings.gd`) + mute apply on title / session load
- [x] Touch emulation enabled in project for mobile-shaped UI testing
- [ ] Dedicated `res://Assets/Prints/` conventions doc + sample folder layout
- [ ] `PrintInstructionResource` / `PrintUnitResource` split (Stage 2+)
- [ ] Gamepad focus neighbors on title/hub (accessibility)

## References

- Rules single source: `Systems/GameRules.gd`
- Battle math: `Systems/BattleResolver.gd`
