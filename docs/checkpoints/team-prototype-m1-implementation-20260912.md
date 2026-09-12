# M1 Battle Core implementation checkpoint

Status: implementation authorized by the user's 2026-09-12 approval of M0 at
`ae8ad71`. Rules authority: [design](../design/team-prototype-20260912.md), F3–F7.
This checkpoint is a deterministic core, not a playable/release build.

## Inspected boundary and ownership

`GameManager._ready` currently loads then normalizes v3 through `UnifiedRules.ensure`,
possibly persisting a new profile, repairs, or Android review coins. A screen-level
selector cannot prevent those writes. `SaveService` already owns the validated
`--qa-save-root` guard and read-only load/backup inspection; preserve that boundary.
Legacy BattleState/UnifiedBattleState have incompatible HP, phase, and deck models;
do not reuse their constructors or alter their effects/catalog.

The sole Terra runtime writer owns `scripts/team_battle/`, new GDScript/scenes in
`tests/team_battle/`, and the narrow early prototype branch in
`scripts/core/game_manager.gd`. Following the documented first-run harness failure,
primary owns the non-runtime `tools/run_team_battle_tests.ps1` verification harness
and invented JSON startup fixtures, as well as approval/checkpoint metadata, review,
staging and commits. The audited harness may be invoked by Terra for isolated
validation; direct engine launches and concurrent engine tests remain prohibited.
No art promotion, main-scene rewrite, export, or actual player
save access in M1. Existing unrelated files and untracked assets are preserved.

## Decision-complete implementation

1. Add pure, explicitly preloaded RefCounted modules: prototype data, state, rules,
   bot and coordinator. Data owns four common rows, five Support rows and exact
   recommended Kit; names/art can later resolve through existing catalog IDs.
   Use integer-only seeded shuffle, fixed ordered arrays, seat-scoped member/job/card
   identities and versioned snapshots. Constructor validates exactly three unique
   eligible IDs per side and 15 eligible Supports; a deliberately named test-only
   1v1 factory uses the same authority. Never silently accept malformed loadouts.
2. State keeps one Active and at most two Ready reserves, each unique roster
   identity's status/HP/landed attacks/gear, finite draw/hand/discard and queued cards,
   FIFO including head, filament, cycle/revision and terminal receipt. Snapshot
   restore validates types, integer ranges, ownership/card conservation and status/
   slot/queue consistency before publishing; do not trust serialized derived stats.
3. Rules validate both composite Plans against the same opening snapshot before any
   mutation. Exact keys and native failure reasons reject stale/unknown/extra choices.
   Filament arithmetic is `min(cap, opening + aid) - costs`; capacity checks count
   both new jobs. Default highest-priority fabrication applies when Active/Ready are
   empty and the entire composite is legal; otherwise a no-choice Plan may Run when
   fabrication is temporarily blocked by insufficient filament or FIFO capacity, to
   replenish or advance exactly one existing work unit. Corrupt or permanently
   inconsistent state rejects instead of entering that escape path. Resolve the locked
   14-step order from F4, one FIFO work/no carry.
   Pending equipment moves out of hand at commit into its job, then discard at fit
   or fizzle; immediate cards discard at commit. Suit replaces armor with eight,
   not +8 stacking; its slot remains occupied after armor is depleted. Mossmunk's
   trait adds two to current armor capped at eight, never resurrects or adds a slot.
   Gem replaces the gem slot (+2 derived attack, no stacking). Player replacement and
   repeated pending jobs for the same slot are legal: each FIFO fit sets Suit armor to
   exactly eight or the Gem modifier to exactly +2, never a sum; the bot still chooses
   only empty slots. Forge Surge applies to the post-swap Active attack in that cycle,
   consumed even without a target. A landed attack includes a legal hit fully absorbed
   by armor; HOLD is not landed. Lock damage as
   `floor((base attack + Gem 2) * Surge multiplier)`, then add Cinderpaw's +2 on each
   third landed attack before simultaneous damage. That locked bonus survives a lethal
   simultaneous return hit. After damage, Aquafin clamps its heal to base HP and only
   heals above zero, Voltwig obeys the filament cap, and Mossmunk may gain trait armor
   without occupying an empty equipment slot.
