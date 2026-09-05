# PrintForge M9 printable model plan v1

Status: **DESIGN READY for three creature pilots; corrected animal-barding v2 is
human-approved and controlled equipment-family generation is authorized; runtime
model/alpha evidence remains pending**

Date: 2026-09-04

Authority: `data/v3/catalog.json`,
`assets/creatures/2d/blueprints/v2/manifest-v2.json`, the exact approved M7 blueprint
family, the matching raw-print PNGs and creature sprite sheets, and
`docs/checkpoints/printforge-m9-playable-progression-v1.md`.

This is a design-only checkpoint. It creates no mesh, source art, runtime asset,
scene, import, or gameplay change and makes no Blender, Godot, Android, build, or
device claim.

## Outcome and bounded scope

M9C supplies real, full-volume, rebuildable creature and equipment models for the
existing catalog without turning PrintForge into a manual phase battler or changing
combat authority. The bounded deliverable is:

- three representative creature pilots first: `cinderpaw` (grounded quadruped),
  `aurorawing` (winged quadruped), and `worldcoil` (coiled serpent);
- after the three-pilot gate passes, one source model and one runtime GLB for each of
  the 24 existing creature IDs in exact catalog order;
- under the approved corrected barding v2, one source model and one standalone
  runtime GLB for each of the 11 equipment IDs: five modular animal
  barding suits, five socketed gems, and the printer-side Filament Ring fixture;
- for each equipment ID, one intact blueprint and one raw-print presentation derived
  deterministically from that accepted model, keyed to the existing real catalog
  card. The creature blueprint/raw pairs already exist and remain identity authority;
  their final models must prove coherence with them rather than replace them;
- a catalog-indexed source/export/socket manifest proving identity, rebuildability,
  full volume, budgets, transforms, and compatibility for all 35 card-level models;
- real fitted geometry and semantic sockets. A billboard, crossed cards, sprite
  plane, depth-extruded alpha cutout, camera-facing quad, or hidden 2D duplicate is
  not a model and fails this milestone.

No new creature, human, humanoid suit, mech, card, rule, ad, IAP, server dependency,
or player-trading system is in scope. The approved family describes living fantasy
animals. Crafted-looking plates on Ironmaw, Skyforge, or Pyraxis must remain anatomy
or worn fantasy material: no motors, pistons, exposed gears, robotic joints, cockpit,
or mechanical locomotion may be introduced.

## Evidence audit: what exists and what does not

The M7 manifest proves 24 unique catalog IDs and 24 accepted transparent blueprint
PNGs in catalog order. The workspace also contains a matching raw-print PNG and sprite
sheet for every one of those 24 IDs. The approved 1440x2340 family sheet establishes
distinct silhouettes and the P2 watch groups already disclosed in M7.

Those files are identity and material references, not recoverable 3D geometry:

- the blueprints are single stylized three-quarter/near-profile illustrations, not
  calibrated side/front/top orthographic plates;
- the raw prints are single rendered views with useful layer/material and apparent
  volume cues, but they do not disclose hidden-side topology or measured width;
- the sprite sheets offer multiple poses but no calibrated camera, matching scale,
  or guaranteed turntable angles;
- no `.blend`, `.glb`, `.gltf`, `.stl`, or `.obj` exists under `assets/` or
  `art-source/`; there is therefore no current source mesh, runtime mesh, socket,
  collision mesh, UV set, rebuild recipe, or export proof for any creature/equipment;
- the 11 equipment cards do not have a coherent approved animal-fitting model family.
  The earlier floating humanoid full-suit image is not M9 authority.

Consequently, the approved single view is the silhouette/identity authority only for
the portions it actually shows. It does **not** authorize invented exact chest width,
hidden-side markings, underside anatomy, tail cross-section, wing thickness/fold,
horn divergence, or socket depth. Front/top calibration is genuinely missing for all
24. Production must record those dimensions as `unresolved` until a reviewable
front/top evidence plate or an approved model turntable resolves them; it must never
present an artist's guess as source-measured anatomy.

Concept Fitter is already installed at
`E:/Tools/Blender/blender-4.5.0-windows-x64/portable/scripts/addons/concept_fitter`.
Its guided landmark, silhouette, cross-section, manifest, local rebuild, validation,
and GLB export contract is the authorized fitting path; it requires no download or
cloud reconstruction. The project must still supply its own catalog-indexed manifests
and builders. Any derived front/side/top concept may be used only after it is labeled
an **inference candidate** and reviewed; it is not retroactively measured evidence.

## Production sequence and gates

1. Build the three pilots from named constructive regions and a machine-readable fit
   manifest. Cinderpaw validates ordinary body/leg/tail construction, Aurorawing
   validates feathers/wing clearance and six-limb readability, and Worldcoil validates
   a continuous coiled body, self-contact, and non-quadruped sockets.
2. Render matched-camera comparisons against the approved visible reference, plus
   neutral front, side, top, and eight-angle turntable evidence. Unknown views are
   explicitly labeled `PROPOSED DEPTH`, never `REFERENCE MATCH`.
