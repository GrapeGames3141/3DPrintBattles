# Tiered Armor Roster Manifest

Each catalog creature has one transparent, square full-suit master in
`assets/armor/tiered`. The shader remaps only the runtime plate masks across
the five suit tiers, and green-dominant helmet gemstone facets to no-Core gray
or a Core color. The masks are deterministic signature-blue selections with
source-curated component exclusions, so natural blue identity materials remain
unchanged. Do not supply tier variants, Core variants, capes, or weapons.

`cinderpaw_tiered_armor_signature_green_alpha_v3.png` is approved and must not
be replaced. The remaining expected runtime files are:

- `aquafin_tiered_armor_signature_green_alpha_v1.png`
- `voltwig_tiered_armor_signature_green_alpha_v1.png`
- `mossmunk_tiered_armor_signature_green_alpha_v1.png`
- `frostling_tiered_armor_signature_green_alpha_v1.png`
- `stoneback_tiered_armor_signature_green_alpha_v1.png`
- `galehopper_tiered_armor_signature_green_alpha_v1.png`
- `sparkotter_tiered_armor_signature_green_alpha_v1.png`
- `glassdrake_tiered_armor_signature_green_alpha_v1.png`
- `coralisk_tiered_armor_signature_green_alpha_v1.png`
- `runestag_tiered_armor_signature_green_alpha_v1.png`
- `brambleowl_tiered_armor_signature_green_alpha_v1.png`
- `ironmaw_tiered_armor_signature_green_alpha_v1.png`
- `aurorawing_tiered_armor_signature_green_alpha_v1.png`
- `thunderelk_tiered_armor_signature_green_alpha_v1.png`
- `coalgriffin_tiered_armor_signature_green_alpha_v1.png`
- `tidewhale_tiered_armor_signature_green_alpha_v1.png`
- `skyforge_tiered_armor_signature_green_alpha_v1.png`
- `pyraxis_tiered_armor_signature_green_alpha_v1.png`
- `verdantitan_tiered_armor_signature_green_alpha_v1.png`
- `miragefox_tiered_armor_signature_green_alpha_v1.png`
- `voidmanta_tiered_armor_signature_green_alpha_v1.png`
- `worldcoil_tiered_armor_signature_green_alpha_v1.png`
- `starloom_tiered_armor_signature_green_alpha_v1.png`

Per-creature helmet-gem anchors are runtime data in
`scripts/ui/tiered_armor_roster.gd`; update those measured normalized positions
only if an approved master changes its helmet composition.

The Core shader multiplies its signature-green material selector by each
master's measured helmet-local ellipse (`gem_anchor` + `gem_radius`). This is
geometry-only disambiguation, not a hand-painted mask: green/cyan identity
materials outside the helmet ellipse remain unchanged, including Voidmanta's
tail inset.

## Plate-mask provenance

`tools/build_tiered_armor_masks.py` deterministically writes one same-size
grayscale mask per master to `assets/armor/tiered/masks`. It starts from the
approved signature-blue material and supports normalized source-specific
component exclusions; the generated coverage, dimensions, soft-edge count, and
any exclusions are captured in `tiered-plate-mask-audit-v1.json`. These are
runtime inputs, not tier art variants or hand-painted recolor layers.

## Staging provenance

On 2026-08-16 the 23 v1 runtime masters were copied from
`E:\CodexCache\printforge-armor-roster-generated\runtime` to
`assets/armor/tiered` and SHA-256 verified byte-for-byte. Their corresponding
chroma sources are retained in the handoff's `sources` folder under the same
creature ID and `*_blue_green_chroma_v1.png` suffix; identity references are
in the handoff's `references` folder. Cinderpaw remains its already-approved
v3 runtime master and was not copied or altered.

