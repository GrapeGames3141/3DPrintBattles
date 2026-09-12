# Team prototype screen-family drafts — 2026-09-12

Status: **DRAFT PREPRODUCTION ONLY; runtime unapproved.** Two text-free 941x1672
composition masters pass read-only substrate review with no P0. They are not a
complete atlas; full-atlas review and human approval remain pending, so they do not
open the Godot/runtime/build gate.

Authority: [team prototype design](../../design/team-prototype-20260912.md) and
[atlas fixture registry](../../design/team-prototype-atlas-fixtures-20260912.md), with
gate status in the
[preproduction checkpoint](../../checkpoints/team-prototype-preproduction-20260912.md).
Generation briefs and edited-source provenance are in [PROMPTS.md](PROMPTS.md).

## Durable progress

Branch `codex/printforge-team-prototype` has committed rules and fixtures at `270c8d9`
and a reviewed physical-family checkpoint at `1546320`. The current scoped review
and remaining-work record is [REVIEW.md](REVIEW.md); older capture folders below are
historical evidence, not a claim that every current route has passed.
The [offline atlas](atlas.html) and [capture script](render-atlas.cjs) exist and remain
in progress. Source presence and a clean render ledger do not constitute visual PASS.

The current first-session candidate is `v4-starter-forge-576f`: all seven selected
576x1024 captures have the corrected front row, empty bed/nozzle sequence, and native
ink treatment. Read-only UI review found no remaining P0 in these seven normal-size
states:

- [starter choice](captures/v4-starter-forge-576f/starter-choice-576x1024.png)
- [starter inspect](captures/v4-starter-forge-576f/starter-inspect-576x1024.png)
- [voucher / empty bed](captures/v4-starter-forge-576f/starter-voucher-576x1024.png)
- [print early](captures/v4-starter-forge-576f/starter-print-early-576x1024.png)
- [print 60](captures/v4-starter-forge-576f/starter-print-60-576x1024.png)
- [raw complete](captures/v4-starter-forge-576f/starter-rawcomplete-576x1024.png)
- [awaken](captures/v4-starter-forge-576f/starter-awaken-576x1024.png)

Terminal `v3-terminal-results2` geometry/material review passed for
[Win](captures/v3-terminal-results2/win-result-m2-576x1024.png),
[Loss](captures/v3-terminal-results2/loss-result-m2-576x1024.png), and
[Draw](captures/v3-terminal-results2/draw-result-m2-576x1024.png). Loss copy has since
been corrected in source, so its next recapture remains pending; the linked Loss image
is geometry/material evidence, not current-copy approval.

`v5-editor-nav-576c` and battle v3 are rejected historical diagnostics. Their selected
replacements are:

- [Team / Kit six-state family](captures/v6-team-support/): normal-size UI review has
  no remaining P0; [ready Team](captures/v6-team-support/teamvalid-576x1024.png).
- [Workshop / system five-state family](captures/v7-nav-system/): normal-size UI
  review has no remaining P0; [Workshop](captures/v7-nav-system/workshop-prototype-nav-576x1024.png).
- [Battle three-state family](captures/v8-battle-core/): normal-size visual review has
  no remaining P0; [combined Plan](captures/v8-battle-core/combined-second-plan-576x1024.png).
  The auto-replacement rival-hand count needs the semantic correction recorded in
  REVIEW.md, and the remaining battle registry is still being converted.

The [superseded `v1-canonical-final` folder](captures/v1-canonical-final/) is rejected
historical diagnostic material, not the current candidate. The bounded
[v1 populated geometry folder](captures/v1-populated-576f/) is likewise historical
diagnostic evidence only. Full state coverage, 576/720/tall-150% families, complete
read-only visual review, and human approval remain incomplete. No Godot, runtime,
asset-integration, test, build, or export change is claimed.

The two generated `C:` master intermediates were removed only after fresh size and
SHA-256 comparisons matched the permanent committed `E:` masters listed below.

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

## Honest gate state

- Two first-pass draft masters present: PASS.
- Required screen family in the preproduction checkpoint: INCOMPLETE.
- Full empty/populated/error/recovery/Win/Loss/Draw and accessibility state coverage:
  INCOMPLETE.
- Basic battle geometry at `v1-populated-576f`: REVIEWED SUCCESSFULLY, bounded only.
- Current first-session `v4-starter-forge-576f`: normal-576 UI review has no P0.
- Terminal `v3-terminal-results2`: geometry/material PASS; corrected Loss-copy
  recapture pending.
- Team/Kit v6 and navigation v7: normal-576 UI review has no P0.
- Battle v8 three-state family: normal-576 visual review has no P0; rival-hand
  continuity correction and remaining registry coverage pending.
- Complete 576x1024 and 720x1280 families, tall safe-top, 150% text, high contrast,
  and reduced-motion coverage: INCOMPLETE.
- Read-only original-resolution substrate review for the two masters: PASS, no P0.
- Two EQ-R1 equipment drafts: subject/material direction PASS only; baked
  checkerboards and alpha FAIL; offline chamber-mask visual review PASS only;
  runtime use blocked.
- Full-atlas read-only UI review: PENDING on incomplete atlas.
- User atlas approval: PENDING.
- Runtime asset promotion/Godot/build authorization: BLOCKED.

Full-atlas aesthetics remain pending human approval. Preserve these masters and
provenance; do not slice, import, package, or represent them or the current canonical
bundle as approved runtime assets.
