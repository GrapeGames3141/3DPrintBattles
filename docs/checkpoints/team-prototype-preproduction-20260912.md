# Team prototype preproduction checkpoint — 2026-09-12

Status: **M0 ATLAS COMPLETE, READ-ONLY REVIEW HAS NO P0; AWAITING HUMAN ATLAS APPROVAL. No Godot invocation, runtime edit, runtime-art promotion, runtime test, build, or export is authorized yet.**

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

Defaults are explicit hypotheses in the design, not final balance: filament 5/cap 9,
+2 per later Plan, common cost 3/work 1; four eligible commons; five Support IDs totaling
15 finite copies. M1 is reward-free. M2 provisionally settles Win 30c/40XP,
Loss 10c/20XP, Draw 20c/30XP through exactly-once prototype receipts.

The user's “12–2” pacing wording remains unresolved. The historical 12–22/maximum 30
proposal is not an acceptance threshold. Never add fatigue, a damage ramp, timeout,
forced Draw, or printer damage to manufacture completion.

## M0 finite acceptance and current evidence

These are **offline HTML compositions over ImageGen masters**, not Godot captures,
interactive gameplay, tested Android Back behavior, or physical-device evidence.
Every dynamic name/value/state/label remains separate from art.

| Required family | Current evidence and result |
|---|---|
| Starter choice/Inspect and voucher/empty/early/60%/raw/awaken | v24b current three-size captures; earlier v4/v18 reviews and final delta review: no P0 |
| All three guaranteed starter receipts | v25, 9/9 static checks; Continue / To Team is inside paper, correct mappings and route: no P0 |
| Team empty/one/duplicate/ready and saved-versus-draft values | v24b current three-size captures; v6/v19 plus final review: no P0 |
| Kit 15, excluded reason, Apply/Cancel/Reset | v24b current three-size captures; exact valid/excluded tallies and unchanged saved values: no P0 |
| Workshop, preflight error, recovery, focus, reduced-motion setting | v24b current three-size captures; v7 and final review: no P0 |
| All 35 battle/result states, including finite hand, atomic rejection, FIFO/gear, swaps, replacement, replenishment and Draw | v24b current three-size captures; v12/v15 and final delta review: no P0 |
| Uniform portrait/synthetic-safe-top fit | v24b 174/174 static checks; replace its nine receipt images with v25; 58 current normal states at three sizes |
| Representative 150%/HC/RM battle | v23c Combined/Swap (six images) plus v26b Print60 (three images); exact native font/ink/owner checks and final read-only review: no P0 |
| Indexed atlas and maintenance audit | 183 selected images linked in INDEX; legacy authoring JS removed, scope/export/startup audits recorded; ready for the single human approval |

Every normal composition must be captured at 576×1024, 720×1280, and 720×1600.
Tall uses uniform 941×1672 stage fit with a synthetic 24px top inset and inert aspect
letterbox; it is **not an ad reserve** and does not establish one-handed reach or real
notch behavior. The representative large-text set must show all Team records, a
four-card Plan, forecast/confirmation, Ready reserves, and in-printer work without
clipping. Back and Run are included in the 24px-at-576/30px-at-720 native font checks.
Print60 uses job marker 1 on each roof, with full names/progress in its sidebar,
queues and aria; the disabled lever says Run / Wait inside its actual ink plate.

M0 approves screen composition, not complete application accessibility. The
route-by-route native Godot 150% reflow, Android Back, animation equivalence, safe-area
changes, input, and touch comfort remain mandatory M3 implementation checks. Do not
mark unhandled offline routes as large text or manufacture flags without actual reflow.
The broader authoring geometry suggestions in REVIEW.md are retained implementation
briefs, not additional M0 screen-generation rounds.

All touch owners remain at least 48 logical pixels and primary owners at least 56 at
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
- Full current three-size normal registry: **PASS, 58 × 3 selected captures**.
- Representative 150%/HC/RM family: **PASS, 3 × 3 selected captures**.
- Final full-atlas read-only UI review: **PASS, no remaining reviewed P0**.
- Human approval of this new full atlas: **PENDING**.
- Godot/runtime/build authorization: **CLOSED**.
- New Android APK or Google Drive release this M0 pass: **NONE**.

A read-only agent review is not human approval. Show the indexed candidate and obtain
the single full-atlas approval before starting M1. Approval must name this current
v24b/v25 + v23c/v26b candidate; historical approvals do not substitute for it.

## M1 — isolated deterministic Battle Core

Implement separate TeamBattle state, rules, bot, coordinator, and explicit eligibility/
cost data; do not rewrite legacy printer-HP constructors. Prove 1v1 then 3v3 using the
same model: atomic Plan/revision rejection, FIFO capacity/work/no carry, finite hand
and discard, simultaneous attacks/traits/Draw, once-only deployment, same-identity
swap, replacement, equipment target/fizzle, no-ready-reserve regeneration path, bot
privacy/legal intents, exactly-once result, and save/reload trace equality.

Prototype selection must branch **before** GameManager legacy initialization can call
`UnifiedRules.ensure`, persist normalization, or apply a review-coin floor. A main-scene
selector is too late. Preserve the existing QA-root guard first. Startup only reads
the existing v3 snapshot; an explicit checked transition creates the additive,
versioned `team_prototype` namespace. Every QA launch, including prebootstrap, supplies
an isolated E-based `--qa-save-root`. Invalid legacy 40-card-deck and old-ownership fixtures
must remain byte-identical. This preproduction pass reads/writes no actual player save.

Run the nine ordered starter-Team pairings × five replicates, seeds 0–44. Report actual
result cycle median/p95/longest, first print/contact, replacements, Support/swap counts,
Draw rate, and terminal causes. A 500-cycle diagnostic stop is a softlock failure, not
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
