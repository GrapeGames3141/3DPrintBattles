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
| Persist | Coins, owned blueprints, active team, printer upgrades, progress flags, settings |

### Hub

- Workshop with **Shop**, **Battle**, **Team** (and **Slicer**/filament cap upgrade as implemented).

### Shop

- **5 random blueprint offers** per session (MVP refresh each launch / seeded run).

### Starter choice

- Pick **one** of **Arcade Unicorn / Spectral Pup / Cookie Cat** — physical unit for battles; **blueprint still bought in shop** later.

### Combat

- **One arena**, AI opponent, summon/spend filament/attack, win/lose, return to hub.
- Battle terminal only opens if **starter chosen** and **active team has ≥1 unit** (`GameRules.can_enter_battle`).

### Database (Stage 1 scope)

- JSON loader active for **first 20 creatures** in the roster file for MVP tuning (expand in Stage 2+).

### Exit criteria (Stage 1)

- New player can finish a full loop without crashes; save/load reliable; headless tests pass for documented rules.

---

## Stage 2 — Better (do not start until Stage 1 exit criteria met)

**Goal:** Replayability and breadth.

- Hub: **Terrarium**, **Archive**, **Slicer forge** (deeper armor/upgrades).  
- **~80** active units from JSON.  
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
- [x] Shop: 5 offers / launch, prices from `GameRules.blueprint_shop_price`
- [x] Starter pick (3 starters) — unit on team, blueprint not auto-granted
- [x] Battle vs AI: summon, filament, combat resolution, payouts, `battles_won`
- [x] JSON units; **first `MVP_ACTIVE_UNIT_COUNT` (20)** rows drive shop + enemy RNG (`UnitDatabase.active_roster_for_stage`)
- [ ] Policy: extend `run_tests.gd` for each new economy/combat tweak

### Stage 2 — Better

- [ ] Terrarium, Archive, deeper slicer forge
- [ ] ~80 roster activation + data pass
- [ ] 24h shop refresh + overworld + bosses
- [ ] Educational coin quests + summoning shader polish

### Stage 3 — Betterest

- [ ] Full 256 units + dynamic asset import + silhouette shaders + procedural arenas + offline NPC trade
