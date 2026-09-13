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
- Keep `application/config/name="PrintForge Legends"` as the existing Godot
  user-data namespace; change the Android launcher label only. Renaming the project
  without a deliberately approved storage migration would hide existing desktop saves.
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
   Explicitly exclude the legacy humanoid raw suit
   `assets/armor/raw/full_suit_raw_print_alpha_v2.png` and its import/cache payload
   from this prototype APK, while preserving the historical source on disk. Its
   old Catalog entries are string paths, not a dependency of the Team renderer;
   the approved quadruped EQ-R1 is the new runtime equipment source.
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

## Normal-entry smoke boundary

After native Collection/Battle acceptance, the entry task must open the real
`team_prototype.tscn` and construct its Runtime from the configured absolute
SaveService profile path. A non-ready compatibility result or Runtime.open failure
must show the read-only Recovery presenter with Back/Leave, not stay on Loading,
pretend a writable Runtime exists, or rewrite the Store to bypass compatibility.

Extend the audited runner with a normal-entry smoke that omits `--team-prototype`
while retaining isolated `--qa-save-root`. The default project main setting itself
must select read-only prototype autoload startup. Quit after a bounded first-frame
marker without taking any granting action; verify every fixture byte unchanged.
Keep the explicit selector available for older isolated tests.

Cover missing fresh profile, an existing valid Collection, future schema, valid
backup recovery, malformed schema type (string/array/null), zero/negative schema,
and malformed JSON. Validate numeric type/finite/safe-whole bounds before any
legacy integer cast; preserve the accepted absence-of-schema compatibility rather
than silently imposing a new schema rule. Do not reset journals or collection data.

The normal-entry scene must expose the expected initial Starter/Workshop/Recovery
route and a native working Back path. Package inspection and desktop isolated smoke
remain separate from physical Android launch, Back, touch and lifecycle evidence.

## Release tooling readiness (not an export result)

`tools/export_team_android.ps1` accepts one full source commit and refuses dirty
tracked source, old launch/version configuration and an existing APK filename.
It reuses the audited runner's process-identity and save-manifest cleanup through
an inert `library` mode and explicit export-only operation. Export progress yields
every10seconds; the600second operation bound does not change normal test timeouts.
Its final signed candidate still requires independent manifest/signature/resource
audit. Signing secrets are read privately and passed through an ephemeral process
environment variable, not printed or stored in evidence.

`tools/inspect_godot_apk_launch.py` is the bounded read-only ECFG/scene-remap audit.
Its6 parser self-tests passed, and it decoded the historical0.8.11 artifact with
explicit historical expectations, matching its282461896bytes and recorded SHA-256.
The default expectations reject that old main/feature. This is tooling validation,
not evidence that a new APK exists or that an Android device has launched it.

`tools/audit_team_android.ps1` now independently checks manifest/launcher/portrait,
review signing v2/v3,16KiB alignment, ECFG main/feature, compiled directional and
prototype assets, arm64-only/stock native dependencies and absent ad identifiers.
PowerShell parsing passed. A negative run against the historical0.8.11 APK passed
its expected rejection at the old `res://scenes/main.tscn` launch identity; logs are
in `build/evidence/team-release-tooling/20260913-negative-old-apk`. This intentionally
does not produce a passing new-build audit receipt. A new signed candidate is still
required. Scoped elevation was used after sandbox evidence-directory access denied;
no ACL, player save or existing APK was changed.

### Prepared normal-entry runner protocol

Main added `-Suite normal-entry`, not yet executed or included in `all`. It launches
the actual project default with no scene override and **without** `--team-prototype`.
Only isolated `--qa-save-root`, `--team-entry-smoke`, and `--expect-route` are supplied.
The future source-entry implementation must restrict this bounded smoke hook to an
explicit validated QA root; observe the native first frame and Back/Stay with zero
writes, print `TEAM_PROTOTYPE_ENTRY failures=0`, then quit. Existing startup guard
marker and full exact-PID/save-manifest cleanup are still required by the harness.

Fixture directories to add under `tests/team_battle/startup_fixtures` during the
entry task: `entry-valid` (compatible existing Collection), `schema-string`,
`schema-array`, `schema-null`, `schema-zero`, `schema-negative`, `schema-fraction`,
`schema-huge`, `malformed-json`. Reuse existing future-schema/backup-recovered.
The fresh-profile case has no fixture directory. Fresh/valid initially show Workshop;
invalid/recovered show Recovery. None grants, normalizes, repairs or deletes data.
Fixture copies remain outside actual player paths. This protocol is tooling readiness,
not a normal-launch or device pass.

### Primary source review: quiet prototype startup

Before entry edits, note `GameManager._ready` currently calls legacy
`SaveService.load_profile()` before checking the prototype selector. That loader
uses `JSON.parse_string` and treats every empty dictionary as invalid. Both are
wrong for the accepted prototype boundary: malformed JSON must enter Recovery
without engine error output, and an existing literal `{}` is a compatible empty
Collection profile (not a corrupted file merely because it contains no keys).

For the entry task, select the read-only prototype path before that legacy load.
Introduce a narrow quiet load-result path in SaveService (or a small shared startup
reader) using `JSON.new().parse` and explicit missing/valid-Dictionary/invalid
status. Preserve legacy public loading behavior; do not normalize data. Valid
empty Dictionary is valid only by the explicit prototype contract. Recovered
backup remains read-only, not automatic restoration. Validate present top schema
types/bounds before calling legacy ProfileRules.compatibility; no int(Array/null/
nonfinite/huge) casts. The accepted Runtime/Store still validates actual Collection,
ledger and cursor values and owns all later writes.

Add an `entry-empty-profile` fixture containing literal `{}` alongside missing
fresh and existing valid Collection; all initially show Workshop without a write.
Do not bypass Runtime.open failure by creating a fake writable Runtime. Shell may
offer an explicit presentation-only `configure_recovery(reason)` path with the
same physical Back/Leave sheet when opening returns no Runtime object.
