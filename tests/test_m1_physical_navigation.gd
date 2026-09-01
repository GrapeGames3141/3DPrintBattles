extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const TEST_ROOT := "E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/m1-navigation-save"
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
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
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
	var bed_light_mask := main.find_child("FirstPrintBedInactiveLightMask", true, false) as ColorRect
	require(bed != null and cartridge != null and begin != null and main.find_child("FeedbackForgeStage", true, false) == null and main.find_child("ArcaneForgeStage", true, false) == null, "First Print setup keeps the bed empty before Start.")
	require(cartridge.texture != null and not IMPRINT.is_neutral_placeholder(cartridge.texture) and cartridge.mouse_filter == Control.MOUSE_FILTER_IGNORE and cartridge.accessibility_name == "Docked blueprint: Cinderpaw" and not cartridge.get_global_rect().intersects(bed.get_global_rect()), "Docked pre-print review uses the approved M7 blueprint, native name, passive input, and external chamber bounds.")
	require(_has_dark_cream_font(back) and _has_dark_cream_font(begin) and bed_status != null and bed_status.mouse_filter == Control.MOUSE_FILTER_IGNORE and "BED EMPTY" in bed_status.text and bed_light_mask != null and bed_light_mask.color.a >= 0.80 and bed_light_mask.mouse_filter == Control.MOUSE_FILTER_IGNORE, "First Print cream actions stay live while the third lower plaque is passive empty-bed status with its own dimmed indicator lamp.")
	var pre_start := var_to_str(GameManager.profile)
	require(begin != null and var_to_str(GameManager.profile) == pre_start, "First Print setup introduces zero mutation before Start.")
	GameManager.profile = RULES.new_profile()
	main.screen = "title"
	main.render()
	await get_tree().process_frame
	var fresh_before := var_to_str(GameManager.profile)
	var title_settings := main.find_child("TitleSettings", true, false) as Button
	var title_continue := main.find_child("TitleContinue", true, false) as Button
	var fresh_new_maker := main.find_child("TitleNewMaker", true, false) as Button
	require(title_continue != null and title_continue.text == "NEW MAKER", "Fresh Title primary copy is New Maker without mutating onboarding.")
	require(title_settings != null and fresh_new_maker == null, "Fresh Title exposes only its central New Maker and native Settings actions.")
	if title_continue != null:
		title_continue.emit_signal("pressed")
		await get_tree().process_frame
		require(main.screen == "onboarding" and var_to_str(GameManager.profile) == fresh_before, "Fresh New Maker enters choose-starter onboarding without progression mutation.")
		main.screen = "title"; main.render(); await get_tree().process_frame
		title_settings = main.find_child("TitleSettings", true, false) as Button
	if title_settings != null:
		title_settings.emit_signal("pressed")
		await get_tree().process_frame
		var settings_return := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
		require(main.screen == "settings" and settings_return != null and settings_return.tooltip_text.contains("Title"), "Title Settings opens the physical Settings instrument with a caller-aware return control.")
		if settings_return != null:
			settings_return.emit_signal("pressed")
			await get_tree().process_frame
			require(main.screen == "title" and main.find_child("TitleContinue", true, false) != null and var_to_str(GameManager.profile) == fresh_before and OnboardingState.screen_for_profile(GameManager.profile) == "onboarding", "Title Settings returns to Title without creating or completing onboarding.")
	GameManager.profile = base.duplicate(true)
	main.screen = "title"
	main.render()
	await get_tree().process_frame
	var title_resume := main.find_child("TitleContinue", true, false) as Button
	var title_new_maker := main.find_child("TitleNewMaker", true, false) as Button
	title_settings = main.find_child("TitleSettings", true, false) as Button
	require(title_resume != null and title_new_maker != null and title_settings != null and main.find_children("Title*", "Button", true, false).size() == 3 and title_resume.text == "CONTINUE" and "Continue" in title_resume.accessibility_name, "Completed profiles receive exactly three truthful physical title actions.")
	for title_action in [title_resume, title_new_maker, title_settings]:
		if title_action != null:
			require(title_action.custom_minimum_size.x >= 48.0 and title_action.custom_minimum_size.y >= 48.0 and _has_dark_cream_font(title_action), "%s retains physical target size and dark native cream copy." % title_action.name)
			for edge in ["Top", "Right", "Bottom", "Left"]:
				require(title_action.find_child("WorkshopHotspotTightFocusStroke%s" % edge, true, false) != null, "%s has all four title focus edges." % title_action.name)
	require(is_instance_valid(title_resume) and int(title_resume.anchor_left * 941.0) in range(150, 191) and int(title_resume.anchor_top * 1672.0) in range(1150, 1201) and int(title_resume.anchor_bottom * 1672.0) in range(1300, 1351) and is_instance_valid(title_new_maker) and int(title_new_maker.anchor_top * 1672.0) in range(1395, 1421) and is_instance_valid(title_settings) and int(title_settings.anchor_top * 1672.0) in range(1395, 1421), "Title central and lower controls are seated in their authored large/lower plaques rather than the roller or central frame.")
	# Parchment copy keeps dark native ink in high contrast. The only Title text
	# reduced at 150% is the brand, so its complete word remains inside the paper.
	var title_accessibility_before: Dictionary = GameManager.profile.get("settings", {}).duplicate(true)
	var title_accessibility := title_accessibility_before.duplicate(true)
	title_accessibility["high_contrast"] = true
	title_accessibility["text_scale_bps"] = 15000
	GameManager.profile["settings"] = title_accessibility
	main.screen = "title"; main.render(); await get_tree().process_frame
	var title_brand := main.find_child("TitleNativeBrand", true, false) as Label
	var title_status_copy := main.find_child("TitleNativeStatus", true, false) as Label
	var dark_brand := is_instance_valid(title_brand) and title_brand.get_theme_color("font_color").r < 0.35 and title_brand.get_theme_color("font_color").g < 0.28 and title_brand.get_theme_color("font_color").b < 0.22
	var dark_status := is_instance_valid(title_status_copy) and title_status_copy.get_theme_color("font_color").r < 0.35 and title_status_copy.get_theme_color("font_color").g < 0.28 and title_status_copy.get_theme_color("font_color").b < 0.22
	var brand_bounds_ok := is_instance_valid(title_brand) and int(title_brand.get_global_rect().position.x) in range(110, 131) and int(title_brand.get_global_rect().end.x) in range(450, 471) and title_brand.get_combined_minimum_size().x <= title_brand.size.x and int(title_brand.get_theme_font_size("font_size")) <= 36
	require(dark_brand and dark_status and brand_bounds_ok, "Title parchment brand/status keep dark ink in high contrast, and the 150% PRINTFORGE word fits its narrow 576px parchment inset.")
	GameManager.profile["settings"] = title_accessibility_before
	main.screen = "title"; main.render(); await get_tree().process_frame
	title_resume = main.find_child("TitleContinue", true, false) as Button
	title_new_maker = main.find_child("TitleNewMaker", true, false) as Button
	title_settings = main.find_child("TitleSettings", true, false) as Button
	# A completed maker's Settings route returns to the exact same physical Title,
	# never a generic Workshop redirect or a mutation of the profile.
	var completed_before_settings := var_to_str(GameManager.profile)
	var completed_revision := int(GameManager.profile.get("revision", 0))
	if title_settings != null: title_settings.emit_signal("pressed")
	await get_tree().process_frame
	var completed_settings_return := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	if completed_settings_return != null: completed_settings_return.emit_signal("pressed")
	await get_tree().process_frame
	require(main.screen == "title" and main.find_children("Title*", "Button", true, false).size() == 3 and var_to_str(GameManager.profile) == completed_before_settings and int(GameManager.profile.get("revision", 0)) == completed_revision, "Completed Title Settings round-trip restores its exact three actions, profile, and revision without opening Workshop.")
	# Title must not render a reset/navigation surface while recovery is read-only.
	var compatibility_before_read_only := GameManager.save_compatibility.duplicate(true)
	var recovery_before_read_only := SaveService.recovery_status
	GameManager.save_compatibility = {"compatible":false, "state":"future_schema", "schema_version":9, "supported_schema":6, "message":"A newer save needs a safe decision."}
	SaveService.recovery_status = "future_schema"
	main.screen = "title"; main.render(); await get_tree().process_frame
	require(main.find_child("M3RecoveryLedger", true, false) != null and main.find_child("TitleContinue", true, false) == null and main.find_child("TitleNewMaker", true, false) == null and main.find_child("TitleSettings", true, false) == null and main.find_child("TitleConfirmNewMaker", true, false) == null, "Read-only Title exposes only the M3 recovery ledger and no reset or navigation action.")
	GameManager.save_compatibility = compatibility_before_read_only
	SaveService.recovery_status = recovery_before_read_only
	main.screen = "title"; main.render(); await get_tree().process_frame
	title_new_maker = main.find_child("TitleNewMaker", true, false) as Button
	var title_before_confirmation := var_to_str(GameManager.profile)
	if title_new_maker != null:
		title_new_maker.emit_signal("pressed")
		await get_tree().process_frame
		var confirm := main.find_child("TitleConfirmNewMaker", true, false) as Button
		var cancel := main.find_child("TitleCancelNewMaker", true, false) as Button
		require(confirm != null and cancel != null and main.find_child("TitleContinue", true, false) == null and var_to_str(GameManager.profile) == title_before_confirmation and cancel.has_focus(), "New Maker first opens a zero-mutation confirmation with Cancel as default focus.")
		if cancel != null: cancel.emit_signal("pressed")
		await get_tree().process_frame
		require(main.find_child("TitleContinue", true, false) != null and var_to_str(GameManager.profile) == title_before_confirmation, "Cancel restores the completed Title without mutation.")
	# Re-query after the confirmation's render rebuilt the original node.
	title_resume = main.find_child("TitleContinue", true, false) as Button
	if title_resume != null:
		title_resume.emit_signal("pressed")
		await get_tree().process_frame
		await get_tree().process_frame
	var launch_hotspots := ["WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"]
	var launch_count := 0
	for node_name in launch_hotspots:
		if main.find_child(node_name, true, false) is Button: launch_count += 1
	require(main.screen == "workshop" and launch_count == 6 and main.find_children("WorkshopHotspot*", "Button", true, false).size() == 6, "Completed-profile Continue dispatches through the real Title button to the six-hotspot redesigned Workshop hub.")
	# The destructive Title action must leave the authoritative snapshot and
	# in-memory profile untouched when its target parent is unavailable.
	require(SaveService.commit_snapshot(GameManager.profile), "Title New Maker test can seed an existing primary snapshot.")
	var saved_primary_before_failure := FileAccess.get_file_as_string(SaveService.profile_path)
	var backup_existed_before_failure := FileAccess.file_exists(SaveService.profile_backup_path)
	var saved_backup_before_failure := FileAccess.get_file_as_string(SaveService.profile_backup_path) if backup_existed_before_failure else ""
	var profile_before_failure := var_to_str(GameManager.profile)
	var revision_before_failure := int(GameManager.profile.get("revision", 0))
	var blocked_parent := TEST_ROOT.path_join("title-new-maker-blocker")
	var blocker_file := FileAccess.open(blocked_parent, FileAccess.WRITE)
	if blocker_file != null: blocker_file.store_string("not a directory"); blocker_file.close()
	SaveService.configure_test_paths(blocked_parent)
	main.screen = "title"; main.render(); await get_tree().process_frame
	title_new_maker = main.find_child("TitleNewMaker", true, false) as Button
	if title_new_maker != null: title_new_maker.emit_signal("pressed")
	await get_tree().process_frame
	var failed_confirm := main.find_child("TitleConfirmNewMaker", true, false) as Button
	if failed_confirm != null: failed_confirm.emit_signal("pressed")
	await get_tree().process_frame
	var failure_copy := main.find_child("TitleNativeStatus", true, false) as Label
	require(main.screen == "title" and main.find_child("TitleConfirmNewMaker", true, false) is Button and is_instance_valid(failure_copy) and failure_copy.text.contains("Profile storage is unavailable") and var_to_str(GameManager.profile) == profile_before_failure and int(GameManager.profile.get("revision", 0)) == revision_before_failure, "Failed Title New Maker keeps the confirmation, visible native retry error, and prior in-memory profile/revision.")
	SaveService.configure_test_paths(TEST_ROOT)
	require(FileAccess.get_file_as_string(SaveService.profile_path) == saved_primary_before_failure and FileAccess.file_exists(SaveService.profile_backup_path) == backup_existed_before_failure and (not backup_existed_before_failure or FileAccess.get_file_as_string(SaveService.profile_backup_path) == saved_backup_before_failure), "Failed Title New Maker leaves the existing primary and backup authority byte-identical, including prior backup existence.")
	if FileAccess.file_exists(blocked_parent): DirAccess.remove_absolute(blocked_parent)
	main._title_cancel_new_maker()
	await get_tree().process_frame
	title_new_maker = main.find_child("TitleNewMaker", true, false) as Button
	var revision_before_new_maker := int(GameManager.profile.get("revision", 0))
	if title_new_maker != null: title_new_maker.emit_signal("pressed")
	await get_tree().process_frame
	var persisted_confirm := main.find_child("TitleConfirmNewMaker", true, false) as Button
	if persisted_confirm != null: persisted_confirm.emit_signal("pressed")
	await get_tree().process_frame
	var revision_after_new_maker := int(GameManager.profile.get("revision", 0))
	require(main.screen == "onboarding" and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "choose_starter" and revision_after_new_maker == revision_before_new_maker + 1 and FileAccess.file_exists(SaveService.profile_path), "Confirmed Title New Maker writes once before assigning a clean choose-starter profile.")
	main._title_confirm_new_maker()
	require(int(GameManager.profile.get("revision", 0)) == revision_after_new_maker, "A late Title confirmation cannot write a second new profile.")
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "aquafin").profile
	main.screen = "title"; main.render(); await get_tree().process_frame
	var starter_continue := main.find_child("TitleContinue", true, false) as Button
	if starter_continue != null: starter_continue.emit_signal("pressed")
	await get_tree().process_frame
	require(main.screen == "printer" and main.printer_creature_id == "aquafin", "Resumable starter-selected Title Continue opens the saved starter's exact First Print setup.")
	main.queue_free()
	await get_tree().process_frame
	(mounted.subviewport as SubViewport).queue_free()
	await get_tree().process_frame
	_clean_paths()
	SaveService.reset_paths()
	if failures.is_empty(): print("PASS: M1 physical workshop navigation")
	get_tree().quit(0 if failures.is_empty() else 1)
