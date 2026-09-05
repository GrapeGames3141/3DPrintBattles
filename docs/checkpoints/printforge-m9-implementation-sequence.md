# M9 implementation and verification sequence

Root planning record, 2026-09-04. Baseline `8eac477` on
`spike/printforge-physical-ui`. Product authority is
[the M9 gameplay checkpoint](printforge-m9-playable-progression-v1.md).

## Ownership and current state

- Gameplay designer: decision-complete Markdown contracts and model-design notes.
- Terra: sole writer of runtime, scenes, tools, and runtime-asset integration.
- UI reviewer: read-only original-resolution concept/capture review.
- Root: architecture planning, ImageGen candidates/provenance, diff review,
  maintainability gates, final staging/commit and delivery verification.

M9A is in implementation. M9B below is planned but must not start until root reviews
the M9A diff and verification. M9C equipment direction was human-approved on
2026-09-04 ("Approve and approve the art too"); no
candidate is promoted merely because it was generated. Current Android device
inventory is empty, so real device Back verification remains a separate open gate.

## M9A: input, packs, Founder onboarding

1. Centralize one readable visible Back owner and its existing caller/transaction
   ordering. Mount it last above passive layout wrappers. Preserve actual controls'
   hit ownership; do not globally turn all Controls into IGNORE.
2. Add explicit pack-route ownership instead of a pending-receipt override on every
   management route. Record receipt caller before the atomic claim/purchase. Preserve
   content/page on Back, and expose Resume Pack on Workshop.
3. Page the full ordered receipt, including bonus cards, five cards per page. Keep
   native counters, prices, all card facts, focused inspection and accessibility.
4. New-profile-only Founder marker: choose creates the one-card provisional deck;
   first print creates its model but does not secretly fill the deck. Claim grants
   and appends 13 atomically; Keep only acknowledges. Three Kept receipts unlock the
   existing 40-card composition. Unmarked legacy saves retain their original path.
5. Repair confirmed card facts, effective-price display, Spool-level display and
   equipment card/license grants. Normalized catalog aliases are authoritative and
   are not defects merely because raw JSON uses different field names.
6. Use a shared test-only ready-profile builder to update tests affected by the new
   onboarding contract. Do not hide regressions behind unmarked legacy fixtures.

Acceptance must exercise actual viewport hit-testing at control coordinates. A
known-good control and original-STOP-overlay negative control first validate the
harness. Headless `Viewport.push_input` and rendered `Input.parse_input_event`
evidence must be distinguished. Neither proves OS-delivered Android Back. Never use
private handlers, signal emission, mouse capture or Windows control to substitute
for this interaction test.

## M9B: battle print queue and progression

The following architecture decisions are based on inspection of
`unified_battle_state.gd`, `unified_battle_rules.gd`,
`unified_battle_cycle_coordinator.gd`, `unified_ai_opponent.gd`,
`unified_rules.gd`, `v3_profile_state.gd`, and GameManager's launch/settlement paths.

### Pure rule and state boundaries

- Keep the existing five internal phases and the approved Plan -> Run Cycle UI.
- Define catalog-driven legality/queue projections in the rule boundary and reuse
  them in bot decisions and native disabled reasons. UI and AI must not each invent
  their own queue capacity, price, socket, or unique-mod rules.
- Serialize a print-cycle identity, total budget, remainder, and resolved flag per
  seat/turn. Calculate once upon entering Print. Required decisions consume only
  the remainder; returning to Print does not refill it. A jam consumes that cycle's
  work budget once. Separately authored bonus progress does not reset base speed.
- Queue every non-spell type with stable job identity, original cost, minimum-one
  print turns, and required reservation data. Only a spell resolves immediately.
  Validate before any hand/currency mutation, including copied/reprinted jobs.
- Reservations prevent overfilling queue/installed hardware caps and duplicate
  unique effects while jobs wait. Cancel/reject/completion releases reservations
  exactly once. Preserve authored refund economics.
- Creature completion retains the finite raw -> awaken -> walk-to-slot receipt.
  Equipment completion produces holding, then a separate compatible target decision;
  it never auto-attaches to a stale preselected creature. Ring targets the printer.
  Traps need explicit replacement decisions, and the bot must handle each pending
  decision deterministically without fallback stalls.
