# M1 bot and session implementation interface

Primary decision-complete follow-on to the Rules interface. Not implemented or
accepted yet. No new gameplay or human approval gate is introduced.

## Bot

Replace the incompatible draft Bot with `choose_plan(view: Variant) -> Dictionary`.
It accepts only the checked own-private/opponent-public view schema, never State,
receipt, seed or the player's Plan. Return `{ok,plan}` or a native failure. A valid
nonterminal no-choice preview is the baseline validation; every proposed composite
uses the same Rules preview, and the returned public Plan is resubmittable to Run.

Implement F7 literally: highest-priority Unspent fabrication; lowest-gain required
aid (Raw before Heated when either suffices); otherwise low-HP swap, empty Suit
slot, empty Gem slot, Surge with a living attack forecast, spare aid below cap, none.
Ready swap candidate is the highest-priority Ready identity, and its current HP plus
armor must exceed the active's. Low HP uses `2 * HP <= base HP`. Equipment targets
are Active, Ready by priority, then Printing/same-Plan by priority. Slots refer to
current equipped slots; player replacement remains legal. Tie order is hand index,
target priority, card ID. Illegal composite drops tactical and retries fabrication
once, then no fabrication plus first legal tactical, then baseline. No randomness,
private peeking, or alternate hand/deck authority is added.

Bot tests cover the required-aid thresholds, swapping, slot-vs-trait armor, printing
targets, legality fallback, hand-index ties, terminal/malformed/private-input rejection,
input immutability and repeatability. Produce both bot Plans from the opening views
before supplying either to Run.

## Coordinator ownership and public API

Replace the incompatible draft Coordinator. All authority and raw receipts are
private instance data. `create(initial_state, match_id, persist, test_1v1=false)`
and `restore(snapshot, cursor_checkpoint, persist, test_1v1=false)` return a checked
factory result. Start requires revision zero and validates State before accepting it.
Match/request IDs are nonempty bounded identifier strings, not user-facing text.
Production factories never silently accept the test-only roster shape.

Public methods:

- `request(match_id, request_id, player_plan, rival_plan)` prepares one Run.
- `acknowledge(match_id, request_id, expected_cursor)` is an internal automatic
  stage-completion callback, never a player phase action.
- `skip(match_id, request_id, expected_cursor)` consumes the same remaining ordered
  acknowledgements; it changes no authority or result.
- `view(viewer)` and `viewer_receipt(request_id, viewer)` return only validated
  projections. `snapshot()` returns a deep internal persistence snapshot, not UI data.
- `is_busy()` is true while the current receipt cursor is below its stage count.

The coordinator snapshot has an explicit schema version, match ID, origin State,
current authority, ordered request records and current presentation reference/cursor.
Each request record retains its input Plans, canonical input hash, raw Rules receipt
and canonical receipt hash. Hashing uses stable sorted-key JSON, not Dictionary
insertion order; hashes detect corruption, not hostile-save cheating.

Persistence JSON round trips are part of the contract, not only Dictionary clones.
Normalize finite whole-number JSON floats within the State safe-integer bound to
integers before hashing or validating restored records, including Plans, stage
events and cursor overlays. Preserve booleans as booleans; reject fractions,
nonfinite/unsafe numbers and non-JSON objects. Use the same canonical normalization
for fresh hashes and restored hashes, with string-key Dictionaries sorted and
array order retained. This normalization never repairs an invalid schema or value.
Include actual `JSON.parse_string(JSON.stringify(snapshot))` and overlay round-trip
tests at pending Print and Damage and a terminal receipt, not only deep clones.

## Persistence and bounded writes

Use one injected callback `persist(kind: String, payload: Dictionary) -> bool`.
It is called once per accepted transition and before publication. `start` and `run`
carry the complete candidate snapshot. `cursor` carries only match ID, authority
revision, request ID, receipt hash and next cursor. This keeps automatic stage
acknowledgements small: the later storage adapter must not rewrite the growing
complete match/profile for every animation stage. M1 uses explicit in-memory test
stores only; no file, GameManager, live profile or reward mutation is permitted.

Start persists once before returning an initialized coordinator. Run validates both
Plans, prepares the candidate/receipt, validates both viewer projections, calls the
store once, and only then publishes. Store rejection leaves every field unchanged.
The same request ID and input hash returns the original projected result with no
new store/rule call. Reusing that ID with different input rejects. Pending animation
blocks another Run. Terminal authority blocks gameplay permanently for that match.

Cursor acknowledgement is bound to match/request/current cursor. Exact expected
cursor advances one stage only after its small store update succeeds. Older duplicate
or historical-receipt acknowledgements are ignored without writes; future/invalid
cursors reject. Normal, reduced motion and Skip consume the same stages and produce
the same authority and final cursor. Empty stages auto-skip in the later UI driver.
Back/pause resumes an existing receipt; it never invokes Run to reconstruct animation.

One Skip call performs successive cursor transitions, with one small cursor write
per acknowledgement, not one atomic jump and never a full-record rewrite. If a
later write fails, Skip stops and reports that failure at the last successfully
published cursor. Resume/Skip continues from that cursor; already acknowledged
stages and the Rules transition are not repeated. Tests reject the second Skip
cursor write and prove partial progress, unchanged authority and exact continuation.

## Restore and receipt integrity

Restore performs no persistence calls and never reruns Rules or settlement. Validate
the schema, origin/current States, all request IDs/hashes/Plans, ordered revision and
State chains, known stage sequence/shapes, and both viewer projections. Opening and
final receipt States are settled/restorable; intermediate Print/Awaken/Damage/etc.
snapshots use the separate transient projection schema. The latest receipt's final
State must equal the stored authority. Unknown keys, corrupt hashes, mismatched
revisions, impossible cursors and malformed current records fail closed.

A separate valid cursor checkpoint is used only when match/revision/request/hash
match the stored latest receipt. A well-formed checkpoint from an older Run/match
is ignored (a newer full Run may have committed before its first cursor write).
A malformed or out-of-range checkpoint for the current receipt rejects; never silently
replace it. Tests include save failure at Start/Run/cursor, duplicate input, payload
mismatch, pending-input rejection, stale ack, restore mid-Print and mid-Damage, skip,
terminal settlement once, corruption/privacy and identical resumed traces.

## Full-match and maintenance evidence

Run the design's 45 bot matches with seeds 0–44 and the nine ordered starter-team
pairings. Record actual cycle counts, median/p95/max, first print/contact, replacements,
support/swap counts, Draws and terminal causes. A 500-cycle harness stop is failure,
never a game result. No pacing threshold is invented from the unresolved “12–2”.
Also report serialized completed-session size and timing descriptively so the first
maintenance review can identify costly snapshots or duplicated responsibilities.
The approved UI, Collection Link and Android export remain subsequent milestones.
