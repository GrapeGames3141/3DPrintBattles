# Native Battle acceptance plan — 2026-09-13

Status: **IMPLEMENTATION-READY TEST PLAN; NO NATIVE TEST PASS IS CLAIMED.**

Authority is the approved
[`team-prototype-native-ui-plan-20260912.md`](team-prototype-native-ui-plan-20260912.md)
and registered geometry/input ownership in
[`team-prototype-battle-ui-registration-20260912.md`](team-prototype-battle-ui-registration-20260912.md).
Primary already corrected target-row wording to distinguish **Active**, **Ready**,
existing **Printing**, and same-Plan/default **Next**. This plan adds no mechanic,
balance change, art approval, or release claim.

## Feature acceptance boundary

- **Entry:** A compatible prototype runtime exposes an Applied Team 3/3, Support Kit
  15/15, and either a valid preflight or one durable current match.
- **Player decision:** Start/Resume, select optional fabrication and at most one
  Support or swap, Run Cycle, Skip/Back/Retry, and Continue a terminal Result.
- **Result:** Native controls send canonical checked inputs; presentation consumes the
  projected receipt/cursor; terminal reward is displayed exactly once.
- **Failure:** Rejected Start/Run/cursor storage keeps the last accepted authority,
  request identity, cursor, and wallet and exposes Retry/Back.
- **Disabled:** No UI-derived rules, rival-private data, second tactical choice,
  authority replay, printer targeting, forfeit, reward claim, or current-match replace.
- **Feedback:** Native copy shows checked forecast, exact blocked reason, current
  presentation stage, Resume state, HOLD/replacement, and fixed Result reward.
- **Progression:** Back, Skip, reload, Retry, and Result replay never alter permanent
  ownership or duplicate battle reward.

## Required native tests

1. **Preflight Start and Resume**
   - Valid Applied 3/15 exposes **Start Battle**. One activation calls
     `MatchSession.start(request_id, expected_sequence, collection_revision,
     fingerprint, seed)` and produces one ledger write.
   - Fail that store: remain in preflight with sequence/current unchanged. Retry the
     same attempted input and accept once. A nonterminal or presentation-pending
     current match exposes only **Resume Battle** or **Resume Result**.

2. **Canonical Plan identities**
   - Fabrication stores `player:member:<member_id>` in `fabrication_id`; a hand owner
     stores its projected `copy_id` in `support_copy_id`; a Ready bay stores canonical
     `swap_id`; gear target stores canonical `equipment_target_id`.
   - **Clear Plan** clears all four local fields with zero authority/store calls.

3. **Optional and default fabrication**
   - With a living Active, omitted `fabrication_id` remains optional for a legal
     Support-only, swap-only, or empty Plan.
   - With an empty field, submit omission to `Rules.check_view_plan`; use only its
     returned `plan.fabrication_id`. If blocked, preserve empty fabrication and show
     `forecast.default_fabrication_reason` as `default_need_filament` or
     `default_capacity_blocked`; the legal no-choice **Run Cycle** stays enabled.

4. **Equipment target authority**
   - Obtain the explicit or legal-default canonical fabrication ID from the checked
     Plan, then call `Rules.eligible_equipment_targets(view, card_id,
     fabrication_id)`. Target controls equal that array exactly in order and identity.
   - Do not expose an unaffordable/capacity-blocked omitted default. Label returned
     targets Active, Ready, Printing, or Next from projected status/context.

5. **Equipment modal cancellation**
   - Initial Suit/Gem tap is provisional and the sheet exclusively owns input/focus.
     Back/Cancel clears provisional `support_copy_id` and `equipment_target_id`, writes
     nothing, and restores source focus.
   - Choosing one returned target finalizes both. Retapping the finalized card clears
     it without reopening the sheet.

6. **One tactical choice**
   - Any selected Support disables Ready swap hits; any selected Ready swap disables
     all hand hits with the accessible reason `Choose 1 Support or 1 swap.`
   - The UI never sends a Plan with both nonempty `support_copy_id` and `swap_id`.
     Tapping the selected owner clears it and restores the other class.

