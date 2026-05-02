# Phase 4 — Staged development roadmap

**Purpose:** Scope control. Ship vertical slices in order; do not build Stage 2/3 systems until Stage 1 goals are stable.

---

## Stage 1 — MVP (current focus)

**Goal:** One tight playable loop: menu → hub → shop/team → battle → rewards → save.

### Menus & save (reconciled design)

The master prompt originally described **three save slots**. **Current product decision:** **one local profile** per device for MVP — industry-standard **Continue / New Game / Options / Quit**, persistent data in **`user://Saves/profile.json`**, with **`local_settings.json`** for title-accessible audio prefs; legacy `slot_1.json` may migrate once. See `DEVELOPMENT_PLAN.md` → “Title / first-run UX.”

| Deliverable | Notes |
|-------------|--------|
| Title | Continue (disabled if no save), New Game (overwrite confirm), Options, Quit |
| Persist | Coins, owned blueprints, active team, printer upgrades, progress flags, settings, shop timestamp + offer ids |

### Hub

- Workshop with **Shop**, **Battle**, **Team**, **Slicer**/filament cap, plus Stage 2 terminals (below).

### Shop

- **5 random blueprint offers**; **24h real-time** refresh (`GameRules.shop_refresh_due`, `GameState.shop_last_refresh_unix`).

### Starter choice

- Pick **one** of **Arcade Unicorn / Spectral Pup / Cookie Cat** — physical unit for battles; **blueprint still bought in shop** later.

### Combat

- **One arena**, AI opponent, summon/spend filament/attack, win/lose, return to hub.
- Battle terminal only opens if **starter chosen** and **active team has ≥1 unit** (`GameRules.can_enter_battle`).

### Database (Stage 1 scope)

- JSON base roster + **synthetic fill** to **`ACTIVE_ROSTER_CAP` (256)** for shop + enemy RNG (`UnitDatabase`).

### Exit criteria (Stage 1)

- New player can finish a full loop without crashes; save/load reliable; headless tests pass for documented rules.

---

## Stage 2 — Better

**Goal:** Replayability and breadth.

- Hub: **Terrarium**, **Archive**, **Slicer forge** (deeper armor/upgrades).  
- **~80** active units from JSON — **superseded by full 256 pool** in this repo (JSON + synth).  
- Economy: **24h real-time** shop refresh; **boss battles** on an **overworld** map.  
- **Educational quests:** math mini-games for coins (kid-safe).  
- Visuals: summoning VFX (e.g. bottom-to-top shader mask).

---

## Stage 3 — Betterest / RC-shaped (later)

**Goal:** Scale toward release candidate quality.

- Full **256** units in data.  
- **Dynamic imports** — auto-discover `.gltf`/`.obj` under `Assets`.  
- **Silhouette shaders** for unowned units.  
- **Procedural arenas** — lighting/floor/prop variety.  
- **Offline NPC trading** — COPPA-safe UI copy, no open chat.

---

## References

- Live task list: `DEVELOPMENT_PLAN.md`
- Balance knobs: `Systems/GameRules.gd`

## Stage checklist — implementation status (living)

### Stage 1 — MVP

- [x] Single-profile save (`profile.json`) + title **Continue / New Game / Options / Quit**
- [x] Hub: Shop, Battle, Team, Slicer filament-cap upgrade
- [x] Shop: **6** tier-weighted offers, prices from `GameRules.blueprint_shop_price`, **24h refresh + persisted offers**
- [x] Starter pick (3 starters) — unit on team, blueprint not auto-granted
- [x] Battle vs AI: summon, filament, combat resolution, payouts, `battles_won`
- [x] Roster: **`ACTIVE_ROSTER_CAP` (256)** via JSON + `UnitDatabase` synth ids
- [ ] Policy: extend `Tests/unit_tests.gd` (via `TestRunner.tscn`) for each new economy/combat tweak (ongoing)

### Stage 2 — Better

- [x] **Terrarium** (owned collection view), **Archive** (full roster; unowned darkened)
- [x] **Learning Quests** — addition / subtraction / geometry rewards (`progress.quests_claimed`; legacy `quest_math_bonus_claimed` for add)
- [x] 24h shop refresh + save-backed offers
- [ ] Deeper slicer forge / armor (beyond filament cap)
- [x] **Overworld** hub entry — gated routes + practice duel → battle (mid/boss previews locked by wins)
- [ ] Summoning shader VFX

### Stage 3 — Betterest

- [x] **256** unit rows in pool (synthetic generation for ids without JSON)
- [x] **Dynamic import hook** — `PrintMeshResolver.try_model_path` + `Assets/Prints/<id>/model.gltf`
- [x] **Archive “silhouette”** — unowned labels modulated dark (shader deferred)
- [x] **Procedural arena** — random battle backdrop tint
- [x] **Offline Trade** — stub panel (COPPA-safe copy; no chat)
