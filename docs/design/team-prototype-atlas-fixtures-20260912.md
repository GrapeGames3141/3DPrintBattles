# Team prototype M0 atlas fixture registry — 2026-09-12

Status: **ILLUSTRATIVE, DECISION-COMPLETE M0 AUTHORING FIXTURES; NOT RUNTIME OR
VALIDATION EVIDENCE.**

Authority: [solo team prototype](team-prototype-20260912.md). This registry fixes the
meaning of atlas states so the offline concept cannot invent a fourth creature,
present an Unspent member as deployed, or add another commit action. It adds no new
gameplay rule or balance target.

## Registry conventions

Both seats use exactly three seat-scoped identities for the whole battle fixture:
**Cinderpaw (C), Aquafin (A), and Mossmunk (M)**. A branch may start from a named
checkpoint, but never substitutes Voltwig or another fourth identity.

Status shorthand is `U` Unspent, `P` pending fabrication, `A` Active, `R` ready
Reserve, and `D` Defeated. Each `C/A/M` cell lists all three identities in that order.
The atlas must show all three native status records at every battle state. Only `A`
and `R` own living battlefield figurines. `U`, `P`, and `D` remain visible native
roster/status records; they do not occupy Active or Reserve bays. A `P` member is
labelled `Queued` while another job is FIFO head and `Printing` only when its roster
job is head. Only the head job owns printer art: a gear head shows gear, not the queued
creature. Blueprint/status choice tokens may appear in an otherwise empty bay as UI
records, but may not imply ready living occupancy.

Filament notation is `opening + aid - checked costs = post; next N`, where `next N`
includes the next Plan's +2 regeneration and the cap of 9. During Run and Result,
`post/next` repeats the already-committed values; presentation frames never spend a
second time. Each seat has a private checked Plan, but the two Plans are evaluated from
the same opening snapshot without private-plan peeking.

## Fixed battle sequence

