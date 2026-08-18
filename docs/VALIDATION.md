# Validation record

## Android 0.6.5 missing runtime asset fix (2026-08-17)

- **Root cause and repair:** Android excludes `docs/*`, while `main.gd` and
  `creature_art_gallery.gd` eagerly referenced
  `docs/art/reference/workshop-theme-reference.jpg` before the first scene.
  The exact 132,628-byte provenance JPG (SHA-256
  `86C81AE183A7B1A2B70E84E4BC318BC98952BEB1EF7BE183AD267F302F55EE5B`)
  is now copied to the runtime path
  `assets/ui/workshop/workshop-theme-reference-fallback.jpg`; all runtime
  references and Main's unknown-workshop fallback use that path. The source
  reference remains in `docs/art/reference/` for provenance.
- **Regression and focused gates:** `test_export_boundary.tscn` recursively
  rejects any `res://docs/` dependency from `scripts/` and proves the Main
  scene, both affected scripts, and the fallback texture exist and load. It
  passed in a fresh E:-hosted APPDATA/LOCALAPPDATA/TEMP root (Godot console
  PID 12960, exit 0). Existing `test_startup_isolation.tscn` also passed in a
  separate fresh E: root (PID 23900, exit 0), reaching the Forward+ onboarding
  first-frame marker. Parser/import scan PID 25408 exited 0 with no GDScript
  parse errors; the durable repository's known `.godot` cache ACL diagnostics
  were retained as environmental output.
- **Export and archive audit:** Android Review is now version code 80/name
  `0.6.5-missing-runtime-asset`, with a non-overwriting arm64 debug artifact
  name. A writable exact-source E: staging copy hash-verified all eight changed
  runtime/preset/test files before import/export. Godot 4.7.1 console PID 21380
  exported and signed `PrintForge-Legends-0.6.5-missing-runtime-asset-arm64.apk`:
  145,855,231 bytes, SHA-256
  `C9ACB4D8DC0D0300AB56B186AB4829BB74D4EF364D3A10525161912D4F68138A`.
  `apksigner` verifies v2/v3 with the Android Debug certificate and `aapt2`
  reports `com.tak.printforge.legends.review`, code 80/name
  `0.6.5-missing-runtime-asset`, min/target SDK 24/36, and arm64-v8a only.
  The 461-entry archive has exactly one fallback `.import` and matching
  `.ctex`, and zero `docs/`, backend, tests, tools, Git, or node_modules
  entries. No physical Android device was attached, so device launch/smoke is
  still pending.

## Android Forward+ startup-isolation launch checkpoint (2026-08-17)

- **Symptom and scope:** The physical 0.6.3 review build showed the configured workshop splash, then a uniform dark-gray full-screen surface indefinitely. This proves Android launched the activity and displayed the Android/Godot splash, but does not by itself prove a native crash. A same-phone build line worked the prior day, so Forward Plus remains unchanged pending a 0.6.2-to-0.6.3 source and APK boundary comparison plus phone logcat. No combat, queue-limit, or performance change is part of this checkpoint.
- **Bounded startup isolation:** The 0.6.3-only `opponent_rules.gd` is a 464-line/18,852-byte compiled daily-contract module. It was eagerly preloaded through `ProfileRules`, `CampaignRules`, and `GameManager` even though the workshop/onboarding first frame does not use it. 0.6.4 keeps Forward Plus and defers that module until the Proving Door/Workshop Trials request it; profile migration no longer creates unused daily-training fields during startup. Main likewise defers Battle, Forge, support-card, Equipment Workbench, tier-preview, and Local Battle stage resources until their screens are opened. Each optional path has a Workshop-safe failure message rather than making the shell unavailable.
- **Desktop gate:** `test_startup_isolation.tscn` verified the optional daily-opponent/Battle/Forge/Equipment/tier-preview/Local-stage paths were uncached before Main and after the first onboarding frame, while the Proving Door and Equipment Workbench loaded their modules on demand. It also verified no direct optional preload or `BattleSpriteStage.new()` remains in Main. The final scene-by-scene retained suite passed 39/39 with fresh E:-hosted `APPDATA`/`LOCALAPPDATA`/`TEMP` per scene and exact console PID/exit/raw-output records in `E:/CodexCache/printforge-android-triage/retained-suite-064-startup-isolation-net2/accepted-suite-manifest.json` (the raw attempt history is preserved alongside it); the final startup-isolation rerun was PID 2956, exit 0, and the long `test_move_presentation` case was PID 24236, exit 0 within its sole 180-second bound. A source parser/import scan was PID 1932, exit 0; it retained known repository `.godot` ownership/import-cache write diagnostics but reported no script parse error. The root-certificate-store warning and headless dummy-renderer cleanup warnings remain environment output.
- **Raw pre-change emulator evidence:** `E:/CodexCache/printforge-android-triage/emulator.stderr.log` is retained outside Git. The E:-hosted API 35 Google APIs x86_64 AVD failed before boot with `x86_64 emulation currently requires hardware acceleration` and `Android Emulator hypervisor driver is not installed on this machine`; `emulator -accel-check` returned exit 6. Firmware virtualization was disabled, so this checkpoint did not change Windows features, drivers, or BIOS settings. Consequently there is no emulator install/logcat/screenshot result and no Android launch-pass claim.
- **APK under test:** `build/android/PrintForge-Legends-0.6.3-opponent-diversity-arm64.apk`, SHA-256 `5F68E8518CD73A40F6028F7A90990AA09BD56CE1DC0A48B14F41EA6064841090`, 145,019,387 bytes; `aapt2` reported `com.tak.printforge.legends.review`, code 78/name `0.6.3-opponent-diversity`, min/target SDK 24/36, GLES 3 required, and only `arm64-v8a`. `apksigner` verified debug v2/v3 signatures. It uses Godot `4.7.1.stable.official.a13da4feb`; matching templates SHA-256 `86409DB6200B6F8FD3230989C2D2002851F3DD18ACF11D7BDBAFDDF5A0DD0F72` are retained on E:. The required pre-fix raw APK and emulator output are not overwritten.
- **Final debug review APK:** The source preset is code 79/name `0.6.4-startup-isolation`; export used a writable E:-hosted exact-source staging copy after verifying hashes of each changed source/config/test/tool file against this repository, because the repository-owned `.godot/exported` cache is inaccessible to the sandbox. Godot 4.7.1 console PID 17972 exited 0 and produced `build/android/PrintForge-Legends-0.6.4-startup-isolation-arm64.apk`, 145,023,483 bytes, SHA-256 `4E6AABF10C91ADDE1B6AE86AA9EFC3AAE46CADB20EC82FF36EFF7DAE7A929F3F`. `aapt2` reports `com.tak.printforge.legends.review`, min/target SDK 24/36, code 79/name `0.6.4-startup-isolation`, and only `arm64-v8a`; `apksigner` confirms the Android Debug signer plus v2/v3 signatures. Archive audit found only `lib/arm64-v8a/libc++_shared.so` and `lib/arm64-v8a/libgodot_android.so`, with zero backend/docs/tests/tools entries. The manifest contains `com.godot.game.GodotApp` plus the exported MAIN/LAUNCHER alias `com.godot.game.GodotAppLauncher`.
- **Phone smoke procedure:** With a connected device, run `powershell -ExecutionPolicy Bypass -File tools/android_smoke.ps1 -ApkPath <final-apk> -Mode clean` and then `-Mode upgrade -PriorApkPath <prior-apk>`. In clean mode it queries whether the package exists before uninstalling; it dynamically resolves the exported launcher alias, checks native adb exit codes, saves the PNG through a binary stream, and fails after eight seconds unless both a process PID and `PRINTFORGE_STARTUP marker=first_frame` are present. It retains raw logcat, `am start -W`, activity/process state, screenshot, and markers under the supplied E:-backed artifact directory on success or failure. Verify workshop/onboarding interaction, portrait/landscape, suspend/resume, Back, and a short workshop/battle flow before accepting the release; Android runtime validation remains pending the physical-device result.

## Tiered full-suit and Core checkpoint (2026-08-16)

- The active catalog is schema 8 / `0.6.0-tiered-suits`: five complete-suit tiers and five optional socketed Cores. The approved Cinderpaw signature-green v3 master is the sole tiered runtime master; the shader recolors blue-dominant plates and green-dominant gemstone material, with a smoky-gray unsocketed stone.
- Reviewed non-headless OpenGL evidence is retained outside the project at `E:/CodexCache/printforge-equipment-artifacts/`: 576x1024 and 1280x720 Workbench (including empty and socketed Core states), Suit Forge/Core Lab select-print-hold states, armored Team Cinderpaw, and Legendary+Arcane battle activation peak. `SHA256SUMS.txt` records every capture hash.
- Full isolated retained suite passed 33/33 scenes after the current-fixture conversion. Console PIDs: 26836, 25428, 8556, 26988, 3948, 2764, 996, 27244, 13096, 12548, 18792, 5920, 25464, 22316, 26292, 26844, 27516, 21180, 11360, 17180, 17544, 22816, 24080, 16388, 1948, 23940, 23152, 2932, 22856, 3868, 23032, plus focused reruns 10128 and 22336. The Windows root-certificate-store warning and headless dummy-renderer cleanup warnings remain non-fatal environment output.
- Final parser/import PID 8504 and post-exclusion tier-palette smoke PID 1300 exited 0. Final debug export PID 25212 exited 0: `E:/CodexCache/printforge-equipment-artifacts/PrintForgeLegends-0.6.0-arm64-debug.apk`, 122,289,768 bytes, SHA-256 `4A382878AF5B7B8887613B6E96A434318B53B623709AC316DFF57AE986116819`. Independent `apksigner` confirms v2/v3 signatures; `aapt` reports `com.tak.printforge.legends.review`, versionCode 75, versionName `0.6.0-tiered-suits-cores`, and only `lib/arm64-v8a` native libraries. Archive audit found no tests, tools, backend, docs, runtime roots, or retired modular raw assets. The installed `aapt` returns its known nonzero `android:required` parsing warning after emitting valid metadata.
- The archived pre-tiered raw PNGs and sidecars have zero active callers and are explicitly excluded from Android export; the full-suit and Core raws remain the only shippable equipment print assets.
- Final corrective regressions: `test_core_power_vfx` proves two Arcane-equipped units render only the event actor's finite helmet-local activation and clear both atlas overlay and compact halo after the event, including reduced motion. `test_ui_checkpoint_a1` runs six accepted player Basic Attacks against durable Voidmanta with rival Defends at 576x1024 and 1280x720, asserting exactly one action dock/grid, viewport-contained four moves plus secondary toggle, and stable dock top/height. Focused console PIDs `25212`, `3156`, `26212`, and `14144` exited 0; post-tightening UI A1 PID `11008` exited 0. Final multi-turn OpenGL evidence is `battle_armored_cinderpaw_multiturn_576x1024.png` (`bfca98c817649bdb05474ee821c08b093e27f38ccacb2083c7a265e1d2eeb7e8`) and `battle_armored_cinderpaw_multiturn_1280x720.png` (`1e22067482c300a7b35096f5ce9fbf0eda3a4bd4a0f8389a593d104393ef87f9`) from console PID `4540` under the external artifact root. Final parser PID `1392` and post-fix debug export PID `6640` exited 0. The refreshed APK is 122,289,768 bytes, SHA-256 `29BC8ACB99C501ABAA5C0C331C4636323D1A6D22CD19564F05F824CCA055ABF1`; independent audit reconfirmed debug v2/v3 signature, `com.tak.printforge.legends.review` / code 75 / `0.6.0-tiered-suits-cores`, arm64-only native libraries, and zero excluded runtime/test/tool/docs/retired-raw entries. `aapt` retains its documented post-metadata `android:required` warning.

## Checkpoint 0.5.25 landscape support-card art (staging only)

- The four approved v2 runtime atlases are 1536x512 4x2 sheets; every mapped card
  region is a complete 384x256 3:2 cell. `CardArtAspect` holds the visible art
  window at 3:2, so centered containment fills it without crop, pillarbox, or
  letterbox space while the external support-card silhouette remains 2:3.
- Focused support-card mechanics/catalog test passed: console PID `17968`, worker
  PID `8740`. Focused UI regression passed: console PID `22276`, worker PID
  `25812`; it asserts actual post-layout 2:3 cards, 3:2 art viewport/regions,
  required title/rules/target hierarchy, privacy/noninteractive policy, and bounded
  four-card portrait/landscape carousels. The final exact all-30 approved A/B atlas
  mapping assertion also passed in the focused catalog/UI rerun (console PIDs
  `24952`/`26448`, worker PIDs `4064`/`16996`).
- Fresh inspected OpenGL captures under `E:/CodexCache/printforge-validation/`
  use the `cardartlandscape-review` tag: Archive `19088`/`3300`, Deck
  `6484`/`16528`, Shop `9448`/`21056`, first-fold Battle Hand `23424`/`7352`,
  focused complete Battle Hand `6956`/`26520`, and Local revealed `10448`/`8924`,
  each ordered `576x1024` then `1280x720`. Inspection confirmed full 3:2 art fill,
  readable text hierarchy, and unchanged first-fold move controls.
- Final parser passed: console PID `23924`, worker PID `21580`, exit 0. Retained
  suite passed 29/29 through the fresh E:-backed APPDATA/LOCALAPPDATA process
  pattern; manifest
  `E:/CodexCache/printforge-validation/card-landscape-art-retained-suite-0525.txt`.
  The non-marginal move-presentation case passed in 63 seconds (console PID
  `25980`, worker PID `13940`).
- Debug Android export passed: console PID `22972`, worker PID `17448`, exit 0.
  `PrintForge-Legends-0.5.25-alpha-landscape-card-art-arm64.apk` is 122,199,559
  bytes with SHA-256 `66B9140158CE5E8E65B5CC6ADDD9D5248D400CE158CD9E9389F94E743557E7F6`.
  `apksigner` verifies v2/v3; `aapt` reports package
  `com.tak.printforge.legends.review`, versionCode `75`, versionName
  `0.5.25-alpha-landscape-card-art`, and only `arm64-v8a` native libraries. Archive
  exclusion audit found zero backend/test/tool/source/provenance paths or raw atlas
  source files. (The installed `aapt` returns its known nonzero
  `android:required` parsing warning after emitting valid package metadata.)

## Checkpoint 0.5.24 contained support-card art (staging only)

- Front `CardArt` now uses centered aspect containment instead of aspect-covered
  rendering. Each runtime 4x2 atlas region is its entire portrait cell; its object
  or scene is visible in the dark framed side space rather than cropped at top or
  bottom. Full and compact art windows are 112px and 92px respectively. The private
  local back remains aspect-covered because its 2:3 source exactly matches the card.
- Focused `test_ui_support_cards.tscn` passed after the containment change. It
  asserts front/compact/hidden 2:3 layout after host geometry, native Button text
  emptiness, decorative/privacy policy, full atlas-cell regions, non-cropping front
  stretch mode, long readable title/rules/target fields, and bounded four-card
  portrait/landscape Hand carousels.
