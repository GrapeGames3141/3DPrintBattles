extends Node
## One sandbox-portable composed v3 journey. It exercises public GameManager
## seams in their normal order against an isolated user:// save authority.

const RULES := preload("res://scripts/core/unified_rules.gd")
const ROOT := "user://checkpoint7-alpha-loop-isolated"
const FILES: Array[String] = ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]

var failures: Array[String] = []
var original_profile: Dictionary = {}
var original_compatibility: Dictionary = {}

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	original_compatibility = GameManager.save_compatibility.duplicate(true)
	var absolute_root := ProjectSettings.globalize_path(ROOT)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	for filename in FILES:
		var path := absolute_root.path_join(filename)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	SaveService.configure_test_paths(ROOT)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	GameManager.profile = RULES.new_profile()
	SaveService.commit_snapshot(GameManager.profile)

	var starter_revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.choose_starter("cinderpaw") and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and int(GameManager.profile.get("revision", 0)) == starter_revision + 1, "starter selection persists the saved v3 first-print setup exactly once")
	require(GameManager.print_selected_starter() and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "complete" and GameManager.active_deck_cards().size() == 40, "first print completes onboarding and provisions the legal Forge Deck")

	var printed_before := (GameManager.profile.get("printed_models", {}) as Dictionary).size()
	var print_result := GameManager.print_workshop_model_v3("cinderpaw", "alpha-workshop-print")
	require(bool(print_result.get("ok", false)) and (GameManager.profile.get("printed_models", {}) as Dictionary).size() == printed_before + 1, "Workshop print commits one persisted model receipt")
	require(bool(GameManager.print_workshop_model_v3("cinderpaw", "alpha-workshop-print").get("payload", {}).get("duplicate", false)), "duplicate Workshop print receipt cannot create a second model")

	var battle_result: Dictionary = GameManager.create_unified_battle("local", {"team":["mossmunk"]}, 42)
	require(bool(battle_result.get("ok", false)), "the completed starter profile launches a deterministic unified local battle")
	var revision_before_settlement := int(GameManager.profile.get("revision", 0))
	var settlement := GameManager.settle_unified_battle("alpha-local-settlement", battle_result.get("battle", null), true, 20)
	var duplicate_settlement := GameManager.settle_unified_battle("alpha-local-settlement", battle_result.get("battle", null), true, 20)
	require(bool(settlement.get("ok", false)) and bool(duplicate_settlement.get("payload", {}).get("duplicate", false)) and int(GameManager.profile.get("revision", 0)) == revision_before_settlement + 1, "unified local settlement persists once and returns a duplicate receipt on retry")

	var expected := GameManager.profile.duplicate(true)
	var reloaded := SaveService.load_profile()
	require(int(reloaded.get("revision", -1)) == int(expected.get("revision", -2)) and str(reloaded.get("onboarding", {}).get("state", "")) == "complete" and (reloaded.get("printed_models", {}) as Dictionary).size() == (expected.get("printed_models", {}) as Dictionary).size(), "snapshot reload preserves onboarding, printed models, and revision")
	require(SaveService.pending_events().size() >= 4, "the composed v3 journey retains durable event receipts without replay duplication")

	SaveService.reset_paths()
	GameManager.profile = original_profile
	GameManager.save_compatibility = original_compatibility
	if failures.is_empty(): print("PASS: sandbox-portable composed v3 alpha loop")
	get_tree().quit(0 if failures.is_empty() else 1)
