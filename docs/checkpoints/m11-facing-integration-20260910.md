# M11 facing-integration checkpoint — 2026-09-10

Status: **23 available species UI-cleared and promoted in development; release build
blocked. The reviewed stage integration is parked and the previous playable
all-creature stage baseline is restored.** The user approved the facing-inward direction on 2026-09-08 and on
2026-09-10 explicitly requested that it appear in the battlefield and be delivered in
a new Android review build on Google Drive. The user then answered “yes do it,”
explicitly approving programmatic background cleanup for the production facing family.
Conservative source-preserving front/rear variants that remain inside the already-
approved direction require no additional human approval round. This method approval
does not waive manifest, runtime-evidence or read-only no-P0/P1 gates; a new direction
or creature redesign still requires approval.
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

## Durable progress and known blocker

The original proof is a static three-creature composition concept, not runtime art.
Source-art checkpoint `b823022` now holds 23 identity-preserving directional masters.
All 23 available species now pass offline read-only UI review and have runtime sheets
promoted in the development working tree. The fresh strict cache import proves all
23 available sheets; its full-catalog failure is Voltwig only. Pyraxis and Voidmanta passed lossless
whole-pose cross-cell reclaim: their toe/fin anatomy is preserved rather than cropped
or deleted to force a cell boundary. The visual cleanup P0 findings for Runestag and
Aquafin remain corrected and reviewed.

Runestag's stale import was resolved by fresh import PID `24928` and GPU validation PID
`49952`: source, imported texture and shader each report `834/834` accepted alpha
pixels at the same original `0.04` tolerance. This closes the previously recorded
source/import alpha discrepancy; it does not substitute for lifecycle review.

Actual Main public-FIFO capture PID `66612` passes at 576x1024 for partial raw printing
with no early field occupant. The reviewed parked patch has final fixed-training-viewer
Main/coordinator captures at 576x1024 (PID `53832`) and 720x1280 (PID `82732`): both
physical seats print and settle, actor 0 uses rear contact frame 7, actor 1 uses front
contact frame 3, receipt identity is unchanged, target captions remain readable, and
the P1 contact-grounding correction passed read-only review. The existing real Release
Cycle regression also passes after that correction (PID `99476`). These captures are
evidence for the parked patch, not the restored default stage. Tall portrait, device,
Android packaging and Drive delivery remain pending.

Voltwig is the sole missing master. The image service blocked its unchanged prompt at
output moderation three times; the last request was
`d4923bae-6fa1-4c40-9196-0d0751ef5e02`. No usable 3D or other source alternative was
found. The user was asked asynchronously to authorize an explicitly limited interim
23-creature build that retains legacy Voltwig, but has not answered; **no exception is
approved**. Full 24-creature coverage with no fallback remains the release gate unless
the user explicitly grants that exception.

The primary permits incremental working-tree integration and testing of candidates
that have passed UI review. The exact reviewed runtime stage diff is preserved in
[the parked integration record](../art/m11-facing-minis-20260910/PENDING-INTEGRATION.md)
and is not active on the default stage. This does not authorize a final release claim,
a Voltwig substitution or a 23-creature Android delivery. Latest delivered remains
`0.8.10-physical-ui-polish` / code `106`; no APK, Drive artifact or version bump has
occurred in this integration pass. The prior concept-only Drive receipt is
`docs/art/m11-living-battles-20260908/FACING-DRIVE-DELIVERY.md`; it is not an APK.

Execution ownership remains gated: the primary prepares the complete 24-creature
source-facing family; the sole Terra runtime writer performs deterministic background
cleanup/alpha extraction, registers animation frames, integrates assets and tests the
result. The designer changes only this checkpoint and the UI reviewer remains read-only.

## Durable evidence

- [Facing-mini source collection and review ledger](../art/m11-facing-minis-20260910/README.md)
- [Pyraxis lossless cleanup — dark composite](../art/m11-facing-minis-20260910/cleaned/pyraxis-battle-facing-cleaned-v1-dark-composite.png)
- [Voidmanta lossless cleanup — dark composite](../art/m11-facing-minis-20260910/cleaned/voidmanta-battle-facing-cleaned-v1-dark-composite.png)
- [Actual Main 576 public FIFO partial-print capture](../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/actual-main-576-qa/m11-b1-actual-fifo-print60-576x1024.png)
- [Parked runtime-patch index, final 576/720 captures and superseded diagnostics](../art/m11-facing-minis-20260910/PENDING-INTEGRATION.md)

These links expose the reviewed source collection, the two anatomy-reclaim proofs,
bounded actual-runtime image, and the parked-patch final lifecycle capture index. They
do not prove Voltwig/full-24 release coverage, tall portrait behavior, device behavior,
Android packaging or Drive delivery.

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
   Programmatic cleanup must be deterministic and background-only: preserve source RGB
   inside the accepted creature silhouette, preserve intentional internal openings,
   reject ambiguous edge/background regions, and retain per-file provenance/hashes.
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
   Passing conservative variants within the approved direction do not require a second
   human approval; any new direction or creature redesign does.
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

Open gaps are Voltwig's missing directional master or a user-approved limited-release
exception, full 24-creature coverage, tall/device validation, and
`0.8.11-facing-integration` / code `107` Android/Drive delivery. No final release,
full-facing, mechanics or ad claim is made. The approved static proof, 23-master
source checkpoint, 23 development promotions, focused 834/834 GPU pass, reviewed
parked-patch 576/720 lifecycle evidence, earlier r7 captures and `0.8.10` APK do not
close the full-24 release gate.