| Atlas state | Cycle / phase | Player C/A/M | Rival C/A/M | Checked fabrication; Support or swap | FIFO after commit / during frame | Filament player; rival | Run Cycle |
|---|---|---|---|---|---|---|---|
| `preflight-empty` | C1 Plan | U/U/U | U/U/U | None yet; none | Empty; empty | P `5; next 7`; R `5; next 7` | Disabled until first fabrication is selected |
| `choose-first` | C1 Plan | U/U/U | U/U/U | P `C`; Raw Filament. R `C`; Raw Filament | Preview P `C`; R `C` (aids are immediate, not FIFO jobs) | Both `5 +2 -3 = 4; next 6` | Allowed; this is the sole commit |
| `print-early` | C1 Run | P/U/U | P/U/U | Locked from `choose-first` | P `C head, early`; R same | Both `post 4; next 6` | Disabled; resolution in flight |
| `print-60` | C1 Run | P/U/U | P/U/U | Locked | P `C head, 60% presentation`; R same | Both `post 4; next 6` | Disabled; resolution in flight |
| `raw-body-complete` | C1 Run | P/U/U | P/U/U | Locked | P `C head, raw-body presentation`; R same | Both `post 4; next 6` | Disabled; resolution in flight |
| `awaken` | C1 Run | P/U/U | P/U/U | Locked | P `C completion/awaken presentation`; R same | Both `post 4; next 6` | Disabled; resolution in flight |
| `first-entry-active` | C1 Result | A/U/U | A/U/U | Settled | Empty; empty | Both `post 4; next 6` | Disabled until next Plan opens |
| `combined-second-plan` | C2 Plan | A/U/U | A/U/U | P `A`; Standard Full Suit -> C. R same | Preview P `A -> Suit(C)`; R same | Both `6 -3 -2 = 1; next 3` | Allowed; atomic two-job Plan |
| `second-print` | C2 Run | A/P/U | A/P/U | Locked | P `A head -> Suit(C)`; R same | Both `post 1; next 3` | Disabled; resolution in flight |
| `reserve-1-entry` | C2 Result | A/R/U | A/R/U | Settled | P `Suit(C) head`; R same | Both `post 1; next 3` | Disabled until next Plan opens |
| `third-plan-behind-gear` | C3 Plan | A/R/U | A/R/U | P `M`; none. R same | Existing `Suit(C)` then preview `M`; same for R | Both `3 -3 = 0; next 2` | Allowed; capacity is 2 of 3 |
| `equipment-auto-fit` | C3 Run | A/R/P | A/R/P | Locked | P `Suit(C) head` (gear art) -> `M Queued` (no creature art); R same | Both `post 0; next 2` | Disabled; one FIFO work resolves Suit only |
| `equipment-fitted` | C3 Result | A/R/P | A/R/P | Settled | P `M head` (creature printer art); R same | Both `post 0; next 2` | Disabled until next Plan opens |
| `printing-wait-plan` | C4 Plan | A/R/P | A/R/P | No new choice; none | P `M head` (creature printer art); R same | Both `2 = 2; next 4` | Allowed; Run advances existing work |
| `third-print-awaken` | C4 Run | A/R/P | A/R/P | Locked | P `M head, completion/awaken`; R same | Both `post 2; next 4` | Disabled; resolution in flight |
| `reserve-2-entry` | C4 Result | A/R/R | A/R/R | Settled | Empty; empty | Both `post 2; next 4` | Disabled until next Plan opens |
| `swap-plan` | C5 Plan | A/R/R | A/R/R | P none; swap C <-> A. R none; none | Empty; empty | Both `4 = 4; next 6` | Allowed; Support is unavailable while swap is selected |
| `swap-and-attack` | C5 Run | R/A/R | A/R/R | Locked | Empty; empty | Both `post 4; next 6` | Disabled; swap preserves identity, HP, and gear before attack |
| `swap-result` | C5 Result | R/A/R | A/R/R | Settled | Empty; empty | Both `post 4; next 6` | Disabled until next Plan opens |
| `replacement-risk-plan` | C6 Plan | R/A/R | A/R/R | P none; Forge Surge -> A. R none; none | Empty; empty | P `6 -2 = 4; next 6`; R `6 = 6; next 8` | Allowed |
| `replacement-attack` | C6 Run | R/A/R | A/R/R | Locked; fixture HP makes P Aquafin lose this simultaneous beat | Empty; empty | P `post 4; next 6`; R `post 6; next 8` | Disabled; resolution in flight |
| `auto-replacement` | C6 Result | A/D/R | A/R/R | Settled; C is highest-priority ready replacement | Empty; empty | P `post 4; next 6`; R `post 6; next 8` | Disabled until next Plan opens |

The early, 60%, raw-body, and awaken rows are presentation frames inside the **same
cycle-1 Run**. They are not extra rounds, work units, confirmation points, or evidence
of runtime timing. Likewise, `reserve-1-entry` is deliberately later than the first
entry: the first completed member becomes Active; Aquafin is the first later completion
that enters a Reserve bay.

## Empty-Active and terminal branches

These branches reuse the same three identities per seat. Their starting HP and prior
combat events are fixture setup, not additional atlas-visible roster members.

