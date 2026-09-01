# PrintForge physical UI M7 blueprint and release-readiness checkpoint v1

Status: decision-complete remaining-work authority; human blueprint-grammar approval,
full family, integration, export, device gate, and Drive delivery pending

Date: 2026-09-01

Baseline: branch `spike/printforge-physical-ui`, HEAD
`f52d4477f659f0800e757514a474f5cffe54bcb1` at checkpoint authoring.

Authority: M1-M6 checkpoints; the committed
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/README.md`;
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-generation-brief-v1.md`;
and the no-AdMob M5 delivery contract. If the implementation commit differs from the
baseline above, every final ledger, capture, APK, README, and Drive filename binds to
the later exact full commit hash.

## Current truth

| Area | Status | Verified evidence or blocker |
| --- | --- | --- |
| M1-M3 physical routes and deterministic rules | Verified at their recorded checkpoints | M1 correction PASS; M3 104/104 image matrix and 52/52 precommit regression are recorded in the existing checkpoint ledgers. |
| M6 bounded visual corrections | Verified for the scoped corrections only | `build/evidence/m6-visual-correction/manifest.json`: 11 Forward+ captures, reserve `0`, dimension/SHA verification; formal UI review reports 0 P0/P1 after the contact P2 recapture. |
| V2 blueprint grammar candidates | Technically verified; human decision pending | Three 1254x1254 alpha pilots and parchment composite are inventoried in the committed v2 README. Alpha and pilot geometry are evidence, not human approval. |
| Complete v2 family | Missing | Only Cinderpaw, Aurorawing, and Worldcoil pilots exist. The remaining 21 identities and a reviewed 24-asset family manifest do not exist. |
| Runtime blueprint family | Blocked on approval/family | V1/v3 imagery is rejected; no reviewed v2 family is authorized for runtime promotion. |
| Rejected runtime package content | Blocking | `assets/creatures/2d/blueprints/` contains 24 tracked rejected v1 card PNGs plus unknown/provenance/import material; directory total is 11,112,054 bytes. Android uses `export_filter="all_resources"`, and the runtime path is not excluded, so unreachable rejected art can enter an APK. |
| No-AdMob source behavior | Focused test verified; package proof pending | M6 records `test_m5_android_no_ad` PASS and reserve `0`; no exact-commit resolved-export/APK audit is yet claimed here. |
| APK/device/Drive | Missing or conditionally blocked | No commit-qualified M7 APK, device result, DriveFS copy, or cloud-visible proof is claimed. Device status remains unknown until `adb devices -l`. |

No later section converts pending, blocked, or missing evidence into PASS without the
named artifact and review.

## Locked invariants

- No gameplay value, catalog identity, save/profile schema, ownership, duplicate,
  legal 40+ deck, three Pre-Print, economy, exactly-three booster, reward, or
  deterministic transaction changes.
- Battle remains Plan -> Run Cycle with authoritative Draw -> Main -> Print -> Attack
  -> Collect ordering. Print, awaken, and attack animations remain present and finite.
- Blueprint is pre-print; solid-below/wireframe-above is active extrusion; existing
  animated creature sprites are awakened field units; rival concealed hands use the
  existing card back. Existing support-card art is not replaced.
- Portrait only, native dynamic text/accessibility, 48/56-logical-pixel targets, 150%
  text, high contrast, reduced motion, safe-area rebuilding, and zero no-ad reserve.
- No AdMob SDK, plugin, identifier, permission, metadata, request path, placeholder,
  creative, or reserved strip.

## Decision-complete remaining work

### Human approval of the v2 blueprint grammar

- **Entry:** Present the three alpha pilots and parchment composite named in the
  committed v2 README at original resolution and at 160 px card scale, alongside the
  approved character references and the rejected-v1 exclusions.
- **Player decision:** The user chooses **Approve grammar**, **Revise grammar**, or
  **Reject grammar**. Approval explicitly covers one intact print-plan creature,
  transparent ink, one build plane, sparse physically connected supports, and one
  scan datum; it does not approve unseen family assets.
- **Result:** Approval creates a dated Markdown approval record naming the four
  reviewed files and SHA-256 hashes, and authorizes full-family generation only.
  Revision records concrete changes and returns to pilot review. Rejection keeps all
  generation and promotion blocked.
- **Failure:** No response, ambiguous preference, omitted original-resolution view,
  alpha failure, baked checkerboard, or mixed approval is not approval and causes no
  mutation.
- **Disabled:** Full-family generation, runtime integration, export qualification,
  and release delivery remain disabled until **Approve grammar** is recorded.
- **Feedback:** The approval surface labels candidates, rejected intermediates, scale,
  transparency result, and exact consequence in native/readable text.
