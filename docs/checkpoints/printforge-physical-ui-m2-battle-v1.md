# PrintForge physical UI M2 battle checkpoint v1

Status: decision-complete; M2 implementation authorized under the screen-first
production workflow

Date: 2026-08-31

Entry baseline: M1 commit `ecb0c0a`

Authority: `docs/design/printforge-legends-mechanics-v3.1.md` (document title
mechanics v3.2), `docs/design/printforge-screen-first-gameplay-v1.md`, and
`docs/checkpoints/printforge-physical-ui-preproduction-v1.md`. This checkpoint
specifies M2 presentation and orchestration only. It changes no catalog value,
integer combat rule, deck rule, economy rule, save namespace, save schema, card
identity, or authority intent.

## Authorization and product boundary

M1 runtime/visual correction is PASS at `ecb0c0a`; therefore M2 is authorized under
the required designer → Sol → sole runtime writer → read-only UI reviewer → Sol
audit workflow. M2 covers Challenge/Preflight, portrait Battle Plan, Plan → Run Cycle
orchestration, contextual battle decisions, living-print presentation, and the
battle-complete handoff. Android/native AdMob completion, release export, and Drive
delivery remain M4 work.

The player-facing loop removes manual Draw, Main, Print, Attack, and Collect controls.
Those five phases remain authoritative and occur in that exact order. The player
chooses optional Main actions in Plan, pulls Run Cycle once, watches accepted actions
resolve, and intervenes only for a decision the deterministic rules cannot choose on
the player's behalf: placement and mode, equipment attachment, or overflow discard.

## Locked deterministic and visual boundaries

- Printer HP begins at 2,000; reducing the opposing printer to zero remains the only
  loss condition.
- Battle filament begins at 200 with existing 400/500/700 capacity rules and no turn
  regeneration. Filament Ring, recovery, queues, staging, holding, traps, upgrades,
  Emergency Reprint, preprints, modes, cooldowns, equipment, damage, scrap, and all
  catalog values retain current behavior.
- Each side has three ordered creature slots. The queue is FIFO, starts at capacity
  three, advances only its head, and retains current speed, carryover, pause, cancel,
  refund, and Dual Queue rules.
- Starting player draws zero and cannot attack on turn one; the other player draws
  two; later Draws draw one when available. An empty deck is not a loss. Collect hand
  limit remains eight.
- All arithmetic remains deterministic integer arithmetic. The same seed and ordered
  accepted intents must produce the same snapshots, revisions, events, and winner.
- The UI consumes the viewer's `public_snapshot`. The rival hand shows count and
  face-down cards only; rival deck identity and face-down trap identity never cross
  the presentation boundary.
- Preserve catalog character identity and existing creature sprite sheets. One living
  field unit is one animated sprite at one slot. A card, raw print, wireframe, or
  awakening overlay never remains as a duplicate living unit.
- Preserve the exact support-card back at
  `assets/cards/support_card_back_source_v1.png`, SHA-256
  `CCCD58ED5272B031640864F1F3989AE9F1297C05816A2903C52EB1A90B9FA5DB`, for all
  face-down rival-hand cards.
- Generated UI art is text-free static composition/material only. Names, HP,
  filament, counts, queue progress, statuses, targets, errors, focus, event copy, and
  accessibility remain native Godot controls.
- Portrait only. Production Godot ad reserve remains zero under the native-bottom
  contract. No M2 control may depend on a synthetic reserve or be covered when the
  native host resizes the usable surface.

## Revisioned one-intent coordinator contract

Every authority submission uses one checked envelope:

```text
{ seat, expected_revision, intent }
```

The coordinator reads but never mutates authoritative battle state. It may select the
next existing intent, submit it, wait for one accepted/rejected response, replace its
view with the returned public snapshot, and then decide whether to present, pause, or
submit the next intent. It must not dispatch a second intent while the first is in
flight or while its finite presentation is active.

- One accepted existing intent increments the canonical battle revision exactly once.
  The coordinator has no second revision counter and cannot double-increment.