3. Require read-only visual review with P0 none/P1 none and human acceptance of all
   three pilots before expanding the remaining 21 creatures.
4. Produce the remaining creatures in catalog order, using the archetype learnings
   but retaining each ID's locked features below. Shared topology may accelerate work;
   it may not normalize silhouettes into palette swaps.
5. Use the exact approved corrected barding-v2 direction to pilot one Standard Full
   Suit on Cinderpaw, Aurorawing, and Worldcoil, plus one Iron Gem on the same sockets.
   Controlled family generation is authorized; fit/clearance validation of those
   representatives precedes final promotion of the other four suit tiers and four gem
   identities, without another concept-direction approval request.
6. Model the Filament Ring as a printer-side fixture, not jewelry on a creature. It
   becomes equip-ready after printing under the M9 gameplay contract, then seats at
   its printer fixture socket when its existing battle effect is active.

Creature and controlled equipment-family work are authorized under their recorded
decisions. Prior M7 creature-family and current barding-v2 approvals are already
recorded and must not be requested again. Runtime alpha, models, fit, and promotion
remain separate evidence gates.

### Three-pilot production decision

- **Entry:** The Cinderpaw, Aurorawing, and Worldcoil source/rebuild/export packages,
  evidence views, metrics, and read-only P0/P1 report are complete.
- **Player decision:** The user chooses **Approve**, **Revise**, or **Reject** for the
  exact three model packages and hashes. This is new model authority, not a repeat of
  the already approved M7 blueprint decision.
- **Result:** Approve unlocks the remaining 21 creature builds under this matrix;
  Revise records exact corrections; Reject retains the candidates as history.
- **Failure:** Missing source, mismatched hash, absent evidence view, mislabeled
  inference, P0/P1 finding, ambiguous assent, or partial package produces no approval.
- **Disabled:** Remaining creature production and runtime promotion stay disabled
  until exact pilot approval. Review rendering and correction remain available.
- **Feedback:** The decision record binds source/export hashes, metrics, evidence
  paths, findings, choice, date, and next enabled gate.
- **Progression:** This production decision changes no card, profile, queue, model
  inventory, battle, XP, coins, printer, build qualification, or cloud state.

### Corrected barding-v2 production decision

- **Entry:** The corrected nonhuman barding-v2 concept, exact hash, reviewer finding,
  opaque-checkerboard disclosure, and rejection of the humanoid predecessor are
  presented together.
- **Player decision:** The user chooses **Approve**, **Revise**, or **Reject** for the
  exact corrected concept direction.
- **Result:** Approve unlocks controlled production of the five-suit/five-gem family,
  beginning with the Standard Suit/Iron Gem representative fit. It does not promote
  the concept PNG into runtime.
- **Failure:** Ambiguous assent, changed bytes, missing archetype, humanoid anatomy,
  floating parts, mech language, or unresolved P0/P1 does not confer authority.
- **Disabled:** Runtime promotion remains disabled until model, fit, deterministic
  blueprint/raw derivative, machine-verified RGBA, and package gates pass. Creature
  pilot work remains independent.
- **Feedback:** The record names exact artifacts/hashes, choice, findings, rejected
  predecessor, and next equipment gate.
- **Progression:** Approval changes production authority only; it grants or equips no
  item and changes no stats, currency, save, battle, build, or delivery state.

Decision record: **APPROVED** on 2026-09-04 in the current thread by the user's
statement, “Approve and approve the art too.” The exact approved direction is
`docs/art/m9-equipment-20260904/standard-barding-completed-concept-v2.png`, SHA-256
`8A6DE969B4950E24F7480B2F2D9C32D35E20C54C1DFB9EDA5CE2E095AAAC82B8`.
It approves the connected animal-barding silhouette/material direction and controlled
family generation. The PNG contains an opaque painted checkerboard; approval is **not**
runtime-alpha approval and does not authorize copying those bytes into runtime.

## Constructive model contract

Every creature source is a deterministic, editable assembly with named regions rather
than an opaque one-click reconstruction. The required source package records:

- reference paths and hashes, crop, camera assumption, ground line, visible-side
  authority, unresolved views, and approved review record;
- one neutral, non-action pose with `+Y` up, visual forward along Godot `-Z`, applied
  transforms, origin on the ground/support centroid, and catalog ID as root name;
- named body regions, semantic landmarks, cross-section/ring controls, silhouette
  curves, relational guides, and allowed controls for later correction;
- closed or intentionally thickened manifold volumes for torso, head, limbs, tails,
  horns, feathers, fins, membranes, plates, and accessories; roots overlap or join the
  parent volume so no part floats at any review angle;
- explicit source units and one reviewed `display_scale` in the manifest. The current
  art contains no real-world scale, so no physical centimeter value may be inferred
  from the PNGs;
- clean outward normals, no zero-area faces, no unintended duplicate shells, no
  internal coplanar z-fighting, valid UVs, and material slots named by semantic role;
