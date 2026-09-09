# M11 UI1 Android review delivery — 2026-09-08

## Scope

- Review build for the approved M11 UI1 physical UI polish on the current branch.
- Android version: `0.8.10-physical-ui-polish` (version code `106`).
- Target contract: `com.tak.printforge.legends.playtest`, signed arm64 APK,
  portrait, and no AdMob.
- This is not an M11 completion claim. Pacing acceptance, M11-B2 living-print
  presentation/facing assets, and M11-C remain open.

## Export and delivery checklist

Delivered as a scoped UI1 review update; broader M11 acceptance remains open.

- [x] Confirm the requested source commit is checked out and has no tracked edits.
- [x] Export a commit-qualified, non-overwriting APK derived from
  `build/android/PrintForge-Legends-0.8.10-physical-ui-polish-arm64.apk`.
- [x] Verify package, version/code, signing certificate and v2/v3 schemes, arm64
  only ABI, portrait launch metadata, and absence of advertising configuration.
- [x] Run the APK-extracted compiled game runtime on desktop and check approved UI1
  controls and the receipt-safe battle path. Physical-device installation is not
  included in this review delivery.
- [x] Copy a commit-qualified, non-overwriting APK and README to the established
  Google Drive release folder.
- [x] Compare local and DriveFS byte size and SHA-256.
- [ ] Cloud-visible synchronization: unconfirmed; no cloud connector available.

## Source evidence already reviewed

The following source-only checks passed before packaging. They do not validate an
exported APK:

- Authority receipts: PID `102936`.
- Unified cycle: PID `59516`.
- Presentation sequence: PID `118328`.
- Back contract: PID `117060`.
- Main/stage integration: PID `107036`.
- Release Run Cycle scheduling/input proof (headless only, not render evidence):
  PID `114864`.

Source records are under `build/evidence/m11-ui1-release-20260908/source-regression/`;
the headless r4 record is under `writer-validation/release-battle-cycle-r4/`.
The final test rejects headless execution. Primary rendered Forward+ validation
passes at PID `118992`. Rules PID `111336` and manifest PID `117540` also pass.
Save-recovery PID `122572` passes its deliberately malformed-primary/backup checks;
the strict runner flags the expected JSON parse diagnostic from the corruption
fixture. This is classified negative-test evidence, not a globally loosened check.

## Delivered artifact

Source commit: `f699bcbf0a0a0d448316c8d0b8e5e788c2eff58a` (includes UI1 `31f0e2b`).
Only the evidence document is updated after export; runtime source remains exact.

- APK: `PrintForge-Legends-0.8.10-physical-ui-polish-arm64-f699bcbf0a0a.apk`.
- Bytes: `248430069`.
- SHA-256: `0888A70596B1BBF25D350EBC21FD7D50A33C9BD38BBA16C1ED00F6D7A9402D5A`.
- README: `README-0.8.10-physical-ui-polish-f699bcbf0a0a.md`, `5119` bytes.
- README SHA-256: `D51C668DD5A9A578A60CC3AFE55D0A9E15ABAAE2F4921235E545198CB3492E73`.
- Destination: `H:\My Drive\AI Projects\PrintForge`; both files size/hash verified.
- Previous 0.8.9 release retained. No DriveFS restart or cloud-sync claim.

## Compiled-runtime acceptance and cleanup

Export PID `75796` and nine observed worker PIDs exited cleanly. Package, matching
review certificate, v2/v3 signing, 16 KB ZIP alignment, portrait launcher alias,
required runtime art and exclusion/ad scans pass. All 15 DEX/native dependencies
match the stock template. The optional themed-icon warning is unchanged from 0.8.9.

The source and APK-extracted compiled catalog expose all 57 card fronts. Six catalog
and two-size rendered deck-edit/save/activate/reload/bot-opening runs pass: PIDs
`124140`, `123960`, `99420`, `115064`, `123364`, `112144`. The APK's real compiled
runtime is used, not substituted editor scripts. Read-only review finds no new
P0/P1 export regression in Deck and Battle at 576x1024 and 720x1280.

Compiled Forward+ Run Cycle-to-bot-to-player and Main/stage FIFO/contact/replacement
checks pass at PIDs `104236` and `111888`. Initial compiled PID `104804` passed
behavior but was rejected for shader-cache write errors. Shortening only the
isolated OS cache root removes them; no runtime, APK, or error-allowlist change.
Normal animation and reduced-motion completion are tested; no complete-match
performance or new pacing acceptance is claimed. Windows audio uses the dummy driver.

After all checks, all 624 original extracted runtime entries (218137048 bytes) and
the APK remain byte/hash-identical. The four QA-only harness files were added
separately and never overwrite a shipped entry. Final process audit confirms all
32 recorded engine/worker PIDs gone and no error-dialog process. No phone install,
phone save mutation, external window control, or pointer capture was performed.

Evidence root: `build/evidence/m11-ui1-release-20260908/`, including
`audit-f699bcbf0a0a/apk-audit.json`, `apk-f699bcbf0a0a/post-run-integrity.json`,
`drivefs-delivery-f699bcbf0a0a.json`, and `final-process-audit.json`.

Remaining boundaries: actual Android-device acceptance, battle safe-area handling,
facing-inward animation resources, B2 visual/performance completion, pacing, and
M11-C are not closed by this scoped review delivery. Guard-only remains unapproved.
