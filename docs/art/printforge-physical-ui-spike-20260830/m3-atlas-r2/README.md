# PrintForge physical UI M3 atlas r2

- Date: 2026-08-31
- Branch: `spike/printforge-physical-ui`
- Generator: built-in ImageGen
- Use case: `ui-mockup`
- Output intent: original-resolution M3 composition and text-free runtime-master candidates
- Canonical size: opaque RGB PNG, `941x1672`
- Runtime status: **not promoted**; read-only original-resolution review is required
- Dynamic ownership: all names, values, cards, creature art, focus, disabled/error
  reasons, progress, receipts, selection, accessibility copy, and ad state remain native
  Godot controls/layers.
- Layout boundary: no game-owned bottom ad reserve. The Android native host owns any
  banner creative and bottom system inset outside Godot.

Built-in ImageGen returned each candidate at `941x1671`. Each durable source below
was normalized to `941x1672` by adding one final bottom row sampled from the existing
bottom-left edge color; no authored composition pixel was cropped or rescaled.

## Candidate ledger

| Candidate | Generator output | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `CO-01-archive-folio-grid-text-free-v4.png` | `exec-5c0f30d1-323b-478a-b21c-b74f7f16ea20.png` | 2,534,630 | `CB86C63DAB77D6F6CF028426CC0A98F6B74B01ED926A98A35A4C1EBD301D2B16` |
| `CO-02-archive-folio-detail-text-free-v3.png` | `exec-a0131e7b-4b37-4d1a-bb2d-69d8bb52443f.png` | 2,492,522 | `F89CB8F9CAF84B292BE12E2422A66F0464A3CEC1EE2A0E7A9A7B12786D3E2CBC` |
| `DK-01-deck-workbench-text-free-v2.png` | `exec-dbc7dc6b-0744-4c5c-84c0-ab2ae9220ae0.png` | 2,370,308 | `886F548F6CDF87FEA7BBCFC38FDAAF80A216430D7AF7345B50DD6FF6005B27CD` |
| `MK-01-supply-cabinet-text-free-v2.png` | `exec-309674dd-7933-4db0-b78b-586ed47df61c.png` | 2,286,953 | `FCD4B0A045DEEF2C701C5EF07D5E376E47CB570A9F9CB9A96735EC5D4E15D8B2` |
| `RW-02-pack-opening-v3.png` | `exec-08ed64f7-4c90-4185-9674-5c64eaeacc72.png` | 2,294,573 | `88100CB06C41E3E9C7996757EC118A4BAE56CF35DD65E633EDCD3FB42F103C25` |
| `BA-05-result-receipt-v4.png` | `exec-b91544b0-fba9-49db-b4ec-501ef7ce2b23.png` | 2,524,092 | `9E436AAF7780EE93EFD62F9B142793BD169E340E02D3F8B4D8789A8EEEDB9D4F` |
| `ST-01-settings-instrument-text-free-v3.png` | `exec-37a36662-e69e-4071-8fba-e76cd6505f39.png` | 2,335,660 | `AA10B51A1DF930BC8032EA4D2A4AF3766E1EF0FDDF55926D61C16AD25CACFE2B` |
| `SY-02-recovery-ledger-text-free-v2.png` | `exec-52aff9d5-6ad5-445f-bcd6-7386257eb521.png` | 2,293,126 | `9D3673D3D8328B40A7746E9EA5C746E9B25FC30BFEF6D366A0CEECC2ED724F0E` |

## Generation briefs

### Archive folio grid

References: `CO-01-collection-archive-v3.png`,
`assets/ui/physical_ui/m1-r2/workshop-archive-folio-v2.png`, and
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`.

Prompt: Create a text-free static `941x1672` Collection Archive grid master as one
coherent open walnut/leather/brass folio in the established maker-workshop family.
Use exactly six empty portrait apertures in a `2x3` grid, a blank search/filter rail,
compact blank status plate, three neutral bottom tab faces, and a separate blank
return socket. Keep critical wells inside `x=52..889`, `y=92..1570`. Remove all
creatures, animals, silhouettes, cards, card backs, element icons, ownership medals,
badges, labels, numbers, logos, watermark, fills, glow, focus, selection, checks,
locks, and ad/disclosure. Use warm walnut, worn brass, navy enamel, cream parchment,
and restrained cyan ambient task light; avoid spellbook/tavern/app-grid drift.

### Archive folio detail

References: `CO-02-creature-blueprint-detail-v2.png`,
`CO-03-card-detail-filter-v2.png`, and `CO-01-collection-archive-v3.png`.

Prompt: Create the matching text-free `941x1672` Archive detail master as the same
recognizable folio, materials, hinge logic, and straight-on camera as the grid route,
not a freestanding easel or generic inspector. Provide one large blank parchment
blueprint/art mat, four blank side inspector/value wells, a shallow neutral filter
tray, a blank close/back socket, and one blank primary route/action socket. Preserve
space for 150% native text inside `x=52..889`, `y=92..1570`. Remove the generic
silhouette, exploded animal drawing, fake card, magnifier, letters, numbers, logos,
watermark, creatures, cards, state icons, ownership, rarity, focus, glow, checks,
locks, and ad/disclosure.

### Deck workbench

References: `DK-01-deck-workbench-v1.png`, `DK-02-preprint-selection-v1.png`, and
`assets/ui/physical_ui/m1-r2/workshop-deck-drawer-v2.png`.

Prompt: Create one reusable text-free `941x1672` Deck Workbench master that owns
legal, editing, Pre-Print, empty, and invalid states without changing object identity.
Use a navy-enamel clipboard on walnut with an upper deck book of empty card-sized
wells, central blank inspector/legality receipt, exactly three empty Pre-Print clamp
wells, a lower pull-out owned-card tray with five neutral wells, three small fixed-deck
slot sockets, one blank primary action socket, and separate blank back/revert sockets.
Support 150% native legality copy inside `x=52..889`, `y=92..1570`. Remove cards,
exact backs, creatures, animal drawings, silhouettes, X placeholders, sliders,
meters, counts, locks, flags, labels, numbers, logos, watermark, selection, focus,
checks, valid/invalid state, and ad/disclosure.

### Supply cabinet

References: `MK-01-supply-cabinet-v1.png`,
`assets/ui/physical_ui/m1-r2/workshop-supplies-tray-v3.png`, and
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`.

