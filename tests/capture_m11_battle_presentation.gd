extends Node
## One B1 diagnostic capture from a checked coordinator receipt.  It is not a
## fake stage receipt or a release visual gate; it records the first legal FIFO
## print while the raw silhouette is still incomplete.

const MAIN := preload("res://scenes/main.tscn")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	await _run()
	get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	require(active_root.begins_with(evidence_root + "/"), "M11 diagnostic capture requires the pre-autoload E: QA save root.")
	require(DisplayServer.get_name().to_lower() != "headless", "M11 diagnostic capture requires a rendered Forward+ viewport.")
	if not failures.is_empty():
		return
	get_window().content_scale_size = Vector2i(576, 1024)
	get_window().size = Vector2i(576, 1024)
	await get_tree().process_frame
	GameManager.profile = RULES.new_profile()
	GameManager.profile.settings = {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":false}
	var deck: Array = []
	for _index in 40:
		deck.append("cinderpaw")
	var state := STATE.create(deck, deck, 812)
	state.starting_seat = 0
	state.active_seat = 0
	state.phase = "print"
	state.turn = 2
	state.player(0).installed_upgrades = ["turbo_spool"]
	state.player(0).queue = [
		{"card_id":"cinderpaw", "remaining":1, "target":-1, "mode":"attack", "cost":70, "job_id":"job-1"},
		{"card_id":"aquafin", "remaining":1, "target":-1, "mode":"attack", "cost":70, "job_id":"job-2"},
		{"card_id":"coalgriffin", "remaining":5, "target":-1, "mode":"attack", "cost":440, "job_id":"job-3"}
	]
	var shell := MAIN.instantiate()
	shell.screen = "unified_battle"
	shell.battle = state
	shell.battle_mode = "local"
	shell.unified_battle_coordinator.configure(state, 0)
	add_child(shell)
	await get_tree().process_frame
	var accepted: Dictionary = shell.unified_battle_coordinator.submit_checked(shell.unified_battle_coordinator.envelope(0, {"type":"advance_phase"}), shell.unified_battle_coordinator.generation)
	var receipt: Dictionary = accepted.get("receipt", {}) if accepted.get("receipt", {}) is Dictionary else {}
	require(bool(accepted.get("ok", false)) and (receipt.get("print_events", []) as Array).size() == 3, "Diagnostic capture starts from an accepted legal three-work FIFO receipt.")
	if not failures.is_empty():
		return
	shell._present_unified_battle_event(receipt)
	shell.render()
	await get_tree().create_timer(.46).timeout
	await RenderingServer.frame_post_draw
	var stage := shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
	var raw := stage.find_child("BattlePrinterSolidRaw0", true, false) as TextureRect if stage != null else null
	var first_living := stage.find_child("LivingPrintSlot0", true, false) as TextureRect if stage != null else null
	require(stage != null and raw != null and raw.visible and first_living != null and not first_living.visible, "At the captured 60% raw-print beat, the printer owns the unfinished silhouette and no finished creature is already on the battlefield.")
	var image := get_viewport().get_texture().get_image()
	var output := SaveService.profile_path.get_base_dir().path_join("m11-b1-actual-fifo-print60-576x1024.png")
	require(image != null and image.get_size() == Vector2i(576, 1024) and image.save_png(output) == OK, "M11 diagnostic capture is a real 576x1024 Forward+ viewport PNG.")
	print("M11_B1_CAPTURE path=%s renderer=%s dimensions=%s receipt_serial=%d first_event=%s" % [output, RenderingServer.get_current_rendering_method(), image.get_size() if image != null else Vector2i(), int(receipt.get("serial", -1)), str(((receipt.get("print_events", []) as Array)[0] as Dictionary).get("event", ""))])
	shell.queue_free()
