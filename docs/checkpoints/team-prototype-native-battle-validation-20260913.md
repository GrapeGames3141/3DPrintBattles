# Native Team Battle — accepted review checkpoint

2026-09-13. Battle source/design and read-only visual review are accepted. This is
not an Android export or physical-device certificate. Normal-entry integration and
final source regressions are recorded in the
[entry/release checkpoint](team-prototype-entry-release-validation-20260913.md),
including its disclosed Windows native-crash limitation. APK audit is separate.

## Accepted implementation

- The existing Rules, Collection, Match Session and Store remain authoritative.
  No gameplay or save schema changed in this UI slice. The 3-unique-companion Team,
  15-card Support Kit, one Support-or-swap decision, automatic Run Cycle, bilateral
  HOLD, priority replacement and Team-defeat result are preserved.
- One controller owns local canonical inputs, frozen retry IDs and durable receipt
  cursor presentation. The native presenter renders projected values. A passive
  visual and shared Seating projection own figure roots, scale and animation only.
- All four launch companions print as neutral partial layers, awaken, enter and
  fight facing inward. Voltwig uses its approved true front/rear2x1 alpha sheet,
  not mirrored side art. Its two views animate through native movement.
- Equipment uses distinct approved quadruped armor/Gem printer art and native Fit
  status. It does not invent another creature or permanently consume entitlement.
- Swap keeps both canonical identities visible in opposite travel lanes, with
  correct root/size/shadow endpoints. Replace interpolates Ready-to-Active scale.
  Moving captions do not label the wrong creature at its old position.
- Native Back/Cancel, applied-loadout entry, private rival hand counts, real own
  Support faces, checked filament forecast, save Retry and immutable Result reward
  are preserved. No printer-health win condition, manual stage stack or ads added.

## Evidence

Directories below are beneath `build/evidence/team-battle/`.

| Coverage | Evidence directory | Verified result |
| --- | --- | --- |
| Foundation / cursor failure | `20260913-062125-d625205fe62145e4ae56cdfe5b16d8a4` |39 assertions; PID159252|
| Final native interactions | `20260913-065904-1792e38fa12944a3b0fa2d88612f9bec` |32 assertions; PID134888|
| Real Gem/Ready/Swap/Replace + Swap poses | `20260913-065559-6aa1fbaf687645dcbd07c675fd2b2f6e` |26 assertions; PID73884|
| Real low-filament bilateral HOLD | `20260913-060557-d4841aea3e114186a5f661e445da5a4a` |4 assertions; PID156016|
| Real Result Continue pointer/Retry | `20260913-054113-fd9f53414ec94e618a7edfbf165a0732` |12 assertions; PID149020|
| Real Loss / Draw terminal receipts | `20260913-044624-8dda8f1f3a9d43f99eaef42c223e1719` / `20260913-044823-630384a0d88c49a4aa838bb0ba375cd9` |8 each; PID136024 /122604|
| True720x1280 normal lifecycle | `20260913-064643-3db7b5302fff40bd863b4e60a504f930` |12 captures; PID153376|
| Final normal720x1280 progression | `20260913-070847-903924ef30714fea9336a4e1d7f7edc8` |6 captures; PID139776|
| Tall720x1600 progression,150%/HC/RM/insets | `20260913-065628-6f8fb28163f54b1f8b96cb3c3698d61e` |6 captures; PID137060|
| Final tall lifecycle/Plan/modal/paper names | `20260913-070926-115af4d026c74714bd9fd9861829a488` |12 captures; PID137000|

Each passing run has exact selected-case markers, exit0, empty stderr, no task
survivors and unchanged isolated QA fixture bytes. Runtime/controller assertions
are not relabeled as physical pointer or phone tests. Native pointer coverage is
specifically Start/Resume/Open Team, fabrication/Support/target/Cancel/Back/Clear,
Ready swap, Run Retry and Result Continue/Retry. Pose tests use real receipts.

The read-only UI reviewer closed the assigned matrix with no remainingP0/P1 on
the final070847 and070926 corrections. Earlier normal/150 Result and all-four
creature reviews remain valid. Synthetic insets are24/48/24/48, not measured phone
notches. The portrait prototype reserves no AdMob area.

## Audit integrity and maintainability

Two old Battle runs mislabeled576x1024 PNGs as720 variants. Their dimension
acceptance was withdrawn; the capture tool now sizes the actual Window and checks
every Image before saving. Synthetic insets are fitted before capture. The exact
case/creature/nonzero-frame runner guard rejects accidental wrong-case success.
Failed/rejected frames remain evidence, not release screenshots.

Receipt data is copied/cached at boundaries; no per-frame Runtime/JSON/file reads.
Figure atlases and equipment textures are cached, route-owned nodes are removed
before replacement, and no dead manual acknowledgement control remains. Source
review found no new authority leaks, schema mutation, or pointer capture.

See [chronological Battle review and durable image index](team-prototype-native-battle-progress-20260913.md)
for art proofs, rejected iterations and exact corrections, and
[accepted Collection checkpoint](team-prototype-collection-ui-validation-20260913.md)
for the prior469-assertion first-session/Team/Kit/Settings/Forge review.
