# Native Battle genuine-runtime fixture recipes — 2026-09-13

Status: **SOURCE-DERIVED IMPLEMENTATION GUIDANCE; NOT AN ENGINE OR TEST PASS.**
These recipes use only the production `TeamPrototypeRuntime`, checked Plans, Store
writes, and projected receipts. They do not authorize fabricated Coordinator
snapshots, direct authority mutation, new mechanics, or a second terminal-outcome
matrix. The separate Win/Loss/Draw fixtures remain authoritative for terminal cases.

## Shared genuine fixture boundary

- **Entry:** Open a fresh explicit QA profile through `TeamPrototypeRuntime.open`,
  complete the accepted starter actions, acknowledge the grant, and Apply the exact
  Cinderpaw Team `[cinderpaw, aquafin, mossmunk]` with the recommended Kit 15/15.
  Start match sequence 1 with seed 0, which supplies the fixed tutorial hand.
- **Player decision:** Submit only canonical Plans through `runtime.run_cycle`; read
  only `runtime.view().match.player` and `runtime.pending_receipt()`.
- **Result:** Every requested state has a real ledger record and viewer-safe projected
  receipt. Use `begin.result.print_id` for starter completion and
  `complete.result.receipt_id` for grant acknowledgement.
- **Failure:** Any failed Collection, Start, Run, Skip, or acknowledgement stops the
  fixture. Never patch a file or in-memory authority to reach the desired stage.
- **Disabled:** Test-only 1v1, direct `Rules.run_cycle`, hand-authored receipts, copied
  terminal authority, and legacy battle state are unavailable.
- **Feedback:** Assertions name the exact canonical event, identity, stage, and
  projected snapshot fact that makes the state player-readable.
- **Progression:** Non-target nonterminal receipts may be skipped through the real
  Runtime. Inspect each target receipt before advancing its cursor.

## F1 — Iron Gem Fit and a Ready swap

- **Entry:** Use the shared sequence-1 Cinderpaw fixture at its first Plan.
- **Player decision:**
  1. Cycle 1: fabricate `player:member:cinderpaw`; play the real tutorial
     `iron_gem` copy targeting that same identity.
  2. Cycle 2: fabricate `player:member:aquafin`; play the real tutorial
     `raw_filament` copy.
  3. Cycle 3: submit an empty checked Plan.
  4. Cycle 4: select swap `player:member:aquafin`.
- **Result:** Cycle 1 queues companion before equipment and enters Cinderpaw without
  fitting the Gem. In Cycle 2 the existing Gem is FIFO head; projected `Enter/Fit`
  contains exactly:

  ```text
  type=equipment_fit
  seat=player
  card_id=iron_gem
  target_identity_id=player:member:cinderpaw
  ```

  Its snapshot has Cinderpaw `gem_slot=true`; absent Forge Surge, the player's
  `attack_locked.damage` is 9. Cycle 3 `companion_entered` makes Aquafin Ready.
  Cycle 4 `Swap` contains `active_member_id=player:member:aquafin` and
  `reserve_member_id=player:member:cinderpaw`; its snapshot makes Aquafin the sole
  Active and Cinderpaw Ready with the same identity, HP, and Gem slot.
- **Failure:** A missing tutorial copy, changed FIFO order, noncanonical target, Gem
  Fit in Cycle 1, Aquafin not Ready after Cycle 3, or lost Cinderpaw state fails.
- **Disabled:** Do not edit the projected hand, inject a Ready member, or fit equipment
  directly. Fabrication remains independent of the one Support-or-swap choice.
- **Feedback:** The Fit stage names Iron Gem and Cinderpaw. The Plan shows Aquafin as
  Ready before swap; the Swap stage names both incoming and outgoing companions.
- **Progression:** Gem remains one persistent match slot and the swap moves the same
  living identities; neither action changes permanent Collection ownership.

## F2 — Defeat and automatic reserve replacement

- **Entry:** Continue from F1 after Cycle 4 with at least one real Ready reserve.
- **Player decision:** At each editable Plan use
  `Bot.choose_plan(runtime.view().match.player)`, submit that checked Plan, and inspect
  its projected receipt before Skip. Stop at the first **nonterminal** receipt that
  contains both `Defeat` and `Replace` events.
