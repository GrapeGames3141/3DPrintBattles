extends Node

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")

var failures: Array[String] = []
var width := 576
var height := 1024
var text_scale_bps := 10000
var high_contrast := false
var reduced_motion := false
var synthetic_safe_insets := Rect2(Vector2.ZERO, Vector2.ZERO)
var synthetic_safe_insets_enabled := false


class StoreFault extends RefCounted:
	var reject_profile_write := false

	func allow(stage: String, kind: String) -> bool:
		return not (reject_profile_write and stage == "temp_write" and kind == "profile")

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		width = int(args[0]); height = int(args[1])
	for argument in args:
		if argument.begins_with("--text-scale-bps="):
			text_scale_bps = int(argument.trim_prefix("--text-scale-bps="))
		elif argument == "--high-contrast":
			high_contrast = true
		elif argument == "--reduced-motion":
			reduced_motion = true
		elif argument.begins_with("--synthetic-safe-insets="):
			_parse_synthetic_safe_insets(argument.trim_prefix("--synthetic-safe-insets="))
	get_window().size = Vector2i(width, height)
	get_window().content_scale_size = Vector2i(width, height)
	var root := _fixture_root()
	var capture_root := root.get_base_dir().path_join("captures")
	DirAccess.make_dir_recursive_absolute(capture_root)
	for starter_id in ["cinderpaw", "aquafin", "voltwig"]:
		await _capture_starter_flow(root, capture_root, starter_id)
	await _capture_recovery(root, capture_root)
	await _capture_retry_states(root, capture_root)
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


func _parse_synthetic_safe_insets(value: String) -> void:
	var fields := value.split(",", false)
	if fields.size() != 4:
		require(false, "synthetic safe inset fixture has left,top,right,bottom")
		return
	for field in fields:
		if not field.is_valid_float() or float(field) < 0.0:
			require(false, "synthetic safe inset fixture values are nonnegative numbers")
			return
	synthetic_safe_insets = Rect2(float(fields[0]), float(fields[1]), float(fields[2]), float(fields[3]))
	synthetic_safe_insets_enabled = true