- a deterministic rebuild entry point or parameter manifest sufficient to regenerate
  the accepted source structure, plus the editable source and exported GLB. A GLB
  alone is not rebuildable evidence.

Each creature package separates `creature_mesh`, `print_plinth`, and
`print_supports`. The latter two are intentional presentation geometry matching the
existing raw-print language: a grounded creature may use a thin build raft, while a
swimming/flying body such as Tidewhale or Voidmanta may use clearly authored support
stems from plinth to body. Supports are continuous full-volume pieces, never mistaken
for anatomy, excluded from creature silhouette/fit metrics, and removable/hidden as a
named group for the clean model preview. This node contract demonstrates printable
construction language but does not certify a slicer, printer, or real material.

### Shared asset budgets

Budgets are hard ceilings for the delivered neutral model, not targets that justify
removing signature features.

| Asset | Triangle ceiling | Material slots | Texture ceiling |
| --- | ---: | ---: | --- |
| Small/medium creature | 14,000 | 4 | two 2048-square sets |
| Complex winged/heavy/coiled creature | 20,000 | 5 | two 2048-square sets |
| Barding suit, standalone | 8,000 | 4 | one 2048-square set |
| Gem, standalone | 2,000 | 2 | one 1024-square set |
| Filament Ring fixture | 4,000 | 3 | one 1024-square set |

One fitted creature/equipment **preview** must remain at or below 26,000 visible
triangles and six simultaneous material slots. Texture reuse across tiers is allowed
when it preserves the approved identity. This is inspection/export guidance, not a
3D battlefield budget: approved combat continues to render animated 2D sprites and
needs no 3D collision mesh. LOD generation is not an M9C deliverable or gate. If a
future separately approved 3D runtime uses LODs, a 45-55% lower level should keep
silhouette delta within 2% of creature image height and may not be a sprite-plane fake.

### Fit metrics

- At the calibrated visible reference view, foreground silhouette IoU must be at
  least `0.88`, and each locked landmark must be within `0.025` of image width/height
  after bounding-box normalization. These metrics diagnose a candidate; the visual
  reviewer may still reject a high-scoring identity miss.
- Front/top views without approved evidence have no fake match score. They report
  bounds, asymmetry, intersections, and `REFERENCE MISSING`.
- Body/limb/tail/wing pieces must have measurable thickness in all three local axes;
  a region whose least principal-axis extent is below 1% of its largest extent is a
  plane-like failure unless it is an intentionally thin feather/fin/membrane. Those
  exceptions still require closed thickness, continuous roots, and correct normals.
- Grounded feet/support coil remain within 0.5% of model height of the ground plane.
  No non-support anatomy penetrates the ground.
- In the neutral pose, no adjacent body parts visibly intersect beyond their authored
  root overlap; no gap at a joined root exceeds 0.5% of model height.
- Equipped shell/strap clearance is 0.5-2.5% of local torso width, never intersects
  eyes, jaw, limb swing corridor, wing root, tail root, fin root, or ground, and never
  floats beyond 3% of local torso width.
- Every named socket round-trips through source and GLB with translation error below
  0.1% of model height and angular error below 0.5 degrees.

## Catalog-indexed creature build matrix

“Uncertainty” is a required evidence label, not permission to invent. All rows share
missing calibrated front/top/hidden-side evidence; the table names the additional
high-risk dimension for each identity.

