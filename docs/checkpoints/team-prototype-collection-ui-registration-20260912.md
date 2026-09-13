# Collection native registration addendum

Primary records the read-only UI audit of the approved M0 atlas. Rects below are
`x,y,w,h` in the uniformly fitted941x1672 layer. Native labels/control states remain
separate. These measurements are implementation inputs, not native/device sign-off.

## Starter / Inspect

Master: `assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png`.

| Owner | Rect |
| --- | --- |
| Blueprint ink | 261,278,418,418 |
| Header | 245,193,451,56 |
| Name | 247,737,448,49 |
| Type/rarity | 247,796,448,42 |
| Voucher/status | 247,850,448,42 |
| Previous / Next | 25,920,183,106 / 733,920,183,106 |
| Back / Inspect | 75,1120,266,140 / 600,1120,266,140 |
| Choose | 70,1292,800,157 |

Use approved transparent blueprint ink, not raw/living portraits. Inspect and
confirmation reuse this master; confirmation hides arrows/Inspect. No extra panel.

M0 defines150% CSS only for three battle representatives, not these route families.
Start native150% with39.21px font/42.48px line height and the same art seats. Type
becomes `(247,790,448,50)`, voucher `(247,844,448,58)` with concise text. Verify all
three names at576wide and tall; these overrides are derived, not previously approved
native evidence.

## First Forge

Master: `assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png`
(941x1671 source intentionally fits941x1672 as M0).

| Owner | Rect / position |
| --- | --- |
| Back | 29,33,134,80 |
| Chamber clip | 142,317,498,631 |
| Cinderpaw front sprite | 291,595,225,301; planted root about403.5,874.1 |
| Scan | x291,width225,height3; alpha-aware scanY |
| Moving guide / head | 145,scanY-149,490,139 / 421,scanY-160,78,163 |
| Parked guide / head | 145,359,490,139 / 421,332,78,163 |
| Guarantee/current/guarantee blueprint docks | 127,1065,150,150 / 397,1065,150,150 / 665,1065,150,150 |
| Left / center / right plates | 93,1353,224,149 / 359,1353,224,149 / 626,1353,224,149 |

Guarantees come from the selected starter, never hard-coded Aquafin/Mossmunk for every
choice. Center plate is the single action/status owner: Start Free Print, progress+
Skip, Saving Print, Retry Save, or Skip Animation. At150%, each149px plate fits three
42.48px lines. Full native accessibility text retains name and save consequence.

The old ArcaneForgeStage uses incompatible chamber/bed/hardware coordinates and a
different raw-source registration. Do not drop it in unregistered or change its old
global constants. Primary decision: create a small shared prototype print compositor
under `scripts/team_ui/`, used by first Forge and battle printers, taking explicit
texture/frame/root, aperture, raw-progress, living-transition and hardware geometry.
Reuse the facing cache, existing raw-filament/blueprint shaders and the Stage's proven
alpha-aware reveal approach, with cached source bounds calculated only on subject
change. This matches M0's use of the front-facing Cinderpaw sheet for first Forge and
keeps raw and awakened silhouettes identical. Source root metadata differs by species;
align each to the same physical bed without scaling it to fill the whole chamber.
No whole old Forge screen or legacy commit callback is a dependency.

Keep ArcaneForgeSequence for first-print timing/commit gates as described in the
native UI plan. Battle uses its accepted receipt/cursor clock, not another sequence
that can commit authority. Before Start/0% the bed is empty except its small seed.

## Grant and Result

Master: `assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png`.

| Owner | Rect |
| --- | --- |
| Back | 25,22,118,100 |
| Title | 230,90,480,58 |
| Receipt heading / body | 188,355,565,58 / 188,425,565,130 |
| Grant cards1/2/3 | 153.6,833.6,163.4,145.5 / 377.4,833.6,174.9,145.5 / 609.3,833.6,191.2,145.5 |
| Support Kit | 210,1016,240,180 |
| Continue | 616,1300,268,300 |

Normal grant icon52.3x70.2 centered at localy16.3; native caption at localy86.6,
height58.8, font26.1/line29.4. Derived150% override: icon36.6x49 centered at localy5,
caption localy57,height86,font39.21/line42.48. Verify every two-line name/status.
Do not use PhysicalResultReceiptComponent's legacy Main/unified-rule/HUD callbacks
or its mismatched normalized bays. Use native labels and transparent hardware hits.

## Recovery

Master: `assets/ui/physical_ui/m3/SY-02-recovery-ledger-text-free-v2.png`.
Back `(29.40,32.68,133.96,78.50)`; message `(94.75,290.77,751.50,236.89)`;
action `(156.83,1279.83,287.50,148.73)`.
View Details replaces text within the same bounded owner and becomes Close; Back
remains available. No reset/repair button. At150%, message can hold five42.48px
lines and button three. Use concise visible reason and full accessible detail.
Do not reuse the legacy recovery renderer wholesale.

All new derived150% cases require actual576x1024 and720x1600 captures: Starter
type/voucher, full names, Forge plates, all three receipt captions and future/corrupt
recovery detail. This fills approved composition interactions, not a new art gate.
