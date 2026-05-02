# Phase 3 — Core battle mechanics (design contract)

**Purpose:** Single source of truth for combat rules so implementation and tests stay aligned.

## Arena

- **Grid:** 4 columns × 2 rows per side (8 slots per player).
- **Board objects:** Units occupy slots; each side has a **Core Printer** with HP.

## Win conditions

Match ends when either:

1. A side’s **Core Printer HP** reaches **0** (default start **20** unless rules say otherwise), or  
2. **Exhaustion:** that player has **no units on board** and **cannot play** from hand/filament (no usable prints / no legal summons — exact wording lives in `BattleResolver` / battle state).

## Turn flow (target loop)

1. **Opening flair** — Visual coin flip (who goes first).  
2. **Start of turn** — Gain **+1 usable filament** (subject to cap/upgrades).  
3. **Main phase** — Spend filament to **summon** from hand to valid slots.  
4. **Combat phase** — **Drag-and-drop** (or tap-select) targeting for attacks.  
5. **Resolution** — **Simultaneous** damage/effects where the rules specify; then deaths, triggers, abilities.  
6. **End turn** — Advance turn counter, clear turn-scoped flags, hand AI if applicable.

## Filament

- **Cap** starts at **3**, upgradable toward **10** (hub/slicer progression).  
- **Refresh:** replenishes per turn rules (e.g. +1 max filament per turn in master spec — confirm against `GameRules`).

## Elemental triangle (MVP)

- **Heat > PLA > Resin > Heat**  
- **TPU** — Dodge/evasion emphasis (not triangle material).  
- **Carbon** — Neutral / separate rule layer for mythic units.

## Physics & defeat (presentation + rules)

- **Rigid** materials — Knockback flavor where implemented.  
- **Flexible** — Deform/dodge flavor.  
- **0 HP** — “Shatter” / puzzle-piece breakup + audio hook (placeholder OK).

## Implementation map

| Concept | Where to look first |
|--------|---------------------|
| Grid size, core HP, payouts | `Systems/GameRules.gd` |
| Damage, dodge, resolution order | `Systems/BattleResolver.gd` |
| Battle UI / turns | `Battle/BattleScreen.gd` |

## Checklist

- [ ] Any new combat rule → extend `run_tests.gd` where practical.
- [ ] Keep “design doc” (this file) and code in sync when numbers change.

## Implementation checklist (living)

- [x] 4×2 grid per side + Core HP (`Battle/BattleScreen.gd`, `CORE_HP_START`)
- [x] Filament cap / gain tied to slicer upgrade + turn flow (`GameRules`, battle screen)
- [x] Heat / PLA / Resin triangle + **Carbon neutral** damage (`BattleResolver.effective_damage`)
- [x] TPU dodge chance on direct hits (`BattleResolver.tpu_dodges`) + toast when a dodge happens
- [x] Player targeting (slot / Core) + simultaneous resolution pass
- [x] Enemy filament shown in battle status bar
- [x] Coin-flip intro overlay (toss animation + who goes first) before first turn
- [ ] Full exhaustion rules vs master prompt (verify vs `BattleResolver` / `_check_end`)
- [ ] Knockback / shatter presentation passes