| Atlas state | Cycle / phase | Player C/A/M | Rival C/A/M | Checked fabrication; Support or swap | FIFO | Filament player; rival | Run Cycle / settlement |
|---|---|---|---|---|---|---|---|
| `empty-active-required` | C7 Plan | D/D/U | A/R/R | P required/default `M` auto-selected; none. R none; none | Preview P `M`; R empty | P `3 -3 = 0; next 2`; R `5 = 5; next 7` | Allowed; sole commit, no extra mandatory selection click |
| `last-member-printing` | C7 Run | D/D/P | A/R/R | Locked | P `M head`; R empty | P `post 0; next 2`; R `post 5; next 7` | Disabled; resolution in flight, not defeat |
| `last-member-active` | C7 Result | D/D/A | A/R/R | Settled | Empty; empty | P `post 0; next 2`; R `post 5; next 7` | Disabled until next Plan; battle continues |
| `empty-active-replenish` | C7 Plan | D/D/U | A/R/R | P `M` option disabled at F2 with no aid; submit no fabrication/support/swap. R none; none | Empty; empty | P `2 = 2; next 4`; R `5 = 5; next 7` | **Allowed:** `Need 1 filament · Run to replenish · next 4` |
| `replenish-run` | C7 Run | D/D/U | A/R/R | Locked legal no-cost Plan | Empty; empty | P `post 2; next 4`; R `post 5; next 7` | Disabled only while resolution runs; player attacks hold, no defeat |
| `replenish-next-plan` | C8 Plan | D/D/U | A/R/R | P required/default `M` auto-selected at opening F4; none. R none; none | Preview P `M`; R empty | P `4 -3 = 1; next 3`; R `7 = 7; next 9` | Allowed; sole commit, no extra mandatory selection click |
| `replenish-last-printing` | C8 Run | D/D/P | A/R/R | Locked | P `M head`; R empty | P `post 1; next 3`; R `post 7; next 9` | Disabled; resolution in flight, not defeat |
| `replenish-last-active` | C8 Result | D/D/A | A/R/R | Settled | Empty; empty | P `post 1; next 3`; R `post 7; next 9` | Disabled until next Plan; battle continues |
| `loss-result-m2` | C9 Result | D/D/D | A/R/R | None | Empty; empty | P `2`; R `7`; next none | Gameplay disabled; settle Loss `10 coins / 20 XP` exactly once |
| `win-result-m2` | C9 Result | A/R/R | D/D/D | None | Empty; empty | P `7`; R `2`; next none | Gameplay disabled; settle Win `30 coins / 40 XP` exactly once |
| `draw-result-m2` | C9 Result | D/D/D | D/D/D | None; both final members fell in one simultaneous beat | Empty; empty | P `2`; R `2`; next none | Gameplay disabled; settle Draw `20 coins / 30 XP` exactly once |

If an atlas sheet intentionally depicts an isolated M1 rules fixture, it must say
`M1 TEST FIXTURE — NO PERSISTENT REWARD`. It must not use generic player-facing copy
such as `no reward in prototype`, because M2 has the provisional settle-once table
above. Terminal states have no next Plan balance.

## First-session receipt fixture

The Cinderpaw starter example has three distinct stages:

| State | Collection truth | Allowed action | Forbidden implication |
|---|---|---|---|
| `starter-confirmed` | Cinderpaw license + unused immediate voucher; Aquafin and Mossmunk permanent licenses and preprinted instances granted | Open the real empty Workshop bed and redeem voucher | Team Ready or a completed starter receipt |
| `starter-printing` | Cinderpaw voucher consumed and receipt pending; Cinderpaw Printing; Aquafin and Mossmunk Printed | Let the existing print/awaken presentation finish or resume it | A second voucher, reroll, or receipt settlement |
| `team-grant-receipt` | Cinderpaw Printed after awaken; Aquafin and Mossmunk Printed; all three licenses present; voucher consumed; recommended Kit `15/15` | Acknowledge the idempotent receipt and continue to Team | `Printing`, an empty bed, an unused voucher, or two more required prints |

The Team/Kit workbench may show all three as **collection Printed**. On battle entry,
all three begin `U/U/U` because match fabrication/deployment is separate from permanent
Workshop ownership.

## Fixture interaction contract

- **Entry:** Load the named state with exactly the statuses, queue, checked choices,
  cycle phase, and filament values above.
- **Player decision:** Only Plan rows accept choices. `Run Cycle` is the sole battle
  commit; Workshop receipt acknowledgement and Team/Kit Apply are not battle commits.
- **Result:** One checked Plan advances to its Run frames and one Result without adding,
  hiding, duplicating, or replacing a roster identity.
- **Failure:** A mismatched status, fourth identity, live mini for `U/P/D`, wrong queue,
  false forecast, premature receipt, or wrong reward makes that atlas fixture invalid.
- **Disabled:** Run is disabled for an invalid checked Plan, throughout Run/Result
  presentation, and after terminal settlement. An unaffordable fabrication option is
  disabled, but the legal no-cost Run remains enabled to reach next-Plan regeneration.
  Run is also enabled for a valid checked Plan and for a no-new-choice Plan that
  advances existing FIFO work.
- **Feedback:** Native status records expose all six seat-scoped identities, selected
  choices, exact queue order, arithmetic, disabled reason, and settle-once result.
- **Progression:** These are static authoring examples only. They grant nothing, mutate
  no save, prove no timing or deterministic runtime behavior, and do not open the M0
  implementation gate.
