extends Node

const CAMPAIGN_RULES := preload("res://scripts/core/campaign_rules.gd")
const SOLO_BATTLE_FACTORY := preload("res://scripts/core/solo_battle_factory.gd")
const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")
const V3_CATALOG := preload("res://scripts/core/v3_catalog.gd")
## Account state facade. All mutations pass through SaveService journal entries.

signal profile_changed
signal toast_requested(message: String)
var profile: Dictionary = {}
var save_compatibility: Dictionary = {"compatible":true, "state":"ready", "message":""}

func _ready() -> void:
	var qa_storage := SaveService.configure_debug_qa_storage_from_command_line()
	if bool(qa_storage.get("handled", false)) and not bool(qa_storage.get("ok", false)):
		var error := str(qa_storage.get("error", "QA storage could not be configured."))
		push_error(error)
		save_compatibility = {"compatible":false, "state":"qa_storage_rejected", "message":error}
		get_tree().quit(1)
		return
	if not bool(qa_storage.get("handled", false)):
		SaveService.configure_unified_playtest_paths()
	else:
		print("PRINTFORGE_STARTUP marker=qa_storage profile=%s journal=%s receipt_ui=%s user_data=%s" % [SaveService.profile_path, SaveService.journal_path, SaveService.pack_ui_session_path, OS.get_user_data_dir()])
	print("PRINTFORGE_STARTUP marker=profile_load path=%s" % SaveService.profile_path)
	var loaded := SaveService.load_profile()
	if _team_prototype_requested():
		# This internal M1 selector is deliberately before legacy normalization,
		# grants, repair, review floors, or any persistence path.  It only reads
		# the existing v3 snapshot into memory for isolated prototype QA.
		profile = loaded.duplicate(true)
		if SaveService.recovery_status in ["corrupt_primary", "corrupt_backup", "backup_recovered"]:
			save_compatibility = {"compatible":false, "state":SaveService.recovery_status, "message":"Team prototype startup is read-only; existing save recovery state was preserved."}
		else:
			save_compatibility = ProfileRules.compatibility(loaded)
		print("PRINTFORGE_STARTUP marker=team_prototype_read_only compatibility=%s" % str(save_compatibility.get("state", "ready")))
		return
	_initialize_loaded_profile(loaded)
	print("PRINTFORGE_STARTUP marker=profile_ready compatibility=%s has_starter=%s" % [str(save_compatibility.get("state", "ready")), str(has_selected_starter())])

func _team_prototype_requested() -> bool:
	if OS.has_feature("team_prototype"): return true
	for argument in OS.get_cmdline_user_args():
		if str(argument) == "--team-prototype": return true
	return false

## Kept narrow and callable by isolated save-compatibility tests. It is the only
## bootstrap path that is allowed to migrate or persist a loaded profile.
func _initialize_loaded_profile(loaded: Dictionary) -> void:
	# Package/catalog validation must run before profile normalization or any
	# snapshot/journal/receipt-sidecar write. A bad build is not bad player data.
	var catalog_errors: Array[String] = V3_CATALOG.validation_errors()
	if not catalog_errors.is_empty():
		profile = loaded.duplicate(true)
		save_compatibility = {"compatible":false, "state":"catalog_unavailable", "message":"This build could not load its card catalog. Your saved workshop has not been changed. Install the updated PrintForge build and reopen it.", "catalog_errors":catalog_errors.duplicate()}
		push_error("PrintForge catalog unavailable: %s" % "; ".join(catalog_errors))
		return
	if SaveService.recovery_status in ["corrupt_primary", "corrupt_backup"]:
		profile = {}
		save_compatibility = {"compatible":false, "state":SaveService.recovery_status, "message":"No valid save snapshot could be read. Your recoverable files have not been changed."}
		return
	if SaveService.recovery_status == "backup_recovered":
		profile = loaded.duplicate(true)
		save_compatibility = {"compatible":false, "state":"backup_recovered", "message":"A validated backup was recovered. Acknowledge it before this session writes a new primary snapshot."}
		return
	save_compatibility = ProfileRules.compatibility(loaded)
	if not bool(save_compatibility.get("compatible", true)):
		profile = loaded.duplicate(true)
		return
	profile = loaded.duplicate(true)
	if profile.is_empty():
		profile = UNIFIED_RULES.new_profile()
		SaveService.commit_snapshot(profile)
	else:
		# This service reads only the clean v3 namespace, so legacy migration is
		# intentionally never invoked here.
		var loaded_profile := profile.duplicate(true)
		var unified := UNIFIED_RULES.ensure(loaded_profile)
		# JSON storage may deserialize a numeric field as a float while the rules
		# canonicalize the same value to an integer. That is not a migration and
		# must not rewrite a valid player save on every startup. Persist only an
		# actual JSON-value/schema change; still publish the ensured in-memory form.
		var needs_persistence := not _json_value_equivalent(unified, loaded_profile)
		profile = unified
		if needs_persistence:
			SaveService.commit_snapshot(profile)
	apply_android_review_coin_floor(OS.has_feature("android_review"))

func _json_value_equivalent(first: Variant, second: Variant) -> bool:
	return JSON.stringify(_json_value_normalized(first)) == JSON.stringify(_json_value_normalized(second))

func _json_value_normalized(value: Variant) -> Variant:
	# Serializing then parsing normalizes Godot's in-memory numeric representations
	# to the values actually stored by SaveService, without mutating player data.
	var normalized: Variant = JSON.parse_string(JSON.stringify(value))
	return value if normalized == null else normalized

func is_save_read_only() -> bool:
	return not bool(save_compatibility.get("compatible", true))

func save_recovery_message() -> String:
	return str(save_compatibility.get("message", ""))

func apply_android_review_coin_floor(review_enabled: bool) -> bool:
	if is_save_read_only(): return false
	var result := ReviewBuildRules.apply_coin_floor(profile, review_enabled)
	if not bool(result.get("ok", false)):
		return false
	return bool(_commit_rule_result(result, "android_review_coin_floor").get("ok", false))

func default_profile() -> Dictionary:
	return UNIFIED_RULES.new_profile()

func has_selected_starter() -> bool:
	return str(profile.get("onboarding", {}).get("state", "")) == "complete" and not str(profile.get("onboarding", {}).get("starter_id", "")).is_empty()

func choose_starter(creature_id: String) -> bool:
	if _reject_read_only(): return false
	var result := UNIFIED_RULES.choose_starter(profile, creature_id)
	if not bool(result.ok):
		toast_requested.emit(str(result.error))
		return false
	if not bool(_commit_rule_result(result, "choose_starter").get("ok", false)):
		return false
	toast_requested.emit("Starter blueprint unlocked. Print your first Workshop model free.")
	return true

