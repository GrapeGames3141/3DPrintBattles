## 3D Print Battles — DEVELOPMENT_PLAN

**Current phase**: 🟢 STAGE 1 (MVP) — playable loop + test harness

**Active dev / test OS:** **Windows** only for now (editor + F5 play). Cross-platform and store work stay planned; don’t block day-to-day iteration on them.

### Release targets (keep in scope)
Ship on **Steam (PC)** and **Google Play (Android)**. Engine is Godot 4.x; no platform-specific APIs in core gameplay — add Steamworks / Play Billing in dedicated wrappers later.

| Target | MVP note | Later |
|--------|----------|--------|
| **Steam** | Export **Windows** `.exe` + depots; test clean install | Steamworks (overlay, achievements, cloud), Proton/Linux if desired |
| **Android** | Portrait/landscape-safe UI (anchors/stretch); touch-sized controls | AAB, Play Console, signing, data safety form, optional IAP |

### Progress tracker (microtasks)
- [x] Create `DEVELOPMENT_PLAN.md`
- [x] Scaffold `res://` folder architecture
- [x] Initialize Godot 4 project bootstrap (`project.godot`, main scene)
- [x] Add core autoloads: `EventBus`, `GameState`, `SaveSystem`, `UnitDatabase`
- [x] Title Screen: 3 save slots (New/Continue/Delete) + Settings stub
- [x] Save data model: coins, owned blueprints, active team, upgrades, progress, settings
- [x] Hub room MVP: Shop terminal, Battle terminal, Team manager, Slicer upgrade (filament cap)
- [x] Shop MVP: 5 random blueprints per launch (seeded) + purchase flow
- [x] Starter choice: pick 1 unit (Arcade Unicorn / Spectral Pup / Cookie Cat) without granting blueprint
- [x] Battle MVP: 4x2 grid per side, summon units from hand, basic AI, simultaneous resolution
- [x] Post-match: coin payout winner/loser, return to hub
- [x] Battle: player attack targeting (unit → enemy slot or Core) + shared `BattleResolver` math
- [x] Battle: TPU dodge (MVP evasion vs direct hits)
- [x] Mobile MVP: emulate touch-from-mouse for desktop testing; larger grid cells on small viewports
- [ ] HTML5 export readiness pass (optional; not required for Steam/Android)
- [x] Linux dev note: AppImage `libfuse2t64` dependency instructions (see `README.md`)
- [x] Testing: add headless unit test runner + run it before each commit
- [x] Testing: smoke test (save + starter + battle-ready team data)
- [ ] Steam: Steamworks integration plan (GDExtension / addon) + depot layout
- [ ] Android: export preset + release signing + Play internal testing track

### Active blockers
- None

### Notes / constraints
- Prefer code-driven UI + node trees to minimize fragile `.tscn` spam.
- Always run even with no art/audio: generate primitive meshes + simple materials.
- All unit roster must load from JSON: `res://Data/units.json` (no hardcoded roster in scripts).
- **COPPA / kid-safe**: if you add multiplayer or accounts, architect chat-free or heavily moderated flows before Steam/Android social features.
- **Godot 4.0 parse compatibility**: avoid typed `signal` parameters; use `.bind()` instead of lambdas with `:=` default args where older parsers choke.
