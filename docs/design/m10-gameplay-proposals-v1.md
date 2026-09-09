# PrintForge M10 gameplay clarity proposals v1

Status: **APPROVED by the user on 2026-09-08. The 200-HP/+50-Chassis rule
supersedes the earlier unimplemented x10 direct-hit decision. Priorities 1-6 are
authorized only through the bounded M11 checkpoint in
`docs/checkpoints/m11-living-print-battles-v1.md`.**

Date: 2026-09-08

## Grounded diagnosis

The current authority already presents turns as **Plan -> Run Cycle**, while retaining
deterministic Draw, Main, Print, Attack, and Collect internally. That is the right
high-level direction. The clarity problem is that one Plan screen still exposes too
many concepts simultaneously: a horizontally scrolling hand, selected-card actions,
three target anchors per side, FIFO queue state, cancellation/refund, creature modes,
abilities, Emergency Reprint, contextual placement, held equipment, overflow discard,
private rival state, and the Run Cycle lever.

There is also one previously approved pacing repair that is not in the current runtime:
the 2026-09-04 decision to multiply legal exposed-printer strikes by 10. Current
`UnifiedBattleRules._attack()` still applies raw `_damage(attacker, {})`; an unopposed
three-Cinderpaw field therefore needs 134 own Attack phases to break a 2,000-HP
printer. The user's 2026-09-08 question correctly identifies a cleaner alternative:
keep normal damage readable and lower the printer's health scale instead.

## Priority 0 — replace the unfinished x10 rule with a 200-HP printer scale

Approved direction: supersede the unfinished x10 direct-hit approval
with **200 base printer HP**, keep direct printer strikes at their normal integer
damage, and scale every printer-health modifier to the same one-tenth basis. The
current `Reinforced Chassis` is the only runtime printer-health modifier: it adds 500
maximum/current HP, so the replacement value is **+50**. Current v3 creature heals
and damage abilities affect creatures, not printers; `Counter Strike` modifies a
creature-target attack, not an exposed-printer hit. No current v3 card repairs the
printer directly.

The previously proposed M9 Filament Ring mastery shield and any future printer repair
must be reviewed on the new scale before implementation rather than copied at their
2,000-HP values. Percentage relationships should be preserved where intended and any
fractional one-tenth result needs an explicit deterministic integer rounding rule.
This is not authority for a blanket multiplier on all incoming damage.

- **Entry:** A legal attack reaches an exposed rival printer after all three defender
  slots are empty, after a match was constructed with its printer-health upgrades.
- **Player decision:** None beyond the existing Plan and Run Cycle decisions; approval
  of this proposal would be a product decision outside a match.
- **Result:** Each printer starts at 200/200 HP; Reinforced Chassis adds 50 maximum and
  current HP; exposed-printer strikes apply the unchanged normal integer damage. All
  creature HP, armor, creature-versus-creature damage, targeting, turn order, and
  printer-zero victory rules remain unchanged.
- **Failure:** Any x10 hit left active, blanket damage multiplier, defender bypass,
  unscaled printer-health modifier, fatigue, repeated damage, or receipt/HUD mismatch
  rejects the checkpoint.
- **Disabled:** Do not implement both x10 damage and 200 HP. Do not scale creature HP,
  armor, or creature-target repair. No further pacing rule is stacked if the evidence
  fails; return traces for a new user decision.
- **Feedback:** Attack contact, exact applied damage, printer HP movement, and event
  rail agree; preflight and both printer instruments show the new maximum and applied
  chassis value without implying creature stats changed.
- **Progression:** Only the existing exactly-once Result settles XP/coins.

Why it is equivalent for the immediate starter case: Cinderpaw's normal exposed hit
is 5. Three unopposed Cinderpaws deal 15 per own Attack phase, so a 200-HP printer
falls in 14 phases—the same bound as 150 damage against 2,000 HP under x10. Aquafin
also yields 14; Voltwig and Mossmunk yield 17. The lower-health version keeps displayed
damage consistent with creature damage and makes Chassis' 25% health increase legible.

Required before further balance changes: rerun the existing deterministic 30-match
matrix against the proposed 200/+50 scale, require all cases to terminate by printer
zero in at most 30 rounds with median 12-22, and compare its traces with the historical
x10 expectation. Also test base and Chassis matches, both opening seats, direct-hit
receipts, zero-HP clamping, Result settlement, UI fallback defaults, AI construction,
save/reload of an in-progress battle snapshot, and every test fixture that currently
embeds 2,000/2,500. No UI or Android build should silently select this proposal.

