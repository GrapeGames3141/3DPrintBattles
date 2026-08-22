# Legacy Runtime Boundary

The shipped Workshop, Daily Training, Workshop Trials, and local hot-seat
launches now construct `UnifiedBattleState` and submit only
`UnifiedBattleRules` intents. `scripts/ui/unified_battle_screen_component.gd`
owns the v3 battle composition; `main.gd` supplies shell navigation and
presentation helpers.

`BattleState`/`BattleRules` and local-versus rendering are no longer referenced
by `main.gd` or a shipped launch route. The retained legacy boundary is limited
to Workshop collection/progression presentation: current Workshop screens still
call `ProgressionRules`, `EquipmentRules`, `ArmorCoreDefinitions`, and the
support-card archive presenter for non-battle collection displays.

Removal gate: migrate those Workshop collection displays to the v3
blueprint/model inventory and v3 card viewer, then delete the remaining
progression/presentation modules only after `rg` reports no runtime callers.
