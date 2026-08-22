# Arcane Foundry v2 UI kit

Built-in ImageGen generated the no-text, chroma-key source plates on 2026-08-17
using `docs/art/review/ui-reskin-pitches/round-01/03-arcane-foundry.png` as a
material-only reference. The generated assets are deliberately orthographic:
deep brass/steel bevels, inset slate faces, cyan nodes, and no baked
player-facing copy.

- `outer_panel_chroma_v1.png` -> `assets/ui/arcane_foundry/foundry_panel_compact_v1.png`
- `keycap_primary_chroma_v1.png` -> primary/hover/pressed/disabled keycap textures
- `blueprint_cartridge_chroma_v2.png` -> `foundry_blueprint_cartridge_compact_v2.png`
- `inset_well_chroma_v1.png` -> `foundry_inset_well_compact_v1.png` for nested
  rows and Blueprint detail surfaces.

Extraction uses the installed `remove_chroma_key.py` helper with border
auto-key, soft matte, thresholds 12/220, and despill. Cartridge v1 was rejected
because its black background made its internal surface translucent; v2 has an
opaque center and only uses the uniform magenta background outside the plate.

`tools/build_arcane_foundry_ui_assets.gd` documents the retained deterministic
compact and state-derivative recipe. It reads these approved plates directly,
so the runtime folder contains only consumed compact PNGs. The runtime theme
uses them through `StyleBoxTexture` nine-slices; no generated source under
`docs/` is exported.

`assets/fonts/Arvo-Bold.ttf` is bundled for Foundry headings and keycaps with
its adjacent `Arvo-OFL.txt`. Body copy intentionally retains the readable sans
fallback.
