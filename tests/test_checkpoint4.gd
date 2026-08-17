extends Node
var failures: Array[String] = []
func require(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func _ready() -> void:
	var migrated := ProfileRules.migrate({"schema_version":3,"coins":12,"onboarding":{"state":"choose_starter","starter_id":"","starter_instance_id":""}})
	require(int(migrated.settings.text_scale_bps) == 10000 and not bool(migrated.settings.high_contrast), "settings migration defaults")
	var settings_result := AccessibilityRules.save(migrated, {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":true,"ai_difficulty":"Master"})
	require(bool(settings_result.ok) and int(settings_result.profile.settings.text_scale_bps) == 15000, "settings save validates")
	require(not bool(AccessibilityRules.save(migrated, {"text_scale_bps":11111}).ok), "invalid text scale rejected")
	require(BattleSpriteStage.select_frame("attack", 0, true, true, 0.2) == 0 and BattleSpriteStage.select_frame("attack", 0, true, false, 0.2) == 5 and BattleSpriteStage.select_frame("attack", 0, false, false, 0.2) == 7, "sprite frames support reduced motion and hit response")
	require(BattleSpriteStage.sprite_path_for("cinderpaw").ends_with("cinderpaw_sprite_sheet.png") and BattleSpriteStage.sprite_path_for("future_unmapped_creature").ends_with("mossmunk_sprite_sheet.png"), "catalog sprite mapping safely falls back for unknown future IDs")
	CreatureSpriteCache.clear_for_test()
	var first_stage := BattleSpriteStage.new()
	first_stage.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "", 0, false)
	var first_bounds := CreatureSpriteCache.alpha_bounds_for_path(BattleSpriteStage.sprite_path_for("cinderpaw"))
	var second_stage := BattleSpriteStage.new()
	second_stage.configure({"id":"cinderpaw"}, {"id":"mossmunk"}, "", 0, true)
	var second_bounds := CreatureSpriteCache.alpha_bounds_for_path(BattleSpriteStage.sprite_path_for("cinderpaw"))
	var cinder_path := BattleSpriteStage.sprite_path_for("cinderpaw")
	require(first_bounds == second_bounds and CreatureSpriteCache.texture_load_count(cinder_path) == 1 and CreatureSpriteCache.alpha_bounds_scan_count(cinder_path) == 1, "shared sprite cache reuses imported texture and alpha bounds across recreated stages")
	require(not second_stage.is_processing(), "reduced-motion stage disables processing")
	var armored := BattleState.create([{"creature_id":"cinderpaw","suit_id":"arcane"}], ["mossmunk"], 3, 3, 2)
	var unit := armored.active_unit(0)
	require(int(unit.max_hp) == 54 and int(unit.speed) == 8 and int(unit.armor) == 1, "full suit applies hp speed guard modifiers")
	var invalid := BattleState.create([{"creature_id":"cinderpaw","suit_id":"bad"}], ["mossmunk"], 3, 3, 2)
	require(int(invalid.active_unit(0).max_hp) == 34 and int(invalid.active_unit(0).armor) == 0, "invalid suit falls back")
	armored.turn = 3; armored.active_player = 1
	var hp := int(unit.hp); var hit := BattleRules.apply_intent(armored, 1, {"type":"attack"})
	require(bool(hit.ok) and int(unit.hp) < hp and int(hit.damage) < int(armored.active_unit(1).attack), "guard reduces incoming damage")
	var ai_state := BattleState.create(["cinderpaw","aquafin"], ["mossmunk","voltwig"], 3, 3, 3)
	require(AIOpponent.choose_intent(ai_state, "Master").type == "end_turn", "AI yields the first symmetric setup action")
	ai_state.turn = 3; ai_state.active_player = 1; ai_state.active_unit(1).hp = 5; ai_state.players[1].hand = ["quick_patch"]
	require(AIOpponent.choose_intent(ai_state, "Craftsman").type == "card", "AI uses affordable heal")
	GameManager.profile = settings_result.profile.duplicate(true)
	GameManager.profile.coins = 0; GameManager.profile.xp = 0; GameManager.profile.spool_level = 3
	var reward_state := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2); reward_state.finished = true; reward_state.winner = 0
	var revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.claim_battle_reward(reward_state) and int(GameManager.profile.revision) == revision + 1 and int(GameManager.profile.coins) == 20 and not GameManager.claim_battle_reward(reward_state) and int(GameManager.profile.revision) == revision + 1, "battle reward is single-claim atomic")
	if failures.is_empty(): print("PASS: checkpoint4 accessibility suits and AI")
	call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
