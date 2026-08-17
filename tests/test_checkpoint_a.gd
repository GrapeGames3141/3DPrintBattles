extends Node

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	var first := ProgressionRules.complete_calibration(profile, "2026-08-15", 72)
	var second := ProgressionRules.complete_calibration(first.profile, "2026-08-15", 72)
	var third := ProgressionRules.complete_calibration(second.profile, "2026-08-15", 72)
	var blocked := ProgressionRules.complete_calibration(third.profile, "2026-08-15", 72)
	var rollover := ProgressionRules.complete_calibration(third.profile, "2026-08-16", 72)
	require(bool(first.ok) and int(first.payload.reward) == 22 and int(third.profile.daily_job_count) == 3 and not bool(blocked.ok) and bool(rollover.ok) and int(rollover.profile.daily_job_count) == 1, "calibration is atomic, capped, and rolls over by supplied day")
	var yard_profile: Dictionary = profile.duplicate(true)
	yard_profile.xp = 298
	var yard := ProgressionRules.visit_print_yard(yard_profile, "2026-08-15")
	var yard_repeat := ProgressionRules.visit_print_yard(yard.profile, "2026-08-15")
	require(bool(yard.ok) and int(yard.payload.xp) > 0 and int(yard.payload.spool_gained) == 1 and int(yard.profile.spool_level) == 4 and not bool(yard_repeat.ok) and int(yard_repeat.profile.xp) == int(yard.profile.xp), "Print Yard is once-per-day, advances spool thresholds, and is non-exploitable")
	var opponents_a := ProgressionRules.training_opponent("2026-08-15", ["cinderpaw", "aquafin"])
	var opponents_b := ProgressionRules.training_opponent("2026-08-15", ["cinderpaw", "aquafin"])
	var opponents_c := ProgressionRules.training_opponent("2026-08-16", ["cinderpaw", "aquafin"])
	require(opponents_a == opponents_b and opponents_a.size() == 2 and opponents_a != opponents_c, "training rivals are deterministic and vary by day")
	var deck_saved := ProgressionRules.save_deck_slot(profile, ProgressionRules.STARTER_DECK, "workshop-deck")
	var deck_selected := ProgressionRules.select_deck(deck_saved.profile, "workshop-deck")
	require(bool(deck_saved.ok) and bool(deck_selected.ok) and str(deck_selected.profile.active_deck_id) == "workshop-deck", "named deck slot saves and selects legally")
	var learned := EquipmentRules.learn_suit(profile, "standard")
	var printed := EquipmentRules.print_suit(learned.profile, "standard")
	var equipped := EquipmentRules.equip_suit(printed.profile, str(profile.onboarding.starter_instance_id), str(printed.payload.suit_instance_id))
	var removed := EquipmentRules.remove_suit(equipped.profile, str(profile.onboarding.starter_instance_id))
	require(bool(equipped.ok) and bool(removed.ok) and str(removed.profile.creatures[0].suit_instance_id).is_empty() and str(removed.profile.suits[0].equipped_to).is_empty(), "suit removal keeps both valid instances")
	if failures.is_empty(): print("PASS: checkpoint A calibration yard decks suits and rivals")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
