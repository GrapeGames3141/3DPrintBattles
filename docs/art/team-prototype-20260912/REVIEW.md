# M0 review record — solo Team prototype

This is offline HTML/art authoring evidence, **not Godot, runtime, Android, or device
acceptance**. The new full atlas and human approval remain incomplete. Do not promote
art or begin runtime/build work from the bounded passes below.

## Reviewed normal-portrait families

| Evidence | Scope | Read-only UI result |
|---|---|---|
| `captures/v4-starter-forge-576f` | Seven starter/Forge states at 576×1024 | No remaining P0: empty voucher bed, raw layers, front-row contact, aligned nozzle, color only after awakening, native plate ink |
| `captures/v6-team-support` | Six Team/Kit states at 576×1024, final revised captures | No remaining geometry/state/copy P0: selected minis 0/1/3/3, Kit four face previews, saved trio, five-type tally `[3,2,3,3,4]`, truthful Apply/Reset, centered name plates |
| `captures/v7-nav-system` | Five navigation/system states at 576×1024; final ledger finished `2026-09-12T18:13:56.125Z` | No remaining P0 after cream context-label recapture: physical owners, one Back, actual cyan focus, checked reduced-motion dial, contained right-plate labels |
| `captures/v12-battle-verified` | All 35 battle/result states at 576×1024; ledger finished `2026-09-12T19:38:59.893Z` | No remaining composition P0: inward-facing Active minis, six unique roster records, indexed FIFO, raw/wire/awaken continuity, finite hands, automatic replacement, Win/Loss/Draw. Separate selected-control finding below remains until v15. |

V6 and v7 final render ledgers report all bounds, touch, native text, source, and clip
checks passing, and closure/removal of their isolated task-owned Edge profiles. These
folders are retained checkpoint evidence; subsequent work must use new capture labels.

Non-blocking normal-size follow-up: replace the excluded-Kit condensed-font workaround
with the regular font and a wrapped reason on the existing paper during the 150% pass.
Recovery wording can describe recovered Team/Kit values instead of authoring jargon.

## Read-only sprite measurements

The primary reviewer inspected frame 0 in each facing row with Pillow, without
modifying any image. Cells are 384×512. Bounds below use alpha ≥128 and have exclusive
right/bottom coordinates.

| Source identity | Front row 0 alpha bounds | Rear row 1 alpha bounds |
|---|---|---|
| Cinderpaw | `[39,88,329,476]` | `[42,63,340,426]` |
| Aquafin | `[43,70,351,488]` | `[76,40,314,421]` |
| Mossmunk | `[52,99,329,487]` | `[45,62,340,426]` |

Read-only UI review measured battle printer bed contact planes at actual 576-size
`y≈204` (top) and `y≈802` (bottom), centered near `x=100`. For a 72×96 sprite owner:

- Sprite top = bed Y − alpha bottom / 512 × 96.
- Scan Y = bed Y − progress × (alpha bottom − alpha top) / 512 × 96.
- Clip solid below that scan and wire above it, relative to the same sprite owner.

Using the whole transparent cell height as print progress is incorrect: rear-facing
Cinderpaw's first 15% can otherwise display no solid layers. The formulas above are
presentation authoring constraints, not evidence of a running print transaction.

## Equipment material test

`EQ-R1-quadruped-armor-kit-raw-draft-v2.png` is still an unapproved **RGB** ImageGen
draft with a baked checkerboard; it is not a transparent production cutout.

The proposed offline native SVG mask is `alpha = clamp(4R − 4B − 0.1)` in sRGB,
followed by the original SourceGraphic composited into that mask. The negative bias
removes small neutral-background channel noise (measured maximum R−B of 4/255 above
the object). Read-only predicted mask bounds at alpha ≥16 are
`[112,201,1153,1043]` on the 1254×1254 source.

