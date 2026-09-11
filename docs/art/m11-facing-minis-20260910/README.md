# Facing-miniature production checkpoint — 2026-09-10

Status: **23 source sheets generated; cleanup, registration and runtime validation in progress. No new Android build delivered yet.**

The user approved inward-facing direction on September 8 and requested runtime integration plus Google Drive delivery on September 10. Earlier forward/rear evidence was concept-only; the playable game used side-biased creature sheets. This work integrates production front/rear poses through print, awaken, deploy, idle and attack.

The [implementation checkpoint](../../checkpoints/m11-facing-integration-20260910.md) preserves current mechanics, saves, decks, card backs, physical UI and no-AdMob portrait Android configuration. No Reboot gameplay proposal is adopted.

## Authority and status

- User explicitly approved programmatic background cleanup with “yes do it.” Cleanup preserves generated creature pixels; only matte/antialiasing and mathematical registration are changed offline.
- Eight poses per species, 1536×1024: top rival/front, bottom friendly/rear; each row idle A, idle B, windup, contact.
- Built-in ImageGen produced sources. Selected files were copied from tool-managed C: to durable E: storage and SHA-256 compared.
- Terra is sole cleanup/runtime writer; UI review is read-only. Original-resolution and phone-slot proofs precede final promotion.
- Runestag’s first alpha extraction was rejected for translucent body material; revised spatially bounded cleanup preserves solid violet material and passed re-review.
- Aquafin foot registration/material appearance remain under slot-size review.
- Voltwig generation was rejected twice by the service (output moderation). No directional source exists. User was asked whether an explicitly limited interim 23-species release is acceptable; **no exception approved yet**.
- Incremental development integration is allowed for approved candidates; full roster remains a release gate unless user approves an exception.
- Target 0.8.11-facing-integration/code107 remains subject to validation. Latest delivered APK is still 0.8.10-physical-ui-polish/code106.

## Durable image collection

The [common family prompt](directional-family-prompt.md) plus each species note reconstructs generation. Original species atlas supplies identity; Cinderpaw v4 supplies camera/grid only. Green mattes protect pink/purple creature materials.

| Species | Generated master | Prompt | Matte |
| --- | --- | --- | --- |
| aquafin | [Source](aquafin-directional-source-v1.png) | [Prompt](aquafin-prompt-v1.md) | Magenta |
| aurorawing | [Source](aurorawing-directional-source-v1.png) | [Prompt](aurorawing-prompt-v1.md) | Magenta |
| brambleowl | [Source](brambleowl-directional-source-v1.png) | [Prompt](brambleowl-prompt-v1.md) | Magenta |
| cinderpaw | [Source](cinderpaw-directional-source-v4.png) | [Prompt](cinderpaw-prompt-v4.md) | Magenta |
| coalgriffin | [Source](coalgriffin-directional-source-v1.png) | [Prompt](coalgriffin-prompt-v1.md) | Magenta |
| coralisk | [Source](coralisk-directional-source-v1.png) | [Prompt](coralisk-prompt-v1.md) | Magenta |
| frostling | [Source](frostling-directional-source-v1.png) | [Prompt](frostling-prompt-v1.md) | Magenta |
| galehopper | [Source](galehopper-directional-source-v1.png) | [Prompt](galehopper-prompt-v1.md) | Magenta |
| glassdrake | [Source](glassdrake-directional-source-v1.png) | [Prompt](glassdrake-prompt-v1.md) | Magenta |
| ironmaw | [Source](ironmaw-directional-source-v1.png) | [Prompt](ironmaw-prompt-v1.md) | Magenta |
| miragefox | [Source](miragefox-directional-source-v1.png) | [Prompt](miragefox-prompt-v1.md) | Green |
| mossmunk | [Source](mossmunk-directional-source-v1.png) | [Prompt](mossmunk-prompt-v1.md) | Magenta |
| pyraxis | [Source](pyraxis-directional-source-v1.png) | [Prompt](pyraxis-prompt-v1.md) | Green |
| runestag | [Source](runestag-directional-source-v1.png) | [Prompt](runestag-prompt-v1.md) | Magenta |
| skyforge | [Source](skyforge-directional-source-v1.png) | [Prompt](skyforge-prompt-v1.md) | Magenta |
| sparkotter | [Source](sparkotter-directional-source-v1.png) | [Prompt](sparkotter-prompt-v1.md) | Magenta |
| starloom | [Source](starloom-directional-source-v1.png) | [Prompt](starloom-prompt-v1.md) | Green |
| stoneback | [Source](stoneback-directional-source-v1.png) | [Prompt](stoneback-prompt-v1.md) | Magenta |
| thunderelk | [Source](thunderelk-directional-source-v1.png) | [Prompt](thunderelk-prompt-v1.md) | Magenta |
| tidewhale | [Source](tidewhale-directional-source-v1.png) | [Prompt](tidewhale-prompt-v1.md) | Magenta |
| verdantitan | [Source](verdantitan-directional-source-v1.png) | [Prompt](verdantitan-prompt-v1.md) | Magenta |
| voidmanta | [Source](voidmanta-directional-source-v1.png) | [Prompt](voidmanta-prompt-v1.md) | Green |
| worldcoil | [Source](worldcoil-directional-source-v1.png) | [Prompt](worldcoil-prompt-v1.md) | Magenta |

Candidates, dark/light proofs and provenance are under [cleaned](cleaned/). Sources/review assets are excluded from Godot imports by .gdignore. Runtime assets belong separately under assets/creatures/2d/battle-facing; candidate existence is not release approval.

## Earlier corrections and failed generation

- [Cinderpaw v1](cinderpaw-directional-source-v1.png), [prompt](cinderpaw-prompt-v1.md): rejected camera/idle/tail.
- [Cinderpaw v2 alpha attempt](cinderpaw-directional-source-v2-alpha-attempt.png), [prompt](cinderpaw-prompt-v2.md): still RGB checkerboard.
- [Cinderpaw v3](cinderpaw-directional-source-v3.png), [prompt](cinderpaw-prompt-v3.md): corrected camera, superseded rear-idle/matte.
- [Voltwig attempted prompt](voltwig-prompt-v1.md): no output; service request IDs 6c95db58-8d7d-4977-bd63-d2ef49c3a50c and 475f1a9a-0c7e-4f16-8ea1-be8aad10b619.

## Approved direction and delivery gates

[Approved concept](../m11-living-battles-20260908/direction-proof-facing-inward-v1.png) and [direction record](../m11-living-battles-20260908/FACING-DIRECTION.md).

Required: stable roots/alpha; actual Main/coordinator both-seat lifecycle and deterministic checks; portrait/accessibility captures; no blocking visual finding; exported-runtime checks; signed arm64 metadata and no-ad audit. APK/README must have commit-qualified non-overwriting names in the established Google Drive PrintForge release folder. Compare bytes/SHA-256; distinguish DriveFS copy from cloud sync.