| # / ID | Locked silhouette and identity | Rebuildable volume recipe | Additional visible-view uncertainty | Fit class / semantic yoke |
| --- | --- | --- | --- | --- |
| 01 `cinderpaw` | Catlike quadruped; very large triangular ears; forehead flame; cheek tufts; arched flame tail; broad paws and chest flame | Ellipsoid head/torso rings; tapered muzzle; four segmented limb tubes and paw volumes; rooted ear shells/tufts; swept tail spline with thick flame lobes | Far ear/legs and exact chest width; flame-tail section and rear clearance | `compact_quad`; neck yoke behind jaw, dorsal plate between shoulders |
| 02 `aquafin` | Low salamander/axolotl quadruped; three swept side gills; dorsal nubs; broad finned tail | Low torso/head rings; short limb tubes; paired closed gill blades; tapered tail spline with thick fin lobes | Gill thickness, far-side count, belly width, tail-fin section | `low_aquatic_quad`; pectoral yoke behind gills, clear tail base |
| 03 `voltwig` | Small rabbit quadruped; tall unequal ears; leaf crown; tiny leaf tail; compact paws | Compact torso/head cells; four short limbs; thick rooted ear shells; leaf crown/tail as closed lobes | Ear separation, narrow chest depth, hidden hind leg | `compact_quad`; low neck yoke below crown |
| 04 `mossmunk` | Squirrel/chipmunk quadruped; curled foliage tail; leaf mantle; rounded ears; cheek stripe rhythm | Compact body rings; short limbs; spiral tail core with layered closed leaf scales; separate rooted mantle lobes | Dense tail layering and hidden curl; mantle clearance | `compact_quad`; shoulder yoke under mantle, rear plate kept off tail curl |
| 05 `frostling` | Foxlike quadruped; long ears; swept ice/leaf crown; layered neck/chest plates; broad leaf-flame tail | Fox torso/head rings; four limb tubes; rooted crown/ruff cells; tapered tail with stacked closed lobes | Far crest, tail width, ruff depth | `compact_quad`; collar/yoke beneath ruff with crown and tail clear |
| 06 `stoneback` | Low tortoise; dominant faceted dome shell; stout scaly legs; small tucked head; segmented tail | Dome shell rings with separate belly volume; head/neck cells; four stout limb tubes; faceted shell plates as joined relief | Shell plan-view width/height, belly and hidden leg placement | `heavy_shell`; dorsal yoke uses shell-safe plate pads, no belly strap assumption |
| 07 `galehopper` | Slender rabbit-deer; very long swept ears; fine legs; spiral cloud tail and hip spirals | Narrow torso/head rings; four tapered limb tubes; thick ear shells; swept tail spline with spiral lobes | Fine-leg spacing, ear divergence, chest depth | `cervid_quad`; light withers yoke, no obstruction of ears/tail |
| 08 `sparkotter` | Long otter body; round head; whiskers; stout paws; lightning-bolt tail tip | Long torso rings; rounded head/muzzle; short limbs; tapered tail spline ending in thick bolt; whiskers as safe tapered tubes | Whisker depth/order, belly width, bolt thickness | `low_aquatic_quad`; pectoral yoke behind jaw, dorsal strap before tail |
| 09 `glassdrake` | Crystalline quadruped drake; faceted head/torso armor; dorsal crystals; long segmented curling tail | Under-body rings plus joined faceted shell cells; four limbs/paws; articulated tail spline; rooted crystal prisms | Hidden facet layout, tail curl depth, crystal divergence | `compact_quad`; yoke indexes under dorsal crystals, keeps tail root free |
| 10 `coralisk` | Salamander/lizard quadruped; branching coral crown; dorsal coral row; fishlike fin tail | Low body/head rings; short limbs; branching coral tubes with fused roots; thick tail fin | Crown branch depth and far branches, tail-fin width | `low_aquatic_quad`; pectoral yoke below crown, sparse dorsal pads between coral roots |
| 11 `runestag` | Small stag; branching antlers; long fine legs/hooves; rune marks on torso; short tail | Cervid torso/head rings; four tapered limbs/hooves; antler branch tubes with buried roots; shallow rune relief | Antler spread and hidden branches; chest width; rune placement on far side | `cervid_quad`; withers yoke below neck, antler/leg clearance |
| 12 `brambleowl` | Upright owl; large circular eyes; hornlike branch tufts; layered feather body/wings; talons | Ovoid torso/head; folded wing shells; layered closed feather cells; two leg/talon tubes; rooted branch tufts | Back profile, folded-wing thickness, rear feather/talon spacing | `perched_avian`; pectoral/dorsal yoke with wing corridor clear |
| 13 `ironmaw` | Low broad crocodilian beast; oversized jaw/teeth; layered fantasy plates; thick segmented tail | Broad torso/head and jaw rings; four stout limbs; tapered segmented tail; overlapping joined plate shells | Jaw/chest width, far teeth, tail sweep depth; crafted plates must not become robotic | `heavy_shell`; shoulder/flank pads between existing plates, jaw/tail clear |
| 14 `aurorawing` | Feathered winged quadruped; beaked head/crest; four grounded legs; large layered swept wings and fan tail | Torso/head rings; four limb tubes; wing spar curves with closed feather cells; rooted neck feathers; fan-tail feather cells | Wing planform/fold, far-wing separation, torso width behind feather cover | `winged_quad`; sternum/withers yoke, mandatory wing-root and four-leg corridors |
| 15 `thunderelk` | Elk quadruped; angular lightning antlers; long legs/hooves; neck armor/ruff; short tail | Cervid rings; tapered limb/hoof tubes; branched antler tubes following bolt silhouette; rooted ruff cells | Antler spread, hidden branch order, chest depth | `cervid_quad`; withers yoke below ruff, no antler/neck obstruction |
| 16 `coalgriffin` | Griffin cub; hooked beak; four paws; folded feather wings; feathered tail tuft | Feline torso rings; beaked head; four limbs; folded wing shell/feather cells; tail spline and tuft | Far folded wing and wing thickness; hindquarter width | `winged_quad`; sternum/withers yoke with folded-wing corridor |
| 17 `tidewhale` | Rounded whale; bulbous head/body; side flippers; dorsal fin; small tail flukes; swirl markings | Continuous whale body rings; thick flipper/fin lobes with buried roots; fluke tail cells; shallow marking relief/material mask | Full body length and plan-view width; far flipper/fluke; underside | `aquatic`; anterior dorsal/pectoral yoke, never a humanoid collar |
| 18 `skyforge` | Living fantasy forge-griffin; beaked head; four taloned legs; plated wings and tail; disc/plate ornament rhythm | Organic torso/head rings beneath joined fantasy plate cells; four limbs; wing spars and closed feather/plate cells; tail fan | Far wing, torso width, and plate layering; absolutely no mechanical joint/gear/motor inference | `winged_quad`; sternum/withers yoke indexed between wing roots |
| 19 `pyraxis` | Crystal-crested feline/drake quadruped; angular ears/crown; side armor facets; long crystal-tipped tail | Feline torso/head rings; four limbs/paws; joined crystal cells; articulated tail spline and closed tip crystals | Far crystal layout, tail depth, torso width under facets | `compact_quad`; shoulder yoke between crystals, tail corridor clear |
| 20 `verdantitan` | Massive rhino-like quadruped; single horn; broad leafy/plate mantle; thick pillar legs; short tail | Heavy body/head rings; four pillar limb tubes; horn cone with buried root; layered closed mantle cells | Great body width, hidden mantle layers, belly/leg spacing | `heavy_shell`; shell-safe dorsal/shoulder pads, horn and mantle roots clear |
| 21 `miragefox` | Slender fox quadruped; very large faceted fan tail; tall ears/crest; long fine legs | Fox torso/head rings; tapered limbs; fan-tail core with layered closed facet/feather cells; rooted crest | Tail fan depth and far layers; chest width | `compact_quad`; neck/withers yoke, rear shell excluded from fan-tail sweep |
| 22 `voidmanta` | Broad manta/ray body; rounded frontal face; large pectoral wings; dorsal plates; long arrow-tipped tail | Broad closed disc using transverse sections; thick pectoral lobes continuous with body; dorsal cells; tapered tail spline | Planform span and body thickness are especially unresolved; underside and cephalic shape unseen | `aquatic`; anterior dorsal yoke between eyes and wing roots |
| 23 `worldcoil` | Coiled serpent-dragon; large upright head/neck; layered cranial plates/horns; two forearms/claws; broad armored coil | One continuous closed body tube along coil spline; cross-section rings prevent collapse; head/jaw cells; two limb tubes; joined scale plates | Coil depth/self-contact, hidden tail end, head width and horn divergence | `serpentine`; collar/yoke at neck-to-coil junction plus dorsal coil pads |
| 24 `starloom` | Feline/fae quadruped; four butterfly-like wings; antennae; large ears; star-tipped tail | Feline body/head rings; four limbs; four closed wing lobes with rooted spars; safe antenna tubes; tail spline/star volume | Wing-pair depth/order, antenna divergence, tail-star thickness | `winged_quad`; chest/withers yoke with all four wing roots clear |

