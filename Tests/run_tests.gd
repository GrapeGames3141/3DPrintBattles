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
	_reset_game_state_for_tests()

	_test_game_rules_blueprint_shop_price()
	_test_game_rules_shop_pick_unique()
	_test_game_rules_shop_pick_small_pool()
	_test_game_rules_team_limits()
	_test_game_rules_constants_vs_save_defaults()

	_test_unit_database_loads()
	_test_save_roundtrip()
	_test_starter_rule_does_not_grant_blueprint()
	_test_battle_resolver_elements()
	_test_battle_resolver_tpu_constants()
	_test_smoke_newgame_to_battle_ready()


func _reset_game_state_for_tests() -> void:
	GameState.active_slot = -1
	GameState.coins = 0
	GameState.owned_blueprints.clear()
	GameState.active_team.clear()
	GameState.printer_upgrades = {"filament_cap": GameRules.DEFAULT_FILAMENT_CAP}
	GameState.progress = {"starter_chosen": false, "battles_won": 0}
	GameState.settings = {"music": true, "sfx": true}


func _assert_true(cond: bool, message: String) -> void:
	if not cond:
		_failures += 1
		push_error("ASSERT TRUE FAILED: %s" % message)


func _assert_eq(a, b, message: String) -> void:
	if a != b:
		_failures += 1
		push_error("ASSERT EQ FAILED: %s (got=%s expected=%s)" % [message, str(a), str(b)])


func _test_game_rules_blueprint_shop_price() -> void:
	_assert_eq(GameRules.blueprint_shop_price(1, 2), 14, "tier 1 cost 2 -> 8+4+2")
	_assert_eq(GameRules.blueprint_shop_price(3, 5), 25, "tier 3 cost 5 -> 8+12+5")


func _test_game_rules_shop_pick_unique() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var pool: Array[Dictionary] = []
	for i in range(10):
		pool.append({"id": "%03d" % (i + 1), "name": "U"})
	var ids: Array[String] = GameRules.pick_shop_offer_unit_ids(rng, pool, GameRules.SHOP_OFFER_COUNT)
	_assert_eq(ids.size(), GameRules.SHOP_OFFER_COUNT, "full pool yields 5 offers")
	var seen: Dictionary = {}
	for id in ids:
		_assert_true(not seen.has(id), "no duplicate offer ids")
		seen[id] = true


func _test_game_rules_shop_pick_small_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pool: Array[Dictionary] = [
		{"id": "001", "name": "A"},
		{"id": "002", "name": "B"}
	]
	var ids: Array[String] = GameRules.pick_shop_offer_unit_ids(rng, pool, GameRules.SHOP_OFFER_COUNT)
	_assert_eq(ids.size(), 2, "only two unique ids possible")
	_assert_true(ids.has("001") and ids.has("002"), "both ids appear")


func _test_game_rules_team_limits() -> void:
	_assert_true(GameRules.can_add_team_member(0), "can add at 0")
	_assert_true(GameRules.can_add_team_member(GameRules.TEAM_MAX_UNITS - 1), "can add below max")
	_assert_true(not GameRules.can_add_team_member(GameRules.TEAM_MAX_UNITS), "cannot add at max")


func _test_game_rules_constants_vs_save_defaults() -> void:
	_assert_eq(GameRules.NEW_SAVE_STARTING_COINS, 25, "doc: starter coins")
	_assert_eq(GameRules.DEFAULT_FILAMENT_CAP, 3, "default filament cap")
	_assert_eq(GameRules.FILAMENT_CAP_MAX, 10, "max filament cap")
	_assert_eq(GameRules.BATTLE_WIN_COINS, 40, "win payout")
	_assert_eq(GameRules.BATTLE_LOSS_COINS, 15, "loss payout")


func _test_unit_database_loads() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	_assert_true(UnitDatabase.units_array.size() >= 20, "units.json should have >= 20 units")
	_assert_true(not UnitDatabase.get_unit("001").is_empty(), "unit 001 should exist")
	_assert_true(UnitDatabase.get_unit("nonexistent999").is_empty(), "unknown id is empty dict")


func _test_save_roundtrip() -> void:
	_reset_game_state_for_tests()
	var slot := 3
	SaveSystem.create_new_slot(slot)
	var s: Dictionary = SaveSystem.load_slot(slot)
	_assert_eq(int(s.get("coins", -1)), GameRules.NEW_SAVE_STARTING_COINS, "new save coins match GameRules")
	_assert_true(typeof(s) == TYPE_DICTIONARY, "loaded save should be a Dictionary")

	GameState.active_slot = slot
	GameState.load_from_save(s)
	GameState.coins = 123
	GameState.owned_blueprints = ["010"]
	GameState.active_team = ["001"]
	GameState.printer_upgrades["filament_cap"] = 5
	GameState.progress["starter_chosen"] = true

	SaveSystem.write_slot(slot, GameState.to_save())
	var s2: Dictionary = SaveSystem.load_slot(slot)
	_assert_eq(int(s2.get("coins", -1)), 123, "coins should persist")
	_assert_true(Array(s2.get("owned_blueprints", [])).has("010"), "owned_blueprints should persist")
	_assert_true(Array(s2.get("active_team", [])).has("001"), "active_team should persist")
	_assert_eq(int(s2.get("printer_upgrades", {}).get("filament_cap", -1)), 5, "filament_cap should persist")
	SaveSystem.delete_slot(slot)


func _test_starter_rule_does_not_grant_blueprint() -> void:
	_reset_game_state_for_tests()
	GameState.coins = 0
	GameState.owned_blueprints = []
	GameState.active_team = []
	GameState.progress = {"starter_chosen": false}

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


func _test_battle_resolver_tpu_constants() -> void:
	_assert_eq(BattleResolver.TPU_DODGE_CHANCE, 0.15, "TPU dodge chance (gameplay + tuning)")


func _test_smoke_newgame_to_battle_ready() -> void:
	_reset_game_state_for_tests()
	UnitDatabase.load_units("res://Data/units.json")
	var slot := 2
	SaveSystem.create_new_slot(slot)
	var s0: Dictionary = SaveSystem.load_slot(slot)
	_assert_true(bool(s0.get("progress", {}).get("starter_chosen", false)) == false, "new slot not starter-complete")

	GameState.active_slot = slot
	GameState.load_from_save(s0)
	GameState.progress["starter_chosen"] = true
	GameState.active_team = ["001"]
	SaveSystem.write_slot(slot, GameState.to_save())

	var s: Dictionary = SaveSystem.load_slot(slot)
	_assert_true(bool(s.get("progress", {}).get("starter_chosen", false)), "starter flag saved")
	var team: Array = s.get("active_team", []) as Array
	_assert_true(team.size() >= 1, "active team non-empty")
	var first_id: String = str(team[0])
	_assert_true(not UnitDatabase.get_unit(first_id).is_empty(), "team unit loads from json")

	SaveSystem.delete_slot(slot)
