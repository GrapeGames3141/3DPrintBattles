# PrintForge physical UI M5 no-ad Android delivery checkpoint v1

Status: decision-complete implementation and delivery contract; no build/device/Drive
evidence is claimed until the bounded M5 run completes

Date: 2026-08-31

Authority: the active no-AdMob goal, the approved portrait physical UI direction,
M1–M3 gameplay/UI/save checkpoints, and the repository Android/Drive delivery rules.
This checkpoint supersedes the implementation authority of the earlier native review-
banner sections in `docs/design/printforge-screen-first-gameplay-v1.md`,
`docs/checkpoints/printforge-physical-ui-preproduction-v1.md`, and
`docs/checkpoints/printforge-physical-ui-m4-android-delivery-v1.md`. Those documents
remain historical records; their AdMob SDK/plugin/test-ID/banner requirements must not
be implemented or shipped in M5.

M5 removes advertising capability and delivers a new no-ad review APK. It changes no
catalog value, gameplay rule, profile/save schema, ownership rule, economy, reward,
deck/Pre-Print rule, Forge or battle transaction, animation outcome, accessibility
value, or screen-flow authority.

## Locked review identity

| Field | Required value |
| --- | --- |
| Marketing version | `0.8.5-physical-ui-no-ad-review` |
| Android version code | `101` |
| Package | `com.tak.printforge.legends.playtest` |
| Export kind | Android debug/review APK |
| Orientation | Portrait only |
| Native ABI | `arm64-v8a` only |
| Advertising capability | Absent |
| Godot/native ad reserve | None; `0` additional pixels |

The build uses the already approved branding without redesign or regeneration:

| Purpose | Approved source | SHA-256 |
| --- | --- | --- |
| Legacy/main launcher icon | `docs/art/printforge-physical-ui-spike-20260830/branding-app-icon-v1.png` | `91C67524D124506EE74333957F9D6CD1A37654315032C1417248A085B681034F` |
| Adaptive background | `docs/art/printforge-physical-ui-spike-20260830/branding-adaptive-icon-background-v1.png` | `397ED26029D9BF6D1F1657546CDC5081A3111278402CD6B3A78A9607880A9935` |
| Adaptive foreground | `docs/art/printforge-physical-ui-spike-20260830/branding-adaptive-icon-foreground-v2.png` | `22D433B4EFDD4DE827A591B5C70B9C82C8A3B36BDA3F9D3E87600C3CE68CAE3B` |

Any exportable runtime derivatives must retain those exact identities and document
their deterministic size/crop transformation. Generated source masters under `docs/`
remain excluded from the APK.

## No-AdMob definition

“No AdMob” means absence, not an inert or disabled integration. The exact source tree,
export boundary, resolved Android project, and final APK must contain none of the
following:

- Google Mobile Ads/AdMob SDK Maven dependencies, AARs, Java/Kotlin classes, DEX
  references, native libraries, resources, ProGuard/R8 rules, Gradle plugin hooks, or
  transitive advertising dependencies.
- Godot AdMob addon/export plugin files, enabled plugin records, autoload/singleton
  entries, adapters, native host bridges, diagnostics signals, banner nodes,
  placeholders, test fixtures packaged as runtime UI, or load/show/hide/retry/request
  paths.
- Production, sample, test, placeholder, or commented AdMob app/unit IDs. This
  includes the previously approved Google sample identifiers; no identifier is kept
  “for later.”
- AdMob application metadata such as
  `com.google.android.gms.ads.APPLICATION_ID`, ad-services config, mediation metadata,
  provider/receiver/service/activity declarations, or advertising initialization.
- Advertising-specific permissions such as
  `com.google.android.gms.permission.AD_ID` and Android Privacy Sandbox ad-services
  permissions. Any generic permission previously introduced solely for advertising
  is removed. A generic permission required independently by existing game/platform
  behavior must be justified by that non-ad owner and is not evidence of AdMob.
- Network requests, DNS endpoints, consent prompts, disclosure labels, ad event
  callbacks, ad-derived telemetry, rewarded/interstitial/app-open/native/banner code,
  or progression hooks.

