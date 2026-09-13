# Android Team prototype delivery checkpoint

Primary plan, 2026-09-12. Packaging is downstream of accepted Match Session, file
adapter and native UI gates. This document does not claim an APK exists or authorize
exporting the historical main scene as the new prototype.

## Build identity

- Branch: `codex/printforge-team-prototype`.
- Next Android version: `0.9.0-team-prototype`, version code `108`.
- Preserve package `com.tak.printforge.legends.playtest` and the configured review
  signing identity so this can update the existing review app without uninstalling.
- Native app label: `PrintForge`. Retain the approved icon and portrait orientation.
- Use custom feature `team_prototype`; normal source launch and packaged main scene
  must both enter the new Team prototype without command-line QA flags.
- Arm64 only, no ads/IAP/network backend integration, no additional ad-area reserve.
- Do not delete/migrate player data to make a smoke test pass. Existing legacy
  collection fields are preserved; prototype Collection and match-ledger authority
  use the accepted separate boundaries.

## Source and export gate

1. Accept deterministic first session, Team3/Kit15, bot Run Cycle, reward/resume,
   Back, startup and file-failure coverage. Accept actual new UI captures through
   the read-only UI reviewer, not historical presenter captures.
2. Review maintainability, commit the exact runtime/assets/export settings, confirm
   tracked source is clean, and use the full source commit for release attribution.
3. Export with the audited exact-identity process harness and E:-isolated cache,
   temp, logs and QA paths. No console wrappers or name-wide process termination.
   If export requires more than one minute, return control for progress checks;
   retain one bounded engine operation rather than restarting unchanged work.
4. Use the existing E: Godot4.7.1 templates, Android SDK build-tools36.1.0 and JDK17.
   Align APK at16KiB with zipalign, then sign with the configured review identity.
   Read signing configuration privately; never print or commit credentials.
5. Independently inspect manifest/version/package/portrait/launcher, arm64 libraries,
   compiled new main scene and Team runtime resources, all24 directional creature
   sources (including Voltwig2x1), approved armor and promoted Team/Battle masters.
   Reference atlases, docs, tests, build evidence and rejected art must stay out.
6. Verify signing certificate, alignment, source commit and APK byte count/SHA-256.
   Check task-owned process/window cleanup. Do not claim physical-device validation
   from an APK archive inspection or a desktop capture.

## Delivery

Observed release destination on2026-09-12:
`H:\My Drive\AI Projects\PrintForge` (mounted Google DriveFS studio layout).
Most recent observed build remains0.8.11/code107 until this checkpoint completes.

- Durable local APK: `build/android/PrintForge-Legends-0.9.0-team-prototype-arm64-<commit12>.apk`.
- Beside it, `README-0.9.0-team-prototype-<commit12>.md` with exact version/source,
  install/update route, short first-session/battle controls, tested evidence and
  explicit physical-device limitations. Include byte count and SHA-256.
- Refuse existing filenames locally and on Drive; do not overwrite an older release.
- Use the DriveFS delivery skill's deterministic copier with the exact filenames,
  verify destination length and SHA-256, and deliver the README beside the APK.
- Separately confirm cloud-visible filenames when a suitable read-only connection
  exists; otherwise report **DriveFS copy verified; cloud synchronization pending**.
- Push final accepted source to the verified private repository branch and verify
  the remote commit. Local commit, remote push, local APK and Drive sync are distinct.

No physical Android device was connected at the readiness check. A review delivery
may accurately state that limitation; do not uninstall, clear app data or erase
device logs to manufacture a clean-install result.

## Verified binary launch-path audit seam

Primary read the existing0.8.11 APK's `assets/project.binary` directly, without
launching it or extracting player data. It is an `ECFG` envelope:4-byte magic,
little-endian u32 property count, then each property's u32 UTF-8 key byte length,
key bytes, u32 Variant byte length, Variant bytes. String Variant type is4, followed
by u32 UTF-8 byte length and padded string bytes. Validate every bound/type and
complete consumption; do not search arbitrary binary strings for apparent success.

The historical APK decoded `application/run/main_scene=res://scenes/main.tscn`
and `_custom_features=unified_playtest`. The new APK must independently decode
`application/run/main_scene=res://scenes/team_prototype.tscn` and contain
`team_prototype` (not `unified_playtest`) in its comma-separated custom features.
Checking that a new scene merely exists in the ZIP is insufficient to prove launch.
Reuse this small read-only parser in the final audit with explicit size bounds.