Suggested 576-size gear owners are `(52,125,96,96)` and `(52,723,96,96)`; their raft
lands near y204.85/y802.85. Read-only UI spot-review of the evolving v8 equipment
capture passed the **gear-only** material/contact test: no checkerboard, source box,
halo, or clipped raft; open cavities reveal the chamber; both rafts contact their beds;
the object reads as hollow quadruped equipment, not a living unit. This is not a final
v8 battle-family pass or production-alpha approval. No source image is changed or
promoted by this material test.

The final v8 family passed read-only UI review with larger Active frames (124×165.33
at 576, feet near y380/y566), two-line Ready captions, full target names, indexed FIFO,
and Heated Spool cost 0 / gain 3. The readable reserve-caption wood/brass seam is
non-blocking material polish for the 150% pass. This does not approve the full atlas.

Primary semantic follow-up: C6 auto-replacement must retain **four rival hand backs**,
not three: only the player spent Surge in that cycle. The current three-back preview
is a fixture continuity defect, not permission to leak or discard rival cards. Correct
it with the remaining finite-hand fixtures and retain v8 as historical evidence.

## Remaining M0 work

1. Shared battle geometry and explicit per-seat status records, with no duplicate
   rows, rival pending-Plan leak, false ready occupancy, or creature art for gear jobs.
2. Remaining finite battle fixtures from the registry, including finite hand changes,
   Support versus swap, replenishment, final-member deployment, and terminal causes.
3. Fixed-aspect tall layout, 150% native text, high contrast, reduced motion, and
   corresponding capture coverage; no AdMob reservation.
4. Full-atlas read-only review and maintainability/checker audit, then one human atlas
   approval before Godot/runtime/build work.

The pacing wording `12-2` remains unresolved. No pacing pass threshold or playable
prototype is claimed by this authoring checkpoint.

### Expanded battle review status

`v9-battle-registry` is superseded diagnostic evidence, not an accepted family. Its
35-state render did not prevent reversed scan math or inconsistent input defaults.
Primary review rejected it and sent bounded corrections back to the sole writer.

`v10-corrections` contains thirteen scoped correction captures. Primary self-review
confirms the corrected Cinderpaw print direction and full-color awakening. At 576,
the independently calculated positions are:

| Seat | Sprite owner Y | Scan at 15% | Scan at 60% |
|---|---:|---:|---:|
| Rival/front | 114.75 | 193.0875 | 160.35 |
| Player/rear | 722.125 | 791.790625 | 761.1625 |

The scan rises as progress increases: `bedY - progress * opaqueHeight`. It must not
use `alphaTop + progress * opaqueHeight`, which reveals less raw material over time.
The remaining bounded v11 pass normalizes all fixture defaults, removes obsolete
battle helpers, validates per-seat input ownership and low-filament fabrication
disabling, makes the cyan upper layer visibly striped/transparent, and reruns the
entire registered battle family. Neither v9 nor v10 is a full-atlas approval.

Read-only UI review subsequently cleared v10's thirteen scoped visual/semantic
corrections, with the filled-cyan material and input/default issues explicitly left
for the following passes. V11 added transparent horizontal cyan layers; v12 retained
the control metadata that the factory had previously dropped. Primary inspected the
actual v12 ledger: F2 fabrication is disabled while Run is enabled, Support selection
disables swaps, and a selected swap disables Supports. V12 contains **35** normal
battle/result captures, not 36. The read-only family review is pending.

The maintenance-only v13 follow-up unifies fixture defaults, adds the omitted
combined-Plan fabrication selection, and permits editing a queue-rejected Plan.
The remaining dead JS fixture/helper declarations were removed afterward and the
inline script parsed successfully. Explicit seat/identity/pressed input assertions
are a separate pending v14 check, not completed v13 evidence. No additional art
family or gameplay rule is added by these corrections.

Read-only UI review has now cleared all 35 v12 normal-size battle/result captures
with no remaining visual P0. This is limited to 576x1024 static composition and does
not establish tall-screen, 150% text, native Godot, animation, or device acceptance.