| Creature | Runtime SHA-256 |
| --- | --- |
| Aquafin | `B594BE7E48336E1986B00BABC1A8A1891BBF6FEB82218A58A3CE11CC5B5FD0AF` |
| Aurorawing | `91688EE18874633A48535EE285B0FD52B245EC75AFA0184DC9CBB1464B29B48C` |
| Brambleowl | `05984715F573484F9CF6F5F180ACEAFDD308EE90D16FF2531ADBBAC4F998ED18` |
| Coalgriffin | `A0DC231E41864B0CE703ECA7655C0F53DA2AF9887B7C1CB20B61E015F6FCD439` |
| Coralisk | `D61830EAB0D070D238FFF0A2E48B120706B9D3BE1B3C6B8D53CF7CA120BFDAD4` |
| Frostling | `BCC9CAE6F8F2D5BCCED3B3E2C4ADB251417F88553C350E8342D5226E267EA06F` |
| Galehopper | `97BFDC0CD423437F6666591A82117EB3AD5FAA2E4B92CF159F28A17D84C3893F` |
| Glassdrake | `87B1E55FFA452AB1E16A963C39C89A8B601BA65894CE34F25B9ADF9BEF4CE5A1` |
| Ironmaw | `EEE542C825EDEFC1567CE8C480C7E86F0EF8E9370C3767C7B3E1EA1F25ED72BC` |
| Miragefox | `74613A36A43C4F2AB436A18C2D034B6D594809147E0472838FB289776B8EA969` |
| Mossmunk | `2B81C1EDCFBC1EF3C5C5DCB0E15EA73CD84C97D65FF0C60637092D820F84F665` |
| Pyraxis | `12DF79C321551CBE87078AD38E7AA34B4BD1F8C4D05CFDEA45196E94BE1F90D9` |
| Runestag | `AE68E636CD3B7321AC309AF808C447EE638316CBFF133F99E8BEF3566A09AB57` |
| Skyforge | `A547F7B15B8DB0CADDB41163AB7CE1F25CF207D2AF15828E441A9DD689208DF9` |
| Sparkotter | `D92E7EC6873C9BC3CEE2283F104456F8FAA04F6D5CADF7168961D39F9142C118` |
| Starloom | `4EA29319379767822BEF7106A08D9310E4A96559A34D9227B89B165EF3DB881A` |
| Stoneback | `20BF2D3AFF1F33AC1915656115BC2CD5150D61FD8805F7F565B26F430281DB5B` |
| Thunderelk | `7D278BAB261312218758C04FC5DF314BBCA648D702EC9A874FB54DDA496C0CA1` |
| Tidewhale | `B020D5ED37BFFF384B3242F4D56538BA29FE6019423992C69884D4811C7CE166` |
| Verdantitan | `A743625C8CBA637FB629519DAF8921177FAF1D1849E0C12C79D9A9B8461C711B` |
| Voidmanta | `59C4CD1225DB1DE82FFCCF967DB3930DFC24AD529EF5C3E678680F623A4FDF73` |
| Voltwig | `EDDC70A9042E77F800BF5405DF5839103D760580BFFDB5E7A8B46A3E9A8C59D4` |
| Worldcoil | `6E8CF8376E658B1DD8940A8F4D6D06BBA40E4FBE03E6CD2360841FE79E7A99D8` |

## Chroma-source provenance

The versioned authored chroma delivery is retained at
`docs/art/source/armor/tiered-roster-v1/` (excluded from Android export). The
exact filenames and SHA-256 values below make the master pipeline independently
reproducible. Each maps by creature ID to the runtime master above.

