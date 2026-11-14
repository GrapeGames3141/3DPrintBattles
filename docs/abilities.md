# The 100 abilities

Design list for card abilities, drawn from Magic: The Gathering (MtG), Pokémon (PKMN),
Yu-Gi-Oh! (YGO) and our own printing theme (ORIG). A card should be known by what it
does, so no two cards share an ability. **Built** means it is in the engine, on a card,
and covered by `tests/test_rules.gd`; **Next** means designed but not built.
Moments ("When") are the engine's trigger names (`trig` on a card, see
`BattleEngine._fire_unit`). Cards with a Mk II/III Blueprint keep their ability.

## Wave 1: triggered abilities (built, 32)

| # | Ability | When | Effect | From | Card |
|---|---|---|---|---|---|
| 1 | Sprout | Turn Start | This gets +0/+1 | MtG growth | Sproutling |
| 2 | Tinker | Turn End | Repair your Printer 1 | ORIG | Runemite |
| 3 | Static Ping | Turn Start | 1 damage to a random enemy print | MtG pinger | Sparkbug |
| 4 | Frost Bite | Turn End | Jam a random enemy print | PKMN paralysis | Snowmite |
| 5 | Seed Money | Turn Start | +1 Filament on the Spool | MtG mana dork | Seedpup |
| 6 | Overclock | Turn Start | +1 Print Speed | ORIG | Zapkit |
| 7 | Cheerleader | Ally Print | This gets +1/+0 | MtG | Mistwalker |
| 8 | Courier | Attack | Draw a card | MtG | Pinfeather |
| 9 | Pebble Toss | Attack | Your Printer gains 1 Armor | ORIG | Sandpiper |
| 10 | Flyby | Attack | 1 damage to the enemy Printer | YGO | Gustkit |
| 11 | Enrage | Hurt | This gets +1/+0 | MtG/HS | Cairncrab |
| 12 | Hunter | Kill | Draw a card | MtG | Reefhopper |
| 13 | Cleave | Attack | 1 damage to all enemy prints | MtG | Lavalynx |
| 14 | Prowess | Tool | This gets +1/+1 | MtG | Glyphhare |
| 15 | Frost Armor | Hurt | Jam a random enemy print | PKMN | Slushpup |
| 16 | Last Rites | Ally Shatter | Repair your Printer 1 | MtG | Bubbleray |
| 17 | Watchful | Foe Print | This gets +1/+0 | MtG | Cloudhopper |
| 18 | Sentry | Foe Print | 1 damage to the arriving print | MtG | Gravelhopper |
| 19 | Sentinel | Hurt | Your Printer gains 1 Armor | ORIG | Pebblepup |
| 20 | Adrenaline | Kill | +1 Print Speed | ORIG | Staticcub |
| 21 | Whiteout | Turn Start | 1 damage to all enemy prints | MtG | Snowdrift |
| 22 | Stampede | Attack | This gets +1/+0 | MtG | Basalt Bison |
| 23 | Charge | Ally Print | The arriving print gets +1/+0 | MtG anthem | Capacitor |
| 24 | Scholar | Tool | Repair your Printer 2 | MtG | Voidmoth |
| 25 | Regrow | Turn End | Repair this 2 | MtG regenerate | Chronocat |
| 26 | Soul Feast | Foe Shatter | This gets +1/+1 | MtG | Bramblemaw |
| 27 | Piercing Shot | Attack | 2 damage to the enemy Printer | YGO | Granite Griffin |
| 28 | Berserk | Kill | This can attack again | MtG/YGO | Gridstag |
| 29 | Cold Snap | Turn Start | Jam a random enemy print | PKMN | Glaciermaw |
| 30 | Volley | Attack | 1 damage to a random enemy print | MtG | Gustgriffin |
| 31 | Memorial | Ally Shatter | This gets +2/+0 | MtG | Monolith |
| 32 | Wellspring | Turn End | Repair your Printer 2 | ORIG | Tidemaw |

## Wave 2: new combat keywords (9 built, 8 next)

Each is a keyword like Guard and Rush: a lettered marker on the bench, a line in the Handbook.
Nine are built and tested; Support, Loner (auras need a live Attack bonus), Pair, Phase, Fury, Mirror and Magnet
are still next. Idle is dropped because Twin Nozzle already does it. Reach here means "can attack Hover prints".

| # | Ability | What it does | From | Card |
|---|---|---|---|---|
| 33 | Hover | Cannot be attacked by prints without Hover or Reach | MtG flying | **Skyhawk** |
| 34 | Reach | Can block (be attacked as) a Hover print and attack Hover prints | MtG | **Gantry Mantis** |
| 35 | Snap | Any damage it deals destroys the print it hits | MtG deathtouch | **Gearspider** |
| 36 | Quick Draw | Deals its damage first; a print it kills deals none back | MtG first strike | **Vinehare** |
| 37 | Overflow | Extra damage past a print's Health hits the Printer | MtG trample | **Obsidian Ray** |
| 38 | Support | Cannot attack, but gives your other prints +1/+0 | MtG defender | Next |
| 39 | Ward | The first tool aimed at it by the enemy is wasted | MtG ward / YGO | **Stormdrake** |
| 40 | Idle | Attacks and can still be attacked as if it had not (stays READY) | MtG vigilance | Next |
| 41 | Reprint | The first time it is destroyed it returns to the bench with 1 Health | MtG undying | **Rimestag** |
| 42 | Pair | Needs another print with the same element beside it to attack | YGO | Next |
| 43 | Loner | +2/+0 while it is your only print | MtG | Next |
| 44 | Menace | Cannot be blocked by a single Guard print | MtG | **Swiftwhip** |
| 45 | Phase | Returns to your hand at the end of your turn | YGO Spirit | Next |
| 46 | Fury | Attacks twice but takes damage from the first strike back only | MtG double strike | Next |
| 47 | Mirror | Reflects the damage of the first attack on it each turn | ORIG | Next |
| 48 | Magnet | Enemy prints must attack it if it is the only unjammed print | MtG goad | Next |
| 49 | Cloak | Cannot be targeted by tools until it attacks | MtG hexproof | **Tempest Lynx** |

