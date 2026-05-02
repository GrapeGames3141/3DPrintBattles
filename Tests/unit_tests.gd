class_name UnitTests
extends RefCounted

## Headless assertions for economy, saves, battle math. Run via [member TestRunner].

var _failures := 0


func run_all() -> int:
	_failures = 0
	_run_all()
	return _failures


func _run_all() -> void:
	_reset_game_state_for_tests()

	_test_game_rules_blueprint_shop_price()
	_test_game_rules_shop_pick_unique()
	_test_game_rules_shop_pick_small_pool()
	_test_game_rules_shop_tier_weight_curve()
	_test_game_rules_team_limits()
	_test_game_rules_can_enter_battle()
	_test_game_rules_shop_refresh()
	_test_game_rules_constants_vs_save_defaults()
	_test_overworld_route_unlocks()
	_test_game_rules_core_armor()
	_test_battle_mode_enemy_filament()
	_test_trade_draft_pool()

	_test_unit_database_loads()
	_test_starter_boss_flags_in_data()
	_test_starter_ids_exist_in_database()
	_test_local_settings_roundtrip()
	_test_save_single_profile_roundtrip()
	_test_migrate_legacy_slot1()
	_test_starter_rule_does_not_grant_blueprint()
	_test_battle_resolver_elements()
	_test_battle_resolver_carbon_neutral()
	_test_battle_resolver_tpu_constants()
	_test_active_roster_full_cap()
	_test_print_mesh_resolver_stub()
	_test_audio_buses_ensure()
	_test_smoke_newgame_to_battle_ready()


func _reset_game_state_for_tests() -> void:
	SaveSystem.delete_save()
	GameState.session_active = false
	GameState.coins = 0
	GameState.owned_blueprints.clear()
	GameState.active_team.clear()
	GameState.printer_upgrades = {"filament_cap": GameRules.DEFAULT_FILAMENT_CAP, "core_armor": 0}
	GameState.progress = {
		"starter_chosen": false,
		"battles_won": 0,
		"quest_math_bonus_claimed": false,
		"quests_claimed": {"add": false, "sub": false, "geo": false}
	}
	GameState.settings = {"music": true, "sfx": true}
	GameState.shop_last_refresh_unix = 0
	GameState.shop_offer_ids.clear()
	GameState.battle_mode = GameRules.BATTLE_MODE_STANDARD


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
		pool.append({"id": "%03d" % (i + 1), "name": "U", "tier_level": 1})
	var ids: Array[String] = GameRules.pick_shop_offer_unit_ids(rng, pool, GameRules.SHOP_OFFER_COUNT)
	_assert_eq(ids.size(), GameRules.SHOP_OFFER_COUNT, "full pool yields offer count")
	var seen: Dictionary = {}
	for id in ids:
		_assert_true(not seen.has(id), "no duplicate offer ids")
		seen[id] = true


func _test_game_rules_shop_pick_small_pool() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pool: Array[Dictionary] = [
		{"id": "001", "name": "A", "tier_level": 1},
		{"id": "002", "name": "B", "tier_level": 1}
	]
	var ids: Array[String] = GameRules.pick_shop_offer_unit_ids(rng, pool, GameRules.SHOP_OFFER_COUNT)
	_assert_eq(ids.size(), 2, "only two unique ids possible")
	_assert_true(ids.has("001") and ids.has("002"), "both ids appear")


func _test_game_rules_team_limits() -> void:
	_assert_true(GameRules.can_add_team_member(0), "can add at 0")
	_assert_true(GameRules.can_add_team_member(GameRules.TEAM_MAX_UNITS - 1), "can add below max")
	_assert_true(not GameRules.can_add_team_member(GameRules.TEAM_MAX_UNITS), "cannot add at max")


func _test_game_rules_can_enter_battle() -> void:
	_assert_true(not GameRules.can_enter_battle(false, 1), "no starter -> no battle")
	_assert_true(not GameRules.can_enter_battle(true, 0), "empty team -> no battle")
	_assert_true(GameRules.can_enter_battle(true, 1), "starter + unit -> battle ok")


