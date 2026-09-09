extends Node
## B1 integration proof: accepted authority receipts flow through Main and the
## mounted physical stage.  Fixtures may seed a legal public state, but never
## fabricate the receipt consumed by the presentation layer.

const MAIN := preload("res://scenes/main.tscn")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _phase(marker: String) -> void:
	# Keep native-crash evidence ordered even when the process dies outside
	# GDScript.  These markers distinguish receipt rendering from deferred teardown.
	print("M11_B1_PHASE %s" % marker)

func _qa_root_isolated() -> bool:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	var isolated := active_root.begins_with(evidence_root + "/")
	require(isolated, "M11 presentation integration requires the pre-autoload E: QA save root.")
	return isolated

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await get_tree().process_frame

func _new_state() -> UnifiedBattleState:
	var deck: Array = []
	for _index in 40:
		deck.append("cinderpaw")
	var state := STATE.create(deck, deck, 811)
	state.starting_seat = 0
	state.active_seat = 0
	state.phase = "print"
	state.turn = 2
	return state

func _receipt_event(result: Dictionary) -> Dictionary:
	return result.get("receipt", {}) as Dictionary

func _ready() -> void:
	_phase("ready")
	if not _qa_root_isolated():
		_phase("qa_rejected")
		get_tree().quit(1)
		return
	await _run()
	_phase("before_quit failures=%d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func _run() -> void:
	_phase("run_begin")
	GameManager.profile = RULES.new_profile()
	GameManager.profile.settings = {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":false}
	var shell := MAIN.instantiate()
	shell.size = Vector2(576, 1024)
	shell.screen = "unified_battle"
	add_child(shell)
	await get_tree().process_frame
	_phase("shell_mounted")

	# Turbo Spool's legal three-work Print budget gives the required FIFO outcome:
	# complete A, complete B, then partial C.  The coordinator emits the only
	# receipt; Main mounts it, and the stage derives every finite beat from it.
	var fifo := _new_state()
	fifo.player(0).installed_upgrades = ["turbo_spool"]
	fifo.player(0).queue = [
		{"card_id":"cinderpaw", "remaining":1, "target":-1, "mode":"attack", "cost":70, "job_id":"job-1"},
		{"card_id":"aquafin", "remaining":1, "target":-1, "mode":"attack", "cost":70, "job_id":"job-2"},
		{"card_id":"coalgriffin", "remaining":5, "target":-1, "mode":"attack", "cost":440, "job_id":"job-3"}
	]
	shell.battle = fifo
	shell.battle_mode = "local"
	shell.unified_battle_coordinator.configure(fifo, 0)
	var printed: Dictionary = shell.unified_battle_coordinator.submit_checked(shell.unified_battle_coordinator.envelope(0, {"type":"advance_phase"}), shell.unified_battle_coordinator.generation)
	var print_receipt := _receipt_event(printed)
	var work: Array = print_receipt.get("print_events", []) if print_receipt.get("print_events", []) is Array else []
	require(bool(printed.get("ok", false)) and work.size() == 3 and str((work[0] as Dictionary).get("event", "")) == "complete" and str((work[1] as Dictionary).get("event", "")) == "complete" and str((work[2] as Dictionary).get("event", "")) == "partial" and str((work[2] as Dictionary).get("job_id", "")) == "job-3", "Coordinator produces the legal complete-A, complete-B, partial-C FIFO receipt.")
	shell._present_unified_battle_event(print_receipt)
	shell.render()
	await get_tree().process_frame
	_phase("fifo_first_frame")
	var stage := shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
	var beats: Array = stage.event.get("presentation_beats", []) if stage != null and stage.event.get("presentation_beats", []) is Array else []
	require(stage != null and beats.size() == 5 and str((beats[0] as Dictionary).get("job_id", "")) == "job-1" and str((beats[1] as Dictionary).get("kind", "")) == "deploy" and str((beats[4] as Dictionary).get("job_id", "")) == "job-3", "Main passes the coordinator receipt into one ordered stage sequence, rather than a fabricated first-job preview.")
	var first_slot := stage.find_child("LivingPrintSlot0", true, false) as TextureRect if stage != null else null
	var second_slot := stage.find_child("LivingPrintSlot1", true, false) as TextureRect if stage != null else null
	require(first_slot != null and second_slot != null and not first_slot.visible and not second_slot.visible, "Authority's completed creatures stay concealed until their own arrival beats begin.")
	await _wait(1.55)
	_phase("fifo_a_landed")
	require(first_slot.visible and not second_slot.visible, "Only completed job A has landed before job B's own finite arrival beat.")
	await _wait(2.55)
	_phase("fifo_finished")
	var fifo_remaining := int(fifo.player(0).queue[0].get("remaining", -1)) if not fifo.player(0).queue.is_empty() else -1
	require(not shell.unified_battle_coordinator.presentation_active and first_slot.visible and second_slot.visible and fifo_remaining == 4, "The stage's single clock acknowledges once after ordered FIFO beats while partial job C remains authoritative queue work (active=%s first=%s second=%s remaining=%d event=%s)." % [str(shell.unified_battle_coordinator.presentation_active), str(first_slot.visible), str(second_slot.visible), fifo_remaining, str(stage.event if stage != null else {})])

	# A public attack receipt may deploy a staged replacement after contact.  The
	# original defender owns the visible contact beat even though authority has
	# already filled the released anchor with the next staged job.
	var contact := _new_state()
	contact.phase = "attack"
	contact.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	contact.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	contact.player(1).slots[0].hp = 1
	contact.player(1).staging = [{"unit":STATE._unit(RULES.card("voltwig")), "job_id":"replacement-1"}]
	shell.battle = contact
	shell.unified_battle_coordinator.configure(contact, 0)
	var attack: Dictionary = shell.unified_battle_coordinator.submit_checked(shell.unified_battle_coordinator.envelope(0, {"type":"attack", "slot":0, "target":0}), shell.unified_battle_coordinator.generation)
	var attack_receipt := _receipt_event(attack)
	require(bool(attack.get("ok", false)) and bool(attack_receipt.get("defeated", false)) and str(contact.player(1).slots[0].get("card_id", "")) == "voltwig", "Authority resolves a defeat and staged replacement without overwriting the receipt defender identity.")
	shell._present_unified_battle_event(attack_receipt)
	shell.render()
	await _wait(.24)
	_phase("attack_contact")
	stage = shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
	var defender_caption := stage.find_child("LivingPrintCaption3", true, false) as Label if stage != null else null
	require(defender_caption != null and defender_caption.visible and defender_caption.text.contains("Aquafin"), "The original defeated defender remains visible through Main's contact beat while the future replacement stays hidden.")
	await _wait(1.20)
	_phase("attack_finished")
	defender_caption = stage.find_child("LivingPrintCaption3", true, false) as Label if stage != null else null
	require(defender_caption != null and defender_caption.visible and defender_caption.text.contains("Voltwig") and not shell.unified_battle_coordinator.presentation_active, "The staged replacement becomes the only living occupant after its own post-contact landing beat (active=%s caption=%s visible=%s event=%s)." % [str(shell.unified_battle_coordinator.presentation_active), defender_caption.text if defender_caption != null else "<missing>", str(defender_caption.visible if defender_caption != null else false), str(stage.event if stage != null else {})])
	_phase("before_queue_free")
	shell.queue_free()
	_phase("after_queue_free")