- Fresh inspected captures are under `E:/CodexCache/printforge-validation/` with
  tag `cardartfit-review`: Archive PIDs `22596`/`7064`, Deck `17968`/`20364`, Shop
  `11624`/`8688`, first-fold Battle Hand `6192`/`18724`, focused complete Battle
  Hand `14592`/`11780`, and Local revealed `21704`/`23260`, each ordered
  `576x1024` then `1280x720`. Inspection confirmed complete, centered art objects,
  visible title/cost/rules/target hierarchy, intentional dark side space, and
  unchanged first-fold move controls.
- Parser/import scan passed: Godot 4.7.1-stable desktop x64 console PID `13108`,
  exit 0. The retained suite passed 29/29 scenes through a fresh E:-backed
  APPDATA/LOCALAPPDATA root per invocation; its manifest is
  `E:/CodexCache/printforge-validation/card-art-fit-retained-suite-0524.txt`.
  The slower move-presentation test was console PID `9720`, worker PID `7196`, and
  passed in 64 seconds. Earlier failed bootstrap evidence remains outside the
  repository at
  `E:/CodexCache/printforge-validation/card-art-fit-godot-bootstrap-crash-0524.txt`;
  no gameplay, queue, or schema change was made in response. Android export audit
  used console PID `21184` and worker PID `19936`, exit 0. The debug-signed arm64
  APK is `PrintForge-Legends-0.5.24-alpha-card-art-fit-arm64.apk`, 117,946,883
  bytes, SHA-256 `43BF82551C474DC61350474569D58643BE0EBFBCD7BE1052303A47E05BC81C08`.
  `apksigner` verifies v2/v3 (debug signer); `aapt` reports package
  `com.tak.printforge.legends.review`, versionCode `74`, versionName
  `0.5.24-alpha-card-art-fit`, and only `arm64-v8a` native libraries. Archive audit
  found zero excluded source/provenance/backend/test paths, raw armor atlas files,
  or source card atlases.

## Checkpoint 0.5.23 portrait support-card frames (staging only)

- Every support-card front and the private Local Versus back now shares a tested
  2:3 portrait silhouette. Fronts use code-rendered workshop/navy/brass outer and
  inset frames, rarity accent, title plate, separate Filament badge, framed art,
  rarity/role, exact rules, target, copy count, and legality banner. Native button
  text is empty; semantic tooltip/accessibility names retain the full card detail.
- Solo and Local Hands use horizontal carousels. The opened solo tactical drawer has
  a bounded vertical touch viewport so portrait card content is reachable on short
  landscape screens without moving the primary battle controls out of the first fold.
  Shop and private handoff cards are decorative/noninteractive; the hidden hand shows
  only its centered 2:3 back.
- Godot 4.7.1 parser: console PID `21684`, exit 0. Full retained suite: 29/29 scenes
  exit 0; manifest `E:/CodexCache/printforge-validation/cardframes-retained-suite-0523.txt`.
  The long move-presentation scene was PID `10224`; final responsive and card scenes
  were PIDs `17420` and `4924`, respectively.
- Fresh inspected OpenGL captures are under `E:/CodexCache/printforge-validation/`:
  `card_archive`, `deck_cards`, `shop_cards`, `battle_hand_cards`, focused
  `battle_hand_cards_focus`, `local_card_handoff`, and `local_card_revealed`, each at
  `576x1024` and `1280x720` with tag `cardframes-release`. Capture PIDs, in order,
  are `13364`, `25200`, `9164`, `16536`, `24996`, `23152`, `25368`, `6128`, `17456`,
  `2936`, `1192`, `22252`, `23472`, and `9872`; all exited 0. Inspection confirms
  visible title/cost/art/rarity/rules/target hierarchy, centered 2:3 Shop and Local
  back silhouettes, an in-frame first-fold move layout, and complete focused Hand
  cards without overlap.
- Debug export PID `22356`, exit 0: `PrintForge-Legends-0.5.23-alpha-card-frames-arm64.apk`
  is 117,946,883 bytes with SHA-256
  `43F656DFC496C44AA1DB33DF0069C3086134D7D2D35A86407FC42791C4F34A1A`.
  `apksigner` verifies v2/v3; package is `com.tak.printforge.legends.review`,
  versionCode `73`, versionName `0.5.23-alpha-card-frames`, with only arm64 native
  libraries and no excluded source/provenance paths in the archive.

## Checkpoint 0.5.22 offline support cards (staging only)

- The 30-card offline catalog now has stable IDs, cached 4x2 atlas regions, direct
  private-card-back rendering, ordered deterministic effects, runtime discard,
  exact target/rules/legality wording, and a shared `SupportCardRules` seam for
  UI and AI. Decks stay 15 cards; opening hand and cap stay four; one normal draw
  occurs toward the cap; cards never end the turn; exhausted decks do not reshuffle.
- Focused `test_support_card_system`, `test_ui_support_cards`,
  `test_card_balance_audit`, `test_presentation`, `test_signature_rules`, and
  `test_ui_checkpoint_a1` passed. The rules test verifies every card/effect,
  discard snapshot roundtrip and byte-equal card rejections. The balance audit
  verifies contextual useful/legal values, no same-tier duplicate vectors, and
  deterministic legal AI choices. The touch-safe portrait Hand uses a bounded
  horizontal carousel for larger hands and shows visible cost/rules/target plus
  legality feedback; normal two-card capture shows the complete first fold.
- Final retained suite: 29/29 individual ShellExecute scenes exited 0. PIDs:
  `26292,20320,26572,10380,18348,5700,20476,18640,9352,23492,2928,22468,
  2016,6880,21064,15392,9256,23640,23752,22788,13616,18456,5060,3324,
  15296,8740,25732,24600,23224`. `test_move_presentation` PID 2928 took
  59.621 seconds and passed under its explicit 180-second bound. Logs/manifests
  remain external under `E:/CodexCache/printforge-validation/`.
- Fresh OpenGL visual QA captured and inspected `card_archive`, `card_detail`,
  `deck_cards`, `shop_cards`, `battle_hand_cards`, `local_card_handoff`,
  `local_card_revealed`, and `high_contrast_cards` at 576x1024 and 1280x720.
  Portrait uses its height cleanly: Archive filters and visual cards are legible,
  Deck exposes one selected-card tray, Hand cards are contained and readable,
  and handoff shows only the card back before Ready. Landscape remains unclipped.
- Final Android debug/review export PID 20624 exited 0:
  `PrintForge-Legends-0.5.22-alpha-support-cards-arm64.apk` is 117,942,985 bytes,
  SHA-256 `817540C662FD21A6D76D6209D5A4CF52AF66A487999D4D2E6066519145313CE9`.
  `apksigner` confirms Android Debug v2/v3; `aapt` reports package
  `com.tak.printforge.legends.review`, versionCode 72/name
  `0.5.22-alpha-support-cards`, SDK 24/36, and only arm64-v8a native libraries.
  Archive exclusion audit found zero backend/tests/tools/tmp/node_modules/.git/
  docs-art-source entries. The known `aapt` `android:required` reader warning is
  non-failing and unchanged.

## Checkpoint 0.5.21 battle presentation (staging only)

- The finite tokenized `BattleMoveVFX` presentation covers every one of the 24
  catalog signatures, all eight elements, and all eight status accents without
  changing `BattleRules`. The static idle/reduced-motion/Forge/Workshop paths
  retain their ordinary imported texture behavior.
- `tools/clean_sprite_atlas_edges.gd` repaired only 17 living 1536x1024 PNG
  sheets. It removed 33 non-largest edge components / 15,922 alpha pixels;
  seven verified zero-removal PNGs were restored byte-for-byte from `HEAD`.
  `docs/SPRITE_ATLAS_EDGE_REPAIR.json` records every source path, before/after
  SHA-256, frame count, and removal count. The Android export excludes `tools/`.
- Fresh parser/import used Godot 4.7.1 official `a13da4feb`, direct isolated
  E: runtime, final console PID `22408`, exit 0. The wrapper bootstrap crash was
  retained at `docs/validation/godot-bootstrap-user-logs-sigsegv-20260816.txt`:
  it failed
  opening `user://logs` before the first test marker and then produced a
  SIGSEGV, so it was treated as engine/log-path evidence rather than gameplay.
  All accepted test/capture/export runs use the smaller direct
  `APPDATA`/`LOCALAPPDATA` E: invocation instead.
- Focused source/import audit PID `23056`, exit 0, inspected all 24 sheets x 8
  frames. It proves valid alpha survives, no non-largest edge component remains,
  and every imported `Texture2D` matches its repaired source alpha. Runtime
  imported texture lookup measured 19,504 microseconds cold and 27 microseconds
  cached; it performs no runtime component cleanup.
- Post-review focused regressions also passed: checkpoint4 accessibility/armor/AI
  (PID `19412`, exit 0) and presentation audio/captions/battle feedback/card
  detail (PID `23160`, exit 0).
- Inspected OpenGL captures: corrected Fire portrait
  `battle_vfx_fire_576x1024_battle-presentation-reimported.png` (wrapper PID
  `5816`, exit 0) has neither the prior left beige fragment nor orange sliver;
  Arcane landscape `battle_vfx_arcane_1280x720_battle-presentation-final.png`
  (PID `24808`, exit 0) and labeled all-16-cell contact sheet
  `battle_vfx_contact_sheet_1280x720_battle-presentation-final.png` (PID
  `25832`, exit 0) were also visually accepted.
- The isolated retained 26-scene Godot suite passed (wrapper PID `15016`, every
  scene exit 0). Expected environment-only root-certificate warnings and the
  existing orderly dummy-renderer RID cleanup messages remained non-failing.
- Android debug/review arm64 export console PID `26404`, exit 0:
  `build/android/PrintForge-Legends-0.5.21-alpha-battle-presentation-arm64.apk`
  is 108,742,147 bytes, SHA-256
  `48DB7966004CAB8D2BDC1FE6B605C3CC5DA56FA5F20A2E579CB6F81B969A67C0`.
  `apksigner verify --verbose` confirms v2/v3 with the Android Debug
  certificate; `aapt2` reports package `com.tak.printforge.legends.review`.
  `aapt` reports version code 71/name `0.5.21-alpha-battle-presentation`, SDK
  24/36, then its known `android:required` reader warning. Archive audit found
  two arm64 libraries, the VFX and battle resources, and zero backend/tests/
  tools/tmp/node_modules/.git/docs-art-source entries.

## Checkpoint 0.5.20 Android static battle catalog (staging only)

- The 0.5.19 phone result still produced empty first-build and catalog-ID retry
  teams despite correct canonical Cinderpaw/Brambleowl/Verdantitan IDs. The
  battle domain therefore no longer reads the `Catalog` Node autoload or
  `ProgressionRules` in static code. `BattleCatalog` preloads immutable
  `catalog.gd` constants and exposes creatures, armor, cards, elements, and
  signatures without creating a Node or copying authored data. State/unit
  normalization, rules, and AI all use this one export-safe accessor.
- `test_battle_static_catalog.tscn` runs exact three-unit legacy aliases with a
  Helm, rival build, raw-filament support card, Cinderpaw signature, legal AI,
  and a deterministic completed match. It source-checks all battle-domain
  scripts for zero `Catalog.` and `ProgressionRules.` references. Isolated run
  PID `22596` exited 0 with PASS; parser PID `17336` exited 0. Focused rules,
  signatures, Trial launch, and factory runs `4432,17420,11384,2992` exited 0.
- Fresh OpenGL `576x1024` captures were inspected: `trials_teamlaunch_
  576x1024_staticcatalog-final.png` (PID `24500`, exit 0) shows the exact
  Cinderpaw/Brambleowl/Verdantitan lineup, and `trial_battle_teamlaunch_
  576x1024_staticcatalog-final.png` (PID `15128`, exit 0) shows a populated
  Cinderpaw-vs-Mossmunk Warm Nozzle opening with its action dock.
- The isolated retained 25-scene suite exited 0: PIDs
  `18876,23640,5756,7692,7196,13176,24224,20908,21040,23884,21860,21928,
  13912,21180,1208,22972,3172,3980,7336,8640,13584,19372,20780,21320,25724`.
  The UI-A1 and Workshop-navigation log files omit their print marker but both
  processes exited cleanly; every other scene logged PASS.
- Android export PID `24648` exited 0. Artifact
  `build/android/PrintForge-Legends-0.5.20-alpha-battle-static-catalog-
  arm64.apk` is `105,435,381` bytes, SHA-256
  `E005D52F4BAC9560A455B92E98BC11A4079798B6DB4C5C4695C91267247B9779`.
  `apksigner` verified v2/v3 with the Android Debug certificate. `aapt` listed
  package `com.tak.printforge.legends.review`, code `70`, version
  `0.5.20-alpha-battle-static-catalog`, SDK 24/36, then returned its known
  `android:required` manifest-reader warning. Archive audit found two arm64
  libraries, eight battle-script entries, and zero backend/tests/tools/tmp/
  node_modules/.git paths. No physical device was attached.

## Checkpoint 0.5.19 Android battle export boundary (staging only)

- Phone evidence showed `SoloBattleFactory` receiving canonical IDs
  Cinderpaw/Brambleowl/Verdantitan while both dictionary and ID-only BattleState
  construction yielded empty teams. The narrowed root cause was the 0.5.18
  nested static alias helper resolving `Catalog` before `make_team()` reached
  its established direct lookup. Alias extraction is now pure data extraction
  (`creature_id`, `species_id`, `creature`, `species`, then ambiguous `id`),
  and `make_team()` remains the only catalog validator. Armor aliases follow
  the same extraction/validation separation. This does not write profiles or
  relax invalid-team validation.
- Isolated parser/import PID `24392` exited 0. Focused tests exited 0:
  Trial launch `17992`, solo factory `13280`, Trials UI `18484`, and Battle
  rules `22224`. The Trial launch regression proves a three-unit current
  lineup, legacy aliases, scalar retry, equipped armor, rival construction,
  no-owned refusal, and that helper extraction preserves even invalid raw
  strings for the existing `make_team()` catalog rejection boundary.
- Fresh isolated OpenGL captures were inspected at true `576x1024`:
  `trials_teamlaunch_576x1024_exportboundary-final.png` (PID `24252`, exit 0)
  shows the three-name Trial lineup and Start Warm Nozzle; `trial_battle_
  teamlaunch_576x1024_exportboundary-final.png` (PID `9588`, exit 0) shows a
  populated Cinderpaw-vs-Mossmunk opening with visible Defend/End Turn. Neither
  contains an invalid-team toast or clipped action dock.
- The 24-scene retained suite completed with isolated E app-data: PIDs
  `23308,23064,5948,20144,15880,18940,23372,10448,24772,10484,17924,25500,
  1608,18000,12652,21704,21748,25176,21108,5724,15844,19592,10276,17380`,
  all exit 0. Two UI logs omit `print()` in their log-file but exited cleanly;
  all other scene logs emitted their PASS marker.
- Final Android export PID `25636` exited 0. Artifact
  `build/android/PrintForge-Legends-0.5.19-alpha-battle-export-boundary-
  arm64.apk` is `105,431,108` bytes, SHA-256
  `572140B46EEFAF9F399EBE5212333F78226E043A59164A73E73CB5F0017176E2`.
  `apksigner` verified v2/v3 with the Android Debug certificate. `aapt` listed
  package `com.tak.printforge.legends.review`, version code `69`, version name
  `0.5.19-alpha-battle-export-boundary`, SDK 24/36, then returned its known
  `android:required` manifest-reader warning. Archive audit retained two arm64
  libraries and BattleState/runtime scripts; backend/tests/tools/tmp/
  node_modules/.git were absent. The intentionally runtime-used workshop
  reference import remains under `assets/docs/`. No physical device was
  attached.

