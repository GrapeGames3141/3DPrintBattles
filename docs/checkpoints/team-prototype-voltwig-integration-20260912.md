# Voltwig genuine facing integration

Primary implementation plan, 2026-09-12. User explicitly requires genuine front/rear
views before the next Android build and approved deterministic checkerboard cleanup.
The current source has passed identity/direction/camera review; the first alpha
derivative has not passed because it removes cream highlights. Runtime promotion
is gated on primary and read-only UI acceptance of the corrected derivative.

## Bounded sole-writer scope

After alpha acceptance, Terra owns the promoted Voltwig PNG in
`assets/creatures/2d/battle-facing/`, `scripts/ui/battle_facing_sprite_cache.gd`,
the five facing-region calls in `physical_battlefield_stage.gd`, and the focused
cache/roster/lifecycle tests. Primary owns the runner and checkpoint records.
No battle-rule, legacy win-condition, profile, other creature art, or default-entry
changes in this slice. This verifies a shared presentation dependency; it does not
make the historical game the approved team prototype or authorize an APK yet.

## Decision-complete interface

- Promote exactly the reviewed 768x512 RGBA derivative, named
  `voltwig_battle_facing_2x1.png`; record its source/derivative hashes.
- Each 384x512 cell is a real generated neutral pose. Column0 is rival/front;
  column1 is friendly/rear. Both share root (192,455), common uniform scale, and
  verified transparent ear padding. Do not expand to eight duplicate/fake poses.
- Keep the other 23 existing 4x2 atlases and their frame semantics unchanged.
- `frame_for_creature` and `raw_frame_for_creature` return 0 for Voltwig seat1 and
  1 for seat0. They retain those actual neutral cells throughout finite native
  motion. Invalid IDs/seats still reject. The general 4x2 frame API stays intact.
- Add `safe_source_region_for_creature(creature_id, frame)` and an explicit
  `atlas_size_for_creature` contract. Voltwig uses two columns/one row; other species
  use four columns/two rows. Validate frame range rather than silently turning an
  invalid species/frame into another image. Preserve two-pixel safe gutters.
- All species-aware runtime callers and tests use the species-aware region API.
  An X-and-Y region assertion is required; the old Y-only lifecycle assertion
  cannot distinguish the two Voltwig directions in the same row.
- Remove the Voltwig side-view resource exception and legacy action mapping.
  Existing compatibility query `uses_legacy_art` may remain returning false while
  callers are migrated; no release path may classify legacy coverage as success.
  `has_directional_coverage` is true for all 24 valid imported assets. Coverage kind
  is `directional_neutral` for Voltwig and `directional` for the other 23.
- Validate loaded texture dimensions against the explicit contract once at load;
  cache failures and report a precise error instead of substituting side views.
  No per-frame image reads, atlas assembly, texture loading, or mask scans.
- Existing finite visual motion is preserved: one visible unit, no mirror flip,
  no simultaneous home/attack copy, contact shadow moves with the unit and resets,
  raw filament remains seat-correct until Awaken, reduced motion stays grounded.
  The later team presenter will animate neutral Voltwig natively; it must not
  claim eight authored poses or rely on a legacy side-view frame during attacks.

## Acceptance and maintenance

1. All 24 catalog creatures have genuine directional coverage. Voltwig resolves
   only the reviewed new file; invalid/missing resources fail closed.
2. Both Voltwig frames fit the 768x512 atlas, have distinct alpha signatures,
   two-pixel clear edges and retained ear padding. All 23 previous sheet contracts
   still pass unchanged. Cache requests reuse one texture load per source.
3. Every raw/idle/attack/deploy region call uses its species-aware geometry. Tests
   cover both seats, finite attack progress, no legacy path, and invalid frames.
4. Actual rendered print/reveal/awake/attack-return and reduced-motion evidence
   must show Voltwig in both directions with no clipped ears, checker, dark holes,
   duplicate sprite, or shadow drift. New-team runtime captures remain a later
   gate; a historical presenter fixture cannot substitute for those captures.
5. Review the diff for duplicated frame logic and stale interim-success wording.
   The cache owns geometry and source mapping; presenters consume its contract.
   No general asset-framework rewrite or unrelated refactor is needed.

Use the audited E:-isolated Godot runner for parser/import/tests/captures. Record
exact PIDs, logs and cleanup. Freeze after focused validation for primary review;
do not stage, commit, export, or copy to Drive from the writing agent.