- A rejected, invalid, stale, duplicate, wrong-seat, or wrong-phase envelope preserves
  the exact serialized snapshot and revision. The coordinator refreshes from the
  returned public snapshot and explains the rejection.
- A generation token identifies the current Run Cycle. Route exit, match replacement,
  recovery, or a new cycle invalidates older callbacks so a late animation/timer can
  never submit an intent.
- Presentation skip and reduced motion complete only the current presentation window.
  They never acknowledge an intent, advance a phase, resolve a print, choose a target,
  settle Collect, or change a revision.
- Save only at existing stable authority boundaries or a fully specified pending
  decision/receipt. Reload resumes the exact phase, revision, pending decision, and
  public presentation state without replaying an accepted intent.
- A watchdog may stop orchestration and restore the latest accepted public snapshot.
  It may not fabricate success, retry a non-idempotent intent, jump phases, or consume
  the remaining cycle in one batch.

## Portrait battle information hierarchy

From top to bottom inside the usable Godot surface:

1. **Rival instrument rail:** rival identity/public status, printer HP/max HP,
   filament/current maximum, active public effects, face-down hand using the exact
   card back plus native hand count, and deck count only. No private card or trap
   identity.
2. **Rival printer and queue:** a physical printer chamber with FIFO head progress and
   up to the current public capacity. The printer HP instrument remains readable
   during animation. Queue cards are blueprints/material jobs, not living battlefield
   units.
3. **Rival living field:** three stable left-to-right ceramic/etched floor anchors.
   Occupied anchors show animated creature sprites with native HP, armor HP, mode,
   equipment, readiness, cooldown/status, and accessible name. Empty anchors stay
   visibly open; the field is not a row of tactical card holders.
4. **Shared action lane:** compact native event rail and transient print/awaken/attack
   effects. It never hides printer HP, required decisions, or Run Cycle status.
5. **Player living field and printer:** three matching ordered anchors, player printer
   chamber, FIFO queue, staging/holding indicators, printer HP, filament/current max,
   trap-set/public effects, and installed-upgrade summary. Player units use the same
   sprite/state language as rival units.
6. **Player hand and cycle controls:** a readable physical fan/tray of owned face-up
   cards, selected-card inspector/targets, and one primary physical Run Cycle lever.
   Hand, required-decision controls, event feedback, and lever remain inside safe
   bounds at 100% and 150% text.

Selection raises or lights the physical object without displacing the battlefield.
Touch targets are at least 48 logical pixels; Run Cycle is at least 56. Native focus is
complete on all four edges and follows visible reading order from rival public summary
through field, hand, contextual decision, and Run Cycle. No pointer capture,
confinement, or hidden pointer mode is allowed.

## Feature contracts

### Challenge Board and battle preflight

- **Entry:** Activate the Workshop battle dais from M1, then open a challenge using
  the saved active deck, legal preprints, printer/workshop upgrades, and seeded rival
  definition.
- **Player decision:** Inspect the challenge and public rival summary, inspect or
  change the active deck/preprints through their existing routes, begin a legal
  battle, or return to Workshop.
- **Result:** Begin creates exactly one seeded match from the validated 40-card-or-more
  owned deck, current legal preprints, and current upgrades. Preprints consume matching
  active-deck creature copies, occupy up to three ordered slots in Defense, and retain
  first-owner-turn restrictions.
- **Failure:** Invalid ownership, fewer than 40 cards, illegal/absent/noncreature
  preprint, stale revision, missing authority, or creation failure leaves profile and
  preflight unchanged and gives the exact reason.
- **Disabled:** Begin is disabled while deck/preprint validation fails, authority/save
  setup is pending, or another begin transaction is in flight. Rival private data and
  unavailable difficulty inputs are never interactive.
- **Feedback:** Native deck size, legality, selected preprints, printer summary, public
  rival traits, seed/mode context, disabled reason, focus, and safe return. No baked
  dynamic values.
