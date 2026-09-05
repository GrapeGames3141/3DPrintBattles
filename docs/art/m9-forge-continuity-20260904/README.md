# Restore the enclosed steampunk Forge

The user's rejected capture used the wrong scene. The previous code selected the
approved enclosed printer only for starter IDLE, then switches to an old room and
open desktop printer for routine selection and active printing. This is a P0
screen-identity failure, not a high-contrast setting or a mere button-style problem.
The approved replacement is now integrated and its narrow Start/60% runtime gate
passes. The Android review build is still held for the full phase/regression review.

Read-only source review: **candidate direction PASS, no P0/P1**. The user
[approved this matching derivative family](approval-20260904.md); [review
details](review-v1.md) separate that source gate from alpha/crop registration and
actual runtime validation, which remain required before delivery.

## Exact approved reference and matching layer candidates

- [Approved enclosed-printer reference](../../../assets/ui/physical_ui/m1-r2/first-print-empty-printer-v2.png)
- [Matching empty enclosure, moving carriage removed](enclosed-forge-static-master-v1.png)
- [Matching independently movable carriage and print head, actual transparent alpha](enclosed-forge-carriage-atlas-source-v1.png)
- [Literal prompts, input, dimensions, hashes and provenance](provenance-v1.json)
- [Route-wide continuity and validation contract](../../checkpoints/evidence/m9-forge-scene-continuity-correction.md)

The same enclosed brass/navy station must remain through setup, printing, raw hold,
awakening, departure, completion, failure, pause and resume. The bed alone contains
the progressively revealed raw print and later existing living sprite. Text, values,
Back, Skip/Start/Return, status and selection stay native in the physical cream
instrument/control faces. M8's narrow scan-adjacent preview is retained; the full
unprinted silhouette must not return.

These source candidates were generated with built-in ImageGen from the existing
approved printer, then copied from its required tool-managed C: output into this
durable E: repository. Source and destination bytes/SHA-256 match. The carriage
atlas has real transparency; dark preview RGB outside the objects has alpha zero.
Runtime crop registration and the narrow actual-Start input/visual gate now pass.
Full phase, accessibility and final release evidence are still pending.

## Durable runtime review images

Selected alpha/registration proofs:

- [Registered enclosure and carriage](../../../build/evidence/m9a-runtime-20260904/forge-continuity-alpha/registered-composite.png)
- [Light alpha proof](../../../build/evidence/m9a-runtime-20260904/forge-continuity-alpha/light-proof.png)
- [Dark alpha proof](../../../build/evidence/m9a-runtime-20260904/forge-continuity-alpha/dark-proof.png)

Current first-gate-v3: root/UI pass the normal 576x1024 Start/60% composition;
this does not approve uncaptured phases, accessibility or physical Android input.

- [Before Start and routine selector](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v3/before-start-576x1024.png)
- [After actual Start](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v3/after-start-576x1024.png)
- [60% progressive print](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v3/print-60-576x1024.png)

Rejected integration history is retained for comparison, not release approval:

- First gate: [before](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate/before-start-576x1024.png), [after](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate/after-start-576x1024.png), [60%](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate/print-60-576x1024.png).
- Second gate: [before](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v2/before-start-576x1024.png), [after](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v2/after-start-576x1024.png), [60%](../../../build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v2/print-60-576x1024.png).

## Other M9 art delivered earlier in this work

- [Equipment art collection](../../../build/art-releases/M9-Equipment-Art-20260904-d864c95/README.md)
- [Model depth-study collection](../../../build/art-releases/M9-Model-Depth-Studies-20260904-97b5c41/README.md)

Those two collections have verified DriveFS copies. Cloud synchronization is not
independently confirmed; inferred depth studies are not completed 3D models.