4. Player equipment intent includes an explicit same-seat roster target. All eligible
   targets are exposed by a pure query for later native UI selection; no resolution
   modal. Bot target order and tactical tie-breaking follow F7 exactly. Bot receives
   only an own-private/opponent-public projection, never full authority or player Plan.
   Forecast exposes own effects and hidden-choice uncertainty, not rival pending data.
5. Coordinator prepares a deep candidate plus stable ordered event receipt, calls an
   injected persistence callback once, and only publishes after success. M1 default
   store is explicit in-memory test storage, not GameManager/profile mutation.
   Duplicate request IDs return the existing receipt without reapplying; stale event
   acknowledgements do not advance another receipt. Presentation cursor/duration is
   separate from authority; normal, reduced motion, skip and resume consume the same
   receipt. Save/load during pending presentation must not rerun rules or settlement.
   Win/Loss/Draw settles once, no rewards in M1, no postterminal gameplay.
6. Add internal `--team-prototype`/`team_prototype` feature selection immediately after
   existing QA storage/path setup and before legacy initialization. It reads the
   existing v3 snapshot into memory unchanged, marks corruption/backup recovery
   read-only, and never initializes a namespace/grant/repair/review floor. M1 QA uses
   the internal switch with test scenes; enabling the exported entry and replacing
   navigation belongs to M3. No user-facing legacy selector is introduced.

## Verification and cleanup

Use Godot 4.7.1 direct hidden/headless launches, explicit isolated E-based QA roots,
logs and PID ledgers. Record root/descendant IDs, executable/start identity and window
handles/titles; inspect post-run for task-owned crash/error windows and survivors.
Only recorded task descendants may be stopped, with identity rechecked. Preserve
failure evidence. Do not run on actual saves or launch the interactive game.

Tests cover 1v1 and 3v3; atomic failed composites; all five Supports; finite hand,
FIFO/capacity/no carry; once-only fabrication/deployment; repeated swaps preserving
identity/gear/HP; replacements; equipment targets/fizzle; empty-active default and
regeneration; simultaneous final KO and nonresurrecting traits; bot privacy/legality;
snapshot validation, save-failure rollback, duplicate receipt/ack and deterministic
trace equality across reload/presentation modes. Synthetic legacy invalid-deck and
ownership snapshots plus backup/journal/sidecars stay byte-identical on actual
prototype startup; a clean root remains without a newly written profile.

Acceptance includes: a third Cinderpaw hit with Gem and Surge has the exact locked
integer result and still lands when Cinderpaw dies in the same beat; a fully absorbed
legal hit advances its counter while HOLD does not; Aquafin cannot heal above base HP
or from zero; repeated queued Suit/Gem fits replace rather than stack; Mossmunk's
trait armor leaves an empty equipment slot eligible; and an empty Active with an
unspent member plus a full temporary FIFO can Run without choice, advance one work,
avoid early defeat, and auto-select fabrication at the first later legal Plan. A
corrupt equivalent rejects. The named test-only 1v1 factory alone uses one configured
identity while production constructors require three; authority loops use the
configured roster count so simultaneous final KO settles one 1v1 Draw and only the
third-member final KO settles the equivalent 3v3 result. If either seat's checked Plan
is invalid, neither seat changes any field: filament, hand/deck/discard, FIFO, roster,
priority, cycle, revision, terminal receipt, and event/presentation cursor all remain
unchanged.

Run F7's 45 deterministic bot matches, seeds 0–44; report median/p95/max actual
cycles, first print/contact, replacements, Support/swap use, Draws and terminal
causes. A 500-cycle harness stop is a failure, never a result. No claimed pacing
threshold until the user's ambiguous “12–2” wording is clarified.

After tests: primary reviews diff and an independent read-only contract/maintenance
audit, sends substantive fixes to Terra, reruns checks and commits exact files.
M2 collection receipts and M3 native UI/Android are still subsequent work.
