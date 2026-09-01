# Blueprint v2 complete-family preproduction review

Status: **PASS — preproduction UI review; human full-family approval pending; runtime promotion disabled**

Review date: 2026-09-01

## Exact review authority

This gate binds only the following current files:

| Artifact | Dimensions | SHA-256 |
| --- | ---: | --- |
| `docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/family-manifest-v2.json` | manifest; 24 entries | `9C70CF826C08D8C12348A74B44B505BA7A3850FC927B455685C7B18EFEE7F893` |
| `docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/family-contact-sheet-v2.png` | 1440x2340 | `5DE9CB3C5D50F301ADD74B10E5140B415286144C3BA1E03A34EF9C51162273A8` |
| `docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/family-thumbnails-160-v2.png` | 1260x864 | `BFDCAF22D6D52D990F999CD58C134541AA066A3E2A65AD656CFF3E690EC43066` |

Changing any of these bytes invalidates this gate and requires a new hash-bound
review. Candidate folders, individual reviews, or a later similarly named sheet do
not inherit this PASS.

## Manifest audit

- Exactly 24 entries and 24 unique catalog IDs are present.
- All 24 selected source paths are unique.
- Every selected creature image is 1254x1254 ARGB/RGBA.
- The selected catalog order is exactly:

  1. Cinderpaw
  2. Aquafin
  3. Voltwig
  4. Mossmunk
  5. Frostling
  6. Stoneback
  7. Galehopper
  8. Sparkotter
  9. Glassdrake
  10. Coralisk
  11. Runestag
  12. Brambleowl
  13. Ironmaw
  14. Aurorawing
  15. Thunderelk
  16. Coalgriffin
  17. Tidewhale
  18. Skyforge
  19. Pyraxis
  20. Verdantitan
  21. Miragefox
  22. Voidmanta
  23. Worldcoil
  24. Starloom

- Required maximum corner alpha is `1`; all entries pass. Cinderpaw, Aurorawing, and
  Worldcoil disclose bottom-left alpha `1/255`. Their other corners are `0`; all four
  corners of the other 21 entries are `0`. The three `1/255` pixels are accepted for
  this preproduction sheet gate and must remain disclosed in any deterministic
  derivation audit.
- No unlisted candidate was selected.

## Formal UI result

Read-only inspection of the exact contact sheet, 160-pixel sheet, and manifest is
**PASS** with **P0 none / P1 none**. The set reads as 24 distinct, intact whimsical
creatures on a coherent paper-through blueprint family. Silhouettes and defining
features remain recognizable at 160 pixels; no accepted entry introduces detached
parts, duplicate figures, opaque sticker rectangles, humans, or mechs.

The following P2 consistency/watch groups remain mandatory inputs to derivation and
runtime-route review:

1. **Older full-width cyan/support language:** Cinderpaw, Aurorawing, and Worldcoil;
   Skyforge also has a noticeably longer cyan line. Do not silently normalize these
   through anatomy/content edits. Check family rhythm and support language in route.
2. **Dense dark microdetail:** Mossmunk foliage/tail, Brambleowl plumage, Glassdrake
   facets, Coralisk crown, Ironmaw plating, Stoneback shell, Skyforge wing/plating,
   Pyraxis crystals, Verdantitan mantle, and Miragefox fan tail.
3. **Very short cyan ticks:** Voltwig, Galehopper, Coralisk, Tidewhale, Pyraxis,
   Verdantitan, and Miragefox.
4. **Fine signature features are secondary but survive at 160:** Runestag rune cuts,
   Sparkotter whiskers, Frostling far ear/crest, Thunderelk antler tips, Voidmanta tail
   tip, Starloom narrow far wing lobe/antennae, and Coalgriffin folded far wing.
5. **Pilot provenance links blank:** Cinderpaw, Aurorawing, and Worldcoil have blank
   manifest provenance links. Link their existing approval/provenance records before
   any runtime promotion.

P2 findings do not block the preproduction UI gate, but they cannot be discarded.
Runtime derivation and route captures must prove that dark-paper detail, datum length,
supports, and fine identity cues remain subordinate and readable.

## Human full-family approval decision surface

- **Entry:** Present the exact hash-bound `family-contact-sheet-v2.png`,
  `family-thumbnails-160-v2.png`, and `family-manifest-v2.json` above, together with
  this P0/P1 result, P2 disclosures, and the three blank pilot provenance links.
- **Player decision:** The user chooses **Approve**, **Revise**, or **Reject** for this
  exact complete-family set. Approval must refer to these exact two sheets and
  manifest; approval of a single creature or earlier pilot does not satisfy it.
- **Result:** **Approve** records a dated, hash-bound human decision and authorizes
  deterministic runtime-derivative preparation and completion of provenance links
  under M7. **Revise** records exact requested changes and invalidates affected family
  evidence until regenerated/reviewed. **Reject** keeps the set as history and blocks
  derivation and promotion.
- **Failure:** Ambiguous assent, missing artifact, hash mismatch, unavailable original
  sheet, undisclosed substitution, or no response is not approval and changes no
  authority.
- **Disabled:** Until explicit **Approve**, deterministic runtime derivation and
  provenance work are disabled. Runtime promotion remains disabled even after approval
  until the three pilot provenance links and every M7 integration/review gate pass.
  This UI PASS does not authorize integration, APK, device, DriveFS, or cloud claims.
- **Feedback:** The approval record repeats all three artifact paths/hashes, the exact
  choice, date, reviewer/user identity boundary, P2 groups, pilot-provenance status,
  and the next enabled/disabled gates.
- **Progression:** Approval changes art-production authority only. It grants no card,
  blueprint, currency, deck entry, print, battle result, reward, profile/save change,
  build qualification, delivery state, or cloud state.

Only human approval of these exact two sheets plus this exact manifest can authorize
deterministic runtime-derivative/provenance work. That approval would still not prove
runtime integration, interaction, animation preservation, APK correctness, device
behavior, DriveFS delivery, or cloud synchronization; those require their separate M7
evidence.
