# M2 runtime link product semantics — 2026-09-12

Status: **DECISION-COMPLETE DESIGN CHECKLIST FOR THE BOUNDED M2 RUNTIME LINK.**
This applies the already user-approved F2, F3, F6, and F7 rules from the
[solo team prototype contract](../design/team-prototype-20260912.md). It introduces
no new human approval gate. The implementation boundary is defined separately in
[`team-prototype-m2-runtime-interface-20260912.md`](team-prototype-m2-runtime-interface-20260912.md).

This slice links the accepted Collection projection/session to the accepted
production `TeamBattleCoordinator`. It owns match lifecycle and the provisional
prototype reward receipt only. It does not add or change battle rules, Market,
packs, upgrades, ads, IAP, backend services, legacy currency, UI art, or the
portrait visual gate.

## Locked preservation boundary

- The accepted `team_prototype` Collection namespace and its strict schema remain
  unchanged. Battle state and rewards use a separate adjacent, versioned team-match
  ledger.
- Existing profile fields and values, including legacy coins, XP, decks, ownership,
  receipts, RNG, and history, remain structurally unchanged. Prototype-earned coins
  and XP are separate totals beginning at zero; this slice does not spend them.
- At most one current production 3v3 match exists. Its Coordinator snapshot and
  current presentation cursor are durable and restorable. Full match authority is
  saved only at Start and Run; animation acknowledgement writes only the small cursor.
- A current match is never silently replaced. Back leaves it resumable, and the
  Battle entry reads **Resume** until its terminal presentation is complete.
- Win grants 30 coins and 40 XP; Loss grants 10 coins and 20 XP; Draw grants 20 coins
  and 30 XP. The terminal Run stores authority, reward record, and new prototype
  totals atomically and exactly once.

## R1 — compatible preflight is read-only

- **Entry:** Prototype startup has a readable, explicitly compatible profile;
  Collection projection exposes an explicitly Applied Team 3/3, priority permutation,
  and eligible Support Kit 15/15; no current match requires Resume; and the route has
  an explicit supported deterministic seed.
- **Player decision:** Inspect the saved Team, first-fabrication/reserve priority,
  Kit, deterministic rival notice, and seed, then choose **Start Battle** or **Back**.
- **Result:** Preflight validates Collection revision/fingerprint, ledger version,
  sequence, production roster shape, Kit expansion, and seed without constructing or
  persisting a match. Start remains a separate checked transition.
- **Failure:** Missing/unapplied/invalid loadout, stale Collection projection, invalid
  seed, malformed/future/null ledger or cursor, corrupt/recovered/future compatibility
  state, or invalid Coordinator data returns an exact recovery/preflight reason and
  performs zero writes.
- **Disabled:** Start is disabled while validation fails or any current match is
  nonterminal, presentation-busy, or terminal-but-not-fully-presented. There is no
  repair, default Team Apply, legacy normalization, alternate battle route, abandon,
  forfeit, or reward claim on preflight.
- **Feedback:** Native copy shows Team 3/3, Kit 15/15, first/reserve order, seed, and
  either **Start Battle**, **Resume Battle**, or the exact blocking reason. Back from
  a clean preflight returns to the prior route.
- **Progression:** Opening, refreshing, cancelling, or backing out of preflight writes
  nothing, consumes no match sequence, does not mark the tutorial used, and grants no
  reward.

## R2 — checked Start freezes one deterministic match

- **Entry:** R1 passes, no unfinished/current-busy match exists, the next match
  sequence and Collection revision/fingerprint match, and the player commits **Start
  Battle** with one bounded request identity.
- **Player decision:** Start the inspected matchup. The Team and reserve priority were
  chosen through the earlier explicit Collection Apply; Start does not edit them.
