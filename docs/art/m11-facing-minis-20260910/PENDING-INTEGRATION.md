# Current battle-facing runtime integration and evidence index

Status: active on 2026-09-10; release validation passes and the APK DriveFS copy is
byte/hash verified. The frozen README DriveFS copy is also byte/hash verified; cloud
synchronization is not confirmed. The user explicitly
approved finishing the build and putting it on Google Drive with the exact
interim contract of new reviewed front/rear sets for 23 species and Voltwig retaining
its existing legacy artwork. All 24 species must remain visible and playable, with no
general fallback, no gameplay change, and no ad change. After directly observing the
Voltwig side profiles, the user reconfirmed: **“Ship the interim build.”** The 23 new
directional species plus named legacy Voltwig integration is now active. Version
`0.8.11-facing-integration` / code `107` is exported from final source
`b4fcd709b1c2` and passes the full static APK audit, all six final compiled checks, and
the bounded compiled 576x1024 read-only UI spot-check. The APK DriveFS copy is
byte/hash verified; cloud synchronization is unconfirmed.
This record is not itself an APK, device proof, cloud proof, or full-24-directional-art
approval.

## Historical park/apply provenance

Before the exception was approved, the default playable stage was restored at base
`65ea60a9a00874aef63c2133bbeb6022ae85b951`. The exact reviewed stage diff remains
preserved for provenance at
[pending-stage-integration.patch](pending-stage-integration.patch). It was made from
that base; the pre-park stage blob SHA-1 was
`1a87442f39a578f6a37e660c043e677cf3493e6e`, and the patch blob SHA-1 is
`c9d79c500b9fefe774aac2e1c37d395e7b7aacb8`.

The historical activation commands were:

```powershell
git apply --check docs/art/m11-facing-minis-20260910/pending-stage-integration.patch
git apply docs/art/m11-facing-minis-20260910/pending-stage-integration.patch
```

The historical patch contains only `scripts/ui/physical_battlefield_stage.gd`: approved
front/rear atlas integration through print/deploy/idle/attack, the raw-filament
material path, explicit no-legacy-art fallback messaging, and the reviewed
contact grounding correction. It has no rules, receipt, timing, save, asset, or
release-version change.

## Current active-integration capture suites

Final read-only UI review passes all four suites—normal 576x1024, normal 720x1280,
Voltwig 576x1024, and tall Voltwig 720x1600 at 150% text/high contrast/reduced
motion—with no P0/P1.

### Normal 576x1024 — read-only pass

[Directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/):
[seat 0 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-seat0-print-576x1024.png),
[seat 0 settled — shown to user](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-seat0-settled-576x1024.png),
[seat 1 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-seat1-print-576x1024.png),
[seat 1 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-seat1-settled-576x1024.png),
[actor 0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-actor0-attack-contact-576x1024.png),
[actor 0 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-actor0-attack-return-576x1024.png),
[actor 1 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-actor1-attack-contact-576x1024.png), and
[actor 1 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-576-2/qa/m11-facing-actor1-attack-return-576x1024.png).

### Normal 720x1280 — read-only pass

[Directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/):
[seat 0 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-seat0-print-720x1280.png),
[seat 0 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-seat0-settled-720x1280.png),
[seat 1 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-seat1-print-720x1280.png),
[seat 1 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-seat1-settled-720x1280.png),
[actor 0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-actor0-attack-contact-720x1280.png),
[actor 0 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-actor0-attack-return-720x1280.png),
[actor 1 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-actor1-attack-contact-720x1280.png), and
[actor 1 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-normal-720-1/qa/m11-facing-actor1-attack-return-720x1280.png).

### Voltwig 576x1024 — read-only pass

[Directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/):
[seat 0 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-seat0-print-576x1024.png),
[seat 0 settled — shown to user](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-seat0-settled-576x1024.png),
[seat 1 print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-seat1-print-576x1024.png),
[seat 1 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-seat1-settled-576x1024.png),
[actor 0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-actor0-attack-contact-576x1024.png),
[actor 0 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-actor0-attack-return-576x1024.png),
[actor 1 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-actor1-attack-contact-576x1024.png), and
[actor 1 return](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-576-1/qa/m11-facing-actor1-attack-return-576x1024.png).

