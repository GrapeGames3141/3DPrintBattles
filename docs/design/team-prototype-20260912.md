# PrintForge solo team prototype — 2026-09-12

Status: **USER-APPROVED PRODUCT CONTRACT; bounded numeric values below are explicit
prototype defaults, not final balance.** This document supersedes the proposal-only
status of the matching ideas in `printforge-reboot-proposal-20260908.md` and
`reboot-comparison-20260908/gameplay-audit.md`. It does not authorize runtime work
before the linked preproduction atlas gate passes.

## Locked identity and preservation boundary

PrintForge is a solo portrait-Android game set in the tactile navy/brass/wood
workshop. Player-facing characters are animals and whimsical fantasy printed
figurines—no humans, mechs, or space theme. The core relationship is:

`Blueprint license -> Workshop Print -> Team of exactly 3 unique printed companions -> 15-card Support Kit -> Battle`

Preserve deterministic integer authority, receipt-safe presentation, native dynamic
text, portrait-only layout, the exact card back, the active no-AdMob contract, catalog
and asset identity, and existing profile bytes/history. The prototype is an isolated
mode with additive versioned team/support data. It does not rewrite current catalog
effects, import an old save shape, destroy or auto-migrate existing decks, or retain
printer HP as a second victory system.

Current v3's 40-card minimum, eight-card hand, three simultaneous field slots,
repeat-creature deck, multiple freeform Main actions, and printer-HP victory remain
historical mode behavior, not prototype rules. The historical 12–22 median / maximum
30-round proposal is not a settled target and never becomes fatigue, a timeout, or an
end-cap result; user clarification is pending.

## Tunable prototype defaults

These are implementation defaults chosen to make the first deterministic comparison
possible. They may be tuned from evidence without changing the locked loop, and are
not a blind division of the legacy 40–680 filament economy.

| Item | Prototype default |
|---|---|
| Filament at cycle 1 Plan | 5 |
| Filament cap | 9 |
| Regeneration | +2 at each later Plan opening, before choices |
| Eligible common roster fabrication | cost 3; one print-work unit |
| FIFO work | exactly one work unit per cycle; no unused work carry credit |
| Standard Full Suit | cost 2; one work; +8 ablative armor; one armor slot |
| Iron Gem | cost 2; one work; +2 attack; one gem slot; replacement does not stack |
| Forge Surge | cost 2; this cycle's one attack is 150%, floored; buff is consumed even if no hit lands |
| Raw Filament printer aid | cost 0, gain 2 |
| Heated Spool printer aid | cost 0, gain 3 |
| Hand/deck | four visible; finite 15; draw one at each later Plan if below four; no reshuffle |
| First tutorial hand | Raw Filament, Standard Full Suit, Iron Gem, Forge Surge |

The forecast shows opening balance, regeneration, selected gains and costs, FIFO work,
expected completions, swap/replacement, and projected post-cycle balance. It is not a
promise about hidden rival choices.

### M1 eligible cohort and combat defaults

Only the four current common companions are eligible in the first proof; all other
owned creatures and content remain intact but ineligible until a later explicit
prototype balance row exists. This is not a broad 24-creature content pass.

| Companion | HP | Attack | Automatic every-third-landed-attack trait |
|---|---:|---:|---|
| Cinderpaw | 34 | 7 | +2 damage on that attack |
| Aquafin | 36 | 6 | heal 3 after the simultaneous beat, only if Aquafin survived |
| Voltwig | 30 | 7 | +1 filament |
| Mossmunk | 31 | 5 | gain 2 armor after the simultaneous beat if Mossmunk survived; armor cap 8 |

M1 has no manual abilities, Defense mode, or element multiplier; element identity and
art remain visible. Every locked living attack hits for at least 1 before normal
ablative armor. Both active attacks are calculated from the same beat snapshot and
applied together; only then do stable, non-resurrecting automatic traits resolve.

## F1 — deterministic first-session grant

- **Entry:** A profile without the versioned team-prototype grant receipt selects
  Cinderpaw, Aquafin, or Voltwig.
- **Player decision:** Inspect the three starter blueprints, choose one, confirm once,
  and use its immediate free-print voucher in the real Workshop printer.
