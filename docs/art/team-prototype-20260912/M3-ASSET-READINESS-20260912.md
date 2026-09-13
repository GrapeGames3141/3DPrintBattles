# M3 asset readiness — 2026-09-12

Read-only UI reviewer inspected approved M0 records and existing full-resolution
art. This does not reopen M0 approval or authorize a silent release exception.

## Existing assets

BA-R1 battlefield and TM-R1 workbench composition masters are usable for bounded
integration. Existing cleaned Cinderpaw, Aquafin and Mossmunk inward-facing sheets
are reusable. Voltwig blueprint, raw-print and legacy sprite art are usable in
their corresponding non-directional contexts only. No new native UI/capture pass
is claimed here.

## Voltwig: still blocked

User decision on 2026-09-12: **"Hold the build until front/rear art is supplied."**
No temporary side-view exception is authorized for this prototype. Continue safe
implementation/testing, but do not export or stage an Android review build before
proper Voltwig front/rear art is supplied, reviewed and integrated. Existing side-view
art remains usable only in its approved non-directional contexts/static history.

The legacy `assets/creatures/2d/voltwig_sprite_sheet.png` has eight side-view frames,
not friendly-rear/rival-front views. No directional replacement exists. Preserve
its exact character identity. Do not borrow Cinderpaw anatomy or flip a side view
and call it a rear view.

One built-in ImageGen request on 2026-09-12 used the exact existing identity sheet
and `docs/art/m11-facing-minis-20260910/cinderpaw-directional-source-v4.png` as
camera/grid-only reference. It requested the existing 1536x1024, 4x2, 384x512-cell
family: elevated front top row, rear bottom row, idle A/B, windup and contact, stable
feet, text-free uniform magenta for the previously approved matte-cleanup pipeline.
The golden-yellow quadruped identity, tall forked ears, charcoal inserts and cream
features were explicitly preserved. No image was returned.

Exact tool failure: HTTP400 `moderation_blocked`, output stage, category `other`.
Request ID: `49b97080-5d9e-4726-b1f4-19a99fe47d43`. Prior service rejections were
already recorded in the historical directional-family README. Do not retry by
changing tools/prompts to evade the filter. A supplied approved directional asset
or explicit temporary release exception is still needed if service access remains
unavailable. The old interim release exception is not silently carried into M3.

## Armor: alpha attempt failed; not a runtime asset

Retained draft: [EQ-R1 v3](EQ-R1-quadruped-armor-alpha-attempt-v3.png).
Built-in ImageGen edit of `EQ-R1-quadruped-armor-kit-raw-draft-v2.png`.
The target retained the accepted orange empty quadruped shell/cuffs/raft. Requested
actual alpha, not a painted checkerboard, with no character or new anatomy.

- Output: 1254x1254 PNG, RGB (PNG color type2), 2,204,641 bytes.
- SHA-256: `E369A6E46068E6CA7919E11BB39E75392452144F785869307E4FEE231E4D0CE3`.
- Durable E: copy matches the generated source by size and SHA-256.
- The redundant tool-managed C: intermediate was removed by exact path after
  rechecking both copies as 2,204,641 bytes with the SHA-256 above. The rejected
  draft remains recoverable from its identical E: copy.
- Result: failed transparency; checkerboard remains baked. No runtime promotion.

Exact final prompt:

> Use case: background-extraction. Asset type: production transparent game sprite. Image 1 is the edit target. Change ONLY its background: remove every gray checkerboard square and all ambient background pixels, replacing them with genuinely transparent alpha in the output PNG. Preserve the exact orange empty quadruped armor kit, thin orange fabrication raft, geometry, orange plastic horizontal layer ridges, lighting, cavities and camera. Preserve all existing orange pixels and delicate edges. The backdrop must be actual alpha=0, not a picture of transparency or a solid-colored backdrop. Keep the compact low curved chest/back shell and four open cuff shells exactly as shown, no character inside. No restyling, no extra parts, no animal, mannequin, humanoid or mech, no text, logos, room, floor, haze or shadow outside the raft. Square RGBA production cutout, same framing.

The read-only reviewer identified the existing mask `alpha=clamp(4R-4B-0.1)` as
a viable fallback, previously reviewed only inside an offline printer chamber.
The user explicitly approved deterministic background removal preserving exact shape
on 2026-09-12. The resulting derivative is recorded below and passed read-only UI
and primary review. It has not yet been integrated into runtime assets.

## Armor: deterministic EQ-R1 v2 alpha derivative — accepted for M3 integration

The reusable offline derivation
[`tools/extract_team_armor_alpha.py`](../../../tools/extract_team_armor_alpha.py)
read only the approved-shape source
[`EQ-R1-quadruped-armor-kit-raw-draft-v2.png`](EQ-R1-quadruped-armor-kit-raw-draft-v2.png).
It preserves the 1254×1254 RGB bytes exactly and derives only alpha with the reviewed
sRGB rule `alpha = clamp(4R - 4B - 0.1)`. It does not crop, repaint, reshape, add
objects, or use the failed v3 or the rejected humanoid armor source.

Its outputs and complete reproducibility record are in
[`armor-alpha-v1/`](armor-alpha-v1/):

- RGBA candidate: `EQ-R1-quadruped-armor-alpha-v1.png`, SHA-256
  `6C8DC945F0809E2B46E9A9C86274F4B3418BA84D932BCADB7E0D240AF458262C`.
- Full-resolution light/dark composites and 80px/96px light/dark scale proofs.
- [`provenance.json`](armor-alpha-v1/provenance.json) records source/output hashes,
  dimensions/modes, exact algorithm, synthetic threshold checks, alpha support
  bounds `[112,201,1153,1043]`, transparent corners, and the approval text/date.

Technical checks passed: source/output RGB byte hashes match, the RGBA candidate has
transparent corners, and alpha support is bounded away from every source edge.
Primary independently reran synthetic checks, matched the output SHA-256, and
recomputed every RGBA pixel in memory with exact equality. The read-only UI reviewer
and primary inspected full-resolution light/dark composites and phone-scale proofs.
P0/P1: none. Shape, open cavities, four cuffs, raft and printed layer material remain
intact, with no checker rectangle, gray haze or broad fringe.

A few neutral-bright specular/rivet pixels become translucent at source resolution
(P2); these are not shape-bearing and are imperceptible at the reviewed 80/96px sizes.
Do not present the asset as a large close-up without revisiting that limitation.

Primary accepts this derivative for the planned M3 equipment-print integration under
the user's existing shape approval and explicit cleanup approval. Actual Godot
chamber, progressive reveal and device captures remain required. This acceptance
is not evidence of runtime integration or Android signoff. The retained v3 RGB
failure and its record above remain historical evidence, never an alternate source.