- **Progression:** Browse and preflight are zero-mutation. Battle state begins only
  after one accepted creation transaction; profile rewards remain outside M2 until
  the existing result settlement.

### Entering Plan

- **Entry:** A nonfinished match is at the active player's Draw with no unresolved
  pending decision and a checked public snapshot/revision. Local hot-seat privacy
  handoff completes before a local owner's face-up hand appears; AI/remote hands never
  appear face up.
- **Player decision:** Acknowledge privacy handoff when applicable, then inspect the
  refreshed battlefield and hand. There is no Begin Main or Draw button.
- **Result:** The coordinator submits exactly one existing `advance_phase` intent for
  Draw, waits for acceptance, presents native Draw/status events, and enters Plan only
  from the returned Main snapshot. Draw count, cooldown/status ticks, readiness, and
  waiting staging/holding use existing rules.
- **Failure:** Stale revision, wrong seat, recovery, or rejected Draw advance stops on
  the returned snapshot; it does not reveal a private hand or submit Main actions.
- **Disabled:** Hand and Run Cycle remain disabled during privacy handoff, Draw intent,
  snapshot refresh, blocking recovery, and any pending required decision.
- **Feedback:** Native `Your Plan`/rival-turn status, accepted Draw events, hand count,
  changed statuses, and exact rejection. Internal phase names may appear in an
  inspector/event log but never as player-operated phase controls.
- **Progression:** Draw advances one battle revision only. It changes no profile,
  collection, model, entitlement, or save schema.

### Plan actions

- **Entry:** Active seat is in authoritative Main with no blocking pending decision,
  current expected revision, and the player's face-up hand available.
- **Player decision:** Perform zero or more currently legal existing Main intents:
  inspect a card/unit/queue; play a creature; choose a friendly target and queue armor
  or gem; play filament/spell/trap/effect/upgrade; confirm trap replacement when
  required; cancel a queued item with the existing floor-half refund and graveyard;
  switch one eligible unit's mode once; activate an eligible Main ability/target; use
  an installed Emergency Reprint charge; or set/clear one transient focus target for
  the next cycle.
- **Result:** Each confirmed gameplay action submits one existing intent, waits for one
  response, and refreshes from the accepted public snapshot/revision. Inspect and
  focus are presentation-only. Creature/equipment jobs enter the existing FIFO queue;
  immediate cards resolve under existing catalog rules.
- **Failure:** Invalid target, stale revision, insufficient filament, full queue,
  unavailable socket, inactive ability, illegal reprint, rejected trap replacement,
  catalog mismatch, or save/recovery error preserves the exact snapshot and returns
  the specific authority reason.
- **Disabled:** The UI derives reasons from current public state: wrong phase/seat,
  pending intent, insufficient filament, queue capacity, absent/occupied target,
  active Ring, one-upgrade-per-turn/five-installed cap, cooldown/status lock,
  preprint first-turn restriction, used mode switch, exhausted reprint charge, or
  blocking modal/privacy handoff. A disabled card remains inspectable.
- **Feedback:** Selected card rises from the hand and shows native cost/type/effect;
  legal targets light, illegal targets remain visible with a reason, queue/filament
  changes animate only after acceptance, and the event rail names the accepted action.
  Focus target is visibly marked as `Focus this cycle` and carries no authority
  revision.
- **Progression:** Accepted Main intents change battle state/revision only. Inspect,
  selection, target preview, focus, and cancellation preview are zero-mutation.

### Pull Run Cycle

- **Entry:** Active seat is in settled Main, no request/presentation/save/handoff is in
  flight, no required decision is pending, and the coordinator holds the current
  revision.
- **Player decision:** Pull Run Cycle once, then watch. During the cycle the only
  gameplay choices are contextual placement/mode, attachment, and exact overflow
  discard. A presentation-speed/skip action is visual only.
