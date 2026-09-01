# M7 Aquafin paper-through alpha calibration review

Status: PASS for bounded per-asset alpha fallback; no runtime or family promotion

Date: 2026-09-01

Authority: the user-approved deterministic alpha/mask-only fallback in
`m7-blueprint-grammar-human-approval.md`, the M7 per-asset review gate, and
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/aquafin_blueprint_ink_v2-paper-through-v2-calibration.json`.

## Review history

The initial border-connected calibration was rejected by read-only UI review with
**0 P0 / 2 P1**:

1. Enclosed opaque ivory remained as a sticker instead of allowing the owning paper
   surface to show through.
2. The border-connected method was unsafe to extrapolate across the family as a batch
   rule.

The user had explicitly approved deterministic post-processing that changes only
background alpha/mask values on built-in ImageGen outputs while preserving generated
creature pixels and content. The corrected `paper-through-ink` v2 calibration uses
that narrow permission; it is not manual redraw or content editing.

## Corrected source and outputs

All durable paths are under
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/`.

| Role | Path | Dimensions / mode | SHA-256 |
| --- | --- | --- | --- |
| Unchanged ImageGen RGB source | `sources/aquafin-imagegen-rgb-v1.png` | 1254x1254 RGB | `19A7BB74731B9F9C199A0E4EB5CE3B92302BAD956429D7AD0A8E44FCEDE73481` |
| Corrected RGBA calibration | `aquafin_blueprint_ink_v2-paper-through-v2-calibration.png` | 1254x1254 RGBA | `83EBE0175F4ACB612F70173DACD93A11E85C94E0A8657FD8F69C8A2229F7BA54` |
| Light-parchment proof | `aquafin_blueprint_ink_v2-paper-through-v2-light-parchment.png` | 1254x1254 RGB | `72F20071756F3F7B90C6E8F32F53DE862ED38E60B4812A3CBCEE88C1D558257E` |
| Dark-parchment proof | `aquafin_blueprint_ink_v2-paper-through-v2-dark-parchment.png` | 1254x1254 RGB | `6386CBA8E94EF68430A78E7B224C8A5C4D3CFD1205B86DB82A159A580534B191` |
| 160 px light-parchment proof | `aquafin_blueprint_ink_v2-paper-through-v2-proof-160px.png` | 160x160 RGB | `6DAD240FC459F44E1A06436269CC62A25B94FCDC54D0C340FCB856D5FD69C1F2` |

The provenance JSON records alpha range 0-255, alpha `0` at all four corners and
every outer-edge pixel, source-identical RGB bytes for every RGBA output pixel, and a
passing synthetic calibration fixture. It also records the exact algorithm,
parameters, Python/tool identity, alpha counts, and bounded cyan-datum treatment.

## Bounded review contract

- **Entry:** Review the corrected Aquafin RGBA calibration, both full-resolution
  parchment proofs, the 160 px proof, unchanged source/hash, and algorithm ledger.
- **Player decision:** None; this is a read-only UI and evidence re-review of the
  already-authorized background-alpha fallback.
- **Result:** UI re-review is **PASS, 0 P0 / 0 P1**, for Aquafin's bounded per-asset
  fallback only. Paper shows through the illustration; the complete contour remains
  intact; there is no light or dark fringe; the single cyan datum is subordinate and
  bounded; Aquafin remains recognizable at 160 px and distinct from Coralisk; and no
  part is detached, exploded, or duplicated.
- **Failure:** Opaque sticker fill, checkerboard, changed creature/content pixels,
  broken contour/extremity, light/dark halo, dominant or unbounded datum, unreadable
  160 px identity, Coralisk confusion, or detached/duplicate imagery rejects the
  asset and prohibits reuse of its parameters without another per-asset review.
- **Disabled:** This PASS does not authorize batch application, unseen-family
  approval, complete-family approval, runtime promotion, APK qualification, device
  claims, DriveFS delivery, or cloud-sync claims.
- **Feedback:** Preserve source/output hashes, alpha/corner checks, light/dark paper
  composites, 160 px proof, original-resolution UI findings, and these two P2
  cautions: dense hatch detail can become noisy on dark paper, and fine interior
  detail can disappear at thumbnail scale.
- **Progression:** The calibration and review change art evidence only. They mutate no
  catalog, ownership, deck, print, battle, reward, economy, profile, save, runtime,
  package, delivery, or cloud state.

## Gate consequence

Aquafin may be considered a reviewed alpha-calibration candidate when assembling the
future 24-asset family review set. Its P2 cautions must be checked again in actual
Archive, Deck, Forge, and Battle route captures. No asset is runtime-promotable until
the complete family and all M7 human/UI/runtime gates pass.
