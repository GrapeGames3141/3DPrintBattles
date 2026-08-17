extends Node

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile["coins"] = 1000
	var starter_id := str(profile.get("team", [""])[0])
	var targets := ProgressionRules.calibration_pattern("2026-08-15", 0)
	require(targets.size() == 3 and targets == ProgressionRules.calibration_pattern("2026-08-15", 0) and targets != ProgressionRules.calibration_pattern("2026-08-15", 1), "calibration has deterministic distinct three-step daily patterns")
	require(ProgressionRules.calibration_performance(targets, targets) == 100 and ProgressionRules.calibration_performance(targets, [0, 0, 0]) < 100, "calibration performance is integer distance based")
	var calibration := ProgressionRules.complete_calibration(profile, "2026-08-15", 100)
	require(bool(calibration.get("ok", false)) and int(calibration.get("payload", {}).get("reward", 0)) == 28, "exact calibration reaches the existing capped 28 coin curve")
	profile = calibration.get("profile", profile)
	var yard_xp := ProgressionRules.visit_print_yard(profile, "2026-08-15", "field_practice")
	require(bool(yard_xp.get("ok", false)) and int(yard_xp.get("payload", {}).get("xp", 0)) == 12, "field practice grants exactly 12 XP")
	var next_day := ProgressionRules.visit_print_yard(profile, "2026-08-16", "team_bond")
	require(bool(next_day.get("ok", false)) and int(next_day.get("profile", {}).get("creature_mastery", {}).get(starter_id, 0)) == 5, "team bond grants exactly five mastery to each saved-team instance")
	var no_capacity := ProgressionRules.visit_print_yard(profile, "2026-08-17", "spool_warmup")
	require(not bool(no_capacity.get("ok", true)) and str(no_capacity.get("profile", {}).get("last_yard_day", "")) == str(profile.get("last_yard_day", "")) and str(no_capacity.get("profile", {}).get("yard_choice", "")) == str(profile.get("yard_choice", "")), "failed spool warmup preserves the prior daily choice atomically")
	profile.spool_level = 4
	var warm := ProgressionRules.visit_print_yard(profile, "2026-08-17", "spool_warmup")
	var consumed := ProgressionRules.consume_spool_warmup(warm.get("profile", {}))
	require(int(consumed.get("payload", {}).get("bonus", 0)) == 1 and int(ProgressionRules.consume_spool_warmup(consumed.get("profile", {})).get("payload", {}).get("bonus", 0)) == 0, "spool warmup is one-shot and idempotently consumed")
	var stacked := ProgressionRules.ensure_fields({"spool_level":8,"pending_spool_warmup":7,"creatures":[],"suits":[],"cores":[],"decks":[],"support_cards":{}})
	require(int(stacked.pending_spool_warmup) == 1, "warmup migration clamps legacy stacking to one pending solo bonus")
	var partial_bond := ProgressionRules.visit_print_yard({"creatures":[{"instance_id":"m1","creature_id":"cinderpaw"}],"team":["m1"],"spool_level":3,"coins":0,"xp":0}, "2026-08-18", "team_bond")
	require(bool(partial_bond.get("ok", false)) and int(partial_bond.get("profile", {}).get("creature_mastery", {}).get("m1", 0)) == 5, "team bond initializes mastery safely on partial profiles")
	var printable: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	printable = ProgressionRules.print_creature(printable.get("profile", profile), "mossmunk")
	require(int(printable.get("profile", {}).get("print_history", {}).get("creatures", {}).get("mossmunk", 0)) == 1, "creature printing increments immutable history")
	var armored := EquipmentRules.learn_suit(printable.get("profile", profile), "standard")
	armored = EquipmentRules.print_suit(armored.get("profile", {}), "standard")
	require(int(armored.get("profile", {}).get("print_history", {}).get("suits", {}).get("standard", 0)) == 1, "suit printing increments immutable history")
	var migrated: Dictionary = ProgressionRules.ensure_fields({"creatures":[{"creature_id":"mossmunk","instance_id":"m1"}],"suits":[],"print_history":{"creatures":{"mossmunk":9},"suits":{"standard":7}},"decks":[],"active_deck_id":""})
	require(int(migrated.print_history.creatures.mossmunk) == 9 and int(migrated.print_history.suits.standard) == 7, "history normalization never decreases higher current counts")
	var deck_profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	var created := ProgressionRules.create_deck(deck_profile, "guard-line", "Guard Line")
	var invalid_duplicate := ProgressionRules.duplicate_deck(created.get("profile", {}), ProgressionRules.STARTER_DECK_ID, "guard-line")
	var renamed := ProgressionRules.rename_deck(created.get("profile", {}), "guard-line", "Masterwork")
	var deleted := ProgressionRules.delete_deck(renamed.get("profile", {}), "guard-line")
	require(bool(created.get("ok", false)) and not bool(invalid_duplicate.get("ok", true)) and bool(renamed.get("ok", false)) and str(renamed.get("profile", {}).get("decks", [])[1].get("name", "")) == "Masterwork" and bool(deleted.get("ok", false)) and str(deleted.get("profile", {}).get("active_deck_id", "")) == ProgressionRules.STARTER_DECK_ID, "five-slot deck lifecycle preserves empty-slot identity, fixed labels, and starter fallback")
	if failures.is_empty(): print("PASS: workshop depth calibration, yard drills, history, suits, and deck lifecycle")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
