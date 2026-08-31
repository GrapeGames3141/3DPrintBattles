extends Node
const ROOT := "E:/AI Projects/games/3d print battler/build/validation/checkpoint5-save-isolated"
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	SaveService.configure_test_paths(ROOT)
	for filename in ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]:
		if FileAccess.file_exists(ROOT.path_join(filename)): DirAccess.remove_absolute(ROOT.path_join(filename))
	SaveService.commit_snapshot({"marker":"A","revision":1})
	SaveService.commit_snapshot({"marker":"B","revision":2})
	var primary := FileAccess.open(ROOT.path_join("profile.json"), FileAccess.WRITE); primary.store_string("{ truncated"); primary.close()
	var recovered := SaveService.load_profile()
	require(str(recovered.get("marker", "")) == "A" and SaveService.recovery_status == "backup_recovered", "malformed primary recovers validated backup A")
	SaveService.append_event("one", {}, 1); SaveService.append_event("two", {}, 2)
	SaveService.acknowledge_events(1)
	var once := SaveService.pending_events(); var twice := SaveService.pending_events()
	require(once.size() == 1 and twice.size() == 1 and int(once[0].revision) == 2 and str(twice[0].operation_id) == str(once[0].operation_id), "journal acknowledgement is idempotent")
	SaveService.reset_paths()
	if failures.is_empty(): print("PASS: checkpoint5 physical save backup recovery and journal acknowledgement")
	call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