The matrix locks identity, not hidden dimensions. If a future calibrated view conflicts
with a provisional depth choice, the source controls are corrected and re-reviewed;
the visible approved silhouette remains the anchor.

## Three pilot briefs

### Pilot A — Cinderpaw

- Causal drivers: head/ear scale, short feline torso, broad planted paws, and the
  arched flame tail. Dependents: cheek tufts, forehead flame, chest flame, and joints.
- Locked relationships: ear height relative to head, eye-to-muzzle placement, paw
  width relative to lower leg, tail apex relative to ear apex, and four-foot ground
  contact.
- Allowed controls: head/torso ring widths, muzzle projection, limb joint positions,
  tail spline/radius, ear/tuft thickness, and camera calibration.
- Pilot failure: generic fox/cat, five legs, floating rear foot, thin cutout flames,
  tail intersecting rump, human armor socket, or a side match achieved by flattening
  width.

`docs/art/m9-model-pilots-20260904/cinderpaw-inferred-turnaround-v1.png` is an optional
depth-inference study. Its front/top panels may guide a candidate volume, but its side
is still three-quarter and none of its panels is calibrated source measurement. The
approved Cinderpaw v2 blueprint remains visible-silhouette authority. The study must
be labeled `INFERRED` in every overlay and does not need separate approval before the
first graybox; it cannot qualify the model by itself.

### Pilot B — Aurorawing

- Causal drivers: beaked feathered head, four grounded legs, large swept feather
  wings, and fan tail. Dependents: crest, neck ruff, feather tiers, and claws.
- Locked relationships: wing-root position to shoulder, wing length to torso, beak to
  eye, fore/hind foot spacing, and tail fan below/behind folded wing.
- Allowed controls: torso rings, wing spar curves, feather cell length/overlap,
  limb/foot controls, tail fan, crest, and ruff thickness.
- Pilot failure: bird biped, missing or extra leg/wing, membrane replacing feather
  structure, feather cards floating from the spar, wings fused into a single flat
  plane, or an armor yoke that blocks the wing root.

### Pilot C — Worldcoil

- Causal drivers: continuous broad coil, upright neck/head, layered cranial armor,
  and two forearms. Dependents: scales, horns, brows, claws, and chest plate rhythm.
