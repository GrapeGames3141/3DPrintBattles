# M2 runtime link — bounded implementation interface

Primary inspection/plan, 2026-09-12. Implements the already approved F2/F3/F6/F7
semantics; no new battle rules, art direction, Market, ads or profile migration.
The pure Collection core and Battle Coordinator remain the authority owners.
The gameplay designer's companion checklist is `team-prototype-m2-runtime-design-20260912.md`.

## Ownership and scope

The sole Terra writer owns new `scripts/team_runtime/team_match_session.gd`,
`scripts/team_runtime/team_match_ledger.gd`, and
`tests/team_battle/test_team_match_session.gd/.tscn` for this slice. Primary owns
the audited runner and review/checkpoint/commit metadata. No UI, export, art,
GameManager, SaveService, legacy code, or actual player save changes in this slice.
File persistence and UI wiring follow after the injected-store boundary passes.

Use a separate versioned prototype battle ledger beside the v3 profile in the later
file adapter. This keeps the accepted `team_prototype` Collection namespace schema
unchanged and preserves all legacy profile fields. Proposed durable filenames are
`<profile-stem>.team-match.json` and `<profile-stem>.team-cursor.json`, with their own
validated temp/backup files. Never reuse the legacy journal or pack UI sidecar.
Ledger coins/XP are prototype-earned totals, initially zero, not legacy wallet edits.

## Pure ledger schema

Exact version1 envelope: `version`, `next_match_sequence`, `current`, `starts`,
`rewards`, `coins`, `xp`. Missing ledger means an empty in-memory envelope, with
sequence1, empty maps/current and zero wallet; creation must not persist defaults.
An explicitly present null, malformed/future schema or bad cursor fails closed.
Pass an explicit `ledger_exists` flag so missing and invalid null are distinct.

`current` is empty or the exact production 3v3 Coordinator snapshot. Retain the
full current match receipts. When a completed/presented match is followed by a new
Start, replace only `current`; retain compact historical Start/reward records.
There is never more than one unfinished match.

`starts` is keyed by bounded request ID. Each immutable record contains original
canonical input (`expected_sequence`, Collection revision/fingerprint, `seed`),
and result (`match_id`, `sequence`, `seed`, `tutorial_opening`, player/rival priority
and expanded kits). Match IDs derive from the sequence: `tp-match-<sequence>`.
Sequences are unique/contiguous, and `next_match_sequence = starts.size() + 1`.
Every older match must have a reward record before a later match can exist.

`rewards` is keyed by match ID, with exact result, terminal receipt ID, final
authority revision/cycle, and coin/XP deltas. No free-form grants. Current terminal
reward must agree with the Coordinator authority. Older records agree with a known
Start and the fixed reward table. Coins/XP equal the sum of all deltas, using safe
whole JSON integers. Unknown keys/types, duplicate sequence/identity, invalid sums,
or nonterminal reward combinations reject without repair or persistence.

Canonicalize only the ledger/cursor/request data; never normalize raw profile
values recursively. Reuse existing canonical helpers where their contract fits.
On external restore, validate `current` once through Coordinator.restore with the
supplied cursor and production shape; never rerun Rules to validate/reward it.
Trusted new Coordinator candidates do not need a second full receipt-history
restore on every Run; validate the owned envelope/ledger arithmetic and publish
only after the injected store confirms literal Boolean true.

## Session API and behavior

`create(raw_profile, compatibility, ledger_exists, ledger, cursor,
persist_ledger, persist_cursor)` returns a session or exact error, never writes.
Require valid callbacks. Compatibility must explicitly be ready/compatible;
future schema, corrupt/recovered backup and other unsafe load states reject.
CollectionProjection validates the retained deep profile snapshot. No legacy helper.

`update_collection(raw_profile, compatibility)` is a read-only refresh of the
private Collection snapshot following a separately committed Collection action.
It validates before publication and does not modify the current battle. It is not
a grant or save API. UI may change the saved future Team while an active match
continues using its immutable starting roster/Kit.

`start(request_id, expected_sequence, collection_revision, fingerprint, seed)`:

