# Workshop navigation art provenance

**Reviewed:** 2026-08-17. The v6 overview plates and established close-ups are
selected built-in image-generation outputs for the spatial Workshop navigation
pass. They were created from the established winter workshop composition and
the canonical Arcane Forge printer plus existing raw-print and living-creature references.
They are environment/navigation art only: no existing creature sheet or raw
print asset was regenerated or modified.

| Runtime asset | Purpose and prompt direction | Hotspot rationale |
| --- | --- | --- |
| [`workshop_overview_landscape_v4.png`](../assets/ui/workshop/workshop_overview_landscape_v4.png), [`workshop_overview_portrait_v4.png`](../assets/ui/workshop/workshop_overview_portrait_v4.png) | v6 direct-object Workshop hub plates: printer and drawers at left, team display/equipment cubby above, stone Battle Arena center, and terminal/card deck at right. | Transparent accessible targets sit over the pictured objects and route directly; the calibration dial claims in place, and Settings remains a compact corner control. |
| [`workshop_printer_closeup_v2.png`](../assets/ui/workshop/workshop_printer_closeup_v2.png) | Arcane Forge close-up with the approved animated-printer design, finished/raw display prints, and filament shelf. | The Forge marker follows the central machine; Collection follows the left display/shelf. |
| [`workshop_maker_closeup_v2.png`](../assets/ui/workshop/workshop_maker_closeup_v2.png) | Maker bench with canonical printed forms, damaged/disassembled pieces, armor, printable tools, and holographic pattern shards. | Team board, deck hologram, armor stand, and calibration dial each get a physical tool hotspot. |
| [`workshop_terminal_closeup_v2.png`](../assets/ui/workshop/workshop_terminal_closeup_v2.png) | Forge terminal workbench with three readable holographic/monitor destinations and pattern-shard dressing. | The three monitor thirds map left-to-right to Offers, Forgedex, and Guild Trade. |
| [`workshop_proving_closeup_v2.png`](../assets/ui/workshop/workshop_proving_closeup_v2.png) | Center proving doorway with training equipment, canonical print displays, and a local-versus marker. | The training table/door and lower local-versus marker are independent objects. |
| [`workshop_yard_closeup_v2.png`](../assets/ui/workshop/workshop_yard_closeup_v2.png) | Snow-lit Print Yard with companion lesson area, raw/finished print storytelling, and workshop continuity. | One broad companion-area hotspot opens the bounded daily Print Yard activity. |

The implementation reads these only through `res://assets/ui/workshop/` in
`scripts/ui/main.gd`. The images use each file's native 3:2 ratio, so
normalized hotspots remain on their pictured props in portrait and landscape.
The compact physical-item glow overlays and integrated Forge blueprint selector
are code-native UI, not baked text or button plaques in the art.

## Ambient and responsive presentation

The Workshop overview and close-ups use the approved art planes. Close-ups use a clipped cover plane in portrait so the room fills the usable viewport; hotspots remain children of that same mapped foreground plane. Their horizontal crop is boundedly pannable by swipe/drag, and keyboard focus pans the target fully into the clipped scene before it activates. The v6 overview chooses a dedicated landscape or portrait plate and uses a static full-plane establishing shot; its direct-object targets map to the matching plate rather than to a cover-backdrop workaround.

`WorkshopHotspotOverlay` supplies soft cyan or amber physical-item corner light for legacy close-ups only and never darkens the underlying art. The v6 overview keeps its accessible direct-object buttons completely transparent, including keyboard focus. `WorkshopAmbientLayer` supplies slow, code-native station-local hologram movement only; the overview remains static. It owns no profile, printer, or game state and freezes at a deterministic readable phase when reduced motion or capture freeze is enabled.

## v6 direct-object overview and station-live plates

| Runtime asset | Generated-asset purpose | Dynamic overlay region |
| --- | --- | --- |
| [`workshop_overview_landscape_v4.png`](../assets/ui/workshop/workshop_overview_landscape_v4.png) | 2026-08-17 v6 landscape Workshop hub plate with the printer, drawers, team display, equipment cubby, stone Battle Arena, terminal, card deck, and calibration dial all pictured as distinct physical objects. | Invisible accessible targets route each pictured object directly to its destination; the terminal panels route independently to Offers, Forgedex, and Guild Trade. |
| [`workshop_overview_portrait_v4.png`](../assets/ui/workshop/workshop_overview_portrait_v4.png) | 2026-08-17 v6 portrait Workshop hub plate, composed independently from landscape. | The same direct-object map is placed against the portrait plate; no overview door, yard, or station-zone target is retained. |

`WorkshopStationLiveLayer` composites the existing alpha Arcane Forge printer frames, catalog raw-print forms, living idle cells, and current active-team instances only into focused Printer and Maker station crops. Its integer-clock sequence is deterministic for capture/testing: ten seconds of bottom-up raw reveal, a raw hold, calm awakening/crossfade, departure, then a seeded choice among learned blueprint IDs. It never calls `GameManager`, saves, journals, changes coins, or changes the team. Reduced Motion is a static, readable raw-print frame. The empty plate regions are deliberate station integration space, not missing generated art.

## Integrated Arcane Forge selector

The overview printer opens the Arcane Forge directly; it no longer visits the
legacy Printer Bench close-up or a separate Blueprint Tray. At idle, learned
catalog cartridges are embedded beside the desktop Forge or below the large
portrait printer. Each compact card shows idle-cell art, element, rarity, exact
catalog cost, and owned count. Selecting a card updates the dormant plate and
fact summary in place without changing profile state. The selector locks once
printing begins, and the existing Arcane Forge commit seam remains the only
coin/inventory authority.