## Checkpoint 0.5.18 Trial launch canonicalization (staging only)

- The exact screenshot-style Team Builder path was reproduced on baseline with
  Cinderpaw, Brambleowl, Verdantitan, and an equipped Helm: it already built a
  valid three-print state (`TRIAL_LAUNCH_REPRO`, PID `3116`, exit 0). This means
  the reported Android failure was not a standard current Team Builder record;
  it is consistent with a legacy dictionary alias crossing the preview/battle
  boundary. `SoloBattleFactory.preview()` and `create()` now share the same
  catalog-valid canonical entries, while `BattleState.make_team()` accepts
  `creature_id`, `id`, `species_id`, `creature`, `species`, and scalar IDs.
  A failed dictionary build makes exactly one non-persisting catalog-ID retry
  without optional armor; a double failure reports canonical/built IDs and the
  Team Builder recovery route.
- Isolated parser/import PID `15988` exited 0. Focused tests passed: canonical
  UI save/start `20508`, solo factory `18736`, Trials UI `12620`, and Battle
  rules `7996`. The new Trial-launch scene proves the actual Team Builder
  save -> Trial preview -> Warm Nozzle launch preserves Cinderpaw/Brambleowl/
  Verdantitan order, the owned Helm, active profile/deck/inventory/revision,
  and no-owned refusal.
- Fresh OpenGL captures were inspected at true `576x1024`: `trials_teamlaunch_
  576x1024_triallaunch-final.png` (PID `24584`, exit 0) shows the exact
  canonical lineup plus Edit Current Team; `trial_battle_teamlaunch_576x1024_
  triallaunch-final.png` (PID `20324`, exit 0) shows a successful Warm Nozzle
  first frame with the responsive opening dock. No clipping or invalid-team
  screen was present.
- Retained suite coverage passed with isolated E-cache app-data. The first 17
  scenes passed with PIDs `22104,22080,5064,14320,25484,13652,5584,22672,
  20900,25976,22148,4992,22468,15828,17720,6344,5440`; UI-A1 then printed its
  PASS result but did not terminate before the generic 90-second wrapper, so it
  was stopped as task-owned PID `14272` and rerun under an engine `--quit-after
  12` bound as PID `24112`, exit 0. The remaining UI/depth/live tests passed:
  `22620,8952,13172,14084,11064,22532`, all exit 0. This is a bounded harness
  cleanup issue, not an assertion failure.
- Final Android review export PID `22292` exited 0. Artifact
  `build/android/PrintForge-Legends-0.5.18-alpha-trial-launch-arm64.apk` is
  `105,431,108` bytes, SHA-256
  `A3DA5A24ADF7C46AEBC84EAAD7BEDBC4801C971FC47416FE7F4D4BD2D8786BE4`.
  `apksigner` verified v2/v3 debug signatures; `aapt` reports package
  `com.tak.printforge.legends.review`, version code `68`, version name
  `0.5.18-alpha-trial-launch`, SDK 24/36, then returns its known
  `android:required` manifest-reader warning. Archive audit found 2 arm64
  libraries, retained workshop and creature resources, and excluded backend,
  tests, tools, tmp, node_modules, and `.git`. No physical device was attached.

## 2026-08-15 Checkpoint 4 - presentation and accessibility (staging only)

- Added idempotent fixed-step audio settings (`master_bps`, `music_bps`, `sfx_bps`) through `AudioSettings` and `AccessibilityRules`; `AudioDirector` routes muted-in-capture procedural Workshop/Battle/Forge, press, impact, and card cues while the UI keeps an explicit text cue. Generated samples use bounded integer master-by-channel gain, and an unchanged route preserves the latest cue caption rather than replacing it with a generic state caption. Audio remains non-authoritative. Battle uses a compact outcome/HP/shield banner and exact catalog-derived support-card cost/effect/target details in Hand and Deck; disabled cards say how much Filament is missing. High contrast and reduced motion retain text feedback.
- Final isolated OpenGL parser/import scan: wrapper PID `22796`, Godot console/worker PIDs `18124/23964`, exit 0. The 21-scene retained suite passed: alpha `6880/16804,25612`, art `7276/17168,23288`, battle `8028/10808,22840`, campaign `17116/5896,14168`, checkpoint-A `22004/12600,13152`, checkpoint4 `20428/19948,24968`, checkpoint5 `16840/23136,26180`, checkpoint6 `24372/9344,21344`, presentation `5724/4352,22152`, profile `18220/13752,22128`, progression `11284/4112,5112`, save `3484/6912,24268`, signatures `22772/17536,21836`, UI-A `21832/14800,19592`, UI-A1 `22024/10288,17644`, UI5 `3928/2132,10992`, UI6 `26424/20660,25804`, trials `9448/19144,22624`, Workshop navigation `18832/19276,20248`, depth `5740/14044,23460`, and Workshop live `26612/18632,19492` (wrapper/Godot PIDs; all exit 0). The known Windows root-certificate warning and orderly dummy-renderer resource-leak messages remain environment/test-exit noise.
- Inspected OpenGL evidence under `E:/CodexCache/printforge-validation/`: settings at `576x1024` and `1280x720` (PIDs `21340/6664,24696` and `16424/3640,8588`), final portrait impact/high-contrast/reduced-motion/Hand at `576x1024` (`11076/11192,21932`, `26572/14248,14320`, `4100/7072,20444`, `24204/19932,24836`), and matching landscape evidence under the `presentation-final` tag. All capture processes exited 0. The compact settings controls and battle dock keep readable 44px targets inside the viewport.
- Follow-up audio correctness proof: parser, `test_presentation`, and UI-A1 passed after the gain/cue update; fresh muted impact captures `battle_impact_576x1024_presentation-audiofix.png` (`4360/26340,26460`) and `battle_impact_1280x720_presentation-audiofix.png` (`20136/6044,25960`) exited 0 and visibly retain `Cue: battle action resolved.` after the unchanged Battle route.
- Final Android debug/review export after audio gain/cue correction: wrapper PID `20004`, Godot console/worker PIDs `22084/25276`, exit 0. `build/android/PrintForge-Legends-0.5.14-alpha-presentation-arm64.apk` is `104,150,666` bytes, SHA-256 `B10201B066CB9BC1CEF7CD48852830E5703D2715132069504326091451BD7741`; package `com.tak.printforge.legends.review`, version code `64`, version name `0.5.14-alpha-presentation`, arm64 only. `apksigner` verified v2/v3 with the Android Debug certificate. `aapt dump badging` printed the expected package/version/min SDK 24/target SDK 36 and then returned its known `android:required` attribute-reader warning. APK archive audit found no backend/tests/tmp/node_modules/.git/docs entries and retained the required workshop reference, creature-sheet, and new presentation scripts. No physical device was attached.

## 2026-08-15 Checkpoint 2 - Workshop Trials (staging only)

- Added a catalog-authored, deterministic offline campaign: five ordered tiers (`First Layers`, `Element Bench`, `Reinforced Run`, `Masterwork Circuit`, `Primordial Proof`), each with three normal encounters and a fixed three-print boss. `CampaignRules` owns schema-5 campaign migration, locks, rewards, per-instance mastery, best turns, and idempotent claims. First clears journal one mutation; a faster completed replay journals only a lower best turn count and awards no coins, XP, mastery, unlock, or spool; equal/worse replays do not revise the profile.
- Final durable parser/import scan: CMD PID `20332`, Godot console/worker PIDs `22020/10992`, exit 0. It now recognizes the two tracked v3 Workshop plates through their project-relative import sidecars and has no GDScript parse error. The post-fix isolated OpenGL retained suite passed all 19 scenes: profile `24024/13540,6020`, progression `3528/25924,20776`, battle `25912/7244,24672`, checkpoint4 `13744/25216,20744`, checkpoint5 `23580/3364,6584`, checkpoint6 `5720/6868,23312`, checkpoint-A `8688/20396,21228`, save recovery `25764/18180,5328`, UI5 `10564/7924,23472`, UI6 `23096/11340,7960`, UI-A `23064/6840,4068`, UI-A1 `1376/6160,18960`, art contract `9752/17744,1932`, alpha loop `16388/8512,4924`, workshop live `24636/23272,25732`, signature rules `20832/1816,19312`, campaign rules `20000/9356,9060`, UI trials `16532/21644,21008`, and Workshop navigation `15616/21348,23168`; each exited 0. The Windows root-certificate warning and existing orderly dummy-renderer resource-leak messages are environment/test-exit noise, not failures.
- Inspected OpenGL capture evidence: `trials_576x1024_trials-final2.png` (CMD/Godot PIDs `25268/14044,1392`), `trials_1280x720_trials-final2.png` (`19832/25008,448`), `trial_battle_576x1024_trials-final2.png` (`18888/6904,7244`), and `trial_battle_1280x720_trials-final2.png` (`24372/20408,9228`) under `E:/CodexCache/printforge-validation/`, all exit 0. The Trial list shows clear locks/rewards/rival previews; the in-Trial battle shows the named encounter, fixed rival, and first-fold move dock in both layouts.
- Android arm64 debug/review export after the durable-preload repair: CMD PID `24172`, Godot console/worker PIDs `22276/12448`, exit 0. The staging artifact `build/android/PrintForge-Legends-0.5.12-alpha-trials-arm64.apk` is 104,129,844 bytes, SHA-256 `354AEA08D649E06F2F51149756A115AA8554E3FFF7A8EA89673E8BB4BD51FBB6`. `apksigner verify --verbose --print-certs` passed v2/v3 with the Android Debug certificate; `aapt` reports package `com.tak.printforge.legends.review`, version code 62/name `0.5.12-alpha-trials`, then returns 1 on the known `android:required` manifest-attribute parser warning. Archive inspection excludes backend, tests, tmp, node_modules, and `.git`; the sole docs-prefixed runtime entry is the intentionally retained workshop reference import. No physical Android-device smoke was performed.

## 2026-08-15 Checkpoint 1 - catalog signatures and solo AI (staging only)

- This staging-only checkpoint adds immutable `signature` records to all 24
  entries in `scripts/core/catalog.gd`. Each record has an integer damage bonus
  and ordered deterministic effects; no profile embeds signature data, so old
  creature IDs, teams, decks, and saves continue to resolve through the catalog.
  `ProfileRules.migrate()` only refreshes `catalog_version` during its existing
  idempotent integrity pass and preserves owned records/team references.
- `tests/test_signature_rules.tscn` passed with Godot console/worker PIDs
  `14148/1376`, exit 0. It loops the full catalog, rejects unknown effects,
  invalid targets, and negative amounts, requires materially distinct mappings,
  exercises damage, self/foe effects, shield absorption, lethal resolution, and
  filament/cooldown/ability-lock rejection. It also covers catalog-version
  migration preservation plus Apprentice opening defense, Craftsman repair and
  shield-card survival, Master signature/basic lethal choices, and an affordable
  elemental switch.
- Final parser/import scan used the isolated E-cache OpenGL command wrapper
  (CMD PID `20128`, Godot console/worker PIDs `13392/6912`), exit 0. The full
  retained 17-scene suite plus the new signature scene passed under isolated
  E-cache app-data roots: profile `9176/19940`, progression `10224/22148`,
  battle `12252/25148`, checkpoint4 `20352/5108`, checkpoint5 `13736/16024`,
  checkpoint6 `2900/22512`, checkpoint-A `26136/5720`, UI5 `24380/7336`, UI6
  `26104/2956`, UI-A `16424/24700`, UI-A1 `19912/1604`, workshop navigation
  `18116/6228`, workshop live `20716/16792`, save recovery `25916/20452`, art
  contract `13188/10484`, alpha loop `2012/2388`, and signatures `14148/1376`;
  all exited 0. The only non-failing environment output was the known Windows
  root-certificate-store warning.
- Original-detail OpenGL capture evidence is
  `E:/CodexCache/printforge-validation/battle_voidmanta_576x1024_signatures-final4.png`
  (CMD PID `5112`, Godot `26112/1336`, exit 0) and
  `E:/CodexCache/printforge-validation/battle_voidmanta_1280x720_signatures-final4.png`
  (CMD PID `17992`, Godot `10844/19652`, exit 0). Both were inspected for the
  opening lock, visible Defend/End Turn, full four-action dock, and exact
  catalog-derived Cinderpaw/ Voidmanta effect lines.
- Android arm64 review export used CMD PID `1864` and Godot console/worker
  PIDs `12004/6652`, exit 0. The staging artifact
  `build/android/PrintForge-Legends-0.5.11-alpha-signatures-arm64.apk` is
  `104,100,999` bytes with SHA-256
  `ADC0CF3E4EFE56EC4E47AA95C63A892C180601FC49CDBDAC0DAF4E9FE5FC2272`.
  `apksigner verify --verbose` confirmed v2/v3 debug signing. `aapt dump
  badging` reported package `com.tak.printforge.legends.review`, code `61`,
  name `0.5.11-alpha-signatures`, min SDK 24/target 36, then returned 1 on the
  known `android:required` manifest-reader warning. APK archive audit retained
  arm64 libraries, the required workshop reference import, and creature sprite
  imports, with no backend/tests/tmp/node_modules/.git entries; no physical
  Android device install was performed.
- Follow-up wording/contract refinement: `Catalog.signature_description()` now
  states that each bonus is base damage before element and armor, and the
  signature contract requires exactly 24 distinct mappings. Isolated parser
  CMD/Godot PIDs `22280`/`23556/21748`, signature rules `20648`/`6828/5612`,
  and responsive UI-A1 `10440`/`6516/15416` all exited 0. Fresh original-detail
  captures `battle_voidmanta_576x1024_signatures-baseword-final.png`
  (CMD/Godot `20272`/`10216/17756`) and
  `battle_voidmanta_1280x720_signatures-baseword-final.png`
  (`11000`/`8124/10268`) exited 0 and were inspected for readable, in-frame
  exact signature wording plus the four-action opening dock.
- Hash-synchronized durable follow-up verification repeated the parser
  (`19912/25548`), signature contract (`18476/25020`), and responsive UI-A1
  (`24200/26232`) directly from `E:/AI Projects/games/3d print battler`; each
  Godot console/worker pair exited 0 with isolated E-cache app-data.

## 2026-08-15 refactor/optimization staging validation

- Staging-only refactor validation used Godot 4.7.1 `a13da4feb` with isolated
  E-cache app-data roots and OpenGL compatibility. Parser PID 22012 exited 0.
  The retained 16-scene suite then passed with PIDs
  `15972/22828/22928/20812/21184/2340/25760/23336/5428/24256/20492/22512/18296/19700/9412/19608`,
  all exit 0 (profile, progression, battle, checkpoints 4-6, checkpoint A,
  save/UI coverage, art contract, alpha loop, and workshop live).