Case-insensitive source/archive scans include `admob`, `MobileAds`,
`com.google.android.gms.ads`, `ca-app-pub-`, `AdView`, `AdRequest`, `AD_ID`,
`ACCESS_ADSERVICES`, `rewarded`, `interstitial`, `app_open`, and known Google ads
resource/manifest names. A match fails until classified and removed; allowlisting a
shipped advertising implementation is forbidden. Historical Markdown under `docs/`
may retain the terms because `docs/` is excluded from the APK, but runtime/export
source must not.

## Feature contracts

### Complete advertising capability removal

- **Entry:** Start from the exact approved M1–M3 runtime plus any historical M4
  advertising integration present in source, addons, Android plugins, or export
  configuration.
- **Player decision:** None. The player is never offered an ad, consent-for-ads,
  reward, disclosure, retry, close, or advertising preference.
- **Result:** All AdMob SDK/plugin/bridge/identifier/permission/metadata/request and
  callback paths are removed from runtime and export inputs. No advertising object can
  initialize, load, request, display, resize, signal, or reward on any platform.
- **Failure:** Any surviving direct/transitive dependency, class/resource/string,
  plugin flag, ID, manifest declaration, permission, request path, or ad callback
  blocks export acceptance. “Disabled,” “test-only,” and “empty production ID” do not
  satisfy removal.
- **Disabled:** Advertising is absent rather than disabled. No compile-time flag,
  hidden menu, remote switch, or dormant adapter may reactivate it.
- **Feedback:** Source and resolved-export audits produce a path/class/dependency
  ledger with zero unexplained advertising matches. The game UI shows no ad label,
  blank band, placeholder, disclosure, or consent surface.
- **Progression:** Removal affects no profile field, RNG, timer, revision, currency,
  reward, entitlement, save, battle intent, Forge transaction, or input path.

### Full portrait usable surface with no ad strip

- **Entry:** Godot receives the portrait host surface on desktop/headless or Android,
  including system safe-area information that is independently required by the host.
- **Player decision:** Use the existing physical UI normally; there is no ad-derived
  layout or control.
- **Result:** Godot occupies the full usable host surface after ordinary system insets.
  Additional bottom ad reserve is exactly `0`; no native sibling/overlay/placeholder
  reduces or covers the surface. M1–M3 safe-area and portrait rebuilding remain
  unchanged except removal of ad-only branches.
- **Failure:** A persistent blank bottom band, ad-sized padding, ad-height diagnostic,
  ad-only resize, covered control, double-counted system inset, or platform-dependent
  gameplay geometry blocks acceptance.
- **Disabled:** Runtime and production captures contain no synthetic ad overlay. A
  historical labeled synthetic fixture may remain only in excluded test/evidence
  tooling if needed for regression history; it cannot affect the shipped layout or be
  cited as M5 device evidence.
- **Feedback:** Geometry evidence records viewport, safe-area, and every primary
  action bound at standard/tall portrait sizes; there is no advertising state or
  banner height to report.
- **Progression:** Layout has zero gameplay/save mutation and does not alter
  deterministic input reachability.

### Version, package, ABI, orientation, and branding

- **Entry:** The no-ad source boundary and approved branding resources are ready for
  one exact-commit export.
- **Player decision:** None; build identity is fixed by this checkpoint.
- **Result:** The APK reports version `0.8.5-physical-ui-no-ad-review`, code `101`,
  package `com.tak.printforge.legends.playtest`, portrait orientation, and only
  `arm64-v8a`. Legacy and adaptive launcher icons use the approved identity sources.
- **Failure:** Wrong/missing version, code, package, ABI, orientation, launcher
  activity, icon identity, or accidental docs/concept packaging blocks delivery.
- **Disabled:** No alternate ABI, landscape activity branch, production package,
  AAB/release claim, icon redesign, or alternate branding is produced by this task.
- **Feedback:** Export evidence records exact commit, clean status, Godot/JDK/SDK tool
  identity, package metadata, archive ABI list, icon resources, signing result, APK
  bytes, and SHA-256.
- **Progression:** Build identity changes no runtime game or save value.

### M1–M3 behavior preservation

- **Entry:** Run existing deterministic/UI suites from the no-ad source with isolated
  E:-based test data and unchanged catalog/save fixtures.
