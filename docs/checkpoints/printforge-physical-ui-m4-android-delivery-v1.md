# PrintForge physical UI M4 Android delivery checkpoint v1

Status: decision-complete implementation contract; no Android/native-AdMob/build/
device/Drive evidence exists until the bounded M4 implementation and validation run

Date: 2026-08-31

Entry baseline: the next Sol-approved commit containing the completed M1–M3 physical
UI checkpoints. Final artifact identity is always the actual clean export commit, not
the branch name or this document's authoring commit.

Authority: `docs/checkpoints/printforge-physical-ui-preproduction-v1.md`, the M1–M3
physical UI checkpoints, `docs/design/printforge-screen-first-gameplay-v1.md`, the
repository `AGENTS.md`, and the PrintForge/portrait-AdMob/DriveFS workflows. This
checkpoint changes Android review presentation and delivery only. It changes no
catalog value, deterministic game rule, profile/save schema, economy, reward,
ownership, battle revision, Forge transaction, pack receipt, or progression rule.

## Locked review build identity

| Field | Required value |
| --- | --- |
| Version name | `0.8.4-physical-ui-review` |
| Version code | `100` |
| Package | `com.tak.printforge.legends.playtest` |
| Export kind | Android debug/review APK |
| Orientation | Portrait only |
| Native ABI | `arm64-v8a` only |
| Production AdMob app ID | Empty/unset |
| Production AdMob unit IDs | Empty/unset |
| Review AdMob app ID | Google's sample `ca-app-pub-3940256099942544~3347511713` |
| Review anchored-adaptive banner unit | Google's sample `ca-app-pub-3940256099942544/9214589741` |
| Godot production content reserve | `0` |