- Keep both public snapshots and visual receipts free of opponent hand/deck/trap
  identity. Queue and field are public; ownership and mastery snapshots cannot mutate
  when the profile changes after launch.
- The user approved the separate pacing correction on 2026-09-04: multiply only an
  exposed-printer strike by ten. Preserve unit-versus-unit damage, printer HP2000,
  Reinforced Chassis +500, defender-first targeting and the no-fatigue rule. New
  full-match tests must exercise the unified authority, not legacy battle tests.

### XP and permanent-mod boundary

- Add a small pure progression module rather than duplicating XP formulas in main,
  cards, Market and battle state. The existing UnifiedRules facade may expose it.
- Migrate additive wallet/lifetime/mastery fields idempotently, preserving all old
  profile fields and legitimate ownership/decks. Reconstruct legacy earned Spool XP
  using the checked level formula; never regrant on repeated ensure/load.
- One confirmed result ID settles the exact authored base win/loss coins and XP
  once. Existing Trial/Training first-clear and drop/quest extras remain separate.
  Keep duplicate receipt payloads and profile revisions stable. Do not trust UI
  predicted rewards or use wall-clock randomness for outcomes.
- XP spending is a GameManager atomic rule transition with expected next tier,
  cap, print/ownership prerequisites and receipt identity. Native UI previews use
  the same integer projection that battle construction applies.
- Permanent mods use highest owned track tier, not the sum of all historical tier
  entries. Existing stable IDs retain effects; new tiers require the previous one.
  Snapshot base speed, capacity, FIFO and Pre-Print allowance at launch. In-battle
  Upgrade Cards are separate queued hardware and retain their five-installed cap.

### UI integration and validation

- Reuse the physical Market cabinet, folio inspector, printer instruments and
  battle holding tray. Do not add unrelated app-style panels or bake dynamic text.
- Surface exact base/next effect, price, XP wallet, prerequisites, cap/owned state,
  rejection reason and Back; preserve 56px primary targets and scroll reachability.
- Until M9C approval, unavailable equipment printable art/models have an explicit
  unavailable presentation. Do not restore the retired humanoid suit or present a
  creature sprite as equipment. Gameplay card identity may use existing approved
  card art while its new model family remains pending.
- Cover every non-spell type, a spell, duplicate IDs, queue carryover/pause/resume,
  equipment holding, empty/full sockets, trap replacement, unique reservations,
  cancellation, reload, no-mutation rejection, deterministic bot results, exactly-once
  base/extras rewards, migration, tier caps and all mod tracks.
- Run actual-control fresh onboarding -> legal deck -> bot battle -> result -> Market
  -> purchase/upgrade. Capture 576x1024, 720x1280 and a tall Android aspect, including
  representative 150% text, high contrast, reduced motion and keyboard focus.

## M9C: real printable assets

Existing 24 approved creature sprite/raw/v2-blueprint identities remain authority.
No GLB existed at the entry baseline. Use three volume pilots (quadruped, winged,
coiled), then the full 24-creature and 11-equipment roster. New equipment is creature
barding and socketed gems, never a humanoid suit. Candidate inferred depth studies
must not replace approved silhouette authority or masquerade as measured views.

The installed E:-based Concept Fitter is available; its current schema is
quadruped-specific. A family-aware project adapter must represent absent limbs
explicitly rather than invent dummy geometry to satisfy the old schema. Each final
ID needs editable controls/source, full-volume mesh, matched-camera fit evidence,
triangle/material/bounds metrics, pivots and fitting anchors, `.blend`/`.glb`, asset
hashes, and original-resolution review. A billboard is not a 3D model, and a GLB alone
does not establish watertight manufacturing readiness.

## Milestone handoff

At each verified milestone root reviews the diff for maintainability and performance,
sends substantive fixes/refactors back to Terra, obtains required visual approval,
stages only owned files, and commits. Export a commit-qualified non-overwriting
portrait arm64 Android review APK without AdMob. Verify metadata, signing, version,
package contents and launch/input evidence. Deliver APK and README to the observed
`H:\My Drive\AI Projects\PrintForge` folder; compare exact byte size and SHA-256.
DriveFS copy verification and cloud-visible synchronization are separate claims.
