# Team prototype preproduction checkpoint — 2026-09-12

Status: **DESIGN AUTHORITY COMPLETE; M0 SCREEN ATLAS IN PROGRESS AND INCOMPLETE, SO GODOT/RUNTIME/ASSET
INTEGRATION, TEST, BUILD, AND EXPORT WORK REMAIN BLOCKED.**

Authority: [solo team prototype](../design/team-prototype-20260912.md) and
[M0 atlas fixture registry](../design/team-prototype-atlas-fixtures-20260912.md).
Current preparation: branch `codex/printforge-team-prototype`; committed rules and
fixtures at `270c8d9` (historical branch baseline `d7a4a10`).

## Current evidence update (supersedes historical coverage status below)

Normal-size read-only UI review now has no remaining P0 in the seven-state
`v4-starter-forge-576f` family, six-state `v6-team-support` family, five-state
`v7-nav-system` family, and all 35 battle/results in `v12-battle-verified`.
V13 corrects selected fabrication and editable rejected-Plan controls. Independent
control assertions, all starter grant variants, saved-versus-proposed editor values,
720/tall/150% material-safe text, and the complete indexed atlas still need closure.
The current evidence and links are maintained in
[the art index](../art/team-prototype-20260912/README.md) and
[review record](../art/team-prototype-20260912/REVIEW.md).

These are offline HTML compositions over ImageGen art, not Godot captures or tested
gameplay. The historical table below records earlier authoring stages; its v3/v5
failures have been superseded by the selected families above. The full-atlas/human
approval gate remains closed. No new Android APK has been built or delivered.

## User authority recorded

The user approved a solo portrait-Android tactile navy/brass/wood Workshop populated
only by animal/fantasy printed figurines—no humans, mechs, or space theme. The approved
loop is Blueprint license -> Workshop Print -> Team of exactly three unique printed
companions -> 15-card Support Kit. First session grants a starter blueprint, immediate
free-print voucher, two named usable preprinted common companions with permanent
licenses, and the full recommended Kit without RNG or grind.

Battle authority is one Active plus two Reserve bays per side, maximum four visible
hand cards, one roster fabrication plus at most one Support **or** swap per Plan,
automatic Run Cycle, once-only fabrication/deployment per roster identity, ready-
reserve priority auto-replacement, roster-defeat Win/Loss/Draw, and small integer
filament with regeneration and forecast. Printers have no HP. Unprinted or printing
survivors are not defeated. A swap moves the same deployed identity and may later
return without refabrication; a defeated identity never returns.

The historical 12–22 / maximum-30 proposal is not current authority while user
clarification is pending. No timeout, fatigue, damage ramp, or end-cap result may be
introduced as a substitute.

The Android prototype entry is selected before any legacy bootstrap and exposes only
the solo Team/Kit workflow. Preserved legacy code/profile data is compatibility and
history, not a second visible battle mode; the old 40-card/printer-HP route is not
reachable from prototype navigation.

## M0 required screen atlas

Two first-pass text-free composition masters are now preserved with hashes and prompt
provenance in [the draft art record](../art/team-prototype-20260912/README.md). They are
not a complete or approved atlas. Before runtime work, complete one coherent portrait
screen family in the existing tactile workshop materials:

| ID | Required screen/state |
|---|---|
| TP-01 | Starter blueprint choice: three animals/fantasy companions, Inspect/Confirm |
| TP-02 | Free starter print: empty bed, voucher review, early/60%, raw, awaken |
| TP-03 | Grant receipt: chosen printed starter plus two named preprinted commons |
| TP-04 | Team setup: empty/1-of-3/duplicate-disabled/ready 3-of-3 and reserve order |
| TP-05 | Support Kit: recommended 15, eligibility/exclusion, Apply/Cancel/Reset |
| TB-01 | Solo preflight: Team, Kit, first fabrication, reserve priority, Back |
| TB-02 | Plan with empty Active: one fabrication, hand four, FIFO/filament forecast |
| TB-03 | Populated battle: one Active/two Reserves for both sides, private rival hand |
| TB-04 | Combined companion+equipment Plan, locked target, two-job FIFO preview |
| TB-05 | Support spell/printer aid versus swap mutually exclusive states |
| TB-06 | Automatic print/awaken/deploy and equipment auto-fit sequence |
| TB-07 | Active defeat, priority auto-replacement, and no-ready-reserve printing wait |
| TB-08 | Legal swap preserving unit identity and equipped/HP state |
| TB-09 | Win, Loss, and simultaneous-final-KO Draw results |
| TS-01 | Empty/error/recovery/disabled/focus/high-contrast/reduced-motion state sheet |

