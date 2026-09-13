# Team prototype file boundary — primary plan

2026-09-12. Downstream of accepted Collection and Match Session authorities. This
plan does not authorize implementation before the Match Session slice passes.

## Scope and ownership

One Terra writer owns new `scripts/team_runtime/team_prototype_store.gd`,
`scripts/team_runtime/team_prototype_runtime.gd` and focused synthetic-file tests.
No edits to legacy SaveService journal/pack persistence or gameplay normalization.
The prototype entry can later call this facade with SaveService's already-selected
profile path and the read-only compatibility result. Do not open actual player
saves during tests. Primary owns the audited runner and validation checkpoint.

## Store contract

- Explicit constructor path must be absolute after `ProjectSettings.globalize_path`,
  with a nonempty JSON basename. Derive adjacent `.team-match.json` and
  `.team-cursor.json` paths from that exact basename. Never infer a profile from
  another directory, use the legacy journal, or share a global cursor.
- Read is zero-write. Missing files and present malformed/null files differ.
  Preserve invalid primary/temp/backup evidence; no startup repair, grant, deletion,
  or normalization. Reject future schemas and unsafe compatibility states.
- Each file has separate `.tmp.json` and `.backup.json` paths. A write validates the
  candidate with its authority before I/O, writes/flushes a temp, closes and reads
  it back, and requires JSON-value equivalence plus validator success. Failure
  before primary promotion leaves the prior authority and backup usable.
- Windows replacement uses checked renames: retain a validated previous primary
  as backup, promote validated temp, and restore the previous primary on promotion
  failure. Never report success until reading the promoted primary proves it is
  the candidate. Never delete the only valid snapshot. Keep failures' temp/evidence
  for diagnosis. If rollback itself fails, fail closed with explicit recovery state;
  do not continue accepting mutations using uncertain disk authority.
- A valid backup with missing/corrupt primary is a read-only recovery state, not
  permission to overwrite the primary. Existing backup recovery UX may display
  the reason; prototype has no destructive New Maker/reset action in this slice.
- A stale valid cursor for another known match/request follows Coordinator rules
  and may be ignored. Malformed/current-mismatched cursor rejects. Cursor files
  contain only the bounded cursor checkpoint, not profile or match history.
- Keep exact disk-generation bytes/hash checks around commits so an external
  modification since read rejects rather than overwriting newer data. These checks
  occur at transactions, not per animation frame. Re-read through the facade to
  recover from a benign stale generation; never merge authority heuristically.
- File operation failures must be testable through an injected small operation
  seam or explicit test-only backend. Production has one direct file backend;
  tests do not patch player paths or globally change SaveService configuration.

## Runtime facade

- Open validates raw profile through CollectionProjection and creates the accepted
  CollectionSession and MatchSession with the store callbacks. A clean install
  may keep `{}` in memory; the first explicit Collection action creates the first
  profile. No legacy `ensure`, coin floor, pack grant, migration, or save on open.
- The store's Collection callback writes only the candidate profile. After accepted
  Collection requests, refresh MatchSession's collection snapshot read-only.
  Future Team Apply does not mutate a frozen match roster or its Kit.
- Battle Start/Run write only the match ledger and settle rewards there. Cursor
  acknowledgement writes only its small sidecar. No profile-wallet mutation,
  journal append, or animation-triggered grant.
- Route Back and app background do not mutate authority. The UI keeps its last
  accepted request identity for a retry after a failed store. A successfully saved
  pending first-print voucher resumes the same print; grant/Apply retries use the
  Collection receipts. Presentation timing can restart without replaying grants.
- Native settings remain a separate explicit user save action, preserving unknown
  profile values; opening Settings, changing routes or resizing never writes.
  Settings persistence should be added only with the bounded UI settings slice,
  not by weakening Collection action validation here. After a successful settings
  profile write, recreate the CollectionSession from that accepted profile and
  refresh MatchSession's collection snapshot read-only. Never leave a stale private
  Collection profile that could overwrite the new settings on the next action.
- Expose narrow views/actions/error state, no public full-history per-frame polling.
  Reuse the accepted authority classes; do not duplicate validation or battle rules
  in the facade. Cache the active session until an explicit reload is necessary.
- Avoid RefCounted ownership cycles between runtime, sessions, Coordinator and
  bound persistence callbacks. Use weak-owner dispatch or an explicitly verified
  disposal boundary; repeated open/close and failed-open fixtures must release
  objects and file handles without relying on application exit.

## Evidence

Use unique `adapter-fixtures` directories beside the runner's `qa-save` directory;
the startup `qa-save` manifest must remain unchanged. Test missing/open/read
zero-write, first Collection action, five-action starter-to-Applied sequence,
Start/Run/cursor JSON reload, terminal reward exactly once, corrupt/null/future
files, valid-backup read-only state, stale file generation, and injected failures
at temp open/write/validation, backup, primary promotion, post-read and rollback.
Assert profile/ledger/cursor write separation and untouched journal/pack sentinels.
Run one complete deterministic match through actual synthetic-file storage.

Primary reviews diff, focused fault evidence and maintainability before committing.
This slice alone is not native UI or Android validation.

## Gameplay-design save-safety audit

The plan preserves the accepted M2 lifecycle and has no unresolved product choice
after applying these fail-closed clarifications:

- Treat `{}` as a clean install only when the profile primary and all prototype
  ledger/cursor primaries, temps, and backups are absent. A missing profile with any
  prototype sidecar evidence, a cursor without a ledger/current match, or a ledger
  history without its originating profile is an orphaned recovery state. Preserve the
  evidence, expose recovery copy, and permit no Collection, Start, Run, cursor, or
  reward write; never silently pair old battle history with a new profile.
- Before Battle Start commits the ledger, recheck both the profile generation that
  supplied Collection revision/fingerprint and the ledger generation. This check is
  required even though Start writes no profile. An externally changed profile rejects
  the Start as stale rather than freezing an obsolete Team/Kit. Later Run and cursor
  operations use the immutable Start roster and do not rebind to Collection.
- Validate the ledger first, then apply the separately loaded cursor only against that
  exact current Coordinator snapshot. A missing cursor is safe and resumes from the
  cursor retained in the full snapshot; a valid older-match/older-request cursor may
  be ignored only under the accepted Coordinator rule. A malformed or current-receipt
  mismatched cursor is recovery, never a reset to zero.
- Back and app background perform no opportunistic save. They leave the last accepted
  full snapshot and cursor durable, so **Resume Battle** returns to the same match.
  “Presentation timing can restart” applies to the starter-print presentation only;
  battle presentation resumes its stored cursor and never replays acknowledged stages.
- Retain the last *attempted* request identity after a failed store so an identical
  retry is possible. Do not label the rejected transition accepted, and do not publish
  its candidate in memory. There is still no abandon, forfeit, reward claim, or new
  Start until terminal presentation has completed.
- A terminal Run keeps Coordinator authority, fixed reward delta, and prototype wallet
  total in the one ledger candidate/write. Cursor and Result presentation remain
  separate and cannot grant. The adapter must never split terminal authority and its
  reward across files or repair one from the other.

Focused fixtures must include the three orphan combinations above, an external profile
change immediately before Start, an external ledger change immediately before cursor
write, and missing/old/current-invalid cursor cases against the same ledger snapshot.
These are save-safety requirements within the existing scope, not new gameplay or a
human approval gate.
