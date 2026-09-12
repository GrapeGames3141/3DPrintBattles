# Team prototype screen-family drafts — 2026-09-12

Status: **DRAFT PREPRODUCTION ONLY; runtime unapproved.** Two text-free 941x1672
composition masters pass read-only substrate review with no P0. They are not a
complete atlas; full-atlas review and human approval remain pending, so they do not
open the Godot/runtime/build gate.

Authority: [team prototype design](../../design/team-prototype-20260912.md) and
[preproduction checkpoint](../../checkpoints/team-prototype-preproduction-20260912.md).
Generation briefs and edited-source provenance are in [PROMPTS.md](PROMPTS.md).

## Draft masters

| Master | Bytes | SHA-256 | Intended composition role |
|---|---:|---|---|
| [BA-R1 team autobattle chassis](BA-R1-team-autobattle-chassis-text-free-v1.png) | 2,068,110 | `F967088054521889012A5C63D989DE74EA71AB8AA4DB644709CD65918977EA99` | Empty battle chassis: two printers, two reserve bays per side, central active battlefield, bottom hand/action framing |
| [TM-R1 team/support workbench](TM-R1-team-support-workbench-text-free-v1.png) | 2,390,727 | `585346089AFA79794752A8B79B98A83A2F1FBD6D68C87C10A59287FFA89EEB60` | Empty Team/Support workbench: three companion bays, central native-content panel, four visible hand slots, closed deck, bottom actions |

Both files were generated on 2026-09-12 with built-in ImageGen as edits of existing
approved-family sources. Both are 941x1672 portrait PNGs and contain no intentional
text, creature, card-face, HP, filament, queue, status, or button label content.

## Ownership and reuse inventory

The draft PNG owns only static navy/brass/wood scenery, framing, printer shells, empty
bays, empty plates, and fixed workshop objects. Runtime/native UI must own all names,
values, cards, creatures, blueprint/license/print states, Team 3/3, Kit 15/15, hand,
FIFO, filament, forecast, focus, disabled reasons, actions, errors, accessibility text,
and animations. Do not draw a runtime duplicate over a baked object.

Edited composition sources:

- Battle: `docs/art/m11-living-battles-20260908/battle-continuous-floor-master-v1.png`
- Team/Kit primary edit target:
  `assets/ui/physical_ui/m3/DK-01-deck-workbench-text-free-v2.png`
- Team/Kit supporting material/bay reference:
  `docs/art/team-prototype-20260912/BA-R1-team-autobattle-chassis-text-free-v1.png`

Planned existing runtime reuse, after atlas approval only:

- `assets/creatures/2d/battle-facing/` — existing approved 23-species directional
  sheets; prototype M1 initially permits only the eligible common cohort.
- `assets/creatures/2d/voltwig_sprite_sheet.png` — named legacy Voltwig exception.
- `assets/creatures/2d/raw/` — existing raw-print stages.
- `assets/creatures/2d/blueprints/v2/` — current blueprint art and manifest.
- `assets/cards/support_card_back_source_v1.png` — exact existing support-card back.
- `assets/cards/support_cards_resources_source_v1.png`,
  `support_cards_offense_source_v1.png`, and
  `support_cards_defense_source_v1.png` — catalog-aligned kit art sources.
- `assets/cards/v3/` and `data/v3/catalog.json` — existing card identity/art lookup;
  the prototype uses a separate eligibility/cost table and does not rewrite catalog
  values or effects.

No source asset is copied into these masters as dynamic populated content. Reuse means
native/runtime placement later, after approval.

## Honest gate state

- Two first-pass draft masters present: PASS.
- Required screen family in the preproduction checkpoint: INCOMPLETE.
- Empty/populated/error/recovery/Win/Loss/Draw and accessibility state coverage:
  INCOMPLETE.
- 576x1024, 720x1280, tall safe-top, 150% text, high contrast, and reduced-motion
  capture family: NOT RUN; these are source masters, not runtime captures.
- Read-only original-resolution substrate review for the two masters: PASS, no P0.
- Full-atlas read-only UI review: PENDING on incomplete atlas.
- User atlas approval: PENDING.
- Runtime asset promotion/Godot/build authorization: BLOCKED.

Full-atlas aesthetics remain pending human approval. Preserve these masters and provenance;
do not slice, import, package, or represent them as approved runtime assets.
