extends Node
## Focused deterministic proof for every catalog card and primitive effect.
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var ids := {}
	var art_cells := {}
	for definition in Catalog.SUPPORT_CARDS:
		var id := str(definition.get("id", ""))
		require(not id.is_empty() and not ids.has(id), "unique card id: " + id); ids[id] = true
		var art = definition.get("art", {}); var key := "%s:%d" % [str(art.get("atlas", "")), int(art.get("cell", -1))]
		require(art is Dictionary and int(art.get("cell", -1)) >= 0 and int(art.get("cell", -1)) < 8 and not art_cells.has(key), "valid unique atlas cell: " + id); art_cells[key] = true
		var effects := SupportCardRules.normalized_effects(definition)
		require(not effects.is_empty() and not SupportCardRules.rules_text(definition).is_empty() and not SupportCardRules.target_text(definition).is_empty(), "metadata/effects/rules: " + id)
		_assert_play_effects(definition, effects)
	_assert_landscape_atlas_mapping()
	_assert_rejections_and_snapshot()
	_assert_lazy_art_cache()
	if failures.is_empty(): print("PASS: all 30 support cards, every effect, discard snapshots, atomic rejection, lazy atlas cache")
	call_deferred("finish")

func _prepared_state(card_id: String) -> BattleState:
	var state := BattleState.create(["cinderpaw"], ["mossmunk"], 10, 10, 2)
	state.turn = 2; state.active_player = 0
	state.players[0].hand = [card_id]; state.players[0].deck = ["raw_filament", "heated_spool", "quick_patch"]; state.players[0].discard = []; state.players[0].filament = 10
	var unit := state.active_unit(0); unit.hp = maxi(1, int(unit.max_hp) - 12); unit.shield = 1; unit.attack_buff = 1; unit.cooldown_remaining = 2; unit.attack_debuff = 2; unit.ability_lock_turns = 1
	var foe := state.active_unit(1); foe.hp = maxi(1, int(foe.max_hp) - 4); foe.shield = 1; foe.attack_buff = 1; foe.attack_debuff = 0; foe.ability_lock_turns = 0
	return state

func _assert_play_effects(definition: Dictionary, effects: Array) -> void:
	var id := str(definition.id); var state := _prepared_state(id)
	var expected_filament := 10 - int(definition.cost); var expected_hand := 0; var expected_deck := 3
	var expected := {"self_hp":int(state.active_unit(0).hp), "self_shield":int(state.active_unit(0).shield), "self_buff":int(state.active_unit(0).attack_buff), "self_cooldown":int(state.active_unit(0).cooldown_remaining), "self_debuff":int(state.active_unit(0).attack_debuff), "self_lock":int(state.active_unit(0).ability_lock_turns), "foe_debuff":int(state.active_unit(1).attack_debuff), "foe_lock":int(state.active_unit(1).ability_lock_turns), "discount":0}
	for effect in effects:
		var name := str(effect.effect); var amount := int(effect.amount); var target := str(effect.target)
		match name:
			"filament": expected_filament = mini(10, expected_filament + amount)
			"heal": expected.self_hp = mini(int(state.active_unit(0).max_hp), int(expected.self_hp) + amount)
			"shield": expected.self_shield = int(expected.self_shield) + amount
			"attack_buff": expected.self_buff = int(expected.self_buff) + amount
			"cooldown": expected.self_cooldown = maxi(0, int(expected.self_cooldown) - amount)
			"draw": var draws := mini(amount, mini(4 - expected_hand, expected_deck)); expected_hand += draws; expected_deck -= draws
			"switch_discount": expected.discount = maxi(int(expected.discount), amount)
			"debuff": expected.foe_debuff = int(expected.foe_debuff) + amount; expected.foe_lock = maxi(int(expected.foe_lock), 1)
			"cleanse":
				if target == "foe": expected.foe_debuff = 0; expected.foe_lock = 0
				else: expected.self_debuff = 0; expected.self_lock = 0
	var result := BattleRules.apply_intent(state, 0, {"type":"card", "card_id":id})
	require(bool(result.get("ok", false)) and result.get("card_id", "") == id and result.get("effects", []) == effects, "accepted payload: " + id)
	require(not id in state.players[0].hand and state.players[0].discard.size() == 1 and state.players[0].discard[0] == id, "hand removal/discard: " + id)
	require(int(state.players[0].filament) == expected_filament and state.players[0].hand.size() == expected_hand and state.players[0].deck.size() == expected_deck, "forge cost/draw effects: " + id)
	require(int(state.active_unit(0).hp) == int(expected.self_hp) and int(state.active_unit(0).shield) == int(expected.self_shield) and int(state.active_unit(0).attack_buff) == int(expected.self_buff) and int(state.active_unit(0).cooldown_remaining) == int(expected.self_cooldown), "self effects ordered: " + id)
	require(int(state.active_unit(0).attack_debuff) == int(expected.self_debuff) and int(state.active_unit(0).ability_lock_turns) == int(expected.self_lock) and int(state.players[0].switch_discount) == int(expected.discount), "cleanse/team effects: " + id)
	require(int(state.active_unit(1).attack_debuff) == int(expected.foe_debuff) and int(state.active_unit(1).ability_lock_turns) == int(expected.foe_lock), "foe effects: " + id)
	var restored := BattleState.from_snapshot(state.serialize())
	require(restored.serialize() == state.serialize(), "discard survives snapshot: " + id)