- Locked relationships: coil outside/inside radii, neck emergence point, head mass to
  coil height, forearm root to chest, and coil ground contact.
- Allowed controls: body spline, section rings, coil pitch/radius, neck/head cells,
  limb controls, horn/plate thickness, and camera calibration.
- Pilot failure: disconnected torus base, tail hidden by an impossible cut, coil
  self-intersection, legged dragon conversion, flat spiral card, floating chest/scale
  plates, or guessed underside presented as matched reference.

### Concept Fitter family-adapter requirement

The installed v1 schema is quadruped/dragon-oriented: it requires front- and hind-leg
seven-point chains. It is directly usable for the real Cinderpaw leg chains and can
support Aurorawing's four actual legs, but that requirement is invalid for wing-only,
limbless, aquatic, perched, or coiled anatomy. Production must add a project-local,
family-aware manifest/adapter extension with explicit `present: false` limb semantics
and archetype-specific appendages. It must retain the add-on's calibrated views,
landmarks, curves, cross-sections, invariants, and evidence outputs. Invisible,
zero-scale, buried, or off-camera dummy legs added merely to satisfy schema are a P0
failure. Tool extension is a later implementation slice, not work performed here.

## Equipment model and compatibility contract

The equipment catalog contains exactly 11 IDs:

| Catalog ID | Required standalone model | Fit/identity requirement |
| --- | --- | --- |
| `standard_full_suit` | Modular animal barding, Standard tier | Exact approved v2 direction; no helmet/head/arms/gloves/boots arranged as a humanoid |
| `reinforced_full_suit` | Same approved barding grammar, Reinforced tier | Clear added protection while preserving eyes, jaw, gait, wings/fins, and identity |
| `arcane_full_suit` | Same approved barding grammar, Arcane tier | Tier distinction follows approved concept; no new unapproved humanoid or mech motif |
| `masterwork_full_suit` | Same approved barding grammar, Masterwork tier | Added authored detail stays within shared budgets and does not bury creature silhouette |
| `legendary_full_suit` | Same approved barding grammar, Legendary tier | Most legible tier cap, still a fitted animal shell rather than a replacement body |
| `iron_gem` | Faceted socket gem | Seats in semantic `socket_gem`; Iron identity follows approved card/concept authority |
| `ember_gem` | Faceted socket gem | Same socket envelope; Ember identity remains material/color/approved shape, not size advantage |
| `frost_gem` | Faceted socket gem | Same socket envelope and clearance |
| `storm_gem` | Faceted socket gem | Same socket envelope and clearance |
| `arcane_gem` | Faceted socket gem | Same socket envelope and clearance |
| `filament_ring` | Printer-side ring/guide fixture | Uses `printer_effect_socket`; never placed on a creature finger, horn, neck, or limb |

### Semantic anchor set

Every creature GLB exports these named transforms even when the visible suit uses only
a subset:

- `socket_armor_yoke`: primary collar/pectoral/dorsal yoke at the anterior torso;
- `socket_armor_spine`: midline dorsal support;
- `socket_armor_rear`: rear torso support before the tail/coil/fin root;
- `socket_armor_flank_l` and `_r`: paired side/belly strap contacts;
- `socket_gem`: a visually quiet collar/yoke junction, normally anterior and dorsal;
- `clearance_head`, `clearance_limb_l/r`, `clearance_tail`, and
  `clearance_wing_l/r`: bounds used by the fit validator, not rendered geometry.

“Collar” is semantic, not humanoid. Tidewhale, Voidmanta, and Worldcoil use their
anterior dorsal/pectoral yoke; owls and winged quadrupeds use sternum/withers space;
shell-backed creatures use reviewed shell-safe pads. The gem's local forward is
`-Z`, up is `+Y`, and its mount envelope is identical across all five gems. All five
remain swappable without moving the creature socket.

Each suit is a standalone modular collection of closed plates and straps with the
same node vocabulary across tiers: `yoke`, `spine`, `rear`, `flank_l`, `flank_r`, and
`gem_bezel`. Modules seat individually on the semantic anchors, which avoids a single
stretched humanoid shell. The eight exact fit classes in the creature table select
reviewed module visibility and orientation; each of the 24 creature rows must also
carry a per-ID fit record. Uniform scaling alone is not a fit record.

All 24 creatures remain gameplay-compatible with armor and gems. A missing visual fit
is a production-blocking asset failure, not a new gameplay incompatibility and not a
reason to silently hide or reject an otherwise legal card. Each per-ID fit record must
prove no intersection at a bounded set of manually posed neutral, walk-extreme,
attack-extreme, hit-extreme, and defeat-extreme clearances. These are model-fit
evidence poses, not a new 3D runtime animation requirement.

Each accepted equipment model also produces two catalog-keyed 2D derivatives. The
intact blueprint is the approved navy/cream paper-through grammar with the whole item
assembled, transparent outside its art, and no baked dynamic text. The raw print is a
single-filament, layered render of the same geometry from the same reviewed camera.
The blueprint, raw render, and GLB must agree on module count, silhouette, handedness,
and defining features. Independent image generation that changes the model or invents
extra pieces fails coherence.

