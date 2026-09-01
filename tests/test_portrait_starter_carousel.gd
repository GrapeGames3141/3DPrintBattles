extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const TEST_ROOT := "user://printforge-validation/m1-starter-carousel"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func snapshot() -> String:
	return var_to_str(GameManager.profile)

func _has_dark_cream_font(button: Button) -> bool:
	if button == null: return false
	var color := button.get_theme_color("font_color")
	return color.r <= 0.12 and color.g <= 0.18 and color.b <= 0.26

func _configure_isolated_save_paths() -> void:
	var absolute_root := ProjectSettings.globalize_path(TEST_ROOT)
	var create_error := DirAccess.make_dir_recursive_absolute(absolute_root)
	var directory := DirAccess.open(absolute_root)
	require(create_error == OK and directory != null, "Starter carousel creates and opens its unique test-local SaveService directory before mutation.")
	SaveService.configure_test_paths(TEST_ROOT)
	for path in [SaveService.profile_path, SaveService.profile_temp_path, SaveService.profile_backup_path, SaveService.profile_backup_temp_path, SaveService.journal_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	require(SaveService.profile_path.begins_with(TEST_ROOT) and SaveService.profile_path != SaveService.PROFILE_PATH, "Starter carousel configures a unique test-local SaveService root before mutation.")

func _cleanup_isolated_save_paths() -> void:
	for path in [SaveService.profile_path, SaveService.profile_temp_path, SaveService.profile_backup_path, SaveService.profile_backup_temp_path, SaveService.journal_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	SaveService.reset_paths()

func _ready() -> void:
	await _run_test()

func _run_test() -> void:
	_configure_isolated_save_paths()
	GameManager.profile = RULES.new_profile()
	var viewport := Vector2(576, 1024)
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(viewport)
	subviewport.size_2d_override = Vector2i(viewport)
	subviewport.size_2d_override_stretch = true
	subviewport.disable_3d = true
	add_child(subviewport)
	var canvas := Control.new()
	canvas.size = viewport
	subviewport.add_child(canvas)
	var main := MAIN.instantiate()
	main.screen = "onboarding"
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	var before := snapshot()
	require(main.find_children("StarterCarouselCard", "Control", true, false).size() == 1, "Portrait starter shows exactly one focused card.")
	require(main.find_child("StarterR2PhysicalPlate", true, false) != null, "Portrait starter is mounted on the approved physical desk plate.")
	var seen: Array[String] = []
	for page in 3:
		main.starter_page = page
		main.render()
		await get_tree().process_frame
		var card := main.find_child("StarterCarouselCard", true, false) as Control
		require(card != null and card.get_meta("starter_id", "") in ["cinderpaw", "aquafin", "voltwig"], "Focused card is one catalog starter.")
		seen.append(str(card.get_meta("starter_id", "")) if card != null else "")
		require(main.find_child("StarterPrevious", true, false) != null and main.find_child("StarterNext", true, false) != null, "Carousel has separate 48px paging controls.")
		var previous := main.find_child("StarterPrevious", true, false) as Button
		var next_button := main.find_child("StarterNext", true, false) as Button
		var inspect := main.find_child("StarterInspectFocused", true, false) as Button
		var confirm := main.find_child("StarterConfirmFocused", true, false) as Button
		require(inspect != null and confirm != null and inspect.custom_minimum_size.y >= 48.0 and confirm.custom_minimum_size.y >= 56.0, "Inspect and confirm are separately touch-safe.")
		require(_has_dark_cream_font(previous) and _has_dark_cream_font(next_button) and _has_dark_cream_font(inspect) and _has_dark_cream_font(confirm), "Starter cream-face actions use dark native normal-state copy.")
		if inspect != null: inspect.emit_signal("pressed")
		await get_tree().process_frame
		var inspector_select := main.find_child("StarterInspectorSelect", true, false) as Button
		var inspector_close := main.find_child("StarterInspectorClose", true, false) as Button
		require(snapshot() == before and main.find_child("StarterCardInspector", true, false) != null and _has_dark_cream_font(inspector_select) and _has_dark_cream_font(inspector_close), "Inspect opens UI only with zero profile mutation and dark cream-face inspector actions.")
		main.starter_inspector_id = ""; main.render(); await get_tree().process_frame
	main.starter_page = 2; main.render(); await get_tree().process_frame
	var next := main.find_child("StarterNext", true, false) as Button
	if next != null: next.emit_signal("pressed")
	await get_tree().process_frame
	require(main.starter_page == 0, "Next wraps from third starter to first.")
	require(seen == ["cinderpaw", "aquafin", "voltwig"], "All three starters are reachable.")
	main.pending_starter_id = "invalid"; main.confirm_starter(); await get_tree().process_frame
	require(snapshot() == before, "Invalid confirmation preserves profile exactly.")
	main.pending_starter_id = "cinderpaw"; main.confirm_starter(); await get_tree().process_frame
	require(str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and main.screen == "printer" and main.printer_sequence != null and int(main.printer_sequence.phase) == 0 and main.find_child("FirstPrintR2PhysicalPlate", true, false) != null and main.find_child("FeedbackForgeStage", true, false) == null, "Valid confirmation grants once and routes to the physical idle empty-bed first print.")
	var after := snapshot(); main.confirm_starter(); await get_tree().process_frame
	require(snapshot() == after, "Stale repeat confirmation has zero mutation.")
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame
	_cleanup_isolated_save_paths()
	if failures.is_empty():
		print("PASS: portrait starter carousel")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
