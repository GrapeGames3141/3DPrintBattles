extends Node
## Reusable deterministic visual QA capture; output is deliberately outside the repository.
const OUTPUT_DIR := "E:/CodexCache/printforge-validation"
const MAIN_SCENE := preload("res://scenes/main.tscn")
var workshop: Control
var capture_size := ""
var capture_mode := "onboarding"
var capture_tag := ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	capture_mode = requested_mode()
	capture_tag = requested_tag()
	GameManager.profile = fixture_profile() if capture_mode != "onboarding" else ProfileRules.new_profile()
	workshop = MAIN_SCENE.instantiate()
	workshop.shop_day_key = "2026-08-14"
	if capture_mode != "onboarding": workshop.screen = capture_mode
	get_tree().root.call_deferred("add_child", workshop)
	call_deferred("capture")

func fixture_profile() -> Dictionary:
	var fixture: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	fixture.coins = 1000
	var blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(fixture, "mossmunk")
	var printed: Dictionary = ProgressionRules.print_creature(blueprint.profile, "mossmunk")
	var armor_blueprint: Dictionary = ProgressionRules.learn_armor_blueprint(printed.profile, "helm")
	var armor_print: Dictionary = ProgressionRules.print_armor(armor_blueprint.profile, "helm")
	fixture = armor_print.profile
	fixture.team = [str(fixture.onboarding.starter_instance_id), str(printed.payload.instance_id)]
	fixture.support_cards.coolant = 1
	return fixture

func capture() -> void:
	await wait_for_stable_header()
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	get_viewport().get_texture().get_image().save_png(OUTPUT_DIR.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix]))
	print("CAPTURED: %s (%s, %s%s)" % [OUTPUT_DIR, capture_mode, capture_size, suffix])
	get_tree().quit()

func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame

func wait_for_stable_header() -> void:
	# Avoid capturing before a resized window has completed its first container pass.
	for _frame in 60:
		var header := workshop.find_child("WorkshopHeader", true, false) as Control
		if header and header.is_visible_in_tree() and header.get_global_rect().position.y >= 15.0 and header.get_global_rect().size.y >= 80.0:
			await wait_frames(3)
			return
		await get_tree().process_frame
	push_error("Capture header never reached a safe visible layout.")

func requested_resolution() -> String:
	var size := DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0: size = get_viewport().get_texture().get_size()
	return "%dx%d" % [int(size.x), int(size.y)]

func requested_mode() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-mode="):
			var mode := arg.trim_prefix("--capture-mode=")
			if mode in ["workshop", "shop", "collection", "team", "armor", "deck"]: return mode
	return "onboarding"

func requested_tag() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-tag="):
			return arg.trim_prefix("--capture-tag=").validate_filename()
	return ""