func _assert_rejections_and_snapshot() -> void:
	var rejected := _prepared_state("final_pass"); rejected.players[0].filament = 0
	var snapshot := rejected.serialize().duplicate(true)
	require(not BattleRules.apply_intent(rejected, 0, {"type":"card", "card_id":"final_pass"}).get("ok", false) and rejected.serialize() == snapshot, "unaffordable card byte-equal")
	require(not BattleRules.apply_intent(rejected, 0, {"type":"card", "card_id":"unknown"}).get("ok", false) and rejected.serialize() == snapshot, "unknown card byte-equal")
	rejected.players[0].filament = 10; rejected.players[0].hand = []; snapshot = rejected.serialize().duplicate(true)
	require(not BattleRules.apply_intent(rejected, 0, {"type":"card", "card_id":"final_pass"}).get("ok", false) and rejected.serialize() == snapshot, "not-in-hand card byte-equal")

func _assert_landscape_atlas_mapping() -> void:
	var expected := {
		"resources":["raw_filament", "heated_spool", "print_accelerant", "emergency_coil", "calibration", "forge_map", "print_preview", "spare_nozzle"],
		"defense":["quick_patch", "reinforced_layer", "coolant", "dense_infill", "flux_tape", "safety_brace", "repair_drone", "spark_guard"],
		"offense":["arcane_spark", "windup", "filament_snare", "layer_lock", "tempered_edge", "spool_siphon", "anchor_bolt", "final_pass"],
		"utility":["switchback", "overclock", "resin_wash", "hot_swap", "thermal_paste", "soft_reset"]
	}
	for atlas_id in expected:
		var ids: Array = expected[atlas_id]
		for cell in ids.size():
			var art: Dictionary = Catalog.support_card(str(ids[cell])).get("art", {})
			require(str(art.get("atlas", "")) == atlas_id and int(art.get("cell", -1)) == cell, "approved landscape atlas mapping: %s cell %d" % [str(ids[cell]), cell])

func _assert_lazy_art_cache() -> void:
	SupportCardView.reset_cache_for_test(); require(SupportCardView.cache_count_for_test() == 0, "startup card cache remains empty")
	for atlas_id in ["resources", "defense", "offense", "utility"]:
		var first := SupportCardView.atlas_texture_for_test(atlas_id); var second := SupportCardView.atlas_texture_for_test(atlas_id)
		require(first != null and Vector2i(first.get_size()) == Vector2i(1536, 512) and first == second, "lazy cached 4x2 landscape atlas: " + atlas_id)
	var back := SupportCardView.card_back_for_test(); require(back != null and back.get_size().x > 0 and back.get_size().y > 0, "lazy card back")
	var sample := Catalog.support_card("raw_filament"); var sample_region := SupportCardView.atlas_region(sample); require(sample_region == SupportCardView.atlas_region(sample) and sample_region is AtlasTexture and absf((sample_region as AtlasTexture).region.size.x / (sample_region as AtlasTexture).region.size.y - 1.5) <= 0.001, "3:2 atlas region identity cached")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
