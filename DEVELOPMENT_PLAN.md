## 3D Print Battles — DEVELOPMENT_PLAN

**Current phase**: **Visual polish & 3D presentation** — gameplay loops and greybox UI are **frozen**: **do not add new hub terminals, quests, or mechanics** until art passes stabilize. Work prioritizes **global UI theming**, **3D battle readability**, shaders/audio polish, and export smoke tests — not feature creep.

**Production pivot**
- **Global theme**: `UiTheme.build_workshop_theme()` assigned to each root screen `Control.theme` in `Main._set_screen` (inherits to all child controls; no `ThemeDB.set_project_theme` in shipping Godot APIs).
- **Battle arena**: `BattleScreen` renders units as **CapsuleMesh / BoxMesh / SphereMesh** in a **SubViewport** + camera/light/floor; element-driven **StandardMaterial3D** colors; grid **Buttons** remain a translucent HUD for input.
- **Boot flow**: `startVideo.*` → **`IntroVideoScreen`** → **`WorkshopLandingScreen`** (3D guild hall, ray pick hotspots) → **Title** via door; monitor/shop require an existing save or toast.

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
- [x] Hub: Shop (24h real-time offer rotation + persisted deals), Battle, Team, **Slicer** (filament cap + **core armor** → bonus Core HP in battles), **Terrarium**, **Archive** (silhouette-style unowned + starter/boss tags), **Learning Quests**, **Overworld** (practice / **Midtown** / **Boss** battle modes), **Offline Trade** (draft blueprint voucher), hub stats show team size
- [x] Battle terminal gated: require starter + ≥1 unit on active team (`GameRules.can_enter_battle`)
- [x] Shop MVP: **6** tier-weighted random blueprints per day (seeded rotation) + purchase flow
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
- [x] `Systems/GameRules.gd` — shop refresh interval, **ACTIVE_ROSTER_CAP (256)**, quest coins, battle payouts, etc. (with unit tests)
- [x] **Phase 5 data scale**: `units.json` core roster + `UnitDatabase` synthetic ids **021–256**; `PrintMeshResolver` + `Assets/Prints/` pipeline; `PrintInstructionResource` / `PrintUnitResource` Resource stubs
- [x] Title audio toggles → **Music / SFX buses** + mute apply (`Systems/AudioSettings.gd`, wired from `Main` + title Options)
- [ ] **Policy:** each new gameplay/economy feature must add or extend a test in `res://Tests/unit_tests.gd` (run via `res://Tests/TestRunner.tscn`) and be run headless before merge
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
- Unit definitions start from JSON (`res://Data/units.json`); missing ids up to **`GameRules.ACTIVE_ROSTER_CAP`** are generated at load so shop/battle always see a full tiered pool (synth rows marked in `ability` text).
- **COPPA / kid-safe**: if you add multiplayer or accounts, architect chat-free or heavily moderated flows before Steam/Android social features.
- **Godot / GDScript**: Project targets **4.3** (`config/features`). Prefer **explicit types** where values come from `Variant` (`Dictionary.get`, `JSON`, `min`/`max`) so strict warnings stay clean. Untyped `signal` args kept for broad compatibility. Avoid C-style `?:`; use plain `if` / `else` blocks (no inline `a if b else c` on older parsers).
- **Tests:** Run `res://Tests/TestRunner.tscn` headless (see `README.md`) after logic changes. Put balance rules in `GameRules` / `BattleResolver` when possible so they stay testable without scenes.
