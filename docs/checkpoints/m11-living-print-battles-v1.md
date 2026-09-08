# PrintForge M11 living-print battles checkpoint v1

Status: **AUTHORIZED design; battle art delta requires reviewed atlas and user
approval before runtime promotion; implementation and evidence pending**

Date: 2026-09-08

Authority: `docs/design/printforge-legends-mechanics-v3.1.md` (document title
mechanics v3.2), `docs/design/printforge-screen-first-gameplay-v1.md`,
`docs/design/m10-gameplay-proposals-v1.md`, and the user's 2026-09-08 approval:
“Do it. Also during battle theres no print animations. And battles need to look less
like cards and more like creatures in 3d.”

## Outcome and boundaries

M11 makes the approved Plan -> Run Cycle battle understandable and finite: 200-HP
printers, a readable next-cycle forecast, visible printing, automatic creature
deployment, one post-print equipment choice, living animated print creatures, deck
assistance, and a guided first bot battle. Deterministic integer authority remains the
source of every result.

- Portrait only; no landscape duplicate. No ads, ad SDK/configuration, or reserved ad
  strip.
- Whimsical animal and fantasy-creature identity only; no humans, mechs, tavern, or
  generic tactical card-holder field.
- Reuse the approved character sprite sheets, exact card back, printer/Workshop visual
  family, blueprint grammar, and all unaffected atlas material.
- Cards remain the player's hand/blueprints and rival concealment language. Once a
  creature prints, the battlefield representation is one living animated 2D sprite
  styled as an awakened 3D print, not a card standing in a slot. No sprite-plane 3D
  model is claimed.
- The less-cardboard battlefield and printer-animation delta needs a bounded
  text-free portrait battle-atlas supplement, read-only UI review with no P0, and user
  approval of that exact supplement before any new generated runtime art is promoted.
  The approved full-game atlas and unaffected battle surfaces remain in force and do
  not require reapproval. Dynamic text, HP, progress, targets, focus, accessibility,
  and state remain native Godot.
- Existing ownership, printable licenses, models, rewards, receipts, catalogs, and
  profile saves are preserved. M11 may version transient battle snapshots only as
  specified below.

## M11-01 — 200-HP printer scale

- **Entry:** A new unified battle is constructed, or a supported legacy unified battle
  snapshot is resumed.
- **Player decision:** None beyond existing battle entry and checked Plan actions.
- **Result:** Both printers start at 200/200 HP. Reinforced Chassis adds 50 maximum and
  current HP. Exposed-printer hits use unchanged normal integer damage; the unfinished
  x10 multiplier is not implemented. Creature HP, armor, healing, damage, elements,
  defender-first targeting, and printer-zero victory are unchanged.
- **Failure:** A snapshot with malformed players/printers or an unsupported health
  scale is rejected as a battle-resume error without changing the profile save. It
  never combines 200 HP with x10 damage or silently resets a match.
- **Disabled:** Resume/Run Cycle stays disabled while snapshot validation fails, with
  safe return to Workshop. No creature stat or repair is scaled.
- **Feedback:** Preflight, both HP instruments, Chassis copy, direct-hit receipt, and
  Result show the same exact integers.
- **Progression:** Only existing exactly-once Result settlement changes profile XP,
  coins, quests, or trials.

The actual `v3.1` battle snapshot contains `schema`, `revision`, `seed`,
`starting_seat`, `active_seat`, `turn`, `phase`, `finished`, `winner`, `pending`,
`players`, and `log`; `players` owns each hand, deck, queue, staging, holding, field,
printer, and other battle values. It does not currently serialize a presentation
cursor or a separate RNG state beyond `seed`.

Legacy battle-snapshot adapter: version that existing transient battle schema. For a
supported old snapshot whose printer maximums use the 2,000 scale, convert each printer once:
`new_max = ceil(old_max / 10)` and `new_hp = 0` when old HP is zero, otherwise
`clamp(ceil(old_hp / 10), 1, new_max)`. Thus 2000 -> 200 and Chassis 2500 -> 250 while
preserving positive near-defeat states. Preserve every existing snapshot key and
nested battle value except the explicitly converted printer health and equipment
target fields below; preserve every profile field byte-semantically. Mark the adapted
battle schema so reload never divides twice. Failure retains the original snapshot
and profile; starting a new battle requires explicit player choice.

Legacy queued equipment currently carries a recipient `target` selected before print
and attaches immediately on completion when still compatible. During one-time snapshot
adaptation, keep its card, paid cost, remaining work, FIFO position, and ownership in
the battle, but clear the recipient as an authority choice. On completion it enters
the new Fitting Tray and requests one current compatible recipient. Existing legacy
holding equipment is likewise preserved as held, never discarded, refunded,
duplicated, or silently attached. The old target may be exposed as a nonauthoritative
native hint only; it cannot bypass the new post-print checked choice.