- **Result:** The chosen starter gains a permanent license and one visible Workshop
  print. Two additional common companions arrive immediately as usable preprinted
  instances with their permanent licenses: Cinderpaw -> Aquafin + Mossmunk; Aquafin ->
  Voltwig + Mossmunk; Voltwig -> Cinderpaw + Mossmunk. No pack roll gates play.
- **Failure:** Interrupted print, reload, stale confirmation, or save rejection resumes
  the same receipt; it never grants another license, voucher, print, or companion.
- **Disabled:** Reclaim, reroll, duplicate starter confirmation, random replacement,
  and a second grant remain disabled after receipt settlement.
- **Feedback:** Native copy distinguishes License, Voucher, Printing, Printed, and
  Team-ready; the bed starts empty and the starter uses the existing print/awaken
  presentation. The two guarantees are named, not hidden in pack rewards.
- **Progression:** The grant is exactly-once and additive. Existing ownership is
  preserved; entitlement processing tops up only missing approved items and never
  removes or converts cards, licenses, models, coins, XP, decks, or receipts.

## F2 — Team and Support Kit setup

- **Entry:** At least three distinct printed companion IDs and the team grant receipt
  exist.
- **Player decision:** Choose exactly three unique printed companions, select one as
  first fabrication, order the other two as reserve priority, and Apply or Cancel the
  recommended Support Kit.
- **Result:** Team stores three unique IDs and priority. Recommended Kit stores exactly
  15 owned copies: 3 Raw Filament, 2 Heated Spool, 3 Standard Full Suit, 3 Iron Gem,
  and 4 Forge Surge. Filament cards are presented as printer aids. Kit duplicates are
  legal; uniqueness applies only to the three companion IDs.
- **Failure:** Duplicate/unprinted/unknown companion, wrong kit count, unsupported ID,
  stale ownership, or save failure changes nothing.
- **Disabled:** Apply is disabled unless Team is 3/3 unique printed companions and Kit
  is 15/15 eligible cards. Traps, upgrades, resurrection/theft, printer-HP, recovery,
  and queue-denial cards are outside the prototype eligibility table, not deleted.
- **Feedback:** Show Team 3/3, Kit 15/15, first/reserve order, card counts, eligibility
  reasons, and an exact before/after save preview.
- **Progression:** The starter kit receipt tops up deficits to the listed counts once.
  Cancel and preview grant nothing. Later collection edits cannot replay the grant.

## F3 — battle entry and visible field

- **Entry:** Solo bot preflight validates a saved Team 3/3, Kit 15/15, one deterministic
  seed, and prototype schema/version.
- **Player decision:** Confirm first fabrication and reserve priority, or Back without
  mutation.
- **Result:** Each side has one active anchor, two reserve bays, a printer/FIFO of
  capacity three including work in progress, a four-card hand, and three unspent
  roster identities. Only one living figurine occupies each active/reserve position.
- **Failure:** Invalid loadout, bad seed/schema, stale save, or incomplete privacy
  projection returns to preflight with an exact reason and creates no battle receipt.
- **Disabled:** Rival-private kit/hand data, extra field slots, duplicate roster IDs,
  direct printer targeting, and legacy battle intents remain inaccessible.
- **Feedback:** Native states label every member Unspent, Printing, Reserve, Active, or
  Defeated; inward-facing printed figurines remain the visual focus.
- **Progression:** Starting, backing out, or replaying a presentation grants nothing and
  never mutates collection prints.

## F4 — one Plan and automatic Run Cycle

- **Entry:** Authority opens a Plan boundary, applies scheduled +2 regeneration after
  cycle 1, and exposes a revision-bound forecast.
- **Player decision:** Choose at most one unspent roster member for fabrication plus
  at most one Support card **or** one swap, then press **Run Cycle**. Run Cycle is the
  sole committing action; there is no separate Confirm Plan step, phase toolbar, or
  timer.
- **Result:** One atomic composite intent resolves. If Support is equipment, its FIFO
  job follows the selected companion job, its target is locked during Plan, and it
  auto-fits after completion without a modal pause. Equipment does not consume the
  roster-fabrication selection, but it is the sole Support choice. Queue capacity
  counts the active head; a two-job Plan fits only when both slots exist.
