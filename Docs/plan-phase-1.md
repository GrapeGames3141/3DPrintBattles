# Phase 1 — Agentic execution & context preservation

**Purpose:** Keep development continuous, recoverable, and traceable while building *3D Print Battles* in Cursor/Godot.

## Principles

1. **Living roadmap** — Maintain `DEVELOPMENT_PLAN.md` at repo root: break work into small sequential micro-tasks, check items off, add notes when scope or design shifts.
2. **Terminal & Git** — Use the shell for Godot project bootstrap, exports when needed, and **atomic commits** after each coherent unit of work (one component, one system, or one vertical slice), not giant lump commits.
3. **Programmatic UI first** — Prefer building node trees and layout in GDScript to reduce manual `.tscn` churn and merge pain. Use `.tscn` where the editor adds clear value (main scene shell, complex animations).
4. **Placeholder visuals** — Every creature/feature must run without bespoke art: colored `BoxMesh` / `SphereMesh` / primitives when `res://Assets/...` has no model yet.
5. **Handoff discipline** — When context is tight, add short session notes or pointers in `DEVELOPMENT_PLAN.md` / phase plans so the next agent knows current truth.

## Micro-task checklist (ongoing)

| Area | Tasks |
|------|--------|
| **Repo** | Git initialized; sensible `.gitignore`; meaningful commit messages. |
| **Godot** | `project.godot` valid; main scene runs; autoloads wired; version in `application/config/version`. |
| **Plans** | `DEVELOPMENT_PLAN.md` + `Docs/plan-phase-1.md` … `Docs/plan-phase-5.md` kept in sync with shipped behavior. |
| **Quality** | Headless `res://Tests/TestRunner.tscn` after logic changes when feasible. |

## Out of scope for this phase alone

Phase 1 does not replace gameplay design or architecture rules — those live in Phases 2–5. This phase is **how** we work, not **what** we ship.

## Implementation checklist (living)

- [x] Git repo + Godot 4.3 project boots to `Main.tscn`
- [x] `DEVELOPMENT_PLAN.md` + phase plans (`Docs/plan-phase-*.md`) maintained
- [x] Core autoloads wired (`EventBus`, `GameState`, `SaveSystem`, `UnitDatabase`)
- [x] Headless test runner `res://Tests/TestRunner.tscn` + `Tests/unit_tests.gd`
- [ ] Every merge: run headless tests locally (policy)
- [ ] Optional: pre-commit hook calling tests

## References

- Root tracker: `DEVELOPMENT_PLAN.md`
- Tests: `README.md` (headless command)