- Focused lifecycle/cache coverage confirms a persistent Battle stage, Forge
  stage, and Workshop live layer retain identity across Main renders; the
  checkpoint-4 sprite cache regression reports one texture load and one alpha
  bounds scan for a reused creature path. Battle snapshot import also accepts
  malformed non-array `players`/`log` values safely and active-unit lookup is
  side-effect-free.
- Inspected fresh OpenGL captures were written under
  `E:/CodexCache/printforge-validation/`: workshop at 576x1024 (PID 22632),
  720x1280 (2096), and 1280x720 (22436); Voidmanta battle at 576x1024 (20352),
  720x1280 (5872), and 1280x720 (10216); and Arcane Forge printing at 576x1024
  (23088), 720x1280 (20632), and 1280x720 (17196). Each exited 0 and was
  checked for the persisted stage presentation, visible action dock, and
  in-frame Forge controls. Android export evidence is recorded only after the
  final staging export below.
- Final post-cleanup parser PID 1932 exited 0. The repeat retained suite passed
  profile/progression/battle/checkpoint4/checkpoint5/checkpoint6/checkpoint-A/
  save/UI5/UI6/UI-A/UI-A1/workshop-nav/art/alpha/workshop-live as PIDs
  `11656/17980/1624/1516/19356/1064/20096/5968/3152/16164/16948/17988/22892/24060/1440/21664`,
  all exit 0. The PowerShell text-integrity audit exited 0.
- Final staging Android review export after the Forge lifecycle optimization was
  PID 24900, exit 0:
  `E:/CodexCache/printforge-refactor-export-final/PrintForge-Legends-0.5.9-alpha-battle-runtime-refactor-final-arm64.apk`
  is 104,088,711 bytes, SHA-256
  `FD6095F92B7248A61ACE0512533FC01993A70B1F7C8C973B0292D09DFB87A12D`.
  `apksigner` verified debug v2/v3 signing; `aapt` reported package
  `com.tak.printforge.legends.review`, version code 59/name
  `0.5.9-alpha-battle-runtime`, then returned 1 on the known
  `android:required` manifest reader warning. Archive inspection found no
  backend, node_modules, tests, tmp, or .git entries; the runtime workshop
  reference import is an intentional documented asset exception.
- Follow-up Forge lifecycle polish: parser PID 24648 exited 0; checkpoint-6,
  printer UI, and composed alpha-loop tests PIDs 21832/24144/21040 all exited
  0. The UI regression advances a printing sequence without changing phase and
  proves both the retained shell/stage identity and live progress-label update.
  `ArcaneForgeStage` now processes only during printing carriage motion;
  deterministic awakening/departure updates need no per-frame processing.
  Fresh inspected portrait printing capture
  `printer_printing_720x1280_refactor-polish.png` was PID 22884, exit 0.
- Durable verification followed SHA-256-checked synchronization of the 29
  reviewed source/test/document files. The authorized parser used console PID
  23544 and worker PID 19252, exit 0. Focused durable regressions then passed:
  battle rules 21080/7564, checkpoint-4 cache coverage 22028/7716, printer UI
  lifecycle 19292/16944, and the composed alpha loop 25624/6228
  (console/worker PIDs, all exit 0). An earlier restricted-shell parser attempt
  was discarded because it could not refresh generated import metadata; it was
  not used as acceptance evidence. Its generated sidecars were removed after
  the authorized run, raw tracked import diffs remained empty, and no Godot
  process remained.

## 2026-08-15 Checkpoint 0.5.10 - battle/profile integrity (staging only)

- This staging-only fix was based on durable local commit `55ae272`; no durable synchronization, staging, commit, push, remote operation, or Drive delivery occurred. Current-schema profile migration now runs an idempotent conservative integrity pass: it keeps valid inventory, accepts only catalog-valid species aliases and unambiguous instance/team repairs, verifies starter species-to-instance linkage, and leaves irreparable teams empty for a safe battle preflight block instead of fabricating ownership.
- `BattleState.validation_error(true)` is used before solo/local-versus start while finished-state display still permits a defeated unit at zero HP. The solo opening HUD disables Basic Attack and Signature for the coin-flip winner, labels the legal Defend/End Turn choice, and UI-A1 clicks both controls through their bound callbacks. Deferred AI now captures the exact `BattleState` and a session generation; a stale presentation timer returns without acting on a replaced match.
- Team Builder callbacks bind stable instance IDs and reset their draft before the synchronous profile change, so a saved three-print team immediately feeds `GameManager.current_team_loadout`, battle Bench switches, and the persistent Maker shelf. The Armor Workbench now presents acquire, print, and fit/move/remove steps; its bound handlers were exercised through blueprint learning, printing, equipping, unequipping, and reassigning one concrete armor instance. Deck controls use stable slot/card IDs and touch-driven draft redraws do not auto-grab the first slot; keyboard and joypad input still opts into deterministic focus.
- Parser/import scan: Godot 4.7.1 `a13da4feb` PID `23960`, exit 0. Focused UI-A1 stale-timer/action-dock regression PID `23604`, exit 0. Final retained 16-scene suite was run directly with logs under `E:/CodexCache/printforge-validation/integrity-rerun/full-stale-final/`: profile `7064`, progression `22596`, battle `20300`, checkpoint4 `21008`, checkpoint5 `780`, checkpoint6 `22988`, checkpoint-A `7352`, save recovery `23964`, UI5 `22264`, UI6 `26456`, UI-A `916`, UI-A1 `14044`, workshop navigation `3788`, art contract `23272`, alpha loop `21672`, workshop live `13556`; all exited 0 with no parse or script errors. Expected non-failing environment output remains the Windows root-certificate warning and known dummy-renderer allocation notices from prior stage tests.
- Original-detail OpenGL capture PID `21556`, exit 0: `E:/CodexCache/printforge-validation/battle_voidmanta_576x1024_battleintegrity-final.png`. It was inspected for the player opening restriction, visible Defend/End Turn, valid Cinderpaw `44/44` armored summary, Voidmanta rival, and in-frame action dock.
- Final signed review export: Godot PID `14688`, exit 0. `E:/CodexCache/printforge-battle-integrity-export-stale-final/PrintForge-Legends-0.5.10-alpha-battle-integrity-arm64.apk` is `104,096,903` bytes with SHA-256 `A146705374674B95D6A5F1BBBC89DE6B17413716F2A9B101C7F7D43159A3A4CA`. `apksigner verify --verbose` exit 0 confirms v2/v3; `aapt dump badging` reports `com.tak.printforge.legends.review`, code `60`, name `0.5.10-alpha-battle-integrity`, min SDK 24/target 36, then returns the known `android:required` reader warning. Archive audit found zero backend/tests/tmp/node_modules/.git/docs-demo paths and retained workshop-reference, Cinderpaw, Voidmanta, and Arcane Forge printer resources. No physical device install was performed.

## 2026-08-15 Checkpoint 0.5.9 - battle runtime normalization (staging only)

- Local staging clone `E:/CodexCache/printforge-battle-runtime-20260815` was created from durable local commit `d3c592a`. No durable synchronization, Drive delivery, staging, commit, push, or remote operation occurred.
- Root cause for the Android empty `Moves` dock was a presentation abort, not a collapsed container: an older active-player dictionary retained only an ID/current HP, while `render_battle_summary()` and `render_battle_action_dock()` read missing fields with `unit.attack`, `unit.name`, and related dictionary-property syntax. `BattleState.normalize_unit()` now rebuilds the catalog-backed runtime contract before create/active-unit access, preserving legitimate changing values and accepted legacy aliases. Main battle/local-versus presentation uses safe `.get()` reads, while named `submit_battle_action` callbacks replace the four core anonymous move closures.
- Historical runtime-normalization validation predates the full-suit/Core replacement and is superseded for active equipment by the current tiered-suit rules test.
- Full retained 16-scene suite completed exit 0 under `E:/CodexCache/printforge-battle-runtime-validation/full_pid/`: profile 6280, progression 22080, battle 18888, checkpoint4 1624, checkpoint5 25268, checkpoint6 23588, checkpoint-A 20604, save recovery 19272, UI5 7564, UI6 26272, UI-A 19720, UI-A1 24180, Workshop navigation 12280, art contract 21972, alpha loop 9392, and workshop live 13876. Expected non-failing environment output remains the Windows root-certificate-store warning and pre-existing checkpoint6 dummy-renderer leak notice.
- Original-detail inspected OpenGL evidence: `E:/CodexCache/printforge-validation/battle_voidmanta_576x1024_battleruntime-final.png`, exit 0. It shows the complete 2x2 core dock and secondary control above both Voidmanta and Cinderpaw summary rows.
- Fresh post-armor Android review export: Godot PID 21816, exit 0; `E:/CodexCache/printforge-battle-runtime-export-final/PrintForge-Legends-0.5.9-alpha-battle-runtime-arm64.apk`, 104,083,668 bytes, SHA-256 `B22E4F717C911C463C0E572242A00B859183EDFB2CA874175B83B7FF45E8DE6B`. `apksigner verify --verbose` exit 0 confirms v2/v3. `aapt dump badging` reports package `com.tak.printforge.legends.review`, code 59/name `0.5.9-alpha-battle-runtime`, min SDK 24/target 36; its exit 1 is the known `android:required` attribute reader warning after metadata output. Archive audit found no backend/tests/tmp/node_modules/.git/docs-demo entries and retained required workshop/printer/Cinderpaw/Mossmunk/Voidmanta resources. No physical Android-device installation occurred.

## 2026-08-15 Checkpoint 0.5.8 - full-height battle layout (staging only)

- Local staging clone `E:/CodexCache/printforge-battle-layout-20260815` was created from durable local commit `aee6cb5`. No durable synchronization, Drive delivery, staging, commit, push, or remote operation occurred.
- `BattleFullscreenPanel` replaces the generic scroll-body path for solo Proving Grounds. It gives the stage, `BattleActionDock`, and compact secondary tactics an explicit visible-viewport composition. The first frame exposes Basic Attack, Signature Ability, Defend, End Turn, and the secondary toggle with 48px action targets; portrait retains a compact HP/armor/filament/log summary, while landscape uses the saved space for the stage and moves. Expanded Bench, Hand, Details, and two-step Concede remain reachable in-frame.
- Fresh parser/import scan: Godot 4.7.1 `a13da4feb` PID 24648, exit 0 (`E:/CodexCache/printforge-battle-layout-validation/parser_pid_final.log`). The focused `test_ui_checkpoint_a1` was also run after the pre-settle assertions as PID 7576, exit 0. It checks synchronous action-grid/button minimums before layout settles, then actual nonzero in-viewport geometry and lower-viewport composition at 576x1024, 720x1280, and 1280x720; it also expands Bench, Hand, and Concede and submits a legal action.
- Full retained 16-scene Godot suite passed with direct Godot console PID/exit pairs: profile 23188/0, progression 7632/0, battle 26168/0, checkpoint4 25468/0, checkpoint5 16296/0, checkpoint6 3528/0, checkpoint-A 4360/0, save recovery 23964/0, UI5 19540/0, UI6 1448/0, UI-A 10896/0, UI-A1 7576/0, Workshop navigation 2732/0, art contract 24484/0, alpha loop 5612/0, and workshop live 21316/0. Logs are under `E:/CodexCache/printforge-battle-layout-validation/full_pid/`.
- Fresh OpenGL captures all exited 0: initial `battle_review_576x1024_battlelayout-final.png`, `battle_review_720x1280_battlelayout-final.png`, and `battle_review_1280x720_battlelayout-final.png`; secondary `battle_secondary_576x1024_battlelayout-final.png`, `battle_secondary_720x1280_battlelayout-final.png`, and `battle_secondary_1280x720_battlelayout-final.png`, under `E:/CodexCache/printforge-validation/`. Original-detail inspection confirmed readable initial moves, 2x2 portrait dock, in-frame secondary switches, no collapsed action grid, and useful lower viewport occupancy.
- Fresh Android review export used Godot PID 800, exit 0: `E:/CodexCache/printforge-battle-layout-export-final/PrintForge-Legends-0.5.8-alpha-battle-layout-arm64.apk`, 104,079,572 bytes, SHA-256 `B24E0A7611A4FB7B5DEB46AFF99DD4CB63902836093BEBABA4F2617F6582F4A2`. `apksigner verify --verbose` exit 0 confirms v2/v3. `aapt dump badging` identifies `com.tak.printforge.legends.review`, code 58/name `0.5.8-alpha-battle-layout`, min SDK 24/target 36; its exit 1 is the known `android:required` manifest attribute reader warning after metadata output. Archive audit found 0 backend/tests/tmp/node_modules/.git/docs-demo paths and 10 required workshop/printer/creature resource matches. No physical Android-device installation occurred.

## 2026-08-15 Printer Blueprint Picker and portrait battle move dock (staging only)

- Staging clone `E:/CodexCache/printforge-printer-picker-20260815` was created from durable local commit `ce25d29`; no durable sync, staging, commit, push, or remote operation occurred. The Printer Bench now owns a visible accessible `Choose a Print` control and a station-local Blueprint Tray. It lists learned catalog blueprints only with idle art, exact rarity print cost, and owned count; preview/cancel are authority-neutral and the existing Arcane Forge commit seam remains the only print mutation.
- Solo Proving Grounds now puts `BattleActionDock` directly after the compact 2D stage. Basic Attack, Signature Ability, Defend, and End Turn are initial, in-frame actions at 576x1024, 720x1280, and 1280x720. Bench, Hand, Details, and two-step Concede are compact tabs, so secondary controls remain reachable without burying core moves. `BattleSpriteStage` keeps its 250px default except when a caller explicitly requests a compact HUD height.
- Final parser/import scan used Godot 4.7.1 `a13da4feb` and completed cleanly (Godot PID 13484; wrapper exit 0). Fresh direct retained-suite runs all exited 0 and logged PASS: profile, progression, battle, checkpoint4, checkpoint5, checkpoint6, checkpoint-A, save recovery, UI5, UI6, UI-A, UI-A1, Workshop navigation, art contract, alpha loop, and Workshop live. The associated prior console PIDs are `24128/24688/22284/12200/24184/14624/1888/18540/11464/24720/24392/19940/10988/22816/23988/22028`; final direct logs are under `E:/CodexCache/printforge-printer-picker-validation/full_direct_final/`.
- Inspected OpenGL captures under `E:/CodexCache/printforge-validation/` are `workshop_printer_picker_1280x720_pickerfinal.png`, `workshop_printer_picker_720x1280_pickerfinal.png`, `workshop_printer_picker_576x1024_pickerfinal.png`, and matching `printer_picker_preview_mossmunk_*_pickerfinal.png`. The compact Android-review battle evidence is `battle_review_576x1024_pickerbattle-final.png` (PID 20064), `battle_review_720x1280_pickerbattle-final.png` (PID 9256), `battle_review_1280x720_pickerbattle-final.png` (PID 26516), plus expanded Bench evidence `battle_secondary_576x1024_pickerbattle-final.png` (PID 7328). All capture processes exited 0 using OpenGL compatibility. Inspection confirmed readable picker cards/actions, exact Mossmunk preview price, 5,000 review-floor header, full first-render primary moves, and in-frame compact Bench controls.
- Final audited staging Android review export used Godot PID 19004 and completed successfully: `E:/CodexCache/printforge-printer-picker-export-final/PrintForge-Legends-0.5.7-alpha-printer-picker-arm64.apk`, 104,079,572 bytes, SHA-256 `39D80A47767D0697AA17BC6691CEAAC351874FB64F0DEDD6441FDC7841C037FD`. `apksigner verify --verbose` passed v2/v3. `aapt dump badging` reported package `com.tak.printforge.legends.review`, code 57/name `0.5.7-alpha-printer-picker`, min SDK 24 and target SDK 36; its existing nonzero exit follows the known `android:required` attribute warning after metadata output. Archive audit excludes backend, tests, tmp, node_modules, `.git`, and `docs/demo`, while retaining workshop overview, creature, printer, and the intentional runtime workshop-reference imports. This staging-only review APK was not copied to Drive or tested on a physical Android device.

