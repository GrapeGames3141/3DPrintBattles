# Team prototype preproduction checkpoint — 2026-09-12

Status: **DESIGN AUTHORITY COMPLETE; M0 SCREEN ATLAS MISSING, SO GODOT/RUNTIME/ASSET
INTEGRATION, TEST, BUILD, AND EXPORT WORK REMAIN BLOCKED.**

Authority: [solo team prototype](../design/team-prototype-20260912.md).
Preparation baseline: branch `codex/printforge-team-prototype`, commit `d7a4a10`.

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

Design documents and two first-pass masters are complete. The sole Terra writer owns
only the remaining offline HTML atlas and capture production during M0; this does not
authorize Godot, runtime, scene, project-setting, build, or runtime-asset work. Produce
the full screen atlas above, retain masters and
provenance, obtain read-only UI review with no P0, and obtain user approval of the
atlas. Until all are true, no Godot invocation, runtime edit, asset integration, test,
build, or export may begin.

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
- Two first-pass text-free masters: PRESENT, unapproved.
- Full new screen atlas: **INCOMPLETE**.
- Read-only atlas review: **BLOCKED on atlas**.
- User atlas approval: **BLOCKED on atlas**.
- Runtime/build authorization: **BLOCKED**.
