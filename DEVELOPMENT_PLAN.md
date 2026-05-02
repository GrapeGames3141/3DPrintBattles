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
- [x] Title Screen: **single local profile** (Hearthstone-style: **Continue / New Game / Options / Quit** — no multi-slot columns). Continue disabled until `profile.json` exists; New Game confirms overwrite if a save exists; Options = audio toggles + optional wipe-all-progress (still uses `local_settings.json` for prefs readable before loading adventure).
- [x] Save data model: coins, owned blueprints, active team, upgrades, progress, settings
- [x] Hub room MVP: Shop terminal, Battle terminal, Team manager (stats on roster rows), Slicer upgrade (filament cap), hub stats show team size
- [x] Battle terminal gated: require starter + ≥1 unit on active team (`GameRules.can_enter_battle`)
- [x] Shop MVP: 5 random blueprints per launch (seeded) + purchase flow
- [x] Starter choice: pick 1 unit (Arcade Unicorn / Spectral Pup / Cookie Cat) without granting blueprint — cards load stats from `units.json`
- [x] Battle MVP: 4x2 grid per side, summon units from hand, basic AI, simultaneous resolution
- [x] Post-match: coin payout winner/loser, return to hub
- [x] Battle: player attack targeting (unit → enemy slot or Core) + shared `BattleResolver` math
- [x] Battle: TPU dodge (MVP evasion vs direct hits)
- [x] Battle: coin-toss intro overlay (first player) before turn 1
- [x] Mobile MVP: emulate touch-from-mouse for desktop testing; larger grid cells on small viewports
- [ ] HTML5 export readiness pass (optional; not required for Steam/Android)
- [x] Linux dev note: AppImage `libfuse2t64` dependency instructions (see `README.md`)
- [x] Testing: add headless unit test runner + run it before each commit
- [x] Testing: smoke test (save + starter + battle-ready team data)
- [x] `Systems/GameRules.gd` — single source for shop price, offer count, team cap, battle payouts, upgrade costs, **MVP roster size** (first N units in JSON for shop/AI) (with unit tests)
- [x] Title audio toggles → **Music / SFX buses** + mute apply (`Systems/AudioSettings.gd`, wired from `Main` + title Options)
- [ ] **Policy:** each new gameplay/economy feature must add or extend a test in `res://Tests/run_tests.gd` and be run headless before merge
- [ ] Steam: Steamworks integration plan (GDExtension / addon) + depot layout
- [ ] Android: export preset + release signing + Play internal testing track

### Active blockers
- None

### Title / first-run UX (MVP design)
- **One adventure per device** for the MVP: `user://Saves/profile.json` is the only campaign save. **Legacy** `slot_1.json` is **migrated once** on boot if `profile.json` is missing, then removed.
- **Hearthstone-like** main menu: vertical primary actions, no “pick slot 1/2/3” grid. **Game version** from `ProjectSettings` → `application/config/version` (see `project.godot`).
- **Options** on the title are **local** (music/SFX) and apply on Continue / New Game; New Game seeds the in-save `settings` from the same local prefs so a fresh run matches what the player chose on the title.

### Notes / constraints
- **Master-prompt phase plans** (agent workflow, architecture, combat contract, staged roadmap, data schema): `Docs/plan-phase-1.md` through `Docs/plan-phase-5.md`.
- Prefer code-driven UI + node trees to minimize fragile `.tscn` spam.
- Always run even with no art/audio: generate primitive meshes + simple materials.
- All unit roster must load from JSON: `res://Data/units.json` (no hardcoded roster in scripts).
- **COPPA / kid-safe**: if you add multiplayer or accounts, architect chat-free or heavily moderated flows before Steam/Android social features.
- **Godot / GDScript**: Project targets **4.3** (`config/features`). Prefer **explicit types** where values come from `Variant` (`Dictionary.get`, `JSON`, `min`/`max`) so strict warnings stay clean. Untyped `signal` args kept for broad compatibility. Avoid C-style `?:`; use plain `if` / `else` blocks (no inline `a if b else c` on older parsers).
- **Tests:** Run `res://Tests/run_tests.gd` headless (see `README.md`) after logic changes. Put balance rules in `GameRules` / `BattleResolver` when possible so they stay testable without scenes.