## 2026-08-15 Workshop v3 static overview and station-live presentation (staging only)

- Staging clone `E:/CodexCache/printforge-workshop-live-20260815` remains local only: no durable synchronization, staging, commit, or remote operation occurred. Independent v3 landscape/portrait Workshop plates are static overview establishing shots. `WorkshopStationLiveLayer` appears only in the focused Printer and Maker station crops, where it renders the four existing printer frames, catalog raw/living art, and the active team without changing the profile, coins, revision, journal, or team. `ReviewBuildRules` applies the 5,000-coin Android-review floor once through `GameManager` only when the `android_review` feature is active.
- Fresh isolated E-cache OpenGL parser/import scan used CMD PID 25820 with Godot console/worker PIDs 20764/13420 and exited 0 (`parser-true-final.log`). No console/worker remained after it exited.
- The complete retained Godot suite ran in `E:/CodexCache/printforge-workshop-live-tests-final`, each exit 0: profile 22696, progression 22268, battle 5880, checkpoint4 20524, checkpoint5 24888, checkpoint6 15552, checkpoint-A 5168, save recovery 8740, UI5 19876, UI6 23144, UI-A 13160, UI-A1 22288, Workshop navigation 18004, art batch 13356, alpha loop 3520, and station-live 22208. Logs are `final_*.log` under `E:/CodexCache/printforge-workshop-live-validation/`. The expected Windows root-certificate-store warning remains environment-only output.
- Fresh OpenGL capture CMD PIDs all exited 0 under isolated E-cache app data: static overview 1280x720/720x1280 (6656/26448), Printer start/mid/hold/awakening 1280x720 (9600/19700/5720/19492), Printer hold/awakening 720x1280 (23648/11316), Maker team 1280x720/720x1280 (22364/9256), reduced-motion Printer 1280x720 (2608), and test-injected Android-review header 720x1280 (15420). A final live-capture audit used CMD PID 17528 with Godot console/worker PIDs 20696/5720 and exited 0. Files use the `*_stationfinal.png` tag in `E:/CodexCache/printforge-validation/`. Original-detail inspection confirmed a static overview, physically seated Forge/raw/living sequence, all three team members on Maker plinths, visible Back/Settings chrome, no clipped controls, frozen reduced motion, and the visible 5,000 review floor.
- Staging Android review export CMD PID 20780 exited 0: `E:/CodexCache/printforge-workshop-live-export/PrintForge-Legends-0.5.6-alpha-workshop-live-arm64.apk`, 104,071,380 bytes, SHA-256 `08B9B053914CBDF14995E7A176AEA1BF4B747A884124204119091A34FF09CA6D`. `apksigner verify --verbose` passed v2/v3. `aapt dump badging` reported package `com.tak.printforge.legends.review`, version code 56/name `0.5.6-alpha-workshop-live`, min SDK 24 and target SDK 36; its existing nonzero tool exit followed metadata output. Archive audit retained arm64 libraries, the v3 overview plates, all four printer-frame imports, and creature raw/living imports; it excluded backend, tests, tmp, node_modules, and `.git`. The deliberate runtime workshop-reference import remains the sole `docs`-named dependency.

## 2026-08-15 Workshop ambient and portrait-fill (staging only)

- The Workshop now uses a brighter, clipped 3:2 art plane for portrait close-ups and a contained interactive overview over a cover backdrop. Focusable hotspot Buttons use transparent, shadow-free styles; `WorkshopHotspotOverlay` draws the only cyan/amber physical-item edge light. `WorkshopAmbientLayer` supplies slow code-native printer/hologram movement and freezes without changing profile, printer, or gameplay state when reduced motion/capture freeze is active.
- Fresh isolated E-cache parser/import scan: CMD PID 19964, Godot PIDs 26364/2616, exit 0. Focused Workshop navigation UI regression CMD PID 19276, Godot PIDs 11572/19504, exit 0. It verifies overview/close-up navigation, focus targets, no rune glyphs, hotspot bounds at 1280x720, 576x1024, and 720x1280, portrait close-up fill, reduced-motion freeze, and normal ambient phase advancement without authority mutation.
- Full retained isolated suite passed: profile 18628 (2760/21968), progression 22696 (11884/25788), battle 25596 (1816/13360), checkpoint4 4928 (18892/13900), checkpoint5 24060 (23080/26428), checkpoint6 15608 (17888/21268), checkpoint-A 19160 (25064/22096), UI5 21956 (15108/19700), UI6 25676 (25616/19752), UI-A 20144 (5428/24204), UI-A1 21972 (23372/25192), UI Workshop Nav 19272 (20912/24032), save recovery 15088 (22512/12988), art contract 2504 (25988/7708), and alpha loop 10356 (23484/11424); every command exited 0. The only environment output was the known Windows root-certificate-store warning and existing non-failing test cleanup warnings.
- Fresh inspected OpenGL captures under `E:/CodexCache/printforge-validation/` are: portrait overview/Printer/Maker/Terminal at `*_576x1024_ambient-final.png` (CMD PIDs 24412/25060/19712/19760), the same four at `*_720x1280_ambient-final.png` (20400/5524/26576/20372), and landscape Printer/Maker/Maker drawer at `*_1280x720_ambient-final.png` (6668/8616/15956). All Godot console/worker pairs exited 0. Inspection confirmed bright art, full usable portrait scene coverage, in-frame compact controls, correctly aligned edge-only physical highlights, and a fully visible landscape Blueprint Tray.
- Portrait crop accessibility follow-up: close-up art now exposes bounded drag/swipe panning, a non-text pan affordance with the tooltip "Swipe the workshop view to reach more tools", and focus-driven reveal for each physical prop. Fresh terminal left/center/right OpenGL captures are `workshop_terminal_offers_576x1024_ambient-pan-final.png`, `workshop_terminal_forgedex_576x1024_ambient-pan-final.png`, and `workshop_terminal_trade_576x1024_ambient-pan-final.png` (CMD PIDs 6280/9804/6568); Maker left-state evidence is `workshop_maker_576x1024_ambient-pan-final.png` (19876). All exited 0 and were inspected for no hidden terminal actions. Final parser CMD PID 7276 (Godot 22828/21616), focused UI nav PID 1816 (23176/15944), progression PID 19024 (9636/15228), and checkpoint-A PID 21792 (20716/22096) all exited 0.
- Final staging Android debug/review export after the drag-input panning fix: CMD PID 19912, Godot PIDs 18932/3816, exit 0. `build/android/PrintForge-Legends-0.5.5-alpha-workshop-ambient-arm64.apk` is 99,658,921 bytes, SHA-256 `412B0DF3D05D11B71B8B74B73BD7CC18F0DF913157AED8CC76F10130C447C5D7`. `apksigner verify --verbose` passed v2/v3; `aapt dump badging` reports package `com.tak.printforge.legends.review`, code 55/name `0.5.5-alpha-workshop-ambient`, and returns 1 only on the existing Android manifest-attribute parse warning. Archive audit excludes backend/tests/tmp/node_modules/.git/non-runtime docs; the sole matching reference is the intentional runtime `assets/docs/art/reference/workshop-theme-reference.jpg.import`. The required workshop and creature assets are present. No physical Android device was attached.

## 2026-08-15 Workshop navigation - spatial close-ups

- Staging-only navigation work uses the approved native-3:2 overview and five close-up assets in `res://assets/ui/workshop/`; provenance and normalized hotspot rationale are in `docs/WORKSHOP_NAV_ART.md`. The overview has five focusable, label-free rune zones (Printer, Maker, Terminal, Proving, Yard) plus a compact Settings control. Close-ups use prop-level runes and a compact Blueprint Tray. Escape closes the tray, then returns to overview; launched screens remember their close-up origin.
- Final parser/import scan: CMD PID 25604, Godot console/worker PIDs 24560/22676, exit 0. The full retained 15-scene suite passed under an isolated E-cache profile: profile 24916 (17728/23600), progression 14596 (11992/21532), battle 14512 (11804/26128), checkpoint4 4352 (19420/19548), checkpoint5 6640 (6620/23068), checkpoint6 14600 (11328/22320), checkpoint-A 26412 (6180/22840), UI5 18080 (22212/10896), UI6 23768 (18808/23724), UI-A 19192 (23240/17368), UI-A1 5612 (26484/12996), UI Workshop Nav 11580 (21268/12304), save recovery 9512 (9872/9416), art batch 6824 (18884/10664), and alpha loop 17704 (23944/15392); every scene exited 0. The expected deliberate corrupt-save JSON parse message, Windows root-certificate-store warning, and pre-existing checkpoint6 dummy-texture leak remain non-failing test output.
- Inspected OpenGL captures are under `E:/CodexCache/printforge-validation/`: overview, Printer, Maker, Terminal, Proving, and Yard landscape captures use the `*_1280x720_nav-final2.png` tag; core portrait overview/Printer/Maker/Proving use `*_720x1280_nav-final2.png`. The accepted landscape drawer split captures are `workshop_maker_drawer_1280x720_nav-final3.png` and `workshop_proving_drawer_1280x720_nav-final3.png` (CMD PIDs 13460/19788, exit 0), while portrait drawers remain `workshop_maker_drawer_720x1280_nav-final2.png` and `workshop_proving_drawer_720x1280_nav-final2.png`. Inspection confirmed visible headers, full native-aspect art, hotspot alignment, compact corner controls, and fully in-frame tray actions.
- Fresh Android debug/review export: CMD PID 14632, Godot console/worker PIDs 21876/23760, exit 0. `build/android/PrintForge-Legends-0.5.4-alpha-workshop-nav-arm64.apk` is 99,650,168 bytes, SHA-256 `E045D987AF644873358BA447A3F02D53183D313EB67EA0709F95560E82F92C36`. `apksigner verify --verbose` passed v2/v3. `aapt dump badging` reports package `com.tak.printforge.legends.review`, version code 54/name `0.5.4-alpha-workshop-nav`, then returns 1 on the known `android:required` manifest-attribute parse warning. APK audit found zero backend/tests/runtime/tmp/non-reference-document paths and retained the workshop close-ups, all required raw/living imports, and the allowed runtime workshop-reference dependency. No physical Android device was attached for install/launch smoke.

## 2026-08-15 Checkpoint A.1 - expandable portrait battle HUD

- Staging clone `E:/CodexCache/printforge-checkpointA1-20260815` was created from durable local `7b8d05d`. The Godot display configuration now uses a 720x720 base viewport with `canvas_items` and `expand`, retaining the 1280x720 desktop override and Android sensor orientation. The capture harness deliberately has no content-scale or viewport-size override; it asserts the screenshot dimensions instead.
- Parser/import scan PID 9252 exited 0. Focused responsive HUD regression PID 19700 and final retained profile/progression/battle/checkpoint4/checkpoint5/checkpoint6/checkpoint-A/UI-A/UI-A1/alpha-loop/save/UI5/UI6/art-contract suite PIDs `24220/21036/3932/15540/25000/2884/21972/25596/26536/9628/16936/25200/5816/20544` all exited 0. The known Windows root-certificate warning and checkpoint6 dummy-renderer leak warning remain environment/pre-existing test output.
- Inspected OpenGL captures prove full-frame sizing and first-render actions: `battle_1280x720_checkpointA1.png` (PID 25604), `battle_720x1280_checkpointA1-polish.png` (PID 25448), and `workshop_720x1280_checkpointA1.png` (PID 17456), under `E:/CodexCache/printforge-validation/`. The portrait battle has no letterbox; primary actions remain in `BattleActionGrid`, while Bench and Hand are titled compact grids below it.
- Android debug/review export PID 17524 exited 0: `build/android/PrintForge-Legends-0.5.3-alpha-checkpointA1-arm64.apk`, 88,478,910 bytes, SHA-256 `806F37C0E13418E6FCC8B33651B853086C44AE786A930BBF01B1DDA2037EB0E9`. `apksigner verify --verbose` confirmed v2/v3 signing. `aapt` reported package `com.tak.printforge.legends.review`, version code 53/name `0.5.3-alpha-checkpointA1`, then returned 1 on the known `android:required` manifest parsing warning. Android physical-device smoke remains pending.

## 2026-08-15 Checkpoint A - workshop progression hub

- Implementation was completed in `E:/CodexCache/printforge-checkpointA-20260815` from durable `SolBranch-Clean` baseline `a4906be`, then the reviewed code, tests, docs, preset, README, and final review APK were hash-synchronized to durable E:. No staging, commit, or remote operation was performed.
- Fresh Godot 4.7.1 `a13da4feb` parser/import scan PID 19412 exited 0. Checkpoint-A pure progression PID 6636 and Workshop/UI/concede integration PID 2140 exited 0. The final retained suite passed profile/progression/battle/checkpoint4/checkpoint5/checkpoint6/checkpoint-A/save/UI5/UI6/UI-A/alpha-loop/art-contract as PIDs `3912/7680/22016/25128/19660/10564/23264/25636/20144/21764/19444/20000/20392`, all exit 0. The engine emitted the known Windows root-certificate warning; checkpoint6 also emitted its pre-existing dummy-texture leak warning on orderly test exit.
- The six-zone spatial Workshop map was captured with OpenGL compatibility and a deterministic viewport assertion: `workshop_1280x720_checkpointA-mapfix.png` (PID 13096), `workshop_1920x1080_checkpointA-mapfix.png` (PID 24896), `workshop_720x1280_checkpointA-mapfix.png` (PID 21388), and `workshop_1080x1920_checkpointA-mapfix.png` (PID 15956), all under `E:/CodexCache/printforge-validation/` and exit 0. They were inspected at original detail for visible header, workshop art, six non-overlapping zones, focusable labels, and in-frame action tray. New activity captures `calibration_1280x720_checkpointA.png` / `yard_1280x720_checkpointA.png` / `deck_1280x720_checkpointA.png` / `armor_1280x720_checkpointA.png` used PIDs 26480/21336/6320/8492, exit 0; portrait calibration PID 15404 exited 0.
- Checkpoint-A scope adds catalog-authoritative atomic calibration/Print Yard transitions, immediate XP-to-spool threshold advancement, safe deck-slot selection, armor unequip/reassignment, date-keyed deterministic training opponents, and two-step concede with explicit cancellation/disarm. Final Android arm64 review export PID 6804 exited 0: `build/android/PrintForge-Legends-0.5.2-alpha-checkpointA-arm64.apk`, 88,474,814 bytes, SHA-256 `A4A91C1B8D925F12E5C29F05075F59D877482C9502FD9D012570005EE4AF80B1`; `apksigner verify --verbose` reports v2/v3 signed and `aapt` reports package `com.tak.printforge.legends.review`, version code 52/name `0.5.2-alpha-checkpointA`. The first export PID 25916 correctly failed only because the new output folder did not exist; its folder-creation retry succeeded. A physical-device smoke remains pending.

