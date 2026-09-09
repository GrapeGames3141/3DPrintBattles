extends Node

const SEQUENCE := preload("res://scripts/ui/battle_presentation_sequence.gd")
const VFX := preload("res://scripts/ui/battle_move_vfx.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var sequence := SEQUENCE.new()
	var receipt := {
		"kind":"print", "generation":7, "serial":12,
		"print_events":[
			{"event":"complete", "seat":0, "job_id":"job-a", "card_id":"cinderpaw", "remaining_before":1, "remaining_after":0, "total_work":1},
			{"event":"complete", "seat":0, "job_id":"job-b", "card_id":"aquafin", "remaining_before":1, "remaining_after":0, "total_work":1},
			{"event":"partial", "seat":0, "job_id":"job-c", "card_id":"coalgriffin", "remaining_before":5, "remaining_after":3, "total_work":5}
		],
		"deployments":[{"seat":0, "slot":0, "job_id":"job-a", "card_id":"cinderpaw"}, {"seat":0, "slot":1, "job_id":"job-b", "card_id":"aquafin"}]
	}
	var visual := sequence.begin(receipt, 4, false)
	var beats: Array = visual.get("presentation_beats", [])
	require(beats.size() == 5 and str((beats[0] as Dictionary).get("kind", "")) == "print" and str((beats[0] as Dictionary).get("job_id", "")) == "job-a" and str((beats[1] as Dictionary).get("kind", "")) == "deploy" and str((beats[1] as Dictionary).get("job_id", "")) == "job-a" and str((beats[2] as Dictionary).get("job_id", "")) == "job-b" and str((beats[3] as Dictionary).get("kind", "")) == "deploy" and str((beats[3] as Dictionary).get("job_id", "")) == "job-b" and str((beats[4] as Dictionary).get("job_id", "")) == "job-c", "Presentation orders legal FIFO work: complete A, land A, complete B, land B, then preserve partial C by stable job ID.")
	require(is_equal_approx(float(visual.get("presentation_duration", -1.0)), VFX.event_duration("print") * 3.0 + VFX.event_duration("deploy") * 2.0), "Presentation duration is the sum of finite legal FIFO work and arrival beats.")
	var attack := sequence.begin({"kind":"attack", "generation":8, "serial":13, "deployments":[{"seat":1, "slot":0, "job_id":"job-c", "card_id":"voltwig"}]}, 5, false)
	var attack_beats: Array = attack.get("presentation_beats", [])
	require(attack_beats.size() == 2 and str((attack_beats[0] as Dictionary).get("kind", "")) == "attack" and str((attack_beats[1] as Dictionary).get("kind", "")) == "deploy", "A staged replacement follows, rather than overlaps, the base attack contact.")
	var reduced := sequence.begin(receipt, 6, true)
	require(float(reduced.get("presentation_duration", -1.0)) == 0.0 and sequence.matches(6, 7, 12), "Reduced motion preserves receipt identity while settling the visual sequence without a timer.")
	sequence.finish()
	require(not sequence.matches(6, 7, 12), "Finished presentation sequences reject stale acknowledgement tokens.")
	if failures.is_empty(): print("PASS: M11 ordered battle presentation sequence")
	get_tree().quit(0 if failures.is_empty() else 1)
