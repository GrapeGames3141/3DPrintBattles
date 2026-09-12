# M2 collection and first-session grant plan — 2026-09-12

Status: **NOT STARTED — DECISION-COMPLETE PLANNING ONLY; NO IMPLEMENTATION,
RUNTIME EVIDENCE, RELEASE AUTHORITY, OR PLAYER-SAVE ACCESS.**

Rules authority: [solo team prototype](../design/team-prototype-20260912.md), F1–F2.
M2 begins only after M1 is accepted. This checkpoint does not relax the approved
visual gate, portrait-only scope, native dynamic-text rule, active no-AdMob contract,
or deterministic receipt boundary.

## Scope and preservation boundary

M2 may inspect only the loaded v3 snapshot and an additive, versioned
`team_prototype` namespace. Legacy 0.7 files, importers, profiles, and migration paths
are entirely out of scope. M2 never calls `V3ProfileState.ensure_base`,
`UnifiedRules.ensure`, ownership migration, catalog aliases, legacy starter/deck
repair, or the existing v3 grant/print helpers. It does not read an actual player save
in QA.

Every explicit M2 transition prepares a deep candidate, invokes persistence once,
and publishes only after success. Namespace-local revision and receipt identities are
the only counters M2 advances. Every preexisting top-level field and value—including
legacy revision, onboarding, cards, blueprints, printed models, decks, coins, RNG,
and receipts—remains structurally unchanged.

## M2.1 — typed read-only v3 ownership projection

- **Entry:** A readable loaded v3 Dictionary is available before any prototype
  collection transition.
- **Player decision:** None; this is a pure eligibility projection.
- **Result:** Missing `owned_blueprints`, `owned_cards`, or `printed_models` fields mean
  empty. For an eligible ID, effective License is raw `owned_blueprints[id] == true`,
  a positive raw creature/equipment `owned_cards[id]`, or a namespaced license.
  Effective Printed is a valid raw printed-model record whose `blueprint_id` is the
  exact eligible ID, or a namespaced printed instance. Effective Support count is a
  nonnegative raw `owned_cards[id]` count plus the namespaced granted count.
- **Failure:** A present ownership field of the wrong type, a malformed relevant
  eligible entry, or an unknown/malformed preexisting `team_prototype` schema fails
  closed with an exact reason and no write. A printed model proves Printed, not
  License; a missing License is handled only by an explicit grant transition.
- **Disabled:** Type coercion, default insertion, aliasing, normalization, repair,
  import, inferred legacy starter selection, and mutation through legacy helpers are
  unavailable.
- **Feedback:** Preview names the raw or namespaced source of each effective License,
  Printed companion, and Support count without exposing unrelated profile data.
- **Progression:** Projection grants nothing and does not create `team_prototype`.

## M2.2 — checked starter binding and guaranteed commons

- **Entry:** No valid namespaced starter binding exists, projection succeeded, and the
  player has selected Cinderpaw, Aquafin, or Voltwig.
- **Player decision:** Inspect the three eligible starter blueprints and confirm one
  immutable choice once.
- **Result:** One checked transition creates the versioned namespace, binds the chosen
  starter, and adds its namespaced License only when effective License is absent. It
  immediately supplies the approved guarantees—Cinderpaw -> Aquafin + Mossmunk;
  Aquafin -> Voltwig + Mossmunk; Voltwig -> Cinderpaw + Mossmunk—adding each missing
  License and one namespaced preprinted instance only when that companion is not
  already effectively Printed. Stable grant and instance IDs derive from the
  namespaced request/receipt, never the legacy RNG nonce.
- **Failure:** Invalid/stale choice, bad schema, projection failure, ID collision, or
  persistence rejection changes nothing and grants no entitlement.
- **Disabled:** Reselect, reroll, a second starter binding, random replacement, legacy
  onboarding inference, and duplicate guaranteed prints are disabled after binding.
- **Feedback:** Native receipt preview distinguishes preexisting, License added,
  Preprinted added, and already Printed for each named companion.
- **Progression:** Guarantees top up only absent entitlements. Existing ownership is
  preserved and no pack, purchase, RNG roll, or legacy deck is involved.