## Player-facing feature contracts

### Creature print and animated-2D battlefield handoff

- **Entry:** A non-spell creature card is legally played, reaches the head of its
  printer queue, completes its authoritative print time, and reaches any existing
  required placement decision.
- **Player decision:** Select the existing legal placement when requested, cancel only
  when the rules expose cancel, or watch/skip presentation under the existing reduced-
  motion contract.
- **Result:** Blueprint becomes the catalog-matched layered raw-print presentation,
  then the existing exact animated 2D creature awakens and walks to the accepted
  battlefield position. The GLB is not a battlefield unit. Simplified automatic
  combat remains authoritative.
- **Failure:** Missing/wrong raw art or sprite, stale placement, or interrupted 2D
  animation preserves battle authority, reports the exact presentation failure, and
  never fabricates a unit, target, reward, or result. A missing GLB fails M9C model
  qualification but does not change this 2D battle transaction.
- **Disabled:** Non-head jobs do not animate; placement is enabled only when requested;
  a model that failed the asset gate cannot qualify a milestone build.
- **Feedback:** Queue receipt, native creature name/status, visible layer-to-volume
  transition, ground contact, short walk, and reduced-motion state markers agree with
  the authoritative job and side.
- **Progression:** Art loading and animation are zero-mutation. Only the existing
  accepted play/print/placement/battle transactions change state.

### Equipment print, equip-ready state, and fitted appearance

- **Entry:** A non-spell equipment card completes its queue time and appears in the
  existing equip-ready inventory; a compatible living creature and legal slot exist.
- **Player decision:** Tap the actual equip-ready card/control, select a legal creature
  when required, confirm, replace under existing slot rules, or Back without mutation.
- **Result:** The exact equipment card/raw presentation becomes equip-ready. An
  accepted equip updates the existing 2D field marker/stat presentation. The GLB's
  barding, gem socket, and Ring fixture are proven in model inspection/fit evidence;
  they are not rendered as 3D battlefield attachments. Existing armor/attack/effect
  rules remain the only authority.
- **Failure:** Missing fit record, occupied/illegal slot, stale creature, visual
  intersection, persistence rejection, or wrong socket keeps the accepted state
  unchanged and identifies the exact reason. It never attaches a different item or
  guesses a humanoid mount.
- **Disabled:** The action is visibly disabled for existing rule reasons or in-flight
  persistence. Asset production authority never bypasses player progression or equip
  legality in an already qualified future build.
- **Feedback:** Native item/creature/slot names, printer-ready receipt, stat delta,
  and non-color equipped marker agree. Back remains
  visible and Android native Back follows the same route rule.
- **Progression:** Inspect/select/Back are zero-mutation. One accepted equip or replace
  is one persisted transaction; art/socket presentation grants no stat by itself.

### Printable-model inspection and fit preview

- **Entry:** The player opens the M9 printable-model detail for an existing visible
  catalog creature/equipment ID outside live battle.
- **Player decision:** Drag the actual preview viewport to rotate, select an owned
  compatible equipment preview when offered, reset view, or use visible/native Back.
- **Result:** The exact full-volume GLB is grounded in a bounded preview; equipment
  seats on semantic anchors for inspection only. Native ID/type/facts remain separate
  controls. No GLB enters the animated-2D battlefield.
- **Failure:** Missing/corrupt/wrong model, socket loss, or preview load failure shows
  a truthful non-model placeholder and native reason; it never substitutes another
  ID or presents a sprite plane as 3D.
- **Disabled:** Preview availability never bypasses card visibility, blueprint,
  ownership, queue, print, slot, purchase, or equip authority. External mesh download
  and physical-printer controls are not offered by M9C.
- **Feedback:** Ground shadow, stable camera, whole-model bounds, non-color selected
  item marker, loading/failure copy, focus order, 150% text, high contrast, reduced
  motion, and Back remain legible in portrait.
- **Progression:** Rotate/reset/equipment preview/Back are zero-mutation. The GLB
  exporter is a production-pipeline artifact, not a player reward or stat transaction.

## Required source/export manifest

The later asset manifest has one row per 24 creature and 11 equipment IDs and must
contain at least:

`catalog_index`, `id`, `type`, `source_path`, `source_sha256`, `builder_path`,
`builder_sha256`, `reference_paths[]`, `reference_sha256[]`, `evidence_authority`,
`unresolved_views[]`, `forward_axis`, `up_axis`, `source_unit`, `display_scale`,
`root_name`, `named_regions[]`, `fit_class`, `socket_names[]`, `socket_transforms`,
`bounds`, `triangle_count`, `vertex_count`, `material_slots`, `texture_sets`,
`nonmanifold_edges`, `zero_area_faces`, `open_boundary_edges`, optional `lod_counts`,
`export_path`, `export_sha256`, `exporter_version`, and `review_record`.

