# M11: living-print battle art supplement

Status: **preproduction candidate; human approval pending; no runtime changes or new APK.**

This is a bounded supplement to the already-approved full-game atlas. Workshop,
Forge, Archive, Deck, Market, title, icon, and their approved art are not being
redesigned or submitted for reapproval.

## What changes

The six cream card-like platforms become a shared workshop floor. Existing animated
creatures stand directly on that floor, with larger unclipped silhouettes, contact
shadows, perspective scale, and room to step out of their printers and attack.
This is 2.5D staging with the existing sprites, not a conversion to mesh-based 3D.
Cards remain blueprints in the hand; they are not the battlefield creatures.

The approved gameplay changes remain: 200 base printer HP, +50 Chassis, unchanged
normal damage, automatic leftmost deployment with Attack as default, a public
Next Cycle forecast, equipment fitting after print, owned-card deck assistance,
and a guided first bot battle. See the
[M11 checkpoint](../../checkpoints/m11-living-print-battles-v1.md).

## Review artifacts

- [Interactive state atlas](atlas.html) — offline HTML composition document, not the game.
- [Portable screenshot index](review-index.html) — the selected candidate for user review.
- [Text-free generated floor master](battle-continuous-floor-master-v1.png).
- [Exact ImageGen prompt and provenance](PROMPTS.md).
- [QA reference-image index](QA-REFERENCES.md).
- `captures/r7/` is the selected 15-state set at 941x1672, 576x1024 and 720x1280.

### Inspected reference images

- [Previous battle plate](../../../assets/ui/physical_ui/m2/battle-chassis-base-text-free-v1.png).
- [Previously approved attack composition](../printforge-physical-ui-spike-20260830/BA-10-auto-attack-printed-sprites-v2.png).
- [Existing Cinderpaw sprite sheet](../../../assets/creatures/2d/cinderpaw_sprite_sheet.png).
- [Existing Aquafin sprite sheet](../../../assets/creatures/2d/aquafin_sprite_sheet.png).
- [Existing Cinderpaw raw print](../../../assets/creatures/2d/raw/cinderpaw_raw_print.png).
- [Existing Cinderpaw blueprint](../../../assets/creatures/2d/blueprints/v2/cinderpaw_blueprint_ink_v2.png).

Earlier capture revisions are retained locally only as correction evidence.
They are not approval targets, are not part of the selected commit or Drive package,
and must not be promoted. Their findings are recorded in [REVIEW.md](REVIEW.md).

Only the floor master is new raster art. All unit art, raw prints, blueprints, card
backs, and equipment references are existing project assets. Text and state are
separate native HTML layers in this approval document; they must be native Godot
controls in the later implementation. The populated composites must never ship as
runtime backplates.

## Grounded implementation diagnosis

Read-only code inspection identified these causes; runtime reproduction is still
pending the art gate:

1. `PhysicalBattlefieldStage` forces print progress to 100% whenever completion
   produces `pending.place`, even while the print receipt should still animate.
2. The rival loop schedules presentation and waits before rendering that receipt.
3. The battle component prioritizes pending/rival branches ahead of presentation.
4. The stage raw-art resolver handles creatures only, not printed equipment.
5. Living sprites are clipped into shallow card rectangles with opaque caption lips
   and rectangular selection framing.
6. The schematic shader keeps the source's solid alpha between its derived ink
   lines, so unfinished geometry can still read as a filled silhouette.

The fix will sequence visible layer work, raw completion, awakening, step-off, and
attack without replaying authority. Partial jobs must retain progress; each job
must have one visual owner. Public rival queues may show their known print identity;
only rival hand, deck, and hidden trap identities remain private. Idle uses the
first four existing sheet cells, while appropriate action poses use the second row.

## Review and production gates

The read-only final r7 concept review passed with no P0/P1, carrying forward the full
15-state review and checking each corrected state at all three sizes. It covers
the lower-printer launch/hop/landing route, both teams without card-like frames,
print stages, visible attack contact, fitting, and enlarged text. This is not
runtime, animation-timing, input, accessibility-API, or Android certification.
The user must approve this exact battle-art supplement before runtime integration.
The approved gameplay decisions do not need to be approved again.

After that gate: one implementation agent, actual Run Cycle/AI regression tests,
normal and accessibility captures, primary maintainability review, Android package
verification, and a commit-qualified non-overwriting review APK on Google Drive.
Any concept-folder copy is not an APK delivery; DriveFS copy and cloud sync are
separate claims.
