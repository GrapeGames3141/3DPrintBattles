# M11 facing-integration Android delivery — 2026-09-10

Status: **Final-source APK export, audit, compiled checks, read-only UI signoff, and
non-overwriting APK/README DriveFS verification pass; cloud synchronization remains
unconfirmed.** The artifact is a playable portrait Android review build containing the
approved 23 new front/rear directional species plus Voltwig's existing legacy
side-view art as the sole named exception. After directly viewing Voltwig, the user
reconfirmed **“Ship the interim build.”** This is not a claim of full-24 directional
art or real-device performance.

## Artifact

- Local APK: `build/android/PrintForge-Legends-0.8.11-facing-integration-arm64-b4fcd709b1c2.apk`
- Local README: `build/android/README-0.8.11-facing-integration-b4fcd709b1c2.md`
- Source: `b4fcd709b1c21dd92ae36ece3ec2418e1794c5e8`
- Bytes: `282461896`
- SHA-256: `9894AC653726AC4E3FB80240C826ECE22E50B634636E71C74F978CE1BC692ADF`
- Package/version/code: `com.tak.printforge.legends.playtest` /
  `0.8.11-facing-integration` / `107`
- ABI/orientation/signature: arm64 / portrait / matches established review key
- Ad contract: no AdMob SDK, plugin, identifier, permission, metadata, or request path

The export ran as PID `110916`; all 9 child processes were cleaned up with no errors
or dialogs.

## Evidence state

- [Full APK audit](../../build/evidence/m11-facing-release-20260910/audit-b4fcd709b1c2/apk-audit.json):
  PASS with zero errors; 482 non-media entries scanned, 15 stock DEX/native entries,
  all 23 directional imports/compiled textures, named legacy Voltwig, and compiled
  cache/stage present.
- Source UI review and regressions: all four visual suites passed read-only review
  without P0/P1, and all six isolated-save primary regressions passed as recorded in
  [the integration checkpoint](m11-facing-integration-20260910.md).
- Corrected source presentation-frame snapshots at progress 0.50 and 0.68 passed with
  caption layer `z32`/outline `2`; they prove rendered frames, not real elapsed timing,
  and their original process PIDs were not retained. The real Release Cycle caption
  lifecycle/timing passed. Links are indexed with the
  integration evidence.
- [Preview image collection](../art/m11-facing-minis-20260910/PENDING-INTEGRATION.md)
  exposes the normal, Voltwig, and tall accessibility captures shown during approval.

Final compiled-package checks all pass with isolated QA roots, exit code 0, clean
process exit, and no unexpected errors/dialogs: roster PID `108028`, normal PID
`41328`, Voltwig p50 PID `75220`, Voltwig p68 PID `121216`, cycle PID `127856`, and
integration PID `122276`. The
[compiled evidence directory](../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/)
contains the complete records. Final compiled 576x1024 normal and both Voltwig
phases/actors pass read-only review with no P0/P1; the inherited P2 rival-status
ellipsis remains. This is a bounded compiled spot-check, not a repeated compiled
576/720/tall matrix.

[Post-test integrity](../../build/evidence/m11-apk-b4fcd709b1c2/post-test-integrity.json)
passes: 673 original runtime entries totaling 252,154,693 bytes and the APK hash remain
unchanged. Catalog probes pass for source PID `123512` and shipped PID `107256`.
The [final process audit](../../build/evidence/m11-facing-release-20260910/final-process-audit-b4fcd709b1c2.json)
records zero Godot and WerFault processes.

The available
passes do not prove all 24 species at every lifecycle beat, the complete fault
cross-product, a full balance/pacing pass, reboot-redesign adoption, or physical-device
performance.

## Drive delivery state

Destination: `H:\My Drive\AI Projects\PrintForge`.

The non-overwriting APK DriveFS copy is verified at
`H:\My Drive\AI Projects\PrintForge\PrintForge-Legends-0.8.11-facing-integration-arm64-b4fcd709b1c2.apk`.
Source and destination match at 282,461,896 bytes and SHA-256
`9894AC653726AC4E3FB80240C826ECE22E50B634636E71C74F978CE1BC692ADF`;
see the [APK DriveFS receipt](../../build/evidence/m11-facing-release-20260910/drive-apk-b4fcd709b1c2.json).
The frozen README is independently DriveFS-verified at
`H:\My Drive\AI Projects\PrintForge\README-0.8.11-facing-integration-b4fcd709b1c2.md`:
4,482 bytes and SHA-256
`E5F277A494B164E01010C4DB5B8E97A9BBB2531A17F2DB98002F2D1AAFD02DFD`;
see the [README DriveFS receipt](../../build/evidence/m11-facing-release-20260910/drive-readme-b4fcd709b1c2.json).

Both destination files were copied without overwriting and match their local sources
by byte size and SHA-256. Cloud visibility remains unconfirmed; DriveFS verification
is not cloud-sync proof.

The earlier `1de81e4bb78e` APK and README are superseded diagnostic candidates and
must never be copied to Drive. An old compiled Voltwig contact capture from that
candidate is likewise superseded by the corrected source contact evidence; it is not
current approval evidence.

The desktop save-safety incident and full save snapshots remain ignored local evidence
only. They must not be staged, committed, included in the APK README, or copied to
Google Drive.
