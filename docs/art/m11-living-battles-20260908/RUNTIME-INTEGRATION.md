# M11-B runtime integration brief

Primary plan after read-only UI/source review; r7 is user-approved. This supplements
[IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md), not a new art direction.

## One geometry owner

Use design space 941x1672. A battle-specific safe content surface must own the stage
and every native control. Fit once with aspect-preserving contain; art, touch and
text use the same transform. Real safe insets and named synthetic tests are distinct.
Do not add AdMob or a banner reserve. Keep walnut/navy edge fill for tall portraits.

- Rival unit envelopes: `(90,380,190,305)`, `(375,380,190,305)`, `(660,380,190,305)`.
- Friendly envelopes: `(60,680,210,305)`, `(365,680,210,305)`, `(670,680,210,305)`.
- HC150: rival y330, friendly y645, height345; captions use 30 design-px equivalent
  and full accessible Attack/Guard names behind abbreviated visible Atk/Grd.
- Sprite bodies use taller non-clipping owners, bottom-center pivots and floor
  shadows; no opaque slot lip or whole-body rectangular selection/impact frame.
  Aquafin's approved relative art size is about1.28 against the other two starters.
- Rival chamber `(55,165,175,148)`; friendly chamber `(55,1260,175,148)`.
- Back `(30,22,128,80)`; title approximately `(294,34,354,68)`.
- Rival/player HP `(324,200,261,49)` / `(324,1240,261,45)`.
- Rival/player resource `(376,285,206,50)` / `(376,1315,206,57)`.
- Status `(241,1075,461,58)`; own blueprint hand `(204,1455,514,145)`.
- Rival backs row `(318,118,330,72)`, exact existing card-back art, actual hand count.
- Run Cycle group `(746,1495,168,157)`; HC y1455. Preserve lever image aspect in
  its 168x114 visual seat, then native caption below; never stretch its skin to157h.
- Secondary physical actions may use lower-left wood x14..193/y1479..1640, without
  colliding with hand, equipment tray or lever. All hit targets >=48 logical pixels;
  primary actions >=56. Preserve full hand horizontal scrolling and duplicate copies.

Coordinates are composition guides, not permission to shrink text below the native
accessibility scale or to clip controls when min-size wins. Verify actual bounds.

## Receipt sequence and one visible owner

Replace Main's timer/continuation/AI duplicate acknowledgments with one finite
presentation sequence. Identity includes battle generation and receipt serial;
acknowledge only the accepted receipt after all beats. Render each beat before any
wait; Back/leave/re-entry and reduced motion cannot submit or repeat authority.

Each touched job uses actual work-before/work-after, including a new partial head
after one or more completions. Preserve partial previews between receipts. Completed
jobs show raw completion, then a single living sprite awakening and leaving the
printer. Conceal their already-authoritative final-slot representation until their
own visual arrival; no early living figure, duplicate or mismatched job identity.

**Runtime continuity correction:** upper wireframe and lower solid MUST use the
same raw geometry source so their silhouettes meet at the scan. The approved r7 HTML
uses a separately posed blueprint illustration above the scan; the runtime corrects
that composition seam rather than reproducing the pose mismatch. Make edge alpha transparent
between technical lines. The shared schematic shader also serves Forge/Starter;
use a battle-specific shader or an opt-in uniform to avoid unintended regressions.
The actual blueprint artwork stays in the hand/inspection UI.

Friendly travel: chamber/launch about `(65,1290,150,170)`, airborne corridor
`(18,960,150,170)`, mat entry `(18,800,150,170)`, then the chosen foot anchor.
Use a side-specific inward rival route, not a lerp through printer housing or status.
Existing frames0–3 are idle; frames4–7 are action/travel. Reuse exact sprites and
equipment raw/finished mappings. Interrupted printing does not awaken/deploy.

Attack presentation replaces the home sprite with its moving owner, makes contact
at a real enemy foot anchor or exposed printer casing, then returns/settles. Retain
the defeated defender through contact. Printer hits require an empty defender field.
Reduced motion uses the settled owner and concise native receipts.

## Native controls and performance

Presentation status precedes required choices and rival resolving status. Keep
printers/HP, own hand, rival backs and Back visible throughout; input locks are native.
Post-print fitting names the ready item and eligible creature, not glow alone.
Use the public expected forecast and qualify hidden interruptions. Do not leak
private hand/deck/trap data. Keep local handoff privacy mapping correct for eitherseat.

Preallocate sprites, atlases, materials, shadows and contact effects. Cache asset and
card resolution by identity. Separate snapshot/geometry/label synchronization from
animation ticks; do not rebuild six captions, reload resources or create nodes each
frame. Keep the stage persistent across shell renders and disable idle processing
when reduced motion has no finite event. Stable-node/texture assertions complement
real capture review, not substitute for it.

## Required runtime evidence

Actual Main -> coordinator -> stage input: early/60%/complete printing for both seats,
multi-job partial/carryover, duplicate card IDs, staging, fitting and interruption,
raw/awaken/launch/airborne/landing, populated3v3, creature and exposed-printer contact,
skip/RM, Back/re-entry and stale callbacks. Capture 576x1024,720x1280,tall-safe and
150%/HC/RM. Repeat cycles without node/material growth. Compare against exact r7 and
obtain read-only UI noP0/P1 before Android review delivery.
