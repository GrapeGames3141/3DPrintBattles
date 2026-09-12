# M2 collection implementation interface

Primary inspection and API plan only. M1 acceptance is a prerequisite; this file
does not authorize early runtime work. Product semantics are in the
[M2 feature plan](team-prototype-m2-collection-plan-20260912.md).

## Inspected integration seams

`GameManager`'s prototype startup already reads the v3 profile before legacy
normalization and returns without writes. Keep it that way. `SaveService` has an
existing validated-temp/backup snapshot path; the prototype adapter will use that
later, without `append_event` or old grant/deck helpers. M2 core tests use injected
in-memory stores and synthetic source Dictionaries, never actual player saves.

`UnifiedRules` has two valid historical printed-record shapes: a starter record
with `blueprint_id` and `source`, and workshop records with additional model/rarity/
nonce fields. Do not require the workshop shape for a historical starter. A raw
print proves Printed only, not License. No catalog alias conversion is permitted.

## Bounded modules and APIs

Use a pure checked collection schema/projection plus a transactional collection
session. Keep UI, file paths, Battle Rules and legacy normalizers out of both.
Names may follow existing project conventions; responsibilities must not duplicate
M1 State/Rules or bury raw profile normalization in an adapter.

- `project(raw_profile)` returns effective eligible ownership, source information,
  namespace revision/fingerprint, current first-session state and saved loadout.
  A missing namespace stays missing. Pure preview never calls persistence.
- `create(raw_profile, persist)` validates and retains a deep private snapshot;
  creation itself is read-only. `snapshot()` is an internal deep persistence copy.
- `request(action, request_id, expected_revision, ownership_fingerprint, payload)`
  validates exact action/payload fields, deduplicates the original input, prepares
  one candidate and immutable native result, persists the complete profile once,
  then publishes. The callback receives only a deep candidate and returns bool.
  Rejected callback leaves all published state unchanged. No optional silent
  success without a valid callback is allowed for writes.
- `preview_loadout(team, priority, kit)` validates eligibility/ownership and gives
  the before/after draft without writes. The later UI owns its local draft;
  Cancel/Back do not need an authority mutation.

All public request numerics are checked, not coerced from booleans/fractions.
Restore accepts safe whole-number JSON numeric forms while preserving legacy
top-level JSON values. Do not recursively normalize or rewrite unrelated fields.
Only the prototype namespace and the relevant fingerprint projection normalize.

## Actions

| Action | Exact payload | Result |
| --- | --- | --- |
| `choose_starter` | `{starter_id}` | Immutable binding, missing licenses/common prints, available voucher |
| `begin_starter_print` | `{}` | Consumed voucher and one stable pending print identity |
| `complete_starter_print` | `{print_id}` | Same print, missing Support deficits, final unacknowledged grant receipt |
| `acknowledge_grant` | `{receipt_id}` | Durable acknowledged state; no ownership/loadout change |
| `apply_loadout` | `{team, priority, kit}` | Exactly3 unique printed companions and exactly15 owned eligible Support copies |

The request's canonical identity includes action and exact payload. Keep its original
expected revision/fingerprint for identity checks: a replay with those original
values returns the immutable result even when the namespace has since advanced;
changed input under the same request ID rejects. Check duplicate identity before
current freshness. Never fabricate a new receipt for a duplicate action.

An independently generated second request cannot grant again: a bound starter
cannot be rebound, the same consumed voucher cannot be consumed twice, and a
completed print cannot add another instance/top-up. Stale receipt acknowledgements
cannot affect a different receipt. New valid Apply requests may change loadout but
do not consume ownership. Receipt presentation has no grant callback.

## Relevant ownership validation

Eligible companions are the four `TeamBattleData.MEMBERS`; eligible Supports are
the five `TeamBattleData.SUPPORTS`. License projection concerns companions and the
two equipment recipes, not aid/spell licenses. For relevant raw `owned_cards`
entries accept only safe nonnegative integer counts. Relevant `owned_blueprints`
entries must be booleans. Missing fields/entries mean zero/false; wrong-typed
present ownership containers fail. Unrelated IDs and values remain untouched.

A historical print record with an exact eligible `blueprint_id` String proves
Printed. It must have a nonempty String instance key; additional historical fields
are retained untouched. Do not infer from aliases, artwork, integer-to-String
conversion, or record names. Unrelated print records are not imported into the
prototype. Recognized malformed eligible records fail with a native reason.

Namespaced grants, prints, receipts and saved loadout have explicit versioned
schemas. Unknown namespace fields/versions and impossible state combinations
reject rather than reset. Stable namespaced IDs cannot collide with raw instances.
Effective ownership is a projection union, never a combined rewritten legacy map.

The grant's recommended Team draft is the chosen starter plus its two guaranteed
commons in the approved mapping order. Kit draft is `recommended_kit()`. Player
Apply remains explicit. Returning to the editor always begins from the saved
loadout when present, otherwise this recommended draft.

## Acceptance and later adapter

Run every fixture in the feature plan, with explicit callback counts, exact
duplicate results, mismatch failures and JSON round trips for each durable state.
After every accepted transition assert that all original top-level keys/values
other than `team_prototype` are structurally unchanged; after failure compare the
entire snapshot. Include zero/partial/exact/excess ownership, preprinted-but-not-
licensed guarantees, previously printed chosen starter, invalid relevant counts,
stale fingerprint, four/duplicate/unprinted Team, ineligible/wrong-sized Kit,
Start/complete/ack/Apply store failures, replay after Apply, and no-write previews.

Battle session storage/rewards is a subsequent bounded M2 adapter task, not an
extra collection action here. Its approved reward table is Win30/40XP,
Loss10/20XP, Draw20/30XP once per match in a namespaced ledger. Do not add Market,
ads, legacy coin edits or an external service while implementing this slice.