func _new_shell(runtime: Variant) -> Variant:
	var shell := Shell.new()
	shell.size = Vector2(width, height)
	shell.synthetic_safe_insets = synthetic_safe_insets
	shell.synthetic_safe_insets_enabled = synthetic_safe_insets_enabled
	add_child(shell)
	shell.configure_runtime(runtime)
	return shell

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
	opened.runtime.apply_settings({"text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion})
	var shell: Variant = _new_shell(opened.runtime)
	if starter_id == "cinderpaw":
		await _capture_route(capture_root, "workshop", shell)
		shell.navigate("team")
		await _capture_route(capture_root, "team-empty", shell)
	shell.navigate("starter")
	await get_tree().process_frame
	shell.chosen_index = ["cinderpaw", "aquafin", "voltwig"].find(starter_id)
	shell._render()
	await _capture_route(capture_root, "%s-starter" % starter_id, shell)
	_press(shell, "INSPECT")
	await _capture_route(capture_root, "%s-inspect" % starter_id, shell)
	shell.back()
	await get_tree().process_frame
	_press(shell, "CHOOSE")
	await _capture_route(capture_root, "%s-confirm" % starter_id, shell)
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
	if str(shell.first_print.sequence.phase) == Sequence.RAW_HOLD:
		shell.first_print.advance(Sequence.RAW_HOLD_BPS, print_id)
		shell.first_print.advance(Sequence.AWAKEN_BPS, print_id)
		shell.first_print.advance(Sequence.DEPART_BPS, print_id)
		shell._render_forge_print()
	shell._refresh_cache()
	shell.replace_route("grant")
	await get_tree().process_frame
	await _capture_route(capture_root, "%s-grant" % starter_id, shell)
	if starter_id == "cinderpaw":
		_press(shell, "CONTINUE\nTO TEAM")
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-team", shell)
		var bay: Button = shell.find_child("TeamBay0", true, false) as Button
		if bay is Button:
			(bay as Button).pressed.emit()
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-team-selector", shell)
		_press_named(shell, "TeamChoiceNext")
		await _capture_route(capture_root, "cinderpaw-team-selector-page2", shell)
		await _click_design(shell, Vector2(259, 198))
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-team-back-focus", shell)
		var apply := shell.find_child("CollectionApply", true, false) as Button
		if apply != null:
			apply.grab_focus()
		await _capture_route(capture_root, "cinderpaw-team-apply-focus", shell)
		_press_named(shell, "TeamPriority")
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-team-priority", shell)
		shell.back()
		shell.navigate("kit")
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-kit-page1", shell)
		_press_named(shell, "SupportChip_raw_filament")
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-kit-inspector", shell)
		shell.back()
		_press_named(shell, "KitNext")
		await get_tree().process_frame
		await _capture_route(capture_root, "cinderpaw-kit-page2", shell)
		shell.navigate("settings")
		await get_tree().process_frame
		await _capture_route(capture_root, "settings", shell)
		shell._return_to_workshop()
		shell.back()
		await get_tree().process_frame
		await _capture_route(capture_root, "leave-confirmation", shell)
	require(shell.find_children("*", "Button", true, false).size() >= 2, "%s Forge capture retains native Back and center-plate controls" % starter_id)
	shell.queue_free()
	await get_tree().process_frame


func _capture_recovery(root: String, capture_root: String) -> void:
	var profile := root.path_join("recovery").path_join("profile.json")
	DirAccess.make_dir_recursive_absolute(profile.get_base_dir())
	var file := FileAccess.open(profile, FileAccess.WRITE)
	file.store_string("{bad-json")
	file.close()
	var opened := Runtime.open(profile, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""})
	require(bool(opened.get("ok", false)) and not str(opened.get("recovery", "")).is_empty(), "recovery capture opens only the read-only route")
	if not bool(opened.get("ok", false)):
		return
	var shell: Variant = _new_shell(opened.runtime)
	await _capture_route(capture_root, "recovery", shell)
	_press_named(shell, "RecoveryDetails")
	await _capture_route(capture_root, "recovery-details", shell)
	shell.back()
	await get_tree().process_frame
	shell.back()
	await _capture_route(capture_root, "recovery-leave-confirmation", shell)
	shell.queue_free()
	await get_tree().process_frame


func _capture_retry_states(root: String, capture_root: String) -> void:
	var apply_fault := StoreFault.new()
	var apply_opened := _open_fixture(root, "apply-save-retry", Callable(apply_fault, "allow"))
	require(bool(apply_opened.get("ok", false)), "Apply retry capture opens a sibling fault fixture")
	if bool(apply_opened.get("ok", false)):
		_apply_capture_settings(apply_opened.runtime)
		require(_bootstrap_to_ack(apply_opened.runtime, "capture-apply"), "Apply retry capture reaches a durable editor")
		var apply_shell: Variant = _new_shell(apply_opened.runtime)
		apply_shell.navigate("team")
		await get_tree().process_frame
		apply_fault.reject_profile_write = true
		_press_named(apply_shell, "CollectionApply")
		require(not apply_shell.route_error.is_empty() and str(apply_shell.route) == "team" and _named_button_text(apply_shell, "CollectionApply") == "RETRY APPLY", "Apply retry capture retains the failed editor request and visible Retry")
		await _capture_route(capture_root, "apply-save-retry", apply_shell)
		apply_shell.queue_free()
		await get_tree().process_frame

	var settings_fault := StoreFault.new()
	var settings_opened := _open_fixture(root, "settings-save-retry", Callable(settings_fault, "allow"))
	require(bool(settings_opened.get("ok", false)), "Settings retry capture opens a sibling fault fixture")
	if bool(settings_opened.get("ok", false)):
		_apply_capture_settings(settings_opened.runtime)
		var settings_shell: Variant = _new_shell(settings_opened.runtime)
		settings_shell.navigate("settings")
		await get_tree().process_frame
		_press_named(settings_shell, "SettingsHighContrast")
		settings_fault.reject_profile_write = true
		_press_named(settings_shell, "SettingsApply")
		require(not settings_shell.route_error.is_empty() and str(settings_shell.route) == "settings" and _named_button_accessibility(settings_shell, "SettingsApply") == "RETRY SAVE", "Settings retry capture retains its changed draft and visible Retry")
		await _capture_route(capture_root, "settings-save-retry", settings_shell)
		settings_shell.queue_free()
		await get_tree().process_frame

	var forge_fault := StoreFault.new()
	var forge_opened := _open_fixture(root, "forge-raw-save-retry", Callable(forge_fault, "allow"))
	require(bool(forge_opened.get("ok", false)), "Forge retry capture opens a sibling fault fixture")
	if bool(forge_opened.get("ok", false)):
		_apply_capture_settings(forge_opened.runtime)
		var choose: Dictionary = forge_opened.runtime.collection_request("choose_starter", "capture-forge-choose", {"starter_id":"cinderpaw"})
		require(bool(choose.get("ok", false)), "Forge retry capture has one durable chosen starter")
		if bool(choose.get("ok", false)):
			var forge_shell: Variant = _new_shell(forge_opened.runtime)
			forge_shell.navigate("forge")
			await get_tree().process_frame
			_press(forge_shell, "START\nFREE PRINT")
			await get_tree().process_frame
			forge_fault.reject_profile_write = true
			var print_id := str(forge_shell.cached_collection.get("voucher", {}).get("print_id", ""))
			forge_shell.first_print.advance(Sequence.PRINT_COMPLETE_BPS, print_id)
			forge_shell._render_forge_print()
			require(not str(forge_shell.first_print.save_error).is_empty(), "Forge retry capture remains at RAW_COMPLETE after the injected completion failure")
			await _capture_phase(capture_root, "forge-raw-save-retry", forge_shell, Sequence.RAW_COMPLETE, "raw-save-retry")
			forge_shell.queue_free()
			await get_tree().process_frame


func _open_fixture(root: String, name: String, fault: Callable) -> Dictionary:
	var profile := root.path_join(name).path_join("profile.json")
	DirAccess.make_dir_recursive_absolute(profile.get_base_dir())
	var file := FileAccess.open(profile, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":31,"owned_blueprints":{},"owned_cards":{},"printed_models":{}}))
	file.close()
	return Runtime.open(profile, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""}, fault)


func _apply_capture_settings(runtime: Variant) -> void:
	runtime.apply_settings({"text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion})


func _bootstrap_to_ack(runtime: Variant, prefix: String) -> bool:
	var chosen: Dictionary = runtime.collection_request("choose_starter", "%s-choose" % prefix, {"starter_id":"cinderpaw"})
	if not bool(chosen.get("ok", false)):
		return false
	var begun: Dictionary = runtime.collection_request("begin_starter_print", "%s-begin" % prefix, {})
	if not bool(begun.get("ok", false)):
		return false
	var view: Dictionary = runtime.collection_view()
	var completed: Dictionary = runtime.collection_request("complete_starter_print", "%s-complete" % prefix, {"print_id":str(view.get("voucher", {}).get("print_id", ""))})
	if not bool(completed.get("ok", false)):
		return false
	view = runtime.collection_view()
	var acknowledged: Dictionary = runtime.collection_request("acknowledge_grant", "%s-ack" % prefix, {"receipt_id":str(view.get("voucher", {}).get("receipt_id", ""))})
	return bool(acknowledged.get("ok", false))


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
		"synthetic_safe_insets": _safe_insets_metadata(),
	}
	var metadata_file := FileAccess.open(output.get_basename() + ".json", FileAccess.WRITE)
	metadata_file.store_string(JSON.stringify(metadata, "\t"))
	metadata_file.close()


func _capture_route(root: String, state: String, shell: Variant) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := root.path_join("team-collection-%s-%dx%d.png" % [state, width, height])
	require(get_viewport().get_texture().get_image().save_png(output) == OK, "%s route capture saves beside QA storage" % state)
	var metadata_file := FileAccess.open(output.get_basename() + ".json", FileAccess.WRITE)
	metadata_file.store_string(JSON.stringify({"state":state, "route":str(shell.route), "modal":str(shell.modal), "voucher":shell.cached_collection.get("voucher", {}).duplicate(true), "text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion, "synthetic_safe_insets":_safe_insets_metadata()}, "\t"))
	metadata_file.close()


func _safe_insets_metadata() -> Dictionary:
	return {
		"enabled": synthetic_safe_insets_enabled,
		"left": synthetic_safe_insets.position.x,
		"top": synthetic_safe_insets.position.y,
		"right": synthetic_safe_insets.size.x,
		"bottom": synthetic_safe_insets.size.y,
	}


func _click_design(shell: Variant, design_position: Vector2) -> void:
	var viewport_position: Vector2 = shell._stage.position + design_position * shell._stage.scale
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = viewport_position
	press.global_position = viewport_position
	press.pressed = true
	get_viewport().push_input(press, true)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = viewport_position
	release.global_position = viewport_position
	release.pressed = false
	get_viewport().push_input(release, true)
	await get_tree().process_frame

func _press(root: Node, caption: String) -> void:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == caption:
			(node as Button).pressed.emit()
			return
	require(false, "native %s action exists for capture" % caption)


func _press_named(root: Node, node_name: String) -> void:
	var node := root.find_child(node_name, true, false)
	if node is Button:
		(node as Button).pressed.emit()
		return
	require(false, "native %s action exists for capture" % node_name)


func _named_button_text(root: Node, node_name: String) -> String:
	var button: Button = root.find_child(node_name, true, false) as Button
	return button.text if button != null else ""


func _named_button_accessibility(root: Node, node_name: String) -> String:
	var button: Button = root.find_child(node_name, true, false) as Button
	return button.accessibility_name if button != null else ""
