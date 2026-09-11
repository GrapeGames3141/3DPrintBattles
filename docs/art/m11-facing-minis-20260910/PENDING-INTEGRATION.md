# Parked battle-facing runtime integration

Status: parked on 2026-09-10. The default playable stage is restored at base
`65ea60a9a00874aef63c2133bbeb6022ae85b951` because no Voltwig release
exception or approved directional source exists. This is not an APK, export, or
full-roster approval.

The exact reviewed stage diff is
[pending-stage-integration.patch](pending-stage-integration.patch). It was made
from base `65ea60a9a00874aef63c2133bbeb6022ae85b951`; the pre-park stage blob
SHA-1 was `1a87442f39a578f6a37e660c043e677cf3493e6e`, and this patch blob SHA-1
is `c9d79c500b9fefe774aac2e1c37d395e7b7aacb8`.

Do not apply it until a user-approved Voltwig exception or approved Voltwig
directional source resolves the strict full-roster gate. From this clean base,
validate then apply with:

```powershell
git apply --check docs/art/m11-facing-minis-20260910/pending-stage-integration.patch
git apply docs/art/m11-facing-minis-20260910/pending-stage-integration.patch
```

The patch contains only `scripts/ui/physical_battlefield_stage.gd`: approved
front/rear atlas integration through print/deploy/idle/attack, the raw-filament
material path, explicit no-legacy-art fallback messaging, and the reviewed
contact grounding correction. It has no rules, receipt, timing, save, asset, or
release-version change.

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

The final training-viewer evidence proves actor 0 rear/contact frame 7 and actor
1 front/contact frame 3. It does not claim a Voltwig/full-24 release, extra-tall
fixture, device, AdMob, APK, or Drive validation.
