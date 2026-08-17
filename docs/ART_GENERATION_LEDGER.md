# Arcane Forge selected-art ledger

## Support-card landscape atlas (0.5.25-alpha)

Eight approved `1536x1024` 2x2 source sheets live in
`docs/art/source/cards/landscape_v2/`: resources, defense, offense, and utility A/B.
Every source quadrant is `768x512` (3:2). `tmp/build_support_card_landscape_atlases.ps1`
deterministically places A in runtime cells 0-3 and B in cells 4-7, downsampling each
quadrant once to a `384x256` native-aspect cell in a versioned `1536x512` 4x2 runtime
atlas at `assets/cards/support_cards_*_landscape_v2.png`. The source artwork is not
cropped, stretched, or regenerated during assembly. Runtime is allowed to load only
those four v2 atlases; the v1 source atlases remain preserved for history.

| Asset | SHA-256 |
| --- | --- |
| `resources_a_2x2.png` | `557F336558C9772F993CE9AA5B126AF3BA333BFD3DF82F539C27A1377C97716C` |
| `resources_b_2x2.png` | `39B5CA05EDAA7E90F73B00C853EC07B2AACB82E2F81F35A8128DEB7134B3533B` |
| `defense_a_2x2.png` | `3532AF34BBC12AFEA1291962EF024186D591703D89823CDAC810137313862F37` |
| `defense_b_2x2.png` | `FF01CE7B0B82F1D05776C95FBEA35731205CA29F40B3EEBBFAA81C78689E9617` |
| `offense_a_2x2.png` | `E718F37DDAD4FF93B0E9ED0E624C202F1C96A8E4494802A72FCF581B0AF21E4F` |
| `offense_b_2x2.png` | `75001D406A98B84DF16F4C19917AB7366F45DC6DEE4BB1CF105480D74682FFC0` |
| `utility_a_2x2.png` | `F7A4B0E0F8370CFA68E0CAC092F3437A27065884CB8CBE779FB50D9007D559F2` |
| `utility_b_2x2.png` | `5D54601A4A1647AC3863B829262D94868454BB9E0D2F7F665C7CEE0F614E3DA8` |
| `support_cards_resources_landscape_v2.png` | `FF807F5128430FA5AD1C1A1600B90730049B1D6177881059848F9444F1CD96E4` |
| `support_cards_defense_landscape_v2.png` | `21ADE8211E5BA6B8ABB8F4591BD6BB9EC4DE1B5637CC1429E007D60D8487ACD3` |
| `support_cards_offense_landscape_v2.png` | `950F244BABB5BC7379D571BB6809215914B929F0A8E6AF616F1E91A1F762A43E` |
| `support_cards_utility_landscape_v2.png` | `A096108987F8B25CE8FFECADC624787C5FE1CD4C905FE219B4EBC86F40D445C8` |

Checkpoint 6 uses only the selected transparent PNGs already validated in staging:

- `assets/ui/arcane_forge_printer.png` - SHA-256 `D5D8CD574D37D22AF82B304B3F0EF857ECD0D97312522C691D1AC861A8161C6D`
- `assets/creatures/2d/raw/cinderpaw_raw_print.png` - `760B75F78A6BF5ED97022E7669065825BEF205B7331EE35970F3BE04A56C1C08`
- `assets/creatures/2d/raw/aquafin_raw_print.png` - `18058631BE9B95F40DAA34474674DDEB1C57703D1C8A0724B40693F666EEDBC8`
- `assets/creatures/2d/raw/voltwig_raw_print.png` - `7E660CF7E4AF755EBD1CB32C30E6669D67280C752DD15045ED37F773FB54BA64`
- `assets/creatures/2d/raw/mossmunk_raw_print.png` - `289FA69256CB95E7C44BDEF7D5F8EA757E1C3D733A9DB6A57C6169FA16B343DC`

All five files are 32-bit alpha PNGs. The four existing living 4x2 sheets are untouched and remain the awakened forms.

