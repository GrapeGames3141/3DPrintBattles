# Prototype directional sprite root audit

Read-only UI reviewer measurements, recorded by primary2026-09-12. These are
registration inputs for BA-R1, not an already-completed BA-R1 runtime visual pass.
The actual promoted Cinderpaw, Aquafin and Mossmunk atlases match their cleaned-v1
RGBA outputs; promoted Voltwig matches cleaned-v3 SHA-256
`80883C09C69B52E296152C56E14C3E61DFECDB4031B84100487EB6C8915F9280`.

All values below use the full384x512 source cell, x-root192. The cache's safe region
removes a2px gutter, so local rendering root is `(190, y-2)` in a380x508 region.
Do not use a universal y455 or infer a planted root from each frame's alpha bottom.

| Companion | Rival/front idleA, idleB, windup | Friendly/rear idleA, idleB, windup |
| --- | --- | --- |
| Cinderpaw | f0:y475; f1:y475; f2:y492 | f4:y425; f5:y426; f6:y433 |
| Aquafin | f0:y487; f1:y484; f2:y484 | f4:y421; f5:y421; f6:y404 (provisional) |
| Mossmunk | f0:y486; f1:y485; f2:y488 | f4:y425; f5:y426; f6:y434 |
| Voltwig | f0:y455 for all finite native beats | f1:y455 for all finite native beats |

Aquafin rear idleA/B is the documented registration root in
`docs/art/m11-facing-minis-20260910/aquafin-registration-v1.json`; both Voltwig roots
are documented in cleaned-v3 provenance. Other values are measured solid-foot
baselines in the promoted pixels and require actual BA-R1 capture verification.
Correct small idle baseline differences through registration so breathing doesn't
make planted feet slide.

The 4x2 contact frames f3/f7 are airborne/extended: they have **no planted foot root**.
Their lowest solid pixels (Cinderpaw457/424, Aquafin485/~404, Mossmunk464/437) are
not floor anchors. Preserve the preceding seat-floor anchor and its finite horizontal
contact translation. Anchor the contact sprite from the preceding grounded windup
root, allowing its authored airborne clearance; do not pull its alpha bottom down
to the shadow. Native hop/impact effects, if used, move the creature above the floor
while the shadow remains on the floor and changes only in opacity/size appropriately.

The renderer should store these small immutable per-species/per-frame metadata
values beside its presentation geometry, use the cache's actual safe-region size,
and apply scale/rotation around the registered root. Do not scan pixels, load images,
or clone battle snapshots per frame. Native Voltwig finite motion uses its two real
neutral views; do not invent extra authored animation frames or mirror a rear view.

Required BA-R1 checks: idleA/B planted contact, windup, airborne contact, return,
printer/Enter transition, both seats and all four eligible companions; verify
no clipping, shadow detachment, duplicate home mini, or root jump at pose changes.

## Approved-composition floor anchors

The reviewer resolved these centers in the uniformly fitted941x1672 design space.
Place the per-frame source root onto these scene anchors, rather than moving feet
to the bottom of the sprite's bounding rectangle.

| Owner | Floor anchor x,y |
| --- | --- |
| Rival Active | 470.5,620.3 |
| Player Active | 470.5,924.2 |
| Rival Ready1 | 442.8,279.1 |
| Rival Ready2 | 749.9,279.1 |
| Player Ready1 | 442.8,1225.1 |
| Player Ready2 | 749.9,1225.1 |
| Rival printer bed | 163.4,333.3 |
| Player printer bed | 163.4,1310.6 |

Active centers derive from final CSS and the approved Cinderpaw source roots,
reproducing M0 review's actual576-wide feet near y380/566. Ready planes are calculated
from the final per-species CSS+source registrations: rival values converge near279.1,
player near1225.1. Printer centers convert measured actual576-wide bed centers
near x100,y204/802, retaining approximately1.5design-pixel measurement uncertainty.

Player Active rectangle bottom970.08 would collide with caption top953.9; it is
not the floor. Normal caption clearances from the recommended Active roots are
34.8design pixels rival and29.7 player. At150%, the authored caption tops637.14 and
931.20 leave only16.8/7.0pixels: verify the player shadow never paints the caption.
Ready clearances are about3.5normal and1.6–1.8at150%; keep floor shadows out of the
native caption owner and verify every eligible species. Voltwig was absent from
the historical M0 captures, so its shared-anchor fit is inferred and requires the
first native BA-R1 capture. None of these measurements is device sign-off.
