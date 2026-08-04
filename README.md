# PrintForge

Godot 4.7 project containing two deliberately separate applications:

- **PrintForge Combat POC (Windows):** grid tactics battle between the Goblin Scrap Legion and Elven Moonloom Host.
- **PrintForge Model Inspector (Android):** the existing touch-friendly creature/base/animation inspection app. Mobile feature overrides keep `main.tscn` as its entry scene; desktop launches `combat_main.tscn`.

## Combat POC

The battlefield is a 25×33 orthogonal grid. A three-cell road crosses north-to-south; a two-cell shallow river crosses east-to-west; a three-cell bridge occupies their center intersection. Trees and boulders block movement and line of sight. Shallow water costs three movement points; grass, road, bridge, and cosmetic rolling hills cost one.

Each faction owns a 2×2 fantasy printer with 50 Health and 8 Defense. Printers begin with 6 filament, gain 2 each round, cap at 10, and may produce one reserve unit per round. Destroying the enemy printer or exhausting its entire army wins.

Turns resolve by Initiative. A unit may move and then use one basic attack, ability, or Wait. Range 0 means adjacent melee. Damage is `max(1, Offense - floor(Defense / 2))`. Healers deal normal damage and heal for double their Offense. Goblin Bloodlust buffs Offense and Movement; Elven Forest Shield grants temporary Health and Defense.

### Desktop controls

- Left-click a blue square to move; click a highlighted target to attack or use an ability.
- Use the roster buttons during deployment, or skip the round's spawn.
- Middle-drag pans the camera; right-drag rotates and tilts; mouse wheel zooms; Q/E rotates by 45 degrees.
- Use **Reset View** (or Home) to restore the default tactical framing.
- Escape cancels targeting and restores movement highlights.

### Phone combat controls

- Tap a highlighted grid square to move or choose a target.
- Drag one finger to pan across the battlefield.
- Twist two fingers to rotate; slide them vertically together to tilt; pinch to zoom in or out.
- Use **Reset View** to return to the default tactical framing.
- Camera gestures are separated from taps so dragging cannot trigger a grid action.

### Rosters

| Faction | Unit | Rarity | Roles | HP / DEF / OFF | Range / Move / Init | Cost |
|---|---|---|---|---:|---:|---:|
| Goblin | Ironbound Goblin Warrior | Common | Melee | 24 / 6 / 8 | 0 / 5 / 5 | 3 |
| Goblin | Hobgoblin Forge-Brute | Rare | Melee | 38 / 7 / 14 | 0 / 3 / 2 | 5 |
| Goblin | Scrapbolt Slinger | Uncommon | Ranged | 19 / 3 / 10 | 5 / 5 / 6 | 4 |
| Goblin | Bogbrew Stitchdoc | Uncommon | Ranged, Healer | 21 / 4 / 5 | 3 / 5 / 4 | 3 |
| Goblin | Sparkspool Shaman | Rare | Magic, Support | 23 / 4 / 7 | 4 / 4 / 5 | 4 |
| Elf | Dawnwood Warden | Common | Melee | 28 / 7 / 8 | 0 / 5 / 5 | 3 |
| Elf | Moonshadow Rogue | Rare | Melee | 20 / 4 / 12 | 0 / 7 / 8 | 4 |
| Elf | Starbough Longbow | Uncommon | Ranged | 18 / 3 / 10 | 6 / 5 / 7 | 4 |
| Elf | Lifesong Tender | Uncommon | Magic, Healer | 20 / 4 / 4 | 4 / 5 / 5 | 3 |
| Elf | Runeweave Sage | Rare | Magic, Support | 22 / 5 / 6 | 4 / 4 / 6 | 5 |

Both rosters cost 19 total. Combat uses Common, Uncommon, and Rare only. Their figure bases use reclaimed wood / one chevron, carved stone / two chevrons, and cast bronze / three chevrons respectively.

The animated Ironbound Goblin, Verdant Alchemist (used for Bogbrew Stitchdoc), and Moonlit Elf Duelist (used for Moonshadow Rogue) are used directly. The other seven future units use readable procedural standees in the POC, with their modeling references shown in the unit inspector. The concept library is in `assets/concepts/combat/`; every unit and both printers also have separate front, back, left, and right references in `assets/concepts/combat/four-view-v2/`.

The supplied enchanted terrain kit has now been separated successfully into nine complete full-resolution assets. The corrected proximity-based split, preview, and validation reports are documented in `docs/terrain-kit-status.md`. The playable POC still uses procedural terrain until the 1.12-million-polygon source kit receives a deliberate runtime optimization and collision pass.

## Android model inspector

The phone app retains rarity/base selection, rank badges, animation playback, the horizontal layer-print summon, the parchment stat ledger, reset, touch-drag rotation, and pinch zoom. Its source remains `scripts/summon_lab.gd` and `main.tscn`; combat does not replace that experience.

## Validation and exports

```powershell
# Combat rules and AI smoke test
Godot_v4.7.1-stable_win64_console.exe --headless --path . -- --combat-smoke-test

# Existing Android inspector smoke test (launch its scene explicitly)
Godot_v4.7.1-stable_win64_console.exe --headless --path . res://main.tscn -- --smoke-test

# Builds
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-debug "Windows Desktop" builds/windows/PrintForge-Combat-POC-0.3.5.exe
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-debug "Android Model Inspector" builds/android/PrintForge-Model-Inspector-0.3.0-arm64.apk
Godot_v4.7.1-stable_win64_console.exe --headless --path . --export-debug "Android Combat POC" builds/android/PrintForge-Combat-POC-0.3.5-arm64.apk
```

Combat smoke success prints `COMBAT_SMOKE_OK`; inspector smoke success prints `SUMMON_LAB_SMOKE_TEST_OK`.
