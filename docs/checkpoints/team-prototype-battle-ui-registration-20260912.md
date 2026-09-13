# Native battle interaction registration

Primary records the read-only UI review of M0's final atlas CSS. This adds bounded
interactive geometry to the accepted native UI plan, not new mechanics or art.
All rects are x,y,w,h in the uniformly fitted941x1672 design layer. The current
prototype explicitly has **no ads or banner reserve**; respect all safe insets.
Derived states below require native normal/150% captures before visual sign-off.

## Plan source owners

- Choose Print uses the player roster records, not an unrelated floating control.
  The printer's Unspent docket is `(29.40,1053.00,215.65,79.00)`; player staging
  bays are `(303.90,1109.00,277.80,178.00)` and `(611.00,1109.00,277.80,178.00)`.
  Occupants derive from roster/status/priority, never hard-coded species.
- At150%, the short docket shows only the native creature name at39.21/42.48.
  Its full accessibility name includes Unspent and Choose Fabrication. Two text
  lines cannot fit its79-design-pixel height. Ready-bay150% height is185 and its
  name/status owner has height91.49 as in the final atlas accessibility overrides.
- A Ready staging bay is the Swap hit; the Active caption is not. Selected bay,
  fabrication owner or support card has a cyan ring, white in high contrast.
  Tapping the selected owner clears the local selection. Support and Swap are
  mutually exclusive: disable the conflicting owners with an accessible reason.
- Hand owners are `(51,1360,146,217)`, `(209,1360,146,217)`,
  `(367,1360,146,217)`, `(525,1360,146,217)`. Four is the maximum visible hand.
  Rival controls never receive private card IDs, hidden Plan, or private draw order.
- The player queue rail's visual text owner is `(295.70,1290.60,599.60,44.10)`.
  When a local selection exists, it may also be the redundant Clear Plan hit at
  derived `(295.70,1281.20,599.60,78.40)`, ending before the hand. Keep concise
  queue text, not a tiny appended instruction. Full accessibility names the plan
  being cleared. This clears local action/target fields only and writes nothing.

## Equipment target sheet — derived on the approved battlefield

Use the existing generated physical control family over a stage-local translucent
navy input blocker `(0,0,941,1672)`, approximately `#07111BB8`. No generic app panel.
Freeze/disable underlying controls and focus; the modal owns all interaction.

- Native cream heading `(281,441,622,82)`, e.g. Full Suit — Choose Target.
- Up to three `wide` parchment-family target controls:
  `(281,535,622,96)`, `(281,643,622,96)`, `(281,751,622,96)`.
- Visible native row copy is Name + Active/Ready/Printing/Next; detailed eligibility and HP
  stay accessible. Dark ink `#172b3c`; normal27/30, large39.21/42.48.
  Printing means an existing queued member; Next means the checked same-Plan
  fabrication, including a legal default. Never label an existing print as Next.
- Cancel uses the generated `binding` family at `(654,859,249,82)`, cream text.
  Every hit remains at least48 final viewport pixels after safe fitting.
- Only `Rules.eligible_equipment_targets` supplies eligibility, including a legal
  default or explicit same-Plan fabrication. Preserve full canonical member IDs.
- Initial equipment tap is provisional. Target choice finalizes it. Back/Cancel
  clears the provisional card/target, writes nothing, restores source focus.
  Tapping an already finalized selected card clears it without reopening the sheet.

## Preflight Start / Resume — derived text states on ST-01

The approved BA preflight-empty fixture is post-Start Cycle1 Plan, not a license to
skip the atomic Start boundary. Use the existing ST-01 preflight-error instrument
for valid/Resume variants; only native state/copy changes.

| Owner | Rect |
| --- | --- |
| Back | 29.40,32.68,133.96,78.50 |
| Header | 223.86,168.27,253.30,52.28 |
| Body | 174.82,1150.69,624.13,215.63 |
| Context lever hit | 444.38,1450.00,403.48,153.56 |
| Lever label | 628.88,1481.00,196.00,94.00 |

At150%, short header Battle retains full accessibility name Battle Preflight.
Body has at most3–4 lines: Team3/3, Support15/15, first print/order ready, or current
match cycle/phase. Lever says Start Battle, Resume, or Open Team when loadout invalid.
Use normal27/33 or large39.21/42.48 native text; decorative dial stays noninteractive.
Start freezes the stable sequence-derived seed once; Resume never replaces a match.
An unacknowledged terminal receipt is Resume Result, not New Battle.

## Source / state safety

Names and approved art may come from V3Catalog; combat costs/stats/effects come only
from TeamBattleData / checked projections. `BattleCatalog.support_card` is an older
table without Suit, Gem and Forge Surge, and is not the prototype art lookup.

Run inputs use canonical member identity IDs and support copy IDs. Check the inner
viewer-safe `match.player` projection. During pending presentation, cache and render
only the projected receipt opening/stage snapshots. The current authority is already
the Run's final state and must not leak living units, damage or Result early.

Use the shared passive print compositor with cached frame/alpha/root geometry.
First Forge owns a local Sequence; battle owns its accepted receipt/cursor clock.
No renderer advances rules or grants, and no heavy snapshots or image IO occur per frame.

## First playable presentation cadence

Primary selects these bounded initial presentation durations, in seconds. They do
not change the accepted16-cycle median, authority events, or gameplay timing.

| Eventful stage | Seconds |
| --- | --- |
| Queue | 0.25 |
| Print | 1.60 |
| Awaken | 0.55 |
| Enter/Fit | 0.75 companion;0.45 equipment-only |
| Swap | 0.60 |
| Spell | 0.40 |
| AttackLock | 0.25 |
| Damage | 0.55 |
| Traits | 0.30 |
| Defeat | 0.40 |
| Replace | 0.65 |

Both sides present a stage in parallel. Empty stages settle immediately, with the
same required cursor acknowledgements; they do not add a series of blank delays.
Result waits for a visible native Continue action, which acknowledges that final
presentation cursor before returning to Workshop. It never claims/grants rewards.
The nonterminal Plan stage acknowledges immediately and returns control to Plan.

Normal movement is rooted, finite, and returns exactly to the approved floor anchor.
For attacking, use a short inward lunge of at most70design pixels toward the opposing
Active, the actual seat-specific windup/contact art (native pose motion for two-view
Voltwig), then return. Do not invent mirrored/front/back frames. Shadows track the
floor movement while airborne source poses retain their audited windup datum.
Enter and replacement use the same figure traveling from its prior printer/bay root;
suppress its stationary destination copy until arrival. No sliding whole card panels.

Reduced motion retains readable timing but uses grounded state transitions and a
static carriage; printing may reveal four discrete25% bands over the same1.60s.
No motion setting changes transactions, damage, print work, grants or cursor rules.
Test clocks may advance deterministically for coverage; label those tests honestly
and also capture real renderer poses at normal phase boundaries.