The separate v13 interaction-state review found one additional P0: pending Aquafin
has selected DOM state but no visible selected outline because the reserve-owner
CSS rule is absent. The normal composition review does not waive this finding.
V14 must add and verify the visible selected-owner outline before control sign-off.
Queue-rejection hand editing and locked Run show no additional visual regression.

Closed in **v15-visible-controls**: all seven named-state assertions pass, including
seat, identity, pressed state, disabled state, no rival input, and computed cyan
outline on selected fabrication/reserve owners. Read-only UI spot-review of combined
Plan, swap Plan, and replenishment next-Plan confirms the missing-selection P0 is
resolved without moving or obscuring the physical owners. V14 is superseded by v15.

## Contract audit follow-up

Read-only audit found the core design consistent with the latest user contract: three
unique Team members, fifteen Supports, one Active/two Reserve owners, one fabrication
plus one Support or swap, automatic resolution, team-only defeat, and no ads/network/
Steam expansion. Complete these finite examples on the existing templates:

- All three starter choices and their correct two-preprinted grant mappings. The
  fixed C/A/M battle sequence stays fixed; it is not four-species directional proof.
- Full-FIFO composite rejection with zero spend/append, and exhausted hand/draw pile
  with legal Run still available. Neither introduces a new battle mechanic.
- Saved versus proposed Team/Kit values on the existing folio, including unchanged
  saved values when selection is invalid.
- Before runtime, reconcile defeat feedback to: the creature leaves the field and
  its roster record reads Defeated. Only the FIFO head owns printer-chamber art;
  defeated units must not occupy or replace a working print job.

The existing Voltwig-facing limitation remains an explicit M3 issue, not a reason to
invent a fourth identity in the C/A/M authoring sequence or claim new art approval.

## Corrected 150% reflow contract

These are read-only UI review instructions for the pending pass, not accepted captures.
Coordinates below are actual 576-size acceptance rectangles: convert **once** by
941/576 into the retained logical stage. Keep the stage at 941×1672 with uniform
scaling. Tall 720×1600 places its approximately 720×1280 stage at top 24; do not stretch
the backdrop or reserve banner space.

Use at least 24px text at 576 (30px at 720), approximately 26px/32.5px leading, and
unchanged 48px minimum touch/56px primary owners at the base size. No shrink-to-fit.
High contrast is material scoped: dark ink on paper, cream with dark outline/shadow
on navy and floor. Do not globally blacken native labels, filter all art, or give every
action a focus ring; only the actual focus owner is outlined.

- **Forge:** keep all cleared art/contact/carriage owners and 137×91 bottom plates.
  Arial Bold at 25px measures uppercase CINDERPAW 155px and MOSSMUNK 149px, but title
  case Cinderpaw 127px and Mossmunk 130px. Use title case and three 24/26 lines:
  `Cinderpaw / Printing / 60%`, `Cinderpaw / Raw / complete`,
  `Cinderpaw / Awakened / Continue`, `Voucher / 0 filament / Use`, and the side
  companion name followed by `Already / printed`. Keep complete native aria labels.
- **Starter desk:** shorten visible heading to `CHOOSE BLUEPRINT` and cost to
  `VOUCHER: 0 FILAMENT`; retain current paper, arrows, actions, and native identity.
- **Team:** order on three lines in y362–440; eligibility at most two lines in
  y458–510; status one line y530–558. Preserve minis and name-only brass plates.
- **Kit:** heading y324–354 includes total 15/15; five native tally rows at 26px
  leading in y360–490; one regular-font status/reason block, at most two lines, in
  y506–560. Nothing below paper y≈574. Positive visible shortcut may be
  `Eligible for Solo Battle`, with full card-type eligibility in native aria.
  Four lower card labels use two lines only: short name and ×count. Full names remain
  accessible. Reset keeps its low magazine-band owner; no condensed-font workaround.
