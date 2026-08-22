# PrintForge Legends v3 architecture

## Authority boundaries

- `data/v3/catalog.json` is the shared 57-card v3 catalog contract;
  `scripts/core/v3_catalog.gd` validates and loads it for Godot while backend
  parity reads the same document.
- `scripts/core/unified_rules.gd` owns the catalog-facing profile transitions:
  deck/pre-print validation, collection ownership, market, packs, quests,
  drops, season rewards, and deterministic local commerce.
- `scripts/battle/unified_battle_state.gd` is the plain-data v3 match snapshot.
  It contains revisions, seed, turn/phase, public board data, hidden hands and
  decks, queues, staging, holding, scrap, traps, equipment, and installed
  upgrades.
- `scripts/battle/unified_battle_rules.gd` applies explicit intents and is the
  only layer that resolves match rules. Rejected intents leave state unchanged.
- `scripts/battle/unified_ai_opponent.gd` produces only legal deterministic
  intents from public information plus the AI owner’s hand.
- `scripts/core/game_manager.gd` is the Godot façade: load the clean v3
  namespace, journal accepted profile transitions, construct match launch
  contexts, and settle mode rewards. It does not render UI.

## Presentation boundaries

`scenes/main.tscn` attaches `scripts/ui/main.gd`, a responsive shell that
routes every shipped battle entrypoint to `unified_battle`. The legacy active-
unit renderer is retained only for historical fixtures and has no Workshop
launch route. Battle snapshots contain no UI nodes; player hand/deck and trap
identity are redacted from an opponent view.

`scripts/ui/unified_battle_screen_component.gd` owns the shipped battle screen
composition. The shell remains responsible for navigation, accessibility, and
shared visual helpers. The remaining historical renderer boundary is described
in [LEGACY_RUNTIME_BOUNDARY.md](LEGACY_RUNTIME_BOUNDARY.md).

The primary player-facing surfaces are Workshop, Foundry Battle, deck and
pre-print editor, collection, five-shop market, quest/season, and local
hot-seat handoff. Accessibility settings remain presentation-only.

## Data and assets

Catalog IDs are stable and the v3 runtime derives card fields from the shared
Godot catalog while TypeScript parity remains scaffolded under `backend/`.
Ownership is permanently separate: `owned_cards`, `owned_blueprints`,
`printed_models`, and `gear_loadouts` do not imply one another.

`assets/` is exportable runtime content. `art-source/source`,
`art-source/review`, and `art-source/demo` are editor-ignored provenance/capture content. The runtime
asset manifest names resources loaded through constructed paths, allowing a
test to distinguish supported dynamic art from unused files.

## Validation

`tests/test_unified_rules.tscn`, `tests/test_v3_catalog_contract.tscn`, and
`tests/test_v3_smoke.tscn` form the deterministic CI authority gate. They check
the legal starter deck, Filament Ring’s slotless battle effect, hidden-info
redaction, JSON catalog parity, and the runtime asset manifest.
`tests/test_unified_ui_layout.tscn` exercises responsive hot-seat privacy and
accessible phase controls at portrait and landscape sizes. CI additionally
runs the backend catalog parity test before exporting.

Historical architecture and playtest records are retained in
`docs/archive/0.5-0.7/` and are not implementation authority.
