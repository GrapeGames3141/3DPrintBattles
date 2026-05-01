## Filament Fighters — DEVELOPMENT_PLAN

**Current phase**: 🟢 STAGE 1 (MVP)

### Progress tracker (microtasks)
- [x] Create `DEVELOPMENT_PLAN.md`
- [x] Scaffold `res://` folder architecture
- [x] Initialize Godot 4 project bootstrap (`project.godot`, main scene)
- [x] Add core autoloads: `EventBus`, `GameState`, `SaveSystem`, `UnitDatabase`
- [x] Title Screen: 3 save slots (New/Continue/Delete) + Settings stub
- [ ] Save data model: coins, owned blueprints, active team, upgrades, progress, settings
- [x] Hub room MVP: Shop terminal, Battle terminal, Team manager, Slicer upgrade (filament cap)
- [ ] Shop MVP: 5 random blueprints per launch (seeded) + purchase flow
- [ ] Starter choice: pick 1 unit (Arcade Unicorn / Spectral Pup / Cookie Cat) without granting blueprint
- [x] Battle MVP: 4x2 grid per side, summon units from hand, basic AI, simultaneous resolution
- [ ] Post-match: coin payout winner/loser, return to hub
- [ ] HTML5 export readiness pass (no platform-only APIs, responsive UI containers/anchors)
- [ ] Linux dev note: AppImage `libfuse2t64` dependency instructions

### Active blockers
- None

### Notes / constraints
- Prefer code-driven UI + node trees to minimize fragile `.tscn` spam.
- Always run even with no art/audio: generate primitive meshes + simple materials.
- All unit roster must load from JSON: `res://Data/units.json` (no hardcoded roster in scripts).

