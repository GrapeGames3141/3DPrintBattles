# Forge continuity candidate review v1

Read-only UI reviewer, 2026-09-04: **candidate direction PASS, no P0/P1**.
Human derivative-family approval and runtime integration remain pending.

The static 941x1672 enclosure retains the approved front camera, cabinet silhouette,
star-gem, navy/brass/cream materials, right cartridge, chamber/bed, three dials and
three action wells. The moving assembly has been removed cleanly; there is no ghost,
hole, duplicate printer, creature or text.

The 1536x1024 carriage atlas has genuine RGBA transparency, with 1,178,834 alpha-zero
pixels and no baked black matte. Both moving objects are coherent same-family
mechanisms. Approximate alpha>8 bounds are:

- Guide: x36..1501, y28..429.
- Head: x635..901, y396..979.

Their bounding rectangles overlap vertically. A full-width rectangular guide crop
would include the head crown. Isolate disconnected source-alpha components before
tightly cropping and adding transparent padding. Preserve metallic source RGB and
edge antialiasing; do not apply a luminance mask to this already transparent source.

P2: peak alpha is 254, mostly 252-253 in solid regions. Any interior normalization
must preserve original antialiased edges and be validated on light/dark fields.
Annular collars/pegs differ slightly from the reference's simpler carriage, so the
registered composite must prove these do not double/thicken retained vertical posts.

This is a source-family gate only. Runtime promotion requires independent cropped
layer alpha proofs and a registered in-aperture composite, followed by the actual
Start-to-print scene-continuity test. No Android build is authorized by this review.
