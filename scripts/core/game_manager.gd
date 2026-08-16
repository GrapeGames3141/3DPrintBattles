extends Node

const CAMPAIGN_RULES := preload("res://scripts/core/campaign_rules.gd")
const SOLO_BATTLE_FACTORY := preload("res://scripts/core/solo_battle_factory.gd")
## Account state facade. All mutations pass through SaveService journal entries.

signal profile_changed
signal toast_requested(message: String)
var profile: Dictionary = {}
var save_compatibility: Dictionary = {"compatible":true, "state":"ready", "message":""}

func _ready() -> void:
	_initialize_loaded_profile(SaveService.load_profile())

## Kept narrow and callable by isolated save-compatibility tests. It is the only
## bootstrap path that is allowed to migrate or persist a loaded profile.
func _initialize_loaded_profile(loaded: Dictionary) -> void:
	save_compatibility = ProfileRules.compatibility(loaded)
	if not bool(save_compatibility.get("compatible", true)):
		profile = loaded.duplicate(true)
		return
	profile = loaded.duplicate(true)
	if profile.is_empty():
		profile = ProfileRules.new_profile()
		SaveService.commit_snapshot(profile)
	else:
		var migrated := ProfileRules.migrate(profile)
		if migrated != profile:
			profile = migrated
			SaveService.commit_snapshot(profile)
	apply_android_review_coin_floor(OS.has_feature("android_review"))

func is_save_read_only() -> bool:
	return not bool(save_compatibility.get("compatible", true))

func save_recovery_message() -> String:
	return str(save_compatibility.get("message", ""))

func apply_android_review_coin_floor(review_enabled: bool) -> bool:
	if is_save_read_only(): return false
	var result := ReviewBuildRules.apply_coin_floor(profile, review_enabled)
	if not bool(result.get("ok", false)):
		return false
	profile = result.profile
	mutated("android_review_coin_floor", result.payload)
	return true

func default_profile() -> Dictionary:
	return ProfileRules.new_profile()

func has_selected_starter() -> bool:
	return ProfileRules.has_starter(profile)

func choose_starter(creature_id: String) -> bool:
	if _reject_read_only(): return false
	var result := ProfileRules.choose_starter(profile, creature_id)
	if not bool(result.ok):
		toast_requested.emit(str(result.error))
		return false
	profile = result.profile
	mutated("choose_starter", {"creature_id":creature_id, "instance_id":str(result.instance_id)})
	toast_requested.emit("%s is now bound to your Forge." % Catalog.creature(creature_id).name)
	return true

func current_team_creature_ids() -> Array:
	var result: Array = []
	for entry in ProfileRules.team_loadout(profile):
		result.append(str(entry.get("creature_id", "")))
	return result

func current_team_loadout() -> Array:
	return ProfileRules.team_loadout(profile)

func active_deck_cards() -> Array:
	return ProgressionRules.active_deck(profile)

## A launch-only repair never changes the saved team, inventory, or revision.
func create_solo_battle(rival_team: Array, rival_spool: int, seed: int) -> Dictionary:
	if _reject_read_only(): return {"ok":false, "battle":null, "error":save_recovery_message()}
	return SOLO_BATTLE_FACTORY.create(profile, rival_team, filament_cap(), rival_spool, seed)

func daily_shop(day_key: String) -> Array:
	if _reject_read_only(): return []
	var result := ProgressionRules.daily_shop(profile, day_key)
	if not bool(result.ok): toast_requested.emit(str(result.error)); return []
	profile = result.profile
	SaveService.commit_snapshot(profile)
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
	profile.coins = int(profile.coins) + amount
	mutated("earn_coins", {"amount":amount,"reason":reason})

func spend_coins(amount: int, reason: String) -> bool:
	if _reject_read_only(): return false
	if amount <= 0 or int(profile.coins) < amount:
		toast_requested.emit("Not enough Forge Coins.")
		return false
	profile.coins = int(profile.coins) - amount
	mutated("spend_coins", {"amount":amount,"reason":reason})
	return true

func award_battle(win: bool) -> void:
	if _reject_read_only(): return
	var coins: int = 20 if win else 8
	var xp: int = 30 if win else 10
	profile.coins = int(profile.coins) + coins
	var xp_result := ProgressionRules.grant_xp(profile, xp)
	profile = xp_result.profile
	if int(xp_result.payload.spool_gained) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("battle_reward", {"win":win,"coins":coins,"xp":xp})

func claim_battle_reward(state: BattleState) -> bool:
	if _reject_read_only(): return false
	if not state.finished or state.reward_claimed: return false
	state.reward_claimed = true
	award_battle(state.winner == 0)
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
	profile = result.profile
	mutated("calibration_job", result.payload)
	return int(result.payload.reward)

