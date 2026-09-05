# M9A Android review delivery — verified

Date: 2026-09-05. Scope: M9A Founder packs, Back navigation and the approved
steampunk Forge. M9B battle/progression and M9C actual 3D models remain NOT COMPLETE.

Source: `7ec8920bfd48ee31a40e7f94ec94e820cb51c1d9`, branch
`spike/printforge-physical-ui`. Runtime/art were reviewed and committed in `39f9635`;
the next two commits corrected test fixtures only. No runtime/art changes followed
the final visual gate. All owned files were committed before final tests/export;
unrelated untracked imports, prior artwork and captures were preserved and excluded
from the APK. This delivery-record commit is documentation-only, not new APK source.

## Final candidate tests

All 18 suites ran from this exact commit in Windows Forward+, with isolated E:
profile/journal/receipt paths configured before autoload access and explicit E:
engine logs. Each direct engine exited 0; console wrapper not used; no owned Godot
or error-dialog processes remained. Exact arguments, ISO timestamps and cleanup
are in each suite's `process.json` beside `engine.log`, `stdout.log`, `stderr.log`
under `build/evidence/m9a-release-7ec8920bfd48/`.

| Suite | Engine PID | Result |
| --- | ---: | --- |
| test_ui_workshop_nav | 54692 | PASS |
| test_m8_progressive_first_print_reveal | 51656 | PASS |
| test_m9_founder_progression | 54300 | PASS |
| test_unified_card_acquisition_ui | 23856 | PASS |
| test_unified_rules | 21852 | PASS |
| test_m8_route_back_contract | 48900 | PASS, all 18 rows |
| test_m8_back_transaction_atomicity | 55568 | PASS |
| test_game_manager_atomicity | 51836 | PASS |
| test_save_recovery | 56692 | PASS |
| test_m3_live_controls | 53616 | PASS |
| test_unified_ui_layout | 50508 | PASS |
| test_m5_android_no_ad | 39660 | PASS |
| test_export_boundary | 53284 | PASS |
| test_runtime_asset_manifest | 55912 | PASS |
| test_checkpoint6 | 50972 | PASS |
| test_arcane_forge_screen_lifecycle | 11816 | PASS, verbose |
| test_m9_real_input_navigation | 53748 | PASS, verbose |
| test_m9_rendered_founder_pack_input | 45840 | PASS, verbose |

Suite interval: 01:25:31.805–01:29:40.952 CT. The last suite completes each of
Cinderpaw/Aquafin/Voltwig and Basic/Forge/Arcane/Primordial/Champion via parsed
mouse/touch/key input, not direct action callbacks. The Workshop fixture now tests
actual cartridge Next/Previous and terminal actions. Its old retired-selector
expectations and the progressive fixture's wall-clock race were corrected without
loosening state/identity assertions or changing runtime animation.

An additional headless pre-autoload negative check (`qa-invalid-root/`) ran engine
55532 at 01:39:11.473–01:39:14.564 CT. Expected exit 1 and `Rejected invalid QA
storage root` occurred before any `marker=profile_load`; cleanup passed. This is an
expected rejection, not an additional failing game suite.

No ObjectDB, CanvasItem, resource-owner leaks or script/parse errors in the final
positive suites. Expected negative storage/JSON diagnostics are distinct from the
Windows certificate-store, renderer shader-cache, Vulkan registry and RGB-to-RGBA
verbose diagnostics.

## Visual gate

Root and independent read-only UI: no P0/P1, combining:

- Normal full-map-v2: 40 PNGs plus logical CommitOnceSkip; manifest SHA-256
  `61CF9AEBB44D392793103E22685F10CB374BC17CC21712F154B8695A16BF6A0A`.
- Unchanged passed Forge/Archive/first-print-return rows in v4-final, manifest
  `0D8E30B97C3F3B23DCF2A8FD79A31AC76AD71F222A465A4FE3F965E429FC0763`.
- All 19 supplemental7 Forward+ original-resolution images, manifest
  `3A95A4177CD6F9984192CD9AFC57BF4CD212BF35FE2ABD3AE20161D1AE935276`;
  unique PNGs/hashes and unchanged authority hashes verified by root/reviewer.