### Finite M0 coverage checklist

These are the coordinated atlas authoring IDs for the required rows above. `Present`
means only that the WIP offline state exists; it is not visual approval or runtime
evidence. `Planned` is the finite remaining M0 set, not a new product feature or
approval gate.

| Required coverage | Coordinated atlas states | Minimum completion shown | Current |
|---|---|---|---|
| Shared Workshop entry/navigation reuse | `workshop-prototype-nav` | One reused Workshop concept exposes only native Team, Support Kit, and Battle routes; Back returns here. Old 40-card, printer-HP, online, and ad routes are inaccessible in prototype navigation. No new title, icon, or Market work. | Source/capture present in `v5-editor-nav-576c`; not visually approved |
| TP-01 starter choice | `starter-choice`, `starter-inspect` | Three approved animal/fantasy blueprints, Inspect, one selected starter, Confirm enabled/disabled. | Both sources present; selected `v4-starter-forge-576f` self-review positive, final UI confirmation pending |
| TP-02 voucher print | `starter-voucher`, `starter-print-early`, `starter-print-60`, `starter-rawcomplete`, `starter-awaken` | Empty bed, one voucher, then early/60/raw/awaken presentation; no premature Team-ready receipt. | All selected states present in `v4-starter-forge-576f`; final UI confirmation pending |
| TP-03 grant receipt | `guaranteedstarterreceipt` | Post-awaken starter Printed, two named preprinted commons, voucher consumed, Kit 15/15, idempotent acknowledgement. | Source present; current recapture/review pending |
| TP-04 Team editor | `team-empty`, `team-one`, `teaminvalid`, `teamvalid` | Exactly empty, one selected, duplicate blocked, and ready 3/3 unique Printed states; first fabrication plus Reserve 1/2 order; native Apply and Cancel. | All sources/captures present; `v5-editor-nav-576c` not visually approved due empty-state art regression |
| TP-05 Kit editor | `supportkit`, `supportkit-excluded` | Native five-entry tally totals exactly 15: Raw Filament x3, Heated Spool x2, Standard Full Suit x3, Iron Gem x3, Forge Surge x4. Show eligible and excluded-card reason plus Apply, Cancel, and Reset; invalid Apply is disabled. Four visible slots totalling 13 never substitute for the central five-entry 15-card tally. | Both sources/captures present; `v5-editor-nav-576c` not visually approved due Kit art/ownership corrections |
| TB-01 preflight | `preflight-empty` | Team/Kit/seed check, first priority, two reserve priorities, native Back, exact invalid reason without mutation. | Present, review pending |
| TB-02 empty-Active Plan | `choosefirstprint`, `activewaiting`, `activewaitingrun`, `activewaiting-nextplan` | Both seats start all three Unspent; required/default fabrication, legal no-cost replenishment Run, next-Plan auto-selection, hand four, FIFO and exact filament forecast. | First/wait states present; next-Plan proof planned |
| TB-03 populated battle | `populatedPlan` | One Active/two ready Reserves per seat, all six native status records, rival hand four hidden, no printer HP. | Present; basic `v1-populated-576f` geometry only passed |
| TB-04 combined Plan | `combined-second-plan`, `second-print`, `third-plan-behind-gear`, `equipment-auto-fit` | Companion then locked-target equipment FIFO, capacity/cost forecast, gear-head art while queued creature has status only, auto-fit without a second commit. | Sources/captures present; battle v3 overlap/overflow/missing-gear corrections pending |
| TB-05 Support or swap | `support-plan`, `swap-plan` | One Support versus one swap as mutually exclusive checked Plans; Run Cycle remains the only commit and invalid composite is atomic. | Planned |
| TB-06 print/deploy sequence | `printEarly`, `print60`, `rawcomplete`, `awaken`, `first-entry-active`, `reserve-1-entry`, `reserve-2-entry` | Early/60/raw/awaken are one Run presentation; first completion becomes Active and later completions enter ordered Reserves. | Sources/captures present; battle v3 distribution corrections pending |
| TB-07 defeat/replacement/wait | `auto-replacement`, `activewaiting`, `activewaitingrun`, `activewaiting-nextplan` | Defeated status without a living bay mini, priority replacement, no-ready-reserve hold, legal replenishment Run, and eventual last-member deployment. | Present except next-Plan source; battle v3 distribution corrections pending |
| TB-08 identity-preserving swap | `swap-plan`, `swap-and-attack`, `swap-result` | Before/Run/after states preserve the same identity, HP, equipment, and once-only fabrication record. | Run state present; Plan/Result planned |
| TB-09 terminal results | `win-result-m2`, `loss-result-m2`, `draw-result-m2` | Team-only terminal cause, simultaneous-final-KO Draw, gameplay disabled, and exact settle-once M2 reward copy. | All sources/captures present; `v3-terminal-results2` geometry/material PASS, corrected Loss-copy recapture pending |
| TS-01 shared states | `team-empty`, `preflight-error`, `recovery`, `focus-sheet`, `HC150-RM`, `reduced-motion` | Empty, exact error with zero mutation, resumable native recovery, native Back, focus/disabled reasons, high contrast plus 150% text, and reduced-motion equivalence. | All sources present; 576 editor captures not visually approved and full 720/tall-150% family incomplete |