- **Failure:** Insufficient filament, queue overflow, spent roster ID, illegal/dead
  target, invalid swap, revision mismatch, or any invalid subchoice rejects the whole
  Plan—no partial spend, queue item, card move, or priority change.
- **Disabled:** A second roster fabrication, second Support, Support plus swap, manual
  phase advance, and inputs during Run Cycle remain disabled with exact reasons.
- **Feedback:** Forecast identifies both queued jobs in order, locked equipment target,
  resource arithmetic, expected completions, and automatic cycle order.
- **Progression:** Plan/Run Cycle state is match-local. Reduced motion and Skip change
  presentation duration only, never revision, result, RNG, resource, or receipts.

Both seats' checked Plans use the same initial public/private snapshot; the bot never
peeks at hidden player hand or choice data. Deterministic Run Cycle order is: commit
both checked Plans atomically in stable seat order; resolve printer-aid gains and
costs; append roster then equipment jobs; advance exactly one FIFO work unit; deploy
or auto-fit completions; resolve selected swaps; resolve immediate spells; lock both
living active attacks; apply same-beat damage together; resolve non-resurrecting traits
in stable `(cycle, beat, seat, source ID)` order; mark defeats; auto-replace; evaluate
terminal state; open the next Plan.

Gear may target a living, currently printing, or same-Plan roster identity. If that
identity is defeated before auto-fit, the gear job fizzles with native feedback and
moves to the finite discard; it creates no manual prompt and does not remove permanent
inventory ownership.

## F5 — once-only deployment, reserves, and swaps

- **Entry:** A roster member completes its sole match fabrication, an active is
  defeated, or a legal swap reaches its Run Cycle beat.
- **Player decision:** Before battle, choose reserve priority. During Plan, optionally
  choose one ready reserve to swap instead of playing Support.
- **Result:** Each roster identity fabricates/deploys at most once. The highest-priority
  ready reserve automatically replaces a defeated active. A swap moves the same living
  unit identities between Active and Reserve before attacks; returning later is not a
  new deployment and requires no refabrication.
- **Failure:** Stale/dead/not-ready identity or a late callback cannot duplicate,
  resurrect, refabricate, reorder, or partially swap a unit.
- **Disabled:** Defeated members, fourth creatures, Emergency Reprint, Blueprint Thief,
  and any re-entry that creates a new identity are disabled.
- **Feedback:** Movement visibly preserves creature identity, HP, equipment, priority,
  and one Active owner. If no reserve is ready, show the next unspent/printing member.
- **Progression:** Defeat and swapping never damage or consume the permanent Workshop
  print, blueprint, equipment ownership, or saved Team.

## F6 — empty Active, defeat, and Draw

- **Entry:** Finish one complete Run Cycle damage/trigger beat, then inspect both teams.
- **Player decision:** None during resolution. At the next Plan, if a side has no Active
  and no ready Reserve but has an unspent member, that highest-priority member becomes
  the required/default fabrication choice.
- **Result:** Unprinted or printing surviving roster members are not defeat. With no
  legal creature target, attacks hold; printers have no HP and take no damage. A side
  loses only when all three roster identities are Defeated. If both third members are
  defeated in the same fully resolved beat, settle Draw exactly once.
- **Failure:** Early result, hidden printer damage, sequential terminal checking inside
  a same-beat exchange, duplicate settlement, or a state with a surviving member but
  no eventual fabrication path fails acceptance.
- **Disabled:** After Win/Loss/Draw, all gameplay input is disabled. No resurrection,
  hidden fatigue, round-cap outcome, damage ramp, printer-HP fallback, or off-screen
  tiebreak is permitted.
- **Feedback:** Defeat returns the unit to its printer; terminal copy names Team
  defeated or Draw. Forecast identifies final-member risk without revealing hidden
  rival choices.
- **Progression:** M1 uses reward-free fixtures. M2 uses Sol's provisional prototype
  table in a versioned owned ledger: Win 30 coins/40 XP; Loss 10 coins/20 XP; Draw 20
  coins/30 XP, settled exactly once through the existing receipt boundary. These are
  tunable hypotheses, not a new human-approval gate. Draw is never Loss or Unfinished;
  no ad, IAP, or Market redesign is added.

