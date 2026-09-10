# Facing-miniature production checkpoint — 2026-09-10

Status: **SOURCE CANDIDATES ONLY — no art promoted, no new Android build delivered.**

The user approved the inward-facing direction on 2026-09-08 and explicitly requested its runtime integration and a Google Drive build on 2026-09-10. Investigation confirmed that the earlier front/rear image was a concept only; all 24 production creature sheets and all three living battle-render paths still used side views.

The bounded [implementation checkpoint](../../checkpoints/m11-facing-integration-20260910.md) preserves current rules, stats, saves, decks, card backs, physical UI and the no-AdMob portrait Android configuration. It adopts none of the Reboot gameplay proposal.

## Current production result

- A dedicated seat-aware cache, warm raw-filament shader and focused tests were prepared by the sole Terra writer. Actual stage integration is parked until reviewed art exists so the current playable game does not lose its creatures.
- Planned atlas: 1536×1024, four columns/two rows. Rival/front row uses idle A, idle B, windup, contact; friendly/rear row uses the same beats from behind. Existing nonbattle art remains unchanged.
- Built-in ImageGen returned RGB checkerboard images rather than genuine transparency, including a targeted background-extraction attempt. These cannot be imported as finished sprites.
- An asynchronous user question asks permission for programmatic background removal while preserving generated creature artwork. No programmatic image editing has occurred pending that answer.
- Cinderpaw v3 fixes the low camera, near-identical front idle and exaggerated attack-tail issues found in v1. Rear-visible idle movement and exact idle foot registration still need correction. Camera, identity, tail continuity and action direction passed the second read-only review. Alpha remains a hard failure.
- Aquafin v1 is an opaque magenta-matte source, not a finished transparent sprite. Identity, cells, feet and final alpha still require review.
- The remaining 22 species are not generated. Full 24-species/both-seat lifecycle coverage, runtime visual review and the Android export/Drive delivery remain outstanding.

## Image collection and exact prompts

Every generated image shown during this checkpoint has a durable local link here. Rejected attempts are retained as local correction evidence, never as runtime art.

| Image | State | Prompt |
| --- | --- | --- |
| [Cinderpaw v1](cinderpaw-directional-source-v1.png) | Rejected low camera/idle/tail and baked-checkerboard source | [Exact prompt](cinderpaw-prompt-v1.md) |
| [Cinderpaw alpha-only attempt v2](cinderpaw-directional-source-v2-alpha-attempt.png) | Rejected: still RGB checkerboard | [Exact prompt](cinderpaw-prompt-v2.md) |
| [Cinderpaw corrected v3](cinderpaw-directional-source-v3.png) | Current direction/pose candidate; not alpha-ready | [Exact prompt](cinderpaw-prompt-v3.md) |
| [Aquafin v1](aquafin-directional-source-v1.png) | Opaque matte source awaiting cutout and review | [Exact prompt](aquafin-prompt-v1.md) |

Selected-source SHA-256:

- Cinderpaw v3: `1811F5522609818D2481EA93C76F2F49D8FE7DBAF9554A620A6B9832A79FF440`, 2,970,557 bytes.
- Aquafin v1: `CF9D81A952C96985AA5E993BC9E5535A7366EDE4F9F1A20064ABE6830F50FAA7`, 1,817,763 bytes.

Reference images inspected during this checkpoint:

- [Approved facing direction proof](../m11-living-battles-20260908/direction-proof-facing-inward-v1.png).
- [Original Cinderpaw sheet](../../../assets/creatures/2d/cinderpaw_sprite_sheet.png).
- [Original Aquafin sheet](../../../assets/creatures/2d/aquafin_sprite_sheet.png).
- [Original Voltwig sheet](../../../assets/creatures/2d/voltwig_sprite_sheet.png).
- [Original Mossmunk sheet](../../../assets/creatures/2d/mossmunk_sprite_sheet.png).

## Resume sequence

Resolve the background-removal method, correct Cinderpaw idle registration/rear-readable motion, review alpha on dark/light surfaces, and establish the production grammar before generating the remaining species. Preserve genuine native transparency when available. Do not weaken the alpha acceptance test or substitute screen crops.

Then promote only reviewed sheets through Terra, restore the parked stage integration, validate both seats through print/awaken/deploy/idle/contact/return, inspect full-resolution portrait/accessibility captures, and run exported-runtime checks. Only after those gates should version `0.8.11-facing-integration`, code `107`, be exported and delivered non-overwriting to the established PrintForge folder on Google Drive.

The latest delivered APK remains `0.8.10-physical-ui-polish`, code `106`. Source prototypes or parser passes are not a new playable facing-integration release.