- **Player decision:** Exercise Title/New Maker/Settings, Starter/First Print,
  Workshop/Forge, simplified Battle, Archive/inspection, Deck/Pre-Print, Supplies/
  Pack, Result/rewards, and Recovery using existing choices.
- **Result:** The same accepted inputs produce the same routes, serialized states,
  revisions, receipts, rewards, saves, card/blueprint ownership, print/attack
  animations, and accessibility outcomes. Approved physical UI, intact blueprint
  family, creature sprites, support art, card back, title, and launcher branding remain
  present.
- **Failure:** Missing UI/art, changed transaction count/order, animation loss, save
  incompatibility, hidden/unreachable action, new blank region, or gameplay/value
  drift blocks export.
- **Disabled:** No ad event, absent adapter, or removed signal may be replaced by a
  gameplay fallback, bonus, delay, layout reserve, or conditional action.
- **Feedback:** Regression summary records exact pass/fail counts and named failures;
  representative original-resolution captures are compared with the approved M1–M3
  physical direction.
- **Progression:** Deterministic profile and battle outcomes are byte-equivalent for
  identical fixtures; no migration or bonus is introduced.

### Clean exact-commit export and no-ad APK audit

- **Entry:** All intended source/config removals and M5 branding/version changes are
  reviewed, tests pass, and the exact export commit has a clean working tree.
- **Player decision:** None; export is a reproducible release-engineering action.
- **Result:** One portrait arm64 debug APK is exported from that exact commit. Static
  audit verifies package/version/code/orientation/launcher/signing/ABI/resources and
  proves no advertising dependency, class, resource, ID, permission, metadata,
  component, string, or request path in the resolved manifest, DEX, resources, native
  libs, or archive.
- **Failure:** Dirty tree, mismatched commit, export error, signing/metadata mismatch,
  additional ABI, unclassified scan match, advertising transitive dependency, test/
  evidence leakage, or archive corruption blocks delivery.
- **Disabled:** No stale APK may be relabeled. No build from an uncommitted tree and no
  APK whose content commit cannot be identified is commit-qualified.
- **Feedback:** Retain export command, tool versions, exact commit/full hash, clean-tree
  proof, process/PID/exit cleanup, resolved manifest, dependency tree, archive listing,
  scan reports, signing report, metadata, local size, and SHA-256.
- **Progression:** Export/audit writes no player profile and changes no game state.

### Conditional physical-device gate

- **Entry:** Static APK audit has passed and `adb devices -l` reports exactly one
  authorized device, or the user explicitly selects one serial when several exist.
- **Player decision:** On an available device, launch and exercise Title to six-hotspot
  Workshop plus representative Forge, Battle, and management routes. If no device is
  available, no device action occurs.
- **Result:** The audited APK installs and launches in portrait, uses the full usable
  surface with no ad strip/label/consent/blank band, preserves controls and animations,
  and shows no advertising initialization/request in retained logs.
- **Failure:** Unauthorized/offline device, install/launch error, crash/ANR, landscape
  launch, blank bottom band, clipped controls, missing animation, ad-related log/
  network activity, or package/version mismatch fails device acceptance.
- **Disabled:** If no authorized adb device exists, mark install, launch, screenshot,
  live no-ad geometry, and log/network observation
  **BLOCKED — no adb device**. Do not substitute desktop capture or emulator evidence
  and call it physical-device proof.
- **Feedback:** Record attributed device/API/orientation, commands/exits, portrait
  screenshots/log paths, and separate PASS/FAIL/BLOCKED results without publishing
  unnecessary device identifiers.
- **Progression:** Device validation uses isolated review data and cannot overwrite a
  player's durable save or external/cloud data.

### Non-overwriting Google Drive delivery

- **Entry:** The commit-qualified local APK and companion README have passed every
  available required gate; any unavailable device checks are explicitly BLOCKED.
- **Player decision:** None; delivery targets the established studio DriveFS
  `My Drive\AI Projects\PrintForge` release folder.
- **Result:** Copy new, non-overwriting files named:
  `PrintForge-Legends-0.8.5-physical-ui-no-ad-review-arm64-<commit12>.apk` and
  `README-0.8.5-physical-ui-no-ad-review-<commit12>.md`. README records version/code/
  package/ABI/commit, debug signing, no-AdMob audit, test/device outcomes, local and
  Drive sizes/SHA-256, and launch scope.