Acceptance: base and Chassis cases, old 2000/2500 snapshots at full/damaged/1/0 HP,
repeat migration, rejection rollback, direct-hit receipts, zero clamp, Result
exactly-once, both openers, legacy queued/held equipment, and the deterministic
30-match matrix all execute without a state-integrity failure. No x10 path or changed
creature trace is present.

The prior matrix range remains the pacing benchmark target: all 30 cases should end at
printer zero within 30 rounds with median 12-22. The health-scale equivalence proves
only exposed direct-hit arithmetic; it does not guarantee full-match AI, queue, field,
or equipment behavior. A case outside the range blocks pacing acceptance and returns
its trace for a separate product decision; it does not authorize fatigue, another
multiplier, HP retuning, or an invented winner.

## M11-02 — Next Cycle forecast

- **Entry:** A settled player Plan is visible after any accepted Main action.
- **Player decision:** Add another legal action, change an allowed plan setting, or
  pull Run Cycle.
- **Result:** A native forecast names FIFO head/remaining work, jobs completing this
  cycle, friendly attack order, and public automatic target priority from the current
  authoritative revision.
- **Failure:** Stale revision, pending receipt, hidden-rival data, or required choice
  makes the forecast unavailable without mutation.
- **Disabled:** Run Cycle shows its existing exact lock reason; forecast is never an
  actionable replacement for checked intents.
- **Feedback:** Each accepted Plan action refreshes only the changed forecast line;
  actual print/attack receipts match it.
- **Progression:** Forecast and highlighting are zero-mutation.

## M11-03 — visible battle printing and living deployment

- **Entry:** Run Cycle advances the FIFO head during Print, including partial work,
  completion, staging, and later deployment.
- **Player decision:** Watch or use presentation-only skip/reduced motion; optionally
  set a queued creature's Attack/Guard stance before its completion lock.
- **Result:** Every authoritative print-work receipt produces a finite chamber sequence:
  empty/blueprint seed, raw solid layers below one scan line, wireframe above it, raw
  completion, awakening, then the existing animated creature walking to the leftmost
  open field anchor. Attack is default; Guard is optional. A full field stages the
  same job until a slot opens. Exactly one living sprite remains.
- **Failure:** Missing art/animation uses a finite native progress/contact fallback,
  logs the failed presentation ID, and acknowledges the existing receipt once. It
  never reruns print authority, stalls the cycle, shows a finished creature throughout
  printing, or creates a duplicate.
- **Disabled:** Plan/hand/Run Cycle are locked during finite playback. Stance locks at
  the completion transaction; first-turn readiness and mode-lock rules still apply.
- **Feedback:** Queue job, printer, scan/progress, awakening, destination anchor,
  creature identity, stance, event rail, and reduced-motion state agree.
- **Progression:** Battle printing creates no collection model, blueprint, XP, coin,
  or Forge receipt. Each accepted battle intent advances authority once.

Acceptance includes partial print, exact 60%, completion, reduced motion, skip,
interruption/re-entry, duplicate card IDs, staged deployment, and back-to-back jobs.
Every job has one ordered visible work/completion/deploy sequence; no authoritative
trace differs with presentation mode.

## M11-04 — post-print equipment fitting

- **Entry:** The player holds legal armor/gem equipment, or its FIFO job completes.
- **Player decision:** Queue it without a recipient; after completion choose one
  highlighted living friendly creature with the matching empty socket.
- **Result:** One accepted choice attaches once and resumes saved print work. If no
  target is eligible, the item remains in a visible Fitting Tray until one exists.
- **Failure:** Target death, occupied socket, stale choice, or reload preserves the
  held item and refreshes eligible targets without refund, replacement, or duplication.
- **Disabled:** Incompatible/rival/filled targets are visibly disabled. New authority
  input remains latched at required decision boundaries.
- **Feedback:** `Print equipment`, `Fitting ready`, compatible socket, selected
  creature, attachment, and held reason remain native and agree with the job ID.
- **Progression:** This changes battle state only; it grants no ownership or model.

## M11-05 — living battlefield composition gate

- **Entry:** Preflight, Plan, printing, deployment, combat, or Result renders.
- **Player decision:** Inspect a hand blueprint, select legal Plan actions/targets,
  mark optional focus, or pull Run Cycle.
- **Result:** Printers visibly frame the battlefield; living creatures occupy the
  largest central readable area with ground contact, breathing/idle motion, stance,
  HP/socket state, and finite attack movement. Hand cards remain a subordinate bottom
  planning rail; rival cards remain concealed. Empty field anchors read as places a
  print can walk into, not upright card holders.
