# PrintForge M11 living-print battles checkpoint v1

Status: **AUTHORIZED implementation. The user approved the exact r7 battle-art
supplement on 2026-09-08 after read-only review passed with no P0/P1; runtime
integration and evidence remain pending.**

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
- The less-cardboard battlefield and printer-animation delta is bounded to the exact
  r7 text-free portrait battle-atlas supplement. Read-only UI review passed with no
  P0/P1 and the user approved that exact supplement on 2026-09-08, authorizing
  controlled promotion of its floor master under M11. The approved full-game atlas
  and unaffected battle surfaces remain in force and do not require reapproval.
  Dynamic text, HP, progress, targets, focus, accessibility, and state remain native
  Godot.
- Existing ownership, printable licenses, models, rewards, receipts, catalogs, and
  profile saves are preserved. M11 may version transient battle snapshots as specified
  below and add one idempotent tutorial-state marker; it renames or deletes no profile
  field and performs no retroactive grant.

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
`clamp(ceil(old_hp / 10), 1, new_max)`. `Reinforced Chassis` has no `unique_key` in
the current catalog, so the existing one-upgrade-per-turn/five-installed cap permits
stacked copies. Validate each player's legacy maximum against the actual count in
`installed_upgrades`: `expected_old_max = 2000 + 500 * chassis_count`, where count
zero through five produces valid old maximums 2000 through 4500. Convert to
`expected_new_max = 200 + 50 * chassis_count`, preserving every installed copy and
never imposing new uniqueness. Preserve positive near-defeat states. Preserve every
existing snapshot key and nested battle value except the explicitly converted printer
health and equipment target fields below; preserve every profile field
byte-semantically. Mark the adapted battle schema so reload never divides twice.
Failure retains the original snapshot and profile; starting a new battle requires
explicit player choice.

Legacy queued equipment currently carries a recipient `target` selected before print
and attaches immediately on completion when still compatible. During one-time snapshot
adaptation, keep its card, paid cost, remaining work, FIFO position, and ownership in
the battle, but clear the recipient as an authority choice. On completion it enters
the new Fitting Tray and requests one current compatible recipient. Existing legacy
holding equipment is likewise preserved as held, never discarded, refunded,
duplicated, or silently attached. The old target may be exposed as a nonauthoritative
native hint only; it cannot bypass the new post-print checked choice.

A supported legacy `pending.kind == "place"` cannot remain as an obsolete manual
choice for either the player or AI. Normalize it inside the one-time snapshot adapter,
before the converted snapshot is exposed for resume: place that same pending unit in
the leftmost open slot in Attack mode, or retain it exactly once in staging if the
field is full. A `from_staging` pending record removes its existing staging source
only when deployed; it never appends a duplicate. Clear the obsolete pending record in
the converted snapshot. This load normalization is not a player/AI intent: it does not
increment the gameplay revision, append an authoritative battle receipt/log entry, or
replay print work, cost, draw, RNG, reward, or presentation. The adapter may return a
separate nonauthoritative migration result for native recovery feedback. Failure
retains the original snapshot and accepts no player/AI input.

Acceptance: base and every legal zero-through-five stacked-Chassis case, old
2000/2500/3000/3500/4000/4500 snapshots at full/damaged/1/0 HP, mismatched maximum
rejection, repeat migration, rejection rollback, player and AI legacy pending-place
resume with open/full fields and `from_staging` true/false, direct-hit receipts, zero
clamp, Result exactly-once, both openers, legacy queued/held equipment, and the
deterministic 30-match matrix all execute without a state-integrity failure. No x10
path, lost/unique-collapsed Chassis, duplicate unit, adapter-caused gameplay revision
or receipt, replayed print, or changed creature trace is present.

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
- **Result:** A native forecast names FIFO head/remaining work, publicly expected jobs
  completing this cycle, friendly attack order, and public automatic target priority
  from the current authoritative revision. Rival queue identities already revealed by
  legal play remain public; rival hand, deck, and hidden trap identities remain private.