- **Result:** One persistence write publishes one production 3v3 Coordinator snapshot,
  one immutable historical Start record, and the advanced sequence. Player roster
  order is the saved priority order; player Kit is the exact saved 15-copy expansion.
  Rival selection is deterministic from the explicit seed:

  | `seed % 3` | Rival priority order |
  | ---: | --- |
  | 0 | Cinderpaw, Aquafin, Mossmunk |
  | 1 | Aquafin, Voltwig, Mossmunk |
  | 2 | Voltwig, Cinderpaw, Mossmunk |

  The rival uses the recommended 15-card Kit. The first accepted Start only—match
  sequence 1—uses the locked tutorial opening of Raw Filament, Standard Full Suit,
  Iron Gem, and Forge Surge. The current State factory applies that opening to both
  seats; the rival hand remains private. Every later sequence uses the ordinary
  seeded finite-Kit draw.
- **Failure:** Stale sequence/revision/fingerprint, unsupported seed, ID collision,
  invalid State/Coordinator candidate, or store rejection leaves the sequence,
  current match, Start history, tutorial eligibility, and wallet unchanged.
- **Disabled:** A second current match, new seed against an active match, random rival
  reroll, tutorial-opening replay after sequence 1, test-only 1v1 construction, and
  replacing a resumable match are unavailable.
- **Feedback:** Successful Start opens the battle with the frozen player/rival roster
  and match ID. Failure keeps the inspected preflight and names the stale, schema,
  loadout, or persistence cause. Reload identifies the same match as resumable.
- **Progression:** Sequence 1 is consumed only by a successfully persisted Start. An
  interrupted first match stays the first match and keeps its tutorial opening on
  Resume; because there is no abandon path, it must reach and present its result
  before sequence 2 can start. An exact historical Start replay returns its original
  immutable result with zero writes and never changes whichever match is current.

## R3 — Run Cycle and presentation resume the same authority

- **Entry:** The current match is nonterminal at a Plan boundary and has no pending
  presentation stages. The UI supplies only the player's revision-bound Plan.
- **Player decision:** Choose the one allowed composite Plan and press **Run Cycle**;
  during finite presentation, optionally use reduced motion or **Skip**. Back may
  leave the route at any point after the already-committed authority is durable.
- **Result:** The session derives the rival Plan from the rival's checked private view,
  then supplies both Plans once to the Coordinator. A successful Run persists the
  resulting complete Coordinator snapshot before publication. Acknowledgement and
  Skip advance the existing ordered receipt using only the small durable cursor;
  neither reruns Rules nor reconstructs a receipt. Reload/Resume continues from the
  last successfully stored cursor with the same match, seed, rosters, FIFO, hands,
  authority revision, receipt, and result.
- **Failure:** Illegal/stale Plan, changed duplicate payload, rival-policy failure,
  wrong match/request/cursor, full-store rejection, cursor-store rejection, or corrupt
  restore changes no uncommitted authority. A partially successful Skip stops at the
  last persisted cursor and remains resumable from there.
- **Disabled:** Input while presentation is busy, a second Run, manual phase advance,
  Rules replay on restore, regenerated rival choice for an old request, full-ledger
  writes per animation frame, and cursor writes containing profile or receipt history
  are unavailable.
- **Feedback:** Native status distinguishes Plan, Resolving, Printing, Awakening,
  Entering, Fighting, Replacing, Result, save failure, and **Resume Battle**. Resume
  returns to the current pending stage rather than replaying completed stages. Exact
  duplicate Run returns the original projected receipt without another write.
- **Progression:** Match-local HP, equipment, filament, cards, roster states, and
  receipts do not mutate permanent Collection ownership. Reduced motion, Skip, Back,
  reload, and repeated presentation never alter authority, RNG, reward, or sequence.

## R4 — Back suspends presentation; Team edits affect only a future match

- **Entry:** A current match exists, whether at Plan, mid-presentation, or terminal
  presentation, or the player visits Team/Kit while that match remains current.
- **Player decision:** Use visible/native Android Back to leave the battle route, later
  choose **Resume Battle**, and optionally Apply a different valid Team/Kit for a
  future match from the editor.
- **Result:** Back performs no battle, reward, Collection, or ledger transition. The
  already persisted match remains current and resumable. A separately successful
  Collection Apply may replace the saved future loadout, but the current match keeps
  the immutable roster, priority, Kit, seed, and rival recorded by its accepted Start.