- **Progression:** The decision changes only art-production authority; it grants no
  card, currency, print, deck, reward, profile, or save state.

Acceptance record: `docs/checkpoints/evidence/m7-blueprint-grammar-human-approval.md`.

### Generate and review the complete 24-asset v2 family

- **Entry:** Human grammar approval exists and the committed v2 README/family brief,
  catalog IDs, raw-print references, and sprite sheets are available.
- **Player decision:** None during generation. The user gives final family approval
  only after the read-only visual review has no P0/P1.
- **Result:** Produce exactly one 1254x1254 RGBA master per 24 catalog creatures.
  Default to a clean right-facing side profile; use one shallow three-quarter profile
  only where the family brief's identity guard requires it. Every asset has one intact
  assembled creature, canonical silhouette, one build-plane baseline, one scan datum,
  at most four necessary supports connected bed-to-overhang, transparent warm
  ivory/sepia ink with restrained pale cyan, and no baked paper or text.
- **Failure:** Detached/exploded parts, duplicate views, opaque/checkerboard corners,
  floating supports, missing extremity, identity drift, full-color sprite, robot/human
  redesign, frame/plinth, illegibility at 160 px, wrong dimensions, or missing
  provenance rejects that asset. A rejected asset cannot borrow another creature's
  image.
- **Disabled:** The family is not promotable while any ID is missing, duplicated,
  rejected, hashless, or pending review. Partial-family runtime fallback is forbidden.
- **Feedback:** Retain prompts, identity inputs, tool/provenance, dimensions, alpha
  checks, byte sizes, SHA-256, per-ID findings, 24-up contact sheet, parchment
  composite, and 160 px thumbnail sheet. UI review inspects every master at original
  resolution and the two scale/composition sheets.
- **Progression:** Generation/review changes no runtime mapping or player data. A
  dated user approval of the complete manifest is required before promotion.

Acceptance artifacts:
`docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2/`,
`family-manifest-v2.json`, `SHA256SUMS-v2.txt`,
`family-contact-sheet-v2.png`, `family-thumbnails-160-v2.png`, and
`family-review-v2.md`.

### Retire rejected runtime v1 package inputs

- **Entry:** Before runtime integration/export, inventory and hash all content under
  `assets/creatures/2d/blueprints/`; confirm every historical master worth retaining
  exists under excluded `docs/art/...` with provenance.
- **Player decision:** None; this is package hygiene, not a gameplay choice.
- **Result:** Historical v1/v3 masters remain under `docs/`, which Android excludes.
  The 24 rejected runtime v1 cards, unknown placeholder, their provenance/import
  products, and every rejected filename/byte are removed from runtime export inputs
  or explicitly excluded. The reviewed v2 family occupies a distinct manifest-owned
  runtime path. APK audit finds zero rejected v1 filename, hash, texture, or byte.
- **Failure:** Missing historical retention, an unclassified old file, stale import,
  `all_resources` inclusion, rejected hash in the PCK/APK, or an exclusion that also
  removes reviewed v2 art blocks export.
- **Disabled:** No APK may be called no-ad review/release-ready while the current
  11,112,054-byte rejected directory can be packaged.
- **Feedback:** Retain pre-change inventory/hashes, historical-doc mapping, export
  include/exclude proof, post-change runtime inventory, PCK/APK listing, and rejected-
  hash scan with zero matches.
- **Progression:** Asset retirement changes no ownership, deck, print, battle, reward,
  economy, or save state.

### Bounded reviewed-family runtime integration

- **Entry:** The human-approved 24-asset manifest and runtime-package cleanup are
  complete.
- **Player decision:** Use existing inspect/select/queue/deck/Pre-Print/reward actions;
  no new decision or phase is introduced.
- **Result:** One catalog-to-asset manifest supplies Starter, Archive/detail,
  Deck/Pre-Print, Forge pre-extrusion, player battle hand/queue, and blueprint rewards.
  Native names/values/focus remain above transparent ink on physical paper. Active
  print still becomes raw solid below the scan and wireframe above; completion awakens
  the existing animated sprite, and Run Cycle attack uses the existing animation.
- **Failure:** Missing/malformed mapping shows a noninteractive native placeholder,
  logs the ID, preserves zero-mutation browsing, and blocks release qualification; it
  never crashes, substitutes v1/v3, grants twice, or reveals the rival hand.
- **Disabled:** Illegal ownership/deck/queue/reward actions remain visibly disabled.
  Blueprint art never replaces support art, a rival card back, or an awakened sprite.
- **Feedback:** Physical focus, labels, progress, 60% print split, awakening, attack
  contact, 150% text, high contrast, and reduced motion preserve M1-M6 feedback.
