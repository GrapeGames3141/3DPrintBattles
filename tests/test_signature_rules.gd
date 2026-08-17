extends Node
## Catalog-driven signature and legal AI regression coverage.

var failures: Array[String] = []

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var allowed_effects := {"heal":true,"shield":true,"filament":true,"attack_buff":true,"debuff":true,"cleanse":true,"switch_discount":true,"ability_lock":true}
	var distinct_mappings := {}
	for creature in Catalog.CREATURES:
		var creature_id := str(creature.get("id", ""))
		var signature := Catalog.signature_for_creature(creature_id)
		var description := Catalog.signature_description(creature_id)
		distinct_mappings[JSON.stringify(signature)] = true
		require(not signature.is_empty() and (int(signature.get("damage_bonus", 0)) > 0 or not signature.get("effects", []).is_empty()), "%s has non-generic signature data" % creature_id)
		require(not description.is_empty() and description != "No added effect", "%s has a player-facing signature description" % creature_id)
		for raw_effect in signature.get("effects", []):
			require(raw_effect is Dictionary and allowed_effects.has(str(raw_effect.get("effect", ""))) and str(raw_effect.get("target", "")) in ["self", "foe"] and int(raw_effect.get("amount", 0)) >= 0, "%s only uses implemented deterministic signature primitives with valid target and amount" % creature_id)
		var state := BattleState.create([creature_id], ["mossmunk"], 99, 3, 2)
		state.turn = 3
		state.active_player = 0
		state.opening_player = 1
		state.players[0].filament = 99
		state.active_unit(0)["hp"] = maxi(1, int(state.active_unit(0).get("max_hp", 1)) - 20)
		state.active_unit(0)["attack_debuff"] = 2
		state.active_unit(0)["ability_lock_turns"] = 0
		var before_attacker: Dictionary = state.active_unit(0).duplicate(true)
		var before_defender: Dictionary = state.active_unit(1).duplicate(true)
		var expected_damage := BattleRules.estimate_damage(before_attacker, before_defender, true)
		var result := BattleRules.apply_intent(state, 0, {"type":"ability"})
		require(bool(result.get("ok", false)) and int(result.get("damage", -1)) == expected_damage, "%s resolves catalog signature damage deterministically" % creature_id)
		for raw_effect in signature.get("effects", []):
			if not raw_effect is Dictionary: continue
			var effect := str(raw_effect.get("effect", ""))
			var amount := int(raw_effect.get("amount", 0))
			match effect:
				"heal": require(int(state.active_unit(0).get("hp", 0)) >= int(before_attacker.get("hp", 0)), "%s heals from its signature" % creature_id)
				"shield": require(int(state.active_unit(0).get("shield", 0)) >= amount, "%s gains signature shield" % creature_id)
				"filament": require(int(state.players[0].get("filament", 0)) >= 99 - int(before_attacker.get("ability_cost", 0)), "%s restores signature filament" % creature_id)
				"attack_buff": require(int(state.active_unit(0).get("attack_buff", 0)) >= amount, "%s gains signature attack" % creature_id)
				"debuff": require(int(state.active_unit(1).get("attack_debuff", 0)) >= amount and int(state.active_unit(1).get("ability_lock_turns", 0)) >= 1, "%s applies signature debuff and lock" % creature_id)
				"cleanse": require(int(state.active_unit(0).get("attack_debuff", 0)) == 0, "%s cleanses signature debuffs" % creature_id)
				"switch_discount": require(int(state.players[0].get("switch_discount", 0)) >= amount, "%s grants signature switch discount" % creature_id)
				"ability_lock": require(int(state.active_unit(1).get("ability_lock_turns", 0)) >= amount, "%s applies signature ability lock" % creature_id)
	require(distinct_mappings.size() == Catalog.CREATURES.size(), "all 24 catalog signatures are meaningfully distinct")
	var cinder := BattleState.create(["cinderpaw"], ["mossmunk"], 9, 3, 2)
	require(BattleRules.attack_base(cinder.active_unit(0), true) == int(cinder.active_unit(0).get("attack", 0)) + int(Catalog.signature_for_creature("cinderpaw").get("damage_bonus", 0)), "signature attack base uses catalog bonus instead of generic damage")
	cinder.turn = 3
	cinder.opening_player = 1
	cinder.active_player = 0
	cinder.players[0]["filament"] = 0
	require(not bool(BattleRules.apply_intent(cinder, 0, {"type":"ability"}).get("ok", false)), "signature respects filament lock")
	cinder.players[0]["filament"] = 9
	cinder.active_unit(0)["cooldown_remaining"] = 1
	require(not bool(BattleRules.apply_intent(cinder, 0, {"type":"ability"}).get("ok", false)), "signature respects cooldown lock")
	cinder.active_unit(0)["cooldown_remaining"] = 0
	cinder.active_unit(0)["ability_lock_turns"] = 1
	require(not bool(BattleRules.apply_intent(cinder, 0, {"type":"ability"}).get("ok", false)), "signature respects ability lock")
	cinder.active_unit(0)["ability_lock_turns"] = 0
	cinder.active_unit(1)["shield"] = 999
	var shielded_hp := int(cinder.active_unit(1).get("hp", 0))
	var shielded := BattleRules.apply_intent(cinder, 0, {"type":"ability"})
	require(bool(shielded.get("ok", false)) and int(shielded.get("damage", -1)) == 0 and int(cinder.active_unit(1).get("hp", 0)) == shielded_hp, "signature obeys shield consumption after minimum armor damage")
	var lethal := BattleState.create(["voidmanta"], ["mossmunk"], 9, 3, 2)
	lethal.turn = 3
	lethal.active_player = 0
	lethal.opening_player = 1
	lethal.players[0]["filament"] = 9
	lethal.active_unit(1)["hp"] = 1
	require(bool(BattleRules.apply_intent(lethal, 0, {"type":"ability"}).get("ok", false)) and lethal.finished and lethal.winner == 0, "signature damage resolves a lethal battle exactly once")
	var migrated_source: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	migrated_source["catalog_version"] = "0.1.0"
	var migrated := ProfileRules.migrate(migrated_source)
	require(str(migrated.get("catalog_version", "")) == Catalog.CATALOG_VERSION and migrated.get("creatures", []) == migrated_source.get("creatures", []) and migrated.get("team", []) == migrated_source.get("team", []), "catalog-only migration preserves current profile ownership and team")
	var opening_ai := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 3)
	require(AIOpponent.choose_intent(opening_ai, "Apprentice").get("type", "") == "end_turn", "Apprentice yields the first symmetric setup action")
	var survival_ai := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2)
	survival_ai.turn = 3
	survival_ai.active_player = 1
	survival_ai.active_unit(1)["hp"] = 4
	survival_ai.players[1]["hand"] = ["quick_patch"]
	require(AIOpponent.choose_intent(survival_ai, "Craftsman").get("type", "") == "card", "Craftsman prioritizes affordable survival card")
	var apprentice_recovery := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2)
	apprentice_recovery.turn = 3; apprentice_recovery.active_player = 1; apprentice_recovery.active_unit(1)["hp"] = 4
	apprentice_recovery.players[1]["hand"] = ["arcane_spark", "quick_patch"]
	require(AIOpponent.choose_intent(apprentice_recovery, "Apprentice") == {"type":"card", "card_id":"quick_patch"}, "Apprentice chooses recovery over earlier attack buff at low health")
	var lethal_ai := BattleState.create(["mossmunk"], ["cinderpaw"], 9, 9, 2)
	lethal_ai.turn = 3
	lethal_ai.active_player = 1
	lethal_ai.active_unit(0)["hp"] = 15
	require(AIOpponent.choose_intent(lethal_ai, "Master").get("type", "") == "ability", "Master plans catalog signature lethal damage")
	var basic_lethal_ai := BattleState.create(["mossmunk"], ["cinderpaw"], 3, 3, 2)
	basic_lethal_ai.turn = 3
	basic_lethal_ai.active_player = 1
	basic_lethal_ai.active_unit(0)["hp"] = 1
	basic_lethal_ai.active_unit(1)["cooldown_remaining"] = 1
	require(AIOpponent.choose_intent(basic_lethal_ai, "Craftsman").get("type", "") == "attack", "Craftsman chooses legal lethal basic attack when signature is unavailable")
	var shield_ai := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2)
	shield_ai.turn = 3
	shield_ai.active_player = 1
	shield_ai.active_unit(1)["hp"] = 4
	shield_ai.players[1]["hand"] = ["dense_infill"]
	require(AIOpponent.choose_intent(shield_ai, "Craftsman").get("type", "") == "card", "Craftsman considers defensive shield cards under threat")
	var switch_ai := BattleState.create(["cinderpaw"], ["mossmunk", "aquafin"], 3, 9, 2)
	switch_ai.turn = 3
	switch_ai.active_player = 1
	require(AIOpponent.choose_intent(switch_ai, "Master") == {"type":"switch","index":1}, "Master chooses an affordable elemental switch")
	if failures.is_empty(): print("PASS: catalog signatures, deterministic effects, migration, and AI policy")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