7. **Hand, content, and privacy**
   - Render at most four own projected hand copies. Exercise all five TeamBattleData
     IDs: `raw_filament`, `heated_spool`, `standard_full_suit`, `iron_gem`, and
     `forge_surge` without relying on the incomplete historical BattleCatalog table.
   - Rival UI renders only `hand_count` backs. Card/copy IDs, draw order, target, and
     pending Plan never appear in rival text, accessibility names, or UI metadata.

8. **Checked forecast only**
   - Every local change calls `Rules.check_view_plan` and renders returned
     `available_filament`, `complete_cost`, `post_spend_filament`,
     `next_regeneration`, `new_jobs`, `head_before`, `one_work_completion`, and exact
     failure/default reason.
   - At filament 8 plus Heated Spool, Available is 9, never 11. UI performs no resource
     arithmetic and makes no promise about hidden rival choices.

9. **Run commit and rollback**
   - One **Run Cycle** calls `MatchSession.run_cycle(match_id, request_id,
     player_plan)`; MatchSession alone obtains the rival Plan. Disable Plan input once
     the receipt is accepted.
   - Fail the Run ledger store: retain the same opening authority and wallet with no
     pending receipt/cursor. Identical Retry accepts once; changed duplicate input
     rejects.

10. **Receipt opening and fabrication stages**
    - At accepted Run cursor 0, battlefield roots equal `pending_receipt().receipt.opening`,
      never the already-resolved `view().player` authority.
    - Queue consumes `fabrication_queued`/`equipment_queued`. Print uses only
      `print_work.work_before` to `work_after` for each seat's current head. Living art
      begins only on `awaken_ready` with `work_remaining == 0`. `companion_entered`
      moves that same sprite to Active/Ready; equipment uses `equipment_fit` or
      `equipment_fizzled` and never a creature Awaken or duplicate destination sprite.

11. **Finite stage cursor and Back**
    - Drive Queue, Print, Awaken, Enter/Fit, Swap, Spell, AttackLock, Damage, Traits,
      Defeat, Replace, Result, and nonterminal Plan in receipt order. Empty stages
      acknowledge immediately.
    - Each accepted `acknowledge(match_id, request_id, cursor)` writes one small cursor
      and zero ledger/profile data. Back writes nothing; Resume returns to the same
      match/request/cursor without a Rules call or replay of durably acknowledged stages.

12. **Cursor failure, Retry, and Skip**
    - Reject an acknowledgement after its end pose: show **Progress Paused** with
      Retry/Back, retain the exact expected cursor, and do not advance visually.
      Retry writes once and continues.
    - Reject a later cursor inside `skip(match_id, request_id, cursor)`: retain partial
      accepted progress, then continue from that cursor. Authority and reward remain
      unchanged and no full ledger write occurs.

13. **HOLD and automatic replacement**
    - If either Active is absent, projected `hold` events produce no lunge or damage;
      native feedback says both sides hold while waiting for an opposing Active.
    - A `replacement` event moves exactly the named Ready identity into Active,
      preserving HP, gear, and root identity with no player prompt or duplicate sprite.

14. **Terminal Result and Continue**
    - Real Win/Loss/Draw terminal Runs atomically expose one existing
      `current_result()` reward: 30 coins/40 XP, 10/20, or 20/30. Result rendering,
      opening, Skip, and Back perform no reward action.
    - **Continue** acknowledges the final Result cursor only. Fail that cursor store:
      keep **Resume Result**, block New Battle, and retain the settled reward. Retry
      succeeds once; duplicate Continue/reopen adds zero reward. Only a completed
      Result cursor permits the later New Battle preflight.

## Evidence required for acceptance

Record exact native pointer/key actions, request IDs, callback/write counts, projected
receipt/cursor values, authority/wallet before and after injected failures, and route/
focus outcome. Cover normal, reduced-motion, 150% text, high contrast, visible Back,
and `ui_cancel`. These future results must cite isolated test evidence; this document
alone is not runtime, Android, device, or visual acceptance.
