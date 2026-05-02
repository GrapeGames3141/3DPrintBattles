# Phase 5 — Data-driven creature database (256 units)

**Purpose:** Scale roster, shop, and battles from a **single authoritative data file** (JSON or CSV → JSON), without hardcoding units in scripts.

## Requirements

1. **GameManager / UnitDatabase** loads all units from **`res://Data/units.json`** (or future `.csv` pipeline that generates JSON at build time).
2. **Stable IDs** — Each unit has a machine-safe `id` string used in saves, shop grants, and teams.
3. **Tier taxonomy** — Align with design tiers (Draft → … → Aerospace PEEK / Boss tags). Store tier/rarity as fields for UI filtering and pack weights later.
4. **Stats justification** — Poly-count / complexity fields (or narrative “cost reason”) feed **shop cost**, **ATK/HP**, and balance discussions; keep derivations documented in `GameRules` or data schema comments.
5. **Progressive activation** — Stage 1: first **20** IDs active in rotation/MVP. Stage 2: **~80**. Stage 3: full **256**.

## Schema direction (fields)

Minimum useful columns per unit (exact names follow `units.json`):

| Field group | Examples |
|-------------|----------|
| Identity | `id`, `display_name`, `tier`, `material`, `element` |
| Combat | `cost`, `hp`, `atk`, tags (`starter`, `boss`) |
| Ability | `ability_id` or text hook for future scripting |
| Assets | `model_path` optional; empty → primitive fallback in code |

## Boss / starter flags

Units marked **[STARTER]** or **[BOSS]** in the master list must have explicit flags in data so hub/battle/quests can branch without string matching on names.

## Generation workflow

- **Authoritative list:** Master prompt enumerates 256 creatures with tier and ability blurbs.  
- **Implementation:** Prefer generating/regenerating `Data/units.json` from a script or spreadsheet export so balance passes don’t require hand-editing 256 rows for bulk changes.

## COPPA / kid-safe content

Roster text and ability names stay appropriate for kids; no chat tied to trading (Stage 3 NPC trading stays offline and moderated copy).

## References

- Data file: `res://Data/units.json`
- Loader: `Systems/UnitDatabase.gd`
- Tests: assert parse counts / sample IDs in `Tests/run_tests.gd` as stages expand

## Full roster source

The complete tier-by-tier roster (256 entries) lives in the **master AI generation prompt** / design archive; this repo stores the **subset actually shipped** in JSON. When expanding stages, add IDs in order and update activation filters in code or data flags.

## Implementation checklist (living)

- [x] `res://Data/units.json` array schema + `UnitDatabase.load_units`
- [x] Stable string `id` per unit; lookups via `get_unit`
- [x] Stage 1 activation: **first N** rows only (`GameRules.MVP_ACTIVE_UNIT_COUNT`, `active_roster_for_stage`)
- [ ] Tier/rarity fields used for UI badges + weighted shop (Stage 2+)
- [ ] Scripted abilities beyond MVP placeholders (`ability` column → resolver hooks)
- [ ] Generator script or CSV export when expanding toward 80 / 256 rows
