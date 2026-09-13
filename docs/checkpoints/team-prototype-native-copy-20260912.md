# Team prototype native copy — 2026-09-12

Status: **IMPLEMENTATION-READY COPY FOR THE APPROVED PORTRAIT TEAM PROTOTYPE.**
This wording implements the accepted lifecycle and
[`team-prototype-native-ui-plan-20260912.md`](team-prototype-native-ui-plan-20260912.md).
It adds no mechanics or approval gate. All bracketed values are native dynamic text,
never baked into generated art.

## Copy fit and vocabulary

- Buttons target 16 characters or fewer where practical; headers target 24. Supporting
  copy is one sentence and at most two short lines at 576-wide portrait with 150% text.
- **Blueprint** means the permanent recipe/license. It is not the living field unit.
- **Printed** means a fabricated companion that may enter Team. Extra prints do not
  permit duplicate companion IDs in Team.
- **Support** means an owned match-use instruction in the 15-card Support Kit. Playing
  it moves that match copy to discard; it does not remove collection ownership.
- **Print** is the verb only when fabrication is actually occurring. Use **First to
  Print** for roster priority and **Printed** for completed collection state.
- Use **Team Victory**, **Team Defeat**, and **Draw**. Never say printer victory,
  destroyed printer, lost card, or claim reward.

## C1 — first-session guarantee copy contract

- **Entry:** No settled starter grant exists.
- **Player decision:** Inspect and choose one Blueprint, then start its free print.
- **Result:** One starter becomes Printed; two named commons are Team-ready; Support
  reaches 15/15.
- **Failure:** Save rejection says nothing was applied and offers Retry with the same
  request.
- **Disabled:** No reroll, second voucher, pack requirement, or duplicate completion.
- **Feedback:** Blueprint, Voucher, Printing, Printed, and Team-ready are named as
  separate states.
- **Progression:** Continue acknowledges the existing receipt; it grants nothing new.

## C2 — loadout and battle-decision copy contract

- **Entry:** The grant exists; battle additionally requires a saved valid 3/15 loadout.
- **Player decision:** Apply Team + Support, choose the next fabrication and one
  Support or swap, then Run Cycle.
- **Result:** Copy previews one atomic Plan and describes automatic print, enter,
  fight, and reserve replacement.
- **Failure:** Invalid or stale input names one exact reason and changes nothing.
- **Disabled:** No second Support, Support plus swap, manual phase, printer target,
  duplicate Team member, or new battle over a current one.
- **Feedback:** Status copy distinguishes Unspent, Printing, Ready, Active, and
  Defeated without exposing rival-private information.
- **Progression:** Battle use does not consume Blueprints, Printed companions, or
  collection Support ownership.

## C3 — Resume, Result, and save-safety copy contract

- **Entry:** A durable current match, store failure, terminal receipt, or read-only
  recovery state exists.
- **Player decision:** Resume, Retry the same transition, go Back, or inspect recovery
  details.
- **Result:** Resume returns to the same authority/cursor; Result presents the reward
  already settled by terminal Run.
- **Failure:** Copy never reports success before persistence confirms it.
- **Disabled:** No abandon, forfeit, reward claim, reset, repair, or new match before
  Result presentation completes.
- **Feedback:** The UI says what remains unchanged and whether the next action is
  Resume Battle, Resume Result, Retry, or Back.
- **Progression:** Retry, Back, Skip, reload, and reopening Result never grant twice.

## Route and state copy table