func _test_game_rules_shop_tier_weight_curve() -> void:
	_assert_true(GameRules.shop_tier_weight(1) > GameRules.shop_tier_weight(8), "low tier shop-biased")


func _test_game_rules_shop_refresh() -> void:
	_assert_true(GameRules.shop_refresh_due(0, 100), "first shop visit refreshes")
	_assert_true(not GameRules.shop_refresh_due(100, 500), "same day")
	_assert_true(GameRules.shop_refresh_due(100, 100 + GameRules.SHOP_REFRESH_SECONDS), "next day")


func _test_game_rules_constants_vs_save_defaults() -> void:
	_assert_eq(GameRules.NEW_SAVE_STARTING_COINS, 25, "doc: starter coins")
	_assert_eq(GameRules.DEFAULT_FILAMENT_CAP, 3, "default filament cap")
	_assert_eq(GameRules.FILAMENT_CAP_MAX, 10, "max filament cap")
	_assert_eq(GameRules.BATTLE_WIN_COINS, 40, "win payout")
	_assert_eq(GameRules.BATTLE_LOSS_COINS, 15, "loss payout")
	_assert_eq(GameRules.ACTIVE_ROSTER_CAP, 256, "full phase roster cap")
	_assert_eq(GameRules.SHOP_REFRESH_SECONDS, 86400, "24h shop refresh")
	_assert_eq(GameRules.SHOP_OFFER_COUNT, 6, "shop slots")
	_assert_eq(GameRules.QUEST_MATH_ADD_COINS, 15, "quest add reward")
	_assert_eq(GameRules.CORE_ARMOR_SLABS_MAX, 5, "core armor slabs cap")
	_assert_eq(GameRules.CORE_HP_PER_ARMOR_SLAB, 2, "HP per slab")
	_assert_eq(GameRules.TRADE_DRAFT_BLUEPRINT_COINS, 35, "trade draft cost")


func _test_game_rules_core_armor() -> void:
	_assert_eq(GameRules.player_core_hp_bonus(0), 0, "no slabs")
	_assert_eq(GameRules.player_core_hp_bonus(2), 4, "two slabs")
	_assert_eq(GameRules.player_core_hp_bonus(99), GameRules.CORE_ARMOR_SLABS_MAX * GameRules.CORE_HP_PER_ARMOR_SLAB, "clamp max slabs")


func _test_battle_mode_enemy_filament() -> void:
	_assert_eq(GameRules.enemy_filament_max_for_battle_mode(GameRules.BATTLE_MODE_STANDARD), GameRules.DEFAULT_FILAMENT_CAP, "standard enemy cap")
	_assert_eq(GameRules.enemy_filament_max_for_battle_mode(GameRules.BATTLE_MODE_MID), GameRules.DEFAULT_FILAMENT_CAP + 1, "mid enemy cap")
	_assert_eq(GameRules.enemy_filament_max_for_battle_mode(GameRules.BATTLE_MODE_BOSS), GameRules.DEFAULT_FILAMENT_CAP + 2, "boss enemy cap")


func _test_trade_draft_pool() -> void:
	var roster: Array[Dictionary] = [
		{"id": "004", "tier_level": 1},
		{"id": "099", "tier_level": 2},
		{"id": "005", "tier_level": 1}
	]
	var owned: Array[String] = ["005"]
	var pool: Array[String] = GameRules.trade_draft_blueprint_pool(roster, owned)
	_assert_eq(pool.size(), 1, "one tier-1 unowned")
	_assert_true(pool.has("004"), "004 available")


func _test_overworld_route_unlocks() -> void:
	_assert_true(GameRules.overworld_route_unlocked("practice", 0), "practice always")
	_assert_true(not GameRules.overworld_route_unlocked("mid", 0), "mid locked at 0 wins")
	_assert_true(GameRules.overworld_route_unlocked("mid", 1), "mid at 1 win")
	_assert_true(not GameRules.overworld_route_unlocked("boss", 2), "boss locked at 2 wins")
	_assert_true(GameRules.overworld_route_unlocked("boss", 3), "boss at 3 wins")