Creature entries also include `visible_landmarks`, silhouette/landmark metrics, ground
contacts, and equipment clearance bounds. Suit entries include every module name and
the eight reviewed fit-class configurations. Gem entries include mount-envelope hash.
Filament Ring includes `printer_effect_socket` compatibility. Missing or `null`
evidence stays visible; a manifest generator may not silently backfill it.

## Deterministic milestone acceptance

M9C is accepted only when all of the following are true:

1. Static inventory finds exactly 24 creature source packages/GLBs and exactly 11
   equipment source packages/GLBs, mapped one-to-one to catalog IDs with no human,
   humanoid armor, mech, unknown, duplicate, or wrong-species entry. It also finds
   one intact blueprint and one raw-print image for every creature/equipment ID; the
   11 equipment pairs prove deterministic derivation from their accepted models.
2. The three pilots pass source rebuild, export, hash, manifold, normals, UV, budget,
   ground/support grouping, silhouette, landmark, socket, and full-volume checks. A rebuild from the
   recorded entry point reproduces the accepted geometry/material structure and
   deterministic export hash in the pinned toolchain.
3. Original-resolution pilot evidence includes calibrated visible-reference overlay,
   silhouette mask, landmark plot, neutral front/side/top labeled by evidence status,
   and eight-angle turntable. Aurorawing additionally shows wing roots/open-clearance;
   Worldcoil shows coil interior, back, underside contact, and self-intersection check.
4. Read-only visual review of the pilot evidence reports P0 none/P1 none, followed by
   explicit three-pilot human acceptance. Only then may the remaining 21 expand.
5. All 24 final creature packages pass the same automated checks and a catalog-order
   contact sheet/turntable review. Each retains the locked matrix features and disclosed
   M7 P2 signature cues; none is merely a rescaled/recolored shared animal.
6. The exact corrected barding-v2 concept hash above retains its recorded human
   approval. Controlled broad suit/gem generation may proceed without reapproval of
   that exact decision; changed concept bytes do not inherit it. Runtime derivatives
   still require real RGBA and model/fit evidence.
7. After the equipment pilot passes on Cinderpaw, Aurorawing, and Worldcoil, all five
   suits, five gems, and Filament Ring pass standalone-model, budget, socket, neutral
   fit, pose-clearance, blueprint/raw/model coherence, and catalog-identity checks.
   Every creature has one complete armor/gem fit record; no runtime-legal pairing
   lacks visual geometry.
8. Runtime integration tests use coordinate-based pointer/touch and keyboard focus
   events on actual queue, placement, equip-ready, creature, confirm, printable-model
   viewport, preview selection, and Back controls. Direct callback or emitted-signal
   invocation is not acceptance.
9. A complete queue test proves the catalog-matched animated 2D creature—not its GLB—
   appears only after its print boundary, walks once to its accepted position, and
   does not alter automatic combat outcome. An equipment test proves the printed item
   first becomes equip-ready and only an accepted equip transaction changes its 2D
   field marker/stats. Separate preview evidence proves the GLB/socket fit.
10. Missing/corrupt model, wrong ID, plane fake, socket loss, fit intersection, reduced
    motion, Back, save/reload, and interrupted presentation cases preserve deterministic
    authority and never duplicate cards, jobs, units, equipment, stats, XP, or coins.
11. Portrait captures at 576x1024 and 720x1280 cover the three printable-model
    previews, one fitted suit on all three pilot archetypes, one gem on all three, the
    printer Ring fixture, the separate animated-2D print/battlefield walk, 150% text,
    high contrast, and reduced motion. The native bottom AdMob contract remains
    reserved at zero game height and never covers a model or control.
12. M9A/M9B rules, old saves, deck/economy outcomes, Back routing, and simplified
    automatic battle remain regression-equivalent. Art loading, model-preview motion,
    and sockets consume no gameplay RNG.

## Explicit holds and non-goals

- **AUTHORIZED:** controlled equipment-family concept/model generation under the exact
  approved barding-v2 direction. The old humanoid floating suit remains rejected.
- **HOLD:** runtime promotion until real source/export/socket evidence passes. The
  presence of a rendered raw-print PNG is not model completion.
- No invented orthographic claim, hidden anatomy certainty, physical print size, rig,
  animation set, or compatibility exclusion derived from a single PNG.
- No sprite-plane substitute, AI image-to-3D opaque output, flat depth extrusion,
  humanoid mannequin, robotic/mechanical conversion, or card-shaped field unit.
- No manual MTG phases, direct unit steering, aim timing, added targets, new stats,
  balance changes, gameplay RNG, ads/IAP changes, online dependency, freeform text,
  or player trading.
- No landscape duplicate, build/export/device/Drive/cloud claim, or new approval request
  for the already approved M7 creature/physical-UI family.
- No 3D battlefield conversion, 3D combat collision, mandatory LOD family, slicer
  profile, support-generation promise, material strength claim, or physical-printer
  manufacturing certification.