## 2026-08-15 Forge portrait, icon, and Android 0.5.1-alpha

- Staging work was completed only in `E:/CodexCache/printforge-forge-portrait-20260815` from local baseline `63c92d4`; no remote operation, staging, or commit was performed. The four existing living creature sheets were not edited. The deterministic matte workflow retained the five generated source inputs under `docs/art/source/arcane_forge/`, emitted four clean alpha printer frames under `assets/ui/`, and records hashes plus corner-alpha validation in `docs/ART_GENERATION_LEDGER.md`.
- Parser/import scan: Godot 4.7.1 `a13da4feb`, OpenGL compatibility, console PID 7160, exit 0. Focused checkpoint-6 and printer UI tests were PIDs 23452 and 18560, exit 0. The fresh suite passed profile/progression/battle/checkpoint4/checkpoint5/checkpoint6/save/UI5/UI6/art-batch as PIDs 5444/11360/20352/14380/4104/24024/13364/2464/8064/11596, all exit 0. The composed alpha-loop initially identified its old immediate-awakening expectation after the intentional raw-hold transition; after the assertion was corrected, PID 19408 exited 0 and logged `PASS: checkpoint7 composed credential-free alpha loop`.
- Accepted OpenGL capture matrix used a true root content viewport with a dimension assertion, not the desktop filename alone. Portrait PIDs 6912/1320/3156/17524 produced `printer_printing`, `printer_raw_hold`, `printer_awakening`, and `printer_departing` at 720x1280; landscape PIDs 3520/13964/26284/9652 produced the same states at 1280x720. All exit 0, are tagged `forgeportrait-platefix` under `E:/CodexCache/printforge-validation/`, and were inspected at original detail: full header, workshop background, in-frame 44px control, dominant printer, raw print on the gold plate, restrained crossfade/sparks, and off-plate departure. Captures reported only known environment messages (Windows root certificate store and an OpenGL shader-cache condition on the two printing captures).
- Android debug/review export preset `Android Review arm64` uses package `com.tak.printforge.legends.review`, version code 51/name `0.5.1-alpha`, arm64 only, sensor orientation, the launcher icon, and workshop boot splash. Final staging export console PID 13132 exited 0. `build/android/PrintForge-Legends-0.5.1-alpha-arm64.apk` is 88,466,622 bytes, SHA-256 `18979030C41D7D1524C5CB6F6FB9EF3191F38D9C947E57983A47A5F4C4C23463`. `apksigner` verified debug v2/v3 signatures; APK metadata reports the intended package/version/label. Archive audit found two arm64 native libraries, fourteen printer/icon/splash asset entries, and zero backend/tests/tmp/node_modules/staging-Godot/non-reference-doc entries. `aapt dump badging` printed the expected metadata but returned 1 on an Android build-tools manifest attribute parse warning; Godot's own signed export verification exited 0. No Android device is attached for install/launch smoke.

## 2026-08-15 remaining 20 creature art batch

- Local-only staging clone `E:/CodexCache/printforge-artbatch-20260815` was created directly from durable local commit `d9b2e6a`; no remote fetch, pull, push, durable sync, or export was performed. The original four living/raw asset pairs were left untouched. The catalog now maps all 24 creature IDs to a living 4x2 sheet and a raw-print source.
- Fresh isolated OpenGL parser/import PID 11272 exited 0; the final parser after gallery capture updates was PID 7992, exit 0. Updated checkpoint-6 mapping test PID 18296 and the source asset-contract test PID 23560 each exited 0. The contract verifies all living sheets are 1536x1024 with visible alpha in every 384x512 cell, while raw forms have transparent corners plus visible and transparent sampled coverage.
- Retained isolated OpenGL regression suite exited 0: profile/progression/battle PIDs 26480/10844/24524; checkpoint4/checkpoint5/save PIDs 16808/15944/17180; UI checkpoint5/checkpoint6 PIDs 20380/17756; pure checkpoint6 PID 21720; composed alpha-loop PID 21452; and art-batch contract PID 20956.
- The deterministic two-page gallery contact sheet was captured and inspected at original detail. Page-2 retained its accepted `artbatch-final-clean` captures. A focused Aurorawing repair removed disconnected alpha specks from its living source, then gallery previews gained a two-pixel atlas gutter to prevent neighboring-frame linear-filter bleed. Fresh page-1 captures are `art_gallery_page1_1280x720_artbatch-aurora-nobleed.png` (PID 18528) and `art_gallery_page1_1920x1080_artbatch-aurora-nobleed.png` (PID 4068), both exit 0. They were individually inspected: the former white chevrons are absent, all ten cards retain their readable labels, and the header plus card bounds remain fully in frame.
- Post-repair isolated OpenGL parser/import PID 24088, art-batch source-contract PID 20380, and checkpoint-6 mapping regression PID 6656 each exited 0. The contract now uses actual transparency sampling compatible with Godot 4 rather than a nonexistent `Image.has_alpha()` call. The only environment output was the known Windows root certificate-store warning; no task-started Godot process remained.
- All Godot invocations used isolated E-cache APPDATA/LOCALAPPDATA paths and OpenGL compatibility rendering. The only environment message was the known Windows root certificate-store warning; no task-started Godot console or worker process remained.

## Checkpoint 7 composed credential-free alpha loop

- Final fresh isolated OpenGL parser scan used Godot 4.7.1 `a13da4feb`, PID 17612, exit 0. The new `test_alpha_loop.tscn` ran as PID 6392, exit 0, and logged `PASS: checkpoint7 composed credential-free alpha loop`. It uses only `E:/CodexCache/printforge-validation/checkpoint7-alpha-loop-isolated` for SaveService paths, clears only its five profile/journal files before and after the test, and restores the in-memory GameManager profile and default SaveService paths.
- The composed test exercises the actual public sequence: onboarding route; permanent GameManager starter selection; a 28-coin workshop job; catalog-priced Mossmunk blueprint purchase; Main Arcane Forge preview/raw-complete one-print commit; legal two-instance team and owned 15-card deck saves; real legal defend/pass/attack victory; one accepted and one refused reward claim; then snapshot/journal reload of the coins, XP, inventory, team, active deck, revision, and reward event.
- Relevant transaction UI regression `test_ui_checkpoint6.tscn` ran fresh in isolated OpenGL app data as PID 6884, exit 0, logging `PASS: checkpoint6 printer UI transaction safety`. Known environment-only output was the Windows root certificate-store warning. No task-started Godot console or worker process remained.
- Cleanup refactor verification used fresh isolated OpenGL roots: parser PID 19252; profile/progression/battle PIDs 5320/24892/24216; checkpoint4/checkpoint5/save PIDs 19212/21344/19492; UI checkpoint5/checkpoint6 PIDs 10380/23188; pure checkpoint6 PID 14520; and composed alpha loop PID 19892. All exited 0. This verifies the catalog-authoritative GameManager signature cleanup, shared armor lookup, and screen-navigation helper without a gameplay or visual contract change.
- Final durable verification after hash synchronization: parser PID 9156; profile/progression/battle PIDs 1388/19212/22204; checkpoint4/checkpoint5/save PIDs 3304/464/5860; UI5/checkpoint6/UI6/alpha-loop PIDs 4964/18376/20824/23188. All exited 0, and `npm.cmd test` passed the TypeScript authority compile/build/test. Final 1280x720 OpenGL workshop and awakening captures were PIDs 12760/21532, exit 0, and were inspected for the workshop background, header, readable station grid, printer composition, crossfade/poof, and in-frame controls. Canonical export PID 22276 exited 0: EXE 102,982,144 bytes, SHA-256 `12311E5BD7044C0E427CD5AA15E85866FF0B8FF1EB14B9DF41CB4EFF827C991B`; PCK 10,461,508 bytes, SHA-256 `761A428DEA91E14154BB40F0374267A4FAD30057303ADC53A84461D80CF62571`. The exported build launched with isolated E-cache app data and OpenGL as PID 24820, exit 0. No task-started Godot or export process remained.

## Checkpoint 6 Arcane Forge

- Implementation was reviewed in `E:/CodexCache/printforge-checkpoint6-20260814`, then hash-synchronized into the durable `E:/AI Projects/games/3d print battler` repository. Godot 4.7.1 `a13da4feb` used isolated E-cache APPDATA/LOCALAPPDATA roots and OpenGL for captures and final verification.
- Final parser PID 4104 exited 0. Existing profile/progression/battle/checkpoint4/checkpoint5/save/UI tests exited 0 as PIDs 25828/21260/17248/3140/7864/1300/5920. New pure Arcane Forge and transaction-safe UI tests exited 0 as PIDs 2672/4960. `npm.cmd test` exited 0 using a temporary staging junction to the installed durable dependency tree; the junction was removed.
- Inspected OpenGL capture matrix, all exit 0: preview 1280/1920 PIDs 24896/1104 (`printer_preview_*_checkpoint6-final.png`); mid-layer printing 15808/8052; raw-complete 11004/3064; awakened 2040/26616 (`printer_awakened_*_checkpoint6-final3.png`). Reduced-motion awakened 1280 capture PID 22892 (`printer_reduced_1280x720_checkpoint6-final3.png`). The full Forge, workshop background, header, build plate, raw/living composition, readable controls, and 720p button edges were individually checked; no magenta/checkerboard artifacts were observed.
- Fresh staging export PID 19888 exited 0: `E:/CodexCache/printforge-checkpoint6-export/PrintForgeCheckpoint6.exe` is 102,982,144 bytes, SHA-256 `12311E5BD7044C0E427CD5AA15E85866FF0B8FF1EB14B9DF41CB4EFF827C991B`; PCK is 10,461,956 bytes, SHA-256 `0E3B54418353951654685733D3A744B207513655785744177D9F15473595F69D`. Packing retained the workshop-reference exception, Arcane Forge printer, all raw prints, and all living sheets; it excluded backend, node_modules, tests, tmp, .git, and non-runtime documentation. The exported executable launched under isolated E app data/OpenGL as PID 6816, exit 0. No task-started Godot or export process remained.
- Follow-up presentation validation: reduced motion now uses 0.45-second integer staged holds (1,400 bps) rather than the normal 0.12-second / 900-bps path, with no nozzle or sparks; Main carries a presentation clock across 0.12-second UI rebuilds so normal nozzle position continues to sweep. Final parser/battle/checkpoint6/UI PIDs 24272/25032/12828/4820 exited 0. Deterministic frozen 8,500-bps awakening captures are `printer_awakening_1280x720_checkpoint6-followup3.png` (PID 25996) and `printer_awakening_1920x1080_checkpoint6-followup3.png` (PID 3760), both exit 0 and individually inspected for cyan/amber poof plus raw-to-living crossfade. Mossmunk raw-complete captures `printer_mossmunk_raw_complete_1280x720_checkpoint6-followup.png` (PID 21656) and `printer_mossmunk_raw_complete_1920x1080_checkpoint6-followup.png` (PID 21224) were inspected closely: its transparent source has hidden magenta RGB, but no in-engine fringe or box appeared. Reduced-motion settled capture `printer_reduced_1280x720_checkpoint6-followup.png` (PID 15380) shows no nozzle/sparks.
- Final durable verification after an explicit-type correction in the new UI test: parser PID 1816; profile/progression/battle/checkpoint4/checkpoint5/save/UI5/checkpoint6/UI6 PIDs 2984/22396/2388/2956/4132/11340/9688/7064/22440 all exited 0. `npm.cmd test` passed the TypeScript authority compile/build/test. An initial export attempt PID 8424 exited 1 because PowerShell split the spaced preset name; it started no game process. The correctly quoted canonical export PID 6168 exited 0. `export/PrintForgeLegends.exe` is 102,982,144 bytes, SHA-256 `12311E5BD7044C0E427CD5AA15E85866FF0B8FF1EB14B9DF41CB4EFF827C991B`; PCK is 10,462,612 bytes, SHA-256 `91EE0D3337C763F41A6ED0CBCE79791D1E3F45E04AF641A042B7534F2E26FD76`. The canonical export launched with isolated E-cache app data and OpenGL as PID 25032, exit 0. No task-started Godot or export process remained.

## Checkpoint 5 staging

- New E-cache staging clone `E:/CodexCache/printforge-checkpoint5-20260814` was created from clean durable commit `c022adc`; durable project was not modified.
- Native capture diagnosis/recovery: the original direct default-renderer command `Godot_v4.7.1-stable_win64_console.exe --path . --scene res://tests/capture_checkpoint2.tscn --windowed --resolution 1280x720 --quit-after 600 -- --capture-mode=trade_settled --capture-tag=checkpoint5-final` on Godot 4.7.1 `a13da4feb` exited `-1073741819` after failing to create `user://logs`; retained capture logs also showed the then-untyped harness variables. This did not identify a gameplay fault. After explicit types and isolated existing E-cache APPDATA/LOCALAPPDATA, OpenGL `--rendering-method gl_compatibility` completed the accepted capture matrix with exit 0: handoff `local_vs_*_checkpoint5-final-clean.png` PIDs 26308/20744, revealed turn `local_vs_ready_*_checkpoint5-final-last.png` PIDs 22636/22240, creator-confirmed draft `trade_draft_*_checkpoint5-final-polish.png` PIDs 15104/16376, and settled receipt `trade_settled_*_checkpoint5-final-last.png` PIDs 14500/25164 (1280/1920 respectively). Each was inspected at original detail for background, header, hierarchy, confirmation state, readable controls, and no clipped controls.
- Final isolated parser PID 8028 exited 0. Final isolated Godot test PIDs all exited 0: profile 15636, progression 432, battle 24232, checkpoint4 26568, checkpoint5 1228, physical save recovery 21900, and UI checkpoint5 26248. The save probe touches only `E:/CodexCache/printforge-validation/checkpoint5-save-isolated`: A then B, deliberate primary corruption, backup-A recovery, and exactly-once revision-2 pending event reads. The UI test proves select-render-confirm-render-confirm settlement, receipt, deterministic focus, and Escape navigation.
- `npm.cmd test` exited 0 using a temporary staging junction to the already-installed durable `backend/node_modules`; the junction was removed afterward. It compiles/imports `dist/authority` and passes the in-memory authority and dual-confirm trade tests.
- Fresh internal-alpha Windows debug export: PID 21492 exited 0 to `E:/CodexCache/printforge-checkpoint5-export-release-evidence/PrintForgeCheckpoint5Release.exe` (102,982,144 bytes, SHA-256 `12311E5BD7044C0E427CD5AA15E85866FF0B8FF1EB14B9DF41CB4EFF827C991B`) and `.pck` (4,939,664 bytes, SHA-256 `E8C6271E0C824951A558A1AE9EF93DA6587021BC741C3F1D85BED9AB06A5C580`). Its packing log contains the required `docs/art/reference/workshop-theme-reference.jpg` exception and all four creature-sheet imports; it contains no backend, `node_modules`, tests, `.git`, or non-runtime documentation entries. The exported executable launched with isolated E-cache APPDATA/LOCALAPPDATA, OpenGL, and bounded quit as PID 8492, exit 0; only the known Windows root-certificate-store warning was emitted.
- Final durable E verification after sync: parser PID 6304 exited 0; profile/progression/battle/checkpoint4/checkpoint5/save/UI PIDs 21232/13352/24700/26596/10068/23164/26472 each exited 0; and durable `npm.cmd test` exited 0. The canonical durable export `E:/AI Projects/games/3d print battler/export/PrintForgeLegends.exe` completed as PID 19036, exit 0: EXE 102,982,144 bytes, SHA-256 `12311E5BD7044C0E427CD5AA15E85866FF0B8FF1EB14B9DF41CB4EFF827C991B`; PCK 4,939,696 bytes, SHA-256 `153A99815F2E98B6FDF93046D33FDB70B67785D2D59017644FD1D755CCB523D8`. The canonical export launched with isolated E app data and OpenGL as PID 8732, exit 0; no task-started processes remained.
- Post-review presentation regression check: the reusable battle stage default remains 250px for normal battles, while Local Versus alone applies its 120px compact override after attachment. Parser PID 19548 and battle/checkpoint4/checkpoint5/UI PIDs 9228/26304/14176/25440 each exited 0. Fresh isolated OpenGL Local Versus capture PID 24264 exited 0 and wrote `local_vs_ready_1280x720_checkpoint5-stagefix.png`; it was inspected with the full header, compact stage, and every action/navigation button fully inside the frame.

