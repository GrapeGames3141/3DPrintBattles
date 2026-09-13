# M3 approved UI reuse audit

Read-only UI reviewer findings, recorded by primary on 2026-09-12. These are inputs
to the later decision-complete runtime task, not implementation or device evidence.
M0 remains approved at `ae8ad71`; do not reopen or regenerate the whole atlas.
User has explicitly held the Android build until Voltwig front/rear art is supplied.

## Exact composition sources and reusable seams

| Route | Composition source | Reuse boundary |
| --- | --- | --- |
| Workshop | `assets/ui/physical_ui/workshop-backplate-text-free-v1.png` | M1 placement/focus helpers and physical navigation; re-register hits against approved 941x1672 atlas coordinates |
| Starter/Inspect | `assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png` | Same desk for Inspect; current blueprint-v2 art/imprint helpers, native names/voucher/arrows/actions |
| Forge | `assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png` | ArcaneForgeSequence/Stage finite phases, alpha bounds, scan/wire/raw/living layers and carriage resources; native dock states |
| Team/Kit | `docs/art/team-prototype-20260912/TM-R1-team-support-workbench-text-free-v1.png` | Promote exact reviewed master; new presenter with physical controls/navigation/imprint, support art and exact card back |
| Battle | `docs/art/team-prototype-20260912/BA-R1-team-autobattle-chassis-text-free-v1.png` | Promote exact master; directional sprite cache, finite visual machinery/shaders only, checked TeamBattle projections and accepted EQ-R1 alpha |
| Result/Starter grant | `assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png` | Physical receipt seating/navigation patterns; native Team Win/Loss/Draw or grant facts, no legacy settlement callbacks |
| Settings/Recovery/Back | Existing approved ST-01 and SY-02 masters | Physical settings/navigation helpers, shared visible/system-Back dispatch; no legacy profile mutation |

The atlas and `render-atlas.cjs` are composition/fixture references, not gameplay
implementations. `docs/design/team-prototype-atlas-fixtures-20260912.md` identifies
fixture truth. Dynamic values, names, status, labels, accessibility copy, focus and
hit targets stay native. Baked static hardware must not receive a second opaque
generic panel or duplicate graphic control.

## Reuse hazards to resolve in the M3 implementation plan

- Existing `PhysicalPortraitPlatePresenter.composition_rect()` stretches screens
  above aspect2.05. Do not carry that into the prototype: approved geometry is a
  uniform 941x1672 contain fit, safe top and inert remaining space.
- Existing Workshop hotspot normalization is 576x928, not the atlas registration.
  Reuse logic, not unverified coordinates.
- Do not use the old DK-01 deck layout, m11 battle chassis, six equal floor-slot
  geometry, legacy 40-card rules or printer-damage public-view adapter.
- Exactly one living Active on the floor and two Ready staging bays per seat.
  Unspent/Printing/Defeated remain native roster records; a Printing creature exists
  only as the current printer head presentation, with no premature finished figure.
  Equipment jobs print equipment, not a creature. Color living figures begin at
  Awaken. Preserve front/rear direction and contact shadows, not card-shaped units.
- Rival hand is exact card backs/count only; no hidden Plan or card identity leak.
- Production bottom ad reserve remains zero. No AdMob/IAP integration is authorized.
- The M1 Coordinator owns authority/cursor. UI never recomputes combat, repeats a
  grant/settlement on animation completion or calls full snapshots every frame.

## First playable capture gate

At 576x1024, 720x1280 and 720x1600, exercise the main routes plus:

- Workshop navigation; Starter choice/Inspect (all identity spot-checks); first
  print60; Awaken; guaranteed receipt.
- Team empty/invalid/valid; Support Kit and excluded ownership.
- Battle preflight/first-print choice, print60, first Active entry, combined Plan,
  equipment auto-fit/fitted, swap, replacement attack/automatic replacement,
  empty-active replenishment and following Plan.
- Win, Loss, Draw, focus sheet and reduced motion; visible Back on every route and
  actual Android Back/lifecycle evidence on the device gate.
- Combined Plan, Swap Plan and Print60 repeated at 150% text/high contrast/reduced
  motion, matching the approved accessibility representatives.

Native animation, physical input, first-session interaction and phone performance
remain separate gates. The offline armor alpha gate is cleared; its actual chamber
placement/reveal still needs captures. No runtime visual pass or release is claimed.
