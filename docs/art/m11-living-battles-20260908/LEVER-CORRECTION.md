# M11 bottom-right lever correction

The user identified incoherent stacked artwork in the lower-right control and asked for a scene-by-scene alignment pass. This is a narrow correction within the approved brass/navy Workshop family, not a new screen direction or gameplay rule.

## Selected candidate

[Opaque inner-aperture insert v1](lever-inner-aperture-v1.png). Built-in ImageGen `exec-26794a6a-df77-4ad6-a8f3-90f26218f931`; 1122x1402 RGB; 2,706,983 bytes; SHA-256 `CBE5AEDE27246F288DECECC26435394BAC38D6DDE9795EB8ADA56AA049199FDF`. C: source copied to E: and hash-verified. Selected and mounted within the existing approved frame; see the scoped review below.

Integration contract: the approved battlefield floor's existing square mount owns the only outer frame. Insert only within its dark inner aperture. The small brass mechanism occupies the upper portion; native `RUN` text occupies the lower portion, measured at 100%/150%. The full `Run Cycle` description remains in native tooltip/accessibility and status. The measured aperture is only about65x50 logical pixels: two lines plus the mechanism cannot fit at genuine12->18px accessibility scaling. Abbreviation is a presentation correction, not a new action. The full existing mount owns the accessible hit, disabled, selected, pressed and focus state. No generated labels. No duplicate framed Godot button. Do not replace the full floor or use the facing concept as runtime art.

Mounted r4 review: `build/evidence/m11-ui1-20260908/writer/battle-lever-r4-576/capture.png`
and `battle-lever-r4-576-hc150/capture.png` pass read-only UI review with noP0/P1
for lever/hand. One visible mount, contained mechanism and nativeRUN at both scales.
The later 720, tall-layout, focus and disabled captures pass the changed-control
review. Press feedback darkens only the inner mechanism and native caption, retaining
the one outer frame. The full comparison and regression evidence is linked from
[UI1 scene audit](../../checkpoints/m11-ui-scene-audit-20260908.md) and the
[runtime capture collection](../../../build/evidence/m11-ui1-20260908/index.html).
Battle's synthetic safe-top boundary remains a separate release follow-up: the
tall image is composition evidence, not safe-area certification. Earlier r2 had a missing asset
import and escaped caption and was rejected despite exit0; the shared runner now
fails on unexpected project ERROR lines, not only script errors or nonzero exits.

Exact prompt:

Use case: precise-object-edit. Asset type: opaque inner-aperture insert for one existing PrintForge game lever control. Image 1 is the exact APPROVED FLOOR as material and camera reference only. Its empty bottom-right square frame has a dark brown/charcoal interior. Image 2 is the LEVER MECHANISM reference; ignore its rectangular leather frame. Generate ONLY a rectangular inset panel to fit INSIDE that empty dark aperture, not the surrounding navy/brass outer frame and not the full battlefield. Portrait-ish 4:5 inset composition. Seamlessly dark matte brown-charcoal metal background extending right to all four edges, matching the floor's aperture; no bevel, border, frame, corner rivets, plaque, glow outline, checkerboard or transparency. In the UPPER 55 percent place the same compact circular brass pivot at left, short horizontal shaft and rounded bronze knob pointing right. Same warm top-left highlights and slightly elevated tabletop camera as the floor. Mechanism safely inset about12% from outeredges. LOWER 35 percent is uninterrupted empty dark matte background where the game will place native RUN CYCLE text later. No text, symbols or letters anywhere in generated art. This is a small opaque internal mechanism plate, no second frame. Preserve restrained worn brass/navy workshop realism; not futuristic or fantasy neon. Show only this one insert edge to edge.

## Rejected transparency attempts — never promote

- [Lever mechanism v1](lever-mechanism-transparent-v1.png), `exec-24de7536-3345-48f7-8d34-8c7edf9f2319`, 1774x887 RGB, SHA-256 `48BFD1EA6C69A91B4F6D993C05CEC3A3D7163B56B88A8FE31626E514AD4F4310`.
- [Lever mechanism v2](lever-mechanism-transparent-v2.png), `exec-bcc8127f-b5af-49e3-bf61-d22b27b1b820`, 1774x887 RGB, SHA-256 `8D97D079A78B4522E238446A3FBC6A056728953B946A38C42207E39A4BC38F01`.

Both images contain an opaque checkerboard despite the transparency request. Verified RGB pixel format and alpha255 at corners. Retained on E: for provenance only; excluded from runtime and final art selection. The alternative is an intentionally opaque aperture insert, not color-keying or inferred mask extraction.

v1 prompt:

Use case: background-extraction. Asset type: transparent game UI lever mechanism derivative. Image 1 is EDIT TARGET: existing PrintForge brass lever on black leather rectangle. Image 2 is MATERIAL/VIEW reference only: approved text-free battlefield floor. Extract and preserve ONLY the circular brass pivot, short brass horizontal shaft and rounded dark bronze handle/knob from Image 1. Remove the entire rectangular outer frame, riveted corner brackets, leather panel, black background and all shadows outside the actual metal mechanism. Produce ONE lever mechanism on a genuinely transparent RGBA background, centered with a little transparent margin. Maintain exact warm worn-brass styling, fine metal texture, top-left light and slight elevated tabletop viewpoint from the reference. The lever will be mounted INSIDE the empty square navy/brass frame in Image 2's bottom right, and the game will draw its native text below it inside that aperture. Do not include any mounting plate, outer border, nameplate, text, letters, rune, caption, wood, screen or additional object. Do not output the full battlefield. Preserve the existing compact horizontal lever identity; no redesign. Clean alpha around the actual metal, no opaque checkerboard, no white halo.

v2 prompt:

Use case: background-extraction. Edit target is the attached lever-only image. KEEP the brass pivot, horizontal shaft and bronze knob EXACTLY as-is. The gray checkerboard is accidentally BAKED INTO RGB and is NOT transparency. Remove EVERY gray checkerboard pixel and every background shadow/reflection completely. Return a real RGBA PNG with ALPHA ZERO outside the metal silhouette, including the entire corners and image edges, while preserving opaque metal highlights. Do NOT draw a checkerboard, white backdrop, black backdrop, floor or frame. One isolated lever mechanism with genuine transparent alpha. No text, no labels, no added objects, no redesign. Output actual transparency, not an illustration of a transparency grid.