- **Progression:** Existing deterministic transactions and save schema remain byte-
  compatible; browse/focus/error paths are zero-mutation and accepted grants/saves
  remain exactly once.

Acceptance tests: `test_m7_blueprint_family_assets`,
`test_m7_blueprint_runtime_mapping`, `test_m7_blueprint_route_semantics`, plus the
existing M1-M6 deterministic regression suite.

### Post-integration interaction and visual gate

- **Entry:** Integration tests pass from the intended commit with isolated E:-based
  user data and deterministic fixtures.
- **Player decision:** Exercise every existing route/action represented below.
- **Result:** Original-resolution captures prove the reviewed family, physical
  integration, zero-reserve portrait layout, extrusion/awakening/contact sequence,
  and accessibility modes without gameplay drift.
- **Failure:** Wrong art/state, pasted rectangle, label collision, clipped target,
  hidden action, nonfunctional callback, early finished creature, blueprint field
  sprite, animation loss, dimension mismatch, stderr failure, or P0/P1 blocks export.
- **Disabled:** Geometry-only fixtures and generated mockups cannot approve runtime
  art. No capture substitutes for an untested interaction.
- **Feedback:** The manifest records fixture/seed, viewport, safe insets, reserve `0`,
  text scale, contrast, reduced motion, asset SHA, screenshot SHA, and test exit.
- **Progression:** Capture and review fixtures are isolated and zero-mutation.

| Capture ID | Required state | Sizes/mode |
| --- | --- | --- |
| `M7-BP-01-StarterFocus` | Starter focus and inspect; label-safe transparent blueprint | 576x1024, 720x1280 |
| `M7-BP-02-Archive` | Archive grid and creature detail on paper | 576x1024, 720x1280 |
| `M7-BP-03-DeckPrePrint` | Owned/duplicate/legal deck and three Pre-Print seats | 576x1024, 720x1280 |
| `M7-BP-04-ForgePreExtrusion` | Blueprint on empty bed before finished creature exists | 576x1024, 720x1280 |
| `M7-BP-05-ActivePrint60` | Solid below scan, wireframe above | 576x1024, 720x1280 |
| `M7-BP-06-BattleHandQueue` | Player blueprint hand/queue; rival card backs | 576x1024, 720x1280 |
| `M7-BP-07-AwakenContact` | Animated awakened sprite and named contact frame | 576x1024, 720x1280 |
| `M7-BP-08-RewardReceipt` | Blueprint reward with native receipt values | 576x1024, 720x1280 |
| `M7-AX-01-Text150` | Archive plus Deck/Pre-Print at 150% | 576x1024, 720x1280 |
| `M7-AX-02-HighContrast` | Forge 60% plus Battle hand/contact | 576x1024, 720x1280 |
| `M7-AX-03-ReducedMotion` | Held print/awaken/contact semantic frames | 576x1024, 720x1280 |
| `M7-SA-01-SafeArea` | Required actions/focus with nonzero system safe insets and reserve 0 | 576x1024, 720x1280 |
| `M7-TL-01-TallZeroReserve` | Authored bottom, brass printer HUD, 150% focus clearance | 1080x2400 |

Read-only UI review and human reviewed-family approval must both report PASS with no
unresolved P0/P1.

### Clean exact-commit export and no-ad APK audit

- **Entry:** All art/integration/package gates pass and Sol creates one reviewed
  commit. The current concept workspace may remain dirty/untracked.
- **Player decision:** None; export identity is fixed.
- **Result:** Preserve the existing workspace and its untracked/rejected concepts:
  never delete, reset, clean, or stash them for export. Create a separate detached
  clean worktree under
  `E:\AI Projects\games\3d print battler-release-worktrees\m7-<commit12>` at the exact
  reviewed commit. Prove its tracked status clean and HEAD equal, then export there.
  The APK is portrait, `arm64-v8a` only, debug signed, package
  `com.tak.printforge.legends.playtest`, version
  `0.8.5-physical-ui-no-ad-review`, code `101`, with exact existing branding.
- **Failure:** Dirty/mismatched worktree, export from the concept workspace, stale
  relabeled APK, extra ABI, wrong metadata/signing/branding, packaged docs/tests/
  rejected v1 art, or any ad dependency/ID/permission/metadata/class/resource/string/
  request blocks delivery.
- **Disabled:** No AAB, store/release signing, landscape, production package, alternate
  branding, AdMob, or existing-file overwrite is authorized.
- **Feedback:** Retain worktree-add command, exact hash and clean proof, export command,
  tool versions, resolved manifest, dependency/archive listings, signing/metadata/
  ABI/icon reports, rejected-v1 zero-match audit, no-ad scans, APK bytes, and SHA-256.
- **Progression:** Worktree/export/audit cannot read or modify player saves and changes
  no game value.

