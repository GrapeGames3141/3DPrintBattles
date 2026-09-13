class_name TeamPrototypeEntry
extends TeamPrototypeShell
## The production scene owner.  Tests instantiate TeamPrototypeShell directly and
## inject their Runtime; only this entry opens the configured save boundary.

var _owned_runtime: Variant = null
var _entry_smoke := false
var _expected_route := ""
var _smoke_failures := 0


func _ready() -> void:
	super._ready()
	_entry_smoke = _entry_smoke_requested()
	_expected_route = _argument_value("--expect-route=")
	_open_production_runtime()
	if _entry_smoke:
		call_deferred("_run_entry_smoke")


func _exit_tree() -> void:
	if _owned_runtime != null:
		_owned_runtime.close()
		_owned_runtime = null


func _open_production_runtime() -> void:
	var compatibility: Dictionary = GameManager.save_compatibility.duplicate(true)
	if not bool(compatibility.get("compatible", false)):
		configure_recovery(str(compatibility.get("state", "startup_recovery")))
		return
	var profile_path := ProjectSettings.globalize_path(SaveService.profile_path)
	var opened: Dictionary = Runtime.open(profile_path, compatibility)
	if not bool(opened.get("ok", false)) or opened.get("runtime", null) == null:
		configure_recovery(str(opened.get("error", "runtime_open_failed")))
		return
	_owned_runtime = opened.runtime
	if _owned_runtime.is_recovery():
		configure_recovery(str(opened.get("recovery", "runtime_recovery")))
		_owned_runtime.close()
		_owned_runtime = null
		return
	configure_runtime(_owned_runtime)


func _entry_smoke_requested() -> bool:
	if not OS.is_debug_build():
		return false
	var requested := false
	var qa_roots: Array[String] = []
	for raw_argument in OS.get_cmdline_user_args():
		var argument := str(raw_argument)
		if argument == "--team-entry-smoke":
			requested = true
		elif argument.begins_with("--qa-save-root="):
			qa_roots.append(argument.trim_prefix("--qa-save-root=").strip_edges().trim_prefix("\"").trim_suffix("\"").replace("\\", "/"))
	if not requested or qa_roots.size() != 1:
		return false
	var allowed := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var candidate := qa_roots[0]
	return candidate.is_absolute_path() and candidate.begins_with(allowed + "/") and not candidate.contains("..")


func _argument_value(prefix: String) -> String:
	for raw_argument in OS.get_cmdline_user_args():
		var argument := str(raw_argument)
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func _run_entry_smoke() -> void:
	await get_tree().process_frame
	if _expected_route not in ["workshop", "recovery"]:
		_smoke_fail("Smoke expected route is missing or invalid.")
	else:
		_smoke_require(route == _expected_route, "Expected %s route, found %s." % [_expected_route, route])
		var back_button := find_child("RouteBack", true, false)
		_smoke_require(back_button is Button and back_button.visible, "Recovery or Workshop Back owner was not visible.")
		if back_button is Button and back_button.visible:
			(back_button as Button).pressed.emit()
			await get_tree().process_frame
			_smoke_require(leave_confirmation, "Back did not open the visible Leave/Stay confirmation.")
			var stay_button := find_child("LeaveStay", true, false)
			_smoke_require(stay_button is Button and stay_button.visible, "Stay owner was not visible.")
			if stay_button is Button and stay_button.visible:
				(stay_button as Button).pressed.emit()
				await get_tree().process_frame
				_smoke_require(not leave_confirmation and route == _expected_route, "Stay did not restore the entry route.")
	print("TEAM_PROTOTYPE_ENTRY failures=%d" % _smoke_failures)
	get_tree().quit(0 if _smoke_failures == 0 else 1)


func _smoke_require(condition: bool, message: String) -> void:
	if condition:
		return
	_smoke_fail(message)


func _smoke_fail(message: String) -> void:
	_smoke_failures += 1
	push_error("Team prototype entry smoke: %s" % message)
