# Highlight-preserving completed-object masks

Root inspection, 2026-09-04. This is an alpha-only tool task for Terra, not a new
source-art brief or runtime promotion. Existing source RGB and geometry are approved.

## Failure and scope

`tools/extract_blueprint_alpha.py` currently has only `paper-through-ink`, which
correctly removes enclosed blank paper in line drawings. Applied to solid Iron,
Frost, Storm and Filament Ring concepts, that policy also removes white metallic
highlights inside the object. Keep the ink algorithm and its existing test byte-for-
byte compatible; add a distinct `solid-object` path.

## Decision-complete implementation

- Flood only bright neutral background pixels connected to the image perimeter.
  Retain enclosed bright pixels at opaque alpha, including gem facet and filament
  highlights. Preserve the source RGB bytes in every output pixel.
- Use explicit, recorded neutral-brightness/chroma thresholds and four-neighbor
  connectivity. Do not silently choose or tune thresholds by equipment ID. Boundary
  antialias tapering, if required, applies only adjacent to the proven exterior mask,
  never throughout enclosed faces. Do not smooth or redraw source RGB.
- Allow repeatable explicit background seeds for intentional enclosed apertures.
  Validate bounds and the background predicate; reject invalid seeds rather than
  clearing a solid region. The reviewed Ring source is 1254x1254; `(580,650)` lies in
  its clear central opening. That aperture seed is part of its provenance, not a
  hard-coded catalog special case. Other three gems need no interior seeds.
- Reuse existing PNG I/O, composites, proof resizing, byte hashes and edge audit.
  Emit mode-specific truthful provenance: no paper-through/datum promises for solid
  mode, and no claim that a source is truly transparent before extraction.
- Add synthetic tests proving: exterior removal, enclosed white highlight retained,
  optional aperture removal, invalid-seed rejection, all-pixel RGB identity, and
  unchanged paper-through-ink fixtures. Run the existing self-test as well.
- Generate four new non-overwriting alpha/light/dark/160px/provenance sets using
  suffix `solid-v1`: Iron completed source v1, Frost v2, Storm v2, Ring v1. Preserve
  rejected old alpha files as evidence. No runtime asset paths are changed here.
- Root and UI review source plus light/dark and exact 160px proofs. Only after that
  may the equipment review ledger change those four completed-alpha gates to PASS.

This is queued after the bounded M9A lifecycle repair; it may run independently of
rendered capture collection without changing the game under test. It is not a reason
to delay a validated M9A APK. Actual model and runtime-integration gates remain open.