- **Result:** Let defeated identity be `Y` and replacement identity be `Z`. The
  `Defeat` snapshot has `Y.status=Defeated`, `Y.hp=0`, and no Active for that seat.
  `Z` equals the first Ready member in that Defeat snapshot's priority. The later
  `replacement` event names the same seat and `Z`; its snapshot makes only `Z`
  Active while `Y` remains Defeated.
- **Failure:** Terminal settlement before a qualifying replacement, mismatched seats,
  replacement before Defeat, a non-priority replacement, or resurrected `Y` fails.
- **Disabled:** Do not lower HP, change priority, mark a member Ready, or synthesize
  receipt events. This fixture does not assert Win/Loss/Draw.
- **Feedback:** Defeat names `Y`; Replace says `Z` replaces the defeated Active.
- **Progression:** Continue only after recording stage order `Defeat -> Replace` and
  the preserved roster identities.

## F3 — genuine HOLD after an unaffordable default

- **Entry:** Start a separate shared Cinderpaw sequence-1/seed-0 fixture. Never select
  reserve fabrication. Keep the player's post-spend filament low with real legal
  cost-2 Supports while the sole Active fights. A deterministic source-derived
  candidate sequence is: Cycle 1 Cinderpaw + Iron Gem; Cycles 2 and 3 Forge Surge;
  Cycles 4 and 5 Standard Full Suit; Cycle 6 the next Forge Surge; Cycle 7 the next
  Iron Gem targeting Cinderpaw. The seed-0 tutorial/draw order derives from
  `TeamBattleState._seeded_shuffle`; Terra must verify the resulting combat boundary
  in the actual Runtime.
- **Player decision:** Stop only when the real view has no Active, no Ready member,
  at least one surviving Unspent/Printing roster member, and opening filament below
  fabrication cost 3. Submit an empty checked Plan.
- **Result:** The check remains legal with empty `plan.fabrication_id` and
  `forecast.default_fabrication_reason=default_need_filament`. Its `AttackLock`
  contains exactly two `hold` events—one per seat—with the same `beat_id`; `Damage`
  has no events and neither figure lunges.
- **Failure:** If the fixed candidate does not reach that exact public boundary under
  the current deterministic rival policy, continue with the same invariant-driven
  method—no reserve fabrication and only real legal spending—or fail the fixture.
  Never accept a terminal state or mutate authority to force HOLD.
- **Disabled:** No HP edits, filament edits, injected FIFO, fake save, direct Rules
  call, attack animation, or damage event is allowed.
- **Feedback:** Native copy reads `Waiting for an opposing Active companion. Both
  sides hold.` The blocked default explains that filament is needed for the next
  companion.
- **Progression:** The following legal cycles may replenish filament and fabricate
  the surviving roster member normally; HOLD is neither defeat nor a timeout.

## F4 — receipt-only filament rail

- **Entry:** A Run is durable and a projected receipt stage is being presented.
- **Player decision:** Watch, Skip, Back, Resume, or Retry the existing cursor.
- **Result:** While resolving, the rail shows only `Filament N` from the **currently
  displayed projected opening/stage snapshot** `own.filament`, plus existing stage
  event feedback. It omits Spend, After, and Next. At an editable Plan, restore the
  four rows from that Plan's real `Rules.check_view_plan` forecast.
- **Failure:** A missing projected snapshot shows unavailable/paused feedback; it
  never falls through to settled `runtime.view().match.player` for forecast values.
- **Disabled:** Calling `controller.checked_plan()` against already-final authority
  during receipt playback, recomputing receipt forecasts, adding schema fields, and
  inventing future rival/resource promises are unavailable.
- **Feedback:** The resource number changes only when the displayed projected stage
  says it changed; stage feedback continues to explain Queue, Print, HOLD, and Fit.
- **Progression:** Receipt presentation advances only its cursor. Forecast display
  cannot reveal or alter a future Plan, authority, reward, or wallet.

## Source anchors

- `scripts/team_battle/team_battle_state.gd`: tutorial opening, canonical copies and
  deterministic shuffle.
- `scripts/team_battle/team_battle_rules.gd`: FIFO work, equipment Fit, swap, HOLD,
  Defeat, replacement, default fabrication, and projected stage order.
- `scripts/team_battle/team_battle_projection.gd`: allowed viewer-safe event fields.
- `scripts/team_battle/team_battle_bot.gd`: checked deterministic continuation Plans.
- `tests/team_battle/test_team_battle_core.gd`: direct rule-level Fit/swap/replacement
  precedents only; the native fixtures above must still pass through Runtime/Store.
