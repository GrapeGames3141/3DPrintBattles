extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func in_view(control: Control, viewport_size: Vector2i) -> bool:
	if control == null:
		return false
	var rect := control.get_global_rect()
	return rect.size.x >= 44.0 and rect.size.y >= 44.0 and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y

func completed_profile() -> Dictionary:
	var profile := RULES.new_profile()
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	profile.forge_coins = 100
	return profile

func exercise_terminal_states(viewport_size: Vector2i) -> void:
	get_viewport().size = viewport_size
	GameManager.profile = completed_profile()
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.size = Vector2(viewport_size)
	main.render()
	await get_tree().process_frame
	var base_coins := int(GameManager.profile.get("forge_coins", 0))
	var base_models := (GameManager.profile.get("printed_models", {}) as Dictionary).duplicate(true)
	var base_revision := int(GameManager.profile.get("revision", 0))
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var begin := main.find_child("BeginCreaturePrint", true, false) as Button
	require(begin != null and in_view(begin, viewport_size), "Forge idle starts a real starter print from an in-viewport primary action at %s." % viewport_size)
	main.render()
	await get_tree().process_frame
	require(int(GameManager.profile.get("forge_coins", 0)) == base_coins and GameManager.profile.get("printed_models", {}) == base_models and int(GameManager.profile.get("revision", 0)) == base_revision, "Forge preview/render is zero-mutation at %s." % viewport_size)
	main.cancel_printer_preview()
	await get_tree().process_frame
	require(int(GameManager.profile.get("forge_coins", 0)) == base_coins and GameManager.profile.get("printed_models", {}) == base_models and int(GameManager.profile.get("revision", 0)) == base_revision, "Forge preview cancel is zero-mutation at %s." % viewport_size)
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	begin = main.find_child("BeginCreaturePrint", true, false) as Button
	if begin != null:
		begin.emit_signal("pressed")
	await get_tree().process_frame
	var printing_stage := main.find_child("ArcaneForgeStage", true, false) as Control
	var before_progress := main.find_child("PrinterProgressStatus", true, false) as Label
	var progress_text := before_progress.text if before_progress != null else ""
	main.advance_printer_for_test(70)
	await get_tree().process_frame
	var after_progress := main.find_child("PrinterProgressStatus", true, false) as Label
	require(printing_stage != null and main.find_child("ArcaneForgeStage", true, false) == printing_stage and after_progress != null and after_progress.text != progress_text, "Same-phase Forge advance retains the persistent stage and updates progress at %s." % viewport_size)
	main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	await get_tree().process_frame
	require(int(GameManager.profile.get("forge_coins", 0)) == base_coins - 20 and (GameManager.profile.get("printed_models", {}) as Dictionary).size() == base_models.size() + 1 and int(GameManager.profile.get("revision", 0)) == base_revision + 1, "Raw completion commits exactly one model, debit, and revision at %s." % viewport_size)
	main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	main.skip_printer()
	await get_tree().process_frame
	await get_tree().process_frame
	var open_pack := main.find_child("OpenStarterPack", true, false) as Button
	var another := main.find_child("PrintAnother", true, false) as Button
	var returned := main.find_child("ReturnAfterPrint", true, false) as Button
	require(main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.AWAKENED and open_pack != null and another != null and returned != null and in_view(open_pack, viewport_size) and in_view(another, viewport_size) and in_view(returned, viewport_size), "Awakened Forge restores starter-pack, another-print, and return terminal actions in viewport at %s." % viewport_size)
	main.render()
	await get_tree().process_frame
	require((GameManager.profile.get("printed_models", {}) as Dictionary).size() == base_models.size() + 1 and int(GameManager.profile.get("forge_coins", 0)) == base_coins - 20 and int(GameManager.profile.get("revision", 0)) == base_revision + 1, "Repeat completion/skip/render cannot duplicate the committed Forge transaction at %s." % viewport_size)
	# Insufficient Forge Coins must stay a presentation failure and expose the
	# sole recovery action rather than a dead Skip button.
	GameManager.profile.forge_coins = 0
	main.return_to_printer_picker()
	await get_tree().process_frame
	begin = main.find_child("BeginCreaturePrint", true, false) as Button
	if begin != null:
		begin.emit_signal("pressed")
	await get_tree().process_frame
	main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	await get_tree().process_frame
	var failed_return := main.find_child("ReturnFailedPrint", true, false) as Button
	require(main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.FAILED and failed_return != null and in_view(failed_return, viewport_size) and (GameManager.profile.get("printed_models", {}) as Dictionary).size() == base_models.size() + 1 and int(GameManager.profile.get("revision", 0)) == base_revision + 1, "Failed Forge has no extra model/revision mutation and restores its Return action at %s." % viewport_size)
	main.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	for viewport_size in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		get_viewport().size = viewport_size
		await exercise_terminal_states(viewport_size)
	if failures.is_empty():
		print("PASS: checkpoint6 visual Forge terminal states")
	get_tree().quit(0 if failures.is_empty() else 1)