| Route / state | Header | Primary control | Secondary controls | Native explanation or status |
| --- | --- | --- | --- | --- |
| Workshop, no match | **Workshop** | **New Battle** | **Forge · Team · Support · Settings** | `Blueprints are recipes. Printed companions join your Team.` |
| Workshop, active match | **Workshop** | **Resume Battle** | **Team · Support · Settings** | `Your current match is saved.` |
| Workshop, pending terminal presentation | **Workshop** | **Resume Result** | **Team · Support · Settings** | `Finish the current Result before a new battle.` |
| Starter carousel | **Choose a Blueprint** | **Choose** | **Inspect · Back · Previous · Next** | `Permanent recipe · choice is final` |
| Starter confirmation | **Choose [Name]?** | **Choose Blueprint** | **Back** | `This Blueprint choice cannot change.` |
| Blueprint inspect, unprinted | **[Name] Blueprint** | **Choose** | **Back** | `Permanent recipe · not Printed yet` |
| Blueprint inspect, printed | **[Name] Blueprint** | none | **Back** | `Permanent recipe · Printed and Team-ready` |
| Voucher ready | **Free Starter Print** | **Start Free Print** | **Back** | `Blueprint: [Name] · Voucher: Ready` |
| First print running | **Printing [Name]** | **Skip Animation** | **Back** | `[Percent]% · Blueprint stays owned` |
| Raw-complete, save pending | **Print Ready** | none | **Back** | `Saving before [Name] awakens.` |
| First-print completion failed | **Save Not Confirmed** | **Retry** | **Back** | `Nothing new was applied.` |
| Awaken | **[Name] Awakens** | none | **Skip Animation** | `Printed companion · Team-ready` |
| Grant receipt | **Starter Ready** | **Continue** | **Back** | `1 starter Printed · 2 commons Team-ready · Support 15/15` |
| Grant acknowledgement failed | **Receipt Not Saved** | **Retry** | **Back** | `Your grant is safe. Continue is paused.` |
| Team editor | **Build Your Team** | **Apply** | **Cancel · Back** | `Team [Count]/3 · choose 3 unique Printed companions` |
| Team priority | **Print Order** | **Apply** | **Move Up · Move Down · Back** | `First to Print: [Name] · then Reserve 1 and 2` |
| Support editor | **Support Kit** | **Apply** | **Recommended · Cancel · Back** | `Support [Count]/15 · owned instructions remain in collection` |
| Invalid Team | **Team [Count]/3** | **Apply** disabled | **Back** | `Need 3 unique Printed companions.` |
| Invalid Support count | **Support [Count]/15** | **Apply** disabled | **Back** | `Need exactly 15 owned Support cards.` |
| Unsupported/unowned Support | **Support Kit** | **Apply** disabled | **Back** | `[Name] is not eligible or owned.` |
| Loadout Apply failed | **Save Not Confirmed** | **Retry** | **Back** | `Saved Team + Support are unchanged.` |
| Battle preflight, valid | **Battle Check** | **Start Battle** | **Back** | `Team 3/3 · Support 15/15 · First to Print: [Name]` |
| Battle preflight, invalid | **Battle Check** | **Start Battle** disabled | **Back** | `Apply a valid Team + Support first.` |
| Current match exists | **Battle Saved** | **Resume Battle** | **Back** | `Finish this match before starting another.` |
| Plan, no selection | **Plan** | **Run Cycle** | **Choose Print · Support · Swap · Back** | `Choose next fabrication and 1 Support or swap.` |
| Required empty-Active fabrication | **Print Next** | **Run Cycle** | **Back** | `Required: [Name] · Run when the full Plan is legal.` |
| Fabrication selected | **Next Print: [Name]** | **Run Cycle** | **Clear · Back** | `Cost [Cost] · Queue [Used]/3` |
| Support selected | **Support: [Name]** | **Run Cycle** | **Clear · Back** | `One Support or swap per cycle.` |
| Equipment target | **Equip Whom?** | **Use on [Name]** | **Back** | `Active, Ready, or printing next` |
| Swap selected | **Swap: [Name]** | **Run Cycle** | **Clear · Back** | `Ready companion enters before attacks.` |
| Run forecast | **Cycle Forecast** | **Run Cycle** | **Back** | `Available [Available] · Spend [Cost] · After [PostSpend] · Next [NextRegen]` / `Base forecast · cap 9` |
| No-choice legal Run | **Cycle Forecast** | **Run Cycle** | **Back** | `Run to replenish or advance the print queue.` |
| Insufficient filament | **Plan Blocked** | **Run Cycle** disabled when no legal no-choice Run | **Back** | `Need [Missing] filament.` |
| Queue full | **Plan Blocked** | **Run Cycle** only if legal no-choice Run | **Back** | `Queue full · Run advances 1 work.` |
| Illegal equipment target | **Choose a Target** | **Run Cycle** disabled | **Back** | `Select a living or Printing companion.` |
| Stale Plan | **Plan Changed** | **Review Plan** | **Back** | `Battle state changed. Review before Run.` |
| Receipt resolving | **Resolving** | **Skip Animation** | **Back** | `[Stage] · inputs return at the next Plan` |
| Print stage | **Printing [Name]** | **Skip Animation** | **Back** | `[Work Before] → [Work After] · current queue head` |
| Awaken stage | **[Name] Awakens** | **Skip Animation** | **Back** | `Print complete · entering the battlefield` |
| Enter stage | **[Name] Enters** | **Skip Animation** | **Back** | `[Active or Ready]` |
| Fight, both Active | **Run Cycle** | **Skip Animation** | **Back** | `[Name] and [Rival] strike together.` |
| Fight, one Active | **Run Cycle** | **Skip Animation** | **Back** | `Waiting for an opposing Active companion. Both sides hold.` |
| Fight, no Active | **Run Cycle** | **Skip Animation** | **Back** | `Waiting for Active companions. Both sides hold.` |
| Automatic reserve replacement | **Reserve Enters** | none | **Skip Animation · Back** | `[Name] replaces the defeated Active companion.` |
| No Ready replacement | **No Active Companion** | **Run Cycle** at next legal Plan | **Back** | `No Ready companion · print the next Team member.` |
| Cursor save failed | **Progress Paused** | **Retry** | **Back** | `[Stage] is ready. Retry to continue.` |
| Resume mid-receipt | **Resume Battle** | **Resume** | **Back** | `Continue at [Stage] · completed stages stay complete.` |
| Win Result | **Team Victory** | **Continue** | **Back** | `+30 Coins · +40 XP` |
| Loss Result | **Team Defeat** | **Continue** | **Back** | `+10 Coins · +20 XP` |
| Draw Result | **Draw** | **Continue** | **Back** | `Both Teams fell · +20 Coins · +30 XP` |
| Result cursor incomplete | **Result Paused** | **Retry** | **Back** | `Reward saved · finish this Result to continue.` |
| Result reopened | **Match Result** | **Continue** | **Back** | `[Result] · reward already saved` |
| Read-only recovery | **Recovery Needed** | **View Details** | **Back** | `Your save opened read-only. Nothing was changed.` |
| Future profile/schema | **Newer Save Version** | **View Details** | **Back** | `Update PrintForge to use this save.` |
| Valid backup only | **Backup Found** | **View Details** | **Back** | `Changes are locked to protect your save.` |
| Orphan/mismatched sidecars | **Save Files Do Not Match** | **View Details** | **Back** | `Battle changes are locked. No files were replaced.` |
| Root exit confirmation | **Leave PrintForge?** | **Leave** | **Stay** | `Your last confirmed progress is saved.` |