The M1 mechanics cohort remains four commons, including Voltwig. The fixed Cinderpaw /
Aquafin / Mossmunk battle fixtures deliberately avoid counting Voltwig as directional
visual evidence because the approved 23-species facing set excludes it. Existing
legacy Voltwig art may remain in the M0 starter carousel. Before M3 visual sign-off,
Voltwig's battle presentation needs the same facing review or a separately explicit
carried interim exception; it must not be silently counted as four-species facing
coverage. No new art generation is authorized by this note.

Checking every row completes state coverage only. The existing full screen-family,
responsive capture, read-only review, and single human atlas-approval gate remain
unchanged; no additional design or approval round is created.

Each composition needs 576x1024, 720x1280, and tall portrait coverage. At least one
tall safe-top fixture and 150% text fixture must show Team, hand four, Plan choices,
forecast, and primary confirmation without clipping or obstructing the one Active/two
Reserve battlefield.

Static scenery/material/framing belongs to the authored plate. Companion identity,
cards, names, counts, filament, queue progress, statuses, forecasts, focus, disabled
reasons, accessibility copy, and every interactive target remain native. Do not bake
dynamic text or populated cards/creatures into masters, and do not draw runtime
duplicates over baked objects. Touch targets are at least 48 logical pixels and primary
actions at least 56.

## Screen interaction contracts

### First session / Workshop

- **Entry:** Ungranted profile or recoverable starter receipt.
- **Player decision:** Inspect/confirm starter, redeem one voucher, then acknowledge
  the two named preprinted commons and recommended Kit.
- **Result:** Empty bed -> print -> awaken -> Team-ready 3/3, without pack RNG.
- **Failure:** Resume exact receipt; never duplicate or erase inventory.
- **Disabled:** Reroll, second voucher, incomplete Team Play, and non-fantasy content.
- **Feedback:** Native entitlement, print, ownership, and receipt status.
- **Progression:** Additive licenses/prints/Kit only; preserve all old profile data.

### Team / Kit

- **Entry:** Three or more distinct printed companions.
- **Player decision:** Select/order three; Apply/Cancel/Reset exact 15-card Kit.
- **Result:** Saved Team 3/3 and Kit 15/15 with clear eligibility.
- **Failure:** Invalid or stale selection is zero-mutation.
- **Disabled:** Duplicate/unprinted companion and incompatible support IDs.
- **Feedback:** Counts, reserve order, exact exclusion reason, before/after preview.
- **Progression:** Preview grants nothing; kit top-up is receipt-idempotent.

### Battle Plan / automatic cycle

- **Entry:** Checked solo preflight and current Plan revision.
- **Player decision:** One roster fabrication plus one Support or swap; press Run Cycle.
- **Result:** Run Cycle is the sole commit: the whole Plan commits or rejects atomically
  and resolves without phase buttons. Equipment queues after companion, target-locks,
  and auto-fits.