- **Failure:** Stale revision, pending receipt, hidden-rival data, or required choice
  makes the forecast unavailable without mutation.
- **Disabled:** Run Cycle shows its existing exact lock reason; forecast is never an
  actionable replacement for checked intents.
- **Feedback:** Each accepted Plan action refreshes only the changed forecast line.
  The forecast is explicitly `expected` because a hidden trap may interrupt a known
  action; the resulting public receipt explains any interruption without revealing the
  trap before its legal trigger.
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

`When a slot opens` is immediate authority timing, not a wait for the staged owner's
next Draw, but the opening is claimed only after the currently accepted attack has
fully resolved. If an enemy Attack destroys a defender, resolve that destruction and
its legal trap receipt, then finish the same attack's gem-on-hit and complete ordered
attack-ability/effect chain with the slot still empty. No remaining damage, status, or
other target effect from that attack may retarget the staged replacement. After that
attack closes, deploy the oldest staged creature into the newly open leftmost slot
before the next attacker resolves. The replenishment can therefore be targeted by
later attackers in the same Attack phase, but it never counterattacks or creates a new
input boundary during the enemy turn. It retains its queued Attack or Guard stance and
remains subject to the existing readiness, first-player-turn, and mode-lock rules when
its owner next receives a legal action. This is the approved automatic `first open
slot` behavior at the next legal action boundary; delaying it until Draw would
reintroduce obsolete manual-placement timing, while deploying inside one attack would
change that attack's established target identity.

Acceptance includes partial print, exact 60%, completion, reduced motion, skip,
interruption/re-entry, duplicate card IDs, staged deployment on both an owner's own
turn and during an enemy Attack, multiple attackers after replenishment, and
back-to-back jobs. Assert FIFO identity, leftmost placement, trap-before-deploy order,
full-attack-before-deploy order, no retarget of a replacement by a killing attack's
remaining ability effects, same-phase targetability by later attackers, no
counterattack, and unchanged readiness/first-turn/lock outcomes. Cover both a base hit
and an early multi-effect ability hit killing the defender. Every job has one ordered
visible work/completion/deploy sequence; no authoritative trace differs with
presentation mode.

## M11-04 — post-print equipment fitting

- **Entry:** The player holds legal armor/gem equipment, or its FIFO job completes.
- **Player decision:** Queue it without a recipient; after completion choose one
  highlighted living friendly creature with the matching empty socket.
- **Result:** One accepted choice attaches once and resumes saved print work. If no
  target is eligible, the item remains in a visible Fitting Tray and Run Cycle
  continues. When an authority change creates a compatible living target, attachment
  becomes the next required-choice boundary after the current presentation; accepting
  it resumes the exact saved print budget.
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
fields/hands/printers; early and 60% player print; public Aquafin rival print with its
already-known queue identity while rival hand/deck/trap remain hidden; raw completion; awakening
and step-off; populated living field; creature contact and printer contact; equipment
Fitting Tray; reduced motion/high contrast. Review at 576x1024 and 720x1280. Retain
prompts, dimensions, provenance, hashes, and approval record. The exact r7 supplement
met these gates on 2026-09-08. All unaffected full-game screens and existing approved
atlas assets are reused without a new whole-game art approval.

### Exact r7 battle-art approval record — 2026-09-08

- **Entry:** The user reviewed the r7 populated-field and 60%-print screens plus the
  portable full 15-state battle index; read-only UI review reported P0 none/P1 none.
- **Player decision:** The user explicitly approved the exact r7 battle-only concept
  atlas shown in chat.
- **Result:** M11 may promote only
  `battle-continuous-floor-master-v1.png` and reproduce the approved r7 composition
  with existing runtime sprites, raw prints, blueprints, card back, and native controls.
  Populated concept composites remain evidence and never ship as backplates.
- **Failure:** A new floor, different material/layout, missing state, baked dynamic
  text, changed creature identity, or broader screen redesign requires fresh review
  and user approval.