## M2.3 — exactly-once visible starter voucher print

- **Entry:** A valid bound starter has an available namespaced voucher and no settled
  starter-print receipt.
- **Player decision:** Begin the free print in the real empty Workshop bed, then let
  the print/awaken presentation complete or resume it after interruption.
- **Result:** Checked Begin atomically changes the voucher from available to consumed
  and records one stable pending print/receipt identity. Checked completion adds
  exactly that namespaced starter print and settles the receipt. The chosen starter
  always fabricates this one new visible voucher print even when it was already
  effectively Printed; this is the deliberate grant, not a missing-ownership top-up.
- **Failure:** Begin persistence failure leaves the voucher available. Completion
  persistence failure leaves the same pending print resumable. Reload, duplicate
  Begin/completion, stale callback, Skip, or replay reuses the same identity and never
  adds a second print or consumes another voucher.
- **Disabled:** A second voucher, paid debit, hidden instant completion, reroll,
  reclaim, duplicate printer bed, and another starter print request are disabled.
- **Feedback:** Native states read License, Voucher available, Printing, Printed, and
  Team-ready. Existing ownership never suppresses the visible voucher print.
- **Progression:** Presentation duration changes no authority. Repeated prints of one
  creature never create another Team identity because Team uniqueness is by companion
  ID, not print-instance count.

## M2.4 — missing-only Support top-up and final grant receipt

- **Entry:** The bound starter's checked voucher completion is ready to publish and no
  final team-grant receipt exists.
- **Player decision:** None beyond completing the already-bound voucher print.
- **Result:** The same completion candidate computes each deficit once against the
  effective union and adds only `max(0, target - effective count)` to namespaced
  Support grants: 3 Raw Filament, 2 Heated Spool, 3 Standard Full Suit, 3 Iron Gem,
  and 4 Forge Surge. It adds the stable starter print, Support deficits, consumed
  voucher, and immutable final receipt through one persistence callback before
  receipt presentation. The recommended Kit references exactly those target 15
  copies even when effective ownership exceeds them.
- **Failure:** Stale ownership revision, malformed projection, arithmetic/type error,
  receipt collision, or persistence rejection publishes none of the candidate.
- **Disabled:** Negative top-up, reduction of excess legacy ownership, full-kit grant
  on top of existing copies, a second top-up, and later receipt replay are disabled.
- **Feedback:** The receipt lists existing count, namespaced delta, and final effective
  count for every Support ID plus the exact named starter and guarantee outcomes.
- **Progression:** Later acquisition or dismantling cannot replay the frozen top-up.
  Receipt acknowledgement and presentation grant nothing.

## M2.5 — additive namespace and compatibility preservation

- **Entry:** An explicit checked starter, voucher, receipt, or Team/Kit transition has
  produced a valid candidate from the current namespace revision.
- **Player decision:** Commit only through that transition's named action; previews,
  Back, and Cancel do not enter persistence.
- **Result:** Persistence adds or replaces only the known `team_prototype` namespace
  at its expected namespace-local revision. A successful reload reproduces binding,
  voucher/pending print, entitlement deltas, receipts, and saved Team/Kit exactly.
- **Failure:** Namespace version mismatch, unknown namespace fields/state, stale
  namespace revision, request-ID payload mismatch, save rejection, or reload
  validation failure leaves the published snapshot unchanged. An unknown or malformed
  preexisting namespace is never overwritten with defaults.
- **Disabled:** Top-level schema/revision updates, legacy-key edits, normalizer/import
  calls, destructive migration, namespace auto-creation during startup, and actual
  player-save QA are disabled.
- **Feedback:** Exact failure copy identifies namespace/schema/revision or persistence
  cause without proposing a legacy repair.
- **Progression:** Successful namespace transitions are additive. Every other
  preexisting top-level value remains structurally equal before and after.

## M2.6 — atomic Team and recommended Kit Apply/Cancel

- **Entry:** The final team-grant receipt exists and effective ownership contains at
  least three distinct eligible Printed companion IDs plus the recommended Supports.
