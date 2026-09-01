extends Node
## Regression coverage for the facade's persist-before-assign contract. These
## checks use a file as the configured save parent so FileAccess cannot create
## the snapshot, then retry against the same isolated user:// authority root.

const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const PROFILE_RULES := preload("res://scripts/core/profile_rules.gd")
const ROOT := "user://game-manager-atomicity"
const BLOCKER := "user://game-manager-atomicity-blocker"
const FILES: Array[String] = ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]

var failures: Array[String] = []
var original_profile: Dictionary = {}
var original_compatibility: Dictionary = {}
var campaign_toasts: Array[String] = []
var campaign_toast_listener: Callable = Callable()

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	original_compatibility = GameManager.save_compatibility.duplicate(true)
	_prepare_root()
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	campaign_toast_listener = func(message: String) -> void: campaign_toasts.append(message)
	GameManager.toast_requested.connect(campaign_toast_listener)

	# Starter selection must not become permanent until its candidate has written.
	GameManager.profile = UNIFIED_RULES.new_profile()
	SaveService.commit_snapshot(GameManager.profile)
	var starter_before := GameManager.profile.duplicate(true)
	_block_storage()
	require(not GameManager.choose_starter("cinderpaw") and GameManager.profile == starter_before and int(GameManager.profile.get("revision", 0)) == int(starter_before.get("revision", 0)), "choose_starter leaves profile and revision exact when persistence is unavailable")
	_restore_storage()
	var starter_revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.choose_starter("cinderpaw") and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and int(GameManager.profile.get("revision", 0)) == starter_revision + 1, "choose_starter commits the saved candidate exactly once after storage recovers")
	var starter_after := GameManager.profile.duplicate(true)
	require(not GameManager.choose_starter("cinderpaw") and GameManager.profile == starter_after, "repeated starter selection cannot produce a second commit")

	# Legacy coin callers keep their public bool/void shapes while staying atomic.
	GameManager.profile = PROFILE_RULES.new_profile()
	SaveService.commit_snapshot(GameManager.profile)
	var spend_before := GameManager.profile.duplicate(true)
	_block_storage()
	require(not GameManager.spend_coins(1, "atomicity") and GameManager.profile == spend_before, "spend_coins returns false without changing memory when persistence fails")
	_restore_storage()
	var spend_revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.spend_coins(1, "atomicity") and int(GameManager.profile.get("coins", 0)) == int(spend_before.get("coins", 0)) - 1 and int(GameManager.profile.get("revision", 0)) == spend_revision + 1, "spend_coins commits its exact candidate once after storage recovers")

	# A battle latch belongs to the in-memory battle only after the reward profile
	# snapshot succeeds; a retry can then commit once and no more.
	GameManager.profile = PROFILE_RULES.new_profile()
	SaveService.commit_snapshot(GameManager.profile)
	var battle := BattleState.new()
	battle.finished = true
	battle.winner = 0
	var reward_before := GameManager.profile.duplicate(true)
	_block_storage()
	require(not GameManager.claim_battle_reward(battle) and not battle.reward_claimed and GameManager.profile == reward_before, "claim_battle_reward preserves both profile and reward latch on persistence failure")
	_restore_storage()
	var reward_revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.claim_battle_reward(battle) and battle.reward_claimed and int(GameManager.profile.get("revision", 0)) == reward_revision + 1, "claim_battle_reward sets its latch only after one successful persisted reward")
	require(not GameManager.claim_battle_reward(battle) and int(GameManager.profile.get("revision", 0)) == reward_revision + 1, "claimed battle rewards remain exactly once after recovery")

	# Published-success feedback must wait for a durable campaign candidate too.
	GameManager.profile = PROFILE_RULES.new_profile()
	SaveService.commit_snapshot(GameManager.profile)
	var campaign_before := GameManager.profile.duplicate(true)
	campaign_toasts.clear()
	_block_storage()
	require(not GameManager.claim_campaign_victory("first_layers_1", 5) and GameManager.profile == campaign_before and not _has_campaign_success_toast(), "campaign persistence failure leaves profile exact and does not emit a success or spool toast")
	_restore_storage()
	var campaign_revision := int(GameManager.profile.get("revision", 0))
	require(GameManager.claim_campaign_victory("first_layers_1", 5) and int(GameManager.profile.get("revision", 0)) == campaign_revision + 1, "campaign victory emits its result only after one persisted commit")

	_finish()

func _prepare_root() -> void:
	var absolute_root := ProjectSettings.globalize_path(ROOT)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	for filename in FILES:
		var path := absolute_root.path_join(filename)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var blocker_absolute := ProjectSettings.globalize_path(BLOCKER)
	if FileAccess.file_exists(blocker_absolute): DirAccess.remove_absolute(blocker_absolute)
	SaveService.configure_test_paths(ROOT)

func _block_storage() -> void:
	var blocker := FileAccess.open(BLOCKER, FileAccess.WRITE)
	if blocker != null:
		blocker.store_string("This file deliberately occupies the save parent.")
		blocker.close()
	SaveService.configure_test_paths(BLOCKER)

func _restore_storage() -> void:
	SaveService.configure_test_paths(ROOT)

func _has_campaign_success_toast() -> bool:
	for message in campaign_toasts:
		if message.contains("New Workshop Trial best") or message.contains("filament spool grew"):
			return true
	return false

func _finish() -> void:
	if campaign_toast_listener.is_valid() and GameManager.toast_requested.is_connected(campaign_toast_listener):
		GameManager.toast_requested.disconnect(campaign_toast_listener)
	SaveService.reset_paths()
	GameManager.profile = original_profile
	GameManager.save_compatibility = original_compatibility
	if failures.is_empty(): print("PASS: GameManager persistence mutations remain atomic across unavailable storage")
	get_tree().quit(0 if failures.is_empty() else 1)
