# Phase 5 — Data-driven creature database (256 units)

**Purpose:** Scale roster, shop, and battles from a **single authoritative data file** (JSON or CSV → JSON), without hardcoding units in scripts.

## Requirements

1. **GameManager / UnitDatabase** loads all units from **`res://Data/units.json`** (or future `.csv` pipeline that generates JSON at build time).
2. **Stable IDs** — Each unit has a machine-safe `id` string used in saves, shop grants, and teams.
3. **Tier taxonomy** — Align with design tiers (Draft → … → Aerospace PEEK / Boss tags). Store tier/rarity as fields for UI filtering and pack weights later.
4. **Stats justification** — Poly-count / complexity fields (or narrative “cost reason”) feed **shop cost**, **ATK/HP**, and balance discussions; keep derivations documented in `GameRules` or data schema comments.
5. **Progressive activation** — Stage 1: first **20** hand-authored entries in JSON. **Full pool:** ids **001–256** via JSON + **runtime synthetic fill** for missing ids (`GameRules.ACTIVE_ROSTER_CAP`).

## Schema direction (fields)

Minimum useful columns per unit (exact names follow `units.json`):

| Field group | Examples |
|-------------|----------|
| Identity | `id`, `name`, `tier_*`, `element`, optional **`starter`** / **`boss`** booleans |
| Combat | `cost`, `hp`, `atk`, tags (`starter`, `boss`) |
| Ability | `ability_id` or text hook for future scripting |
| Assets | optional `model_path`; else `PrintMeshResolver` + `Assets/Prints/<id>/model.gltf` |

## Boss / starter flags

Units marked **[STARTER]** or **[BOSS]** in the master list must have explicit flags in data so hub/battle/quests can branch without string matching on names. Implemented as optional JSON booleans `starter` / `boss`; **Starter Choice** uses `UnitDatabase.starter_unit_ids()` (fallback `001–003`).

## Generation workflow

- **Authoritative list:** Master prompt enumerates 256 creatures with tier and ability blurbs.  
- **Implementation:** Hand-authored JSON for core set; **synthetic dictionary** for gaps (`UnitDatabase._synthetic_unit_dict`) until a CSV/export pipeline replaces it.

## COPPA / kid-safe content

Roster text and ability names stay appropriate for kids; no chat tied to trading (Stage 3 NPC trading stays offline and moderated copy).

## References

- Data file: `res://Data/units.json`
- Loader: `Systems/UnitDatabase.gd`
- Mesh path helper: `Systems/PrintMeshResolver.gd`
- Tests: `Tests/unit_tests.gd` (run `res://Tests/TestRunner.tscn` headless)

## Full roster source

The complete tier-by-tier roster (256 entries) lives in the **master AI generation prompt** / design archive; this repo ships **JSON + synthetic padding** to **`ACTIVE_ROSTER_CAP`**.

## Implementation checklist (living)

- [x] `res://Data/units.json` array schema + `UnitDatabase.load_units`
- [x] Stable string `id` per unit; lookups via `get_unit`
- [x] Full activation slice **`GameRules.ACTIVE_ROSTER_CAP` (256)** via `_finalize_sorted_roster`
- [x] Tier fields drive **weighted shop** (`GameRules.shop_tier_weight` / `pick_shop_offer_unit_ids`); UI badges (Archive, etc.) still light
- [x] **`starter` / `boss`** flags in JSON + synth defaults; Archive shows `[Starter]` / `[Boss]`
- [ ] Scripted abilities beyond MVP placeholders (`ability` column → resolver hooks)
- [x] Synthetic generation covers ids **021–256** until a bulk CSV replaces synth rows
