# Workshop navigation art provenance

**Reviewed:** 2026-08-15. These six runtime images are selected built-in
image-generation outputs for the spatial Workshop navigation pass. They were
created from the established winter workshop composition and the canonical
Arcane Forge printer plus existing raw-print and living-creature references.
They are environment/navigation art only: no existing creature sheet or raw
print asset was regenerated or modified.

| Runtime asset | Purpose and prompt direction | Hotspot rationale |
| --- | --- | --- |
| [`workshop_overview_v2.png`](../assets/ui/workshop/workshop_overview_v2.png) | Dominant winter Makers Guild overview: canonical printer and display prints at left, proving door/yard in the center, terminal at right. | Five normalized zones sit over the physical printer, maker bench, terminal, center proving door, and print yard; Settings is a compact corner control. |
| [`workshop_printer_closeup_v2.png`](../assets/ui/workshop/workshop_printer_closeup_v2.png) | Arcane Forge close-up with the approved animated-printer design, finished/raw display prints, and filament shelf. | The Forge marker follows the central machine; Collection follows the left display/shelf. |
| [`workshop_maker_closeup_v2.png`](../assets/ui/workshop/workshop_maker_closeup_v2.png) | Maker bench with canonical printed forms, damaged/disassembled pieces, armor, printable tools, and holographic pattern shards. | Team board, deck hologram, armor stand, and calibration dial each get a physical tool hotspot. |
| [`workshop_terminal_closeup_v2.png`](../assets/ui/workshop/workshop_terminal_closeup_v2.png) | Forge terminal workbench with three readable holographic/monitor destinations and pattern-shard dressing. | The three monitor thirds map left-to-right to Offers, Forgedex, and Guild Trade. |
| [`workshop_proving_closeup_v2.png`](../assets/ui/workshop/workshop_proving_closeup_v2.png) | Center proving doorway with training equipment, canonical print displays, and a local-versus marker. | The training table/door and lower local-versus marker are independent objects. |
| [`workshop_yard_closeup_v2.png`](../assets/ui/workshop/workshop_yard_closeup_v2.png) | Snow-lit Print Yard with companion lesson area, raw/finished print storytelling, and workshop continuity. | One broad companion-area hotspot opens the bounded daily Print Yard activity. |

The implementation reads these only through `res://assets/ui/workshop/` in
`scripts/ui/main.gd`. The images use each file's native 3:2 ratio, so
normalized hotspots remain on their pictured props in portrait and landscape.
The compact physical-item glow overlays and Blueprint Tray are code-native UI,
not baked text or button plaques in the art.

## Ambient and responsive presentation

The Workshop overview and close-ups use the approved art planes. Close-ups use a clipped cover plane in portrait so the room fills the usable viewport; hotspots remain children of that same mapped foreground plane. Their horizontal crop is boundedly pannable by swipe/drag, and keyboard focus pans the target fully into the clipped scene before it activates. The v3 overview chooses a dedicated landscape or portrait plate and uses a static full-plane establishing shot; its five zones map directly to the matching plate rather than to a cover-backdrop workaround.

`WorkshopHotspotOverlay` supplies soft cyan or amber physical-item corner light and never darkens the underlying art. `WorkshopAmbientLayer` supplies slow, code-native station-local hologram movement only; the overview remains static. It owns no profile, printer, or game state and freezes at a deterministic readable phase when reduced motion or capture freeze is enabled.

## v3 static overview and station-live plates

| Runtime asset | Generated-asset purpose | Dynamic overlay region |
| --- | --- | --- |
| [`workshop_overview_landscape_v3.png`](../assets/ui/workshop/workshop_overview_landscape_v3.png) | 2026-08-15 built-in image-generation stage plate for the 16:9 Workshop overview, informed by the winter workshop reference and canonical Arcane Forge/raw/living references. | Static establishing shot with physical illuminated navigation zones. The empty left bench and right plinths are used only by focused station crops, never by the overview. |
| [`workshop_overview_portrait_v3.png`](../assets/ui/workshop/workshop_overview_portrait_v3.png) | 2026-08-15 built-in image-generation stage plate for the portrait Workshop overview, composed independently rather than cropped from landscape. | Static portrait establishing shot. Focused Printer and Maker crops have independent landmark transforms so live overlays remain physically seated. |

`WorkshopStationLiveLayer` composites the existing alpha Arcane Forge printer frames, catalog raw-print forms, living idle cells, and current active-team instances only into focused Printer and Maker station crops. Its integer-clock sequence is deterministic for capture/testing: ten seconds of bottom-up raw reveal, a raw hold, calm awakening/crossfade, departure, then a seeded choice among learned blueprint IDs. It never calls `GameManager`, saves, journals, changes coins, or changes the team. Reduced Motion is a static, readable raw-print frame. The empty plate regions are deliberate station integration space, not missing generated art.