- **Failure:** A failed/stale Team Apply changes neither Collection nor current battle.
  Reload failure or invalid ledger/cursor fails closed to recovery; it never starts a
  replacement match or imports the future Team into current authority.
- **Disabled:** Abandon, concede, forfeit rewards, restart, overwrite-current, resume
  with a new seed, and retroactive roster/Kit edits are unavailable. **Start Battle**
  remains disabled while the current match needs Resume or result presentation.
- **Feedback:** Workshop/Battle navigation visibly reads **Resume Battle**. Team/Kit
  shows that an Apply affects **Next battle** while the current matchup remains named.
  Returning resumes the saved Plan or presentation stage, not a fresh preflight.
- **Progression:** Back, app background/restore, and Team draft Cancel are zero-write.
  A valid future Team Apply follows the already accepted Collection receipt rules and
  grants nothing. The current match's eventual reward is based only on its frozen
  Start and terminal authority.

## R5 — terminal Run settles one reward atomically

- **Entry:** A complete Run Cycle produces the Coordinator's first valid terminal
  player result—`Win`, `Loss`, or `Draw`—and its immutable terminal receipt.
- **Player decision:** None during settlement. After the same Run has persisted, the
  player watches or skips remaining finite stages and views the Result receipt.
- **Result:** The terminal Run's single full-ledger write stores the terminal
  Coordinator snapshot and exactly one reward record keyed by match ID:

  | Result | Coins | XP |
  | --- | ---: | ---: |
  | Win | 30 | 40 |
  | Loss | 10 | 20 |
  | Draw | 20 | 30 |

  The record binds result, terminal receipt identity, final authority revision/cycle,
  and deltas. Prototype coin/XP totals equal the checked sum of all reward records.
  The Result screen is presentation of that settled receipt, not a claim action.
- **Failure:** Store rejection leaves the prior nonterminal Coordinator, reward map,
  and totals unchanged so the identical Run may be retried once. Result/receipt/
  revision mismatch, duplicate or unknown match, invalid arithmetic, malformed history,
  or unsafe integer fails closed without partial authority or currency.
- **Disabled:** Reward on unfinished match, preflight cancellation, Back, abandon,
  forfeit, animation acknowledgement, Skip, Result opening, reload, receipt replay,
  Market multiplier, ad bonus, IAP, legacy-wallet update, and a second settlement for
  the same match are unavailable.
- **Feedback:** Terminal presentation names Team victory, Team defeat, or Draw and the
  exact fixed coin/XP deltas. Resume after interruption completes the same outstanding
  presentation and shows the same receipt; it never shows a second grant animation.
- **Progression:** The reward becomes durable at the terminal authority boundary,
  whether or not its animation has yet played. Exact duplicate Run and all later
  presentation callbacks are zero-reward. The prototype totals are display-only in
  this slice; spending, leveling, upgrades, and Market remain out of scope.

## R6 — terminal presentation gates the next match

- **Entry:** Current authority is terminal and its reward is already settled exactly
  once.
- **Player decision:** Complete or Skip the remaining receipt stages, view the native
  Result, then use its continue/back action. A later Battle entry may start a new
  preflight with the latest valid saved Collection loadout and a new explicit seed.
- **Result:** Until the terminal receipt cursor reaches its exact stage count, Battle
  always resumes that result sequence. Once complete, the terminal match remains the
  current historical source until one successful later Start atomically replaces only
  `current`; its compact immutable Start and reward records remain. A well-formed
  previous-match cursor is safely ignored for the newly started match.
- **Failure:** Missing reward for a terminal current match, reward for a nonterminal
  match, incomplete cursor, invalid Start/reward chain, bad totals, or failed later
  Start keeps the terminal match and history unchanged and prevents the new match.
- **Disabled:** New-match Start before Result presentation completion, dismissing the
  result to bypass its cursor, deleting the old reward, replaying sequence 1 tutorial,
  and using an older saved Team retroactively are unavailable.
