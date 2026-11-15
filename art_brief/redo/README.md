# Creatures to redo

Every creature here has a **placeholder picture made from code** (simple 3D shapes rendered in Godot),
not by an image generator. Each one needs a new painted sprite sheet in the style of the starters
(see `../style_targets/`) following the rules in `../README.md`.

- `redo_list.csv`: the same list as a spreadsheet, with each creature's prompt.
- `current_placeholders/<id>.png`: what the creature looks like now (its standing pose), so its
  body plan and colours can be kept or improved. Do **not** copy the placeholder's blocky style.

Save each new image as `art_inbox/<id>.png` and run `tools/import_creature_art.py`.

Also made from code: the **Test Bot** token (`test_bot`, a little 1/1 printed robot, Neutral), shown in
`current_placeholders/test_bot.png`. All tool and equipment card pictures were made from code too; they
are not in this list, which covers creatures only.

245 creatures.

| # | id | Name | Element | Rarity | Kind | What it does | Placeholder |
|---|---|---|---|---|---|---|---|
| 1 | `nova_burster` | Nova Burster | Fire | rare | card | Shatter: Burst: deal 3 damage to every print. | ![](current_placeholders/nova_burster.png) |
| 2 | `chimera_raiju` | Chimera Raiju | Lightning | epic | card | On Attack: Lightning leaps from the print it hits: 2, then 1, and its snake tail Poisons that print. | ![](current_placeholders/chimera_raiju.png) |
| 3 | `kitsune` | Kitsune | Arcane | rare | card | On Print: Gets +1/+1 for each card in your hand (up to 4). Turn End: It hides again with Cloak. | ![](current_placeholders/kitsune.png) |
| 4 | `layershifter` | Layer Shifter | Arcane | rare | card | On Print: Draw a card and your opponent throws away a random card. | ![](current_placeholders/layershifter.png) |
| 5 | `mana_wraith` | Mana Wraith | Arcane | uncommon | card | On Print: Steal 4 Filament from your opponent's Spool. | ![](current_placeholders/mana_wraith.png) |
| 6 | `mirror_imp` | Mirror Imp | Arcane | uncommon | card | On Print: Add a copy of an enemy print's card to your hand. | ![](current_placeholders/mirror_imp.png) |
| 7 | `moonlight_unicorn` | Moonlight Unicorn | Arcane | rare | card | On Print: Fully repair your prints and Cleanse them. | ![](current_placeholders/moonlight_unicorn.png) |
| 8 | `nullifier` | Nullifier | Arcane | epic | card | On Print: Silence all enemy prints. | ![](current_placeholders/nullifier.png) |
| 9 | `oracle_orb` | Oracle Orb | Arcane | rare | card | Turn Start: Take a print costing 2 or less from your deck into your hand. | ![](current_placeholders/oracle_orb.png) |
| 10 | `runeling` | Runeling | Arcane | common | card | On Print: Take an equipment card from your deck into your hand. | ![](current_placeholders/runeling.png) |
| 11 | `runemite` | Runemite | Arcane | common | card | Turn End: Repair your Printer by 1. | ![](current_placeholders/runemite.png) |
| 12 | `shadow_mare` | Shadow Mare | Arcane | rare | card | On Attack: Your opponent throws away a random card. | ![](current_placeholders/shadow_mare.png) |
| 13 | `shapeshift_sage` | Shapeshift Sage | Arcane | rare | card | On Print: Turn an enemy print into a 1/1 Test Bot. | ![](current_placeholders/shapeshift_sage.png) |
| 14 | `spellsword_fox` | Spellsword Fox | Arcane | uncommon | card | On Tool: This can attack again. | ![](current_placeholders/spellsword_fox.png) |
| 15 | `sphinx` | Sphinx | Arcane | epic | card | Turn Start: If your opponent has more cards than you, they throw one away. | ![](current_placeholders/sphinx.png) |
| 16 | `unicorn_foal` | Unicorn Foal | Arcane | uncommon | card | Evolves into Unicorn after 2 of your turns. | ![](current_placeholders/unicorn_foal.png) |
| 17 | `void_dragon` | Void Dragon | Arcane | legendary | card | On Print: Silence all enemy prints and steal 5 Filament from their Spool. | ![](current_placeholders/void_dragon.png) |
| 18 | `void_weaver` | Void Weaver | Arcane | rare | card | On Print: Your opponent throws away a random card for each Arcane print you have. | ![](current_placeholders/void_weaver.png) |
| 19 | `voidmoth` | Voidmoth | Arcane | uncommon | card | On Tool: Repair your Printer by 2. | ![](current_placeholders/voidmoth.png) |
| 20 | `ashling` | Ashling | Fire | common | card | Shatter: Deal 2 damage to the enemy Printer. | ![](current_placeholders/ashling.png) |
| 21 | `blaze_matriarch` | Blaze Matriarch | Fire | legendary | card | On Print: Deal 1 damage to every enemy print for each print you have. | ![](current_placeholders/blaze_matriarch.png) |
| 22 | `brimstone_bulldog` | Brimstone Bulldog | Fire | common | card | On Kill: Deal 2 damage to the enemy Printer. | ![](current_placeholders/brimstone_bulldog.png) |
| 23 | `cerberus` | Cerberus | Fire | rare | card | On Kill: Heat a random enemy print. | ![](current_placeholders/cerberus.png) |
| 24 | `chimera` | Chimera | Fire | epic | card | On Attack: Heat, Poison and Jam the print it hits. | ![](current_placeholders/chimera.png) |
| 25 | `cinder_juggler` | Cinder Juggler | Fire | uncommon | card | On Print: Throw 3 embers of 1 damage at random enemies. | ![](current_placeholders/cinder_juggler.png) |
| 26 | `cinder_sprite` | Cinder Sprite | Fire | uncommon | card | On Tool: Deal 1 damage to the enemy Printer and 1 to a random enemy print. | ![](current_placeholders/cinder_sprite.png) |
| 27 | `clogglin` | Clog Goblin | Fire | common | card | On Print: Heat an enemy print. | ![](current_placeholders/clogglin.png) |
| 28 | `dragon_egg` | Dragon Egg | Fire | rare | card | Evolves into Dragon Hatchling after 3 of your turns. | ![](current_placeholders/dragon_egg.png) |
| 29 | `ember_dragon` | Ember Dragon | Fire | epic | card | On Attack: Breathe fire: Heat all enemy prints. | ![](current_placeholders/ember_dragon.png) |
| 30 | `ember_moth` | Ember Moth | Fire | common | card | On Foe Attack: Heat the attacker. | ![](current_placeholders/ember_moth.png) |
| 31 | `flarefox_kit` | Flarefox Kit | Fire | common | card | Shatter: Deal 2 damage to a random enemy print. | ![](current_placeholders/flarefox_kit.png) |
| 32 | `furnace_golem` | Furnace Golem | Fire | rare | card | Turn End: Deal 1 damage to every damaged enemy print. | ![](current_placeholders/furnace_golem.png) |
| 33 | `heatbedhedgehog` | Heatbed Hedgehog | Fire | rare | card | On Print: Heat an enemy print. | ![](current_placeholders/heatbedhedgehog.png) |
| 34 | `kilnback_tortoise` | Kilnback Tortoise | Fire | uncommon | card | When Your Printer Is Hit: Heat a random enemy print. | ![](current_placeholders/kilnback_tortoise.png) |
| 35 | `kilnpup` | Kilnpup | Fire | common | card | Weakness: Deals +2 damage to Nature prints. | ![](current_placeholders/kilnpup.png) |
| 36 | `lavalynx` | Lavalynx | Fire | common | card | On Attack: Deal 1 damage to all enemy prints. | ![](current_placeholders/lavalynx.png) |
| 37 | `magma_mole` | Magma Mole | Fire | common | card | On Print: Your Printer gains 1 Armor for each enemy print. | ![](current_placeholders/magma_mole.png) |
| 38 | `magmabloom` | Magmabloom | Fire | legendary | card | On Print: Heat all enemy prints. Shatter: Deal 2 damage to all enemy prints. | ![](current_placeholders/magmabloom.png) |
| 39 | `nozzlet` | Nozzlet | Fire | uncommon | card | Evolves into Extrudrake after 2 of your turns. | ![](current_placeholders/nozzlet.png) |
| 40 | `scorch_wyrmling` | Scorch Wyrmling | Fire | rare | card | On Print: Double a friendly print's Attack. | ![](current_placeholders/scorch_wyrmling.png) |
| 41 | `slagtooth` | Slagtooth | Fire | uncommon | card | On Attack: Destroy the print it hits if that print has 2 Attack or less. | ![](current_placeholders/slagtooth.png) |
| 42 | `sootling` | Sootling | Fire | common | card | On Print: If you have another Fire print, deal 2 damage. | ![](current_placeholders/sootling.png) |
| 43 | `sparkplug_imp` | Sparkplug Imp | Fire | common | card | On Print: Deal 1 damage to a random enemy or the enemy Printer. | ![](current_placeholders/sparkplug_imp.png) |
| 44 | `sunfire_phoenix` | Sunfire Phoenix | Fire | legendary | card | Turn End: It rises from its ashes: fully repair it. | ![](current_placeholders/sunfire_phoenix.png) |
| 45 | `thermochameleon` | Thermochameleon | Fire | rare | card | On Print: Heat all enemy prints and take on +1 Attack for each of them. | ![](current_placeholders/thermochameleon.png) |
| 46 | `torchbearer` | Torchbearer | Fire | uncommon | card | On Ally Attack: Give the attacker +1 Attack. | ![](current_placeholders/torchbearer.png) |
| 47 | `trihydra` | Tri-Head Hydra | Fire | legendary | card | - | ![](current_placeholders/trihydra.png) |
| 48 | `volcano_tortle` | Volcano Tortle | Fire | rare | card | On Print: Deal 2 damage to every other print, yours too. | ![](current_placeholders/volcano_tortle.png) |
| 49 | `avalanche_ox` | Avalanche Ox | Ice | rare | card | On Attack: If your Printer has 10 Health or less, deal 2 damage to all enemy prints. | ![](current_placeholders/avalanche_ox.png) |
| 50 | `chillfan` | Chillfan | Ice | rare | card | On Print: Jam the strongest enemy print. | ![](current_placeholders/chillfan.png) |
| 51 | `cryo_slime` | Cryo Slime | Ice | common | card | Shatter: Put the strongest enemy print to sleep for 2 turns. | ![](current_placeholders/cryo_slime.png) |
| 52 | `crystal_fox` | Crystal Fox | Ice | uncommon | card | Shatter: Jam all enemy prints. | ![](current_placeholders/crystal_fox.png) |
| 53 | `frost_wyvern` | Frost Wyvern | Ice | epic | card | On Print: Jam all enemy prints and deal 1 damage to them. | ![](current_placeholders/frost_wyvern.png) |
| 54 | `frostbit_penguin` | Frostbit Penguin | Ice | common | card | On Foe Attack: Jam the attacker. | ![](current_placeholders/frostbit_penguin.png) |
| 55 | `glacier_dragon` | Glacier Dragon | Ice | legendary | card | On Attack: Freeze the print it hits: it sleeps for 2 turns. | ![](current_placeholders/glacier_dragon.png) |
| 56 | `glacier_golem` | Glacier Golem | Ice | rare | card | Turn End: Put a random enemy print to sleep for 2 turns. | ![](current_placeholders/glacier_golem.png) |
| 57 | `glaciermaw` | Glaciermaw | Ice | rare | card | Turn Start: Jam a random enemy print. | ![](current_placeholders/glaciermaw.png) |
| 58 | `hailstorm_hawk` | Hailstorm Hawk | Ice | uncommon | card | On Print: Throw 4 hailstones of 1 damage at random enemy prints. | ![](current_placeholders/hailstorm_hawk.png) |
| 59 | `ice_queen_moth` | Ice Queen Moth | Ice | legendary | card | On Print: Put every enemy print to sleep for 2 turns. | ![](current_placeholders/ice_queen_moth.png) |
| 60 | `icicle_archer` | Icicle Archer | Ice | common | card | On Attack: Jam a random enemy print. | ![](current_placeholders/icicle_archer.png) |
| 61 | `permafrost_bear` | Permafrost Bear | Ice | uncommon | card | Turn Start: Your Printer gains 1 Armor for each enemy print. | ![](current_placeholders/permafrost_bear.png) |
| 62 | `polar_packrat` | Polar Packrat | Ice | common | card | On Print: Take a tool from your deck into your hand. | ![](current_placeholders/polar_packrat.png) |
| 63 | `rime_knight` | Rime Knight | Ice | rare | card | On Kill: Put a random enemy print to sleep for 2 turns. | ![](current_placeholders/rime_knight.png) |
| 64 | `rimefox` | Rimefox | Ice | common | card | On Print: Put an enemy print to sleep: it cannot attack for 2 turns. | ![](current_placeholders/rimefox.png) |
| 65 | `rimestag` | Rimestag | Ice | rare | card | - | ![](current_placeholders/rimestag.png) |
| 66 | `slushpup` | Slushpup | Ice | common | card | On Hurt: Jam a random enemy print. | ![](current_placeholders/slushpup.png) |
| 67 | `snow_globe_golem` | Snow Globe Golem | Ice | common | card | When Your Printer Is Hit: Jam a random enemy print. | ![](current_placeholders/snow_globe_golem.png) |
| 68 | `snowball_seal` | Snowball Seal | Ice | common | card | On Print: Jam an enemy print and deal 1 damage to it. | ![](current_placeholders/snowball_seal.png) |
| 69 | `snowdrift` | Snowdrift | Ice | common | card | Turn Start: Deal 1 damage to all enemy prints. | ![](current_placeholders/snowdrift.png) |
| 70 | `snowmite` | Snowmite | Ice | common | card | Turn End: Jam a random enemy print. | ![](current_placeholders/snowmite.png) |
| 71 | `yeti` | Yeti | Ice | rare | card | On Foe Attack: Put the attacker to sleep for 2 turns. | ![](current_placeholders/yeti.png) |
| 72 | `arc_wasp` | Arc Wasp | Lightning | common | card | On Attack: If you have 3 or more prints, draw a card. | ![](current_placeholders/arc_wasp.png) |
| 73 | `blackout_bat` | Blackout Bat | Lightning | rare | card | On Print: Put the strongest enemy print to sleep for 2 turns. | ![](current_placeholders/blackout_bat.png) |
| 74 | `capacitor` | Capacitor | Lightning | uncommon | card | On Ally Print: Give it +1/+0. | ![](current_placeholders/capacitor.png) |
| 75 | `capacitor_crab` | Capacitor Crab | Lightning | common | card | Turn Start: If your Printer is damaged, +2 Print Speed this turn. | ![](current_placeholders/capacitor_crab.png) |
| 76 | `gridstag` | Gridstag | Lightning | uncommon | card | On Kill: This can attack again. | ![](current_placeholders/gridstag.png) |
| 77 | `multimeterbeetle` | Multimeter Beetle | Lightning | epic | card | On Print: Deal 2 damage. | ![](current_placeholders/multimeterbeetle.png) |
| 78 | `overload_eel` | Overload Eel | Lightning | uncommon | card | On Print: Silence an enemy print: it loses its keywords and abilities. | ![](current_placeholders/overload_eel.png) |
| 79 | `plasma_pegasus` | Plasma Pegasus | Lightning | epic | card | Turn Start: Lightning: 3 damage to a random enemy print, then 2, then 1. | ![](current_placeholders/plasma_pegasus.png) |
| 80 | `raijin_reactor` | Raijin Reactor | Lightning | legendary | card | On Print: Double the Attack of all your other prints. | ![](current_placeholders/raijin_reactor.png) |
| 81 | `short_circuit` | Short Circuit | Lightning | uncommon | card | On Print: Your opponent gets 2 less Filament next turn. | ![](current_placeholders/short_circuit.png) |
| 82 | `spark_kitten` | Spark Kitten | Lightning | common | card | Turn End: Give a random friendly print +1 Attack. | ![](current_placeholders/spark_kitten.png) |
| 83 | `sparkbug` | Sparkbug | Lightning | common | card | Turn Start: Deal 1 damage to a random enemy print. | ![](current_placeholders/sparkbug.png) |
| 84 | `static_hedgehog` | Static Hedgehog | Lightning | common | card | On Hurt: Deal 1 damage to the enemy Printer. | ![](current_placeholders/static_hedgehog.png) |
| 85 | `staticcub` | Staticcub | Lightning | common | card | On Kill: +1 Print Speed this turn. | ![](current_placeholders/staticcub.png) |
| 86 | `storm_dragon` | Storm Dragon | Lightning | epic | card | On Print: Lightning: 4 damage to a random enemy print, then 3, 2 and 1 to others. | ![](current_placeholders/storm_dragon.png) |
| 87 | `surge_owl` | Surge Owl | Lightning | uncommon | card | On Tool: Deal 1 damage to a random enemy or the enemy Printer. | ![](current_placeholders/surge_owl.png) |
| 88 | `swarm_twinwing` | Swarm Twinwing | Lightning | rare | card | Swarmling. Your Swarmlings get Twin Nozzle, now and when they arrive. | ![](current_placeholders/swarm_twinwing.png) |
| 89 | `tesla_tortoise` | Tesla Tortoise | Lightning | rare | card | On Foe Attack: Deal 2 damage to the attacker. | ![](current_placeholders/tesla_tortoise.png) |
| 90 | `thunder_kirin` | Thunder Kirin | Lightning | epic | card | On Print: Give all your prints Rush. | ![](current_placeholders/thunder_kirin.png) |
| 91 | `thunder_ram` | Thunder Ram | Lightning | uncommon | card | On Attack: Lightning leaps from the print it hits: 3, then 2, then 1 damage. | ![](current_placeholders/thunder_ram.png) |
| 92 | `thunderbird` | Thunderbird | Lightning | epic | card | When Your Printer Is Hit: Lightning: 2 damage to a random enemy print, then 1 to another. | ![](current_placeholders/thunderbird.png) |
| 93 | `volt_ferret` | Volt Ferret | Lightning | common | card | Shatter: Give a random friendly print +1 Attack and Rush. | ![](current_placeholders/volt_ferret.png) |
| 94 | `voltviper` | Voltviper | Lightning | rare | card | - | ![](current_placeholders/voltviper.png) |
| 95 | `zapkit` | Zapkit | Lightning | common | card | Turn Start: +1 Print Speed this turn. | ![](current_placeholders/zapkit.png) |
| 96 | `zapling` | Zapling | Lightning | common | card | On Print: Lightning: 2 damage to a random enemy print, then 1 to another. | ![](current_placeholders/zapling.png) |
| 97 | `barkback` | Barkback | Nature | common | card | Weakness: Deals +2 damage to Water prints. | ![](current_placeholders/barkback.png) |
| 98 | `basilisk` | Basilisk | Nature | rare | card | On Print: Its gaze turns the weakest enemy print to stone: destroy it. | ![](current_placeholders/basilisk.png) |
| 99 | `bloom_druid` | Bloom Druid | Nature | uncommon | card | On Print: Repair all your prints by 2 and your Printer by 2. | ![](current_placeholders/bloom_druid.png) |
| 100 | `bramblemaw` | Bramblemaw | Nature | rare | card | On Foe Shatter: This gets +1/+1. | ![](current_placeholders/bramblemaw.png) |
| 101 | `gaia_engine` | Gaia Engine | Nature | legendary | card | On Print: Give your other prints +2/+2 and Guard. | ![](current_placeholders/gaia_engine.png) |
| 102 | `grove_stag` | Grove Stag | Nature | uncommon | card | On Ally Shatter: Print a 1/1 Test Bot. | ![](current_placeholders/grove_stag.png) |
| 103 | `ironbark_bear` | Ironbark Bear | Nature | uncommon | card | Turn End: If this is damaged, it gets +2 Attack. | ![](current_placeholders/ironbark_bear.png) |
| 104 | `moss_sprout` | Moss Sprout | Nature | common | card | Turn End: Give your most hurt print +0/+1. | ![](current_placeholders/moss_sprout.png) |
| 105 | `mushmunk` | Mushmunk | Nature | common | card | On Print: Repair your Printer by 2 and Cleanse your prints. | ![](current_placeholders/mushmunk.png) |
| 106 | `mushroom_choir` | Mushroom Choir | Nature | rare | card | On Print: Poison all enemy prints. | ![](current_placeholders/mushroom_choir.png) |
| 107 | `nautilark` | Nautilark | Nature | rare | card | Turn Start: It gets Brim again. | ![](current_placeholders/nautilark.png) |
| 108 | `overgrowth_hydra` | Overgrowth Hydra | Nature | epic | card | Turn Start: This gets +1/+1 for each of your prints. | ![](current_placeholders/overgrowth_hydra.png) |
| 109 | `pack_wolf` | Pack Wolf | Nature | common | card | On Print: This gets +1/+1 for each Nature print you have. | ![](current_placeholders/pack_wolf.png) |
| 110 | `pollen_pixie` | Pollen Pixie | Nature | common | card | On Print: Cleanse a friendly print and give it +1 Attack. | ![](current_placeholders/pollen_pixie.png) |
| 111 | `rootling` | Rootling | Nature | common | card | On Print: Add 2 Filament to your Spool for each enemy print. | ![](current_placeholders/rootling.png) |
| 112 | `seedbomb_squirrel` | Seedbomb Squirrel | Nature | common | card | Shatter: Print two 1/1 Test Bots. | ![](current_placeholders/seedbomb_squirrel.png) |
| 113 | `seedpup` | Seedpup | Nature | common | card | Turn Start: Add 1 Filament to your Spool. | ![](current_placeholders/seedpup.png) |
| 114 | `spaghettimess` | Spaghetti Mess | Nature | uncommon | card | On Print: Jam an enemy print and Poison it. | ![](current_placeholders/spaghettimess.png) |
| 115 | `spoolcolossus` | Spool Colossus | Nature | legendary | card | On Print: Add 6 Filament to your Spool. Repair all your prints by 3. | ![](current_placeholders/spoolcolossus.png) |
| 116 | `sproutling` | Sproutling | Nature | common | card | Turn Start: This gets +0/+1. | ![](current_placeholders/sproutling.png) |
| 117 | `sproutpaw` | Sproutpaw | Nature | common | card | Evolves into Thornfang after 2 of your turns. | ![](current_placeholders/sproutpaw.png) |
| 118 | `swarm_queen` | Swarm Queen | Nature | legendary | card | Swarmling. Turn Start: Print a 1/1 Swarm Larva. | ![](current_placeholders/swarm_queen.png) |
| 119 | `swarm_stinger` | Swarm Stinger | Nature | common | card | Swarmling. Your Swarmlings get +1 Attack, now and when they arrive. | ![](current_placeholders/swarm_stinger.png) |
| 120 | `swarm_warden` | Swarm Warden | Nature | common | card | Swarmling. Your Swarmlings get Guard, now and when they arrive. | ![](current_placeholders/swarm_warden.png) |
| 121 | `thornback_hare` | Thornback Hare | Nature | common | card | On Hurt: Deal 1 damage to all enemy prints. | ![](current_placeholders/thornback_hare.png) |
| 122 | `treant_elder` | Treant Elder | Nature | rare | card | Turn Start: Give your other prints +0/+1. | ![](current_placeholders/treant_elder.png) |
| 123 | `supporttreant` | Tree Support Treant | Nature | epic | card | On Print: Repair all your prints by 2. | ![](current_placeholders/supporttreant.png) |
| 124 | `venus_snapper` | Venus Snapper | Nature | uncommon | card | On Print: Destroy an enemy print with 2 Attack or less. | ![](current_placeholders/venus_snapper.png) |
| 125 | `verdant_dragon` | Verdant Dragon | Nature | epic | card | On Print: Fully repair your prints and give them Hover. | ![](current_placeholders/verdant_dragon.png) |
| 126 | `vine_weaver` | Vine Weaver | Nature | common | card | On Print: Give a friendly print +0/+2 and Guard. | ![](current_placeholders/vine_weaver.png) |
| 127 | `vinehare` | Vinehare | Nature | uncommon | card | - | ![](current_placeholders/vinehare.png) |
| 128 | `benchy_unsinkable` | Benchy the Unsinkable | Neutral | legendary | card | Shatter: Return to your hand. | ![](current_placeholders/benchy_unsinkable.png) |
| 129 | `calibration_cube` | Calibration Cube | Neutral | uncommon | card | On Print: Take on the Attack and Health of another print. | ![](current_placeholders/calibration_cube.png) |
| 130 | `failed_print` | Failed Print | Neutral | common | card | On Print: Deal 2 damage to your own Printer. | ![](current_placeholders/failed_print.png) |
| 131 | `fp_frame` | Forbidden Frame | Neutral | legendary | card | Part of the Forbidden Printer: hold all five parts in your hand at once and you win. | ![](current_placeholders/fp_frame.png) |
| 132 | `fp_hot_end` | Forbidden Hot End | Neutral | legendary | card | Part of the Forbidden Printer: hold all five parts in your hand at once and you win. | ![](current_placeholders/fp_hot_end.png) |
| 133 | `fp_left_rail` | Forbidden Left Rail | Neutral | legendary | card | Part of the Forbidden Printer: hold all five parts in your hand at once and you win. | ![](current_placeholders/fp_left_rail.png) |
| 134 | `fp_mainboard` | Forbidden Mainboard | Neutral | legendary | card | Part of the Forbidden Printer: hold all five parts in your hand at once and you win. | ![](current_placeholders/fp_mainboard.png) |
| 135 | `fp_right_rail` | Forbidden Right Rail | Neutral | legendary | card | Part of the Forbidden Printer: hold all five parts in your hand at once and you win. | ![](current_placeholders/fp_right_rail.png) |
| 136 | `glue_golem` | Glue Golem | Neutral | common | card | On Print: Give your other prints +0/+2. | ![](current_placeholders/glue_golem.png) |
| 137 | `purge_line_worm` | Purge Line Worm | Neutral | uncommon | card | On Print: Cleanse all your prints and repair them by 1. | ![](current_placeholders/purge_line_worm.png) |
| 138 | `raft_crawler` | Raft Crawler | Neutral | uncommon | card | On Print: Scrap your weakest other print to get +3/+3. | ![](current_placeholders/raft_crawler.png) |
| 139 | `rainbow_unicorn` | Rainbow Unicorn | Neutral | epic | card | On Print: Give your prints +1/+1 for each different element among them. | ![](current_placeholders/rainbow_unicorn.png) |
| 140 | `stringing_slime` | Stringing Slime | Neutral | common | card | On Foe Print: Poison the arriving print. | ![](current_placeholders/stringing_slime.png) |
| 141 | `support_pillar` | Support Pillar | Neutral | common | card | Shatter: Give your prints +1 Attack. | ![](current_placeholders/support_pillar.png) |
| 142 | `tribute_titan` | Tribute Titan | Neutral | epic | card | On Print: Scrap your weakest other print, or this one is scrapped instead. | ![](current_placeholders/tribute_titan.png) |
| 143 | `basalt_colossus` | Basalt Colossus | Stone | epic | card | On Print: Your Printer gains 2 Armor for each of your prints. | ![](current_placeholders/basalt_colossus.png) |
| 144 | `basaltbison` | Basaltbison | Stone | uncommon | card | On Attack: This gets +1/+0. | ![](current_placeholders/basaltbison.png) |
| 145 | `boulder_beetle` | Boulder Beetle | Stone | common | card | On Ally Shatter: This gets +1/+1. | ![](current_placeholders/boulder_beetle.png) |
| 146 | `cairncrab` | Cairncrab | Stone | common | card | On Hurt: This gets +1/+0. | ![](current_placeholders/cairncrab.png) |
| 147 | `crag_ogre` | Crag Ogre | Stone | uncommon | card | Turn End: Deal 1 damage to your own Printer. | ![](current_placeholders/crag_ogre.png) |
| 148 | `crystalscorp` | Crystalscorp | Stone | rare | card | - | ![](current_placeholders/crystalscorp.png) |
| 149 | `cutie` | Cutie | Stone | legendary | card | On Print: Deal 3 damage to all enemy prints. Shatter: Draw 2 cards. | ![](current_placeholders/cutie.png) |
| 150 | `cyclops` | Cyclops | Stone | uncommon | card | On Print: Knock an enemy print with Hover out of the sky: destroy it. | ![](current_placeholders/cyclops.png) |
| 151 | `fossil_raptor` | Fossil Raptor | Stone | uncommon | card | On Print: This gets +1/+1 for each of your prints destroyed this battle. | ![](current_placeholders/fossil_raptor.png) |
| 152 | `geode_armadillo` | Geode Armadillo | Stone | uncommon | card | On Hurt: Deal 1 damage to the enemy Printer for each Stone print you have. | ![](current_placeholders/geode_armadillo.png) |
| 153 | `granitegriffin` | Granite Griffin | Stone | rare | card | On Attack: Deal 2 damage to the enemy Printer. | ![](current_placeholders/granitegriffin.png) |
| 154 | `gravelhopper` | Gravelhopper | Stone | common | card | On Foe Print: Deal 1 damage to it. | ![](current_placeholders/gravelhopper.png) |
| 155 | `manticore` | Manticore | Stone | rare | card | On Print: Gets +1 Attack for each enemy print. | ![](current_placeholders/manticore.png) |
| 156 | `marble_sculptor` | Marble Sculptor | Stone | uncommon | card | On Print: Give a friendly print +0/+3 and Brim. | ![](current_placeholders/marble_sculptor.png) |
| 157 | `minotaur` | Minotaur | Stone | rare | card | On Print: Give your other Stone prints Menace. | ![](current_placeholders/minotaur.png) |
| 158 | `monolith` | Monolith | Stone | rare | card | On Ally Shatter: This gets +2/+0. | ![](current_placeholders/monolith.png) |
| 159 | `mountain_king` | Mountain King | Stone | legendary | card | On Print: Your Printer gains Armor equal to the damage it has taken. | ![](current_placeholders/mountain_king.png) |
| 160 | `obsidian_dragon` | Obsidian Dragon | Stone | legendary | card | When Your Printer Is Hit: Deal 3 damage to the enemy Printer. | ![](current_placeholders/obsidian_dragon.png) |
| 161 | `obsidianray` | Obsidian Ray | Stone | uncommon | card | - | ![](current_placeholders/obsidianray.png) |
| 162 | `obsidian_sentinel` | Obsidian Sentinel | Stone | rare | card | When Your Printer Is Hit: Deal 2 damage to a random enemy print. | ![](current_placeholders/obsidian_sentinel.png) |
| 163 | `pebbit` | Pebbit | Stone | common | card | Evolves into Bouldron after 2 of your turns. | ![](current_placeholders/pebbit.png) |
| 164 | `pebble_golemite` | Pebble Golemite | Stone | common | card | On Print: Your Printer gains 2 Armor for each Stone print you have. | ![](current_placeholders/pebble_golemite.png) |
| 165 | `pebblepup` | Pebblepup | Stone | common | card | On Hurt: Your Printer gains 1 Armor. | ![](current_placeholders/pebblepup.png) |
| 166 | `quarry_crusher` | Quarry Crusher | Stone | rare | card | On Attack: Destroy the print it hits if that print was already damaged. | ![](current_placeholders/quarry_crusher.png) |
| 167 | `rubble_hound` | Rubble Hound | Stone | common | card | On Kill: Your Printer gains 2 Armor. | ![](current_placeholders/rubble_hound.png) |
| 168 | `sandpiper` | Sandpiper | Stone | common | card | On Attack: Your Printer gains 1 Armor. | ![](current_placeholders/sandpiper.png) |
| 169 | `sandstone_scarab` | Sandstone Scarab | Stone | common | card | Shatter: Your Printer gains 3 Armor. | ![](current_placeholders/sandstone_scarab.png) |
| 170 | `statue_gargoyle` | Statue Gargoyle | Stone | uncommon | card | Turn Start: If it is your only print, it gets +1/+1 and Guard. | ![](current_placeholders/statue_gargoyle.png) |
| 171 | `steppergolem` | Stepper Golem | Stone | uncommon | card | Shatter: Your Printer gains 2 Armor. | ![](current_placeholders/steppergolem.png) |
| 172 | `swarm_carapace` | Swarm Carapace | Stone | uncommon | card | Swarmling. Your Swarmlings get +0/+2, now and when they arrive. | ![](current_placeholders/swarm_carapace.png) |
| 173 | `abyssal_angler` | Abyssal Angler | Water | rare | card | On Print: Take a print from your deck into your hand. | ![](current_placeholders/abyssal_angler.png) |
| 174 | `benchyboss` | Benchy Boss | Water | rare | card | On Print: Repair your Printer by 3 and print a 1/1 Test Bot. | ![](current_placeholders/benchyboss.png) |
| 175 | `brine_bard` | Brine Bard | Water | uncommon | card | On Ally Print: Repair your Printer by 1. | ![](current_placeholders/brine_bard.png) |
| 176 | `brineleech` | Brineleech | Water | rare | card | On Attack: Poison the print it hit. | ![](current_placeholders/brineleech.png) |
| 177 | `bubbleray` | Bubbleray | Water | common | card | On Ally Shatter: Repair your Printer by 1. | ![](current_placeholders/bubbleray.png) |
| 178 | `coral_sentinel` | Coral Sentinel | Water | rare | card | When Your Printer Is Hit: This gets +1 Attack. | ![](current_placeholders/coral_sentinel.png) |
| 179 | `dewdrop_sprite` | Dewdrop Sprite | Water | common | card | Turn Start: Repair your Printer by 1 for each Water print you have. | ![](current_placeholders/dewdrop_sprite.png) |
| 180 | `dripling` | Dripling | Water | common | card | Evolves into Splashard after 2 of your turns. | ![](current_placeholders/dripling.png) |
| 181 | `kelp_strangler` | Kelp Strangler | Water | common | card | On Attack: Jam the print it hits. | ![](current_placeholders/kelp_strangler.png) |
| 182 | `kelpie` | Kelpie | Water | uncommon | card | On Attack: Drag the print it hits back to its owner's hand if it has 2 Attack or less. | ![](current_placeholders/kelpie.png) |
| 183 | `kraken` | Kraken | Water | legendary | card | On Print: Pull the strongest enemy print onto your side for good. | ![](current_placeholders/kraken.png) |
| 184 | `leviathan` | Leviathan | Water | legendary | card | On Print: Swap the Attack and Health of every enemy print. | ![](current_placeholders/leviathan.png) |
| 185 | `mistwalker` | Mistwalker | Water | common | card | On Ally Print: This gets +1/+0. | ![](current_placeholders/mistwalker.png) |
| 186 | `mistweaver` | Mistweaver | Water | common | card | On Print: If you have 3 or fewer cards in hand, draw 2 cards. | ![](current_placeholders/mistweaver.png) |
| 187 | `narwhal_lancer` | Narwhal Lancer | Water | rare | card | On Kill: This gets +2/+2. | ![](current_placeholders/narwhal_lancer.png) |
| 188 | `pearl_oyster` | Pearl Oyster | Water | common | card | Turn End: Your Printer gains 1 Armor. | ![](current_placeholders/pearl_oyster.png) |
| 189 | `puddle_mimic` | Puddle Mimic | Water | rare | card | On Print: Print a copy of an enemy print on your side. | ![](current_placeholders/puddle_mimic.png) |
| 190 | `reefhopper` | Reefhopper | Water | common | card | On Kill: Draw a card. | ![](current_placeholders/reefhopper.png) |
| 191 | `resinjelly` | Resin Jellyfish | Water | epic | card | On Print: Repair your Printer by 4. Draw a card. | ![](current_placeholders/resinjelly.png) |
| 192 | `siphon_squid` | Siphon Squid | Water | uncommon | card | On Attack: Drain 2 Health from the enemy Printer into yours. | ![](current_placeholders/siphon_squid.png) |
| 193 | `siphonshark` | Siphonshark | Water | uncommon | card | Weakness: Deals +2 damage to Fire prints. | ![](current_placeholders/siphonshark.png) |
| 194 | `spool_hydra` | Spool Hydra | Water | epic | card | On Hurt: Grow a 1/1 Hydra Head beside it. | ![](current_placeholders/spool_hydra.png) |
| 195 | `swarm_leech` | Swarm Leech | Water | rare | card | Swarmling. Your Swarmlings get Siphon, now and when they arrive. | ![](current_placeholders/swarm_leech.png) |
| 196 | `tidal_dragon` | Tidal Dragon | Water | epic | card | Turn End: Repair your Printer by 3 and Cleanse your prints. | ![](current_placeholders/tidal_dragon.png) |
| 197 | `tidecaller_crab` | Tidecaller Crab | Water | common | card | Turn Start: Repair your most hurt print by 2. | ![](current_placeholders/tidecaller_crab.png) |
| 198 | `tsunami_titan` | Tsunami Titan | Water | legendary | card | On Print: Send every other print back to its owner's hand. | ![](current_placeholders/tsunami_titan.png) |
| 199 | `whirlpool_ray` | Whirlpool Ray | Water | rare | card | On Print: Swap a print's Attack and Health. | ![](current_placeholders/whirlpool_ray.png) |
| 200 | `aero_mantis` | Aero Mantis | Wind | uncommon | card | On Kill: This gets Hover. | ![](current_placeholders/aero_mantis.png) |
| 201 | `breeze_finch` | Breeze Finch | Wind | common | card | On Print: Give a friendly print Hover. | ![](current_placeholders/breeze_finch.png) |
| 202 | `breezepup` | Breezepup | Wind | common | card | On Print: Cleanse your prints of Heat, Jam and Poison. | ![](current_placeholders/breezepup.png) |
| 203 | `cloudhopper` | Cloudhopper | Wind | common | card | On Foe Print: This gets +1/+0. | ![](current_placeholders/cloudhopper.png) |
| 204 | `cyclone_serpent` | Cyclone Serpent | Wind | rare | card | On Attack: Blow the print it hits back to its owner's hand. | ![](current_placeholders/cyclone_serpent.png) |
| 205 | `feather_duster_fox` | Feather Duster Fox | Wind | common | card | Shatter: Draw a card. | ![](current_placeholders/feather_duster_fox.png) |
| 206 | `gantrymantis` | Gantry Mantis | Wind | uncommon | card | - | ![](current_placeholders/gantrymantis.png) |
| 207 | `griffin_knight` | Griffin Knight | Wind | rare | card | On Print: Give a friendly print Hover and +2 Attack. | ![](current_placeholders/griffin_knight.png) |
| 208 | `gust_glider` | Gust Glider | Wind | common | card | On Kill: Fly back to your hand. | ![](current_placeholders/gust_glider.png) |
| 209 | `gustkit` | Gustkit | Wind | common | card | On Attack: Deal 1 damage to the enemy Printer. | ![](current_placeholders/gustkit.png) |
| 210 | `jetstream_dragonfly` | Jetstream Dragonfly | Wind | rare | card | On Ally Attack: Deal 1 damage to the enemy Printer. | ![](current_placeholders/jetstream_dragonfly.png) |
| 211 | `kite_drake` | Kite Drake | Wind | uncommon | card | On Print: Give all your Wind prints Hover. | ![](current_placeholders/kite_drake.png) |
| 212 | `pegasus_courier` | Pegasus Courier | Wind | uncommon | card | Turn End: Give a random friendly print Hover. | ![](current_placeholders/pegasus_courier.png) |
| 213 | `pinfeather` | Pinfeather | Wind | common | card | On Attack: Draw a card. | ![](current_placeholders/pinfeather.png) |
| 214 | `rotordrone` | Rotor Drone | Wind | rare | card | On Print: +1 Print Speed this turn. | ![](current_placeholders/rotordrone.png) |
| 215 | `sky_pirate_parrot` | Sky Pirate Parrot | Wind | uncommon | card | On Attack: Steal 2 Filament from your opponent's Spool. | ![](current_placeholders/sky_pirate_parrot.png) |
| 216 | `skyhawk` | Skyhawk | Wind | uncommon | card | - | ![](current_placeholders/skyhawk.png) |
| 217 | `storm_roc` | Storm Roc | Wind | epic | card | On Print: Blow the strongest enemy print back to its owner's hand. | ![](current_placeholders/storm_roc.png) |
| 218 | `stormdrake` | Stormdrake | Wind | rare | card | - | ![](current_placeholders/stormdrake.png) |
| 219 | `swarm_glider` | Swarm Glider | Wind | uncommon | card | Swarmling. Your Swarmlings get Hover, now and when they arrive. | ![](current_placeholders/swarm_glider.png) |
| 220 | `swarm_scout` | Swarm Scout | Wind | common | card | Swarmling. Your Swarmlings get Rush, now and when they arrive. | ![](current_placeholders/swarm_scout.png) |
| 221 | `swiftwhip` | Swiftwhip | Wind | uncommon | card | - | ![](current_placeholders/swiftwhip.png) |
| 222 | `sylph_queen` | Sylph Queen | Wind | legendary | card | On Print: Your opponent throws away 2 random cards and gets 2 less Filament next turn. | ![](current_placeholders/sylph_queen.png) |
| 223 | `tempest_dragon` | Tempest Dragon | Wind | epic | card | On Kill: Blow the strongest enemy print back to its owner's hand. | ![](current_placeholders/tempest_dragon.png) |
| 224 | `tempestlynx` | Tempest Lynx | Wind | rare | card | - | ![](current_placeholders/tempestlynx.png) |
| 225 | `tornado_weasel` | Tornado Weasel | Wind | uncommon | card | On Print: Your opponent throws away a random card from their hand. | ![](current_placeholders/tornado_weasel.png) |
| 226 | `whirligig` | Whirligig | Wind | common | card | On Print: If your opponent has more prints than you, print two 1/1 Test Bots. | ![](current_placeholders/whirligig.png) |
| 227 | `windmill_golem` | Windmill Golem | Wind | uncommon | card | Turn Start: +1 Print Speed this turn for each Wind print you have. | ![](current_placeholders/windmill_golem.png) |
| 228 | `wyvern_rider` | Wyvern Rider | Wind | uncommon | card | On Attack: Give a random friendly print +1/+1. | ![](current_placeholders/wyvern_rider.png) |
| 229 | `zephyr_sprite` | Zephyr Sprite | Wind | common | card | On Ally Print: Give the arriving print Hover. | ![](current_placeholders/zephyr_sprite.png) |
| 230 | `alicorn` | Alicorn | Arcane | legendary | token | Turn Start: Repair your Printer by 3 and give your prints +1/+1. | ![](current_placeholders/alicorn.png) |
| 231 | `teravox` | Teravox | Arcane | legendary | token | On Attack: Draw a card. | ![](current_placeholders/teravox.png) |
| 232 | `unicorn` | Unicorn | Arcane | rare | token | Turn Start: Cleanse your prints and repair them by 1. Evolves into Alicorn after 3 of your turns. | ![](current_placeholders/unicorn.png) |
| 233 | `voxelion` | Voxelion | Arcane | rare | token | Evolves into Teravox after 3 of your turns. | ![](current_placeholders/voxelion.png) |
| 234 | `dragon_hatchling` | Dragon Hatchling | Fire | rare | token | Evolves into Elder Wyrm after 3 of your turns. | ![](current_placeholders/dragon_hatchling.png) |
| 235 | `elder_wyrm` | Elder Wyrm | Fire | legendary | token | On Attack: Deal 2 damage to all enemy prints. | ![](current_placeholders/elder_wyrm.png) |
| 236 | `extrudrake` | Extrudrake | Fire | rare | token | Evolves into Infernozzle after 3 of your turns. | ![](current_placeholders/extrudrake.png) |
| 237 | `infernozzle` | Infernozzle | Fire | legendary | token | Turn Start: Deal 2 damage to the enemy Printer. | ![](current_placeholders/infernozzle.png) |
| 238 | `elderbloom` | Elderbloom | Nature | legendary | token | Turn End: Give your other prints +1/+1. | ![](current_placeholders/elderbloom.png) |
| 239 | `swarm_larva` | Swarm Larva | Nature | common | token | Swarmling. | ![](current_placeholders/swarm_larva.png) |
| 240 | `thornfang` | Thornfang | Nature | rare | token | Evolves into Elderbloom after 3 of your turns. | ![](current_placeholders/thornfang.png) |
| 241 | `bouldron` | Bouldron | Stone | rare | token | Evolves into Titanite after 3 of your turns. | ![](current_placeholders/bouldron.png) |
| 242 | `titanite` | Titanite | Stone | legendary | token | When Your Printer Is Hit: Your Printer gains 2 Armor. | ![](current_placeholders/titanite.png) |
| 243 | `hydra_head` | Hydra Head | Water | common | token | - | ![](current_placeholders/hydra_head.png) |
| 244 | `splashard` | Splashard | Water | rare | token | Evolves into Torrentus after 3 of your turns. | ![](current_placeholders/splashard.png) |
| 245 | `torrentus` | Torrentus | Water | legendary | token | Turn Start: Repair all your prints by 2. | ![](current_placeholders/torrentus.png) |