Required setup command after the reviewed commit exists:

`git worktree add --detach -- "E:\AI Projects\games\3d print battler-release-worktrees\m7-<commit12>" <full-commit-hash>`

Inside that worktree, `git rev-parse HEAD` must equal the reviewed hash and
`git status --porcelain=v1 --untracked-files=all` must be empty before export.

### Conditional device gate and non-overwriting Drive delivery

- **Entry:** Static APK audit passes; then `adb devices -l` determines the device gate.
  Drive delivery begins only after all available required gates pass.
- **Player decision:** If several authorized devices exist, the user selects one.
  Otherwise delivery uses the established studio release folder.
- **Result:** With one selected authorized device, install/launch and representative
  portrait routes/animations pass with no ad strip or ad activity. With no device,
  physical-only checks are `BLOCKED - no adb device`, not PASS. Copy new files to
  `H:\My Drive\AI Projects\PrintForge` as
  `PrintForge-Legends-0.8.5-physical-ui-no-ad-review-arm64-<commit12>.apk` and
  `README-0.8.5-physical-ui-no-ad-review-<commit12>.md` without overwrite.
- **Failure:** Unauthorized/offline device, crash/ANR, wrong portrait geometry, missing
  animations, ad activity, Drive mount/account/path error, collision, copy error,
  byte/hash mismatch, or incomplete README blocks the affected gate.
- **Disabled:** No device claim without a device; no cloud claim from DriveFS copy;
  no existing release deletion, rename, or replacement.
- **Feedback:** Record device PASS/FAIL/BLOCKED truth, local and Drive paths/bytes/
  SHA-256, `DriveFS copy: VERIFIED`, and cloud visibility separately as `CONFIRMED`
  or `PENDING` with its evidence.
- **Progression:** Device data is isolated; delivery changes no profile/save/economy
  state.

## Requirement-to-evidence ledger

| Requirement | Current status | Current evidence | Evidence/command still required |
| --- | --- | --- | --- |
| Human pilot grammar approval | Pending | Committed v2 `README.md` and its four-file manifest | Original-resolution/160 px review plus `docs/checkpoints/evidence/m7-blueprint-grammar-human-approval.md` |
| 24 reviewed v2 assets | Missing | Three technical pilots only | Generate per `family-generation-brief-v1.md`; produce `family-manifest-v2.json`, `SHA256SUMS-v2.txt`, contact/thumbnail sheets, UI review, human approval |
| Rejected v1 excluded from package | Blocking | `assets/creatures/2d/blueprints/`; 11,112,054 bytes; `export_filter="all_resources"` | Preserve hashes/masters under excluded `docs/`; remove/exclude runtime v1; `git ls-files assets/creatures/2d/blueprints`; PCK/APK filename/hash scan must return zero rejected matches |
| Runtime mapping/semantics | Blocked on family | M1-M6 route contracts | Godot 4.7.1 headless: `res://tests/test_m7_blueprint_family_assets.tscn`, `test_m7_blueprint_runtime_mapping.tscn`, `test_m7_blueprint_route_semantics.tscn`; then full `tests/test_*.tscn` ledger |
| Runtime visual gate | Pending | M6 scoped evidence at `build/evidence/m6-visual-correction/manifest.json` | Named M7 matrix under `build/evidence/m7-blueprint-release-readiness/manifest.json`; exact dimensions/SHA; read-only UI review 0 P0/P1; human family approval |
| No-ad source/export boundary | Partial | M6 records `test_m5_android_no_ad` PASS and reserve 0 | Repeat test from exact commit; source/dependency/resolved-manifest scans; zero SDK/plugin/ID/permission/metadata/request paths |
| Clean exact-commit APK | Missing | M5 contract only | `git worktree add --detach` to named E: path; clean/hash proof; Godot Android export; `apksigner verify --verbose --print-certs`; package/version/code/orientation/ABI/archive/icon audits; `Get-FileHash -Algorithm SHA256` |
| Physical device | Unknown/conditional | None | `adb devices -l`; install/launch/log/capture if authorized, otherwise record `BLOCKED - no adb device` |
| H: Drive copy | Missing | Established target only | Non-overwriting `Copy-Item`; source/destination `Get-Item` bytes and `Get-FileHash -Algorithm SHA256`; separate cloud-visible confirmation or `PENDING` |

## Completion boundary

M7 is complete only after human pilot approval, a human-approved and UI-reviewed
24-asset family, rejected-v1 package retirement, bounded runtime integration and full
regression, the named visual matrix, exact-commit no-ad APK audit, truthful conditional
device gate, and non-overwriting H: Drive copy with byte/SHA verification and separate
cloud truth. Until then this document is remaining-work authority, not release
evidence.