The Google sample identifiers are review-only build inputs. The review build must not
contain an account-owned production identifier or silently substitute one. A
non-review/desktop/headless build with empty production identifiers performs no ad
request. Google documents the sample app ID in its
[Android SDK quick start](https://developers.google.com/admob/android/quick-start)
and the anchored-adaptive test banner ID in its
[Android banner guidance](https://developers.google.com/admob/android/banner);
recheck those official sources immediately before implementation if the SDK/plugin
generation changes.

## Approved Android branding promotion

Promote exactly these already approved generated masters from the concept ledger into
exportable Android launcher resources. Do not regenerate, repaint, add text, combine
them with another icon family, or use the rejected adaptive foreground v1.

| Role | Approved source | Size / bytes | SHA-256 |
| --- | --- | ---: | --- |
| Legacy/main launcher | `docs/art/printforge-physical-ui-spike-20260830/branding-app-icon-v1.png` | `1254x1254` / `2,399,131` | `91C67524D124506EE74333957F9D6CD1A37654315032C1417248A085B681034F` |
| Adaptive background | `docs/art/printforge-physical-ui-spike-20260830/branding-adaptive-icon-background-v1.png` | `1254x1254` / `2,484,293` | `397ED26029D9BF6D1F1657546CDC5081A3111278402CD6B3A78A9607880A9935` |
| Adaptive foreground | `docs/art/printforge-physical-ui-spike-20260830/branding-adaptive-icon-foreground-v2.png` | `1254x1254` / `1,231,795` | `22D433B4EFDD4DE827A591B5C70B9C82C8A3B36BDA3F9D3E87600C3CE68CAE3B` |

The bounded writer may copy the three identity-preserving masters to exportable paths
under `assets/ui/branding/android/` and point Godot's main/adaptive launcher fields to
those paths. Mechanical Android density generation is allowed; the source identity,
foreground/background separation, crop intent, and provenance remain recorded. The
export audit must prove the APK contains both a legacy launcher fallback and adaptive
foreground/background resources. Generated source files under `docs/` remain excluded
from the APK.

## Native-bottom banner ownership and state machine

The banner is a native Android sibling below the Godot surface, never a Godot Control
and never an overlay across game content. The native host owns the loaded creative,
its disclosure, and bottom navigation/gesture safe inset. Godot always reports
additional game content reserve `0` and lays out only inside the surface provided by
the native host.

The host uses one generation token and these observable states:

1. **Inert:** desktop, headless, editor, plugin missing, non-review build, production
   IDs empty, or review feature absent. No SDK initialization, request, placeholder,
   surface change, or gameplay signal.
2. **Loading:** initialize with only the official sample app/unit IDs and request one
   bottom anchored-adaptive banner. Keep the Godot surface at its exact no-banner
   bottom constraint; reserve no speculative height and show no blank strip.
3. **Loaded/visible:** only after the native load callback supplies a valid view and
   measured creative does one UI-thread layout transaction attach the native banner
   below Godot and constrain the Godot surface above it. Native Android retains
   ownership of the creative and system inset.
4. **Collapsed:** failure, no-fill, offline, hide, plugin removal/unavailability,
   invalid view, lifecycle teardown, or superseding generation removes/hides the
   native view and restores the Godot container to its exact zero-additional-bottom-
   inset constraint in one layout transaction. No empty band remains.
5. **Reloaded:** a later explicit review reload starts a new generation from Loading.
   Late callbacks from an older generation cannot attach a view or resize the surface.

There is exactly one Godot-facing height signal,
`native_banner_height_changed(height_px)`. It is diagnostics-only: it may log the
measured loaded height and `0` after collapse, but no Godot layout, safe-area,
gameplay, UI route, timer, RNG, save, input, reward, or test fixture may consume it as
a content reserve. Native host geometry is the sole layout authority.

## Feature contracts

### Approved launcher branding

- **Entry:** M4 starts from the three hash-verified approved source masters and a
  clean exact-commit Android export workspace on `E:`.
- **Player decision:** None. Launcher branding is platform presentation and exposes no
  gameplay choice.
- **Result:** Main/legacy launchers use app-icon v1; adaptive launchers use background
  v1 and foreground v2 as separate layers. Android density resources retain the
  approved silhouette and safe crop.
- **Failure:** Missing source, hash mismatch, invalid dimensions/alpha, import error,
  clipped adaptive safe zone, or fallback/adaptive resource omission blocks export.
  It never silently uses the old generic launcher icon.
- **Disabled:** Regeneration, v1 adaptive foreground, baked title/version text, and
  alternate icon selection are outside M4.
- **Feedback:** Export/source audit names all three promoted runtime paths, source
  hashes, Android resource roles, and any deterministic derivation.
- **Progression:** Branding affects no profile, catalog, save, entitlement, ad,
  gameplay, revision, RNG, or reward state.

### Review package configuration

- **Entry:** Export only after the bounded M4 source/config work is reviewed and
  committed, using a clean checkout/worktree of that exact commit on `E:`.
- **Player decision:** None. The build is an explicitly labeled internal review APK.
- **Result:** Export one portrait, arm64-only, debug-signed APK with package
  `com.tak.printforge.legends.playtest`, version `0.8.4-physical-ui-review`, and code
  `100`. The filename embeds the actual commit's 12-character short SHA.
- **Failure:** Dirty/exact-source ambiguity, wrong package/version/code/orientation,
  extra ABI, missing launcher resource, signing failure, or export warning that
  invalidates metadata/archive acceptance blocks delivery.
- **Disabled:** AAB, release/production signing, Play upload, landscape support,
  production package, production ad IDs, and version fallback to 0.8.3 are disabled.
- **Feedback:** The retained export log records exact source commit, Godot/template/
  Android tool identities, command, task-owned PIDs, exit, APK path, and cleanup.
- **Progression:** Build configuration changes no runtime game value or save schema.

### Native banner load and layout

- **Entry:** The Android review feature is active, the official sample app/unit IDs
  are present, the plugin is available, and the portrait native root is ready.
- **Player decision:** None. There is no Open Ad, Watch Ad, Close-for-reward, consent
  reward, pack, retry currency, or gameplay input tied to the banner.
- **Result:** Loading keeps the no-banner surface. A successful load alone attaches
  the native bottom banner and resizes the Godot surface above it. Hide/failure/no-
  fill/offline/plugin-missing/teardown restores the exact zero-additional-bottom-inset
  Godot surface with no blank band or covered target.
- **Failure:** SDK init/request/callback/view/layout failure collapses safely, reports
  diagnostics, invalidates the generation, and leaves gameplay fully available. It
  cannot loop requests without an explicit bounded reload policy.
- **Disabled:** Interstitial, rewarded, rewarded-interstitial, app-open, native-feed,
  production ad request, duplicate disclosure, game-owned banner placeholder, and
  Godot-side creative/safe-inset reserve are disabled.
- **Feedback:** Native SDK test disclosure remains native. Logs expose state/generation,
  callback outcome, and the one diagnostic height signal without IDs beyond the
  approved samples or player/device identifiers.
- **Progression:** Ad initialization, load, impression, click, failure, hide, reload,
  size, and consent state affect no game clock, Forge/battle presentation, input,
  profile, save, revision, RNG, currency, pack, reward, or entitlement.

### Desktop/headless and deterministic isolation

- **Entry:** Launch editor, desktop, headless tests, export scans, or Android builds
  without the explicit review feature/plugin/sample configuration.
- **Player decision:** Use the same game UI and deterministic workflows; no ad control
  is shown.
- **Result:** The banner adapter is inert, makes no SDK/network request, adds no node
  or blank region, reports game content reserve `0`, and preserves the M1–M3 layout.
- **Failure:** Unexpected plugin probing, non-Android initialization, nonzero reserve,
  or gameplay/profile differences fail the source/plugin boundary tests.
- **Disabled:** Desktop simulation may use only the already labeled synthetic overlay
  fixture; it cannot claim native AdMob behavior or enable a real request.
- **Feedback:** Tests identify the inert reason and assert zero layout/game mutation.
- **Progression:** Byte-equivalent deterministic fixtures produce the same accepted
  intents, revisions, transactions, rewards, and saves with the adapter present or
  absent.

### APK export and static audit

- **Entry:** Source/plugin/export-boundary tests pass in the clean exact-commit export
  workspace and matching Godot 4.7.1 Android templates/toolchain are available.
- **Player decision:** None. Export/audit is a release-engineering gate.
- **Result:** The debug/review APK exports once, passes signer verification, reports
  the locked package/version/code/portrait metadata, contains only `arm64-v8a` native
  libraries, includes required launcher/adaptive/plugin/game assets, and excludes
  source-only or unsafe paths.
- **Failure:** Nonzero export/signing/audit exit, mismatched metadata, missing/extra
  ABI, invalid manifest component, absent icon/ad resources, production ID, forbidden
  archive entry, or startup-native crash blocks Drive delivery.
- **Disabled:** No failed or unaudited APK is renamed into the release convention. A
  debug signature is reported truthfully and never called production/release signed.
- **Feedback:** Retain export log, `aapt2`/equivalent metadata, `apksigner` result,
  archive inventory summary, byte size, and SHA-256 under an M4 evidence root on `E:`.
- **Progression:** Export and audit do not open or mutate the player's real v3 save.

### Conditional physical-device gate

- **Entry:** Run `adb devices -l` after APK audit. A physical launch gate exists only
  when exactly one explicitly authorized device serial is available; if multiple are
  present, use a user-selected serial rather than guessing.
- **Player decision:** On an available device, launch and exercise Title→Workshop,
  banner load, collapse/failure fixture, hide/restore, and one representative Forge/
  Battle/management route; otherwise no device interaction occurs.
- **Result:** When available, install the audited APK, launch its MAIN/LAUNCHER
  activity, retain logcat and portrait screenshots, and confirm no blank band, covered
  control, duplicate disclosure, layout jump before load, or game-state difference.
  Failure/hide restores the exact no-banner surface.
- **Failure:** Unauthorized/offline device, install/launch failure, crash/ANR, banner
  overlap, unexplained blank band, failure that does not restore, or production ad
  traffic blocks device acceptance and is reported exactly.
- **Disabled:** If `adb` reports no authorized device, mark physical launch,
  real-device screenshot, real banner-load, and real banner-failure evidence
  **BLOCKED — no adb device**. Do not substitute desktop synthetic geometry, an
  emulator, or source tests and call it physical-device proof.
- **Feedback:** Record adb serial only in the private evidence needed for attribution,
  device/API/orientation, install/launch exit, screenshot/log paths, and separate PASS,
  FAIL, or BLOCKED outcomes for launch, banner load, and banner collapse.
- **Progression:** Device/ad validation uses an isolated review profile and must not
  alter a player's durable save, rewards, purchases, or cloud data.

### Commit-qualified Google Drive delivery

- **Entry:** The APK passed every available non-device gate; the final source commit
  and APK size/SHA are known; any unavailable device gate is explicitly BLOCKED in
  the README rather than silently omitted.
- **Player decision:** None. Delivery targets the established studio PrintForge release
  folder and never overwrites an existing file.
- **Result:** Resolve the observed studio DriveFS mount and deliver to
  `H:\My Drive\AI Projects\PrintForge` when that remains the mounted studio layout.
  Use filenames:
  `PrintForge-Legends-0.8.4-physical-ui-review-arm64-<commit12>.apk` and
  `README-0.8.4-physical-ui-review-<commit12>.md`. Verify local source and DriveFS APK
  byte size and SHA-256 are identical; verify the README copy separately.
- **Failure:** Missing/ambiguous account, inaccessible/unmounted DriveFS, existing
  destination name, copy failure, size/hash mismatch, or unsafe mount restart stops
  delivery and preserves every existing release. Access Denied in a restricted shell
  is rechecked in the authorized desktop context before declaring the mount absent.
- **Disabled:** Overwrite, deletion/renaming of an earlier release, top-level personal
  Drive fallback, force-restarting a mounted DriveFS client, and claiming upload from
  local copy alone are disabled.
- **Feedback:** README records commit/branch, package/version/code/ABI/orientation,
  debug signer result, APK bytes/SHA, icon source identities, official test-ad-only
  configuration, production IDs empty, test summary, device PASS/FAIL/BLOCKED status,
  DriveFS paths, copy verification, and a separate cloud-sync status.
- **Progression:** Delivery changes no game/profile state. DriveFS copy verified and
  cloud synchronization confirmed are separate outcomes; if cloud visibility is not
  independently observed, report `cloud synchronization: PENDING`.

## Source, plugin, and export acceptance

Before export, automated evidence must prove:

1. Review configuration contains exactly the official sample app ID and anchored-
   adaptive banner unit above; every production ID field is empty. Source/archive
   scans find no rewarded/interstitial/app-open request path or progression callback.
2. Host state tests cover Inert→Loading→Loaded, Loading→Collapsed for failure/no-fill/
   offline/plugin missing, Loaded→Collapsed for hide/teardown, and stale callback
   rejection. The Godot surface changes only after load and returns to exact zero
   additional bottom inset on every collapse path.
3. `native_banner_height_changed(height_px)` is the only height signal, is emitted for
   diagnostics, and has no layout/gameplay consumer. `game_content_reserve_height()`
   or its established equivalent returns `0` in production and review gameplay.
4. Desktop/editor/headless/plugin-absent tests make zero request and retain identical
   M1–M3 geometry and deterministic state. The positive desktop fixture remains visibly
   labeled synthetic.
5. Icon contract tests verify the three approved source hashes, promoted exportable
   resources, legacy/adaptive export fields, and source-only `docs/` exclusion.
6. Export-boundary tests exclude at least `.git`, `.godot`, `.agents`, `.codex`,
   `backend`, `tests`, `tools`, `docs`, `art-source`, `build`, temporary/user data,
   credentials, keystores, logs, evidence, and unused concept masters while retaining
   every required runtime UI, creature/card, icon, Android plugin, and manifest asset.
7. Focused M1–M3 deterministic transaction and layout regressions remain green with
   the banner adapter present and inert. Ad event order cannot change a seed, intent,
   transaction, save, reward, animation decision, or input reachability.

## APK and delivery acceptance checklist

- Export path on `E:` and artifact name include version and `<commit12>`; exact source
  commit is clean and retained.
- `apksigner verify --verbose` (or current equivalent) passes and identifies the APK
  truthfully as debug/review signed.
- Metadata reports package `com.tak.printforge.legends.playtest`, version code `100`,
  version `0.8.4-physical-ui-review`, portrait support, and the intended launcher.
- Archive contains native libraries only under `lib/arm64-v8a/`, contains required
  Godot/plugin/launcher/adaptive resources, and contains no production ad ID, secret,
  source-only path, test scene, build evidence, or alternate ABI.
- Local APK byte size and SHA-256 are recorded before Drive copy.
- Device launch/banner screenshot/load/failure are PASS when an authorized adb device
  exists; otherwise each is explicitly `BLOCKED — no adb device`.
- Drive destination is the observed studio account's established
  `My Drive\AI Projects\PrintForge` folder. APK and README names are commit-qualified
  and non-overwriting.
- DriveFS APK byte size/SHA match local exactly. A local DriveFS match is reported as
  `DriveFS copy: VERIFIED`; cloud-visible synchronization is independently reported
  as `CONFIRMED` or `PENDING`, never inferred.

## Explicit non-goals

- No production AdMob app/unit ID, account secret, consent shortcut, analytics key,
  rewarded/interstitial/app-open/native-feed ad, ad-derived currency, ad-gated action,
  or store monetization claim.
- No Godot-drawn banner/disclosure, speculative loading reserve, creative-height
  constant, double-counted safe inset, or gameplay use of the diagnostic height.
- No catalog/gameplay/economy/save/reward/profile/authority change and no persistent
  Forge filament inventory.
- No landscape runtime branch, x86/x86_64/armeabi-v7a APK, AAB, release keystore,
  production signing, Play Console upload, public release, or version other than the
  locked review identity.
- No icon redesign, title text baked into launcher art, regenerated branding family,
  or runtime packaging of concept/evidence masters under `docs/`.
- No device claim without a real authorized adb device; no native-banner claim from a
  desktop synthetic fixture.
- No overwrite/removal of an existing local or Drive release and no claim of cloud
  synchronization based only on a successful DriveFS filesystem copy.

## Completion boundary

M4 completes only when the bounded implementation, available source/plugin/export/
APK/device checks, exact-source commit, commit-qualified local APK/README, and verified
non-overwriting DriveFS copies are recorded. A missing adb device may leave the four
physical-device claims explicitly BLOCKED while still allowing a clearly labeled
debug/review APK delivery; it may not be rewritten as PASS. Cloud synchronization may
remain PENDING after a verified DriveFS copy and must be reported separately.

This checkpoint itself is planning evidence only. It does not claim an APK exists,
AdMob initialized, a device was attached, a build was signed/audited, Drive was
written, or cloud synchronization completed.
