# M11 UI1 Android review delivery — 2026-09-08

## Scope

- Review build for the approved M11 UI1 physical UI polish on the current branch.
- Android version: `0.8.10-physical-ui-polish` (version code `106`).
- Target contract: `com.tak.printforge.legends.playtest`, signed arm64 APK,
  portrait, and no AdMob.
- This is not an M11 completion claim. Pacing acceptance, M11-B2 living-print
  presentation/facing assets, and M11-C remain open.

## Export and delivery checklist

Evidence is pending. The primary agent owns every unchecked item below.

- [ ] Confirm the requested source commit is checked out and has no tracked edits.
- [ ] Export a commit-qualified, non-overwriting APK derived from
  `build/android/PrintForge-Legends-0.8.10-physical-ui-polish-arm64.apk`.
- [ ] Verify package, version/code, signing certificate and v2/v3 schemes, arm64
  only ABI, portrait launch, and absence of advertising configuration.
- [ ] Run the APK-extracted compiled game runtime on desktop and check approved UI1
  controls and the receipt-safe battle path. Physical-device installation is not
  included in this review delivery.
- [ ] Copy a commit-qualified, non-overwriting APK and README to the established
  Google Drive release folder.
- [ ] Compare local and DriveFS byte size and SHA-256, then separately confirm
  cloud-visible synchronization or report it as pending.

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

Records are under `build/evidence/m11-ui1-release-20260908/source-regression/`.
