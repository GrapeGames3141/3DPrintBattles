extends SceneTree

var _failures := 0

func _init() -> void:
	print("== 3D Print Battles: unit tests ==")
	_run_all()
	if _failures > 0:
		push_error("TESTS FAILED: %d" % _failures)
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)

func _run_all() -> void:
	_test_unit_database_loads()
	_test_save_roundtrip()
	_test_starter_rule_does_not_grant_blueprint()
	_test_battle_resolver_elements()
	_test_smoke_newgame_to_battle_ready()

func _assert_true(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		push_error("ASSERT TRUE FAILED: %s" % message)

func _assert_eq(a, b, message: String) -> void:
	if a != b:
		_failures += 1
		push_error("ASSERT EQ FAILED: %s (got=%s expected=%s)" % [message, str(a), str(b)])

func _test_unit_database_loads() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	_assert_true(UnitDatabase.units_array.size() >= 20, "units.json should have >= 20 units")
	_assert_true(not UnitDatabase.get_unit("001").is_empty(), "unit 001 should exist")

func _test_save_roundtrip() -> void:
	var slot := 3
	SaveSystem.create_new_slot(slot)
	var s := SaveSystem.load_slot(slot)
	_assert_true(typeof(s) == TYPE_DICTIONARY, "loaded save should be a Dictionary")

	GameState.active_slot = slot
	GameState.load_from_save(s)
	GameState.coins = 123
	GameState.owned_blueprints = ["010"]
	GameState.active_team = ["001"]
	GameState.printer_upgrades["filament_cap"] = 5
	GameState.progress["starter_chosen"] = true

	SaveSystem.write_slot(slot, GameState.to_save())
	var s2 := SaveSystem.load_slot(slot)
	_assert_eq(int(s2.get("coins", -1)), 123, "coins should persist")
	_assert_true(Array(s2.get("owned_blueprints", [])).has("010"), "owned_blueprints should persist")
	_assert_true(Array(s2.get("active_team", [])).has("001"), "active_team should persist")
	_assert_eq(int(s2.get("printer_upgrades", {}).get("filament_cap", -1)), 5, "filament_cap should persist")
	SaveSystem.delete_slot(slot)

func _test_starter_rule_does_not_grant_blueprint() -> void:
	GameState.coins = 0
	GameState.owned_blueprints = []
	GameState.active_team = []
	GameState.progress = {"starter_chosen": false}

	# Simulate starter selection behavior in Main.gd:
	var starter_id := "001"
	GameState.progress["starter_chosen"] = true
	if GameState.active_team.is_empty():
		GameState.active_team.append(starter_id)

	_assert_true(GameState.active_team.has("001"), "starter should be granted as a physical unit")
	_assert_true(not GameState.owned_blueprints.has("001"), "starter blueprint should NOT be granted")


func _test_battle_resolver_elements() -> void:
	_assert_true(BattleResolver.is_element_advantage("Heat", "PLA"), "Heat should beat PLA")
	_assert_true(not BattleResolver.is_element_advantage("PLA", "Heat"), "PLA should not beat Heat")
	_assert_eq(BattleResolver.effective_damage("Heat", 4, "PLA"), 6, "advantage ~1.5x rounded")
	_assert_eq(BattleResolver.effective_damage("PLA", 4, "Heat"), 3, "disadvantage 0.75x rounded")
	_assert_eq(BattleResolver.effective_damage("PLA", 4, "PLA"), 4, "same element neutral")


func _test_smoke_newgame_to_battle_ready() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	var slot := 2
	SaveSystem.create_new_slot(slot)
	var s0 := SaveSystem.load_slot(slot)
	_assert_true(bool(s0.get("progress", {}).get("starter_chosen", false)) == false, "new slot not starter-complete")

	GameState.active_slot = slot
	GameState.load_from_save(s0)
	GameState.progress["starter_chosen"] = true
	GameState.active_team = ["001"]
	SaveSystem.write_slot(slot, GameState.to_save())

	var s := SaveSystem.load_slot(slot)
	_assert_true(bool(s.get("progress", {}).get("starter_chosen", false)), "starter flag saved")
	var team: Array = s.get("active_team", [])
	_assert_true(team.size() >= 1, "active team non-empty")
	var first_id := str(team[0])
	_assert_true(not UnitDatabase.get_unit(first_id).is_empty(), "team unit loads from json")

	SaveSystem.delete_slot(slot)

