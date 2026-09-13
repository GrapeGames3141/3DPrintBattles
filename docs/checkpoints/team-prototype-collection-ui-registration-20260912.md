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

## Team / Support Kit exact hardware owners

Additional read-only review resolved these M0 CSS registrations after rejecting the
first native scaffold. They are not a runtime visual pass. All rects remain in the
941x1672 uniformly fitted layer.

- Back occupies the left header plate `(134,158,250,80)`, cream `#fff0c8` with
  dark outline. The right title plate `(557,158,237,80)` uses ink `#231708`.
  Do not add another Back over the lamp.
- Front-idle living mini owners are `(122.54,284.23,104.54,140.50)`,
  `(414.95,284.23,104.54,140.50)`, `(704.72,284.23,104.54,140.50)`.
  Planted roots are `(174.81,417.6)`, `(467.22,417.6)`, `(756.99,417.6)`.
  Apply the audited per-species front root, not the image rectangle bottom.
  These Team bays show printed companions; Starter and Forge docks use blueprint ink.
- Native name owners are `(78.40,428.29,204.27,47)`,
  `(369.61,428.29,204.27,47)`, `(661.14,428.29,205.90,47)`.
  Use centered ink `#20160b`, normal font27. Passive mini/name children do not
  intercept the parent bay hit.
- Four Support chip owners use x71.88/220.58/372.48/524.38,
  widths138.88/143.78/143.78/143.78, y1042.50, height248.40.
  Within those x/widths, face apertures use y1055.57,height104.54; name owners
  y1162.50,height55; count owners y1217.50,height34. Use actual V3 catalog art
  with prototype Data values. Legacy `BattleCatalog.support_card()` lacks three
  prototype IDs and must not silently substitute card backs.
- The magazine `(715.58,1032.94,171.54,281.05)` is already painted. Do not add a
  duplicate card-back rectangle. Its Recommended hit is `(715.58,1228,171.54,80)`,
  cream `#f6e6bd` with dark `#1a0d04` outline. Recommended changes draft only.
- The derived page readout is `(245,880,453,92)` between the previously registered
  studs. Page2 shows the fifth type in slot1; other slots remain physically empty.
- Apply and Cancel use their existing registered rects, normal font27, cream
  `#fff6d5` with dark `#2a1608` outline2. High contrast uses white and outline3+.
  Plain cream without outline is insufficient on these light physical controls.

First-draft captures at `build/evidence/team-battle/20260912-231216-2c4aad3a6daf4570b47d90e9faecf4e2`
were rejected for missing art, wrong physical owners, unreadable control typography,
and false raw-print state. Their successful capture-process marker is not UI sign-off.

## Derived150% Kit and grant fit

Primary accepts the bounded read-only review on2026-09-13. These are display-only
short tokens, never catalog IDs or renamed companions. Normal size keeps full names;
native accessibility/inspectors always retain the complete identity and meaning.
Actual native glyph bounds/captures remain required.

- Keep full Kit chip hits and face apertures. At150%, one-line tokens are RAW,
  HEAT, SUIT, GEM, SURGE (HEAT is deliberately shorter than HEATED in the narrow
  slot). Token owner uses each slot x/width,y1162.50,h49; count owner y1217,h49.
  Both use39.21 font/42.48 line and centered dark parchment ink. Full accessible
  name includes e.g. Heated Spool,2 selected. Page2 reuses slot1 for the fifth type.
- Grant150% icon rects:217,838.6,36.6,49;446.55,838.6,36.6,49;
  686.6,838.6,36.6,49. Caption rects:153.6,890.6,163.4,86;
  377.4,890.6,174.9,86;609.3,890.6,191.2,86. First slot uses CINDER/AQUA/VOLT
  then FIRST; guaranteed slots use CINDER/AQUA/VOLT/MOSS then PRINTED. Full accessible
  identity says chosen first printed starter or guaranteed printed companion.
  Do not add a new tap affordance to a passive receipt icon.
- Verify all three grant mappings and both Kit pages at576 and tall720 with150%
  independent of high contrast. If actual font metrics still overflow, report the
  measured owner/glyph issue; do not silently reduce the requested text scale.