func visit_print_yard(day_key: String = "", drill_id: String = "field_practice") -> int:
	if _reject_read_only(): return 0
	var resolved_day := Time.get_date_string_from_system() if day_key.is_empty() else day_key
	var result := ProgressionRules.visit_print_yard(profile, resolved_day, drill_id)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "The Print Yard is unavailable.")))
		return 0
	profile = result.profile
	if int(result.payload.get("spool_gained", 0)) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("print_yard_visit", result.payload)
	return int(result.payload.get("xp", 0))

func consume_solo_spool_warmup() -> int:
	if _reject_read_only(): return 0
	var result := ProgressionRules.consume_spool_warmup(profile)
	if not bool(result.get("ok", false)): return 0
	var bonus := int(result.get("payload", {}).get("bonus", 0))
	if bonus <= 0: return 0
	profile = result.profile
	mutated("consume_spool_warmup", result.payload)
	return bonus

func pending_solo_spool_warmup() -> int:
	return clampi(int(profile.get("pending_spool_warmup", 0)), 0, 1)

func learn_blueprint(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.purchase_creature_blueprint(profile, creature_id), "learn_blueprint")

func print_creature(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.print_creature(profile, creature_id), "print_creature")

func print_armor(armor_id: String) -> bool:
	return apply_transition(ProgressionRules.print_armor(profile, armor_id), "print_armor")

func create_deck(deck_id: String, name: String) -> bool:
	return apply_transition(ProgressionRules.create_deck(profile, deck_id, name), "create_deck")

func duplicate_deck(source_id: String, target_id: String) -> bool:
	return apply_transition(ProgressionRules.duplicate_deck(profile, source_id, target_id), "duplicate_deck")

func rename_deck(deck_id: String, name: String) -> bool:
	return apply_transition(ProgressionRules.rename_deck(profile, deck_id, name), "rename_deck")

func delete_deck(deck_id: String) -> bool:
	return apply_transition(ProgressionRules.delete_deck(profile, deck_id), "delete_deck")

func learn_armor_blueprint(armor_id: String) -> bool:
	return apply_transition(ProgressionRules.learn_armor_blueprint(profile, armor_id), "learn_armor_blueprint")

func equip_armor(creature_instance_id: String, armor_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.equip_armor(profile, creature_instance_id, armor_instance_id), "equip_armor")

func unequip_armor(creature_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.unequip_armor(profile, creature_instance_id), "unequip_armor")

func reassign_armor(creature_instance_id: String, armor_instance_id: String) -> bool:
	return apply_transition(ProgressionRules.reassign_armor(profile, creature_instance_id, armor_instance_id), "reassign_armor")

func training_opponent(day_key: String) -> Array:
	return ProgressionRules.training_opponent(day_key, current_team_creature_ids())

func campaign_encounter_state(encounter_id: String) -> Dictionary:
	return CAMPAIGN_RULES.encounter_state(profile, encounter_id)

func claim_campaign_victory(encounter_id: String, turns: int) -> bool:
	if _reject_read_only(): return false
	var result := CAMPAIGN_RULES.claim_victory(profile, encounter_id, turns)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "Workshop Trial reward is unavailable.")))
		return false
	profile = result.profile
	var payload: Dictionary = result.payload
	if not bool(payload.get("first_clear", false)) and not bool(payload.get("best_improved", false)):
		# A completed replay with an equal/worse turn count is a true no-op: it
		# neither journals nor bumps revision, but the result screen may return.
		profile_changed.emit()
		return true
	if not bool(payload.get("first_clear", false)):
		toast_requested.emit("New Workshop Trial best: %d turns. No additional rewards were granted." % int(payload.get("turns", 0)))
	if int(payload.get("spool_gained", 0)) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("workshop_trial_victory" if bool(payload.get("first_clear", false)) else "workshop_trial_best_turn", payload)
	return true

func creature_mastery(instance_id: String) -> int:
	return CAMPAIGN_RULES.mastery_for(profile, instance_id)

func apply_transition(result: Dictionary, kind: String) -> bool:
	if _reject_read_only(): return false
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "That action is unavailable.")))
		return false
	profile = result.profile
	mutated(kind, result.get("payload", {}))
	return true

func settle_local_trade(new_profile: Dictionary, audit: Dictionary) -> void:
	if _reject_read_only(): return
	# The guildmate profile is deliberately session-only; only this local profile persists.
	profile = new_profile.duplicate(true)
	mutated("local_trade_settled", audit)

func _creature_instance(instance_id: String) -> Dictionary:
	for creature in profile.creatures:
		if str(creature.instance_id) == instance_id: return creature
	return {}

func mutated(kind: String, payload: Dictionary) -> void:
	if is_save_read_only(): return
	profile.revision = int(profile.revision) + 1
	SaveService.commit_mutation(profile, kind, payload, int(profile.revision))
	profile_changed.emit()

func _reject_read_only() -> bool:
	if not is_save_read_only(): return false
	toast_requested.emit(save_recovery_message())
	return true