- **Result:** The coordinator locks Plan and submits this ordered sequence one intent
  at a time: Main→Print advance; Print resolution; every required contextual decision;
  Print→Attack advance when Print is settled; eligible attacks from friendly slots
  0, 1, 2 with one accepted attack and finite presentation before the next; Attack→
  Collect advance; exact overflow decision if required; Collect settlement; then
  control passes to the next seat at Draw. Every next step uses the revision returned
  by the prior accepted step.
- **Failure:** Any rejection, stale response, invalid generation token, timeout,
  unknown phase/pending kind, or lost authority stops the lever, preserves/restores
  the latest accepted snapshot, and presents a retry/recovery path. No remaining step
  is assumed, replayed, or batched.
- **Disabled:** Run Cycle is disabled outside settled Main, for the wrong seat, while
  a modal/intent/presentation/save/privacy handoff is active, during a required
  decision, after match finish, or while recovery is unresolved. It cannot be pulled
  twice for one generation.
- **Feedback:** The physical lever moves only after activation, Plan controls visibly
  lock, a native event rail identifies Print/placement/attack/Collect progress, and a
  pause label states exactly what choice is needed. The internal five phases are
  feedback, never five manual buttons.
- **Progression:** Each accepted intent advances one battle revision. Run Cycle itself
  is not a new authority transaction and adds no profile progress. Battle result
  settlement remains a separate exactly-once transaction.

### Required placement and combat mode

- **Entry:** The returned snapshot has `pending.kind == place` for the acting seat,
  either from a completed creature or the oldest staged creature, and at least one
  open field slot exists.
- **Player decision:** Choose exactly one open slot 0–2 and Attack or Defense mode,
  then confirm one existing `place_completed` intent.
- **Result:** One accepted intent places the pending unit in that slot and mode, marks
  it ready under existing rules, clears that pending item, and allows Print
  continuation. A second pending decision may immediately replace it and must pause
  again.
- **Failure:** Occupied/out-of-range slot, invalid mode, wrong seat/kind, stale
  revision, or changed field rejects unchanged and refreshes legal choices.
- **Disabled:** Occupied slots, background Plan/hand/Run Cycle controls, and submit
  without both slot and mode are disabled. A preprinted unit retains its existing
  first-owner-turn limits.
- **Feedback:** The raw/awakened creature remains visibly `Awaiting deployment` near
  its printer; only open anchors light; native mode consequences, name, HP/Bend,
  accessibility, and complete focus are shown. The creature is not yet duplicated as
  a living field sprite.
- **Progression:** Exactly one accepted placement increments one battle revision; it
  creates no collection model or profile asset.

### Required equipment attachment

- **Entry:** The returned snapshot has `pending.kind == attach` for the acting seat
  and at least one friendly living unit has the matching empty armor or gem slot.
- **Player decision:** Choose one compatible friendly unit and confirm one existing
  `attach_completed` intent.
- **Result:** One accepted intent attaches the held item, applies existing armor/gem
  values, removes that holding item, clears pending, and allows Print continuation.
  Further held items pause separately in deterministic order.
- **Failure:** Occupied/wrong socket, missing/destroyed unit, wrong seat/kind, stale
  revision, or changed compatibility rejects unchanged and refreshes targets.
- **Disabled:** Incompatible and rival units cannot be selected; Plan/hand/Run Cycle
  controls remain disabled until the required attachment resolves.
- **Feedback:** Compatible native sockets/units light; item name/effect and resulting
  public armor/gem state are native; holding remains visible until acceptance.
- **Progression:** One accepted attachment increments one battle revision only. It
  creates no Forge model, license, ownership, or save-schema record.

### Required overflow discard

- **Entry:** The cycle reaches authoritative Collect with active hand size greater
  than eight and no other pending decision.
- **Player decision:** Select exactly `hand size - 8` owned hand cards and confirm one
  existing `discard_overflow` intent.
- **Result:** One accepted intent moves exactly the selected cards to the graveyard;
  the coordinator then submits a separate Collect `advance_phase` using the returned
  revision.
- **Failure:** Wrong count, duplicate/absent card, stale revision, wrong seat/phase, or
  changed hand rejects unchanged and refreshes the exact required count.