- **Failure:** Cardboard-dominant field, baked dynamic text, duplicate creature art,
  cropped printer/HP, hidden hand/Run Cycle, human/mech imagery, or incoherent print-
  to-awaken continuity blocks art promotion.
- **Disabled:** Noninteractive scenery never owns hit/focus. Illegal targets retain
  native disabled reasons; rival-private cards stay inaccessible.
- **Feedback:** Blueprint-in-hand -> chamber layers -> raw print -> awakening -> one
  living sprite -> attack contact is visually continuous and readable at normal,
  150% text, high contrast, and reduced motion.
- **Progression:** Art, focus, inspection, and animation are zero-mutation.

Required pre-integration battle-atlas supplement states: Plan with both
fields/hands/printers; early and
60% player print; rival print without private identity leak; raw completion; awakening
and step-off; populated living field; creature contact and printer contact; equipment
Fitting Tray; reduced motion/high contrast. Review at 576x1024 and 720x1280. Retain
prompts, dimensions, provenance, hashes, and approval record. Read-only UI review must
report no P0, then the user must approve this exact battle-art delta before promotion.
All unaffected full-game screens and existing approved atlas assets are reused without
a new whole-game art approval.

## M11-06 — deck assistance without migration

- **Entry:** Founder completion or Deck editing with owned known cards.
- **Player decision:** Keep the draft, use Recommended Deck, Fill to 40, inspect the
  proposed diff, confirm Save/Activate, or Back.
- **Result:** Existing legal decks of 40 or more remain legal and unchanged. Fill adds
  owned copies deterministically until the candidate reaches 40; Recommended builds a
  deterministic 40-card candidate. Neither commits before confirmation.
- **Failure:** Insufficient owned copies, unknown card, stale ownership, invalid draft,
  or save failure preserves the active deck and exact profile snapshot.
- **Disabled:** Save/Activate remains disabled below 40 or otherwise illegal; helper
  actions explain why they cannot form a legal candidate.
- **Feedback:** Native `n / 40 minimum`, type counts, exact additions/removals, legality,
  and active-deck receipt are visible.
- **Progression:** Helpers grant no cards, packs, licenses, models, coins, or XP.

Acceptance: zero-card/partial/39/40/>40 drafts, duplicate owned copies, insufficient
ownership, cancel, failed commit, reload, bot launch, and existing >40 save preservation.

## M11-07 — guided first bot battle

- **Entry:** A completed Founder profile begins its first legal bot battle.
- **Player decision:** Follow or dismiss four contextual lessons: choose a card, watch
  its queue, pull Run Cycle, and watch the printed creature awaken and fight.
- **Result:** The tutorial uses the player's real legal deck, seed, checked authority,
  printer timing, AI, Result, and rewards. Advanced mechanics explain themselves only
  on first legal encounter.
- **Failure:** If a suggested action becomes illegal, refresh to one currently legal
  action and explain why; never rewrite hand, queue, RNG, HP, or opponent state.
- **Disabled:** A teaching overlay owns one focus target at a time while preserving
  visible Back/Concede and accessibility for subdued controls.
- **Feedback:** One sentence, one highlighted physical object, and one predicted result
  per lesson; completion persists once so later battles are unguided unless replayed
  from Settings.
- **Progression:** No hidden tutorial grant or alternate reward; existing transactions
  and settlement remain exactly once.

## Delivery and evidence boundary

Implementation may begin only after the M11 battle-atlas supplement and simplified
loop clear the required review/approval gates. The sole runtime writer must keep battle rules/state
separate from UI/presentation and preserve the previous clean profile when any adapter
or commit fails.

Required evidence includes focused deterministic rule/migration/forecast/queue/deck/
tutorial suites; repeated authority-trace equivalence; actual coordinate input; finite
print/awaken/deploy/attack captures at both portrait sizes; 150% text, high contrast,
reduced motion, focus and safe-area checks; no P0/P1 visual finding after integration;
and unchanged M10 Founder/Deck/Back/Forge/save regressions. Legacy retired-art tests
are classified separately rather than rewritten to manufacture a pass.

Android delivery is a later milestone: versioned non-overwriting arm64 portrait APK,
no ads, package/signing/version/launch checks, absence of ad configuration, and local/
DriveFS size plus SHA-256 verification. DriveFS copy and cloud-visible synchronization
are separate claims. Physical-device behavior is not claimed without an attached,
authorized device.

## Explicit non-goals

No x10 printer damage; no base creature/equipment stat rebalance; no fatigue, sudden
death, manual phase buttons, manual per-attacker targeting, 30-card migration, copy
cap, landscape UI, humans/mechs, fake 3D-model claim, persistent Forge inventory,
profile data deletion, silent battle reset, ads, or new art promotion before exact
atlas review and user approval.
