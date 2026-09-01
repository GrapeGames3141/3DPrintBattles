# Creature Blueprint V2 Pilot

Status: preproduction pilot; not yet promoted to runtime.

Human approval remains required before this grammar is expanded beyond the three
identity pilots or promoted into any runtime route.

## Goal

Replace the rejected exploded-part blueprint language with one coherent print plan per
creature. Each plan shows exactly one intact creature, a print-bed baseline, one
horizontal scan datum, and only physically connected support columns where a real
overhang requires them. Dynamic labels and values remain native Godot controls.

## Review set

- `cinderpaw-orthographic-printplan-alpha-pilot-v2.png`
- `aurorawing-orthographic-printplan-alpha-pilot-v1.png`
- `worldcoil-orthographic-printplan-alpha-pilot-v1.png`
- `blueprint-pilot-parchment-composite-v1.png`

The three subjects prove quadruped, winged, and coiled silhouettes before the visual
grammar is scaled to the complete 24-creature catalog.

## Selected pilot manifest

| Asset | Dimensions | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `cinderpaw-orthographic-printplan-alpha-pilot-v2.png` | 1254x1254 | 1,250,701 | `B5AF9C33B03BA4EEB148C076E367143401BE70E02E033259514B1F854FEFE597` |
| `aurorawing-orthographic-printplan-alpha-pilot-v1.png` | 1254x1254 | 1,293,717 | `7D6416875217EFBC7E9316EEF6E7BD0E1576C83DFAD2A342BF9CD3E95F4356B5` |
| `worldcoil-orthographic-printplan-alpha-pilot-v1.png` | 1254x1254 | 1,616,370 | `D69A072F14BC614A0BCBB6034F049B8B3AA3539EB20027BDCE5DD40C6F5FE51F` |
| `blueprint-pilot-parchment-composite-v1.png` | 1800x680 | 788,727 | `5BCAD8737E25975BF41D684DD9F0950647F318DD3598648921983C7E66AAFFDC` |

The three alpha masters are `Format32bppArgb` and have alpha `0` at both
machine-tested outer corners. The opaque parchment composite is review evidence, not
a runtime illustration.

## Generation

Tool: built-in ImageGen.

Identity inputs for each pilot:

- `assets/creatures/2d/raw/<id>_raw_print.png`
- `assets/creatures/2d/<id>_sprite_sheet.png`

Shared generation brief:

> Create exactly one complete, intact creature in a clean right-facing side-profile
> print-plan elevation. Preserve canonical identity and fused-filament layer contours.
> Use warm ivory maker-blueprint linework, a restrained pale-cyan scan datum, one
> print-bed baseline, and at most four supports connected from the bed to real
> overhangs. No detached anatomy, exploded parts, duplicate views, random debris,
> text, frame, UI, finished-color render, robot redesign, or figurine pedestal.

A second built-in ImageGen background-extraction pass removed the generator's baked
checkerboard. The selected alpha pilots are RGBA PNGs with machine-verified transparent
corner pixels. The parchment composite is a deterministic review image that proves the
underlying paper remains visible through and around the ink.

## Rejected intermediates

The non-alpha `*-pilot-v1.png` files and the landscape
`cinderpaw-orthographic-printplan-alpha-pilot-v1.png` are retained only as generation
history. They are not runtime candidates.

The later `cinderpaw-orthographic-printplan-pilot-v3.png` and
`cinderpaw-orthographic-printplan-pilot-v4.png` experiments removed the cyan scan
datum, but ImageGen flattened a visible checkerboard into opaque RGB pixels. They are
also rejected: no creature illustration may be promoted unless the actual outer alpha
is machine-verified transparent. The reviewed alpha pilots listed above remain the
only human-approval candidates.

## User-feedback contract

- Exactly one complete, intact creature per asset.
- No exploded components, detached anatomy, duplicate assembled figure, callout
  fragments, or decorative debris.
- Blueprint linework must remain recognizable at card scale and integrate directly
  with the archive parchment instead of appearing as a rectangular image pasted over
  the page.
- A visually transparent checkerboard is not transparency; runtime candidates require
  real RGBA alpha.