## F7 — finite Kit, bot, saves, and deterministic completion

- **Entry:** Both sides receive the same checked rules, finite Kit, seeded draw order,
  and public/private snapshot contract.
- **Player decision:** Use the four visible cards under the one-Support-or-swap limit;
  no freeform chat or user-authored text exists.
- **Result:** Used Supports enter a finite discard with no reshuffle. The bot chooses
  only legal Team/Fabrication/Support/Swap actions through the same authority. Save and
  resume reproduce seed, deck order, FIFO, roster identities, equipment, HP, priority,
  resources, revision, and terminal result.
- **Failure:** Invalid bot intent, private-data leak, empty-hand stall, replay drift,
  save failure, or a deterministic loop is an acceptance failure with exact trace.
- **Disabled:** No online mode, market redesign, packs-as-play gate, ad system, IAP,
  broad discovery ladder, Yard expansion, or unrelated economy work enters this pass.
- **Feedback:** Event log and accessibility copy explain legal/disabled choices,
  forecast changes, auto-resolution, save recovery, and exact terminal cause.
- **Progression:** Prototype schema is additive and versioned. Existing profile bytes,
  legacy decks/mode, catalog, transactions, and historical saves remain intact.

## Implementation ownership and bounded modules

Sol's implementation plan uses an isolated TeamBattle domain rather than altering the
legacy printer-HP/deck constructors:

- `TeamBattleState`: roster identities/states, one Active/two Reserve bays, support
  draw pile/hand/discard, FIFO, small filament, revision, and Win/Loss/Draw.
- `TeamBattleRules`: atomic Plan validation, fixed cycle order, simultaneous-beat
  damage, once-only deployment, swap identity, replacement, and settlement.
- `TeamBattleBot`: deterministic legal solo policy using the same checked intents.
- `TeamBattleCoordinator`: receipt-safe state/presentation sequencing and save/resume.
- Prototype eligibility/cost data: explicit card IDs and small values separate from
  catalog-authored legacy numbers/effects.
- Additive profile/grant adapter: Team, Kit, priority, and idempotent first-session
  receipts without destructive migration.
- Screen routes/view models: Workshop grant/print, Team, Kit, preflight, battle Plan,
  forecast, Result, and recovery; dynamic content remains native.

## Deterministic acceptance

1. Identical seed and checked Plan sequence produces byte-equivalent public authority
   traces across fresh run, save/reload, reduced motion, and skipped presentation.
2. Seeded fixtures cover 1v1 foundation then 3v3: companion+equipment two-job Plan,
   queue-capacity atomic rejection, all five kit IDs, hand cap, finite exhaustion,
   once-only deploy, legal repeat swaps of the same identity, auto-replacement,
   empty-Active printing, stale callbacks, simultaneous final KO, and exactly-once Draw.
3. First-session fixtures prove each starter mapping, empty starter print bed, exactly
   one voucher use, two named preprinted common grants, Team 3/3, Kit 15/15, top-up
   idempotence, reload/recovery, and zero RNG/pack/purchase dependency.
4. Compatibility guards prove legacy saves/decks/catalog bytes and historical mode are
   unchanged; no ineligible card is deleted or silently rewritten.
5. Portrait captures and Android evidence remain gated by the preproduction checkpoint.
   No desktop test is a physical-device claim.

## Startup and save-safety acceptance

Prototype mode selection occurs before GameManager startup can call
`UnifiedRules.ensure`. Prototype startup reads the existing v3 snapshot without
running legacy normalizer, deck auto-repair, ownership grants, review-coin floor, or
any other write path. The versioned `team_prototype` namespace is created only by an
explicit checked user transition; every old value and historical mode remains intact.

All QA launches, including prebootstrap/startup fixtures, must pass an explicit
`--qa-save-root`. Legacy invalid-40-card-deck and old-ownership fixtures must remain
byte-identical after prototype startup. This preproduction pass inspects, imports, and
writes no actual player save. Baseline is branch `codex/printforge-team-prototype` at
`d7a4a10`; the shipped APK remains unchanged.