| Chroma source | SHA-256 |
| --- | --- |
| aquafin_tiered_armor_signature_blue_green_chroma_v1.png | `50044E46B7B91B84F4027F8650F23918F8EF09307EE84EB130293FAB2FCF5FDC` |
| aurorawing_tiered_armor_signature_blue_green_chroma_v1.png | `405A54CB6D6151A6130248C8E5770CE31B08BB6B1E87FD88129CC1BE56E86D1A` |
| brambleowl_tiered_armor_signature_blue_green_chroma_v1.png | `2F2EAE85DB86E4272EEFC9ED5ACF4AB6674ED4631CDC3BA7F2D4A64B11DF9926` |
| coalgriffin_tiered_armor_signature_blue_green_chroma_v1.png | `9506F084AD669617C15B8D28A64674B3D7F43D879643AAC34AAF25EDB3A2BF32` |
| coralisk_tiered_armor_signature_blue_green_chroma_v1.png | `7FA63D69E99F80BF45BA5BDDB6793099221D1C6DF646E9CD917C559E119AAE48` |
| frostling_tiered_armor_signature_blue_green_chroma_v1.png | `75C93CC5221B65D68030803C1F981A0D89BD46AF4F5A238E42F4F09EDCC7A995` |
| galehopper_tiered_armor_signature_blue_green_chroma_v1.png | `57775568FE7D7FBB03FDC659246B28430EF166CD91DE073C215CE76D3F876E51` |
| glassdrake_tiered_armor_signature_blue_green_chroma_v1.png | `544EA2BD9C4DFCD6865713BF2C88646BD317C2BB6241FE71622FC229C9DFFE71` |
| ironmaw_tiered_armor_signature_blue_green_chroma_v1.png | `BA4A2AE6155DB09A13C06C031E7616BF6BD428CECDE5FD9905700300714D3C33` |
| miragefox_tiered_armor_signature_blue_green_chroma_v1.png | `31A8CD88E9F7D9970E6B9341403C0C234763D6D9947C9C7D3DEADD1F8575B515` |
| mossmunk_tiered_armor_signature_blue_green_chroma_v1.png | `9C2A974141D953669000B33B03C1CB7E7785DE467821FFBCF49AD845046ACF92` |
| pyraxis_tiered_armor_signature_blue_green_chroma_v1.png | `5BF286119801EFBB7A6A83A68863B7D5C9C08FA49E2D3F8995090DBCB0401AB0` |
| runestag_tiered_armor_signature_blue_green_chroma_v1.png | `E3DFE8CA1D1800C6CCF40308C64EE45255F3508D6ED15BCB96A6F1476E891B90` |
| skyforge_tiered_armor_signature_blue_green_chroma_v1.png | `4D0C191B196506D9F5BCBEC045E8462E4C28B570F955F259AB10C6747E590E51` |
| sparkotter_tiered_armor_signature_blue_green_chroma_v1.png | `17DD9774971D0ADDA63BCD87C7CE94AB2ADD04E5FB34DBF93D09216EFCEBB273` |
| starloom_tiered_armor_signature_blue_green_chroma_v1.png | `C563D010D31ACC9DB5E98384EDF8EA390569359AE4313219882927010528A92B` |
| stoneback_tiered_armor_signature_blue_green_chroma_v1.png | `A170A16F395BB9E1448FA6FA77D00A8A3B3730B725F5B3ABC8E07D52B726AA1A` |
| thunderelk_tiered_armor_signature_blue_green_chroma_v1.png | `D494E4460D177F53A41A21672DF8827924F2137C495E4063F296913442A49E53` |
| tidewhale_tiered_armor_signature_blue_green_chroma_v1.png | `9EAC99604F600B382D3532A163C25452CE394E752D0C7C154949FFCA22A41A23` |
| verdantitan_tiered_armor_signature_blue_green_chroma_v1.png | `7B4E466E1D717A58E9CCAEB552F02C46E694FF7224A57CF471ED908C6D3737B1` |
| voidmanta_tiered_armor_signature_blue_green_chroma_v1.png | `0C2F270A53E84743CEFC93CC9201E96C6A494F809E854DDA2A79430F18FAE226` |
| voltwig_tiered_armor_signature_blue_green_chroma_v1.png | `C912CD24739878F28A1A6BA3DFB1218D6E81FA09F3B760FCA75794613C0F142D` |
| worldcoil_tiered_armor_signature_blue_green_chroma_v1.png | `D9BEBD77B4B180F77DE137AA69A73CC704E6610094E23DD74C856E27AFD59645` |
