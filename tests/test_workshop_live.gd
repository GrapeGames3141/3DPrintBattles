extends Node

const LIVE_LAYER := preload("res://scripts/ui/workshop_station_live_layer.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var sequence := WorkshopLiveSequence.create(5)
	require(sequence.phase() == WorkshopLiveSequence.PRINTING and sequence.phase_progress_bps() == 0, "station presentation starts its deterministic ten-second print")
	sequence.advance(9999, 3)
	require(sequence.phase() == WorkshopLiveSequence.PRINTING and sequence.phase_progress_bps() == 9999, "printing reveal remains monotonic through ten seconds")
	sequence.advance(1, 3)
	require(sequence.phase() == WorkshopLiveSequence.RAW_HOLD, "printing reaches a distinct raw hold")
	sequence.advance(WorkshopLiveSequence.RAW_HOLD_BPS, 3)
	require(sequence.phase() == WorkshopLiveSequence.AWAKENING, "raw hold advances to awakening")
	sequence.advance(WorkshopLiveSequence.AWAKEN_BPS, 3)
	require(sequence.phase() == WorkshopLiveSequence.DEPARTING, "awakening advances to departure")
	sequence.advance(WorkshopLiveSequence.DEPART_BPS, 3)
	require(sequence.phase() == WorkshopLiveSequence.PRINTING and sequence.selected_index(3) == 0, "full loop resets and deterministically selects the next unlocked print")
	sequence.set_capture_progress(5000)
	var frame_a: int = sequence.printer_frame_index(false)
	sequence.set_capture_progress(1300)
	var frame_b: int = sequence.printer_frame_index(false)
	require(frame_a != frame_b and sequence.printer_frame_index(true) == 0, "four-frame printer head has deterministic normal motion and reduced-motion freeze")

	var production: Dictionary = ProfileRules.new_profile()
	production.coins = 180
	var production_floor: Dictionary = ReviewBuildRules.apply_coin_floor(production, false)
	require(not bool(production_floor.ok) and int(production_floor.profile.coins) == 180, "production profiles never receive Android review coins")
	var review_floor: Dictionary = ReviewBuildRules.apply_coin_floor(production, true)
	require(bool(review_floor.ok) and int(review_floor.profile.coins) == 5000, "Android review profile floors coins to exactly 5000")
	var review_again: Dictionary = ReviewBuildRules.apply_coin_floor(review_floor.profile, true)
	require(not bool(review_again.ok) and int(review_again.profile.coins) == 5000, "Android review coin floor is idempotent")

	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 1000
	var moss_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	var moss_print: Dictionary = ProgressionRules.print_creature(moss_blueprint.profile, "mossmunk")
	profile = moss_print.profile
	var aqua_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "aquafin")
	var aqua_print: Dictionary = ProgressionRules.print_creature(aqua_blueprint.profile, "aquafin")
	profile = aqua_print.profile
	profile.team = [str(profile.onboarding.starter_instance_id), str(moss_print.payload.instance_id), str(aqua_print.payload.instance_id)]
	var before: Dictionary = profile.duplicate(true)
	var live := LIVE_LAYER.new()
	add_child(live)
	live.configure(profile, "printer", false, false, false, 17, true)
	live.set_capture_progress(14000)
	require(live.selected_creature_id() in profile.blueprints, "live sequence selects only learned creature blueprints")
	require(live.team_ids == ["cinderpaw", "mossmunk", "aquafin"], "active team maps to the three shelf display slots")
	require(not live.is_processing() and profile == before, "frozen presentation capture neither processes nor mutates profile state")
	live.configure(profile, "printer", true, true, false, 17, false)
	live.set_capture_progress(11000)
	var frozen_phase: String = live.sequence.phase()
	await get_tree().process_frame
	await get_tree().process_frame
	require(not live.is_processing() and live.sequence.phase() == frozen_phase, "reduced motion freezes a meaningful raw-print frame")
	live.queue_free()
	if failures.is_empty():
		print("PASS: workshop station-live sequence, team shelf, and review coin floor")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