- **Feedback:** Before completion the only battle action is **Resume Result**. After
  completion, the route may show **New Battle** and its read-only preflight. Historical
  results and prototype totals are readable but have no repeat/claim control.
- **Progression:** Every earlier Start must have exactly one reward before a later
  sequence can exist. Sequences are contiguous, results are immutable, and totals are
  derived from the ledger, so reload cannot create a skipped match or duplicate reward.

## Decision-complete acceptance criteria

1. Missing ledger creates an empty in-memory view without a write; present null,
   malformed/future ledger, malformed current cursor, and unsafe compatibility states
   reject exactly and preserve profile bytes.
2. Preflight Start/Back proves Back is zero-write and does not consume sequence 1 or
   tutorial eligibility. Only a successful Start consumes a sequence.
3. Seeds covering residues 0, 1, and 2 produce the exact three rival priority rows
   above. Sequence 1 gives both seats the fixed tutorial opening; sequence 2 and later
   use ordinary seeded draw. Save/reload retains the same decision.
4. Active Plan, mid-Print, mid-Damage, partial-Skip, terminal-before-presentation, and
   terminal-after-presentation reload fixtures all Resume the same match, authority,
   receipt, and next cursor without another Rules call.
5. Back at Plan, each presentation phase, and Result is zero-write. No abandon or
   forfeit action exists. Start remains blocked until the terminal cursor is complete.
6. Apply a new valid Team/Kit while a match exists, refresh Collection read-only, and
   prove current roster/Kit bytes are unchanged. After result completion, the next
   successful Start uses the new saved priority/Kit.
7. Real deterministic Win, Loss, and simultaneous Draw fixtures produce respectively
   30/40, 10/20, and 20/30 in the same accepted terminal Run write. Reject that store,
   prove no authority/reward/wallet change, retry, and prove one settlement.
8. Replay terminal Run before and after cursor advancement, reopen Result, reload,
   Skip, and replay the historical Start after a later match; all return immutable
   results with zero additional reward and never replace current.
9. A later Start requires terminal authority, its matching reward, completed
   presentation cursor, current Collection freshness, and the next exact sequence.
   Failure at any check or store leaves current and history unchanged.
10. Restore rejects altered Start inputs/results, noncontiguous or duplicate match
    sequences, missing/extra reward records, terminal receipt mismatch, unknown result,
    incorrect fixed delta, incorrect wallet sum, and a later Start whose predecessor
    lacks a reward. No repair/default path exists.
11. Full-ledger persistence occurs only at successful Start/Run. Cursor persistence is
    small, current-only, and excludes profile and full receipt history. Views expose no
    rival hand or pending Plan and do not request a full snapshot per animation frame.
12. This slice adds no Market, pack, upgrade, ad, IAP, backend, PC, printer-HP,
    40-card, permanent-loss, legacy-wallet, or actual-player-save behavior.

## Product-semantic audit of the implementation interface

The companion implementation interface is product-consistent and has **no blocking
ambiguity** for this bounded pure/injected-store slice:

- Immutable historical Start results are correct: exact replay is a lookup only and
  cannot replace current, consume another sequence, or reopen the tutorial.
- Sequence 1 is the first successfully persisted match, not the first preflight view.
  With no abandon path, interruption always resumes it; sequence 2 is the first
  ordinary seeded opening.
- Back means route/presentation suspension only. It performs no authoritative pause,
  forfeit, reward, or delete transition, and Resume restores the same current match.
- Terminal reward is settled at terminal Run, while terminal presentation completion
  independently gates the next Start. This makes Result replay safe without turning
  the Result screen into a claim button.
- Future Team/Kit Apply remains legal and useful without mutating the current match;
  the next accepted Start rechecks the latest Collection revision/fingerprint.
- The separate team-match ledger and cursor preserve the accepted Collection schema
  and all legacy profile/wallet values.

The later file adapter must still prove validated temp/backup behavior and native
Back/lifecycle integration before UI or Android acceptance. Those are downstream
evidence gates, not unresolved product choices and not permission to release.
