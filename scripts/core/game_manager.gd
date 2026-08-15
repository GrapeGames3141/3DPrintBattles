extends Node
## Account state facade. All mutations pass through SaveService journal entries.

signal profile_changed
signal toast_requested(message: String)
var profile: Dictionary = {}

func _ready() -> void:
	profile = SaveService.load_profile()
	if profile.is_empty():
		profile = ProfileRules.new_profile()
		SaveService.commit_snapshot(profile)
	else:
		var migrated := ProfileRules.migrate(profile)
		if migrated != profile:
			profile = migrated
			SaveService.commit_snapshot(profile)
	apply_android_review_coin_floor(OS.has_feature("android_review"))

func apply_android_review_coin_floor(review_enabled: bool) -> bool:
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

func daily_shop(day_key: String) -> Array:
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
	if amount <= 0: return
	profile.coins = int(profile.coins) + amount
	mutated("earn_coins", {"amount":amount,"reason":reason})

func spend_coins(amount: int, reason: String) -> bool:
	if amount <= 0 or int(profile.coins) < amount:
		toast_requested.emit("Not enough Forge Coins.")
		return false
	profile.coins = int(profile.coins) - amount
	mutated("spend_coins", {"amount":amount,"reason":reason})
	return true

func award_battle(win: bool) -> void:
	var coins: int = 20 if win else 8
	var xp: int = 30 if win else 10
	profile.coins = int(profile.coins) + coins
	var xp_result := ProgressionRules.grant_xp(profile, xp)
	profile = xp_result.profile
	if int(xp_result.payload.spool_gained) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("battle_reward", {"win":win,"coins":coins,"xp":xp})

func claim_battle_reward(state: BattleState) -> bool:
	if not state.finished or state.reward_claimed: return false
	state.reward_claimed = true
	award_battle(state.winner == 0)
	return true

func complete_workshop_job(performance: int, day_key: String = "") -> int:
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

func visit_print_yard(day_key: String = "") -> int:
	var resolved_day := Time.get_date_string_from_system() if day_key.is_empty() else day_key
	var result := ProgressionRules.visit_print_yard(profile, resolved_day)
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "The Print Yard is unavailable.")))
		return 0
	profile = result.profile
	if int(result.payload.get("spool_gained", 0)) > 0:
		toast_requested.emit("Your filament spool grew to %d!" % filament_cap())
	mutated("print_yard_visit", result.payload)
	return int(result.payload.xp)

func learn_blueprint(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.purchase_creature_blueprint(profile, creature_id), "learn_blueprint")

func print_creature(creature_id: String) -> bool:
	return apply_transition(ProgressionRules.print_creature(profile, creature_id), "print_creature")

func print_armor(armor_id: String) -> bool:
	return apply_transition(ProgressionRules.print_armor(profile, armor_id), "print_armor")

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

func apply_transition(result: Dictionary, kind: String) -> bool:
	if not bool(result.get("ok", false)):
		toast_requested.emit(str(result.get("error", "That action is unavailable.")))
		return false
	profile = result.profile
	mutated(kind, result.get("payload", {}))
	return true

func settle_local_trade(new_profile: Dictionary, audit: Dictionary) -> void:
	# The guildmate profile is deliberately session-only; only this local profile persists.
	profile = new_profile.duplicate(true)
	mutated("local_trade_settled", audit)

func _creature_instance(instance_id: String) -> Dictionary:
	for creature in profile.creatures:
		if str(creature.instance_id) == instance_id: return creature
	return {}

func mutated(kind: String, payload: Dictionary) -> void:
	profile.revision = int(profile.revision) + 1
	SaveService.commit_mutation(profile, kind, payload, int(profile.revision))
	profile_changed.emit()
