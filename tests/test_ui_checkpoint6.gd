extends Node
const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 100
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	# Profile dictionaries are intentionally dynamic at this integration boundary.
	# Keep test baselines concrete so a fresh Godot import can compile this scene.
	var base_coins: int = int(GameManager.profile.coins)
	var base_count: int = GameManager.profile.creatures.size()
	var base_revision: int = int(GameManager.profile.revision)
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var persistent_forge := main.find_child("ArcaneForgeStage", true, false) as ArcaneForgeStage
	main.render()
	await get_tree().process_frame
	require(persistent_forge != null and main.find_child("ArcaneForgeStage", true, false) == persistent_forge, "Forge screen component reattaches one persistent compositor across shell refresh")
	require(main.screen == "printer" and GameManager.profile.creatures.size() == base_count and int(GameManager.profile.coins) == base_coins, "printer preview and render do not mutate")
	main.cancel_printer_preview()
	await get_tree().process_frame
	require(GameManager.profile.creatures.size() == base_count and int(GameManager.profile.coins) == base_coins, "preview cancel is zero mutation")
	main.open_printer("cinderpaw"); main.begin_printer(); await get_tree().process_frame
	var printing_stage := main.find_child("ArcaneForgeStage", true, false) as ArcaneForgeStage
	var printing_shell := printing_stage.get_parent() if printing_stage != null else null
	var progress_label := main.find_child("PrinterProgressStatus", true, false) as Label
	var progress_before := progress_label.text if progress_label != null else ""
	main.advance_printer_for_test(70); await get_tree().process_frame
	require(printing_stage != null and main.find_child("ArcaneForgeStage", true, false) == printing_stage and printing_stage.get_parent() == printing_shell and progress_label != null and progress_label.text != progress_before, "same-phase printer advance preserves shell/stage identity and updates retained progress text")
	main.advance_printer_for_test(6930)
	await get_tree().process_frame
	require(GameManager.profile.creatures.size() == base_count + 1 and int(GameManager.profile.coins) == base_coins - 20 and int(GameManager.profile.revision) == base_revision + 1, "raw-complete commit creates exactly one print and debit")
	main.advance_printer_for_test(7000); main.skip_printer(); main.render(); await get_tree().process_frame
	require(GameManager.profile.creatures.size() == base_count + 1 and main.printer_sequence.phase == ArcaneForgeSequence.AWAKENED, "repeat completion render and skip cannot duplicate")
	GameManager.profile.coins = 0
	main.open_printer("cinderpaw"); main.begin_printer(); main.advance_printer_for_test(7000); await get_tree().process_frame
	require(main.printer_sequence.phase == ArcaneForgeSequence.FAILED and GameManager.profile.creatures.size() == base_count + 1, "failed commit has no print or awakening")
	main.open_printer("cinderpaw"); await get_tree().process_frame
	var key := InputEventKey.new(); key.pressed = true; key.keycode = KEY_ESCAPE; main._unhandled_key_input(key); await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "overview" and get_viewport().gui_get_focus_owner() is Button, "Workshop-origin Forge Escape returns directly to the overview and focuses a visible action")
	main.queue_free()
	if failures.is_empty(): print("PASS: checkpoint6 printer UI transaction safety")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
