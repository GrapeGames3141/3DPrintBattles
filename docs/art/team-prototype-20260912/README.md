# PrintForge team prototype — screen-family authoring record

Status: **M0 APPROVED 2026-09-12, candidate `ae8ad71`; M1 implementation authorized. No runtime acceptance claimed.**
Use [the selected-screen index](INDEX.md) to review the candidate and
[the current checkpoint](../../checkpoints/team-prototype-preproduction-20260912.md)
for the authoritative remaining work. These HTML compositions over ImageGen art are
not a playable game, Godot captures, animation tests, or Android/device evidence.

The branch is `codex/printforge-team-prototype`. Its
[design](../../design/team-prototype-20260912.md) and
[fixture registry](../../design/team-prototype-atlas-fixtures-20260912.md) implement the
latest solo three-companion/15-Support/no-printer-HP contract on paper only.
[PROMPTS.md](PROMPTS.md) preserves generation/source provenance;
[REVIEW.md](REVIEW.md) preserves scoped reviews and rejected-draft history.

## Selected evidence

- v4: seven starter/Forge normal states, no-P0 read-only review.
- v6/v19: Team and Kit states, corrected saved-versus-draft values and exact 15 tally,
  no-P0 normal review.
- v7: Workshop/navigation/error/recovery/focus/settings, no-P0 normal review.
- v12: all 35 normal battle/result states, no-P0 review.
- v15: seven independent control-state checks; selected fabrication outline corrected
  and confirmed by read-only UI review.
- v18: all three starter choices and corresponding fixed grant mappings, six passes
  and no-P0 review.
- v20: eight representative screens × three portrait sizes, 24/24 static checks and
  no-P0 fit review. Tall uses a synthetic 24px top inset and inert aspect letterbox,
  not an AdMob reserve or a device-test result.
- v24b: 174/174 static checks, all 58 normal states at three sizes. Its three receipt
  states are superseded by v25 for final paper-contained CTA placement.
- v25: 9/9 receipt checks and final no-P0 UI review; Continue / To Team fits its paper.
- v23c Combined/Swap plus v26b Print60: nine selected 150%/HC/RM images with final
  no-P0 review. Back/Run scale, Ready HP fits, printer markers and Run/Wait stay on
  their physical materials. Earlier v22/v23 Print60 failures are historical only.

The full current candidate is indexed: 174 normal plus nine accessibility images.
The user approved it with “yeah do it” after the final no-P0 read-only review. Historical
v1/v3/v5 and other diagnostic folders are not selected evidence; preserve them without
claiming passes. This is static composition approval, not runtime readiness.

The [offline atlas](atlas.html) is an authoring viewer; its controls display fixture
states, not tested gameplay. The [capture helper](render-atlas.cjs) checks static
geometry, native text, and named fixture/selection states. It cannot establish actual
combat logic, save safety, motion, Android Back, or touch comfort.

## Draft masters

| Master | Bytes | SHA-256 | Intended composition role |
|---|---:|---|---|
| [BA-R1 team autobattle chassis](BA-R1-team-autobattle-chassis-text-free-v1.png) | 2,068,110 | `F967088054521889012A5C63D989DE74EA71AB8AA4DB644709CD65918977EA99` | Empty battle chassis: two printers, two reserve bays per side, central active battlefield, bottom hand/action framing |
| [TM-R1 team/support workbench](TM-R1-team-support-workbench-text-free-v1.png) | 2,390,727 | `585346089AFA79794752A8B79B98A83A2F1FBD6D68C87C10A59287FFA89EEB60` | Empty Team/Support workbench: three companion bays, central native-content panel, four visible hand slots, closed deck, bottom actions |

Both files were generated on 2026-09-12 with built-in ImageGen as edits of existing
approved-family sources. Both are 941x1672 portrait PNGs and contain no intentional
text, creature, card-face, HP, filament, queue, status, or button label content.

## Unapproved equipment drafts

| Draft | Dimensions / mode | Bytes | SHA-256 | Honest status |
|---|---|---:|---|---|
| [EQ-R1 quadruped armor raw draft v1](EQ-R1-quadruped-armor-kit-raw-draft-v1.png) | 1254x1254 RGB | 2,316,973 | `3F929AF4097EBA2C180C6D9506A31EA39BB835955E7B7B896C7A8AD73271F26E` | Subject/material direction PASS only; baked checkerboard; alpha failed |
| [EQ-R1 quadruped armor extraction draft v2](EQ-R1-quadruped-armor-kit-raw-draft-v2.png) | 1254x1254 RGB | 2,201,271 | `99A51C4EFA77BDAB1A82AB5548FC19439CA2CED3283F7F05427357E42D78C36F` | Subject/material direction PASS only; targeted extraction failed alpha; checkerboard remains |

Both were made with built-in ImageGen on 2026-09-12. Their durable `E:` copies freshly
matched the generated `C:` originals by byte size and SHA-256, after which both `C:`
intermediates were removed by exact path. The identity/material reference was
`assets/armor/tiered/cinderpaw_tiered_armor_signature_green_alpha_v3.png`.
`assets/armor/raw/full_suit_raw_print_alpha_v2.png` was rejected as a reusable source
because it reads as humanoid/mech rather than animal/fantasy quadruped equipment.

Neither RGB draft is an actual transparent cutout or runtime-approved asset. Read-only
UI review passed only the quadruped subject/material direction; alpha failed. A
native material mask passed the bounded offline printer-chamber visual review; this
does not make either source a transparent production asset. Exact review scope is in
REVIEW.md. Exact prompts and generation provenance are in
[PROMPTS.md](PROMPTS.md).

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

## Approval boundary

Two text-free masters passed scoped original-resolution substrate review. Their
human approval was recorded on 2026-09-12 for candidate `ae8ad71`; bounded runtime
integration may proceed through the M1–M3 checkpoints.
Dynamic identities, cards, values, text, states, and interaction owners remain native.

The RGB armor drafts below are **not transparent production assets**. Only their
quadruped subject/material direction and the offline chamber-mask composition passed.
Resolve production alpha before runtime use; do not ship baked checkerboard artwork.

No Godot/runtime/build/export/player-save action or new APK/Drive release is claimed.
No-PC/no-backend/no-ads scope remains in force. Full native application accessibility
and physical-device validation remain mandatory later implementation gates.
