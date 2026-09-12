# Team prototype preproduction checkpoint — 2026-09-12

Status: **M0 REVIEW CANDIDATE IN PROGRESS. No Godot invocation, runtime edit, runtime-art promotion, test, build, or export is authorized yet.**

Branch: `codex/printforge-team-prototype`; preserved baseline `d7a4a10`.
Authorities: [solo prototype contract](../design/team-prototype-20260912.md),
[fixture registry](../design/team-prototype-atlas-fixtures-20260912.md),
[screen index](../art/team-prototype-20260912/INDEX.md), and
[review history](../art/team-prototype-20260912/REVIEW.md).

## Locked scope

The latest user contract is the solo portrait-Android tactile navy/brass/wood Workshop:
animal/fantasy printed figurines, no humans/mechs/space theme, no ads/IAP, networking,
PC/Steam work, or math minigames. Preserve historical code and profile bytes; do not
expose the old 40-card/printer-HP workflow through prototype navigation.

Blueprint license → Workshop Print → exactly three unique printed Team companions →
15-card Support Kit → solo bot battle. Starter selection guarantees its license and
immediate free-print voucher, two named preprinted commons with licenses, and the
complete recommended Kit; no packs, RNG, purchase, or grind gates first play.

Battle has one Active and two Reserve bays per seat, a FIFO of capacity three including
its head, and at most four visible hand cards. Each identity fabricates/deploys once;
swaps move that existing living identity without refabrication. Plan selects at most
one companion fabrication and one Support **or** swap; Run Cycle alone commits the
whole Plan. The cycle resolves automatically. Defeat leaves a Defeated roster record;
only the current FIFO head owns printer-chamber art. Ready-reserve replacement is
automatic. All-three defeated loses; same-beat final defeats draw. Printers have no HP.

Defaults are explicit hypotheses in the design, not final balance: filament 5/cap9,
+2 per later Plan, common cost3/work1; four eligible commons; five Support IDs totaling
15 finite copies. M1 is reward-free. M2 provisionally settles Win30c/40XP,
Loss10c/20XP, Draw20c/30XP through exactly-once prototype receipts.

The user's “12–2” pacing wording remains unresolved. The historical 12–22/maximum30
proposal is not an acceptance threshold. Never add fatigue, a damage ramp, timeout,
forced Draw, or printer damage to manufacture completion.

## M0 finite acceptance and current evidence

These are **offline HTML compositions over ImageGen masters**, not Godot captures,
interactive gameplay, tested Android Back behavior, or physical-device evidence.
Every dynamic name/value/state/label remains separate from art.

| Required family | Current evidence | Remaining M0 check |
|---|---|---|
| Starter selection, Inspect, voucher, empty/early/60%/raw/awaken print | v4 seven-state UI review; v18 all three choices | Full three-size registry regression |
| Exactly-once grant receipt presentation and all three fixed mappings | v18 six choice/receipt checks and no-P0 UI review | Full three-size registry regression |
| Team empty/1-of-3/duplicate-invalid/ready plus saved-versus-draft values | v6 normal family; v19 corrected draft review | Full three-size registry regression |
| Recommended15 Kit, excluded-card reason, Apply/Cancel/Reset | v19 eligible and excluded tallies, unchanged saved Kit, no-P0 review | Full three-size registry regression |
| Workshop navigation, preflight error, recovery, actual focus, reduced-motion setting | v7 five-state normal review | Full three-size registry regression |
| Preflight, first/combined fabrication, support/swap, FIFO/gear, print/awaken/enter, replacement, empty Active/replenish, exhausted hand, Win/Loss/Draw | v12 all35 normal battle/results reviewed; v15 seven input-state assertions close selected-outline P0 | Full three-size registry regression and representative accessibility |
| Uniform portrait fit and synthetic safe top | v20 eight representative screens × three sizes, 24/24 checks and no-P0 scoped UI review | Remaining normal registry |
| 150% text, material high contrast, reduced motion presentation | v22b Combined Plan draft checks; Back/Run scaling gap found | v23 Combined/Swap/60%-print × three sizes plus read-only review |
| Indexed complete atlas and maintenance audit | Current index and review history | Final refresh, targeted commit, single user atlas approval |

Every normal composition must be captured at 576×1024, 720×1280, and 720×1600.
Tall uses uniform 941×1672 stage fit with a synthetic 24px top inset and inert aspect
letterbox; it is **not an ad reserve** and does not establish one-handed reach or real
notch behavior. The representative large-text set must show all Team records, a
four-card Plan, forecast/confirmation, Ready reserves, and in-printer work without
clipping. Back and Run are included in the 24px-at576/30px-at720 native font checks.

