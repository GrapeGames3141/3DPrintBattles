class_name TeamPrototypeFirstPrintController
extends RefCounted
## Persistent local presentation gate for the already-durable starter voucher.
## It never marks a retryable completion failure resolved; the same request identity
## remains available until Collection accepts the one authority completion.

const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")

var runtime: Variant
var sequence: Variant = null
var begin_request_id := ""
var complete_request_id := ""
var attempted_commit := false
var begin_error := ""
var save_error := ""
var creature_id := ""
var reduced_motion := false
var elapsed := 0.0
var paused := false


func presentation_snapshot() -> Dictionary:
	return {
		"phase": str(sequence.phase) if sequence != null else Sequence.IDLE,
		"begin_request_id": begin_request_id,
		"complete_request_id": complete_request_id,
		"attempted_commit": attempted_commit,
		"begin_error": begin_error,
		"save_error": save_error,
		"paused": paused,
	}

func configure(owner: Variant, collection: Dictionary, reduced_motion_value: bool) -> void:
	runtime = owner
	reduced_motion = reduced_motion_value
	creature_id = str(collection.get("starter_id", ""))
	var voucher: Dictionary = collection.get("voucher", {})
	if str(voucher.get("state", "")) == "printing":
		sequence = Sequence.create(reduced_motion, false)
		sequence.begin()

func start() -> Dictionary:
	if runtime == null:
		return {"ok": false, "error": "First Print runtime is unavailable."}
	if begin_request_id.is_empty():
		begin_request_id = "ui-begin-starter-%d" % Time.get_ticks_usec()
	var result: Dictionary = runtime.collection_request("begin_starter_print", begin_request_id, {})
	if bool(result.get("ok", false)):
		begin_error = ""
		sequence = Sequence.create(reduced_motion, false)
		sequence.begin()
	else:
		begin_error = str(result.get("error", "First Print could not be saved."))
	return result

func advance_delta(delta: float, print_id: String) -> Dictionary:
	if paused or sequence == null:
		return {"ok": true, "phase": sequence.phase if sequence != null else Sequence.IDLE}
	var interval := Sequence.presentation_interval_seconds(reduced_motion)
	# A foreground frame may spend at most two presentation intervals catching up.
	# Pausing resets the accumulator, so background time cannot turn into hidden
	# printing or a surprise authority commit on resume.
	elapsed += minf(maxf(delta, 0.0), interval * 2.0)
	var latest := {"ok": true, "phase": sequence.phase}
	var steps := 0
	while elapsed >= interval and steps < 2:
		elapsed -= interval
		latest = advance(Sequence.presentation_step_bps(reduced_motion, str(sequence.phase)), print_id)
		steps += 1
		if str(sequence.phase) in [Sequence.RAW_COMPLETE, Sequence.AWAKENED, Sequence.FAILED]:
			elapsed = 0.0
			break
	# Do not retain a multi-second backlog after a long exceptional foreground
	# frame. Normal 30/60/144 FPS delivery keeps its fractional remainder above.
	if steps == 2 and elapsed >= interval:
		elapsed = minf(elapsed, interval * 0.99)
	return latest

func advance(step_bps: int, print_id: String) -> Dictionary:
	if sequence == null:
		return {"ok": false, "error": "No active presentation."}
	sequence.advance(step_bps)
	if str(sequence.phase) != Sequence.RAW_COMPLETE:
		return {"ok": true, "phase": sequence.phase}
	if not attempted_commit:
		attempted_commit = true
		sequence.request_commit()
		if runtime == null:
			return {"ok": true, "raw_complete": true, "phase": sequence.phase}
		if complete_request_id.is_empty():
			complete_request_id = "ui-complete-starter-%d" % Time.get_ticks_usec()
		var completion: Dictionary = runtime.collection_request("complete_starter_print", complete_request_id, {"print_id":print_id})
		if bool(completion.get("ok", false)):
			sequence.resolve_commit(true)
			save_error = ""
			return {"ok": true, "completed": true, "phase": sequence.phase}
		save_error = str(completion.get("error", "Save Not Confirmed"))
	return {"ok": save_error.is_empty(), "raw_complete": true, "error": save_error, "phase": sequence.phase}

func set_paused(value: bool) -> void:
	paused = value
	elapsed = 0.0

func retry(print_id: String) -> Dictionary:
	if complete_request_id.is_empty() or runtime == null or sequence == null or str(sequence.phase) != Sequence.RAW_COMPLETE:
		return {"ok": false, "error": "No retained completion request."}
	var completion: Dictionary = runtime.collection_request("complete_starter_print", complete_request_id, {"print_id":print_id})
	if bool(completion.get("ok", false)):
		sequence.resolve_commit(true)
		save_error = ""
	return completion