Prompt: Create a reusable text-free `941x1672` Supply Cabinet/Market master with one
dominant open walnut/navy/brass cabinet, six large empty product bins, two smaller
utility bins, blank price/owned escutcheons, a neutral resource well, five separated
category selector sockets, one large blank purchase/confirm socket, smaller back
socket, and blank receipt strip. Keep long native copy and actions inside
`x=52..889`, `y=92..1570`. Remove all products, tokens, currencies, coins, gems,
creatures, cards, backs, category icons, prices, ownership, locks, availability,
selection, focus, checks, filled meters, sale tags, vendor, letters, numbers, logos,
watermark, and ad/disclosure; avoid storefront/tavern/app-shop drift.

### Five-dock pack machine

References: rejected `RW-02-pack-opening-v2.png`, `RW-01-pack-counter-v1.png`, and
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`.

Prompt: Replace the three-card pack screen with a practical text-free `941x1672`
five-card reveal machine. Preserve only the roller/press/workbench idea. Provide one
upper packet roller/chute, exactly five complete and unobstructed empty reveal docks
in a shallow `3+2` layout, a wide blank receipt strip, a blank progress well, one
substantial Open lever/socket and a smaller Skip/Back socket. Keep critical wells
inside `x=52..889`, `y=92..1570`; each reveal dock is at least `220x300` master
pixels. Remove cards, backs, faces, packets, creatures, rewards, labels, numbers,
logos, watermark, fills, rarity colors, selection, focus, glow, checks, locks, and
ad/disclosure; avoid three/four-card, Hearthstone/tavern, and clipped-control layouts.

### Result/reward receipt station

References: rejected `BA-05-battle-result-v3.png`,
`assets/ui/physical_ui/m2/battle-chassis-base-text-free-v1.png`, and
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`.

Prompt: Replace the baked creature result scene with a truthful text-free `941x1672`
physical result-and-reward receipt station beside the Workshop printer. Provide a
large blank upper result parchment, exactly five empty reward wells in a `3+2`
layout, one large blank primary action socket, one separate return socket, and only
fixed rollers/hinges/brackets. Keep 150% native copy inside `x=52..889`,
`y=92..1570`. Remove every creature, silhouette, print model, card, reward, coin,
star, XP fill, outcome icon, check, lock, value, label, logo, watermark, state glow,
green success treatment, and ad/disclosure. Do not imply victory or defeat; avoid
fantasy diorama/Hearthstone tableau drift.

### Settings instrument

References: `ST-01-settings-accessibility-v2.png`,
`assets/ui/physical_ui/m1-r2/workshop-settings-dial-v3.png`, and
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`.

Prompt: Create a reusable text-free `941x1672` Settings and Accessibility instrument
master as a navy/brass calibration cabinet on walnut. Provide three section rails,
two large neutral knob wells, two neutral toggle wells, at least six blank cream
label/value plates, a large blank live-preview viewport, one large blank Apply socket,
and separate blank Back/Cancel socket. Make dials/switches imply no value. Keep all
content inside `x=52..889`, `y=92..1570`. Remove letters, numbers, logos, watermark,
speaker/person/monitor/running icons, waveform, ticks, fills, selected values, focus,
cyan focus rings, green success, checks, locks, implied toggle states, and
ad/disclosure; avoid app-list/cockpit/gauge drift.

### Recovery ledger

References: `SY-02-save-recovery-v1.png`,
`assets/ui/physical_ui/workshop-backplate-text-free-v1.png`, and
`assets/ui/physical_ui/title-backplate-text-free-v1.png`.

Prompt: Create a reusable text-free `941x1672` Save Recovery ledger as a calm compact
navy/brass receipt printer on a warm Workshop bench. Provide one large blank
explanation plate, exactly three empty save/revision row wells, a small blank status
well, one large blank Retry/Continue socket, and separate blank Dismiss/Back and New
Maker confirmation sockets. Keep long 150% native recovery copy and controls inside
`x=52..889`, `y=92..1570`. Remove save IDs, paths, arrows, locks/shields, refresh,
checks, module illustrations, selected state, progress fill, lamps, focus, glow,
errors, success, letters, numbers, logos, watermark, and ad/disclosure; avoid terminal,
login, generic error-dialog, and magic-device drift.

## Rejected sources

- `RW-02-pack-opening-v2.png`: only three reveal stations; incompatible with the
  established five-card receipt page.
- `BA-05-battle-result-v3.png`: bakes non-catalog generated creatures and gray models
  into a dynamic result state.
- `CO-02-creature-blueprint-detail-v2.png` and `DK-02-preprint-selection-v1.png`:
  composition references only; their generated creature/animal art is never a runtime
  source.
- `DK-03-invalid-empty-deck-v1.png`, `ST-02-accessibility-preview-v1.png`, and
  `SY-01-state-sheet-v1.png`: state/documentation references only, not separate runtime
  physical owners.
