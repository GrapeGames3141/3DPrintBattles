extends Node
## Release-only integration proof. It seeds legal public authority state, then
## uses the mounted Run Cycle control; it never manually submits, acknowledges,
## or continues a receipt after the initial viewport press.

const MAIN := preload("res://scenes/main.tscn")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _qa_root_isolated() -> bool:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	var isolated := active_root.begins_with(evidence_root + "/")
	require(isolated, "M11 release cycle proof requires a pre-autoload E: QA save root.")
	return isolated

func _deck(card_id: String) -> Array:
	var cards: Array = []
	for _index in 40:
		cards.append(card_id)
	return cards

func _pointer_activate(target: Button) -> bool:
	if target == null or target.disabled or not target.is_visible_in_tree():
		return false
	get_viewport().notify_mouse_entered()
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	get_viewport().push_input(move)
	await get_tree().process_frame
	if get_viewport().gui_get_hovered_control() != target:
		return false
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.position = point
	up.global_position = point
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame
	return true

func _contains_job(events: Array, job_id: String) -> bool:
	for item in events:
		if item is Dictionary and str((item as Dictionary).get("job_id", "")) == job_id:
			return true
	return false

func _seed_state() -> UnifiedBattleState:
	var state := STATE.create(_deck("cinderpaw"), _deck("aquafin"), 906)
	state.starting_seat = 0
	state.active_seat = 0
	state.phase = "main"
	state.turn = 2
	state.player(0).hand = []
	state.player(0).filament = 1000
	state.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "target":-1, "mode":"attack", "cost":70, "job_id":"release-player-print"}]
	state.player(1).hand = ["aquafin"]
	state.player(1).filament = 1000
	state.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	state.player(1).slots[0].hp = 1
	return state

func _run_case(reduced_motion: bool) -> void:
	get_window().content_scale_size = Vector2i(576, 1024)
	get_window().size = Vector2i(576, 1024)
	GameManager.profile = RULES.new_profile()
	GameManager.profile.settings = {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":reduced_motion}
	var shell := MAIN.instantiate()
	add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	shell.battle = _seed_state()
	shell.battle_mode = "training"
	shell.unified_local_handoff = false
	shell.unified_ai_pending = false
	shell.unified_battle_coordinator.configure(shell.battle, 0)
	shell.screen = "unified_battle"
	shell.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var lever := shell.find_child("UnifiedRunCycleLever", true, false) as Button
	var revision_before := int(shell.battle.revision)
	require(await _pointer_activate(lever), "Release cycle fixture reaches the visible enabled Run Cycle mount through the viewport.")

	var saw_player_print := false
	var saw_player_deploy := false
	var saw_player_attack := false
	var saw_rival_receipt := false
	var saw_stage_beat := false
	var completed := false
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		var stage := shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
		var event: Dictionary = stage.event if stage != null else {}
		var actor := int(event.get("actor", -1))
		var work: Array = event.get("print_events", []) if event.get("print_events", []) is Array else []
		var deployments: Array = event.get("deployments", []) if event.get("deployments", []) is Array else []
		if actor == 0 and _contains_job(work, "release-player-print"):
			saw_player_print = true
		if actor == 0 and _contains_job(deployments, "release-player-print"):
			saw_player_deploy = true
		if actor == 0 and str(event.get("kind", "")) == "attack":
			saw_player_attack = true
		if actor == 1 and not event.is_empty():
			saw_rival_receipt = true
		if not event.is_empty() and event.get("presentation_beats", []) is Array and not (event.get("presentation_beats", []) as Array).is_empty():
			saw_stage_beat = true
		if shell.battle != null and int(shell.battle.active_seat) == 0 and str(shell.battle.phase) == "main" and not shell.unified_battle_coordinator.cycle_active and not shell.unified_battle_coordinator.presentation_active and not shell.unified_ai_pending:
			completed = true
			break
		await get_tree().create_timer(.02).timeout
	lever = shell.find_child("UnifiedRunCycleLever", true, false) as Button
	var mode := "reduced-motion" if reduced_motion else "animated"
	if not reduced_motion:
		require(saw_player_print and saw_player_deploy and saw_player_attack and saw_stage_beat, "Animated Run Cycle naturally emits player print, deployment, attack, and mounted finite stage beats from checked receipts.")
	else:
		var player_slots: Array = shell.battle.player(0).get("slots", []) if shell.battle != null else []
		var player_printed := not player_slots.is_empty() and player_slots[0] is Dictionary and str((player_slots[0] as Dictionary).get("card_id", "")) == "cinderpaw"
		require(player_printed, "Reduced-motion Run Cycle completes the same checked player print/deploy before returning control, even when zero-duration receipts settle within one frame.")
	require(saw_rival_receipt, "%s Run Cycle naturally renders accepted rival receipt work after the player cycle." % mode)
	require(completed and lever != null and not lever.disabled and int(shell.battle.revision) > revision_before, "%s Run Cycle returns to the friendly settled Plan with an enabled lever and progressed authority revision." % mode)
	require(not str(shell.toast).contains("paused safely") and not str(shell.toast).contains("safety"), "%s Run Cycle does not hit the rival safety-stop path." % mode)
	shell.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	if not _qa_root_isolated():
		get_tree().quit(1)
		return
	if DisplayServer.get_name() == "headless":
		require(false, "M11 release cycle proof requires a rendered DisplayServer; headless scheduling runs are not visual evidence.")
		get_tree().quit(1)
		return
	await _run_case(false)
	await _run_case(true)
	if failures.is_empty():
		print("PASS: M11 release Run Cycle drives real Main, receipts, stage beats, and rival handoff")
	get_tree().quit(0 if failures.is_empty() else 1)