- Check canonical duplicate identity before current freshness. An exact accepted
  Start returns its immutable original result with zero writes, including after a
  later match has started; it never replaces the current match. Changed input under
  the same ID rejects. Bound IDs to the Coordinator's 96-character grammar.
- New Start requires current empty or terminal with presentation complete, a valid
  explicitly Applied Collection loadout, matching revision/fingerprint/sequence,
  and a seed in State's supported range. Pending/nonterminal match says Resume.
- Player roster uses saved priority order and expanded saved Kit counts. Rival
  starter is `STARTERS[seed % 3]`, followed by its approved two common guarantees;
  rival Kit is the recommended15. Tutorial opening is true only for sequence1.
- Build State through create_production, then Coordinator.create. Its Start
  callback prepares one ledger candidate containing current, immutable Start and
  advanced sequence. One store write publishes all or nothing. Creation of any
  rejected candidate must not consume a sequence or replace the active match.

`run_cycle(match_id, request_id, player_plan)`:

- UI supplies only its own Plan. A new request obtains the bot Plan from only
  Coordinator.view("rival") and passes both Plans to the Coordinator exactly once.
- For an already recorded current-match request ID, use its stored rival Plan so
  the Coordinator can compare the original player/rival inputs even after authority
  advanced. Do not ask the bot to regenerate a prior choice. Changed player input
  rejects; stale match ID rejects before any Run/store/reward work.
- The Coordinator's `run` persistence callback prepares one ledger candidate with
  the new snapshot. If terminal, add that match's reward and update totals in the
  SAME write: Win30/40XP, Loss10/20XP, Draw20/30XP. Result uses the actual existing
  State result strings, with explicit mapping to native Win/Loss/Draw presentation.
  Store failure leaves Coordinator, ledger, rewards and wallet unchanged.
- Animation completion, Skip, Result opening and reload never grant rewards.
  Exact duplicate Run performs zero ledger/cursor writes and returns its receipt.

`acknowledge` and `skip` delegate checked identities/cursors to Coordinator. Its
`cursor` callback writes only the small current cursor checkpoint, never the full
ledger/profile. Preserve successful partial Skip acknowledgements if a later cursor
write fails. Keep the latest in-memory checkpoint only after its store succeeds.
Well-formed older-match/older-request checkpoints follow Coordinator's safe ignore
rule; malformed/current-mismatched hashes/revisions fail closed on restore.

Expose narrow read-only views: current player view, current pending projected receipt
and cursor/stage count, resume availability, wallet and current/historical result.
Do not expose rival private hand/Plans through UI helpers. Internal deep `snapshot`
may exist only for tests/persistence, never per-frame animation polling. Back merely
leaves the route; it suspends neither authority nor a grant transaction, invents no
forfeit, and does not abandon or replace the resumable match. There is no separate
reward acknowledgement transaction; terminal presentation cursor is the gate for
starting a later match.

## Required evidence

Use synthetic profiles and injected stores under the existing audited headless
runner. No file I/O or player saves here. Prove:

1. Create/read/preview zero-write; ready versus corrupt/future/recovered compatibility;
   missing versus null/future/malformed ledger/cursor. Profile bytes unchanged.
2. Explicit valid Applied3+15 Start; rejected/stale/unapplied Start; store rollback;
   all starter mappings/seeded rival choice; first tutorial versus later ordinary hand.
3. Both-Plan same-snapshot bot isolation, full deterministic match to terminal,
   exact Run replay before/after cursor advancement, changed ID payload, stale match.
4. Terminal state and the correct Win/Loss/Draw delta appear atomically, exactly once;
   failed terminal store leaves the prior state/wallet intact and retry settles once.
   Use real deterministic fixtures for all outcomes, not an injected fake reward API.
5. JSON save/reload with missing/current/old/invalid cursor, partial Skip failure,
   complete-result new Start, old Start replay after a later match, active Resume and
   immutable current roster after future Team Apply. No repeated Rules settlement.
6. Full ledger writes only at Start/Run; cursor writes stay small and do not include
   profile/history. Invalid historical reward sums/Start chains reject on restore.

Freeze implementation after passing this slice, report exact commands/evidence/PIDs
and cleanup, then wait for primary review. No new APK or Drive copy from this task.