- **Failure:** Capacity/cost/target/revision error changes nothing.
- **Disabled:** Over-capacity, second Support, Support+swap, spent/defeated identity.
- **Feedback:** Native two-job FIFO, costs/gains, completion, target, and next-state
  forecast.
- **Progression:** Match-local only until checked terminal settlement.

### Replacement / Result

- **Entry:** Completed damage/trigger beat or legal swap.
- **Player decision:** Preselected reserve priority; optional Plan swap only.
- **Result:** Same-identity swap, ready-reserve auto-replacement, or visible fabrication
  wait; all-three defeated loses, same-beat double third defeat draws.
- **Failure:** Early/duplicate result, refabrication, hidden printer damage, or surviving
  roster with no eventual deploy path fails acceptance.
- **Disabled:** Defeated re-entry, resurrection, printer targeting, post-result input.
- **Feedback:** Active/Reserve/Printing/Defeated motion and explicit terminal cause.
- **Progression:** M1 fixtures remain reward-free. M2 provisionally settles Win 30
  coins/40 XP, Loss 10 coins/20 XP, and Draw 20 coins/30 XP exactly once in the
  prototype-owned ledger through the existing receipt boundary. These tunable values
  add no ad, IAP, or Market redesign and require no separate human approval round.

## Milestones and acceptance gates

### Save-safety architecture gate

Prototype selection must occur before GameManager invokes `UnifiedRules.ensure`.
Startup is read-only against the existing v3 snapshot: no legacy normalization, deck
auto-repair, ownership grant, review-coin floor, auto-import, or destructive migration.
Only an explicit checked user transition may add the versioned `team_prototype`
namespace. Every QA launch, including prebootstrap, supplies `--qa-save-root`; legacy
invalid-40-card-deck and old-ownership fixtures remain byte-identical. This
preproduction pass reads or writes no actual player save, and the shipped APK is
unchanged.

### Bot and pacing evidence gate

The deterministic bot reads the same opening public snapshot plus only its own checked
hand and never peeks at the player's pending Plan. It fabricates the highest-priority
legal unspent member, then chooses at most one Support or swap using the locked order
in the design authority; ties are hand index, roster priority, then card ID.

After 3v3 rules pass, run the specified 45-match, seeds-0–44 ordered starter-Team
matrix. Report actual-result cycle median, p95, and longest alongside contact,
replacement, Support/swap, Draw, and terminal evidence. A 500-cycle diagnostic stop is
a softlock failure, never a forced result. The unsettled 12–2 wording and historical
12–22/maximum-30 proposal provide no current pacing pass threshold.

### M0 — atlas and approval (current)

Design documents and two permanent first-pass masters are present. The
[offline atlas](../art/team-prototype-20260912/atlas.html) and
[capture script](../art/team-prototype-20260912/render-atlas.cjs) exist in progress.
Basic battle geometry was reviewed successfully at `v1-populated-576f`, but this was
not a full-atlas pass or human approval. The superseded
[`v1-canonical-final` folder](../art/team-prototype-20260912/captures/v1-canonical-final/)
is rejected historical diagnostic material, not the current candidate.

The current first-session candidate is `v4-starter-forge-576f`; its selected captures
are [choice](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-choice-576x1024.png),
[inspect](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-inspect-576x1024.png),
[voucher](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-voucher-576x1024.png),
[early](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-print-early-576x1024.png),
[60%](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-print-60-576x1024.png),
[raw complete](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-rawcomplete-576x1024.png),
and [awaken](../art/team-prototype-20260912/captures/v4-starter-forge-576f/starter-awaken-576x1024.png).
All seven have the corrected front row, bed/nozzle, and native ink; main self-review is
positive, while final read-only UI confirmation remains pending.

Terminal `v3-terminal-results2` geometry/material review passed for
[Win](../art/team-prototype-20260912/captures/v3-terminal-results2/win-result-m2-576x1024.png),
[Loss](../art/team-prototype-20260912/captures/v3-terminal-results2/loss-result-m2-576x1024.png),
and [Draw](../art/team-prototype-20260912/captures/v3-terminal-results2/draw-result-m2-576x1024.png).
Loss copy is corrected in source but awaits recapture, so the linked Loss image is not
current-copy approval.