## Dynamic reason fragments

Use these only when the authority returns the matching state; never infer them from
disabled-control appearance.

| Authority condition | Copy |
| --- | --- |
| duplicate Team ID | `Choose 3 different companions.` |
| unprinted Team member | `[Name] needs a completed Print.` |
| wrong Team priority | `Order all 3 Team companions.` |
| second Support or Support plus swap | `Choose 1 Support or 1 swap.` |
| equipment target scope | `Eligible: Active, Ready, already Printing, or selected to print next.` |
| dead/not-ready swap | `[Name] is not Ready.` |
| spent fabrication | `[Name] already printed this match.` |
| stale revision | `Battle state changed. Review again.` |
| persistence rejection | `Save not confirmed. Nothing new was applied.` |
| active/current match | `Resume the current match.` |
| terminal presentation incomplete | `Resume Result before a new battle.` |
| Support discarded in match | `Used this match · still owned` |
| permanent collection state | `Blueprint owned · Printed [Count]` |

## Copy acceptance

At 576x1024 with 150% text, primary labels must remain fully visible, supporting copy
may wrap to two lines without covering authored hardware, and dynamic names/counts may
truncate only with an accessible full name. Disabled controls retain their concise
reason. Visible and native Android Back produce the same route semantics. Rival hand
copy exposes only card backs/count; no rival card ID, private Plan, or forecast promise
may appear. Render Available, Spend, After, and Next as separate native instrument
values rather than one wrapping sentence. `Available`, `PostSpend`, and `NextRegen`
come directly from the checked forecast; never reconstruct aid math in the UI.
