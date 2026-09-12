# Team prototype ImageGen edit provenance — 2026-09-12

Status: durable provenance for two first-pass, text-free built-in ImageGen edits. This
record does not constitute visual, product, or runtime approval.

## Shared constraints

- Portrait composition at 941x1672 in the established tactile navy enamel, aged brass,
  cream paper, and warm wood Workshop family.
- Animals and whimsical fantasy printed figurines only when later populated; no
  humans, mechs, spacecraft, sci-fi arena, or generic flat mobile dashboard.
- Output static chassis only: no intentional words, numbers, glyph-like labels,
  creature/card content, HP, filament, queue values, forecast, or accessibility copy.
- Empty native-content regions must remain readable at 576x1024, 720x1280, and tall
  portrait when later overlaid by Godot.
- No runtime promotion, slicing, or package inclusion before complete-atlas review and
  user approval.

Both briefs below are the verbatim built-in ImageGen edit prompts.

## BA-R1 team autobattle chassis

- Date: 2026-09-12.
- Method: built-in ImageGen image edit.
- Edited source:
  `docs/art/m11-living-battles-20260908/battle-continuous-floor-master-v1.png`
- Source bytes: 2,059,907.
- Source SHA-256:
  `0E5A00D26A2EF3D01425EF812B49BD9B3EB43CCCFAAF1FD8535C165E5D7B2259`.
- Output: `BA-R1-team-autobattle-chassis-text-free-v1.png`.
- Output dimensions: 941x1672.
- Output bytes: 2,068,110.
- Output SHA-256:
  `F967088054521889012A5C63D989DE74EA71AB8AA4DB644709CD65918977EA99`.

Verbatim prompt:

> Use case: precise-object-edit. Asset type: text-free portrait 9:16 game battle
> background composition, PrintForge solo creature-team prototype. Image 1 is the edit
> target and approved material/style reference. Preserve its warm wood workbench, navy
> painted printer cabinets, restrained brass hardware, amber workshop lighting,
> continuous dark-blue fabrication mat and readable shallow tabletop perspective.
> Recompose its hardware to support a different battle: ONE active creature per side
> on the central continuous mat and TWO physical reserve staging bays beside EACH
> printer. The two empty printer chambers stay at upper-left and lower-left. Replace
> EACH group of cylindrical spool tanks AND old stacked wide HP-like plaques beside the
> printer with exactly TWO broad, shallow, open wood-and-navy staging bays, each sized
> for one small living animal figurine and each with a small blank brass label lip
> beneath. These are physical shelves/platforms on the table, not trading-card holders,
> cages, pods or digital rectangles. Leave a slim blank instrument strip under each
> paired-bay area for native queue and filament forecast text. No printer health gauge.
> Keep generous clear floor in the central 38% of the portrait for exactly two later
> runtime creatures facing each other; no slots or card frames on that floor. Reserve a
> shallow header and a small physical back medallion top-left, with 4% safe-top breathing
> room. Bottom 18% is an empty leather-and-wood support-card tray wide enough for four
> upright cards plus one large tactile brass pull lever at lower-right; the lever must
> have a broad blank readable label surface clearly separate from its moving mechanism.
> All lower controls remain above 3% bottom safe margin; no ad strip. Keep workshop
> believable and usable at phone size: large broad components, little trim, strong
> contrast. This is one coherent empty static background plate, no creatures, no cards,
> no diagrams, no readable text, no letters, no numerals, no icons, no holograms, no
> sci-fi, no human figures, no mechs, no outer space, no extra printers. Preserve
> original material family rather than fantasy card-game styling.

## TM-R1 team/support workbench

- Date: 2026-09-12.
- Method: built-in ImageGen image edit.
- Primary edited source:
  `assets/ui/physical_ui/m3/DK-01-deck-workbench-text-free-v2.png`.
- Primary-source dimensions: 941x1672.
- Primary-source bytes: 2,370,308.
- Primary-source SHA-256:
  `886F548F6CDF87FEA7BBCFC38FDAAF80A216430D7AF7345B50DD6FF6005B27CD`.
- Supporting material/bay reference:
  `docs/art/team-prototype-20260912/BA-R1-team-autobattle-chassis-text-free-v1.png`.
- Supporting-reference dimensions/bytes/SHA-256: 941x1672 / 2,068,110 /
  `F967088054521889012A5C63D989DE74EA71AB8AA4DB644709CD65918977EA99`.
- Output: `TM-R1-team-support-workbench-text-free-v1.png`.
- Output dimensions: 941x1672.
- Output bytes: 2,390,727.
- Output SHA-256:
  `585346089AFA79794752A8B79B98A83A2F1FBD6D68C87C10A59287FFA89EEB60`.

Verbatim prompt:

> Use case: precise-object-edit. Asset type: PrintForge portrait 9:16 Team and Support
> Kit workbench, one text-free static background master for a mobile game. Image1 is
> edit target; Image2 is supporting approved-material reference for broad wooden
> creature staging bays, navy enamel and brass, not its battle layout. Keep the warm
> walnut workbench, tactile navy-leather folio, brass hinges and lamp atmosphere of
> Image1. Recompose it substantially for a simpler game with a chosen team of THREE
> printed animal companions and a separate FIFTEEN-card support kit. Replace the old
> top 8-card grid with EXACTLY THREE wide open shallow wood-and-navy miniature display
> bays across the upper third, each deep enough to stand a small later runtime figurine
> and each with one generous blank brass label lip below. These are little physical
> platforms, never card frames. Below those platforms, one spacious, calm cream folio
> page occupies the middle third for native selected-companion detail or a native list
> of support recipes and quantity steppers; no drawn rows or baked text. At bottom, a
> physical sliding support drawer with EXACTLY FOUR wide blank card-shaped apertures in
> one horizontal row, and a compact closed navy card magazine beside/above the drawer
> representing the rest of a 15-card kit; DO NOT depict fifteen individual cards.
> Include two broad blank brass/parchment action tabs for native Reset to Recommended
> and Confirm labels, separate from decorative mechanisms, reachable above the lower
> safe margin. Leave top header room with a physical back medallion and two broad blank
> tab seats for Team/Support Kit labels. Strong hierarchy: three obvious creature
> platforms, one broad book detail page, four-card hand preview, generous controls. All
> components must remain usable at 576x1024. Warm amber light, navy/wood/brass palette,
> restrained detail, broad uncluttered surfaces. TEXT-FREE: no readable text, numbers,
> letters, icons, creatures, illustrations, blueprints, card art or card backs. No three
> preprint cards, no eight-card grid, no fifth hand aperture. No modern flat app
> rectangles, no mechs, humans, outer space, sci-fi, holograms, ads or bottom banner
> strip. This is a cohesive game UI plate, not a photograph of a phone.

## Approval boundary

These are two edited-source composition drafts, not the full screen atlas required by
`docs/checkpoints/team-prototype-preproduction-20260912.md`. No read-only UI review or
human atlas approval is recorded here. Exact hashes prove file identity only, not
visual suitability or runtime readiness.
