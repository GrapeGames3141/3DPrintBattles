# M9 equipment concept study

Date: 2026-09-04. Branch baseline: `spike/printforge-physical-ui` at `8eac477`.

These are **concept candidates and reviewed alpha derivatives, not runtime assets**.
The first three pilot sources contain an opaque painted checkerboard; newer sources
use flat white. Only files named `alpha` have calibrated RGBA. Sources must not be
described as transparent or used to claim that printable models are complete.

All eleven equipment IDs now have generated completed, raw-orange and coherent
assembled-blueprint source candidates. See [review status](review-status-v1.md)
before selecting a derivative: a filename containing `alpha` means RGBA exists,
not that visual review passed. Several solid material derivatives need exterior-only
remasking because the ink extraction mode also removed their bright highlights.

The [complete image index](image-index.md) exposes every retained source, derivative,
and light/dark/160px proof. The [family brief](family-generation-brief.md) records the
controlled generation rules. Per-source prompt JSON and alpha provenance JSON remain
beside the images. No image alone is evidence of runtime integration or a real model.

## Review images

- [Selected animal-barding direction, v2](standard-barding-completed-concept-v2.png)
- [Initial completed-material study, v1](standard-barding-completed-concept-v1.png)
- [Initial orange raw-print study, v1](standard-barding-raw-concept-v1.png)

The read-only UI reviewer accepted v2 as a human concept-approval candidate. Its
broad connected flank honeycomb, aged-brass edging, attached underbelly straps, and
empty gem socket read as one printed protective shell. It has no wearer, humanoid
anatomy, or detached assembly fragments. The v1 raw study predates that geometry
correction and is **not** the matching final raw derivative.

Human approval of the selected v2 equipment direction was received on 2026-09-04:
the user replied "Approve and approve the art too" to the paired pacing/art approval
requests. Controlled family derivation may proceed. Runtime promotion additionally
requires controlled orthographic derivatives,
machine-verified RGBA transparency, light/dark parchment and small-card review,
catalog mapping, and the M9C model/asset gate. The approved existing creature v2
blueprints and animated battlefield sprites remain unchanged.

## ImageGen provenance

All three candidates were generated using the built-in ImageGen tool. Required
tool-managed C: outputs were copied to this durable E: repository directory. Copy
identity was checked by SHA-256 for the raw study and selected v2 candidate.

### Completed material v1

Identity references: existing PrintForge resource-atlas direction and Cinderpaw's
raw-print art. Brief: one intact creature-fitting protective harness, rounded low
saddle/back shell, short neck collar, connected flank panels, two underbelly straps,
empty round gem socket, navy fused-filament material, aged brass, hexagonal infill.
One three-quarter orthographic-style view, square 1254px, generous margins. No animal
wearer, humanoid limbs, separate pieces, text, paper, or UI. Requested transparent
output was not achieved.

### Raw material v1

Identity reference: completed material v1. Brief: preserve that exact intact shell,
straps, socket, framing, and camera; replace finished materials with one orange raw
fused-filament print, recognizable layer lines, no floating parts or creature wearer.
Requested transparent output was not achieved. This study is retained as provenance,
not as approval of a final raw silhouette.

### Completed material v2

Identity reference: completed material v1. UI-review correction: enlarge the hexagon
construction motif into one broad shallow **mid-flank inset panel**, structurally
connected to the navy shell. Preserve brass perimeter, round empty socket, short
collar, rounded low saddle, protective flanks, and two attached underbelly straps.
Recognizable at card scale; no dog-coat simplification, wearer, limbs, helmet,
detached pieces, duplicates, text, paper, or UI. Requested actual alpha and no
checkerboard; generator again returned an opaque checkerboard. Shape/material passed
concept review only.

## Immutable source ledger

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `standard-barding-completed-concept-v1.png` | 1776637 | `75D0C56972C42B0A83CED0BFB91AFF21AE455E0D46F2688BADED6A89CCE8E556` |
| `standard-barding-completed-concept-v2.png` | 1723113 | `8A6DE969B4950E24F7480B2F2D9C32D35E20C54C1DFB9EDA5CE2E095AAAC82B8` |
| `standard-barding-raw-concept-v1.png` | 1709248 | `4170CE021803F779E8C12EC233239195BB13EDFC0A5F7C8332217C97A540AE96` |

M9 gameplay/input implementation is independent of this asset-production gate. No
new equipment or creature GLB is claimed by this concept study.