- **Disabled:** Unselected earlier revisions and populated screenshots are not runtime
  candidates. The approval authorizes no unrelated atlas or gameplay-art replacement.
- **Feedback:** Preserve the approved continuous floor, public rival print, one-owner
  awakening, launch/landing path, living-field hierarchy, contact poses, equipment
  readiness, and 150%-text clearances.
- **Progression:** Art approval and promotion change no battle, profile, reward, save,
  receipt, or Android delivery state.

## M11-06 — Recommended Deck and Fill to 40 without migration

- **Entry:** Founder completion or Deck editing with owned known cards.
- **Player decision:** Keep the draft, preview Recommended Deck, preview Fill to 40,
  apply or cancel that preview, confirm Save/Activate, or Back.
- **Result:** Existing legal decks of 40 or more remain legal and unchanged. Fill adds
  owned copies deterministically until the candidate reaches 40 and never removes a
  draft card. Recommended builds an optional deterministic 40-card candidate from
  owned copies. Neither preview commits before the existing atomic Save/Activate.
- **Failure:** Insufficient owned copies, unknown card, stale ownership, invalid draft,
  or save failure preserves the active deck and exact profile snapshot.
- **Disabled:** Save/Activate remains disabled below 40, with invalid Pre-Prints, or
  otherwise illegal. Helpers explain when owned copies cannot form a legal candidate.
- **Feedback:** Native `n / 40 minimum`, type counts, exact additions/removals, legality,
  and active-deck receipt are visible.
- **Progression:** Helpers grant no cards, packs, licenses, models, coins, or XP.

Acceptance: zero-card/partial/39/40/>40 drafts, duplicate owned copies, insufficient
ownership, valid and invalid Pre-Prints, helper-preview cancel/apply, dirty-exit
Save/Discard/Cancel, failed commit, reload, bot launch, and existing >40 save
preservation.

## M11-07 — guided first bot battle

- **Entry:** A completed Founder profile begins its first legal bot battle.
- **Player decision:** Follow four contextual lessons—choose a card, watch its queue,
  pull Run Cycle, and watch the printed creature awaken and fight—or explicitly Skip
  Tutorial; Back/Concede retains its existing meaning and does not silently mark the
  tutorial complete.
- **Result:** The tutorial uses the player's real legal deck, seed, checked authority,
  printer timing, AI, Result, and rewards. Advanced mechanics explain themselves only
  on first legal encounter.
- **Failure:** If a suggested action becomes illegal, refresh to one currently legal
  action and explain why; never rewrite hand, queue, RNG, HP, or opponent state.
- **Disabled:** A teaching overlay owns one focus target at a time while preserving
  visible Back/Concede and accessibility for subdued controls.
- **Feedback:** One sentence, one highlighted physical object, and one expected result
  per lesson. An additive `battle_tutorial_v1` marker records only `completed` after
  the fourth lesson or `skipped` after explicit Skip confirmation. An absent marker is
  eligible only when no prior unified bot settlement or completed Trial record exists;
  veteran profiles are not forced into onboarding and may choose Replay Tutorial in
  Settings. Settings may explicitly reset the marker to pending for replay.
- **Progression:** No hidden tutorial grant or alternate reward; existing transactions
  and settlement remain exactly once.

## Approved implementation defaults and design audit

- **Recommended Deck ordering:** Start from the existing authored 40-card starter
  template for the profile's chosen starter and append only copies actually owned, in
  template order. Then fill missing places in repeated canonical catalog order, one
  available owned copy per ID per pass, to favor diversity. Stop at 40. This is an
  optional preview heuristic, not a new legality rule, grant, copy cap, or balance
  promise.
- **Fill ordering:** Duplicate the current draft exactly, including order and copies;
  add only owned remaining copies. Prefer deficits toward the existing Founder mix
  (20 creature, 6 filament, 6 spell, 4 equipment, 2 trap, 2 upgrade), using repeated
  canonical catalog order within each type, then any legal owned remainder in the
  same stable order. Never remove or reorder a draft card and never alter a legal
  deck above 40.