- **Disabled:** Confirm remains disabled until the exact count is selected. Background
  battlefield actions and Run Cycle are disabled; cards remain inspectable.
- **Feedback:** Native selected count, required count, card names, consequences,
  accessibility, and rejection reason remain visible at 150% text without hiding the
  hand.
- **Progression:** Discard and subsequent Collect settlement are two distinct accepted
  intents/revisions. Recovery, Filament Ring, turn pass, and next Draw remain existing
  rules; no profile reward settles here.

### Print, awaken, deploy, and living sprite

- **Entry:** An accepted Print advance is about to progress the visible FIFO head in
  the acting side's printer; the pre-intent public receipt identifies only information
  legal for that viewer.
- **Player decision:** Watch or use visual-only presentation speed/skip. If the print
  completes, resolve any required placement/attachment choice as specified above.
- **Result:** Progress is shown in the correct side's physical printer: blueprint/job,
  wireframe seed, layer lines/scan, solid raw print, awakening pulse, then step-off.
  Only after accepted placement does exactly one catalog-matched animated sprite
  occupy the chosen field anchor and enter idle/mode presentation. Equipment resolves
  as equipment and never becomes a creature sprite. Staged/held items remain at their
  truthful printer-side state.
- **Failure:** Print Interrupt, jam/pause, incomplete remaining turns, full field,
  incompatible target, missing optional art, or presentation interruption shows the
  accepted authority outcome. Presentation never fabricates completion, placement, or
  a surviving unit.
- **Disabled:** A non-head queue item cannot animate as progressing. A finished
  creature cannot join the field until placement is accepted. A staged unit cannot
  auto-select its mode. Presentation skip cannot resolve authority.
- **Feedback:** Native card/job name, remaining progress, queue position, staging or
  holding status, printer owner, and event text accompany the finite animation.
  Reduced motion uses meaningful seed/raw/awake/idle states with the same accepted
  outcome.
- **Progression:** Print presentation is zero-mutation. The existing Print/placement/
  attachment intents alone mutate battle state and revision; no battle print creates
  a persistent `printed_models` entry.

### Automatic attacks and battle completion

- **Entry:** Print is settled, authoritative phase is Attack, and the coordinator
  holds the current snapshot/revision plus an optional transient focus target selected
  during Plan.
- **Player decision:** Watch or visually skip each finite event. Targeting is automatic:
  a still-legal focused rival slot wins; otherwise choose the lowest occupied rival
  slot; target the printer only when every rival slot is empty.
- **Result:** Inspect friendly slots in order 0, 1, 2. Skip null, Defense, not-ready,
  already-attacked, attack-locked, or first-player-turn-one-forbidden units without an
  attack intent or false receipt. For each eligible unit, submit one existing `attack`
  intent, wait for acceptance, play one finite lunge/projectile/impact/hit/ability/
  defeat sequence using the existing sprite and VFX behavior, update public HP/status,
  then inspect the next slot. Stop immediately if the authority marks the match
  finished.
- **Failure:** Rejected target/attacker, stale revision, destroyed focus, interrupted
  presentation, missing optional VFX, or authority loss stops on the latest accepted
  snapshot. An invalid focus falls back deterministically; it never causes a rejected
  attack loop.
- **Disabled:** Manual attack and phase buttons do not exist. Defense/not-ready/used/
  locked units are visibly nonattacking. Printer targeting is unavailable while any
  rival creature slot is occupied.
- **Feedback:** The acting living sprite visibly leaves idle, attacks, contacts the
  correct living target/printer, and returns or finishes before the next attacker.
  Native damage, armor absorption, status/ability, destruction, printer HP, slot
  order, and target reason remain available. The focus marker clears at cycle end or
  match replacement.
- **Progression:** Every accepted attack is one battle revision. Animation is
  presentation-only. A finished authority hands off to the existing exactly-once
  Battle Result route; M2 does not invent or settle rewards.