Future approved prompt direction: create a separate dormant, fresh-off-the-build-plate creature in single-color matte PLA with clear layer ridges, assembly seams, support witness points, a small brim or raft, chunky printable walls, and a rigid pose. Keep the same friendly proportions and transparent output. The Arcane Forge presentation will reveal that raw form bottom-to-top under a nozzle sweep, then crossfade it into the existing living sheet with restrained cyan/amber filament sparks. Do not regenerate, edit, or replace the current living sheets. Temporary `tmp/imagegen` material is disposable and excluded from export.

## Forge portrait and launcher follow-up (0.5.1-alpha)

The approved source copies are retained outside the runtime pack at
`docs/art/source/arcane_forge/`. Runtime uses only the alpha-keyed frames below;
the magenta-key sources are deliberately excluded by the export preset.

| Purpose | Source / runtime file | SHA-256 |
| --- | --- | --- |
| Printer source 01 | `docs/art/source/arcane_forge/printer_frame_01_chroma.png` | `C78BE74EF2C5B5336B35A0530943BA83DA36234A09A65830524D31928A875219` |
| Printer source 02 | `docs/art/source/arcane_forge/printer_frame_02_chroma.png` | `F1F58CA61B6BA450A038415CEF33809DE478DA97D91EAE898FDC8103665CEDB9` |
| Printer source 03 | `docs/art/source/arcane_forge/printer_frame_03_chroma.png` | `02F117F69369969AA8CE6AF85805F9A2D0C8B6F486217A8AEC26FCD5B55B6678` |
| Printer source 04 | `docs/art/source/arcane_forge/printer_frame_04_chroma.png` | `A3D34CE6D6EFE812B6664BD8BD124783031C4667B8BE1B7962DE0D894DC2CEDD` |
| Runtime printer 01 | `assets/ui/arcane_forge_printer_frame_01.png` | `EA082E231922F13910AF66045958053E072763972DE7BF48F3A3556EC99EE50E` |
| Runtime printer 02 | `assets/ui/arcane_forge_printer_frame_02.png` | `9A8666E85E07AC17D960D58C02B17A2DA1F57A3AD615807A51C992898CDFC875` |
| Runtime printer 03 | `assets/ui/arcane_forge_printer_frame_03.png` | `9E8737BB8BF6EB091CFAAD949D35EF595F6B67D2A7792D631BD37B34CCB395FE` |
| Runtime printer 04 | `assets/ui/arcane_forge_printer_frame_04.png` | `8D2B1B88E2EE910C8AEC65D32083DB029A06342E09932E3108A59E3C20C217F8` |
| Launcher master/runtime | `assets/ui/printforge_launcher_icon.png` | `211AA133CECC0D89630A7B37F5000DAAEDAD665EA1D7CA3E8B04576547C4D2CE` |
| Runtime workshop boot splash | `assets/ui/workshop_boot_splash.png` | `1C31231063DD81A1D98FD896F56EEE6DD457E96A6B0708033A5412D92A0D5CC9` |

The local deterministic matte pass keys the magenta family by chroma strength,
softens the edge alpha, and decontaminates transparent/semitransparent RGB from
the `#ff00ff` backing color. It was validated with transparent corner pixels on
all four runtime PNGs; the opaque print body is unchanged. The stage uses the
four cleaned runtime frames in ping-pong order, so their generated carriage is
the only print-head animation. It does not draw an extra procedural nozzle.

Current raw and living creature art is not regenerated or edited by this pass.

## Armor raw-print atlas (0.5.16-alpha)

The archived pre-tiered `armor_raw_print_atlas_v1.png` source was a
strict 4x2 built-in image-generation atlas: Helm, Chest Plate, Leg Guards,
Full Suit, Arcane Core, Shadow Cloak, and Titan Plate, followed by an empty
cell. Its prompt direction was dormant, single-color FDM armor parts on a
chroma backing: visible printable segmentation and layer ridges, readable
silhouettes, no final creature or living-form art.

The retired `process_armor_raw_atlas.gd` tool deterministically cropped the seven
cells, converts each source region to RGBA before alpha work, flood-keys the
edge-connected/strong green backing, despills surviving edge pixels, and
centers each alpha-bound part on a 512px transparent canvas. Runtime catalog
paths use `res://assets/armor/raw/*_raw_print_alpha_v2.png`; source and
imported-texture alpha probes cover corners and interior background positions.
The atlas and existing creature sheets are retained unchanged; no runtime
chroma masking is used.
