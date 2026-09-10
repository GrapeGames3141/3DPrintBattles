# M11 facing-integration checkpoint — 2026-09-10

Status: **AUTHORIZED bounded integration.** The user approved the facing-inward
direction on 2026-09-08 and on 2026-09-10 explicitly requested that it appear in the
battlefield and be delivered in a new Android review build on Google Drive.
Preparation baseline: branch `spike/printforge-physical-ui`, HEAD `032c546`.

Authority: [facing direction and approval](../art/m11-living-battles-20260908/FACING-DIRECTION.md),
[M11 living-print contract](m11-living-print-battles-v1.md),
[runtime integration brief](../art/m11-living-battles-20260908/RUNTIME-INTEGRATION.md),
and [latest Android delivery](m11-ui1-android-delivery-20260908.md).
The approved visual target is
`docs/art/m11-living-battles-20260908/direction-proof-facing-inward-v1.png`
(SHA-256 `B64980DD082D9D7465B9E512EB301010E7999C0D027095EFF8B374F6EBFD3055`):
friendly lower units show rear/slight three-quarter-rear views facing up-board, and
rival upper units show front/slight three-quarter-front views facing down-board.

## Observed gap

The proof is a static three-creature composition concept, not runtime art. Current
runtime inventory contains 24 tracked `assets/creatures/2d/*_sprite_sheet.png` sheets,
and `assets/runtime_asset_manifest.json` requires the same 24 creatures; those sheets
remain side-biased. No source-preserving production front/rear animation family was
found. Therefore `0.8.10-physical-ui-polish` / code `106` cannot be described as
implementing the approved facing direction. The prior concept-only Drive receipt is
`docs/art/m11-living-battles-20260908/FACING-DRIVE-DELIVERY.md`; it is not an APK.

## Player-facing feature contract

- **Entry:** Either seat begins or resumes an authoritative print receipt, awakening,
  deployment, settled field idle, attack/contact/return, or reduced-motion equivalent.
- **Player decision:** Use only the already-legal Plan, focus, Run Cycle, required
  choice, Skip, Back, and accessibility actions. Facing adds no combat decision.
- **Result:** Presentation selects direction from field ownership, never from creature
  identity: friendly/lower raw print, awakened miniature, travel, idle, attack and
  return use the approved rear family; rival/upper equivalents use the approved front
  family. The same rule applies to all three starters and every non-starter creature
  in the authoritative 24-creature catalog. One job becomes one living unit, with
  stable identity, feet, scale, material, matched slightly elevated board-camera angle,
  and inward orientation through the complete print -> awaken -> deploy -> idle ->
  attack chain.
- **Failure:** A missing/malformed direction, pose, alpha region, creature mapping or
  compiled resource enters the existing finite presentation fallback, names the exact
  creature/seat/beat in diagnostics, acknowledges the accepted receipt exactly once,
  and lets authority finish. It never mirrors a side view and calls it rear-facing,
  substitutes the static proof screen, reruns authority, stalls, or duplicates a unit.
  Any fallback occurrence fails facing-integration acceptance and blocks the review
  build from being labelled complete.
- **Disabled:** Background Plan/hand/Run Cycle targets remain locked during playback;
  rival-private targets remain inaccessible. Unsupported directional art is disabled
  as an acceptance candidate rather than silently falling back in a release claim.
  No new Guard action, targeting option, phase control or skip advantage is enabled.
- **Feedback:** Ground shadow, foot anchor, inward silhouette, print scan/raw boundary,
  awakening, travel, contact, HP receipt and return describe the same receipt and unit.
  Native status/accessibility copy truthfully exposes a presentation fallback where
  it occurs; native focus, dynamic values and captions remain unobscured.
- **Progression:** Facing, animation selection and fallback are presentation-only.
  Identical accepted intents must produce identical deterministic integer battle
  traces, revisions, RNG outcomes and exactly-once settlement with normal, skipped,
  reduced-motion, front-resource-missing and rear-resource-missing presentation.

## Exact preservation boundary