## Wave 3: conditions and element play (Next, 17)

| # | Ability | What it does | From |
|---|---|---|---|
| 50 | Standby | Puts a print to sleep: it cannot attack for 2 turns | PKMN sleep |
| 51 | Confuse | The target attacks a random target next turn | PKMN confusion |
| 52 | Toxic | Poison that stacks: 1, then 2, then 3 damage a turn | PKMN poison |
| 53 | Weakness | Deals +2 to prints of the element it beats (Fire>Nature>Water>Fire...) | PKMN |
| 54 | Resistance | Takes 1 less from the element it resists | PKMN |
| 55 | Type Change | Becomes the element of the print it hit | PKMN |
| 56 | Evolve | After 2 turns on the bench it becomes a stronger print | PKMN |
| 57 | Badge | +1/+1 for every element in your deck beyond the first | MtG domain |
| 58 | Frostbite | A frozen print cannot attack or be healed until your next turn | PKMN |
| 59 | Overheat | At 3 Heat a print is destroyed | PKMN burn |
| 60 | Cleanse | Removes Heat and Jam from your prints | PKMN |
| 61 | Coat | Prints that share its element get Brim | PKMN |
| 62 | Synergy | +1/+1 for each other print of its element on your bench | MtG tribal |
| 63 | Mimic | Copies the Attack of the strongest enemy print | PKMN Ditto |
| 64 | Adapt | Takes on a keyword from the print that last hurt it | MtG |
| 65 | Rain Dance | While in play, all Water prints get +1/+0 | PKMN weather |
| 66 | Sandstorm | While in play, non-Stone prints take 1 at the start of their turn | PKMN weather |

## Wave 4: sacrifice, graveyard and costs (Next, 17)

| # | Ability | What it does | From |
|---|---|---|---|
| 67 | Tribute | A big print that costs 0 Filament but needs you to scrap a print of yours | YGO tribute |
| 68 | Scrapyard | A pile of your destroyed prints that other cards can use | YGO graveyard |
| 69 | Revive | Print one from your Scrapyard with 1 Health | YGO |
| 70 | Salvage | Take a print from your Scrapyard back to your hand | MtG |
| 71 | Flashback | Use a tool from your Scrapyard once, then it is gone | MtG |
| 72 | Fusion | Scrap two prints for one stronger print | YGO |
| 73 | Ritual | A tool that needs a print scrapped to print a specific big print | YGO |
| 74 | Kicker | Pay 2 more Filament when you print it for an extra effect | MtG |
| 75 | Cycling | Scrap this from your hand for 1 Filament to draw a card | MtG |
| 76 | Convoke | Jam your prints to pay Filament | MtG |
| 77 | Storm | Deals damage for each card you used this turn | MtG |
| 78 | Overload | Pay extra and the tool hits every print | MtG |
| 79 | Madness | When you scrap it from your hand it is free to print | MtG |
| 80 | Retrace | Scrap a print to use a tool again | MtG |
| 81 | Sacrifice | Scrap a print: draw 2 cards | YGO/MtG |
| 82 | Devour | Scrap a print as it arrives to take its stats | MtG |
| 83 | Soulbond | Pairs with another print and shares keywords | MtG |

## Wave 5: traps, counters and the stack (Next, 17)

| # | Ability | What it does | From |
|---|---|---|---|
| 84 | Set Trap | A face-down card that springs when the enemy does something | YGO |
| 85 | Counter Print | Cancel the enemy's next print | MtG counterspell |
| 86 | Negate | Cancel a tool as it is used | YGO |
| 87 | Flash | Use it on the enemy's turn | MtG |
| 88 | Reflect | Redirect the next damage to the Printer back | YGO Mirror Force |
| 89 | Scry | Look at the top 3 cards of your deck and reorder them | MtG |
| 90 | Tutor | Search your deck for a print | MtG |
| 91 | Discard | The enemy discards a random card | MtG |
| 92 | Peek | See the enemy's hand until the end of the turn | MtG |
| 93 | Steal Control | Take an enemy print for a turn | MtG/YGO |
| 94 | Swap | Swap the Attack and Health of a print | MtG |
| 95 | Polymorph | Turn a print into a Test Bot | MtG |
| 96 | Silence | Remove a print's abilities and keywords | MtG |
| 97 | Wipe | Destroy every print on the bench | MtG |
| 98 | Time Warp | Take an extra turn (once a battle) | MtG |
| 99 | Draft | Choose 1 of 3 random cards to add to your hand | MtG |
| 100 | Tag Team | Two prints attack as one, adding their Attack | YGO |

Entries 50-100 and the rest of wave 2 each need an engine change before they can be a card; they are listed in the
order that costs the least first. Wave 1 shows the pattern: define the moment in the
catalog (`tools/catalog/fx.py`), give the engine a hook, write a test, then put it on a card.