### Voltwig tall 720x1600 accessibility — read-only pass

[Directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-a11y-720x1600-2/qa/):
[seat 0 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-a11y-720x1600-2/qa/m11-facing-seat0-settled-720x1600.png),
[seat 1 settled](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-a11y-720x1600-2/qa/m11-facing-seat1-settled-720x1600.png),
[actor 0 reduced motion](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-a11y-720x1600-2/qa/m11-facing-actor0-attack-reduced-motion-720x1600.png), and
[actor 1 reduced motion](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/interim-voltwig-a11y-720x1600-2/qa/m11-facing-actor1-attack-reduced-motion-720x1600.png).

These bounded suites do not prove an unrun full-all-24/all-beat/fault-cross-product,
physical-device behavior, APK contents, DriveFS copy, or cloud synchronization.

## Current roster and regression evidence

- [Roster `roster-3` stdout](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/roster-3/stdout.log)
  passes all 24 species on both ownership sides at source geometry 1536x1024. An
  earlier failure was caused by the harness's elapsed-frame assumption, not an asset
  defect.
- [Primary isolated-save regression directory](../../../build/evidence/m11-facing-release-20260910/root-validation/)
  records passing cycle PID `120944`, integration PID `114100`, sequence PID `114032`,
  Back PID `120248` (`18/18`), no-ad PID `57944`, and manifest PID `62632`.

These passes close current roster presence/both-seat coverage and the named primary
regressions. They do not claim every species at every lifecycle beat, the full fault
cross-product, physical-device behavior, APK contents, DriveFS copy, or cloud sync.

## Corrected caption and contact-frame evidence

The final source raises the native attack caption above the moving unit at `z32` and
adds outline `2`; no art, combat rule, or receipt behavior changed. Presentation-frame
snapshots at progress 0.50 and 0.68 both pass, and read-only UI review finds no P0/P1.
They prove the rendered frames, not real elapsed timing; the real Release Cycle run
provides timing evidence:

- [p50 directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact50-2/qa/):
  [actor 0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact50-2/qa/m11-facing-actor0-attack-contact-p50-576x1024.png) and
  [actor 1 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact50-2/qa/m11-facing-actor1-attack-contact-p50-576x1024.png)
- [p68 directory](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact68-2/qa/):
  [actor 0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact68-2/qa/m11-facing-actor0-attack-contact-p68-576x1024.png) and
  [actor 1 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/voltwig-contact68-2/qa/m11-facing-actor1-attack-contact-p68-576x1024.png)
- [Real Release Cycle caption lifecycle process](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/caption-release-cycle-1/process.json): PASS

The original source p50/p68 process PIDs were not retained. Final compiled redos below
have complete process records.

## Current Android candidate

- [Final-source README](../../../build/android/README-0.8.11-facing-integration-b4fcd709b1c2.md)
- [Final-source APK](../../../build/android/PrintForge-Legends-0.8.11-facing-integration-arm64-b4fcd709b1c2.apk)
- [Full static APK audit](../../../build/evidence/m11-facing-release-20260910/audit-b4fcd709b1c2/apk-audit.json):
  PASS with zero errors

The APK is 282,461,896 bytes with SHA-256
`9894AC653726AC4E3FB80240C826ECE22E50B634636E71C74F978CE1BC692ADF`.
All six final compiled checks pass with isolated QA roots, exit code 0, clean process
exit, and no unexpected errors/dialogs: roster PID `108028`, normal PID `41328`,
Voltwig p50 PID `75220`, Voltwig p68 PID `121216`, cycle PID `127856`, and integration
PID `122276`. [Complete compiled records](../../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/)
and [post-test integrity](../../../build/evidence/m11-apk-b4fcd709b1c2/post-test-integrity.json)
pass. The final compiled normal and both Voltwig phases/actors pass read-only UI review
at 576x1024 with no P0/P1; inherited P2 rival-status ellipsis remains. The
non-overwriting APK DriveFS copy is byte/hash verified by
[the local receipt](../../../build/evidence/m11-facing-release-20260910/drive-apk-b4fcd709b1c2.json).
[The frozen README DriveFS receipt](../../../build/evidence/m11-facing-release-20260910/drive-readme-b4fcd709b1c2.json)
confirms 4,482 bytes and SHA-256
`E5F277A494B164E01010C4DB5B8E97A9BBB2531A17F2DB98002F2D1AAFD02DFD`.
[Final process audit](../../../build/evidence/m11-facing-release-20260910/final-process-audit-b4fcd709b1c2.json)
records zero Godot and WerFault processes. Cloud synchronization remains unconfirmed;
no physical-device or cloud-sync claim is made.

