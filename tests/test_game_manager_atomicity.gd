extends Node
## Regression coverage for the facade's persist-before-assign contract. These
## checks use a file as the configured save parent so FileAccess cannot create
## the snapshot, then retry against the same isolated user:// authority root.

const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const PROFILE_RULES := preload("res://scripts/core/profile_rules.gd")
const FILES: Array[String] = ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]

var failures: Array[String] = []
var original_profile: Dictionary = {}
var original_compatibility: Dictionary = {}
var campaign_toasts: Array[String] = []
var campaign_toast_listener: Callable = Callable()
var configured_root := ""
var fixture_root := ""
var blocker_path := ""

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	original_compatibility = GameManager.save_compatibility.duplicate(true)
	configured_root = SaveService.profile_path.get_base_dir()
	if not configured_root.replace("\\", "/").contains("/build/evidence/"):
		require(false, "Atomicity test requires pre-autoload E: build/evidence QA storage; refusing fixture writes outside it.")
		_finish()
		return
	fixture_root = configured_root.path_join("game-manager-atomicity")
	blocker_path = configured_root.path_join("game-manager-atomicity-blocker")
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

	# The market facade must reject a stale displayed price before it commits a
	# receipt, revision, journal source, cards, or Newcomer expiry state.
	GameManager.profile = UNIFIED_RULES.new_profile()
	GameManager.profile.forge_coins = 1000
	GameManager.profile.newcomer_started_at = int(Time.get_unix_time_from_system()) - 8 * 86400
	SaveService.commit_snapshot(GameManager.profile)
	var pack_before := GameManager.profile.duplicate(true)
	var source_before := FileAccess.get_file_as_string(SaveService.profile_path)
	var stale_pack := GameManager.buy_card_pack("basic", "unified_market", {"market_tab":"packs"}, 0)
	require(not bool(stale_pack.get("ok", false)) and bool(stale_pack.get("price_changed", false)) and GameManager.profile == pack_before and FileAccess.get_file_as_string(SaveService.profile_path) == source_before and int(GameManager.profile.get("revision", 0)) == int(pack_before.get("revision", 0)), "stale pack confirmation leaves facade memory, persisted source, and revision unchanged")
	var matching_pack := GameManager.buy_card_pack("basic", "unified_market", {"market_tab":"packs"}, int(stale_pack.get("effective_price", -1)))
	require(bool(matching_pack.get("ok", false)) and int(GameManager.profile.get("revision", 0)) == int(pack_before.get("revision", 0)) + 1 and not GameManager.profile.get("pending_pack_reveal", {}).is_empty(), "matching frozen pack price commits one existing receipt through the facade")

	_finish()

func _prepare_root() -> void:
	var absolute_root := ProjectSettings.globalize_path(fixture_root)
	DirAccess.make_dir_recursive_absolute(absolute_root)
	for filename in FILES:
		var path := absolute_root.path_join(filename)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var blocker_absolute := ProjectSettings.globalize_path(blocker_path)
	if FileAccess.file_exists(blocker_absolute): DirAccess.remove_absolute(blocker_absolute)
	SaveService.configure_test_paths(fixture_root)

func _block_storage() -> void:
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	if blocker != null:
		blocker.store_string("This file deliberately occupies the save parent.")
		blocker.close()
	SaveService.configure_test_paths(blocker_path)

func _restore_storage() -> void:
	SaveService.configure_test_paths(fixture_root)

func _has_campaign_success_toast() -> bool:
	for message in campaign_toasts:
		if message.contains("New Workshop Trial best") or message.contains("filament spool grew"):
			return true
	return false

func _finish() -> void:
	if campaign_toast_listener.is_valid() and GameManager.toast_requested.is_connected(campaign_toast_listener):
		GameManager.toast_requested.disconnect(campaign_toast_listener)
	SaveService.configure_test_paths(configured_root)
	GameManager.profile = original_profile
	GameManager.save_compatibility = original_compatibility
	if failures.is_empty(): print("PASS: GameManager persistence mutations remain atomic across unavailable storage")
	get_tree().quit(0 if failures.is_empty() else 1)