func print_selected_starter() -> bool:
	return apply_transition(UNIFIED_RULES.print_starter(profile), "starter_free_print")
func print_workshop_model_v3(blueprint_id: String, receipt_id := "") -> Dictionary:
	var result := UNIFIED_RULES.print_workshop_model(profile, blueprint_id, receipt_id)
	return _commit_rule_result(result, "v3_workshop_print")

func buy_card_pack(pack_id: String, return_route := "workshop", return_context: Dictionary = {}, expected_price: int = -1) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.buy_pack(profile, pack_id, PackedByteArray(), int(Time.get_unix_time_from_system()), return_route, return_context, expected_price)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Pack unavailable."))); return result
	# Persist result before a reveal may animate; a reload simply resumes it.
	return _commit_rule_result(result, "buy_card_pack")

func claim_next_starter_pack(return_route := "unified_library", return_context: Dictionary = {}) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.claim_next_starter_pack(profile, PackedByteArray(), return_route, return_context)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "No starter pack available.")))
		return result
	return _commit_rule_result(result, "starter_basic_pack")

## Local v3 commerce/reward facades. All use the same journaled mutation path;
## a hosted authority may later replace their clock/entropy provider.
func market_snapshot(unix_time := 0, local_date_key := "") -> Dictionary:
	var prepared := prepare_market_v3(unix_time, local_date_key)
	# Compatibility callers may browse deterministic stock even when a sandbox or
	# offline disk blocks the one-time epoch preparation. They receive no success
	# receipt and cannot purchase until persistence is restored.
	if bool(prepared.get("ok", false)): return prepared.get("snapshot", {})
	return market_snapshot_readonly(unix_time)

func prepare_market_v3(unix_time := 0, local_date_key := "") -> Dictionary:
	if _reject_read_only(): return {"ok":false, "error":save_recovery_message(), "snapshot":{}}
	var stamp := unix_time if unix_time > 0 else int(Time.get_unix_time_from_system())
	var begun := UNIFIED_RULES.begin_newcomer(profile, stamp)
	if bool(begun.get("ok", false)) and begun.profile != profile:
		var committed_begin := _commit_rule_result(begun, "v3_newcomer_started")
		if not bool(committed_begin.get("ok", false)): return {"ok":false, "error":str(committed_begin.get("error", "Market setup could not be saved.")), "snapshot":{}}
	var epochs := UNIFIED_RULES.advance_market_epochs(profile, stamp, local_date_key)
	if bool(epochs.get("ok", false)) and epochs.profile != profile:
		var committed_epochs := _commit_rule_result(epochs, "v3_market_epochs")
		if not bool(committed_epochs.get("ok", false)): return {"ok":false, "error":str(committed_epochs.get("error", "Market setup could not be saved.")), "snapshot":{}}
	var quest_key := local_date_key if not local_date_key.is_empty() else Time.get_date_string_from_unix_time(stamp)
	var quests := UNIFIED_RULES.daily_quests(profile, quest_key)
	if bool(quests.get("ok", false)) and quests.profile != profile:
		var committed_quests := _commit_rule_result(quests, "v3_daily_quests")
		if not bool(committed_quests.get("ok", false)): return {"ok":false, "error":str(committed_quests.get("error", "Daily quest setup could not be saved.")), "snapshot":{}}
	return {"ok":true, "snapshot":UNIFIED_RULES.market_snapshot(profile, stamp), "day_key":quest_key, "revision":int(profile.get("revision", 0))}

func market_snapshot_readonly(unix_time := 0) -> Dictionary:
	var stamp := unix_time if unix_time > 0 else int(Time.get_unix_time_from_system())
	return UNIFIED_RULES.market_snapshot(profile, stamp)
func buy_blueprint_v3(id: String, unix_time := 0) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var stamp := unix_time if unix_time > 0 else int(Time.get_unix_time_from_system())
	var result := UNIFIED_RULES.buy_blueprint(profile, id, stamp)
	return _commit_rule_result(result, "v3_buy_blueprint")
func buy_market_card_v3(id: String, unix_time := 0) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var stamp := unix_time if unix_time > 0 else int(Time.get_unix_time_from_system())
	var result := UNIFIED_RULES.buy_market_card_at(profile, id, stamp)
	return _commit_rule_result(result, "v3_buy_market_card")