`v5-editor-nav-576c` is not visually approved: native ledger PASS masks an empty
Team/Kit art regression and incorrect Workshop/Settings owners. Battle v3 states have
overlapping duplicate records, overflow, and missing gear; both groups await UI
correction. Source/capture presence is not visual PASS.

Full state coverage, tall and 150% text fixtures, complete read-only visual review,
and human approval remain incomplete. The generated `C:` master intermediates were
removed after fresh size/SHA-256 matches against the permanent committed `E:` masters.
This progress does not authorize or claim Godot, runtime, scene, project-setting,
asset-integration, test, build, or export changes. Until every M0 gate is true, none
may begin.

### M1 — isolated deterministic core, 1v1 -> 3v3

Implement isolated TeamBattle state/rules/bot/coordinator and explicit eligibility/
cost table. State includes support draw pile/hand/discard, FIFO, and filament. M1
eligibility is Cinderpaw 34/7, Aquafin 36/6, Voltwig 30/7, and Mossmunk 31/5 at cost 3
and one work each, with the automatic traits and gear values in the design authority;
all other owned content remains intact but ineligible. Prove atomic Plan, queue
capacity three including active work, one FIFO work/cycle with no carry, same-snapshot
simultaneous damage/Draw, once-only deployment, same-identity swap, replacement, gear
target/fizzle, bot privacy, no printer HP, finite Kit, save/reload trace equality, and
legal deterministic bot. Start with 1v1 authority fixtures, then expand the same model
to 3v3. Prove prototype selection bypasses legacy startup mutation and both legacy
save fixtures remain byte-identical. Validate the locked bot tie policy and descriptive
pacing matrix without exposing a legacy battle route. Do not touch legacy constructors.

### M2 — Forge, Team, Kit, first-session ownership

Implement additive schema-versioned Team/Kit/grant receipts, starter voucher flow,
the fixed two-common mapping, preprinted/license grants, exact recommended Kit, top-up
idempotence, recovery, Team/Kit editing, and Back. Preserve existing catalog/assets/
profile bytes and all historical ownership; no auto-import or destructive migration.

### M3 — portrait UI and Android evidence

Integrate only approved atlas-derived runtime assets. Validate native dynamic content,
576x1024/720x1280/tall portrait, 150% text, high contrast, reduced motion, focus,
safe-top, touch targets, no-AdMob package scan, complete first session, full 3v3 match,
save/reload, and Win/Loss/Draw. Read-only UI review must return no P0/P1. Physical
device performance, touch, safe-area, and haptics require actual device evidence before
claim. Deliver only a commit-qualified non-overwriting APK/README with byte/hash and
DriveFS/cloud status reported separately.

## Current gate result

- User gameplay/product direction: PASS.
- Decision-complete prototype rules and tunable defaults: PASS.
- Portrait-only and active no-AdMob preservation: PASS.
- Two permanent first-pass text-free masters: PRESENT, unapproved; verified `C:`
  intermediates removed after `E:` size/SHA match.
- Offline atlas/capture tooling: PRESENT, in progress.
- Basic `v1-populated-576f` battle geometry review: PASS, bounded only.
- Superseded `v1-canonical-final`: **REJECTED HISTORICAL DIAGNOSTIC**, not current.
- Current first-session `v4-starter-forge-576f`: self-review positive; final UI
  confirmation pending.
- Terminal `v3-terminal-results2`: geometry/material PASS; corrected Loss-copy
  recapture pending.
- Editor/navigation `v5-editor-nav-576c`: ledger/source PRESENT, **NOT VISUALLY
  APPROVED**; Team/Kit regression and Workshop/Settings ownership fixes pending.
- Battle v3: source/captures PRESENT, **NOT VISUALLY APPROVED**; duplicate-record
  overlap, overflow, and missing gear pending.
- Full state, tall, and 150% coverage: **INCOMPLETE**.
- Complete read-only atlas review: **PENDING on incomplete atlas**.
- User atlas approval: **PENDING on incomplete atlas**.
- Runtime/build authorization: **BLOCKED**.