## Priority 1 — make one cycle predictable before it runs

Proposal: add a native **Next Cycle** forecast beside the lever: queue head and
remaining work, prints completing this cycle, friendly creatures that will attack,
and the current automatic target priority. It is derived read-only from authority and
contains no hidden rival identity.

- **Entry:** Player Plan is settled after any accepted Main action.
- **Player decision:** Add another legal Plan action, change a legal plan setting, or
  pull Run Cycle.
- **Result:** The forecast says, in plain language, what printing and automatic attacks
  will happen if the player runs now; Run Cycle performs exactly that unless a clearly
  named required choice pauses it.
- **Failure:** Stale revision, pending receipt, or unresolved required choice marks the
  forecast unavailable and preserves state.
- **Disabled:** Run Cycle remains disabled only for an explicit current reason.
- **Feedback:** Every accepted Plan action refreshes the forecast and highlights the
  changed line once.
- **Progression:** Forecasting is zero-mutation; existing checked intents remain the
  only authority.

Recommended decision: **approve**. This changes explanation, not combat balance.

## Priority 2 — remove routine creature-placement pauses

Proposal: while a creature card is queued, let its queue token show one native stance
toggle, `ATTACK` or `GUARD`. On completion, deploy automatically into the leftmost open
slot using that stance. If all slots are full, stage it visibly and deploy it under the
same rule when a slot opens. The player may still switch one eligible living creature
under the existing once-per-Main rule.

- **Entry:** A creature card is legally queued or waiting in staging.
- **Player decision:** Optionally choose its deployment stance before completion.
- **Result:** Completion awakens and walks the creature into the first open slot
  without a modal; the chosen/default Attack stance is visibly applied so the new
  living print joins the fight at its first legal opportunity.
- **Failure:** No open slot sends the same job to staging; stale toggle or invalid job
  changes nothing.
- **Disabled:** Stance cannot change after the job enters its completion transaction;
  first-turn and mode-lock rules remain visible.
- **Feedback:** Queue token, awakening, destination slot, and final stance agree.
- **Progression:** Toggle/deploy presentation grants no collection model or reward and
  does not replay print authority.

Recommended decision: **approve Attack as the default**, with Guard as the optional
pre-print stance. Until approved, preserve the current completion placement/mode
choice. This removes the most common mid-cycle prompt while preserving a meaningful
choice for defensive play.

## Priority 3 — target equipment only after printing

Proposal: tapping armor or a gem queues it without first choosing a creature. When it
finishes, pause once and highlight only living friendly creatures with an empty
compatible socket. If none exists, keep the item in a visible **Fitting Tray** until a
legal creature exists. Never silently replace equipment.

- **Entry:** A legal armor/gem card is in hand, or its print completes.
- **Player decision:** Queue it; after completion, choose one highlighted compatible
  living creature.
- **Result:** One accepted attachment equips the item and resumes the saved print
  budget exactly once.
- **Failure:** Target death, filled socket, stale revision, or save failure refreshes
  choices and preserves the held item.
- **Disabled:** Queue is disabled only when queue/cost/reservation rules reject it;
  attach is disabled for every incompatible target.
- **Feedback:** Hand card says `Print equipment`; completion says `Choose a creature`;
  the Fitting Tray names the item and empty socket required.
- **Progression:** Queue and attachment remain battle-state transactions only.

Recommended decision: **approve**. The runtime screen currently asks for a target
before queueing even though the authored completion contract is to equip after print;
removing that double-target model matches the game's physical promise.

## Priority 4 — keep automatic combat, make target priority explicit

Proposal: preserve automatic slot-order attacks. Ready Attack creatures target the
player's one optional focus mark when legal; otherwise they attack the leftmost rival
creature; only an empty rival field exposes the printer. Guard creatures do not attack.
Show numbered attack order above friendly slots during Plan and animate that exact
order during Run Cycle.

- **Entry:** Player Plan contains one or more ready living creatures.
- **Player decision:** Optionally place one focus mark on a legal rival creature, or
  leave automatic priority unchanged.
- **Result:** Run Cycle resolves a deterministic visible attack order without manual
  per-creature Attack buttons.
- **Failure:** An invalidated focus target falls back to the stated leftmost rule and
  reports the fallback before the next attack.
- **Disabled:** Printer focus is unavailable while any rival creature remains; rival
  private cards are never targetable.