func buy_workshop_upgrade_v3(id: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.buy_workshop_upgrade(profile, id, int(Time.get_unix_time_from_system()))
	return _commit_rule_result(result, "v3_buy_workshop_upgrade")
func buy_upgrade_card_v3(id: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.buy_upgrade_card(profile, id, 0, int(Time.get_unix_time_from_system()))
	return _commit_rule_result(result, "v3_buy_upgrade_card")
func buy_cosmetic_v3(id: String, currency := "forge_coins") -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.buy_cosmetic(profile, id, currency, int(Time.get_unix_time_from_system()))
	return _commit_rule_result(result, "v3_buy_cosmetic")
func fake_store_purchase_v3(purchase_id: String, product_id: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.fake_store_purchase_at(profile, purchase_id, product_id, int(Time.get_unix_time_from_system()))
	return _commit_rule_result(result, "v3_fake_store_purchase")
func buy_paid_season_v3() -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.buy_paid_season(profile)
	return _commit_rule_result(result, "v3_paid_season")
func set_wishlist_v3(id: String, wanted: bool) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.set_wishlist(profile, id, wanted)
	return _commit_rule_result(result, "v3_wishlist")
func daily_quests_v3(day_key := "") -> Dictionary:
	var key := day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	var result := UNIFIED_RULES.daily_quests(profile, key)
	if bool(result.get("ok", false)) and result.profile != profile: return _commit_rule_result(result, "v3_daily_quests")
	return result
func reroll_daily_quest_v3(day_key: String, index: int) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.reroll_daily_quest(profile, day_key, index)
	return _commit_rule_result(result, "v3_quest_reroll")
func claim_daily_quest_v3(day_key: String, id: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.claim_daily_quest(profile, day_key, id)
	return _commit_rule_result(result, "v3_quest_claim")
func record_quest_progress_v3(day_key: String, event_name: String, amount := 1) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.record_quest_progress(profile, day_key, event_name, amount)
	return _commit_rule_result(result, "v3_quest_progress")
func academy_three_star_v3(receipt_id: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.academy_three_star_reward(profile, receipt_id)
	return _commit_rule_result(result, "v3_academy_reward")
func claim_season_level_v3(level: int, paid := false) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result := UNIFIED_RULES.claim_season_level(profile, level, paid, int(Time.get_unix_time_from_system()))
	return _commit_rule_result(result, "v3_season_claim")

func current_market_offers(day_key: String = "") -> Array:
	var resolved := day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	return UNIFIED_RULES.market_offers(resolved)

func buy_market_card(card_id: String, day_key: String = "") -> Dictionary:
	# Compatibility route for old callers; use the canonical typed 48-hour shop.
	return buy_market_card_v3(card_id, 0)

func claim_pending_pack_reveal() -> Array:
	var result := claim_pending_pack_reveal_result()
	return result.get("cards", []).duplicate() if bool(result.get("ok", false)) else []

func claim_pending_pack_reveal_result() -> Dictionary:
	if _reject_read_only(): return {"ok":false, "error":save_recovery_message(), "cards":[]}
	var cards: Array = (profile.get("pending_pack_reveal", {}).get("cards", []) as Array).duplicate() if profile.get("pending_pack_reveal", {}) is Dictionary else []
	var bonus: Array = (profile.get("pending_pack_reveal", {}).get("bonus_cards", []) as Array).duplicate() if profile.get("pending_pack_reveal", {}) is Dictionary else []
	cards.append_array(bonus)
	if cards.is_empty(): return {"ok":false, "error":"There are no pack cards waiting to keep.", "cards":[]}
	var result := _commit_rule_result(UNIFIED_RULES.clear_pack_reveal(profile), "pack_reveal_seen")
	if not bool(result.get("ok", false)): return {"ok":false, "error":str(result.get("error", "Pack receipt could not be saved.")), "cards":[]}
	SaveService.clear_pack_ui_session()
	return {"ok":true, "cards":cards, "payload":result.get("payload", {})}

func pending_pack_presentation(receipt: String) -> Dictionary:
	var pending: Dictionary = profile.get("pending_pack_reveal", {}) if profile.get("pending_pack_reveal", {}) is Dictionary else {}
	if pending.is_empty() or str(pending.get("receipt", "")) != receipt: return {}
	var cards: Array = (pending.get("cards", []) as Array).duplicate()
	cards.append_array((pending.get("bonus_cards", []) as Array).duplicate())
	var presentation := SaveService.load_pack_ui_session(receipt)
	var pages := maxi(1, ceili(float(cards.size()) / 5.0))
	var inspector_id := str(presentation.get("inspector_id", ""))
	if not inspector_id.is_empty() and inspector_id not in cards: inspector_id = ""
	return {"page":clampi(int(presentation.get("page", 0)), 0, pages - 1), "inspector_id":inspector_id}

func save_pending_pack_presentation(receipt: String, page: int, inspector_id := "") -> Dictionary:
	var pending: Dictionary = profile.get("pending_pack_reveal", {}) if profile.get("pending_pack_reveal", {}) is Dictionary else {}
	if pending.is_empty() or str(pending.get("receipt", "")) != receipt:
		return {"ok":false, "error":"That pack receipt is no longer waiting."}
	var cards: Array = (pending.get("cards", []) as Array).duplicate()
	cards.append_array((pending.get("bonus_cards", []) as Array).duplicate())
	if not inspector_id.is_empty() and inspector_id not in cards:
		return {"ok":false, "error":"That card is not in the current receipt."}
	var pages := maxi(1, ceili(float(cards.size()) / 5.0))
	var clamped_page := clampi(page, 0, pages - 1)
	if not SaveService.save_pack_ui_session(receipt, {"page":clamped_page,"inspector_id":inspector_id}):
		return {"ok":false, "error":SaveService.last_commit_error}
	return {"ok":true, "presentation":{"page":clamped_page,"inspector_id":inspector_id}}

func save_unified_deck(cards: Array, deck_id := "starter-deck") -> bool:
	return apply_transition(UNIFIED_RULES.save_deck(profile, cards, deck_id), "save_unified_deck")
func save_unified_deck_and_preprints(cards: Array, card_ids: Array, deck_id := "starter-deck") -> bool:
	# Dirty-exit Save is one user transaction. Validate both transitions against a
	# candidate first, then publish one snapshot; deck-only persistence is forbidden.
	if _reject_read_only(): return false
	var deck_result := UNIFIED_RULES.save_deck(profile, cards, deck_id)
	if not bool(deck_result.get("ok", false)):
		toast_requested.emit(str(deck_result.get("error", "That deck is not legal.")))
		return false
	var candidate: Dictionary = deck_result.get("profile", profile) if deck_result.get("profile", profile) is Dictionary else profile
	var preprint_result := UNIFIED_RULES.save_preprints(candidate, card_ids)
	if not bool(preprint_result.get("ok", false)):
		toast_requested.emit(str(preprint_result.get("error", "Those Pre-Prints are not legal.")))
		return false
	return bool(_commit_rule_result(preprint_result, "save_unified_deck_and_preprints").get("ok", false))
func select_unified_deck(deck_id: String) -> bool:
	return apply_transition(UNIFIED_RULES.select_active_deck(profile, deck_id), "select_v3_deck")
func save_preprints_v3(card_ids: Array) -> bool:
	return apply_transition(UNIFIED_RULES.save_preprints(profile, card_ids), "save_v3_preprints")

func apply_printer_upgrades(nodes: Array) -> bool:
	return apply_transition(UNIFIED_RULES.apply_printer_nodes(profile, nodes), "apply_printer_upgrades")
func respec_printer_upgrades() -> bool:
	return apply_transition(UNIFIED_RULES.respec_printer(profile), "respec_printer")
func build_card_node(card_id: String, node: String) -> bool:
	return apply_transition(UNIFIED_RULES.build_card(profile, card_id, node), "build_card")
func respec_card_build(card_id: String) -> bool:
	return apply_transition(UNIFIED_RULES.respec_card(profile, card_id), "respec_card")

func current_team_creature_ids() -> Array:
	var result: Array = []
	for entry in ProfileRules.team_loadout(profile):
		result.append(str(entry.get("creature_id", "")))
	return result

func current_team_loadout() -> Array:
	return ProfileRules.team_loadout(profile)

func active_deck_cards() -> Array:
	for deck in profile.get("decks", []):
		if str(deck.get("id", "")) == str(profile.get("active_deck_id", "starter-deck")):
			return deck.get("cards", []).duplicate() if deck.get("cards", []) is Array else []
	# v3 launches never fall back to a legacy 0.7 deck. Callers must surface the
	# explicit deck validation failure from create_unified_battle instead.
	return []

func create_unified_battle(mode: String, opponent_setup: Dictionary = {}, seed: int = 42):
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var deck := active_deck_cards()
	var reason := UNIFIED_RULES.deck_reason(profile, deck)
	if not reason.is_empty(): return {"ok":false,"error":reason}
	var resolved := _resolve_unified_opponent(mode, opponent_setup)
	if not bool(resolved.get("ok", false)): return resolved
	var setup: Dictionary = resolved.get("setup", {})
	var rival_deck := _unified_rival_deck(setup, deck)
	var match_seed := _stable_unified_seed([mode, str(resolved.get("source_id", "")), str(resolved.get("day_key", "")), str(seed)])
	# Workshop upgrades and pre-prints are launch data; in-battle hardware starts
	# uninstalled and must be played as Upgrade Cards.
	var rival_preprints := _unified_rival_preprints(setup, rival_deck)
	var resolved_mode := str(resolved.get("mode", mode))
	var result_id := str(opponent_setup.get("result_id", ""))
	if result_id.is_empty() and resolved_mode in ["daily", "trial"]:
		var candidate := UNIFIED_RULES.ensure(profile)
		candidate.unified_launch_sequence = int(candidate.get("unified_launch_sequence", 0)) + 1
		result_id = "unified:%s:%s:%d" % [resolved_mode, str(resolved.get("reward_id", resolved.get("source_id", ""))), int(candidate.unified_launch_sequence)]
		if not _commit_candidate(candidate, "unified_battle_launch", {"mode":resolved_mode,"result_id":result_id,"reward_id":str(resolved.get("reward_id", ""))}):
			return {"ok":false,"error":SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Battle launch could not be saved."}
	var state := UNIFIED_BATTLE_STATE.create(deck, rival_deck, match_seed, [], [], profile.get("preprints", []), rival_preprints, profile, {})
	var rival := state.player(1)
	rival.filament = clampi(int(setup.get("rival_starting_filament", 200)), 0, int(rival.filament_max))
	var context := {"mode":resolved_mode,"source_id":str(resolved.get("source_id", "")),"day_key":str(resolved.get("day_key", "")),"reward_id":str(resolved.get("reward_id", "")),"result_id":result_id,"reward":resolved.get("reward", {}).duplicate(true) if resolved.get("reward", {}) is Dictionary else {}}
	return {"ok":true,"battle":state,"mode":context.mode,"source_id":context.source_id,"seed":match_seed,"settlement_context":context}

func create_unified_daily_battle(contract_id: String = "", day_key: String = "", seed: int = 42) -> Dictionary:
	return create_unified_battle("daily", {"contract_id":contract_id,"day_key":day_key}, seed)

func create_unified_trial_battle(encounter_id: String, seed: int = 42) -> Dictionary:
	return create_unified_battle("trial", {"encounter_id":encounter_id}, seed)

func _resolve_unified_opponent(mode: String, requested: Dictionary) -> Dictionary:
	if mode == "local":
		return {"ok":true,"mode":"local","setup":requested.duplicate(true),"source_id":"local","day_key":"","reward":{},"reward_id":"","result_id":""}
	if mode == "daily":
		var day_key := str(requested.get("day_key", profile.get("daily_training", {}).get("day_key", "")))
		if day_key.is_empty(): day_key = Time.get_date_string_from_system()
		if str(profile.get("daily_training", {}).get("day_key", "")) != day_key or daily_training_contracts().is_empty():
			prepare_daily_training(day_key)
		var contracts := daily_training_contracts()
		var requested_id := str(requested.get("contract_id", ""))
		var contract: Dictionary = {}
		for raw in contracts:
			if requested_id.is_empty() or str(raw.get("id", "")) == requested_id: contract = raw.duplicate(true); break
		if contract.is_empty(): return {"ok":false,"error":"Daily Training contract is unavailable."}
		var id := str(contract.get("id", ""))
		return {"ok":true,"mode":"daily","setup":contract,"source_id":id,"day_key":day_key,"reward":contract.get("reward", {}),"reward_id":"daily:%s:%s" % [day_key, id]}
	var encounter_id := str(requested.get("encounter_id", ""))
	if encounter_id.is_empty():
		var tier_id := mode.trim_prefix("trial_") if mode.begins_with("trial_") else mode
		if tier_id in ["trial", ""]: tier_id = "first_layers"
		encounter_id = "%s_1" % tier_id
	var encounter_state := campaign_encounter_state(encounter_id)
	if not bool(encounter_state.get("ok", false)): return {"ok":false,"error":str(encounter_state.get("error", "Workshop Trial unavailable."))}
	if not bool(encounter_state.get("unlocked", false)): return {"ok":false,"error":"Clear the earlier Workshop Trial encounter first."}
	return {"ok":true,"mode":"trial","setup":encounter_state.get("encounter", {}),"source_id":encounter_id,"day_key":"","reward":encounter_state.get("reward", {}),"reward_id":"trial:%s" % encounter_id}

func _unified_rival_deck(setup: Dictionary, fallback: Array) -> Array:
	var result: Array = []
	for raw in setup.get("team", []):
		var creature_id := str(raw.get("creature_id", raw.get("id", ""))) if raw is Dictionary else str(raw)
		if not UNIFIED_RULES.card(creature_id).is_empty():
			for _copy in 8: result.append(creature_id)
	for raw in setup.get("deck", []):
		var card_id := str(raw)
		if not UNIFIED_RULES.card(card_id).is_empty(): result.append(card_id)
	# Every generated rival deck must be legal under the current catalog.  Do not
	# retain old Helm/Iron Claw IDs here: they were retired in favor of full suits
	# and socket gems and used to be silently discarded by UnifiedBattleState.
	var fillers := ["raw_filament", "heated_spool", "emergency_canister", "layer_melt", "print_jam", "standard_full_suit", "iron_gem", "filament_ring", "counter_strike", "speed_spool"]
	for card_id in fillers:
		if result.size() >= 40: break
		if not UNIFIED_RULES.card(card_id).is_empty(): result.append(card_id)
	if result.is_empty():
		for card_id in fallback:
			if not UNIFIED_RULES.card(str(card_id)).is_empty(): result.append(str(card_id))
	# A malformed encounter cannot manufacture an empty/illegal deck.  The
	# canonical starter composition is the deterministic final fallback.
	if result.is_empty():
		for card_id in UNIFIED_RULES.all_cards():
			if str(card_id.get("type", "")) == "creature": result.append(str(card_id.get("id", "")))
	while result.size() < 40:
		result.append(str(result[result.size() % maxi(1, result.size())]))
	return result.slice(0, 40)

func _unified_rival_preprints(setup: Dictionary, rival_deck: Array) -> Array:
	var result: Array = []
	var requested: Array = setup.get("preprints", []) if setup.get("preprints", []) is Array else []
	if requested.is_empty(): requested = setup.get("team", []) if setup.get("team", []) is Array else []
	for raw in requested:
		if result.size() >= 3: break
		var id := str(raw.get("creature_id", raw.get("id", ""))) if raw is Dictionary else str(raw)
		var card := UNIFIED_RULES.card(id)
		if str(card.get("type", "")) == "creature" and result.count(id) < rival_deck.count(id): result.append(id)
	return result

func _stable_unified_seed(parts: Array) -> int:
	var value := 17
	for part in parts:
		for byte in str(part).to_utf8_buffer(): value = int((value * 131 + int(byte)) & 0x7fffffff)
	return value

func settle_unified_battle(result_id: String, battle, victory: bool, coins: int = 0) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var mine: Dictionary = battle.player(0) if battle != null else {}
	var result := UNIFIED_RULES.settle_unified_battle(profile, result_id, mine.get("played", []), victory, int(mine.get("collector", 0)) + int(mine.get("melted", 0)), coins)
	return _commit_rule_result(result, "unified_battle_settlement")

func settle_unified_mode_battle(context: Dictionary, battle, victory: bool, coins: int = 0) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var result_id := str(context.get("result_id", ""))
	var mode := str(context.get("mode", ""))
	if result_id.is_empty() or mode not in ["daily", "trial"]: return {"ok":false,"error":"Battle settlement context is missing."}
	var working := UNIFIED_RULES.ensure(profile)
	if working.get("unified_settlements", {}).has(result_id): return {"ok":true,"profile":working,"payload":{"id":result_id,"duplicate":true,"mode":mode}}
	var reward_payload: Dictionary = {"first_clear":false,"reward":{"coins":0,"xp":0}}
	if victory and mode == "daily":
		var daily_result := _claim_unified_daily_v3(working, str(context.get("source_id", "")), str(context.get("day_key", "")))
		if not bool(daily_result.get("ok", false)): return daily_result
		working = daily_result.get("profile", working)
		reward_payload = daily_result.get("payload", reward_payload)
		var quest_progress := UNIFIED_RULES.record_quest_progress(working, str(context.get("day_key", "")), "win")
		if bool(quest_progress.get("ok", false)): working = quest_progress.profile
	elif victory and mode == "trial":
		var trial_result := _claim_unified_trial_v3(working, str(context.get("source_id", "")), int(battle.turn) if battle != null else 1)
		if not bool(trial_result.get("ok", false)): return trial_result
		working = trial_result.get("profile", working)
		reward_payload = trial_result.get("payload", reward_payload)
	var mine: Dictionary = battle.player(0) if battle != null else {}
	var settled := UNIFIED_RULES.settle_unified_battle(working, result_id, mine.get("played", []), victory, int(mine.get("collector", 0)) + int(mine.get("melted", 0)), coins)
	if not bool(settled.get("ok", false)): return settled
	var payload: Dictionary = settled.get("payload", {}).duplicate(true)
	payload["mode"] = mode
	payload["source_id"] = str(context.get("source_id", ""))
	payload["reward_claim"] = reward_payload
	settled["payload"] = payload
	var committed := _commit_rule_result(settled, "unified_%s_settlement" % mode)
	if not bool(committed.get("ok", false)): return committed
	return {"ok":true,"profile":profile,"payload":payload}

## Unified modes retain the authored Trial and Training encounters, but their
## rewards must never route through the retired instance/XP/coin progression.
## These adapters deliberately record only campaign completion plus v3 Forge
## Coins, Spool XP, and Season XP.
func _claim_unified_daily_v3(source: Dictionary, contract_id: String, day_key: String) -> Dictionary:
	var p := UNIFIED_RULES.ensure(source)
	var daily: Dictionary = p.get("daily_training", {}) if p.get("daily_training", {}) is Dictionary else {}
	if str(daily.get("day_key", "")) != day_key: return {"ok":false,"profile":p,"error":"That training contract is from another day."}
	var contract: Dictionary = {}
	for raw in daily.get("contracts", []):
		if raw is Dictionary and str(raw.get("id", "")) == contract_id: contract = raw.duplicate(true); break
	if contract.is_empty(): return {"ok":false,"profile":p,"error":"That training contract is unavailable."}
	var claimed: Array = daily.get("claimed_ids", []).duplicate() if daily.get("claimed_ids", []) is Array else []
	if contract_id in claimed: return {"ok":true,"profile":p,"payload":{"contract_id":contract_id,"reward":{"coins":0,"xp":0},"first_clear":false}}
	var reward: Dictionary = contract.get("reward", {}) if contract.get("reward", {}) is Dictionary else {}
	var xp := maxi(0, int(reward.get("xp", 0)))
	p.forge_coins += maxi(0, int(reward.get("coins", 0)))
	p.season.xp = int(p.season.get("xp", 0)) + xp
	var spool := UNIFIED_RULES.grant_spool_xp(p, xp)
	claimed.append(contract_id); daily["claimed_ids"] = claimed; p["daily_training"] = daily
	return {"ok":true,"profile":p,"payload":{"contract_id":contract_id,"reward":reward,"first_clear":true,"spool_gained":int(spool.get("levels", 0))}}

func _claim_unified_trial_v3(source: Dictionary, encounter_id: String, turns: int) -> Dictionary:
	var p := UNIFIED_RULES.ensure(source)
	var encounter := Catalog.workshop_trial_encounter(encounter_id)
	if encounter.is_empty(): return {"ok":false,"profile":p,"error":"That Workshop Trial encounter is unavailable."}
	var campaign: Dictionary = p.get("solo_campaign", {}) if p.get("solo_campaign", {}) is Dictionary else {}
	var tier := clampi(int(encounter.get("tier", 1)), 1, Catalog.WORKSHOP_TRIAL_TIERS.size())
	campaign["unlocked_tier"] = clampi(int(campaign.get("unlocked_tier", 1)), 1, Catalog.WORKSHOP_TRIAL_TIERS.size())
	var completed: Array = campaign.get("completed_encounter_ids", []).duplicate() if campaign.get("completed_encounter_ids", []) is Array else []
	var claimed: Array = campaign.get("claimed_reward_ids", []).duplicate() if campaign.get("claimed_reward_ids", []) is Array else []
	var best: Dictionary = campaign.get("best_turn_counts", {}).duplicate() if campaign.get("best_turn_counts", {}) is Dictionary else {}
	var encounters: Array = Catalog.workshop_trial_tier(tier).get("encounters", [])
	var encounter_index := -1
	for index in encounters.size():
		if str(encounters[index].get("id", "")) == encounter_id: encounter_index = index; break
	var unlocked := tier <= int(campaign.unlocked_tier)
	if encounter_index > 0: unlocked = unlocked and str(encounters[encounter_index - 1].get("id", "")) in completed
	if not unlocked: return {"ok":false,"profile":p,"error":"Clear the earlier Workshop Trial encounters first."}
	var safe_turns := maxi(1, turns)
	if encounter_id in claimed:
		var old_best := int(best.get(encounter_id, 0))
		var improved := old_best <= 0 or safe_turns < old_best
		if improved: best[encounter_id] = safe_turns
		campaign["best_turn_counts"] = best; p["solo_campaign"] = campaign
		return {"ok":true,"profile":p,"payload":{"encounter_id":encounter_id,"reward":{"coins":0,"xp":0},"first_clear":false,"best_improved":improved,"turns":int(best.get(encounter_id, old_best))}}
	var reward: Dictionary = CAMPAIGN_RULES.reward_for(encounter)
	var xp := maxi(0, int(reward.get("xp", 0)))
	p.forge_coins += maxi(0, int(reward.get("coins", 0)))
	p.season.xp = int(p.season.get("xp", 0)) + xp
	var spool := UNIFIED_RULES.grant_spool_xp(p, xp)
	completed.append(encounter_id); claimed.append(encounter_id); best[encounter_id] = safe_turns
	if bool(encounter.get("boss", false)): campaign["unlocked_tier"] = mini(Catalog.WORKSHOP_TRIAL_TIERS.size(), maxi(int(campaign.unlocked_tier), tier + 1))
	campaign["completed_encounter_ids"] = completed; campaign["claimed_reward_ids"] = claimed; campaign["best_turn_counts"] = best; p["solo_campaign"] = campaign
	return {"ok":true,"profile":p,"payload":{"encounter_id":encounter_id,"reward":reward,"first_clear":true,"best_improved":true,"turns":safe_turns,"spool_gained":int(spool.get("levels", 0))}}

## A launch-only repair never changes the saved team, inventory, or revision.
func create_solo_battle(rival_team: Array, rival_spool: int, seed: int) -> Dictionary:
	if _reject_read_only(): return {"ok":false, "battle":null, "error":save_recovery_message()}
	return SOLO_BATTLE_FACTORY.create(profile, rival_team, filament_cap(), rival_spool, seed)

func create_solo_battle_from_setup(opponent_setup: Dictionary, seed: int) -> Dictionary:
	if _reject_read_only(): return {"ok":false, "battle":null, "error":save_recovery_message()}
	return SOLO_BATTLE_FACTORY.create_from_setup(profile, opponent_setup, filament_cap(), seed)

func daily_shop(day_key: String) -> Array:
	if _reject_read_only(): return []
	var result := ProgressionRules.daily_shop(profile, day_key)
	if not bool(result.ok): toast_requested.emit(str(result.error)); return []
	var candidate: Dictionary = result.get("profile", profile) if result.get("profile", profile) is Dictionary else profile
	# Rotation cache updates intentionally retain their existing revision and omit
	# a journal row, but the snapshot must be durable before it becomes live.
	if candidate != profile and not _commit_cache_candidate(candidate): return []
	return result.offers

func buy_shop_offer(day_key: String, offer_id: String) -> bool:
	return apply_transition(ProgressionRules.buy_shop_offer(profile, day_key, offer_id), "buy_shop_offer")

func save_team(instance_ids: Array) -> bool:
	return apply_transition(ProgressionRules.save_team(profile, instance_ids), "save_team")

func save_deck(cards: Array) -> bool:
	return apply_transition(ProgressionRules.save_deck(profile, cards), "save_deck")

func save_deck_slot(cards: Array, deck_id: String) -> bool:
	return apply_transition(ProgressionRules.save_deck_slot(profile, cards, deck_id), "save_deck")

func select_deck(deck_id: String) -> bool:
	return apply_transition(ProgressionRules.select_deck(profile, deck_id), "select_deck")

func save_settings(values: Dictionary) -> bool:
	return apply_transition(AccessibilityRules.save(profile, values), "save_settings")

func filament_cap() -> int:
	return clampi(int(profile.spool_level), 3, 10)

func earn_coins(amount: int, reason: String) -> void:
	if _reject_read_only(): return
	if amount <= 0: return
	var candidate := profile.duplicate(true)
	candidate.coins = int(candidate.coins) + amount
	_commit_candidate(candidate, "earn_coins", {"amount":amount,"reason":reason})

func spend_coins(amount: int, reason: String) -> bool:
	if _reject_read_only(): return false
	if amount <= 0 or int(profile.coins) < amount:
		toast_requested.emit("Not enough Forge Coins.")
		return false
	var candidate := profile.duplicate(true)
	candidate.coins = int(candidate.coins) - amount
	return _commit_candidate(candidate, "spend_coins", {"amount":amount,"reason":reason})

func award_battle(win: bool) -> void:
	_award_battle_result(win)

func _award_battle_result(win: bool) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var coins: int = 20 if win else 8
	var xp: int = 30 if win else 10
	var candidate := profile.duplicate(true)
	candidate.coins = int(candidate.coins) + coins
	var xp_result := ProgressionRules.grant_xp(candidate, xp)
	if not bool(xp_result.get("ok", false)): return xp_result
	candidate = xp_result.profile
	var payload := {"win":win,"coins":coins,"xp":xp}
	if not _commit_candidate(candidate, "battle_reward", payload):
		return {"ok":false,"error":SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Battle reward could not be saved."}
	if int(xp_result.payload.spool_gained) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	return {"ok":true,"payload":payload,"profile":profile.duplicate(true)}

func claim_battle_reward(state: BattleState) -> bool:
	if _reject_read_only(): return false
	if not state.finished or state.reward_claimed: return false
	var awarded := _award_battle_result(state.winner == 0)
	if not bool(awarded.get("ok", false)): return false
	state.reward_claimed = true
	return true

func complete_workshop_job(performance: int, day_key: String = "") -> int:
	if _reject_read_only(): return 0
	# Non-educational calibration/pattern job. The pure rules own rollover/limits;
	# UI supplies the day, while legacy callers safely use the local calendar.
	var resolved_day := Time.get_date_string_from_system() if day_key.is_empty() else day_key
	var result := ProgressionRules.complete_calibration(profile, resolved_day, performance)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Calibration is unavailable.")))
		return 0
	var committed := _commit_rule_result(result, "calibration_job")
	if not bool(committed.get("ok", false)): return 0
	return int(result.payload.reward)

func visit_print_yard(day_key: String = "", drill_id: String = "field_practice") -> int:
	if _reject_read_only(): return 0
	var resolved_day := Time.get_date_string_from_system() if day_key.is_empty() else day_key
	var result := ProgressionRules.visit_print_yard(profile, resolved_day, drill_id)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "The Print Yard is unavailable.")))
		return 0
	var committed := _commit_rule_result(result, "print_yard_visit")
	if not bool(committed.get("ok", false)): return 0
	if int(result.payload.get("spool_gained", 0)) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	return int(result.payload.get("xp", 0))

func consume_solo_spool_warmup() -> int:
	if _reject_read_only(): return 0
	var result := ProgressionRules.consume_spool_warmup(profile)
	if not bool(result.get("ok", false)): return 0
	var bonus := int(result.get("payload", {}).get("bonus", 0))
	if bonus <= 0: return 0
	return bonus if bool(_commit_rule_result(result, "consume_spool_warmup").get("ok", false)) else 0

func pending_solo_spool_warmup() -> int:
	return clampi(int(profile.get("pending_spool_warmup", 0)), 0, 1)

func learn_blueprint(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.purchase_creature_blueprint(profile, creature_id), "learn_blueprint")

func print_creature(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.print_creature(profile, creature_id), "print_creature")

func create_deck(deck_id: String, name: String) -> bool:
	return apply_transition(ProgressionRules.create_deck(profile, deck_id, name), "create_deck")

func duplicate_deck(source_id: String, target_id: String) -> bool:
	return apply_transition(ProgressionRules.duplicate_deck(profile, source_id, target_id), "duplicate_deck")

func rename_deck(deck_id: String, name: String) -> bool:
	return apply_transition(ProgressionRules.rename_deck(profile, deck_id, name), "rename_deck")

func delete_deck(deck_id: String) -> bool:
	return apply_transition(ProgressionRules.delete_deck(profile, deck_id), "delete_deck")

func learn_suit_blueprint(tier_id: String) -> bool:
	return apply_transition(ProgressionRules.learn_suit_blueprint(profile, tier_id), "learn_suit_blueprint")
func print_suit(tier_id: String) -> bool:
	return apply_transition(ProgressionRules.print_suit(profile, tier_id), "print_suit")
func equip_suit(creature_instance_id: String, suit_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.equip_suit(profile, creature_instance_id, suit_instance_id), "equip_suit")
func move_suit(creature_instance_id: String, suit_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.equip_suit(profile, creature_instance_id, suit_instance_id), "move_suit")
func remove_suit(creature_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.remove_suit(profile, creature_instance_id), "remove_suit")
func learn_core_blueprint(core_id: String) -> bool:
	return apply_transition(ProgressionRules.learn_core_blueprint(profile, core_id), "learn_core_blueprint")
func print_core(core_id: String) -> bool:
	return apply_transition(ProgressionRules.print_core(profile, core_id), "print_core")
func socket_core(suit_instance_id: String, core_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.socket_core(profile, suit_instance_id, core_instance_id), "socket_core")
func move_core(suit_instance_id: String, core_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.socket_core(profile, suit_instance_id, core_instance_id), "move_core")
func remove_core(suit_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.remove_core(profile, suit_instance_id), "remove_core")

func training_opponent(day_key: String) -> Array:
	return ProgressionRules.training_opponent(day_key, current_team_creature_ids())

func prepare_daily_training(day_key: String) -> Array:
	if _reject_read_only(): return []
	var rules = _opponent_rules()
	if rules == null: return []
	var result: Dictionary = rules.prepare_daily(profile, day_key, current_team_loadout(), active_deck_cards())
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Daily Training is unavailable.")))
		return []
	var changed: bool = result.get("profile", {}) != profile
	if changed:
		var prepared := result.duplicate(true)
		prepared["payload"] = {"day_key":day_key,"contracts":result.get("profile", {}).get("daily_training", {}).get("contracts", [])}
		if not bool(_commit_rule_result(prepared, "prepare_daily_training").get("ok", false)): return []
	return result.get("contracts", [])

func daily_training_contracts() -> Array:
	var rules = _opponent_rules()
	return [] if rules == null else rules.contracts(profile)

func claim_training_victory(contract_id: String, day_key: String) -> Dictionary:
	if _reject_read_only(): return {"ok":false,"error":save_recovery_message()}
	var rules = _opponent_rules()
	if rules == null: return {"ok":false,"error":"Daily Training could not load. Return to the Workshop and try again."}
	var result: Dictionary = rules.claim_victory(profile, contract_id, day_key)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Training reward is unavailable.")))
		return result
	var payload: Dictionary = result.get("payload", {})
	if result.get("profile", {}) != profile:
		var committed := _commit_rule_result(result, "daily_training_victory")
		if not bool(committed.get("ok", false)): return committed
		if int(payload.get("spool_gained", 0)) > 0: toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
		return committed
	return result

func campaign_encounter_state(encounter_id: String) -> Dictionary:
	return CAMPAIGN_RULES.encounter_state(profile, encounter_id)

## Daily-opponent data is irrelevant to the workshop/onboarding first frame.
## Load it only when the Proving Door asks for a contract, keeping a damaged
## optional module from blanking the primary offline shell at startup.
func _opponent_rules():
	var rules = ResourceLoader.load("res://scripts/core/opponent_rules.gd")
	if rules == null:
		push_error("Daily Training module could not load.")
		toast_requested.emit("Daily Training could not load. The Workshop remains available.")
	return rules

func claim_campaign_victory(encounter_id: String, turns: int) -> bool:
	if _reject_read_only(): return false
	var result := CAMPAIGN_RULES.claim_victory(profile, encounter_id, turns)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Workshop Trial reward is unavailable.")))
		return false
	var payload: Dictionary = result.payload
	if not bool(payload.get("first_clear", false)) and not bool(payload.get("best_improved", false)):
		# A completed replay with an equal/worse turn count is a true no-op: it
		# neither journals nor bumps revision, but the result screen may return.
		return true
	var committed := _commit_rule_result(result, "workshop_trial_victory" if bool(payload.get("first_clear", false)) else "workshop_trial_best_turn")
	if not bool(committed.get("ok", false)): return false
	if not bool(payload.get("first_clear", false)):
		toast_requested.emit("New Workshop Trial best: %d turns. No additional rewards were granted." % int(payload.get("turns", 0)))
	if int(payload.get("spool_gained", 0)) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	return true

func creature_mastery(instance_id: String) -> int:
	return CAMPAIGN_RULES.mastery_for(profile, instance_id)

func apply_transition(result: Dictionary, kind: String) -> bool:
	if _reject_read_only(): return false
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "That action is unavailable.")))
		return false
	return bool(_commit_rule_result(result, kind).get("ok", false))

func settle_local_trade(new_profile: Dictionary, audit: Dictionary) -> void:
	if _reject_read_only(): return
	# The guildmate profile is deliberately session-only; only this local profile persists.
	_commit_candidate(new_profile.duplicate(true), "local_trade_settled", audit)

func _creature_instance(instance_id: String) -> Dictionary:
	for creature in profile.creatures:
		if str(creature.instance_id) == instance_id: return creature
	return {}

func _commit_rule_result(result: Dictionary, kind: String) -> Dictionary:
	if not bool(result.get("ok", false)): return result
	var payload: Dictionary = result.get("payload", {}) if result.get("payload", {}) is Dictionary else {}
	# Authoritative duplicate receipts already exist in the persisted profile. Do
	# not bump revision or journal them again, but retain their public receipt.
	if bool(payload.get("duplicate", false)):
		var duplicate := result.duplicate(true); duplicate["profile"] = profile.duplicate(true); duplicate["revision"] = int(profile.get("revision", 0)); return duplicate
	var candidate: Dictionary = result.get("profile", profile).duplicate(true) if result.get("profile", profile) is Dictionary else profile.duplicate(true)
	if not _commit_candidate(candidate, kind, payload):
		var failed := result.duplicate(true)
		failed["ok"] = false
		failed["profile"] = profile.duplicate(true)
		failed["error"] = SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Could not save this change. Try again from the recovery ledger."
		return failed
	var committed := result.duplicate(true)
	committed["profile"] = profile.duplicate(true)
	committed["revision"] = int(profile.get("revision", 0))
	return committed

func confirm_new_maker_after_recovery() -> Dictionary:
	var expected_state := str(save_compatibility.get("state", ""))
	if expected_state not in ["corrupt_primary", "corrupt_backup"]: return {"ok":false, "error":"New Maker recovery is not required."}
	var reread := SaveService.load_profile()
	if SaveService.recovery_status == "primary" and not reread.is_empty():
		profile = reread.duplicate(true); save_compatibility = {"compatible":true, "state":"ready", "message":""}; profile_changed.emit()
		return {"ok":true, "profile":profile.duplicate(true), "resumed_primary":true}
	if SaveService.recovery_status != expected_state: return {"ok":false, "error":"Recovery state changed to %s; no files were changed." % SaveService.recovery_status}
	if not SaveService.preserve_corrupt_recovery_evidence(): return {"ok":false, "error":SaveService.last_commit_error}
	var candidate := UNIFIED_RULES.new_profile()
	save_compatibility = {"compatible":true, "state":"ready", "message":""}
	if not _commit_candidate(candidate, "new_maker_after_corrupt_recovery", {"preserved_corrupt_primary":true}):
		save_compatibility = {"compatible":false, "state":expected_state, "message":"The corrupt save was preserved, but the new profile could not be written."}
		return {"ok":false, "error":SaveService.last_commit_error}
	return {"ok":true, "profile":profile.duplicate(true)}

func acknowledge_backup_recovery() -> Dictionary:
	if str(save_compatibility.get("state", "")) != "backup_recovered": return {"ok":false, "error":"There is no recovered backup to acknowledge."}
	var reread := SaveService.load_profile()
	if SaveService.recovery_status == "primary" and not reread.is_empty():
		profile = reread.duplicate(true); save_compatibility = {"compatible":true, "state":"ready", "message":""}; profile_changed.emit()
		return {"ok":true, "profile":profile.duplicate(true), "resumed_primary":true}
	if SaveService.recovery_status != "backup_recovered": return {"ok":false, "error":"Recovery state changed to %s; no files were changed." % SaveService.recovery_status}
	# The invalid primary is preserved before promoting the validated recovered
	# profile. This acknowledgement changes no game rule, reward, or revision.
	if not SaveService.preserve_invalid_save(SaveService.profile_path): return {"ok":false, "error":SaveService.last_commit_error}
	if not SaveService.commit_snapshot(profile): return {"ok":false, "error":SaveService.last_commit_error}
	save_compatibility = {"compatible":true, "state":"ready", "message":""}
	profile_changed.emit()
	return {"ok":true, "profile":profile.duplicate(true), "revision":int(profile.get("revision", 0))}

func create_new_maker_profile() -> Dictionary:
	# Title's destructive choice is a real transaction: the old session remains
	# authoritative until the empty choose-starter snapshot has been persisted.
	if _reject_read_only(): return {"ok":false, "error":save_recovery_message()}
	var candidate := UNIFIED_RULES.new_profile()
	if not _commit_candidate(candidate, "title_new_maker", {"entry":"title"}):
		return {"ok":false, "error":SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Could not save the new maker profile."}
	SaveService.clear_pack_ui_session()
	return {"ok":true, "profile":profile.duplicate(true), "revision":int(profile.get("revision", 0))}

func _commit_candidate(candidate: Dictionary, kind: String, payload: Dictionary) -> bool:
	if is_save_read_only(): return false
	var persisted := candidate.duplicate(true)
	persisted.revision = int(profile.get("revision", 0)) + 1
	if not SaveService.commit_mutation(persisted, kind, payload, int(persisted.revision)):
		toast_requested.emit(SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Could not save this change.")
		return false
	profile = persisted
	profile_changed.emit()
	return true

func _commit_cache_candidate(candidate: Dictionary) -> bool:
	# Shop rotation is a deterministic cache, so it keeps the current revision and
	# does not create a replay event. It is nevertheless atomic with the snapshot.
	if is_save_read_only(): return false
	var persisted := candidate.duplicate(true)
	if not SaveService.commit_snapshot(persisted):
		toast_requested.emit(SaveService.last_commit_error if not SaveService.last_commit_error.is_empty() else "Could not save this change.")
		return false
	profile = persisted
	profile_changed.emit()
	return true

func mutated(kind: String, payload: Dictionary) -> bool:
	# Compatibility path for old flows that mutate profile in place. New M3
	# transitions should use _commit_rule_result so assignment occurs post-save.
	if is_save_read_only(): return false
	var candidate := profile.duplicate(true)
	return _commit_candidate(candidate, kind, payload)

func _reject_read_only() -> bool:
	if not is_save_read_only(): return false
	toast_requested.emit(save_recovery_message())
	return true