Run from project root with the Godot 4.7.1 Windows console executable:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --editor --quit
Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/test_battle_rules.tscn
```

## Implementation validation

- 2026-08-14: Godot 4.7.1 `--headless --editor --quit` completed with exit code 0 against the delivered E: project (console PID 23324). The project scan and asset import reported no GDScript parse errors.
- 2026-08-14 correction pass: final direct E: parser smoke (console PID 20252) and bounded game-scene tests (console PIDs 1380 and 21056) exited 0. The game-scene command used `--headless --scene res://tests/test_battle_rules.tscn --quit-after 8` with isolated E: user-data/log paths and emitted `PASS: battle rules, starter deck, cards, switching, catalog counts, and weights`.
- 2026-08-14 AI/Cooling correction: direct E: parser smoke (console PID 21180) and bounded regression test (console PID 7448) exited 0. The regression suite covers AI coin-flip opening defense, forced-replacement Cooling/basic attack, and shield absorption to zero damage.
- The validation environment emitted only non-project warnings about the Windows root certificate store and unavailable local `user://` persistence; the save layer now handles unavailable storage safely for test runs.

No Godot editor processes are required for the test scene.

## Checkpoint 4 staging validation

- 2026-08-14 final direct E: validation used Godot 4.7.1 with isolated app-data roots under `E:/CodexCache/printforge-validation/checkpoint4-final-e/`. Parser worker PID 21180, profile PID 25420, progression PID 16080, battle PID 22468, and checkpoint-4 PID 24264 each exited 0. The last test covers settings migration/rejection, reduced-motion/event frame selection, catalog sprite fallback, armor stat mapping/damage reduction, AI opening/low-HP decisions, and the one-claim reward latch.
- Fresh Forward+ captures used `capture_checkpoint2.tscn` in separate processes and were written under `E:/CodexCache/printforge-validation/`: `battle_1280x720_checkpoint4-alpha-crop.png`, `battle_1920x1080_checkpoint4-alpha-crop.png`, `settings_1280x720_checkpoint4-final.png`, `settings_1920x1080_checkpoint4-repeat.png`, `high_contrast_battle_1280x720_checkpoint4-alpha-crop.png`, and `high_contrast_battle_1920x1080_checkpoint4-alpha-crop.png`. They were inspected for visible headers, readable controls, stable alpha-union sprite crops, equipped-armor labels, high-contrast borders, and non-cropped actions.
- Direct visual invocations emitted known environment-only root-certificate/user-storage warnings plus a renderer cache warning on orderly exit. They still saved the requested PNGs and exited 0. The final process audit found no Godot console or worker process remaining.

## Checkpoint 3 validation

## Checkpoint 5 offline QA and compatibility (staging)

- Staging clone `E:/CodexCache/printforge-offline-qa-20260815` began at durable
  commit `59502c9`; no durable sync, staging, commit, push, or Drive delivery
  was performed during this evidence pass. Schema 7 adds a pure future-save
  compatibility block: bootstrap opens a newer profile read-only and does not
  call the local snapshot writer.
- Final Godot 4.7.1 parser/import scan console/worker PIDs 20292/23068,
  exited 0. The final retained 22-scene suite exited 0, including new offline
  QA console/worker PIDs 19916/25196; the full ordered console/worker pairs
  were `21708/2336`, `20468/17776`, `7068/21184`, `13680/22364`,
  `22624/8060`, `19304/9056`, `24208/14592`, `10216/21064`, `19916/25196`,
  `19976/17360`, `19912/4048`, `20444/21040`, `19272/20764`, `6868/26276`,
  `9336/3556`, `3256/18604`, `24388/25084`, `13416/8760`, `12472/21204`,
  `23476/17716`, `12548/21896`, and `2956/24504`.
  The coverage includes representative schema 1-7
  fixtures, idempotence, future-save byte preservation, support/feedback
  presenters, 72 same-seed catalog simulation matches across Apprentice,
  Craftsman, and Master AI. Aggregate deterministic metrics are 72 terminated
  matches, 25 player wins / 47 rival wins, 367 actions, 367 turns, 2-10 turns
  per match, 213 basic attacks, and 74 signatures. Per difficulty: Apprentice
  9/15 wins in 127 turns (2-10); Craftsman 8/16 in 120 (2-8); Master 8/16 in
  120 (2-8). The scripted survival/attack driver intentionally uses no cards
  (zero recorded); legal card resolution remains covered by retained
  `test_battle_rules.tscn`. The decoded-source art estimate is 301,957,528
  bytes, below the documented 360 MiB desktop QA ceiling.
- Inspected isolated OpenGL captures all exited 0: future-save recovery
  `future_save_recovery_576x1024_offlineqa-final.png` (console/worker
  PIDs 7292/20324), battle Hand `battle_hand_576x1024_offlineqa-final.png`
  (15788/23144), and impact `battle_impact_1280x720_offlineqa-final.png`
  (19548/13592), under `E:/CodexCache/printforge-validation/`. They show
  recovery guidance with no mutation controls, explicit card cost/effect/target
  text, and an impact outcome/caption banner.
- The corrected recovery capture
  `future_save_recovery_576x1024_offlineqa-readonly-final.png` (console/worker
  PIDs 13912/22712, exit 0) was inspected after the header fix: it explicitly
  says `READ-ONLY COMPATIBILITY MODE` and never shows the onboarding ceremony.
- Final Android review export console/worker PIDs 16080/17708 exited 0:
  `build/android/PrintForge-Legends-0.5.15-alpha-offline-qa-arm64.apk`,
  104,155,138 bytes, SHA-256
  `1A2E31057218DED3F7B07E1F783BC037BF96ED0FB8D3402C45DDB6C31D838565`.
  `apksigner verify --verbose` reports v2/v3 signatures and package inspection
  reports `com.tak.printforge.legends.review`. Archive audit found no backend,
  tests, tmp, node_modules, or Git entries; the sole docs match is the required
  runtime workshop reference import. `aapt` still returns its known manifest
  `android:required` parse warning after inspection; `aapt2 dump packagename`
  succeeds with a harmless themed-icon reference warning. Read-only `adb
  devices` started an empty daemon and found no attached device, so physical
  Android smoke remains blocked rather than passed.

## Checkpoint 0.5.17 Trial team integrity (staging)

- `SoloBattleFactory.player_loadout` first returns the authoritative
  `ProfileRules.team_loadout` unchanged. Only an empty authoritative result
  falls back to deterministic catalog-valid raw owned records, including
  legacy `creature_id`, `species_id`, `creature`, `species`, and `id` aliases
  without an instance ID. The fallback never writes the profile and preserves
  an armor only when that catalog-valid armor is owned.
- Isolated parser PID 26520, focused factory PID 20444, and Trials UI PID
  20000 exited 0. The focused tests cover Team Builder precedence, raw
  `{id:"cinderpaw"}` / `{species:"cinderpaw"}` input, invalid deck fallback,
  no-owned refusal, deep input immutability, visible repair notice, and the
  Warm Nozzle start path.
- Inspected true-portrait OpenGL captures: legacy Trial lineup
  `trials_legacy_576x1024_trialteam-final-lineup2.png` (PID 12760, exit 0)
  shows the temporary-use wording and 44px Edit Current Team route; successful
  Warm Nozzle `trial_battle_legacy_576x1024_trialteam-final-warmnozzle.png`
  (PID 19248, exit 0) shows the persistent in-battle lineup notice and visible
  opening Defend/End Turn controls.
- Final isolated parser/import scan PID `18216` exited 0. The retained 23-scene
  suite passed (all exit 0): alpha `12504`, art `1852`, battle `2712`, campaign
  `19980`, checkpoint-A `2820`, checkpoint4 `9420`, checkpoint5 `21200`,
  checkpoint6 `1244`, offline QA `15652`, presentation `23752`, profile
  `25008`, progression `25748`, save recovery `7420`, signatures `10712`, solo
  factory `3412`, UI-A `17092`, UI-A1 `19788`, UI5 `22892`, UI6 `16296`, Trials
  `2772`, Workshop navigation `25160`, depth `3752`, and Workshop live `15416`.
  `test_ui_checkpoint_a` now fixes its training day key to the player-first
  deterministic seed required by its Bench/concede assertions; it no longer
  depends on the host calendar.
- Final Android review export PID `25196` exited 0. The staged artifact
  `build/android/PrintForge-Legends-0.5.17-alpha-trial-team-arm64.apk` is
  `105,427,012` bytes, SHA-256
  `AA5D756B4C6EB68BDAF22BD278DFAF72952347CE686046FE4B8A9AE8EBFA6476`.
  `apksigner` verified v2/v3 using the Android Debug certificate; `aapt` reports
  package `com.tak.printforge.legends.review`, version code `67`, version name
  `0.5.17-alpha-trial-team`, min SDK `24`, target SDK `36`, then emits its known
  `android:required` parser warning. Archive audit retained arm64 libraries and
  runtime workshop/creature resources, excluded backend/tests/tools/tmp/
  node_modules/.git, and contains only the intentionally runtime-referenced
  workshop reference import under `docs/`. No physical device was attached.

## Checkpoint 0.5.16 Trial recovery, touch scroll, and armor atlas (historical staging)

- The shared `SoloBattleFactory` accepts a legal saved team/deck when present,
  otherwise builds a deterministic temporary owned-print lineup for a
  catalog-valid stale team reference without mutating the profile. A profile
  with no catalog-valid owned print is refused before battle creation with its
  exact recovery message. `test_solo_battle_factory.tscn` and
  `test_ui_trials.tscn` cover stale species refs, an invalid active deck,
  no-owned refusal, the Warm Nozzle launch, and touch-scroll configuration.
- The final true-portrait OpenGL captures were inspected: initial Trial list
  `trials_576x1024_trialscroll-final-top3.png` (console PID 17768, exit 0),
  lower-list scroll `trials_scrolled_576x1024_trialscroll-final-scroll3.png`
  (PID 6600, exit 0), and successful Warm Nozzle first frame
  `trial_battle_576x1024_trialscroll-final-warmnozzle.png` (PID 8420, exit 0).
  The list shows an in-frame 32px cyan scrollbar; the Warm Nozzle first fold
  shows opening guidance with Defend/End Turn enabled and core actions visible.
- Armor raw assets were regenerated from the original atlas after converting
  every crop to RGBA before keying. `test_checkpoint6.tscn` (PID 13680, exit
  0) verifies all seven catalog mappings, 512px source dimensions, and
  imported-texture transparency at interior background probes. Inspected
  final OpenGL captures are archived legacy raw-print evidence; the active
  full-suit/Core flow uses the signature-color master, all exit 0;
  no green fringe or black rectangular matte remains.
- Final isolated parser/import PID 5884 exited 0. The final retained 23-scene
  Godot suite also exited 0 (console PIDs 16840, 4872, 3324, 24976, 24412,
  25548, 15712, 9164, 22308, 23088, 20408, 6188, 25924, 16376, 8420, 23264,
  15112, 9460, 17876, 1852, 19760, 8740, and 2796). The Windows
  root-certificate-store warning and dummy renderer cleanup warnings are
  environment-only. One headless capture retry was intentionally discarded
  because the dummy renderer has no viewport texture; the final captures above
  used isolated OpenGL processes.
- Android review export PID 5168 exited 0:
  `build/android/PrintForge-Legends-0.5.16-alpha-trial-scroll-arm64.apk`,
  Final rebuild PID 9932 exited 0 after excluding the converter and source
  atlas from runtime export: 105,427,012 bytes, SHA-256
  `E7BBE8E1A6B9AB7B376915C390288B5D9597F70E25FE24C21CBCE75265F23980`.
  `apksigner` verifies debug v2/v3 signing; APK archive inspection contains
  only arm64 native libraries and no backend, tests, tools, source atlas, tmp,
  node_modules, or Git paths; all seven `*_alpha_v2` runtime armor textures
  remain present. The only docs-like archive entry is the required imported
  workshop reference asset. Legacy `aapt` prints a known manifest `android:required`
  parsing warning after package output, so arm64 was verified directly from
  `lib/arm64-v8a/` entries. No Android device was attached (`adb devices`), so
  physical-device smoke remains blocked rather than passed.

## Checkpoint 3 workshop depth (historical staging)

- Staging implementation in `E:/CodexCache/printforge-workshop-depth-20260815` uses schema 6/catalog 0.5.13 and has not been committed, pushed, or Drive-delivered. It adds deterministic three-step Calibration Bench patterns, one-choice Print Yard drills, print history, five fixed-label deck slots, and the raw-only armor Forge presentation.
- Fresh isolated OpenGL parser/import completed with exit 0 (bounded console wrapper PID 22808). The full retained 20-scene suite completed with exit 0, including the new `test_workshop_depth.tscn`; its pure coverage verifies calibration pattern/performance and cap, all Print Yard transitions, one-shot warmup, history migration/increments, raw-only armor print behavior, and deck lifecycle. Environment output was limited to the known Windows root certificate-store warning and existing dummy-renderer cleanup warnings in UI tests.
- Captures under `E:/CodexCache/printforge-validation/` use true 576x1024 and 1280x720 capture dimension assertions: `calibration_*_workshop-depth-final.png`, `yard_*_workshop-depth-final.png`, `armor_preview/armor_printing/armor_raw_hold/armor_awakened_*_workshop-depth-final.png`, `codex_*_workshop-depth-final.png`, and `deck_*_workshop-depth-final.png`. They were inspected for readable panels, explicit daily/Forge state, in-frame targets, armor completed-part hold, and Forgedex/deck information.
- Signed Android review export used the isolated E-cache app-data root: console wrapper PID 20492 and Godot console/worker PIDs 25760/26188, exit 0. `build/android/PrintForge-Legends-0.5.13-alpha-workshop-depth-arm64.apk` is 104,138,036 bytes, SHA-256 `8E4E2911A0CD571CC85801BB3B6750F84E24A871608FE21AAFDD6AAC86CB9701`; `apksigner` confirms debug v2/v3 signing and `aapt` reports package `com.tak.printforge.legends.review`, version code 63/name `0.5.13-alpha-workshop-depth`. The local `aapt` command returns 1 only after reporting a known manifest `android:required` attribute parse warning; Godot's signed export itself exited 0.