### Rival turn and hidden information

- **Entry:** Collect passes control to the rival at Draw, or a seeded match begins
  with the rival active.
- **Player decision:** Watch public actions. In local hot-seat only, complete a privacy
  handoff before the next human owner's private Plan. There is no access to an AI or
  remote rival hand.
- **Result:** The rival policy chooses canonical legal intents, but the same
  coordinator submits and presents exactly one intent at a time. Public queue, print,
  placement, attachment, attack, damage, and turn-pass receipts appear in causal
  order. AI required choices use its existing deterministic legal policy.
- **Failure:** Unknown pending kind/phase, rejected AI choice, safety budget, stale
  revision, or authority loss stops with a recoverable native error and latest public
  snapshot. The system does not mutate an entire rival turn before replaying it.
- **Disabled:** Player hand/actions/Run Cycle and rival face-down cards are
  noninteractive. Private hand/deck/trap identity is absent, not merely hidden by a
  visual cover.
- **Feedback:** Rival hand uses exact card backs plus native count; trap shows only set
  state; public event receipts contain no hand/deck/trap identity. Rival printer and
  all six field anchors remain visible throughout.
- **Progression:** Rival accepted intents increment battle revision exactly once each.
  Presentation traces contain public data only and create no profile mutation.

### Reduced motion, contrast, accessibility, and interruption

- **Entry:** Any M2 screen or finite battle presentation with the current user
  preferences, safe-area insets, and usable portrait surface.
- **Player decision:** Navigate by touch, mouse, keyboard, controller, or accessibility
  action; change existing text/contrast/motion preferences; use visual-only skip when
  available.
- **Result:** Reduced motion replaces travel with meaningful seed/raw/awake, attacker/
  contact, hit/status, and settled frames while preserving event order and timing
  gates needed for one-intent sequencing. High contrast, 150% text, and screen-reader
  names preserve all decisions. Resize/safe-area changes rebuild presentation from the
  latest accepted public snapshot without resubmission.
- **Failure:** Missing optional raster VFX uses the reviewed code-native fallback.
  Focus loss, route interruption, resize, or animation cancellation cannot advance
  authority or submit a late callback.
- **Disabled:** Background controls are unreachable during required decisions;
  animation-only controls do not masquerade as gameplay; no pointer capture,
  confinement, hidden mode, rapid flashing, or essential color-only state.
- **Feedback:** Complete four-edge focus, 48/56-logical-pixel targets, native state
  labels, non-color mode/status cues, readable event history, and screen-reader order
  mirror the visual hierarchy.
- **Progression:** Accessibility and presentation settings change presentation only.
  Identical accepted intents must finish at the same canonical snapshot/revision with
  full motion, reduced motion, skip, resize, and fallback VFX.

## Exact M2 acceptance tests

M2 cannot pass unless automated evidence proves all items below:

1. Baseline M1 tests remain green from commit `ecb0c0a`; no save-schema or profile
   fixture changes are required by M2.
2. A fresh active Draw auto-submits one checked `advance_phase`, increments revision
   once, and exposes Main/Plan; no player-facing Draw/Main/Print/Attack/Collect button
   exists.
3. Every coordinator request contains seat, current expected revision, and exactly one
   existing intent. An instrumented authority observes maximum one in-flight request
   and no next request before prior response plus required finite presentation.
4. Wrong seat, stale revision, invalid intent, duplicate callback, and generation-token
   mismatch preserve byte-equivalent serialized state and revision and issue no
   follow-on intent.
5. Each legal Plan action category retains existing rule coverage: creature queue,
   armor/gem target, immediate filament/spell/trap/Ring, upgrade cap, queue cancel and
   refund, mode switch, Main ability, Emergency Reprint, and inspect/focus
   zero-mutation. Each disabled reason is asserted.
6. Run Cycle submits Main→Print, resolves FIFO head/speed/carryover, and does not enter
   Attack while pending is nonempty. Queue-pause and incomplete jobs show no false
   completion.