func _test_unit_database_loads() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	_assert_true(UnitDatabase.units_array.size() >= 20, "units.json should have >= 20 units")
	_assert_true(not UnitDatabase.get_unit("001").is_empty(), "unit 001 should exist")
	_assert_true(UnitDatabase.get_unit("nonexistent999").is_empty(), "unknown id is empty dict")


func _test_starter_ids_exist_in_database() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	for sid in ["001", "002", "003"]:
		var u: Dictionary = UnitDatabase.get_unit(sid)
		_assert_true(not u.is_empty(), "starter id %s must exist in units.json" % sid)
		_assert_true(str(u.get("name", "")).length() > 0, "starter %s has name" % sid)


func _test_starter_boss_flags_in_data() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	var starters: Array[String] = UnitDatabase.starter_unit_ids()
	_assert_eq(starters.size(), 3, "three starter flags")
	_assert_true(starters.has("001") and starters.has("002") and starters.has("003"), "expected starter ids")
	_assert_true(bool(UnitDatabase.get_unit("020").get("boss", false)), "Peek Falcon boss flag")


func _test_local_settings_roundtrip() -> void:
	SaveSystem.write_local_settings({"music": false, "sfx": true})
	var ls: Dictionary = SaveSystem.load_local_settings()
	_assert_eq(bool(ls.get("music", true)), false, "music false persisted")
	_assert_eq(bool(ls.get("sfx", false)), true, "sfx true persisted")
	SaveSystem.write_local_settings({"music": true, "sfx": true})


func _test_save_single_profile_roundtrip() -> void:
	_reset_game_state_for_tests()
	SaveSystem.create_new_save()
	var s: Dictionary = SaveSystem.load_save()
	_assert_eq(int(s.get("coins", -1)), GameRules.NEW_SAVE_STARTING_COINS, "new profile coins")
	_assert_true(typeof(s) == TYPE_DICTIONARY, "loaded save is Dictionary")

	GameState.session_active = true
	GameState.load_from_save(s)
	GameState.coins = 123
	GameState.owned_blueprints = ["010"]
	GameState.active_team = ["001"]
	GameState.printer_upgrades["filament_cap"] = 5
	GameState.printer_upgrades["core_armor"] = 2
	GameState.progress["starter_chosen"] = true

	SaveSystem.write_save(GameState.to_save())
	var s2: Dictionary = SaveSystem.load_save()
	_assert_eq(int(s2.get("coins", -1)), 123, "coins persist")
	_assert_true(Array(s2.get("owned_blueprints", [])).has("010"), "blueprints persist")
	_assert_true(Array(s2.get("active_team", [])).has("001"), "team persists")
	_assert_eq(int(s2.get("printer_upgrades", {}).get("filament_cap", -1)), 5, "filament_cap persists")
	_assert_eq(int(s2.get("printer_upgrades", {}).get("core_armor", -1)), 2, "core_armor persists")
	SaveSystem.delete_save()


func _test_migrate_legacy_slot1() -> void:
	SaveSystem.delete_save()
	var legacy_path := "user://Saves/slot_1.json"
	if FileAccess.file_exists(legacy_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://Saves"))
	_assert_true(not SaveSystem.has_save(), "no profile before legacy migrate")
	var legacy_data: Dictionary = {
		"coins": 77,
		"owned_blueprints": [],
		"active_team": [],
		"printer_upgrades": {"filament_cap": 3},
		"progress": {"starter_chosen": true, "battles_won": 1},
		"settings": {"music": true, "sfx": true}
	}
	var f: FileAccess = FileAccess.open(legacy_path, FileAccess.WRITE)
	_assert_true(f != null, "can write legacy file")
	f.store_string(JSON.stringify(legacy_data))
	f.flush()
	f.close()
	_assert_true(FileAccess.file_exists(legacy_path), "legacy slot file on disk")
	SaveSystem.migrate_legacy_if_needed()
	_assert_true(SaveSystem.has_save(), "profile exists after migration")
	var migrated: Dictionary = SaveSystem.load_save()
	_assert_eq(int(migrated.get("coins", 0)), 77, "legacy coins migrated")
	GameState.session_active = true
	GameState.load_from_save(migrated)
	_assert_eq(int(GameState.printer_upgrades.get("core_armor", -1)), 0, "legacy profile gains core_armor default")
	SaveSystem.delete_save()
	if FileAccess.file_exists(legacy_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))