- **Battle:** header is one filament line. The left annotation `(14,330,141,230)`
  holds at most eight short 24/26 lines for cycle/phase/math/target. Active captions
  use x184–392, rival y390–442 and player y570–622, two lines: name then Active/HP.
  Reserve mini height is preferably 50px, at most 53px, above a 52px two-line caption;
  feet and shadows cannot enter text. Keep flat full-word Unspent/Queued/Defeated
  records instead of living minis. Use concise queue and hand labels with full aria.
- **Receipt:** wrap native 24px text on existing paper. Grant minis may be 32×43 to
  leave two 24/26 caption lines inside their owners. Preserve return/continue targets.
- **Settings:** context-label area 120×57 supports at most two 24/26 lines in cream;
  the whole hit owner stays unchanged. Body uses at most four short paper-bound lines.
- **Workshop:** preserve Team left oval, Kit right upper, Battle right lower, Forge
  center tabletop, Settings lower round, and Back. Text reflow never remaps routes.

Representative existing states: `combined-second-plan`, `teamvalid`,
`supportkit-excluded`, `guaranteedstarterreceipt`, `starter-choice`,
`starter-print-60`, `preflight-error`, and `workshop-prototype-nav`. Verify all three
sizes, native font scaling and glyph bounds, topmost hit owners, material contrast,
unclipped focus, no sprite/queue masking, fixed stage aspect, and tall safe top 24.

## Final narrow 150% placement decisions

Read-only UI review confirms these actual-576 acceptance rectangles. Keep the
941×1672 stage uniformly scaled; multiply the rectangles once by 941/576.

- Private hand: `(14,220,141,28)`, visible `Rival ×4`, full concealed-hand aria.
- Battle header: `(171,27,234,34)`, only filament math such as `6 → 1 · Next 3`.
  Cycle/phase moves to the first lines of `(14,330,141,230)`, at most eight 24/26 lines.
- Reserve mini boxes: `(252,105,38,50)`, `(440,105,38,50)`,
  `(252,685,38,50)`, `(440,685,38,50)`; alpha feet contact y155/735.
  Caption owners: `(186,158,170,52)`, `(374,158,170,52)`,
  `(186,738,170,52)`, `(374,738,170,52)`.
- Printer names: one line on cream at `(28,72,136,26)` top and
  `(18,648,132,26)` bottom. Top y52 would cross Back. Keep status/progress in
  side annotation and full aria. Interactive docket hit owners stay at least48.
- Hand copy: exactly two short lines, `Raw/+2`, `Heated/+3`, `Suit/2`, `Gem/2`,
  or `Surge/2`; full names/effects remain native aria.
- Receipt tile captions at 150%: `1 Starter / Printed`, `2 Gift / Printed`,
  `3 Gift / Printed`. The main paper body gives the matching ordered full names
  and first-print/preprinted statuses, plus voucher-used/Team-ready copy.
  Do not squeeze full Cinderpaw/Mossmunk names into 100px tile widths at24px.
  All three32×43 minis and physical tile owners remain. Numbers prevent the two
  gifts from depending solely on creature artwork/color for identity.

These are authoring directions, not completed accessibility evidence.

## Read-only startup audit for the later M1 handoff

Source inspection confirms `project.godot` autoloads Catalog, GameManager, and
SaveService. `scripts/core/game_manager.gd::_ready` currently configures QA or v3
paths, loads the profile, then calls `_initialize_loaded_profile`; that function can
create/persist a v3 profile, run `UNIFIED_RULES.ensure`, persist normalization, and
apply the Android review coin floor. A prototype selector in the main scene would
therefore be too late.

The already-planned prototype entry branch must occur in the startup path before that
legacy initializer. Preserve `SaveService.configure_debug_qa_storage_from_command_line`
as the first test-storage guard; its explicit E-based evidence root precedes any
profile load. The prototype branch must not call the legacy initializer or coin floor.
Use existing journal/atomic storage only for later explicit prototype transitions;
do not normalize or rewrite legacy values while deciding which UI to show.

This was source inspection only. No Godot invocation, actual player-save read, runtime
edit, or startup behavior test has occurred in this M0 pass.
