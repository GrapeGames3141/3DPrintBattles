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
	GameManager.profile = ProfileRules.new_profile() if capture_mode == "onboarding" else ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	workshop = MAIN_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", workshop)
	call_deferred("capture")

func capture() -> void:
	await wait_frames(5)
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	get_viewport().get_texture().get_image().save_png(OUTPUT_DIR.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix]))
	print("CAPTURED: %s (%s, %s%s)" % [OUTPUT_DIR, capture_mode, capture_size, suffix])
	get_tree().quit()

func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame

func requested_resolution() -> String:
	var size := DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0: size = get_viewport().get_texture().get_size()
	return "%dx%d" % [int(size.x), int(size.y)]

func requested_mode() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-mode="):
			var mode := arg.trim_prefix("--capture-mode=")
			if mode == "workshop": return "workshop"
	return "onboarding"

func requested_tag() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-tag="):
			return arg.trim_prefix("--capture-tag=").validate_filename()
	return ""