7. Completed creature placement pauses for one open slot plus Attack/Defense; occupied
   slot and invalid mode reject unchanged. Resolving one pending item can expose a
   second pending item without unlocking background controls.
8. Full field stages a completed creature; destroying a unit does not auto-place it;
   the oldest staged unit becomes pending only when legal and still requires mode.
9. Equipment attaches only to a compatible empty armor/gem socket; incompatible jobs
   hold, later surface deterministically, and pause separately. Filament Ring never
   queues, holds, attaches, stacks, or follows a destroyed creature.
10. Overflow requires exactly `hand size - 8` selected cards. Rejection is unchanged;
    accepted discard and Collect settlement are separate intents/revisions.
11. Friendly attack inspection is slot order 0, 1, 2. Null, Defense, not-ready,
    attacked, locked, and starting-player turn-one units emit neither attack intent nor
    false presentation receipt.
12. A legal focus target wins while occupied; destroyed/invalid focus falls back to
    lowest occupied rival slot; printer is targeted only with all rival slots empty.
    Focus is transient and zero-revision.
13. Each accepted attack produces one finite animation and one public state update
    before the next attack. Rapid skip, reduced motion, and duplicate animation
    completion cannot duplicate attacks or damage.
14. The same seed and Plan intents under full motion, reduced motion, presentation
    skip, optional-VFX absence, resize, and reload yield the same final serialized
    state, revision sequence, event order, and winner.
15. Print presentation occurs inside the acting printer and orders blueprint/wireframe
    → layered raw print → awaken → step-off → one living idle sprite. No preplacement
    living sprite, card-shaped field unit, lasting raw duplicate, or wrong-side
    printer is allowed.
16. All six occupied slots can simultaneously show six independent catalog-matched
    animated sprites. HP/mode/status updates and defeat affect only the matching slot.
    Empty/destroyed slots show no stale sprite.
17. Existing attack, ability, defend, switch, print, hit, destruction, armor/gem, and
    status VFX remain finite; optional generated atlases may enhance but never replace
    the deterministic code-native fallback.
18. Viewer snapshots and all AI/public receipts omit rival hand, deck, and trap
    identity; face-down rival hand uses the exact approved card back and truthful
    native count. A source-level test proves private fields are absent.
19. AI uses the same one-intent dispatcher, resolves deterministic placement/
    attachment/overflow choices, respects first-turn attack prohibition, stops within
    a bounded safety budget, and never mutates a whole turn before presentation.
20. Printer HP/max, filament/max, three slots per side, both queues, player hand,
    rival hand count, public effects, pending decision, event rail, and Run Cycle
    status remain visible/accessible at 576x1024 and 720x1280.
21. Touch targets, four-edge focus, 150% text, high contrast, reduced motion,
    accessibility order, safe-area/resize rebuild, and pointer-safety tests pass.
    Required decisions keep background unreachable and native reasons unclipped.
22. Production Godot ad reserve remains zero. The 1080x2400 positive-reserve fixture
    is visibly labeled synthetic and proves hand, pending decision, toast/event, and
    Run Cycle remain above the simulated native boundary. It is not native-AdMob or
    real-device evidence.
23. Match finish stops orchestration immediately and reaches the existing result
    handoff once. No M2 path grants XP, Coin, quest/season/drop, model, card,
    blueprint, pack, or entitlement before the separate result transaction.
24. Godot process/PID ownership, isolated E:-based test state, crash-dialog cleanup,
    source scan for pointer capture/confinement, `git diff --check`, and no orphaned
    task Godot processes are recorded honestly. Environment warnings are reported and
    are not represented as stderr-clean evidence.

## Original-resolution capture matrix

Capture each numbered state at both 576x1024 and 720x1280 unless the Fixture column
says otherwise. Captures use current native text and approved catalog sprites/card
back; no private rival data or baked dynamic labels.