M0 approves screen composition, not complete application accessibility. The
route-by-route native Godot 150% reflow, Android Back, animation equivalence, safe-area
changes, input, and touch comfort remain mandatory M3 implementation checks. Do not
mark unhandled offline routes as large text or manufacture flags without actual reflow.
The broader authoring geometry suggestions in REVIEW.md are retained implementation
briefs, not additional M0 screen-generation rounds.

All touch owners remain at least48 logical pixels and primary owners at least56 at
the base size. Preserve native focus, selected/disabled reasons, full accessible card
names/effects, private rival data, and one visible owner per unit/job/control.

The Cinderpaw/Aquafin/Mossmunk fixed battle sequence is not Voltwig-facing evidence.
Voltwig remains in the four-common rules cohort and three-starter grant mappings,
using its explicitly named legacy-art exception in this offline atlas. Before M3
visual sign-off, fix its front/rear battle presentation or obtain a separately explicit
carried interim exception. No new art generation is authorized merely by this note.

## Current approval boundary

- User product/battle-loop authority: **PASS**.
- Decision-complete numeric defaults and deterministic fixtures: **PASS**.
- Normal-size scoped UI reviews: **PASS within the evidence above**.
- Full current three-size normal registry: **PENDING**.
- Representative150/HC/RM family: **PENDING corrections and review**.
- Final full-atlas read-only UI review: **PENDING; no P0 may remain**.
- Human approval of this new full atlas: **PENDING**.
- Godot/runtime/build authorization: **CLOSED**.
- New Android APK or Google Drive release this M0 pass: **NONE**.

A read-only agent review is not human approval. Complete M0, show the indexed
candidate, and obtain the single full-atlas approval before starting M1.

## M1 — isolated deterministic Battle Core

Implement separate TeamBattle state, rules, bot, coordinator, and explicit eligibility/
cost data; do not rewrite legacy printer-HP constructors. Prove 1v1 then3v3 using the
same model: atomic Plan/revision rejection, FIFO capacity/work/no carry, finite hand
and discard, simultaneous attacks/traits/Draw, once-only deployment, same-identity
swap, replacement, equipment target/fizzle, no-ready-reserve regeneration path, bot
privacy/legal intents, exactly-once result, and save/reload trace equality.

Prototype selection must branch **before** GameManager legacy initialization can call
`UnifiedRules.ensure`, persist normalization, or apply a review-coin floor. A main-scene
selector is too late. Preserve the existing QA-root guard first. Startup only reads
the existing v3 snapshot; an explicit checked transition creates the additive,
versioned `team_prototype` namespace. Every QA launch, including prebootstrap, supplies
an isolated E-based `--qa-save-root`. Invalid legacy40-deck and old-ownership fixtures
must remain byte-identical. This preproduction pass reads/writes no actual player save.

Run the nine ordered starter-Team pairings × five replicates, seeds0–44. Report actual
result cycle median/p95/longest, first print/contact, replacements, Support/swap counts,
Draw rate, and terminal causes. A500-cycle diagnostic stop is a softlock failure, not
a match result; pacing stays descriptive until the typo is clarified.

## M2 — Collection Link

Add versioned grant/voucher/print/Team/Kit receipts; all three fixed starter mappings,
complete recommended Kit, top-up idempotence, recovery, Apply/Cancel/Reset, reserve
priority, and Forge-to-Team ownership. Invalid/stale selections make zero mutation.
Preserve legacy ownership/catalog/effects/history; no destructive migration,
automatic import, or permanent loss on defeat. Settle provisional match rewards once.

## M3 — native portrait UI and Android delivery

Integrate only human-approved atlas-derived assets, never composition masters as
dynamic text containers. Validate every route with native values, 150% text, material
high contrast, reduced motion/Skip equivalence, real focus/selected/disabled feedback,
safe-top/bottom changes, Android Back, exactly-once prints, and the full solo loop.
Read-only runtime UI review must have no P0/P1. Complete a maintainability/performance
review at each major milestone; one Terra runtime writer performs accepted fixes and
Sol reviews/stages/commits.

Physical-device performance, touch comfort, lifecycle, notch geometry, and haptics
require actual device evidence, never inferred desktop passes. Verify the no-ad package,
version/signing/arm64/portrait metadata and launch path. Deliver a commit-qualified,
non-overwriting APK/README to the established PrintForge Google Drive folder, verify
local/DriveFS bytes and SHA-256, and report cloud synchronization independently.
