# M7 blueprint family final batches review

Status: 14 accepted preproduction candidates, each 0 P0 / 0 P1; no complete-family
or runtime promotion

Date: 2026-09-01

Authority: the M7 blueprint-family gate, approved deterministic alpha/mask-only
fallback, committed v2 family brief, and accepted candidate JSONs under
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/`.

All paths below are relative to that `family-v2/` directory. Every accepted RGBA,
light-paper proof, and dark-paper proof is 1254x1254; every thumbnail proof is
160x160. All final accepted candidates passed their bounded original-resolution,
paper, alpha, identity, and thumbnail review with **0 P0 / 0 P1**.

## Exact accepted-version and identity summary

| Creature | Exact accepted JSON | Decision history | Accepted identity/count | Reviewer P2 watch note |
| --- | --- | --- | --- | --- |
| Mossmunk | `mossmunk_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One chipmunk/squirrel; two round ears, attached leaf crest/chest/back accents, four legs, and one continuous spiral leaf-bush tail. | Dense tail hatching slightly compresses on dark paper. |
| Coralisk | `coralisk_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One aquatic salamander/lizard; one attached branched gill crown, attached dorsal spikes, four sturdy legs, and one reef tail; distinct from Aquafin. | Short datum and busy dark-paper detail. |
| Ironmaw | `ironmaw_blueprint_ink_v2-candidate-v3.json` | v1 REVISE: toe/foot mini-raft; v2 REVISE: missing cyan datum; v3 ACCEPT | One armored mastiff-like hybrid; one square jaw, paired lower tusks, four bulky segmented limbs with separate grounded feet, and one short plated tail. | Busy dark-paper detail and short datum. |
| Thunderelk | `thunderelk_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One elk; two attached branching lightning antlers, two long ears, four cloven legs, and attached chest/shoulder plating. | Modest antler top clearance and short datum. |
| Runestag | `runestag_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One stag; one attached antler pair, two pointed ears, four cloven legs, and attached shoulder/haunch rune plates; no floating glyphs. | Rune detail reduces at 160 px but silhouette holds. |
| Galehopper | `galehopper_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One wind hare; two continuous long leaf ears, four slim legs, attached spiral body motifs, and one attached turbine curl tail. | Short datum. |
| Voltwig | `voltwig_blueprint_ink_v2-candidate-v3.json` | v1 REVISE: wrong antler/stag silhouette; v2 REVISE: black/glow/background and branched-ear defect; v3 ACCEPT | One electric jackrabbit; exactly two attached lightning-bolt ears, four long rabbit legs, angular cheek tufts, and one short attached bolt/leaf tail. | Short datum. |
| Miragefox | `miragefox_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One fox; two huge attached ears, one forehead crest, four legs, and one continuous attached multi-lobed crystalline leaf-fan tail. | Dense tail layering on dark paper, but the single attached tail remains coherent. |
| Verdantitan | `verdantitan_blueprint_ink_v2-candidate-v2.json` | v1 REVISE: toe pucks; v2 ACCEPT | One rhino/titan; one nose horn, four grounded legs with integrated feet, one attached leaf mantle/crown, and one broad plated chest; distinct from Stoneback. | Large mantle/chest dark-paper hatching is dense, but hierarchy survives. |
| Glassdrake | `glassdrake_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One low drake-cat; paired attached ear/horns, four legs, attached dorsal/shoulder fins, and one segmented up-curled tail with attached tip; no wings or loose crystals. | Dense facet detail on dark paper, but controlled. |
| Pyraxis | `pyraxis_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One crystal feline; attached crown/ear mane and cheek/limb plates, four legs, and one tall segmented tail ending in one attached crystal fan. | Short datum and interior detail compress at 160 px. |
| Stoneback | `stoneback_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One tortoise/armadillo beast; one continuous domed rock shell, attached face cap, four squat pillar legs, and one short plated tail; distinct from Verdantitan. | Dark shell detail is dense, but outer contour/major plates remain legible. |
| Sparkotter | `sparkotter_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One otter; two round ears, six attached whiskers, four legs, one attached body bolt mark, and one broad paddle/leaf tail with central bolt. | Individual whisker separation becomes fine at 160, though silhouette remains strong. |
| Frostling | `frostling_blueprint_ink_v2-candidate-v1.json` | v1 ACCEPT | One ice fox/cat; two crystalline ears, one short forehead crest, four legs, cheek spikes, and one broad icy fan tail; no wings, extra tail, or floating ice. | Far ear and central crest cluster at thumbnail size but do not read as an extra ear or wing. |

Rejected Ironmaw v1/v2, Voltwig v1/v2, and Verdantitan v1 evidence remains durable
preproduction history. It is neither accepted art nor a fallback.

## Exact accepted artifact hashes

| Creature | Source | RGBA | Light paper | Dark paper | 160 proof |
| --- | --- | --- | --- | --- | --- |
| Mossmunk v1 | `sources/mossmunk-imagegen-rgb-v1.png`<br>`4ED5CC49659F421A1B44944EC6101BB8762166403369CA214E4958D7A560917A` | `mossmunk_blueprint_ink_v2-candidate-v1.png`<br>`2F89A43C70443D8B5769BA240F0C3837BB71565888FE7B0270832376CC057BAE` | `mossmunk_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`4578A43612A2C01D93A20DB6A76CC652FA298AEFA065D5CDA57F246225392D46` | `mossmunk_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`EE6413BAE448033E17EF85275756CE63F5092A6DFA8189BDAF11D2074D9D75E6` | `mossmunk_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`419FADDEFF53B82000B97FDC1E30026A0F3228264446FE34C82E978D40092A4C` |
| Coralisk v1 | `sources/coralisk-imagegen-rgb-v1.png`<br>`4BFEAD1716F5967C5CD418862AE93CEDDFAF04258C0EBF6009BC8751768BE561` | `coralisk_blueprint_ink_v2-candidate-v1.png`<br>`3093BB6A57406D57EB4BF3E1CBA19D46DFC9C7E6CBA0F056DFA34E3EDEFDAAC2` | `coralisk_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`653833418D7A9FC57B13520669E14785876E36E278FFFDD75B6849A5A6136AB0` | `coralisk_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`5271497A3102657592B48810629335A814ED6C0BC2E328AD51322CDC2DFD7414` | `coralisk_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`CBAADBF72796983EAE79103EE26B58C9CFC2DD4F82F993C5B264BBF4A6515629` |
| Ironmaw v3 | `sources/ironmaw-imagegen-rgb-v3.png`<br>`6B616068E5B0CC3AB678151CAC3D20A8CE315DD0496ADA42EB2B54FE094B061C` | `ironmaw_blueprint_ink_v2-candidate-v3.png`<br>`720891C5728C8299A6C49CB5B902152CDD90EEEAEEF6B8D3E9A44C4B95277E4E` | `ironmaw_blueprint_ink_v2-candidate-v3-light-parchment.png`<br>`1D326491A75F36963893A10A86953C73B6D945DD52C86AFCD225829A55BA5CAD` | `ironmaw_blueprint_ink_v2-candidate-v3-dark-parchment.png`<br>`D12D81F117AADEADF8237C5213830C2AD15ED435B980DB0437C30B4369915DA0` | `ironmaw_blueprint_ink_v2-candidate-v3-proof-160px.png`<br>`9B4577692B4FD1BCFDB54D0C21D2DCC68178481F63E069BDE64C3358CCA31F77` |
| Thunderelk v1 | `sources/thunderelk-imagegen-rgb-v1.png`<br>`C270E7B3A09F3AE6FA98F85E6F1D4969DE160A319370269435B5331CC63E5755` | `thunderelk_blueprint_ink_v2-candidate-v1.png`<br>`CBB0B6FCAE9A3CD8F0694A3D405E944E3DC6E7810660FAFF8E9055845975C0CF` | `thunderelk_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`FFB656F5653D2C81FE614EC32CCBA783DAE6EF393EC7CDCFBEDDB38488EA0DF3` | `thunderelk_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`CC564DA8C15575017D06461EB8955875BF2324C32417145F8E754B667D220D66` | `thunderelk_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`652045A94A4209EA2D881A16099E42FB944C75C72B9CD44B390D167C3C43C3AB` |
| Runestag v1 | `sources/runestag-imagegen-rgb-v1.png`<br>`7AEA15090AB832CAB209B4EF20380FA7CED2896C13F8F5C78E902AEAD4076E3C` | `runestag_blueprint_ink_v2-candidate-v1.png`<br>`5F49C3F4B791573B4E58980A11D638684C5F1369576999754D3BED3D0C9DD78F` | `runestag_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`DDCD1AF5A4B473873EEA8A7106A44942CB69AA14C1507BE58FA897A726A572F4` | `runestag_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`E3681E8DD6D18285C3B8ACFED5CAF271FC338E44E5A83B2D8624785B79B6EC71` | `runestag_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`92541F8886B5042927CEE5FC93761ADD7A07C64B4C0724155DBCE0BD90083F19` |
| Galehopper v1 | `sources/galehopper-imagegen-rgb-v1.png`<br>`D0AD3917152A382E59CB1D39C7B6FB2B567BF65BEC1C852F505DA0815D5DEA3E` | `galehopper_blueprint_ink_v2-candidate-v1.png`<br>`80ED7B07A55738B15A6709F54EFB748041275CAF5C85F301B9ABBF707CCD7C5E` | `galehopper_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`BB32A0CFF2F133AAA673008AB64FBCB02A199B1DE71E5916E2E510AD2A7F6B55` | `galehopper_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`957C85B4450D58DE8FEAE4906D7A2325123E027DF2F649AEF0F827921641F653` | `galehopper_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`9D4A0F3D95ADDBEE0D06431200A37077DF1C90C246AD6AC6B7A553305C0A99CF` |
| Voltwig v3 | `sources/voltwig-imagegen-rgb-v3.png`<br>`A1243A6FE7C314563C5DB3B515BB4C863A138641C38D7A3350A210CB2DEE5374` | `voltwig_blueprint_ink_v2-candidate-v3.png`<br>`090F07509569DC843EB2330CE01B9E23DBA4B4B31B477FB443D0FA62F9F19C6A` | `voltwig_blueprint_ink_v2-candidate-v3-light-parchment.png`<br>`E511D828A081CC6C27D0BEE2C52980F71FD9A00508A10D61E342704D47F10783` | `voltwig_blueprint_ink_v2-candidate-v3-dark-parchment.png`<br>`DF597CC016C0DB277717C16B327B4C08D56429C177C6B753244F0B55C4C320A9` | `voltwig_blueprint_ink_v2-candidate-v3-proof-160px.png`<br>`1DCCB0308A10406584B4F57CACF40B4F15CAD0EC547781144D10F4D5087E8946` |
| Miragefox v1 | `sources/miragefox-imagegen-rgb-v1.png`<br>`8B3D8451F2E2CBB1D3C4D5731293CC8C832232BB54D47C3D812EFF3B5D0EC2EC` | `miragefox_blueprint_ink_v2-candidate-v1.png`<br>`9C74F9D8FAE16512B39B912DA75074E7B379CD7DF7A69CE2757457B389A1C694` | `miragefox_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`F98415ABDE226435A23B06B76F168B53525C37B4F2722F1B810B6E3B184A0FDD` | `miragefox_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`9619DB0583740E6300F14CCBF842E119BA2E7E8DD4C49F101CD53D3E23AF2F80` | `miragefox_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`96755B280978C504B3EAEA2CB7B84653F123AE0BFA33905AA5710D1B4AA6513D` |
| Verdantitan v2 | `sources/verdantitan-imagegen-rgb-v2.png`<br>`DCFAB22D9610E1595C029B6DCFAC77D13A4EA12E0F5B550321D0BF6E30DD28C5` | `verdantitan_blueprint_ink_v2-candidate-v2.png`<br>`0CD24B6FB0521C7751B49A96CEA75ADF80B3062F6CC37F6F005F27F6A238B092` | `verdantitan_blueprint_ink_v2-candidate-v2-light-parchment.png`<br>`C6ACB697FEF75F5AA174B0AE77C8712A35D214E781F0CE81584E48E33CA37725` | `verdantitan_blueprint_ink_v2-candidate-v2-dark-parchment.png`<br>`876BC5027973EE5DF56091C69A6E41E4DB999C23EB0398BE0CD2840358002E66` | `verdantitan_blueprint_ink_v2-candidate-v2-proof-160px.png`<br>`DECD530945AF322C2A8A28140F07B04CD0292BF7ABA49A08F1C574BA38F75E45` |
| Glassdrake v1 | `sources/glassdrake-imagegen-rgb-v1.png`<br>`B04D76FE23EEDCFDFF6BDBCCEE7AFAE5E0AC347F65731A13AA65F658DF740156` | `glassdrake_blueprint_ink_v2-candidate-v1.png`<br>`FC4D4918EC940431154F57DD239A2A4DC186E8F51A4BE5A7812698A436BB4421` | `glassdrake_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`6E16B2B92D0CD4AABC115029CCF8B1F31DA35BE9E4E18738A889E1B25A9E77A9` | `glassdrake_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`A97A9EBD378D7A8019190D36A9AAEB5504163A917D9ADB8EE5A2B0F6BB8ABC6F` | `glassdrake_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`57F03A9E30BE3186CD79BF0BA8263ABE04D189EE925681C189E2C171E2162F41` |
| Pyraxis v1 | `sources/pyraxis-imagegen-rgb-v1.png`<br>`0CFCDCA2C62B82BCA35A72B1D96490043E91B08EF269C29BF8A4DB54996316CB` | `pyraxis_blueprint_ink_v2-candidate-v1.png`<br>`78E7DAB324C21019665DF1A77EE81E34A3D09A2CBB60B5638A42FC832491789D` | `pyraxis_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`350F9EF3F07C3E006618D4F3F540D2DD0B7EBA65DB48A670D1EDFBD6C23606ED` | `pyraxis_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`CC64AF255D92D11825BDB0089F51D2FA7BC664182E3FD4A369D0319018F1A5DB` | `pyraxis_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`DDC50DDF58818DEC245BDB866DA067E3F6AFF440F39517259F64CA59D4F2C518` |
| Stoneback v1 | `sources/stoneback-imagegen-rgb-v1.png`<br>`A6406AB141B95E2BB308181627B48CEFA0E6C6B1216D0758F76AAA55614B318D` | `stoneback_blueprint_ink_v2-candidate-v1.png`<br>`25A2798208A885EF8A0C5BE16119A2EE887998B1A68BFC62ACB934F54767C3BE` | `stoneback_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`EBD6BF9F98A67B9677DB1FA6D7B50455BE08A4B324A588FF783C53667780E93D` | `stoneback_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`64458C502A06AA383E5D3241D309E0D1002D97E3F3ED734B79D1F2C775CB680F` | `stoneback_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`91056476C1EABBB5F3E81ED0967B73B5CBD1982DF353099E02553E5A9627CF57` |
| Sparkotter v1 | `sources/sparkotter-imagegen-rgb-v1.png`<br>`327A7ECF8FA7AEFB26A04C80F764BD151E4BDE7087840E5BC70F6830745F094E` | `sparkotter_blueprint_ink_v2-candidate-v1.png`<br>`6FB5AC1810CDADC6B18874ACEC245CC212B8B1BFBED77DC8AC019F5FCFEADB6C` | `sparkotter_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`206A5FDFE9B0F4AB9E1E43F4939ED3693761FF4F654A0EB239ED98BBAF6ADD0A` | `sparkotter_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`68006E3336C1E2B18024C3DECDF4EAF69254FAEFC74BECA9ADD49E7E205CC33B` | `sparkotter_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`FE838F7D276C48998954ECADD4815DE2C872533DA69846C887632FF80A552126` |
| Frostling v1 | `sources/frostling-imagegen-rgb-v1.png`<br>`9AE7D0D1970309D95FA3D147FD52186FB84D85F7271619344529CDDF7B86A99D` | `frostling_blueprint_ink_v2-candidate-v1.png`<br>`F997271642C099EDD0EAA9127319DFDCC0E2234EBF1F8BF076268C43E01B4041` | `frostling_blueprint_ink_v2-candidate-v1-light-parchment.png`<br>`098252AA4355F91E70F5BD1D538BDAB3B76CF208BC297C83265A4F4A6BA8F128` | `frostling_blueprint_ink_v2-candidate-v1-dark-parchment.png`<br>`4254BD26E1CFB8D2827C32A74EAB8B0B284D47B76B327A8C6DCB3F7E2A437865` | `frostling_blueprint_ink_v2-candidate-v1-proof-160px.png`<br>`4BBCDD635925D059D45F2CFDBB3455472B0473C29A91D637415E432B9598BCD4` |

## Final-batches review contract

- **Entry:** Inspect each accepted candidate's durable JSON, unchanged ImageGen
  source, RGBA output, light/dark paper proofs, 160 px proof, and canonical identity
  guard; preserve every rejected revision as evidence.
- **Player decision:** None. Read-only review records `ACCEPT` or `REVISE` per version;
  revision never silently replaces the decision history.
- **Result:** The exact 14 accepted versions above enter the future 24-asset family
  review set with 0 P0/P1, intact identity/counts, real paper-through alpha, bounded
  datum, recognizable 160 px silhouette, and no detached/duplicate anatomy.
- **Failure:** Wrong species, ambiguous count, detached or duplicated part, mini-raft/
  toe puck, missing or facial/ground-line datum, black/glow/opaque background, alpha
  fringe, broken contour, or unreadable thumbnail yields `REVISE` and blocks that
  version from the accepted set.
- **Disabled:** Individual acceptance does not approve rejected versions, an unseen
  asset, the complete 24-family composition, runtime promotion, APK, physical-device
  evidence, DriveFS copy, or cloud synchronization.
- **Feedback:** Retain exact versions/hashes, revision reasons, original-resolution
  findings, light/dark/160 proofs, and every P2 watch note above. P2 notes must be
  rechecked in the eventual physical-route capture matrix.
- **Progression:** Review changes preproduction art status only. It mutates no runtime
  mapping, catalog, ownership, deck, print, battle, reward, economy, profile, save,
  package, delivery, or cloud state.

## Boundary

Together with the committed three-pilot ledger, Aquafin calibration record, and
high-risk batch 1 ledger, this file accounts for the remaining accepted candidates.
It does not itself establish a consolidated 24-asset manifest/hash audit, complete-
family UI/human approval, runtime integration, release APK, device proof, DriveFS
delivery, or cloud-visible copy. Those M7 gates remain open.