| ID | State | Required visible proof | Fixture |
| --- | --- | --- | --- |
| M2-01 | Challenge Board | physical challenge choice, public rival summary, return | both |
| M2-02 | Legal preflight | 40+ deck legality, preprints, printer summary, Begin | both |
| M2-03 | Opening Plan | Draw feedback, both printers/HP, six anchors, queues, hands, Run Cycle | both |
| M2-04 | Selected hand card | raised face-up card, native cost/effect, legal and disabled targets | both |
| M2-05 | Planned queue | player printer FIFO head/progress, filament delta, settled Main | both |
| M2-06 | Print at 60% | correct printer, layered raw/wireframe treatment, no field duplicate | both |
| M2-07 | Awakening step-off | solid raw print awakening at printer, field slot not yet duplicated | both |
| M2-08 | Placement pause | open anchors, Attack/Defense, background locked, awaiting print | both |
| M2-09 | Attachment pause | compatible native sockets, held item, background locked | both |
| M2-10 | Living print joined | one animated sprite on chosen anchor, truthful native state | both |
| M2-11 | Full six-slot field | six independent catalog sprites, readable printer/field hierarchy | both |
| M2-12 | Auto-attack contact | correct ordered attacker/target, finite VFX, HP/armor event | both |
| M2-13 | Defeat/empty anchor | destroyed sprite removed, public scrap/status feedback | both |
| M2-14 | Overflow pause | exact discard count, face-up hand, background locked | both |
| M2-15 | Rival cycle | face-down exact card backs/count, rival print/attack, no private fields | both |
| M2-16 | 150% text | Plan plus hand inspector and Run Cycle with no clip/dead control | both |
| M2-17 | High contrast/focus | complete four-edge focus on a physical battle target | both |
| M2-18 | Reduced motion | meaningful print or contact peak plus same native event outcome | both |
| M2-19 | Failure/recovery | stale/rejected intent reason, latest public snapshot, retry path | both |
| M2-20 | Synthetic bottom stress | hand, pending choice, event/toast, Run Cycle above visibly labeled synthetic overlay | 1080x2400 only |

The required set is 39 originals: 19 states × 2 standard portrait fixtures plus one
1080x2400 synthetic-bottom fixture. Preserve original dimensions and record a manifest
with state ID, fixture, source revision, preferences, expected authority snapshot,
asset provenance, and SHA-256.

## Visual and maintainability gate

Read-only UI review compares original-resolution captures with approved masters
`BA-01-challenge-board-v1.png`, `BA-02-battle-preflight-v2.png`,
`BA-03-main-plan-v3.png`, `BA-04a-print-animation-v2.png`,
`BA-04a2-awaken-step-off-v2.png`, `BA-04b-attack-animation-v2.png`, and
`BA-06` through `BA-10`. P0 blockers include private-information leakage, missing
printer/HP/hand/field hierarchy, card-shaped living field units, wrong-printer print,
preplacement creature duplication, manual phase controls, hidden required decisions,
clipped Run Cycle/hand, or nonfinite/duplicated animation. M2 requires no P0/P1 before
sign-off.

At the milestone boundary Sol audits coordinator purity, single revision ownership,
one-intent sequencing, stale callback cancellation, node churn, sprite/cache reuse,
texture loads, finite timelines, responsive rebuilds, native text/accessibility,
test isolation, and main-scene growth. The sole runtime writer performs bounded
corrections/refactors and reruns deterministic plus visual regression. Designer and UI
reviewer remain nonwriters. Sol alone stages and commits after review.

## Explicit non-goals

- No manual phase toolbar or tactical card-holder battlefield.
- No gameplay, balance, catalog, economy, reward, save-schema, or orientation change.
- No new creature identity when an approved catalog sprite exists; no mechs or humans.
- No persistent model from a battle print and no lasting duplicate unit.
- No private rival hand/deck/trap data in UI, receipts, captures, or accessibility.
- No landscape duplicate, production AdMob IDs, rewarded ads, Android release claim,
  or Drive delivery in M2.
- No M3 Collection, Deck, Market, reward, settings/recovery replacement, or result
  economy redesign.
