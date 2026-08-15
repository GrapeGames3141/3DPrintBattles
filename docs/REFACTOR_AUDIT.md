# Checkpoint 7 refactor audit

## Completed behavior-preserving cleanup

- Removed unused caller-supplied `price` parameters from the three GameManager
  progression methods. ProgressionRules remains the single catalog-authoritative
  source for blueprint and print prices.
- Removed dead printer commit-success state and unused private GameManager
  instance/armor helper implementations.
- Reused `ProgressionRules.armor_def()` for BattleState loadout armor lookup.
- Added Main's typed `navigate_to(target: String)` helper and routed simple
  screen-only callbacks through it. Callbacks that also reset state or award a
  reward remain explicit.

## Deferred higher-risk cleanup

- Split the large Main presentation/controller into focused screen components.
- Replace dynamic Dictionary profile/battle state with typed models.
- Keep a persistent Arcane Forge widget instead of rebuilding it during full
  Main renders.
- Split the capture harness into small screen-specific scenes/process drivers.

These are intentionally deferred because they touch UI lifecycle, save data, or
capture evidence more broadly than the checkpoint 7 cleanup contract.
