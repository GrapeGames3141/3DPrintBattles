extends Node

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")

var failures: Array[String] = []
var width := 576
var height := 1024

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		width = int(args[0]); height = int(args[1])
	get_window().size = Vector2i(width, height)
	get_window().content_scale_size = Vector2i(width, height)
	var root := _fixture_root()
	var capture_root := root.get_base_dir().path_join("captures")
	DirAccess.make_dir_recursive_absolute(capture_root)
	for starter_id in ["cinderpaw", "aquafin", "voltwig"]:
		await _capture_starter_flow(root, capture_root, starter_id)
	if failures.is_empty():
		print("TEAM_COLLECTION_UI_CAPTURE failures=0")
	get_tree().quit(0 if failures.is_empty() else 1)

func _fixture_root() -> String:
	var qa := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-save-root="):
			qa = argument.trim_prefix("--qa-save-root=")
	var root := qa.get_base_dir().path_join("ui-fixtures")
	DirAccess.make_dir_recursive_absolute(root)
	return root

func _capture_starter_flow(root: String, capture_root: String, starter_id: String) -> void:
	var profile := root.path_join(starter_id).path_join("profile.json")
	DirAccess.make_dir_recursive_absolute(profile.get_base_dir())
	var file := FileAccess.open(profile, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":31,"owned_blueprints":{},"owned_cards":{},"printed_models":{}}))
	file.close()
	var opened := Runtime.open(profile, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""})
	require(bool(opened.get("ok", false)) and str(opened.get("recovery", "")).is_empty(), "%s capture runtime opens only from a sibling fixture" % starter_id)
	if not bool(opened.get("ok", false)):
		return
	var shell := Shell.new()
	shell.size = Vector2(width, height)
	add_child(shell)
	shell.configure_runtime(opened.runtime)
	shell.navigate("starter")
	await get_tree().process_frame
	shell.chosen_index = ["cinderpaw", "aquafin", "voltwig"].find(starter_id)
	shell._render()
	_press(shell, "CHOOSE")
	_press(shell, "CHOOSE BLUEPRINT")
	await get_tree().process_frame
	await _capture_phase(capture_root, "%s-voucher" % starter_id, shell, "available", "seed")
	_press(shell, "START\nFREE PRINT")
	shell.set_process(false)
	shell._render_forge_print()
	await _capture_phase(capture_root, "%s-0" % starter_id, shell, Sequence.PRINTING, "seed")
	var print_id := str(shell.cached_collection.get("voucher", {}).get("print_id", ""))
	shell.first_print.advance(4200, print_id)
	shell._render_forge_print()
	await _capture_phase(capture_root, "%s-60" % starter_id, shell, Sequence.PRINTING, "raw-wire")
	while str(shell.first_print.sequence.phase) == Sequence.PRINTING:
		shell.first_print.advance(Sequence.presentation_step_bps(false, Sequence.PRINTING), print_id)
	shell._render_forge_print()
	await _capture_phase(capture_root, "%s-raw" % starter_id, shell, Sequence.RAW_HOLD, "raw-solid")
	if starter_id == "cinderpaw":
		shell.first_print.advance(Sequence.RAW_HOLD_BPS, print_id)
		shell.first_print.advance(int(Sequence.AWAKEN_BPS / 2), print_id)
		shell._render_forge_print()
		await _capture_phase(capture_root, "cinderpaw-awaken50", shell, Sequence.AWAKENING, "crossfade")
		shell.first_print.advance(int(Sequence.AWAKEN_BPS / 2), print_id)
		shell.first_print.advance(int(Sequence.DEPART_BPS / 2), print_id)
		shell._render_forge_print()
		await _capture_phase(capture_root, "cinderpaw-departmid", shell, Sequence.DEPARTING, "depart")
		shell.first_print.advance(int(Sequence.DEPART_BPS / 2), print_id)
		shell._render_forge_print()
		await _capture_phase(capture_root, "cinderpaw-departend", shell, Sequence.AWAKENED, "awakened")
	require(shell.find_children("*", "Button", true, false).size() >= 2, "%s Forge capture retains native Back and center-plate controls" % starter_id)
	shell.queue_free()
	await get_tree().process_frame


func _capture_phase(root: String, state: String, shell: Variant, expected_phase: String, material: String) -> void:
	var voucher: Dictionary = shell.runtime.collection_view().get("voucher", {})
	var phase := str(shell.first_print.sequence.phase) if shell.first_print != null and shell.first_print.sequence != null else "available"
	var compositor: Variant = shell._forge_compositor
	var visual: Dictionary = compositor.presentation_snapshot() if compositor != null and is_instance_valid(compositor) else {}
	require(phase == expected_phase, "%s capture reaches controller phase %s" % [state, expected_phase])
	require(str(voucher.get("state", "")) in ["available", "printing", "settled"], "%s capture retains a truthful voucher state" % state)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := root.path_join("team-collection-%s-%dx%d.png" % [state, width, height])
	require(get_viewport().get_texture().get_image().save_png(output) == OK, "%s native capture saves beside QA storage" % state)
	var metadata := {
		"state": state,
		"phase": phase,
		"voucher_state": str(voucher.get("state", "")),
		"material": material,
		"raw_progress_bps": int(shell.first_print.sequence.layer_reveal_bps()) if shell.first_print != null and shell.first_print.sequence != null else 0,
		"scan_global_y": float(visual.get("scan_global_y", -1.0)),
		"scan_width": float(visual.get("scan_width", 0.0)),
		"presentation_visible": bool(visual.get("presentation_visible", material != "awakened")),
		"presentation_opacity": float(visual.get("presentation_opacity", 1.0)),
	}
	var metadata_file := FileAccess.open(output.get_basename() + ".json", FileAccess.WRITE)
	metadata_file.store_string(JSON.stringify(metadata, "\t"))
	metadata_file.close()

func _press(root: Node, caption: String) -> void:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == caption:
			(node as Button).pressed.emit()
			return
	require(false, "native %s action exists for capture" % caption)
