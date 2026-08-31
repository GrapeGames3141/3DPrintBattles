extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const TEST_ROOT := "user://printforge-validation/m1-physical-navigation"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _has_dark_cream_font(button: Button) -> bool:
	if button == null: return false
	var color := button.get_theme_color("font_color")
	return color.r <= 0.12 and color.g <= 0.18 and color.b <= 0.26

func _ready() -> void:
	await _run()

func _clean_paths() -> void:
	SaveService.configure_test_paths(TEST_ROOT)
	for path in [SaveService.profile_path, SaveService.profile_temp_path, SaveService.profile_backup_path, SaveService.profile_backup_temp_path, SaveService.journal_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _mount() -> Dictionary:
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
	main.screen = "workshop"
	main.workshop_view = "overview"
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	return {"main":main, "subviewport":subviewport}

func _run() -> void:
	_clean_paths()
	var base: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	base = RULES.print_starter(base).profile
	GameManager.profile = base
	var mounted := await _mount()
	var main: Control = mounted.main
	var expected := {
		"WorkshopHotspotPrinter":"printer",
		"WorkshopHotspotBattleArena":"proving",
		"WorkshopHotspotCardArchive":"unified_library",
		"WorkshopHotspotDeck":"unified_deck",
		"WorkshopHotspotSupplies":"unified_market",
		"WorkshopHotspotSettings":"settings"
	}
	for node_name in expected:
		# Destination presentation may prepare its own deterministic daily/market
		# snapshot; this route test only proves the Workshop control did not dispatch
		# through a legacy alias. The unavailable route below proves zero mutation.
		GameManager.profile = base.duplicate(true)
		main.screen = "workshop"
		main.workshop_view = "overview"
		main.render()
		await get_tree().process_frame
		var button := main.find_child(str(node_name), true, false) as Button
		require(button != null, "%s is one of the six real physical Workshop Button nodes." % node_name)
		if button != null:
			for edge in ["Top", "Right", "Bottom", "Left"]:
				var line := button.find_child("WorkshopHotspotTightFocusStroke%s" % edge, true, false) as Control
				require(line != null and line.mouse_filter == Control.MOUSE_FILTER_IGNORE and line.get_rect().size.x > 0.0 and line.get_rect().size.y > 0.0, "%s focus ring has an attached nonzero %s stroke." % [node_name, edge])
			button.emit_signal("pressed")
			await get_tree().process_frame
			require(main.screen == str(expected[node_name]), "%s dispatches its canonical route %s." % [node_name, expected[node_name]])
	main.screen = "workshop"
	main.render()
	await get_tree().process_frame
	var profile_before_unknown := var_to_str(GameManager.profile)
	main._run_workshop_station("unavailable_fixture")
	await get_tree().process_frame
	require(main.screen == "workshop" and not main.toast.is_empty() and var_to_str(GameManager.profile) == profile_before_unknown, "Unavailable physical route remains in Workshop with a native reason and zero mutation.")
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var bed := main.find_child("FirstPrintEmptyBedProof", true, false) as Control
	var cartridge := main.find_child("FirstPrintDockedBlueprint", true, false) as TextureRect
	var begin := main.find_child("BeginCreaturePrint", true, false) as Button
	var back := main.find_child("ArcaneForgeBack", true, false) as Button
	var bed_status := main.find_child("FirstPrintBedStatus", true, false) as Label
	var cartridge_atlas := cartridge.texture as AtlasTexture if cartridge != null else null
	require(bed != null and cartridge != null and begin != null and main.find_child("FeedbackForgeStage", true, false) == null and main.find_child("ArcaneForgeStage", true, false) == null, "First Print setup keeps the bed empty before Start.")
	require(cartridge_atlas != null and cartridge_atlas.region == Rect2(96, 0, 584, 2172) and cartridge.mouse_filter == Control.MOUSE_FILTER_IGNORE and cartridge.accessibility_name == "Docked blueprint: Cinderpaw" and not cartridge.get_global_rect().intersects(bed.get_global_rect()), "Docked cartridge uses the approved AtlasTexture crop, native name, passive input, and external chamber bounds.")
	require(_has_dark_cream_font(back) and _has_dark_cream_font(begin) and bed_status != null and bed_status.mouse_filter == Control.MOUSE_FILTER_IGNORE and "BED EMPTY" in bed_status.text, "First Print cream actions use dark normal copy and the third lower plaque is passive empty-bed status.")
	var pre_start := var_to_str(GameManager.profile)
	require(begin != null and var_to_str(GameManager.profile) == pre_start, "First Print setup introduces zero mutation before Start.")
	GameManager.profile = RULES.new_profile()
	main.screen = "title"
	main.render()
	await get_tree().process_frame
	var fresh_before := var_to_str(GameManager.profile)
	var title_settings := main.find_child("TitleSettings", true, false) as Button
	var title_continue := main.find_child("TitleContinue", true, false) as Button
	require(title_continue != null and title_continue.text == "NEW MAKER", "Fresh Title primary copy is New Maker without mutating onboarding.")
	require(title_settings != null, "Title exposes its native Settings action.")
	if title_settings != null:
		title_settings.emit_signal("pressed")
		await get_tree().process_frame
		var settings_return := main.find_child("SettingsReturn", true, false) as Button
		require(main.screen == "settings" and settings_return != null, "Title Settings opens Settings with a named return control.")
		if settings_return != null:
			settings_return.emit_signal("pressed")
			await get_tree().process_frame
			require(main.screen == "title" and main.find_child("TitleContinue", true, false) != null and var_to_str(GameManager.profile) == fresh_before and OnboardingState.screen_for_profile(GameManager.profile) == "onboarding", "Title Settings returns to Title without creating or completing onboarding.")
	GameManager.profile = base.duplicate(true)
	main.screen = "title"
	main.render()
	await get_tree().process_frame
	var title_resume := main.find_child("TitleContinue", true, false) as Button
	require(title_resume != null and title_resume.text == "CONTINUE" and "Continue" in title_resume.accessibility_name, "Completed profiles receive truthful Continue title copy without a reset flow.")
	main.queue_free()
	await get_tree().process_frame
	(mounted.subviewport as SubViewport).queue_free()
	await get_tree().process_frame
	_clean_paths()
	SaveService.reset_paths()
	if failures.is_empty(): print("PASS: M1 physical workshop navigation")
	get_tree().quit(0 if failures.is_empty() else 1)