- **Preview and atomic save:** Helper Apply changes only the in-memory dirty draft;
  helper Cancel restores the exact pre-preview draft. A Pre-Print absent from or
  overrepresented in the candidate is a visible preview warning and blocks Save; it
  is never silently discarded or replaced. The player explicitly repairs the draft
  or Pre-Print rack. Dirty-exit Save continues through
  `GameManager.save_unified_deck_and_preprints`, validating deck then Pre-Prints on one
  candidate and committing one snapshot/journal transaction; failure publishes
  neither. Dirty-exit Discard restores both saved deck and saved Pre-Prints; Cancel
  remains on the editor.
- **Tutorial persistence:** Store the validated `pending|completed|skipped` marker as
  `profile.settings.battle_tutorial_v1` and preserve it when unrelated accessibility/
  audio settings save. Missing marker plus no settled `claim_receipts` key beginning
  `unified:daily:` or `unified:trial:` and no
  `solo_campaign.completed_encounter_ids` is pending; known veterans are eligible
  only through Settings replay. `unified_launch_sequence` is launch evidence, not a
  completed-battle record, and does not suppress a tutorial after interruption.
  Complete only after the fourth real checked lesson and its presentation
  acknowledgement; Skip requires its own confirmation. Back, Concede, app
  interruption, or a failed marker save does not complete it. Replay resets only this
  marker through the normal journaled settings transition and never changes ownership,
  deck, battle history, rewards, or RNG.

## M11-C implementation checklist — deck help and first-battle guidance

The current source audit found that `AccessibilityRules.ensure_fields` carries unknown
settings forward, but `AccessibilityRules.save` rebuilds a fixed settings dictionary
and would currently drop a tutorial marker. M11-C must validate and copy the named
marker through that existing save result; it must not install `pending` as a blanket
default because that would force veterans into onboarding. The existing
`GameManager.save_unified_deck_and_preprints` path already validates the deck, then
Pre-Prints against that candidate, and publishes one commit.

### M11-C1 — Recommended/Fill preview and atomic exit

- **Entry:** Founder onboarding is complete and Deck opens a persisted fixed slot.
  Capture its exact saved card order and the saved Pre-Print rack as the cancel/discard
  baseline before any helper preview.
- **Player decision:** Preview Recommended or Fill to 40; Apply or Cancel the preview;
  manually repair cards/Pre-Prints; or use Save, Discard, or Stay when Back or a deck-
  slot change finds a dirty draft.
- **Result:** Recommended iterates the authored `_starter_cards(chosen_starter)` order
  (12 chosen starter, eight Mossmunk, then the existing 20 support entries), adding
  each entry only while another owned copy remains, then repeats canonical catalog
  order one remaining owned copy per ID per pass until 40. Fill retains every current
  entry and its order, fills deficits toward the authored 20 creature / 6 filament /
  6 spell / 4 equipment / 2 trap / 2 upgrade mix in stable catalog order, then uses
  stable legal owned remainder. Apply mutates only the draft. A confirmed Save uses
  `save_unified_deck_and_preprints` once and activates the selected fixed slot only
  after both deck and Pre-Print validation succeed.
- **Failure:** Insufficient ownership, an unknown card, an invalid/overrepresented
  Pre-Print, stale ownership, or commit failure preserves the persisted deck,
  Pre-Prints, active slot, profile revision, and durable journal; the dirty draft stays
  available with the exact rejection reason.
- **Disabled:** Helpers are unavailable when they cannot construct their stated legal
  preview. Save is unavailable below 40 or while any Pre-Print is not an owned creature
  copy present in the candidate at sufficient multiplicity. A legal deck above 40 is
  never trimmed or routed through a helper implicitly.