- **Feedback:** Order badges, focus mark, attack contact, damage receipt, and resulting
  HP agree.
- **Progression:** Presentation does not choose or repeat damage; Result remains the
  only profile reward boundary.

Recommended decision: **approve**. Do not restore manual Draw/Print/Attack/Collect
buttons or per-attacker targeting.

## Priority 5 — deck size and onboarding decision

Current rule: decks have a 40-card minimum and no maximum. Founder onboarding already
constructs an exact legal 40-card deck through the starter card plus three visible
13-card receipts. Changing deck size now would invalidate that content partition and
requires new balance/evidence.

Proposal for the next playable release: keep the existing **40-card minimum with no
maximum**, add `Use Recommended Deck` and `Fill to 40` actions that use owned cards
deterministically, and keep the final Founder deck automatically active. Do not impose
an exact cap or copy cap in this slice: existing legal decks above 40 must remain legal,
and the authored Founder deck intentionally contains 12 starter and eight Mossmunk
copies.

- **Entry:** Founder completion or Deck editing with owned cards.
- **Player decision:** Keep the current exact deck, use the recommended composition,
  fill a partial draft, or edit manually.
- **Result:** Save/Activate continues to accept any legal deck of at least 40 owned
  known cards. Auto actions create or complete a deterministic 40-card candidate and
  show the full proposed diff before one confirmation.
- **Failure:** Unknown/unowned cards, stale ownership, save rejection, or an under-40
  result leaves the current active deck unchanged.
- **Disabled:** Battle and Save/Activate remain disabled until the candidate has at
  least 40 cards and is otherwise legal.
- **Feedback:** Persistent `n / 40 minimum`, type counts, legality reason, and one
  recommended correction are visible.
- **Progression:** Auto-build is configuration only and grants no cards, packs, coins,
  XP, licenses, or models.

Recommended decision: **keep the current 40 minimum now and add deterministic deck
assistance without migrating saves**. A fixed cap or move to 30 belongs to a separate
balance proposal after the selected printer-pacing matrix and observed matches because
either would require Founder, deck, copy-distribution, and existing-save decisions.

## Priority 6 — teach only the core loop in the first bot battle

Proposal: the first bot battle uses the legal Founder deck but guides only four ideas:
`choose a card`, `watch the printer queue`, `pull Run Cycle`, and `prints awaken and
fight`. Advanced trap, upgrade, cancel/refund, Emergency Reprint, mastery, and Market
explanations appear only when first encountered or after the first Result. Cards remain
legal; the tutorial does not use a different rules engine.

- **Entry:** The first legal Founder battle starts.
- **Player decision:** Complete one highlighted legal action at each teaching moment,
  with an optional `Show me` explanation and visible Back/Concede.
- **Result:** The player reaches one creature print, awakening, automatic attack, and
  Result using the same checked battle authority as every later match.
- **Failure:** If the highlighted action becomes illegal, recompute one legal teaching
  action and explain why; never mutate hand/queue/RNG to force the script.
- **Disabled:** Unrelated controls remain visible but temporarily subdued only while a
  teaching prompt owns focus; accessibility can read them and their reason.
- **Feedback:** One sentence, one highlighted physical object, and one expected result
  per step.
- **Progression:** Tutorial actions and Result use normal exactly-once transactions;
  no hidden tutorial grant or alternate reward.

Recommended decision: **approve after Priorities 0-4**, so teaching matches the final
core loop rather than documenting temporary friction.

## Decisions requested from the user

1. **Approved:** replace the unfinished x10 rule with 200 base printer HP and +50
   Reinforced Chassis, subject to the same 30-match pacing gate.
2. **Approved:** preserve the 40-card minimum and existing legal decks above 40; add
   deterministic Recommended Deck and Fill to 40 previews from owned copies without
   migrating ownership.
3. **Approved:** queued creatures may preselect stance and auto-deploy leftmost,
   Attack by default with Guard optional.
4. **Approved:** queue armor/gems without a recipient, then choose one compatible
   living creature after print; retain a Fitting Tray when none is eligible.

Automatic slot-order combat with one optional focus mark remains approved; Priority 4
adds clearer forecast/order feedback, not manual attack targeting. The 2026-09-08 user
message, “Do it,” approves these decisions and additionally requires visible battle
print animations and a battlefield that reads as living printed creatures rather than
cards. M11 remains responsible for implementation and evidence. None of these gameplay
changes belongs to the completed M10 alignment-only Android build.
