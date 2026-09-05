extends Node
## First visual gate for M9 Forge continuity. Start is a real viewport click;
## deterministic progress only freezes the existing sequence for evidence frames.

const MAIN := preload("res://scenes/main.tscn")
const PROFILES := preload("res://tests/m9_test_profile_factory.gd")
const OUTPUT_ROOT := "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/forge-continuity/first-gate-v3"

var main: Control

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("Forge continuity captures require Forward+ rendering.")
		get_tree().quit(1)
		return
	var window := get_tree().root.get_window()
	window.content_scale_size = Vector2i(576, 1024)
	window.size = Vector2i(576, 1024)
	get_viewport().notify_mouse_entered()
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	GameManager.profile = PROFILES.founder_ready("cinderpaw")
	GameManager.profile.forge_coins = 1200
	# The selector is native route UI, so test its real physical hit ownership with
	# two learned blueprints before recording the actual Start evidence below.
	GameManager.profile.owned_blueprints["mossmunk"] = true
	GameManager.profile.owned_cards["mossmunk"] = maxi(1, int(GameManager.profile.owned_cards.get("mossmunk", 0)))
	main = MAIN.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	await get_tree().process_frame
	var previous := _find_button(main, "PrinterSelectPrevious")
	var next := _find_button(main, "PrinterSelectNext")
	print("FORGE_CONTINUITY_SELECTOR ids=%s previous=%s next=%s previous_rect=%s next_rect=%s" % [str(main.printer_blueprint_ids()), str(previous != null), str(next != null), str(previous.get_global_rect() if previous != null else Rect2()), str(next.get_global_rect() if next != null else Rect2())])
	if previous == null or next == null or previous.get_global_rect().size.y < 48.0 or next.get_global_rect().size.y < 48.0 or previous.get_global_rect().intersects(next.get_global_rect()):
		push_error("Forge cartridge selector targets are missing, undersized, or overlapping.")
		get_tree().quit(1)
		return
	await _tap(next)
	if main.printer_creature_id != "mossmunk":
		push_error("Actual Next cartridge tap did not select the next learned blueprint.")
		get_tree().quit(1)
		return
	previous = _find_button(main, "PrinterSelectPrevious")
	if previous == null:
		push_error("Forge cartridge selector did not rebuild its Previous target after a real selection.")
		get_tree().quit(1)
		return
	await _tap(previous)
	if main.printer_creature_id != "cinderpaw":
		push_error("Actual Previous cartridge tap did not restore the selected blueprint.")
		get_tree().quit(1)
		return
	if not await _capture("before-start"):
		return
	var start := _find_button(main, "BeginCreaturePrint")
	if start == null or start.disabled:
		push_error("Forge continuity fixture has no enabled Start owner.")
		get_tree().quit(1)
		return
	await _tap(start)
	await get_tree().process_frame
	main.printer_capture_freeze = true
	if main.printer_sequence == null or main.printer_sequence.phase != ArcaneForgeSequence.PRINTING:
		push_error("Actual Start click did not enter the existing printing sequence.")
		get_tree().quit(1)
		return
	if not await _capture("after-start"):
		return
	# Printing reaches visual 60% at 4,200/7,000 existing print bps. Account for
	# any real-frame presentation tick that occurred between the input click and
	# the deliberate fixture freeze without changing sequence authority.
	main.advance_printer_for_test(maxi(1, 4200 - main.printer_sequence.progress_bps))
	await get_tree().process_frame
	print("FORGE_CONTINUITY_PROGRESS raw_bps=%d reveal_bps=%d" % [main.printer_sequence.progress_bps if main.printer_sequence != null else -1, main.printer_sequence.layer_reveal_bps() if main.printer_sequence != null else -1])
	if main.printer_sequence == null or main.printer_sequence.layer_reveal_bps() < 5900 or main.printer_sequence.layer_reveal_bps() > 6100:
		push_error("Forge continuity fixture did not reach the existing 60 percent sequence state.")
		get_tree().quit(1)
		return
	if not await _capture("print-60"):
		return
	print("PASS: M9 Forge continuity actual Start gate")
	main.get_parent().remove_child(main)
	main.free()
	await get_tree().process_frame
	get_tree().quit(0)

func _tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = point
	release.global_position = point
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	get_viewport().push_input(release, true)
	await get_tree().process_frame

func _capture(name: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.get_size() != Vector2i(576, 1024):
		push_error("Forge capture surface unavailable for %s." % name)
		get_tree().quit(1)
		return false
	DirAccess.make_dir_recursive_absolute(OUTPUT_ROOT)
	var output := "%s/%s-576x1024.png" % [OUTPUT_ROOT, name]
	if image.save_png(output) != OK:
		push_error("Could not write Forge capture %s." % output)
		get_tree().quit(1)
		return false
	print("FORGE_CONTINUITY_CAPTURE state=%s output=%s" % [name, output])
	return true

func _find_button(node: Node, node_name: String) -> Button:
	if node is Button and node.name == node_name:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, node_name)
		if found != null:
			return found
	return null