Accepted final compiled-image evidence includes
[normal seat 0 settled](../../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/normal/qa/m11-facing-seat0-settled-576x1024.png),
[normal actor 0 contact](../../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/normal/qa/m11-facing-actor0-attack-contact-p50-576x1024.png),
[Voltwig actor 0 p50 contact](../../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/voltwig-p50/qa/m11-facing-actor0-attack-contact-p50-576x1024.png), and
[Voltwig actor 0 p68 contact](../../../build/evidence/m11-apk-b4fcd709b1c2/shipped-assets/build/evidence/facing-checks/voltwig-p68/qa/m11-facing-actor0-attack-contact-p68-576x1024.png).

## Process-cleanup correction

The old `raw-filament-shortcache-3` Forward+ parse-failure process pair was
initially left running because non-escalated inspection could not identify its
command line. Escalated CIM later confirmed task ownership; the primary stopped
worker PID `59700` and console PID `61100`, then verified both absent along with
all Godot and WerFault processes. The full durable record is in the adjacent
writer-validation [process ledger](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/process-ledger.md).

## Reviewed provenance and captures

- [Source/provenance collection](README.md)
- [Pyraxis dark composite](cleaned/pyraxis-battle-facing-cleaned-v1-dark-composite.png)
  and [Voidmanta dark composite](cleaned/voidmanta-battle-facing-cleaned-v1-dark-composite.png)
- Final fixed-viewer capture directories:
  [576×1024](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-576-final-1/qa/)
  and [720×1280](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-720-final-1/qa/)
- Final settled examples:
  [576 player print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-576-final-1/qa/m11-facing-seat0-settled-576x1024.png),
  [576 rival print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-576-final-1/qa/m11-facing-seat1-settled-576x1024.png),
  [720 player print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-720-final-1/qa/m11-facing-seat0-settled-720x1280.png),
  and [720 rival print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-720-final-1/qa/m11-facing-seat1-settled-720x1280.png)
- Final real contact examples:
  [576 rear Cinderpaw](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-576-final-1/qa/m11-facing-actor0-attack-contact-576x1024.png),
  [576 front Aquafin](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-576-final-1/qa/m11-facing-actor1-attack-contact-576x1024.png),
  [720 rear Cinderpaw](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-720-final-1/qa/m11-facing-actor0-attack-contact-720x1280.png),
  and [720 front Aquafin](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/train-720-final-1/qa/m11-facing-actor1-attack-contact-720x1280.png)

## Superseded diagnostics

These displayed images remain durable diagnostic evidence, not current approval:

- [Earlier actual Main raw FIFO print](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/actual-main-576-qa/m11-b1-actual-fifo-print60-576x1024.png)
- [Earlier failed settled readback](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/settled-576-qa2/m11-facing-seat0-settled-576x1024.png)
- [Pre-fixed settled capture](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/settled-576-6/qa/m11-facing-seat0-settled-576x1024.png)
  and [pre-fixed actor-0 contact](../../../build/evidence/m11-facing-integration-20260910/writer-validation-dev/settled-576-6/qa/m11-facing-actor0-attack-contact-576x1024.png)
- [The compiled Voltwig contact capture from superseded APK candidate `1de81e4bb78e`](../../../build/evidence/m11-apk-1de81e4bb78e/shipped-assets/build/evidence/facing-checks/voltwig/qa/m11-facing-actor0-attack-contact-576x1024.png)
  sampled the real late pose but used a stale hardcoded frame expectation and exposed
  the caption-layer overlap. It is diagnostic only; it is superseded by the accepted
  p50/p68 source captures above. The old APK and README must never be copied to Drive.

The final training-viewer evidence proves actor 0 rear/contact frame 7 and actor
1 front/contact frame 3. It does not yet prove the approved all-24 interim roster
contract, extra-tall fixture, device, APK, or Drive validation, and it makes no AdMob
or full-24-directional-art claim.