- **Player decision:** Draft exactly three unique companion IDs, choose first
  fabrication and reserve order, inspect the recommended 15-card Kit, then Apply or
  Cancel.
- **Result:** One Apply validates three unique effectively Printed eligible IDs,
  verifies priority is their exact permutation, and verifies Kit counts are exactly
  15 eligible owned copies. On one successful persistence call it replaces only the
  namespaced saved Team, priority, and Kit and advances namespace revision. It
  consumes no card, print, License, or permanent inventory.
- **Failure:** Duplicate, unprinted, unknown, or unsupported companion; wrong priority;
  wrong Kit count; stale ownership/namespace; or save failure changes no field.
- **Disabled:** Apply is disabled unless Team is 3/3 unique and Kit is 15/15 eligible.
  A fourth creature, duplicate companion ID backed by multiple prints, ineligible
  Support, partial Team-only save, legacy deck/team rewrite, and implicit Apply are
  unavailable.
- **Feedback:** Native preview shows Team 3/3, Kit 15/15, first/reserve order, exact
  card counts, eligibility sources/reasons, and the namespace-only before/after diff.
- **Progression:** Cancel, Back, preview, and failed Apply are zero-write. A later valid
  Apply may replace the saved namespaced loadout but cannot replay collection grants.

## Acceptance fixtures required before implementation can be accepted

### Primary implementation clarifications after independent design audit

- Projection returns a canonical ownership fingerprint of the relevant eligible
  raw ownership values plus current namespace revision. Numeric JSON integer
  normalization, stable Dictionary key ordering and retained array order follow
  the M1 canonical JSON contract. The fingerprint is a concurrency token, not
  anti-cheat. Every mutation supplies expected namespace revision and fingerprint;
  recompute from the current source and reject stale input without writes. This
  does not add a legacy counter or persist projection defaults.
- Every mutating action uses a bounded action/request identity and canonical
  payload. Retain the exact input identity and immutable result. An exact duplicate
  returns that result without persistence or grants, even after later transitions;
  the same identity with a changed payload rejects. Validate new requests against
  current revision/ownership only after checking previously accepted duplicates.
- Onboarding has the durable sequence available voucher -> printing -> settled
  unacknowledged grant -> acknowledged. Starter binding is immutable. Receipt
  acknowledgement is one namespace-only transition with one persistence call and
  revision advance, no grant or loadout effect. Its exact duplicate is zero-write.
  Reload routes to the corresponding state and never reopens starter selection.
- First-session completion supplies the recommended loadout as a native editable
  draft; it does not implicitly Apply. The player explicitly Applies Team, priority
  and Kit atomically before battle. Back/Cancel keeps the grant and discards only
  unsaved draft changes, never consumes ownership or writes an empty saved Team.

These resolve implementation ambiguity only and add no gameplay or approval gate.

1. All-empty v3 ownership produces one bound starter License, the two mapped License
   and missing-print guarantees, one available voucher, then exactly one visible
   namespaced starter print and the exact Support deficits.
2. Chosen starter already License-only and already Printed+Licensed both still execute
   exactly one voucher print; the existing item is untouched. A guaranteed companion
   already Printed but missing License receives only the License.
3. Zero, partial, exact, and excess legacy Support counts produce only nonnegative
   missing deltas and one immutable final receipt. Replaying after collection changes
   never tops up again.
4. Reload at available, printing, completion-failed, settled, and acknowledged stages;
   duplicate and payload-mismatched request IDs; stale callbacks; and Skip/reduced
   motion prove exactly one voucher, print, top-up, and receipt.
5. Missing ownership fields project as empty. Wrong-typed or malformed relevant v3
   entries and unknown/malformed existing `team_prototype` fail unchanged without
   defaults, aliases, repair, import, or legacy 0.7 access.
6. Team/Kit valid Apply, Cancel, Back, duplicate printed-instance attempt, stale
   ownership, wrong counts, and persistence failure prove atomic namespace-only
   behavior. Each successful transition asserts structural equality for every
   preexisting top-level key/value other than `team_prototype`.

No M2 implementation, runtime test, screen capture, Godot invocation, build, export,
or release work is authorized by this planning checkpoint.