Preserve portrait-only composition, the approved r7 continuous floor, printer/chamber
geometry, native dynamic controls, exact card back, blueprints, creature identity and
filament materials. Generated art is text-free and never a populated backplate or
text container. Preserve current HP, Guard availability/locks, targeting, readiness,
attack order, print work, FIFO/staging, timing authority, pacing, AI, catalog stats,
ownership, save schema, decks, rewards, receipts and navigation. This pass adopts no
mechanic from `docs/design/printforge-reboot-proposal-20260908.md`.

Preserve the active no-AdMob Android contract: portrait game content reserve is zero,
and this review build contains no AdMob SDK, plugin, identifier, permission, metadata
or request path. Native Android would own banner creative and bottom safe inset if a
future separately approved build enabled it; Godot must not reserve that space twice.

## Decision-complete acceptance and evidence

1. A source/runtime manifest maps the exact 24 catalog creature IDs to reviewed front
   and rear idle/action resources. It rejects missing/extra IDs, bad dimensions/cells,
   invalid alpha, out-of-bounds feet, accidental text, identity/material drift and any
   side-view mirror presented as a rear view. Cinderpaw, Aquafin and Voltwig are each
   exercised as friendly and rival starters; every remaining catalog creature is
   exercised at least once on each ownership side through automated coverage.
2. Actual Main -> coordinator -> stage evidence covers both seats at early print, exact
   60%, raw completion, awakening, launch/travel/landing, settled idle, creature
   contact, exposed-printer contact and return. It includes duplicate card IDs,
   interruption/re-entry, stale callbacks, Skip and reduced motion. Exactly one visible
   owner and one receipt acknowledgement survive every transition.
3. Missing front and missing rear fixtures separately prove the finite truthful
   fallback and unchanged authority trace. No test or README may report full facing
   coverage while any catalog/pose mapping uses fallback.
4. Original-resolution runtime captures at 576x1024, 720x1280 and a tall portrait,
   including 150% text/high contrast and reduced motion, are compared with the approved
   proof and r7 composition. A read-only UI review must return no P0/P1 for identity,
   inward facing, ground contact, scale, unobscured native information, accessibility,
   material consistency or print-to-attack continuity before runtime-art promotion.
   Any new direction or creature redesign requires fresh human approval.
5. Focused deterministic tests prove presentation-mode and missing-resource trace
   equality, exactly-once settlement, no node/material growth, cached resources and no
   late callback unlocking a newer receipt. Existing M11/UI1 rule, battle, Back, save,
   manifest and compiled-runtime regressions remain green. Evidence belongs under
   `build/evidence/m11-facing-integration-20260910/`; concept captures alone never pass.
6. After the reviewed source checkpoint is committed by Sol, export the non-overwriting
   arm64 portrait no-ad review build as version
   `0.8.11-facing-integration`, code `107`, package
   `com.tak.printforge.legends.playtest`. Verify compiled 24-creature directional
   coverage, package/version/code, signature, ABI, portrait metadata, launch, and no-ad
   scans. The APK README must state the remaining M11/pacing/device limits.
7. Copy the commit-qualified APK and README without overwriting an existing release to
   `H:\My Drive\AI Projects\PrintForge`; verify source/destination byte size and SHA-256.
   Report DriveFS copy separately from independently confirmed cloud visibility. Do
   not claim physical-device behavior without an attached authorized-device record.

Current reusable approval/evidence paths are:

- `docs/art/m11-living-battles-20260908/FACING-DIRECTION.md`
- `docs/art/m11-living-battles-20260908/direction-proof-facing-inward-v1.png`
- `docs/art/m11-living-battles-20260908/captures/r7/`
- `docs/checkpoints/m11-ui-scene-audit-20260908.md`
- `build/evidence/m11-ui1-20260908/`
- `build/evidence/m11-ui1-release-20260908/`

Open gaps at authorization are the absent production front/rear family, absent
24-creature/both-seat lifecycle proof, absent integrated no-P0/P1 review, and absent
`0.8.11` Android/Drive delivery. The approved static proof, earlier r7 captures and
`0.8.10` APK do not close any of those gaps.
