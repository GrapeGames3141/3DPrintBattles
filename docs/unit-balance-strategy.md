# PrintForge Unit Balance Strategy

## Decision

PrintForge will use a hybrid balance process:

1. Formula-based checks establish the initial stat and filament budgets.
2. Paired AI-versus-AI simulations measure actual performance on the battlefield.
3. Human playtests judge clarity, satisfaction, counterplay, and skill expression.

Neither formulas nor self-play should be treated as sufficient by itself. A formula cannot accurately price map geometry, attack uptime, deployment timing, or multi-unit synergy. A single AI policy can instead make the roster converge around that bot's blind spots.

Rarity does not provide hidden combat power. Filament cost is the primary balancing currency. Rarity may communicate complexity, collectability, visual treatment, or expected specialization.

## Formula-based checks

Each unit should be evaluated through quantities that correspond to real combat outcomes:

- **Durability:** average number of opposing attacks required to kill the unit.
- **Damage:** average basic-attack damage against the opposing roster's Defense distribution.
- **Reach:** percentage of activations in which the unit can move to and legally affect a target.
- **Ability value:** effective damage, healing, damage prevention, or positional value produced per use.
- **Tempo:** how early the unit's filament cost allows it to enter play and how many additional activations that creates.
- **Efficiency:** total measured combat contribution divided by filament cost.

The damage model remains:

```text
damage = max(1, effective Offense - floor(effective Defense / 2))
```

Linear stat totals should not be used as the final score. Defense changes time-to-kill differently at different Offense values, Range can create attacks that otherwise would not exist, and one extra Movement can cross an important terrain threshold.

## Current roster warnings

The initial roster contains several relationships that deserve immediate simulation:

- **Dawnwood Warden versus Ironbound Goblin Warrior:** both cost 3 and share Offense, Movement, and Initiative. Dawnwood currently has 4 more Health, 1 more Defense, and a team-defense ability. Ironbound's shorter Brace cooldown may not compensate.
- **Starbough Longbow versus Scrapbolt Slinger:** both cost 4 and share Offense, Defense, Movement, and their Pin ability. Longbow gives up only 1 Health for +1 Range and +1 Initiative, which is likely favorable.
- **Runeweave Sage versus Sparkspool Shaman:** their raw stats are not directly comparable because Sage costs 5 and Shaman costs 4. Their support value must be measured per filament and after accounting for the attack action spent casting the buff.
- **Hobgoblin Forge-Brute versus Moonshadow Rogue:** this is an intentionally asymmetric matchup. Brute buys durability and cleave for 5 filament; Rogue buys speed, initiative, and Defense-piercing burst for 4. Map and target-access statistics will determine whether both have viable niches.

Equal total roster cost does not guarantee faction parity. Both current rosters cost 19, but the six-filament opening budget, two-filament income, and one-spawn-per-round limit make cost distribution and deployment order significant.

## AI-versus-AI methodology

Every simulated condition should be paired to cancel obvious structural advantages:

```text
Game A: Goblins north, Elves south
Game B: Elves north, Goblins south
```

Paired runs should also reverse or vary:

- First faction and initiative tie advantage.
- Deployment order.
- Random seed.
- Map or obstacle layout.
- AI policy.
- Army composition when roster construction becomes configurable.

Use at least 5,000 paired matches for a serious balance candidate. Small exploratory batches may be used during development, but changes should not be accepted from a handful of games.

## AI policy set

Testing should use several intentionally different bots:

- **Aggressive:** prioritizes immediate damage and enemy-forge pressure.
- **Objective:** emphasizes crossing control, bridge access, and printer destruction.
- **Defensive:** protects healers and support units and favors favorable trades.
- **Ranged/kiting:** maximizes distance, line of sight, and safe attack uptime.
- **Random legal:** supplies a useful control group and exposes universally dominant actions.
- **Search AI:** compares several legal command sequences using a state evaluation function.

A unit that dominates under every policy is likely overtuned. A unit that succeeds only under a specific coherent policy may have a healthy strategic niche. Results from one tactical AI must not be generalized to the whole game.

## Metrics

Every batch should report at least:

- Faction win rate with confidence intervals.
- North-versus-south advantage.
- First-activation advantage.
- Average and percentile match length.
- Stalemate rate.
- Unit deployment round and deployment frequency.
- Basic and ability damage.
- Effective healing, excluding overhealing.
- Damage prevented by Defense and temporary Health.
- Printer damage.
- Activations survived and actions successfully used.
- Contribution per filament.
- Unit-versus-unit matchup results.
- Faction win-rate change when a unit is removed or replaced.

Initial acceptance targets:

```text
Overall faction win rate:       48-52%
Map-side or first-turn swing:   less than 3 percentage points
Stalemate rate:                 less than 1%
Same-role, same-cost units:     no strict dominance
```

These are diagnostic thresholds rather than guarantees of fun. A matchup outside a threshold triggers investigation; it does not dictate an automatic stat change.

## Ability accounting

Abilities must be valued by their realized outcome rather than their advertised maximum:

- Healing counts only Health actually restored.
- Defense bonuses count damage actually prevented while active.
- Offense bonuses count additional damage caused by the bonus.
- Movement bonuses count attacks, rescues, or objectives reached because of the extra movement.
- Temporary Health counts damage absorbed before the effect expires.
- Cleave counts damage across every affected target.
- Cleanse counts negative-effect turns that were actually removed.

Bloodlust Pulse and Forest Shield consume the caster's attack action. The future value created for the caster and allies must repay that opportunity cost. Large theoretical area-of-effect values should not be credited when adjacent allies cannot exploit them.

## Recommended implementation

The existing node-free match state and authoritative command boundary provide the foundation for a fast simulator. The next balance tooling should:

1. Extract or reuse a presentation-free match resolver.
2. Run deterministic matches from explicit seeds.
3. Load AI policies independently from unit data.
4. Execute paired matches without rendering or animation delays.
5. Write per-match records plus aggregate CSV and JSON reports.
6. Preserve the exact rules, roster revision, map revision, and Git commit in every report.
7. Support controlled stat sweeps, changing only one or two values per candidate.

An automated optimizer may propose candidates later, but it should not freely rewrite the roster. Designers should retain constraints on faction identity, unit roles, integer readability, cooldown cadence, and intended counters.

## Human validation

AI simulation answers whether the numerical system is stable under its tested policies. Human testing must still answer:

- Is the stronger choice obvious for understandable reasons?
- Can players identify and execute counterplay?
- Do abilities feel worth spending an activation on?
- Does each unit create a distinct decision rather than a cosmetic stat variation?
- Are wins attributed to player decisions rather than initiative or spawn luck?
- Are matches an appropriate length and pace?

The release balance loop is therefore:

```text
Formula sanity check
        -> paired AI batches
        -> inspect matchup and efficiency reports
        -> make a constrained change
        -> rerun the same seeds
        -> human PvP validation
```
