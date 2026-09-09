class_name BattlePresentationSequence
extends RefCounted
## Sole non-authoritative lifecycle owner for one checked battle receipt.

const VFX := preload("res://scripts/ui/battle_move_vfx.gd")

var generation := -1
var receipt_serial := -1
var token := -1
var duration := 0.0
var active := false

func begin(receipt: Dictionary, next_token: int, reduced_motion: bool) -> Dictionary:
	generation = int(receipt.get("generation", -1))
	receipt_serial = int(receipt.get("serial", -1))
	token = next_token
	var kind := str(receipt.get("kind", ""))
	var beats := _beats_for(receipt, kind)
	duration = 0.0
	for beat in beats: duration += float((beat as Dictionary).get("duration", 0.0))
	if reduced_motion: duration = 0.0
	active = not beats.is_empty()
	var event := receipt.duplicate(true)
	event["presentation_beats"] = beats
	event["presentation_duration"] = duration
	event["presentation_token"] = token
	event["presentation_serial"] = receipt_serial
	return event

func _beats_for(receipt: Dictionary, kind: String) -> Array:
	var beats: Array = []
	var deployments: Array = receipt.get("deployments", []) if receipt.get("deployments", []) is Array else []
	var deployed_jobs := {}
	if kind == "attack": beats.append({"kind":"attack", "duration":VFX.event_duration("attack")})
	var work: Array = receipt.get("print_events", []) if receipt.get("print_events", []) is Array else []
	for item in work:
		if not item is Dictionary: continue
		var job: Dictionary = item
		beats.append({"kind":"print", "duration":VFX.event_duration("print"), "work":job.duplicate(true), "job_id":str(job.get("job_id", "")), "seat":int(job.get("seat", receipt.get("actor", 0))), "card_id":str(job.get("card_id", ""))})
		if str(job.get("event", "")) in ["complete", "fitting"]:
			for deployment in deployments:
				if deployment is Dictionary and str((deployment as Dictionary).get("job_id", "")) == str(job.get("job_id", "")):
					beats.append(_deployment_beat(deployment as Dictionary))
					deployed_jobs[str(job.get("job_id", ""))] = true
	if kind == "deploy" and work.is_empty():
		for deployment in deployments:
			if deployment is Dictionary:
				beats.append(_deployment_beat(deployment as Dictionary))
				deployed_jobs[str((deployment as Dictionary).get("job_id", ""))] = true
	for deployment in deployments:
		if deployment is Dictionary and not deployed_jobs.has(str((deployment as Dictionary).get("job_id", ""))): beats.append(_deployment_beat(deployment as Dictionary))
	if beats.is_empty() and not kind.is_empty(): beats.append({"kind":kind, "duration":VFX.event_duration(kind)})
	return beats

func _deployment_beat(deployment: Dictionary) -> Dictionary:
	return {"kind":"deploy", "duration":VFX.event_duration("deploy"), "deployment":deployment.duplicate(true), "job_id":str(deployment.get("job_id", "")), "seat":int(deployment.get("seat", 0)), "card_id":str(deployment.get("card_id", ""))}

func matches(candidate_token: int, candidate_generation: int, candidate_serial: int) -> bool:
	return active and candidate_token == token and candidate_generation == generation and candidate_serial == receipt_serial

func finish() -> void:
	active = false
