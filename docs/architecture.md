# PrintForge architecture

PrintForge contains two Godot applications in one repository. Windows launches the tactical combat proof of concept. Android exports use `mobile_router.tscn` to launch either combat or the separate model inspector based on which scenes the export preset includes.

## Combat runtime

`combat_main.tscn` is intentionally thin. Its `combat_main.gd` script is the composition root and match-flow coordinator: it constructs the subsystems, builds the terrain, owns the current phase, and sequences spawning, initiative, activations, rounds, and victory.

| Module | Responsibility |
| --- | --- |
| `combat_data.gd` | Immutable faction, rarity, roster, unit, stat, ability, concept, and model definitions plus startup validation. |
| `combat_state.gd` | Creation of node-free faction/unit runtime records, versioned snapshot creation/application, filament replenishment, and defeat detection. |
| `combat_commands.gd` | Command schema plus authoritative validation of sender, phase, actor, reserves, filament, and coordinator-supplied legal cells. |
| `combat_network.gd` | Godot ENet host/client lifecycle and reliable command, snapshot, rejection, connection, and disconnect messages. |
| `combat_rules.gd` | Effective stats, temporary-health limits, status mutation, healing, and unit/printer damage formulas. |
| `combat_grid.gd` | Grid/world conversion, weighted reachability and pathfinding, walkability, river cost, distance, and line of sight. |
| `combat_ai.gd` | Tactical choices that do not perform presentation or mutate the turn loop: support timing, healer targets, and movement destination scoring. |
| `combat_unit_view.gd` | Rarity bases, rank marks, animated-model loading/fitting, cardboard concept models, animation playback, print reveal, and hit/heal flashes. |
| `combat_camera.gd` | Desktop and touch pan/orbit/zoom gestures, reset state, and screen-to-grid picking. |
| `combat_hud.gd` | Construction and styling of the top bar, reserve panel, inspector, actions, faction selection, and victory modal. |
| `combat_main.gd` | Coordinates the modules and retains rules that directly sequence multiple subsystems, such as resolving an ability or ending an activation. |

Runtime unit definitions remain in `CombatData.UNITS`. Mutable match records remain small dictionaries referenced by the state, rules, grid, and coordinator. Simulation dictionaries only contain Variant-serializable data; `Node3D` references live separately in the coordinator's `unit_nodes` and `printer_nodes` presentation maps.

## Multiplayer boundary

The launch screen selects Solo, Host ENet, or Join ENet. Solo and multiplayer both submit the same `spawn`, `skip_spawn`, `move`, `attack`, `ability`, and `wait` command dictionaries. In solo mode the coordinator validates and executes them locally. In ENet mode the Goblin client sends serial-numbered commands to the authoritative Elf host on UDP port 7000.

Only the host advances spawning, initiative, activation, rounds, combat formulas, and victory. After accepted commands and turn transitions it sends a versioned full snapshot. The client applies that snapshot in place so `CombatRules` and `CombatGridNavigation` retain their shared dictionary references, then `combat_main.gd` reconciles scene nodes and local animations. Static terrain and unit definitions are not transmitted.

ENet currently targets direct LAN/IP play. Public internet hosts must forward UDP port 7000 or use an external VPN/relay. Matchmaking, accounts, host migration, reconnect persistence, and NAT traversal are deliberately outside this transport layer.

## Match flow

1. `CombatData.validate()` checks roster and asset invariants.
2. The coordinator constructs subsystem objects and the world.
3. Faction selection creates fresh faction state.
4. Spawn phases consume filament and move units from reserve to the board.
5. Initiative creates an ordered queue of living units.
6. Each activation delegates movement to the grid, formulas to the rules module, visuals to the unit view, and choices to the AI when applicable.
7. End-of-round processing replenishes filament and starts another spawn phase.
8. State-level defeat detection ends the battle when a forge is destroyed or an army has no living or reserve units.

In network mode, human input enters this flow only through validated commands; clients never advance the turn loop independently.

## Model inspector boundary

`main.tscn` and `summon_lab.gd` remain an independent model-inspection application. They own the dropdowns, base/rank preview, parchment stat label, animation playback, filament-layer shader, orbit controls, pinch zoom, and reset behavior. Combat does not depend on the inspector.

`mobile_router.tscn` is the common Android entry point. Export filters ensure each APK contains only its intended app and assets.

## Asset pipeline

- `source_assets/` contains immutable downloads and authoring inputs.
- `tools/` contains inspection, splitting, consolidation, and optimization scripts.
- `assets/models/` contains optimized runtime GLBs and textures.
- `assets/concepts/` contains gameplay concepts and four-view cardboard/model references.
- `docs/` contains validation reports and release notes.
- `previews/` contains rendered QA evidence.

## Concurrent task ownership

Use one Codex worktree chat per outcome. Prefer editing the owning module rather than `combat_main.gd`:

- Camera and touch behavior: `combat_camera.gd`
- Movement, terrain cost, or line of sight: `combat_grid.gd`
- Damage, healing, buffs, or status formulas: `combat_rules.gd`
- Unit records, economy rollover, or victory: `combat_state.gd`
- AI choices: `combat_ai.gd`
- Models, cardboard art, bases, or visual effects: `combat_unit_view.gd`
- HUD layout and styling: `combat_hud.gd`
- Unit balance and roster content: `combat_data.gd`
- Turn sequencing or cross-module integration: `combat_main.gd`

Changes to module interfaces or shared dictionary schemas are integration work and should be coordinated through the `combat_main.gd` task rather than changed independently in several worktrees.

## Validation

Run both suites after changing a shared interface:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . -- --combat-smoke-test
Godot_v4.7.1-stable_win64_console.exe --headless --path . res://main.tscn -- --smoke-test
```

Run the transport smoke host and client in separate terminals:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/enet_smoke.gd -- --host
Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/enet_smoke.gd
```

The combat capture argument performs a rendered integration check:

```powershell
Godot_v4.7.1-stable_win64_console.exe --path . -- --combat-capture=C:\path\combat-validation.png
```
