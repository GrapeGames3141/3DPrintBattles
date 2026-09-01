# M7 blueprint family high-risk batch 1 review

Status: six accepted preproduction candidates; no runtime or complete-family promotion

Date: 2026-09-01

Authority: the M7 blueprint-family gate, the approved deterministic alpha/mask-only
fallback, the committed v2 family brief, and each accepted candidate JSON under
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/`.

All paths below are relative to that `family-v2/` directory. `ACCEPT` means the named
candidate is admitted to the future complete-family review set. It is not runtime,
complete-family, APK, or delivery approval.

## Exact decisions and identity/count checks

| Creature | Decision history | Accepted identity/count contract | P2 watch note |
| --- | --- | --- | --- |
| Skyforge | v1 **ACCEPT**, 0 P0 / 0 P1 | Exactly one animal griffin: one hooked beak/head, attached crest, one readable tall segmented feather-wing assembly with circular hub, four taloned animal legs, and one attached segmented feather tail. It reads as a plated creature, not a humanoid mech. | Dense plate/hub detail may compress toward a mechanical silhouette on dark paper or at 160 px; recheck animal read in route captures. |
| Voidmanta | v1 **ACCEPT**, 0 P0 / 0 P1 | Exactly one manta in shallow top/side view, with two continuous rounded wings, one compact face/body, attached dorsal plates, and one attached segmented tail ending in one arrowhead tip. | The thin tail segmentation/arrow tip and layered dorsal detail may lose separation at 160 px; do not compensate with detached callouts. |
| Tidewhale | v1 **REVISE** for dense layer-line x-ray treatment and a facial datum; v2 **ACCEPT**, 0 P0 / 0 P1 | Exactly one whale: one continuous bulbous body/head, one dorsal fin, two attached pectoral flippers, and one split fluke. Sparse hatching and a short lower datum keep the face unobstructed. | Fine flipper/fluke and wave-motif interior lines may soften at thumbnail scale; preserve the single-body silhouette rather than adding detail. |
| Brambleowl | v1 **ACCEPT**, 0 P0 / 0 P1 | Exactly one planted owl: two circular eye/brow disks, one hooked beak, one attached pair of branch-antler ear tufts, two attached layered leaf wings, and one attached leaf tail fan. No quadruped or nest/exploded parts. | Eye/leaf hatching can become noisy on dark paper; facial disks and beak must remain the first 160 px read. |
| Coalgriffin | v1 **ACCEPT**, 0 P0 / 0 P1 | Exactly one griffin: one eagle beak/head, one feline quadruped body with four legs, one attached folded wing pair, and one attached feather-fan tail. No separate bird/cat bodies or loose feathers. | Folded far-wing and rear-leg lines can merge at 160 px; confirm one coherent griffin rather than increasing line density. |
| Starloom | v1 **REVISE** for an ambiguous fourth paw, ambiguous far wing pair, and a ground-line-like datum; v2 **ACCEPT**, 0 P0 / 0 P1 | Exactly one fairy-cat with four readable paws, two attached antennae, four distinct attached wing lobes, and one attached segmented tail ending in one star tip. The revised short datum is subordinate and not a ground line. | Far paw/wing separation and the attached star tip may lose clarity at 160 px; route review must not solve this with duplicate or detached anatomy. |

Rejected Tidewhale v1 and Starloom v1 sources, outputs, and JSON ledgers remain as
preproduction revision evidence. They are not accepted candidates or fallback art.

## Accepted candidate hashes

### Skyforge v1

- Source: `sources/skyforge-imagegen-rgb-v1.png` -
  `64090725EF1D8BC5561C87646657FFB3597AD3043C06E8DFBD5912D8C233CA5E`
- RGBA: `skyforge_blueprint_ink_v2-candidate-v1.png` -
  `84BBE759C365288B406179B9102EDE038F4745EFE205FE5E739D0D33FC4299D6`
- Light paper: `skyforge_blueprint_ink_v2-candidate-v1-light-parchment.png` -
  `287C09BC03A9C06A800FCF265082D15A063227ECBA64FCF1266D2F4B7CA647FF`
- Dark paper: `skyforge_blueprint_ink_v2-candidate-v1-dark-parchment.png` -
  `9F4BBCF1D03BA2FD12C19E34708069EA35F36DD64E01B76E1412F260BAD4B39F`
- 160 px: `skyforge_blueprint_ink_v2-candidate-v1-proof-160px.png` -
  `1EFD3550589550484C469BE2E3651383053A197A8082F9B64B57FFE4515D1909`

### Voidmanta v1

- Source: `sources/voidmanta-imagegen-rgb-v1.png` -
  `C855B6055F4798BD0650BDD72BC56A7F0A90E08F655D94E40117252E61E6313A`
- RGBA: `voidmanta_blueprint_ink_v2-candidate-v1.png` -
  `AEBC753A9CE880EF0694CD1CC674709F6940C948E45995FB4D459001E98067C1`
- Light paper: `voidmanta_blueprint_ink_v2-candidate-v1-light-parchment.png` -
  `CF54CDCA99FCD31C30FC58D7B44F354F1EDE6D31D49B5C43F64ADC5B5D35DD4A`
- Dark paper: `voidmanta_blueprint_ink_v2-candidate-v1-dark-parchment.png` -
  `99BBDC616134F722C693E3FD59DA54568A0A2B533218DC50AA21B11F753B2E60`
- 160 px: `voidmanta_blueprint_ink_v2-candidate-v1-proof-160px.png` -
  `D2621C2839763855CEA5973A545BC3E28BCA4F1466270ACD66BD5A66A214858C`

### Tidewhale v2

- Source: `sources/tidewhale-imagegen-rgb-v2.png` -
  `BE8E9A12D86049BB9AFAB6C761CADAB90F153885AE455E7286E02672EE409A2C`
- RGBA: `tidewhale_blueprint_ink_v2-candidate-v2.png` -
  `2229AD9F36588BD229235803560A3A800D838D308CADBD4C322C28DFA47636C6`
- Light paper: `tidewhale_blueprint_ink_v2-candidate-v2-light-parchment.png` -
  `F8868A1348D135FBA039DC7A0970B40C31C8C8440946AC052B9AA35389C2DDF1`
- Dark paper: `tidewhale_blueprint_ink_v2-candidate-v2-dark-parchment.png` -
  `5C57C2AFFFA7143FD4491F63C512F140AE5FE641E98F9CB0390E77F349FD548B`
- 160 px: `tidewhale_blueprint_ink_v2-candidate-v2-proof-160px.png` -
  `A09EF0F40DB659AB3847EA8A41A291818CD84F096D75475DB681974520797A43`

### Brambleowl v1

- Source: `sources/brambleowl-imagegen-rgb-v1.png` -
  `9136A00F48FDD28AC75BEA05336011D511E339A626DB9CDACD4A41AAEBF82429`
- RGBA: `brambleowl_blueprint_ink_v2-candidate-v1.png` -
  `1DCB66C608E02EC22DE1B25893E9D741971594F803061CF617F098383639E882`
- Light paper: `brambleowl_blueprint_ink_v2-candidate-v1-light-parchment.png` -
  `2140B9B1933F748132821CD13B9400090B0260C26EDB7A749118B135219288A1`
- Dark paper: `brambleowl_blueprint_ink_v2-candidate-v1-dark-parchment.png` -
  `A1B65981FD90E975F3B60A8239BFBC0C520DEF8A4F5F2CC7C6255FF48D92B4CE`
- 160 px: `brambleowl_blueprint_ink_v2-candidate-v1-proof-160px.png` -
  `E2A8D550B7551F515DCEB32E0E6FDD50382C3D7A393900E2A69FF43D2056CD5C`

### Coalgriffin v1

- Source: `sources/coalgriffin-imagegen-rgb-v1.png` -
  `592FCBF67A173D5C178897055E05DDF75FCFD86C13AF1810D3AFAB809CEF37DE`
- RGBA: `coalgriffin_blueprint_ink_v2-candidate-v1.png` -
  `E758AC550CDEF31BDEA62CE3E721CD0D66038BA0D240D022B4E81CCD7DE4C455`
- Light paper: `coalgriffin_blueprint_ink_v2-candidate-v1-light-parchment.png` -
  `C5CC35AEF6B095A1A96EE004834F273CF478DE9C5CDD504025974BD41208B3D6`
- Dark paper: `coalgriffin_blueprint_ink_v2-candidate-v1-dark-parchment.png` -
  `F23CDD17C1597A1EFD506D05BAAF0D0797BDB1DE55973E7C1AEE4D63B837B84D`
- 160 px: `coalgriffin_blueprint_ink_v2-candidate-v1-proof-160px.png` -
  `AE5CDA9DC1E12C407BB1CBF5E42C0A3B7A74AF4F8AAFFBDFAC3CFA61C99A9EDE`

### Starloom v2

- Source: `sources/starloom-imagegen-rgb-v2.png` -
  `CCD214C911E8F1EA60BFB5BCE45D97240BDF89A8AFE4A007EE9B101EF6B8B5AF`
- RGBA: `starloom_blueprint_ink_v2-candidate-v2.png` -
  `F328E7B82717AB6D3C05C44DF9CDC8C7813674825120B219DF3BAB89CDD4361B`
- Light paper: `starloom_blueprint_ink_v2-candidate-v2-light-parchment.png` -
  `F979EA38FE2F8196CB6B2AEE6A48F31EC3E5FC7294A2E5E914BED07A72D0686A`
- Dark paper: `starloom_blueprint_ink_v2-candidate-v2-dark-parchment.png` -
  `B60D5387FD6C52724DE26B8A6ADD838992A2ECDA9B2CFB62707CC938F8AF42F2`
- 160 px: `starloom_blueprint_ink_v2-candidate-v2-proof-160px.png` -
  `237E4F9A84F0E70F1D30B0A1F7E777BF2B9DA213B53DF5941337A689006FE26D`

## Batch review contract

- **Entry:** Review each candidate's unchanged ImageGen source, RGBA output, light and
  dark paper composites, 160 px proof, JSON provenance, and canonical identity guard.
- **Player decision:** None; the read-only review records `ACCEPT` or `REVISE` for the
  individual preproduction candidate.
- **Result:** The six accepted versions above enter the future 24-asset family review
  set with intact paper-through silhouettes, real alpha, bounded/subordinate datum,
  exact identity/count acceptance, and no P0/P1 at their final review.
- **Failure:** Identity/count ambiguity, detached or duplicated anatomy, ground-line
  or facial datum, x-ray-like density, opaque paper, fringe, broken contour, or failed
  160 px recognition yields `REVISE`; it cannot be hidden by alpha processing.
- **Disabled:** Individual acceptance does not approve a rejected version, an unseen
  creature, the full family, batch-wide extraction parameters, runtime promotion,
  APK, device, DriveFS copy, or cloud synchronization.
- **Feedback:** Preserve every accepted/rejected candidate and decision, hashes,
  original-resolution findings, light/dark/160 proofs, identity/count result, and P2
  watch note. P2 issues must be checked again in physical route captures.
- **Progression:** Review changes preproduction art status only. It mutates no runtime
  mapping, catalog, ownership, deck, print, battle, reward, economy, profile, save,
  package, delivery, or cloud state.

## Boundary

This batch supplies six candidate entries toward the future family manifest. It does
not establish that all 24 creatures exist or pass together, and it does not satisfy
the complete-family human/UI/runtime gates in the M7 readiness checkpoint.
