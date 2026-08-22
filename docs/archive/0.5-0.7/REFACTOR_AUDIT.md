# Checkpoint 7 refactor audit (archived 0.5–0.7)

> Historical audit for the earlier unified prototype. It is not current implementation authority.

## Completed behavior-preserving cleanup

- Extracted the Printer Bench Blueprint Tray into `BlueprintTrayView`, retaining
  Main's `printer_blueprint_ids()` and `select_printer_blueprint()` facades for
  direct UI tests and existing callers.
- Added `BattleViewComponent` as the rebuildable fullscreen battle shell for
  the summary, action dock, and tactical tabs. `BattleScreenComponent` still
  owns the persistent lazy `BattleSpriteStage`; Main retains intents, AI,
  navigation, and rewards.

- Removed unused caller-supplied `price` parameters from the three GameManager
  progression methods. ProgressionRules remains the single catalog-authoritative
  source for blueprint and print prices.
- Removed dead printer commit-success state and unused private GameManager
  instance/armor helper implementations.
- Reused `ProgressionRules.armor_def()` for BattleState loadout armor lookup.
- Added Main's typed `navigate_to(target: String)` helper and routed simple
  screen-only callbacks through it. Callbacks that also reset state or award a
  reward remain explicit.
- Added `BattleUnitRuntime` as the typed catalog/armor-backed adapter at battle
  create and snapshot-import boundaries. `active_unit()` now remains a pure
  lookup of normalized runtime state rather than normalizing in-place.
- Added a process-wide `CreatureSpriteCache`: imported textures are preferred
  for packed exports, with an editor/capture image fallback. Alpha bounds are
  scanned once per asset path and reused across recreated stages.
- Replaced the counter-only screen lifecycle placeholder with persistent,
  feature-specific Workshop, Battle, and Arcane Forge components. They detach
  their owned presentation node before Main tears down the surrounding shell,
  then reattach and refresh the same instance on the next render.
- Removed confirmed unreachable legacy Workshop, Armor, Deck, and Battle
  renderers. The retained render paths preserve existing screen IDs and state.
- Split capture-mode setup into `tests/capture_feature_setup.gd`, keeping the
  capture scene as a small process/viewport driver.

## Deferred higher-risk cleanup

- Move the remaining surrounding Workshop/Forge markup out of Main. The Printer
  Tray and battle shell now use narrow rebuildable views, while Main retains
  their navigation, action, AI, and reward authority.
- Replace dynamic Dictionary profile and serialized authority payloads with
  complete typed models. `BattleUnitRuntime` is deliberately an adapter so old
  saves, intents, and catalog IDs remain compatible.
- Split `capture_checkpoint2.tscn` itself into separate feature scenes after
  existing retained evidence is retired; setup is already feature-local.

## 2026-08-15 offline QA follow-up

- Added narrow, typed `SupportCardPresenter` and `BattleFeedbackPresenter`
  adapters. Main retains ownership of controls and state, while catalog effect,
  target, outcome, HP, shield, and accessible cue copy is now pure/testable.
- Added `CaptureOfflineQaSetup` for checkpoint-local future-save recovery
  fixture state. The generic capture driver remains the process/viewport layer.
- Added a schema-compatibility seam before migration/bootstrap. Future saves
  remain deep-copied read-only values; the save writer is never called for them.
- Added a deterministic all-roster offline simulation and decoded-source asset
  budget guard. These are structural desktop QA checks, not wall-clock claims.

The remaining monolith, typed-profile, persistent-printer-widget, and broader
capture-scene extraction debt above remains intentionally deferred.

## Text integrity

- Run `tools/check_text_encoding.ps1` from the project root to reject invalid
  UTF-8, replacement characters, and common mojibake lead bytes in project
  GDScript, Markdown, and TypeScript text.

These are intentionally deferred because they touch UI lifecycle, save data, or
capture evidence more broadly than the checkpoint 7 cleanup contract.
