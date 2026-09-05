# Restore the enclosed steampunk Forge

The user's rejected capture used the wrong scene. The existing code selects the
approved enclosed printer only for starter IDLE, then switches to an old room and
open desktop printer for routine selection and active printing. This is a P0
screen-identity failure, not a high-contrast setting or a mere button-style problem.
The Android review build is held; no replacement runtime is claimed yet.

Read-only source review: **candidate direction PASS, no P0/P1**. Human approval of
this matching derivative family is pending; [review details](review-v1.md) separate
that source gate from alpha/crop registration and actual runtime validation.

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
Runtime crop registration, animation and input evidence are still pending.

## Other M9 art delivered earlier in this work

- [Equipment art collection](../../../build/art-releases/M9-Equipment-Art-20260904-d864c95/README.md)
- [Model depth-study collection](../../../build/art-releases/M9-Model-Depth-Studies-20260904-97b5c41/README.md)

Those two collections have verified DriveFS copies. Cloud synchronization is not
independently confirmed; inferred depth studies are not completed 3D models.
