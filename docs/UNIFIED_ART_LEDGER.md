# Unified Battle Art Ledger

| Asset group | Delivery | Runtime use | Status |
|---|---|---|---|
| Daily Arena | `assets/ui/battle_backgrounds/daily_arena_{landscape,portrait}_v1.png` | Daily Training | reviewed |
| First Layers | `first_layers_{landscape,portrait}_v1.png` | Workshop Trials tier 1 | reviewed |
| Element Bench | `element_bench_{landscape,portrait}_v1.png` | Workshop Trials tier 2 / Local | reviewed |
| Reinforced Run | `reinforced_run_{landscape,portrait}_v1.png` | Workshop Trials tier 3 | reviewed |
| Masterwork Circuit | `masterwork_circuit_{landscape,portrait}_v1.png` | Workshop Trials tier 4 | reviewed |
| Primordial Proof | `primordial_proof_{landscape,portrait}_v1.png` | Workshop Trials tier 5 | reviewed |
| Existing creature cards | catalog sprite sheets under `assets/creatures/2d/` | starter, library, and inspector creature presentation | existing approved project art |
| Embermoth | `art-source/retired-runtime/cards/creatures/embermoth_v1.png` | retired: no v3 catalog creature resolves this art | built-in image generation, visually reviewed |
| Ripplehorn | `art-source/retired-runtime/cards/creatures/ripplehorn_v1.png` | retired: no v3 catalog creature resolves this art | built-in image generation, visually reviewed |
| Geargecko | `art-source/retired-runtime/cards/creatures/geargecko_v1.png` | retired: no v3 catalog creature resolves this art | built-in image generation, visually reviewed |
| Lumilynx | `art-source/retired-runtime/cards/creatures/lumilynx_v1.png` | retired: no v3 catalog creature resolves this art | built-in image generation, visually reviewed |
| New equipment / spell / refill cards | reusable category frame and rules presentation | unified catalog | intentionally shared presentation; no individual raster illustration yet |

The six environmental master plates were generated with the built-in image workflow, copied from generation cache into durable `E:` project storage, and visually inspected. Portrait plates are centered local crops of their reviewed landscape masters made by `tools/build_portrait_battle_backgrounds.gd`; they are project-bound assets, not stock or placeholder art.

Creature card art is complete for the four new creature IDs. Equipment, spell, and refill cards currently use the same category presentation in the compact shell; that is an explicit reusable presentation choice, not a claim of per-card illustration coverage.