- **Failure:** Missing/stale DriveFS mount, wrong account/folder, filename collision,
  copy failure, size/hash mismatch, placeholder/stale file, or incomplete README
  prevents delivery completion. Never overwrite an existing release.
- **Disabled:** Cloud visibility is not inferred from a filesystem copy. Existing
  releases are never deleted, renamed, or replaced.
- **Feedback:** Report local artifact, Drive destination, source/destination byte size
  and SHA-256, `DriveFS copy: VERIFIED`, and cloud status separately as `CONFIRMED` or
  `PENDING` with the evidence used.
- **Progression:** Delivery changes no game/profile data and grants no ad/economy
  value.

## Required source, export, and APK evidence

Before Drive delivery, the bounded implementation must prove all of the following:

1. Source inventory shows every historical AdMob addon/plugin/adapter/bridge/ID/
   manifest fragment/request path removed from runtime/export inputs. No enabled or
   dormant advertising flag remains.
2. Dependency resolution for the Android export contains no Google Mobile Ads,
   mediation, ad-services, or advertising library, including transitive dependencies.
3. Resolved `AndroidManifest.xml` contains no AdMob application metadata, ad
   component/provider/service/receiver, `AD_ID`, ad-services permission, or permission
   whose only owner was the removed ad integration.
4. APK archive, resources, DEX/class/string, native-library, and manifest scans have
   zero unexplained advertising matches, including no `ca-app-pub-` sample/test ID.
5. Package/version/code/orientation/MAIN-LAUNCHER/arm64/debug-signing and approved
   legacy/adaptive icon resources are correct. Archive has no second ABI.
6. Godot content reserve is `0`, no ad-height signal/consumer or placeholder exists,
   and portrait geometry shows no blank/covered strip at `576x1024`, `720x1280`, and
   necessary tall fixture/device height.
7. M1–M3 focused and full deterministic regressions pass, including Title/New Maker,
   all Workshop hotspots, Starter/First Print, Forge/print animations, Battle print/
   awaken/attack animations, Archive/Deck/Pre-Print, Supplies/Pack, Result/reward,
   Settings/Recovery, saves, 150% text, contrast, and reduced motion.
8. Exact-commit proof binds source HEAD, clean status, local APK, README, static audit,
   and Drive filenames to one full commit hash.
9. Device evidence passes when available; otherwise every physical-only claim is
   explicitly blocked without preventing a truthful statically audited review APK
   delivery.
10. DriveFS copy is non-overwriting and verified by matching bytes and SHA-256; cloud
    synchronization is separately confirmed or left pending.

## Explicit non-goals

- No AdMob, Google Mobile Ads, mediation, other ad network, banner, interstitial,
  rewarded, rewarded-interstitial, app-open, native-feed ad, ad consent, ad telemetry,
  ad identifier, ad permission, ad placeholder, or future dormant advertising hook.
- No production or test app/unit IDs and no “disabled for now” advertising package.
- No reserved ad strip, speculative bottom padding, Godot-drawn disclosure, native
  banner sibling, advertising height diagnostic, or synthetic ad fixture in the
  shipped APK.
- No gameplay/catalog/economy/save/reward/profile/authority change; no ad-removal
  bonus, migration, compensation, or altered deterministic timing.
- No landscape branch, alternate ABI, AAB/release-store claim, production signing,
  package rename, icon redesign, or generated branding replacement.
- No device claim without an authorized physical device; no cloud-sync claim from a
  successful DriveFS filesystem copy alone.
- No overwrite, deletion, or renaming of an existing local or Drive release.

## Completion boundary

M5 is complete only when the no-ad source/dependency/manifest/APK audits pass, the
clean exact-commit portrait arm64 debug APK and README are copied non-overwriting to
the established Drive folder with matching size/SHA-256, and cloud status is reported
separately. If no authorized adb device exists, physical install/launch/screenshot/
live-log claims remain `BLOCKED — no adb device`; that blocked status must never be
relabelled PASS.

This Markdown checkpoint is planning evidence only. It does not claim that AdMob has
already been removed, an APK has been built/audited, a device has been attached, Drive
has been written, or cloud synchronization has completed.