- **Feedback:** Preview lists exact additions/removals and type counts; invalid
  Pre-Print clamps identify the card and shortage. Dirty Back/slot change exposes one
  physical Save / Discard / Stay docket. Successful joint save names the active slot;
  failure never claims either half was saved.
- **Progression:** Preview, Apply, Cancel, Discard, and Stay grant nothing. Only the
  existing joint configuration commit changes profile state; ownership and rewards do
  not change.

Deterministic acceptance: all three starter identities reproduce their authored
template when fully owned; partial ownership yields the same candidate on repeated
runs; helper Cancel restores both drafts byte-for-byte; Apply survives rerender but
not Discard; valid duplicate Pre-Prints respect candidate multiplicity; invalid
Pre-Prints block the whole commit. For dirty Back and dirty slot change, Save commits
both and follows the requested route, Discard restores both and follows it, and Stay
retains both drafts on the current editor. Native Back while the docket is open equals
Stay. Failed deck validation, failed Pre-Print validation, and failed durable commit
all leave the prior profile/revision/journal and active slot unchanged. Save/reload and
bot preflight read the same committed deck and rack; existing legal `>40` decks remain
unchanged.

### M11-C2 — first-battle eligibility, Skip, and veteran Replay

- **Entry:** Before a legal non-local bot battle, read the tutorial marker and real
  history. Absent marker plus no settled unified daily/trial receipt and no completed
  Trial is first-battle eligible; `pending` is eligible; `completed`/`skipped` and
  missing-marker veterans are not. Settings Replay is available to veterans.
- **Player decision:** Follow the four approved contextual lessons, confirm Skip,
  use Back/Concede with their existing meanings, or later select Replay Tutorial in
  Settings.
- **Result:** Acknowledging the fourth real lesson saves `completed`; confirmed Skip
  saves `skipped`; Replay saves `pending`. Each goes through the normal validated,
  journaled settings transition. The battle, deck, AI, seed, rewards, and settlement
  remain the real checked paths.
- **Failure:** A rejected/failed marker save leaves its prior value and tutorial
  eligibility intact and reports the save failure. A malformed marker is treated as
  absent for eligibility only after consulting battle history; it never forces a
  veteran tutorial or rewrites history.
- **Disabled:** Completion is unavailable before the fourth lesson and its presentation
  acknowledgement. Skip does nothing without confirmation. Replay changes no field
  except this marker. Teaching focus never disables visible Back/Concede.
- **Feedback:** Each lesson names one legal physical action and expected result;
  completion/skip/replay acknowledge only after persistence succeeds. Settings shows
  Replay without claiming history or rewards were reset.
- **Progression:** Marker transitions grant no cards, prints, coins, XP, rewards, RNG,
  or battle settlement. Existing exactly-once Result authority remains unchanged.

Deterministic acceptance: new eligible profile, interrupted first battle, completed
lesson four, confirmed and cancelled Skip, visible Back, Concede, app interruption,
marker-save failure, absent-marker daily/trial veteran, legacy completed-Trial veteran,
completed/skipped suppression, Settings replay to pending, replay completion, and an
unrelated text/high-contrast/reduced-motion/audio save all preserve the expected marker
and history. No missing-marker veteran is forced, no Back/Concede marks completion,
and no tutorial route fabricates ownership, battle state, or settlement.

Audit conclusion: public rival queue identity is preserved; only hand, deck, and
untriggered trap identity stay private. Equipment with no eligible recipient continues
the cycle in holding and prompts at the next valid required-choice boundary. The
tutorial uses the real battle and can be skipped/replayed without fabricating state.
A mandated competitive deck composition, automatic Pre-Print repair, forced veteran
tutorial, or different Recommended algorithm would be a new product choice and is not
authorized by M11.

## Delivery and evidence boundary

The r7 battle-atlas supplement and simplified loop have cleared their human approval
gates, so bounded implementation may begin. The sole runtime writer must keep battle rules/state
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
profile data deletion, silent battle reset, ads, or art beyond the exact approved r7
battle supplement without a new review and user approval.