func _test_starter_rule_does_not_grant_blueprint() -> void:
	_reset_game_state_for_tests()
	GameState.coins = 0
	GameState.owned_blueprints = []
	GameState.active_team = []
	GameState.progress = {
		"starter_chosen": false,
		"battles_won": 0,
		"quest_math_bonus_claimed": false,
		"quests_claimed": {"add": false, "sub": false, "geo": false}
	}

	var starter_id := "001"
	GameState.progress["starter_chosen"] = true
	if GameState.active_team.is_empty():
		GameState.active_team.append(starter_id)

	_assert_true(GameState.active_team.has("001"), "starter unit on team")
	_assert_true(not GameState.owned_blueprints.has("001"), "starter blueprint NOT granted")


func _test_battle_resolver_elements() -> void:
	_assert_true(BattleResolver.is_element_advantage("Heat", "PLA"), "Heat beats PLA")
	_assert_true(not BattleResolver.is_element_advantage("PLA", "Heat"), "PLA does not beat Heat")
	_assert_eq(BattleResolver.effective_damage("Heat", 4, "PLA"), 8, "advantage 2x")
	_assert_eq(BattleResolver.effective_damage("PLA", 4, "Heat"), 2, "disadvantage 0.5x")
	_assert_eq(BattleResolver.effective_damage("PLA", 4, "PLA"), 4, "neutral")


func _test_battle_resolver_carbon_neutral() -> void:
	_assert_eq(BattleResolver.effective_damage("Heat", 4, "Carbon"), 4, "Heat vs Carbon: no triangle")
	_assert_eq(BattleResolver.effective_damage("Carbon", 6, "PLA"), 6, "Carbon atk: no triangle")
	_assert_eq(BattleResolver.effective_damage("Carbon", 4, "Heat"), 4, "Carbon def: no triangle")


func _test_active_roster_full_cap() -> void:
	UnitDatabase.load_units("res://Data/units.json")
	var roster: Array[Dictionary] = UnitDatabase.active_roster_for_stage()
	_assert_eq(roster.size(), GameRules.ACTIVE_ROSTER_CAP, "active roster equals cap")
	_assert_eq(UnitDatabase.units_array.size(), GameRules.ACTIVE_ROSTER_CAP, "units_array padded")


func _test_print_mesh_resolver_stub() -> void:
	var p: String = PrintMeshResolver.try_model_path("999")
	_assert_eq(p, "", "missing gltf returns empty")


func _test_audio_buses_ensure() -> void:
	AudioSettings.ensure_buses()
	AudioSettings.ensure_buses()
	_assert_true(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	_assert_true(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")


func _test_battle_resolver_tpu_constants() -> void:
	_assert_eq(BattleResolver.TPU_DODGE_CHANCE, 0.15, "TPU dodge chance")


func _test_smoke_newgame_to_battle_ready() -> void:
	_reset_game_state_for_tests()
	UnitDatabase.load_units("res://Data/units.json")
	SaveSystem.create_new_save()
	var s0: Dictionary = SaveSystem.load_save()
	_assert_true(bool(s0.get("progress", {}).get("starter_chosen", false)) == false, "new profile needs starter")

	GameState.session_active = true
	GameState.load_from_save(s0)
	GameState.progress["starter_chosen"] = true
	GameState.active_team = ["001"]
	SaveSystem.write_save(GameState.to_save())

	var s: Dictionary = SaveSystem.load_save()
	_assert_true(bool(s.get("progress", {}).get("starter_chosen", false)), "starter saved")
	var team: Array = s.get("active_team", []) as Array
	_assert_true(team.size() >= 1, "team non-empty")
	var first_id: String = str(team[0])
	_assert_true(not UnitDatabase.get_unit(first_id).is_empty(), "unit resolves from json")

	SaveSystem.delete_save()