- 2026-08-14: direct E: parser scan (PID 13152), profile migration/onboarding test (PID 18540), progression regression test (PID 23196), and battle regression test (PID 14148) each exited 0. Direct runs used isolated app-data paths under `E:/CodexCache/printforge-validation/` and bounded `--quit-after 300` scene runs.
- 2026-08-14 archived pre-tiered visual QA: fresh-process Forward+ captures were written under `E:/CodexCache/printforge-validation/` for the former workshop review surfaces at both 1280x720 and 1920x1080. This historical evidence predates and is superseded by the full-suit/Core checkpoint above. Final 1280 PIDs: 13848, 22160, 3304, 13420, 11420. Final 1920 PIDs: 13736, 24272, 11968, 26596, 23744.
- Shop grid width, collection printing, multi-creature team controls, armor target choices, deck count controls, and scroll behavior were visually inspected. No task-started Godot console or worker process remained at final audit.
- Follow-up visual QA: `team_1920x1080_teamstable.png` was captured in a fresh process (PID 10904) after the harness polled the named workshop header for a visible y-position and 80px minimum height, then waited three settling frames. It was individually inspected at original detail with the full title, subtitle, coins, and spool readout visible.
- Follow-up direct E: parser smoke: PID 4916 exited 0 after the capture-harness update; the final process audit found no Godot console or worker process.

## Checkpoint 2 validation

The checkpoint adds `test_profile_rules.tscn` for version migration, one-time starter selection, bound-instance metadata, and pure onboarding routing. `capture_checkpoint2.tscn` is a reusable visual-QA scene that writes onboarding and workshop captures to `E:/CodexCache/printforge-validation/`; it must run with a non-headless Windows display driver because Godot's headless dummy renderer has no viewport texture to save.

- 2026-08-14 checkpoint 2 direct E: verification: parser PID 24656 exited 0; bounded profile/onboarding test PID 7016 exited 0; bounded battle regression PID 18272 exited 0; bounded OpenGL visual capture PID 24988 exited 0. No Godot console processes remained.
- 2026-08-14 checkpoint 2 transition follow-up: parser PID 15652, profile rules test PID 17056, and battle rules test PID 19712 each exited 0. Fresh-scene OpenGL capture runs PID 11420 (1280x720) and PID 6200 (1920x1080) wrote four inspected PNGs to `E:/CodexCache/printforge-validation/`; no Godot process remained.
- 2026-08-14 header-layout correction: isolated-mode capture PIDs 12700, 9448, 12436, and 21792 generated tagged onboarding/workshop files at 1280x720 and 1920x1080. The exact `workshop_*_headerfix.png` files were visually inspected at original detail and show the full `PRINTFORGE LEGENDS` title, subtitle, and ~20px top margin. Final parser PID 23756, profile test PID 23292, and battle test PID 26296 exited 0; no Godot process remained.
## 2026-08-16 0.6.1 armor-roster staging validation

- Full E:-isolated retained suite passed 34/34 Godot scenes. Expected
  environment-only output: Windows root-certificate-store warning and preexisting
  headless dummy-renderer cleanup warnings.
- Renderer-backed review is retained in `docs/art/review/armor-roster-0.6.0/`:
  24-creature no-Core, Standard, Arcane, and Legendary contact sheets at
  576x1024 and 1280x720, plus Aquafin Team, Workbench, and Battle Core captures
  at both sizes. Visual inspection confirmed source identity colors stay stable.
- The 0.6.0 export succeeded before the requested non-overwriting preset bump.
  Android Review now targets `PrintForge-Legends-0.6.1-armor-roster-arm64.apk`,
  version code 76/name `0.6.1-armor-roster`; rerun export is required after this
  preset update.

## 2026-08-16 Arcane Foundry UI + armor-roster integration

- A fresh index-derived E: worktree parsed and imported 214 assets with Godot
  4.7.1, exit 0 (wrapper PID 14600; Godot PIDs 12600/22008). The durable merged
  worktree parser also exited 0 (wrapper PID 16644; Godot PIDs 7620/11624).
- The retained suite passed 34/34 scenes in isolated E:-based app-data roots;
  the per-scene exit/PID manifest is
  `E:/CodexCache/printforge-validation/armor-ui-merge-20260816/full-34-manifest.csv`.
- Inspected merged OpenGL captures: Workbench Aquafin
  `capture-equipment/images/equipment_workbench_aquafin_576x1024.png` and
  `equipment_workbench_aquafin_1280x720.png` (wrapper PID 4672; Godot PIDs
  24884/21288); armored Aquafin battle
  `capture-battle/images/battle_armored_aquafin_storm_peak_576x1024.png` and
  `battle_armored_aquafin_storm_peak_1280x720.png` (wrapper PID 26472; Godot
  PIDs 14648/1932). The captures retain the Arcane Foundry shell and show the
  selected roster armor master at both sizes.
- Initial durable launcher/cache stalls were retained as bootstrap evidence;
  fresh and direct-to-file runs passed, so no gameplay or source fix was needed.

## 2026-08-17 0.6.2 Arcane Armor Android update

- Android Review export preset now targets the non-overwriting artifact
  `build/android/PrintForge-Legends-0.6.2-arcane-armor-arm64.apk` with
  `versionCode` 77 and version name `0.6.2-arcane-armor`.
- The 2026-08-16 merged 34/34 retained-suite evidence remains applicable to
  unchanged gameplay and UI code. The direct durable export correctly stopped
  when its non-writable stale cache lacked required tiered-armor `.ctex` files;
  a clean index-derived E: staging copy imported successfully (console/worker
  PIDs 18724/27404, exit 0) and produced the review APK (23960/19864, exit 0).
- The debug-signed arm64-only APK is 144,990,542 bytes, SHA-256
  `B82FD142F4D0E32507221C83B85651A4A614CD391CCB56073C36A971CF46E52D`.
  `apksigner` confirms v2/v3 with the Android Debug certificate; `aapt` reports
  `com.tak.printforge.legends.review`, code 77, and
  `0.6.2-arcane-armor` before its established nonzero `android:required`
  parsing warning. Archive inspection found only `lib/arm64-v8a` native
  libraries and zero excluded backend/test/tool/docs/cache/raw-armor entries.
- `adb devices -l` and mDNS discovery both returned empty lists, so no install
  or physical-device smoke was attempted.

## 2026-08-17 0.6.3 Opponent diversity and balance

- Daily Training now freezes a visible contract policy per opponent band. It
  records equipment/Core coverage, counter mode, tactics, rival spool, rating
  target/fallback metadata, and a deterministic diversity-selected lineup.
  The preview and post-result surfaces show living creature portraits plus
  suit/Core/tactics and claim/practice labels. Final inspected captures are
  retained at `E:/CodexCache/printforge-validation/` as
  `proving_576x1024_opponent-diversity.png`,
  `proving_1280x720_opponent-diversity.png`,
  `training_result_576x1024_opponent-final.png`, and
  `training_result_1280x720_opponent-final.png`.
- The paired deterministic 600-match audit passed with aggregate
  Apprentice/Circuit/Master rates **68% / 59% / 44%**, opening wins **174/168
  of 300/300** (a **2pp** delta), and **0** stalls. Contract-band rows B1–B5
  were **55/42/55**, **67/62/37**, **60/67/37**, **75/70/40**, and
  **82/52/50** (Apprentice/Circuit/Master). Every match was legal and
  terminated within the 160-turn cap; every row met its contract tolerance.
- Focused parser, opponent-rules, AI benchmark (including chooser purity and
  one successful setup-card guard), battle setup/reply-shield, and audit gates
  passed. The retained full Godot suite passed **38/38** scenes. Setup is
  symmetric: neither seat may attack or use Signature on its first action;
  the second-seat Defend grants exactly 8 reply shield.
- Android Review now targets
  `build/android/PrintForge-Legends-0.6.3-opponent-diversity-arm64.apk`,
  version code **78** / name **0.6.3-opponent-diversity**. The exact-source
  debug export completed with exit 0 and is **145,019,387 bytes**, SHA-256
  `5F68E8518CD73A40F6028F7A90990AA09BD56CE1DC0A48B14F41EA6064841090`.
  `aapt2` confirms package `com.tak.printforge.legends.review`, code 78, and
  the 0.6.3 name; `apksigner` confirms Android Debug v2/v3 signing. Archive
  inspection found only `lib/arm64-v8a` native libraries and no direct
  backend/test/tool/Git/node_modules/source-art/demo entries. The Android
  preset excludes backend, tests, tools, docs, raw source art, caches, and
  build output. No physical Android device was attached, so install/smoke is
  deliberately unclaimed.

## 2026-08-17 0.6.6 Arcane Foundry UI review

- The Arcane Foundry shell uses generated raster nine-slice panel and keycap
  assets for normal interaction, with cached semantic states for panel,
  cartridge, and button roles. High contrast deliberately substitutes
  code-native black/white `StyleBoxFlat` controls. The bundled display face is
  Arvo Bold under its included OFL notice at `assets/fonts/Arvo-OFL.txt`.
- The Blueprint Tray now has deterministic non-mutating selection and a detail
  action: portrait renders its cartridge strip plus detail below it, while
  landscape renders a grid beside detail. The reveal only fades a pre-sized
  wrapper; reduced motion is immediate and never changes layout geometry.
- Fresh isolated per-scene validation completed all **41/41** retained Godot
  scenes with a 180-second maximum per scene. Thirty-nine scenes emitted
  `PASS`; the AI and card-balance audit scenes intentionally emit only their
  audit summaries and were separately rerun with exit 0. Logs are retained
  under `E:/CodexCache/printforge-foundry-ui/logs/retained-*.log`.
- Fresh inspected OpenGL capture matrix (all exit 0) is retained outside Git at
  `E:/CodexCache/printforge-validation/`. It includes
  `workshop_printer_picker`, `battle_review`, `armor`, `training_result`,
  `card_archive`, `deck_cards`, `settings`, and `high_contrast_battle`, each
  at `576x1024` and `1280x720` with the `arcane-foundry-ui` tag. The revised
  Workbench captures are additionally tagged `arcane-foundry-ui-r2`.

### Final Arcane Foundry UI pass (2026-08-17)

- The final OpenGL matrix was regenerated after the compact nine-slice and
  Blueprint detail fixes. All 16 expected files carry the
  `arcane-foundry-ui-final` tag under `E:/CodexCache/printforge-validation/`:
  `workshop_printer_picker`, `battle_review`, `armor`, `training_result`,
  `card_archive`, `deck_cards`, `settings`, and `high_contrast_battle`, each at
  `576x1024` and `1280x720`. Every original-size image was inspected. The
  final pass confirms the Blueprint title stays visible at the scroll origin,
  cards contain only concise selector copy, the detail pane owns print/owned
  metadata, Settings opens at its heading, the Workbench uses compact controls,
  and high contrast uses the intentional native fallback. The capture runner
  PIDs were 21984, 22192, 26640, 21020, 26500, 23812, 2616, 23928, 27028,
  9384, 2984, 19004, 3948, 15672, 26192, and 860; it reported `Captured=true`
  for every output.
- The authoritative isolated ProcessStartInfo suite manifest is
  `E:/CodexCache/printforge-foundry-ui/retained-suite-final-arcane-ui/suite-manifest.jsonl`.
  It records **41/41 exit code 0**, no timeouts, fresh E:-scoped
  `APPDATA`/`LOCALAPPDATA`/`TEMP` for every scene, and console PIDs per scene.
  This supersedes the earlier convenience-log runner, which did not reliably
  expose Godot exit codes.
- A final fresh-cache Godot 4.7.1 editor parse/import exited 0. The focused
  `test_arcane_foundry_theme`, `test_presentation`,
  `test_equipment_workbench_ui`, and `test_ui_workshop_nav` records are all
  present with exit code 0 in that manifest. The navigation test no longer
  emits a freed-scroll script error; ordinary Godot teardown leak warnings are
  retained in its per-scene stderr log.
- The final compact-runtime debug export is
  `build/android/PrintForge-Legends-0.6.6-arcane-foundry-ui-arm64.apk`,
  version code **81**, version name **0.6.6-arcane-foundry-ui**, package
  `com.tak.printforge.legends.review`, size **147,114,930 bytes**, SHA-256
  `BF3E1AE59207A59C2EDF4419C857ECA31B1FE9DC9BAB183CFB34B74C270F15B4`.
  `apksigner` verifies debug v2/v3 signing; archive inspection found only
  `lib/arm64-v8a` native libraries and **0** backend/test/tool/docs entries.
  `aapt` reports the expected package/version before its established
  non-fatal `android:required` manifest parsing warning.
- Runtime texture cleanup retained only seven compact Foundry plates (panel,
  four keycap states, cartridge, and shallow inset) under
  `assets/ui/arcane_foundry/`. The deterministic builder reads the approved
  source plates under `docs/art/source/ui/arcane-foundry-v2/` directly and no
  longer emits raw or trim intermediates. The focused theme contract and
  Forward+ spot captures for Blueprint Tray, Battle, and Equipment Workbench
  at `576x1024` and `1280x720` passed with the `compact-final` tag.

## 2026-08-17 0.6.7 Workshop Hub validation

- Godot 4.7.1 parser/import completed with exit 0. Focused navigation, live,
  depth, export-boundary, and startup gates also exited 0. The full suite
  passed **42/42** scenes with **38** `PASS` markers; its manifest is
  `E:/CodexCache/printforge-workshop-hub/full-suite/suite-manifest.json`.
- The v4 direct-object Workshop Hub captures were visually inspected at
  `E:/CodexCache/printforge-validation/workshop_1280x720_workshop-hub-067.png`
  (capture PIDs 21368/5340) and
  `E:/CodexCache/printforge-validation/workshop_576x1024_workshop-hub-067.png`
  (capture PIDs 24652/412).
- Android review export:
  `build/android/PrintForge-Legends-0.6.7-workshop-hub-arm64.apk`; package
  `com.tak.printforge.legends.review`, version code **82**, **151,072,534**
  bytes, SHA-256
  `A67E0909E76DACF07C3E20FFB44B95F9DB1D1E785FE4CA786BC4712DA96E9FB7`.
  It is debug v2/v3 signed, arm64-only, and archive inspection found **0**
  forbidden backend/tests/tools/docs entries. Export Godot PIDs 12832/7372,
  task Java PIDs 19212/25812/2388, and adb PID 13244 were all cleaned up.
- APK and README DriveFS copies to
  `H:/My Drive/AI Projects/PrintForge` were verified by size and SHA-256;
  cloud synchronization was not independently confirmed. No physical-device
  smoke was performed.
