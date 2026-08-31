---
name: printforge-autonomous-godot
description: Build and review PrintForge through approved design, Godot implementation, visual evidence, maintainability review, and Android-safe delivery.
---

# PrintForge Autonomous Godot Workflow

Use this repository-local skill for every PrintForge feature after the preproduction
gate. It extends `godot-production-workflow`, `screen-first-game-ui`, `imagegen`, and
`portrait-admob-layout`; read each applicable skill before the corresponding work. It
does not authorize gameplay-code work before a decision-complete feature brief exists.

## Required sequence

1. `gameplay_designer` updates relevant Markdown design and checkpoint documents with
   Entry, Player decision, Result, Failure, Disabled, Feedback, and Progression. This
   role never edits runtime code or assets.
2. Sol inspects architecture and the working tree, resolves product decisions, and
   sends `terra_implementer` one bounded, decision-complete implementation task.
3. Terra is the only writer of gameplay code, Godot scenes, runtime assets, and asset
   integration. Terra validates and reports commands, evidence paths, PIDs, and risks
   without staging or committing.
4. `ui_reviewer` remains read-only. It compares original-resolution captures with the
   approved concept direction and returns prioritized findings plus text-free ImageGen
   briefs. It does not authorize runtime asset promotion by itself.
5. Terra makes accepted corrections, including only reviewed runtime-art integration.
   Dynamic text, values, tooltips, focus, accessibility, and state remain native Godot.
6. At every milestone boundary Sol performs a maintainability audit. Terra executes
   the bounded refactor; Sol reviews the diff and regression evidence.
7. Sol validates, stages, and commits the checkpoint.

Use only one runtime writing agent at a time. Preserve rejected and untracked concept
drafts. Pause only for a missing authority, destructive action, unsafe external state,
or an irreconcilable product decision.

## PrintForge visual and interaction contract

- Portrait only: review at 576x1024, 720x1280, and a tall Android fixture.
- Generated masters establish static composition and materials only; dynamic text and
  interactive states are native controls. Never draw a runtime duplicate over baked art.
- Native Android bottom AdMob owns creative and bottom safe inset outside the Godot
  surface; production game-content reserve is zero. Keep positive reserve fixtures
  explicitly labelled synthetic overlay stress. Never add a duplicate Ad disclosure.
- Keep every touch target at least 48 logical pixels, primary actions at least 56, and
  test 150% text, high contrast, reduced motion, focus, resize, and safe-area changes.
- Reuse approved creature sprite sheets and the exact card back. One animated sprite
  represents one living battlefield unit; print/awaken/attack presentations are finite.