The latter closes Founder/Market/Deck large-text contrast/containment holds, checks
real Level 7, normal Forge copy and a focused persistent-stage resize at 1080x2400
with synthetic safe-top 48 and no extra bottom reserve. P2: some 150% tile/palette
names truncate with full selected facts still available. Superseded failed maps,
duplicate-path supplemental5 and Compatibility-only supplemental6 are not PASS proof.

[Final visual index](../../art/m9-forge-continuity-20260904/final-review-index.md)
exposes the final images, retained complete Forge maps and final rendered input PNG.

## Android export and audit

Identity: `0.8.7-founder-navigation`, code 103,
`com.tak.printforge.legends.playtest`, arm64-v8a only, portrait, no ads/reserve.
Resolved launcher alias: `com.godot.game.GodotAppLauncher` targets portrait
`com.godot.game.GodotApp`. Android retains Mobile renderer metadata; desktop
visual/input evidence is Forward+. Min SDK 24 / target SDK 36.

Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256
`323F9C4CC5DB674E98815CDD8E69DA007D5EFC779ABEDC8C0E42883B7FDEA12A`.
Stock debug template SHA-256
`4FA155D5D45B10C651BF9F59FCF79C5670B59AD5B3AFF6F0E714390BAE37EBF6`.
Android build tools 36.1.0; Temurin JDK 17.0.20+8.

The restricted export (`android-export/`, PID 56368) exited 1 because it could not
write the existing SDK/editor cache. The authorized same-source retry
(`android-export-v2/`, PID 55432) ran 01:31:30.181–01:31:57.754 CT, exited 0 and was
cleaned up. Its process record contains the exact headless export command and E:
paths. No project/runtime change was used to bypass that host restriction.

Final APK was aligned and debug-signed with the existing review key. v2/v3 verify;
certificate SHA-256 `c26373b2320fa530be93f5b6d255a4c8e10e6aa4476e430dedb6106a4de865dc`
matches the previous review. ZIP alignment check passes with 16KB page option.
This is a review/debug artifact, not a production signing claim.

Static audit passes: package/version/ABI, portrait exported alias/intent structure,
main scene, active adaptive icon, approved Forge imports and their actual CTEX
targets, approved branding/blueprint manifest, and exclusions for docs/tests/tools/
builds/plugins/keys/attachments and the two unrelated root PNGs. 448 nonmedia entries
and resolved manifest/resources were scanned with no ad identifiers. All 15 DEX/native
entries match the stock template hashes. Entire runtime source/config ad-token scan
had no matches. Detailed receipts and dumps are under `android-export-v2/`.

Legacy AAPT1 badging rejects string-valued optional Vulkan metadata in both this and
the prior APK. AAPT2 plus the resolved XML were used; the current template's exported
activity-alias is validated directly, not inferred from a missing badging line.
AAPT2's unused stock themed-icon reference warning does not name the verified active
adaptive icon. None of these static checks substitutes for physical device testing.

## Delivery receipt

Destination: `H:\My Drive\AI Projects\PrintForge`. Neither filename existed before
copy. The DriveFS delivery skill copied and verified both against durable local
`E:\AI Projects\games\3d print battler\build\android\` sources.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| PrintForge-Legends-0.8.7-founder-navigation-arm64-7ec8920bfd48.apk | 241387448 | `8B9ACB670A3CDD4A0A7ED39CD534E673F77328ADE7C509311DED524743945054` |
| README-0.8.7-founder-navigation-7ec8920bfd48.md | 5137 | `CC8164B4ADF74D3E1825E5E254374B817ED6BA3EB7B5C3853000D3039E0464F1` |

DriveFS: VERIFIED. Cloud-visible synchronization: PENDING, no independent cloud
connector confirmation. Previous releases untouched. Final device inventory was
empty: install, launch/resume, touch, OS Back, device screenshots and live Android
animation remain BLOCKED — no authorized physical adb device. The review-delivery
milestone is complete within that explicit M5 device-evidence boundary.
