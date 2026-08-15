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

The Workshop overview and close-ups use the approved 3:2 art planes. Close-ups use a clipped cover plane in portrait so the room fills the usable viewport; hotspots remain children of that same mapped foreground plane. Their horizontal crop is boundedly pannable by swipe/drag, and keyboard focus pans the target fully into the clipped scene before it activates. The portrait overview keeps a contained foreground for all-station discoverability over a brighter cover backdrop; its zone positions therefore stay attached to the contained plane rather than the backdrop.

`WorkshopHotspotOverlay` supplies soft cyan or amber physical-item corner light and never darkens the underlying art. `WorkshopAmbientLayer` adds slow, code-native printer and hologram movement only. It owns no profile, printer, or game state and freezes at a deterministic readable phase when reduced motion or capture freeze is enabled.
