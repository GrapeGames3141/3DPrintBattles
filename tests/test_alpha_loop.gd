extends Node
## One isolated composed internal-alpha journey. This exercises the public seams in
## their normal order rather than repeating the focused rule tests.

const MAIN := preload("res://scenes/main.tscn")
const TEST_ROOT := "E:/CodexCache/printforge-validation/checkpoint7-alpha-loop-isolated"
const TEST_FILES: Array[String] = ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]

var failures: Array[String] = []
var original_profile: Dictionary = {}

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	_clean_test_files()
	SaveService.configure_test_paths(TEST_ROOT)
	GameManager.profile = ProfileRules.new_profile()

	# New profile routing and the permanent starter transition both travel through
	# the same GameManager persistence/journal seam used by the application.
	require(OnboardingState.screen_for_profile(GameManager.profile) == "onboarding", "new profile routes into onboarding")
	var revision_before_starter: int = int(GameManager.profile.revision)
	var selected_starter: bool = GameManager.choose_starter("cinderpaw")
	require(selected_starter and ProfileRules.has_starter(GameManager.profile) and int(GameManager.profile.revision) == revision_before_starter + 1, "starter selection is permanent and revisioned")
	var starter_instance_id: String = str(GameManager.profile.onboarding.starter_instance_id)
	require(GameManager.profile.team == [starter_instance_id] and "cinderpaw" in GameManager.profile.blueprints, "starter creates its bound blueprint and training team")

	var coins_before_job: int = int(GameManager.profile.coins)
	var revision_before_job: int = int(GameManager.profile.revision)
	var job_reward: int = GameManager.complete_workshop_job(100)
	require(job_reward == 28 and int(GameManager.profile.coins) == coins_before_job + job_reward and int(GameManager.profile.revision) == revision_before_job + 1, "workshop job mutates the economy once")

	var moss_definition: Dictionary = Catalog.creature("mossmunk")
	var blueprint_price: int = int(Catalog.rarity(str(moss_definition.rarity)).blueprint)
	var coins_before_blueprint: int = int(GameManager.profile.coins)
	var learned_blueprint: bool = GameManager.learn_blueprint("mossmunk")
	require(learned_blueprint and "mossmunk" in GameManager.profile.blueprints and int(GameManager.profile.coins) == coins_before_blueprint - blueprint_price, "blueprint purchase is catalog-priced and atomic")

	# Drive the actual Arcane Forge UI test seam through raw completion. Previewing
	# has no mutation; the one commit latch creates exactly one tradable instance.
	var main: Variant = MAIN.instantiate()
	main.printer_capture_freeze = true
	add_child(main)
	await get_tree().process_frame
	var coins_before_print: int = int(GameManager.profile.coins)
	var creature_count_before_print: int = GameManager.profile.creatures.size()
	var revision_before_print: int = int(GameManager.profile.revision)
	var print_price: int = int(Catalog.rarity(str(moss_definition.rarity)).print)
	main.open_printer("mossmunk")
	await get_tree().process_frame
	require(GameManager.profile.creatures.size() == creature_count_before_print and int(GameManager.profile.coins) == coins_before_print, "Forge preview does not mutate the profile")
	main.begin_printer()
	main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	await get_tree().process_frame
	var printed_instance_id: String = str(GameManager.profile.creatures[GameManager.profile.creatures.size() - 1].instance_id)
	require(main.printer_sequence.phase == ArcaneForgeSequence.RAW_HOLD and GameManager.profile.creatures.size() == creature_count_before_print + 1 and int(GameManager.profile.coins) == coins_before_print - print_price and int(GameManager.profile.revision) == revision_before_print + 1, "raw completion commits one catalog print and enters the post-commit raw hold")
	main.advance_printer_for_test(ArcaneForgeSequence.FULL_BPS)
	main.skip_printer()
	require(GameManager.profile.creatures.size() == creature_count_before_print + 1, "Forge completion and skip cannot duplicate the print")
	main.queue_free()
	await get_tree().process_frame

	var saved_team: bool = GameManager.save_team([starter_instance_id, printed_instance_id])
	var starter_deck: Array = ProgressionRules.STARTER_DECK.duplicate()
	var saved_deck: bool = GameManager.save_deck(starter_deck)
	require(saved_team and GameManager.profile.team == [starter_instance_id, printed_instance_id], "two owned prints save as a legal team")
	require(saved_deck and GameManager.active_deck_cards() == starter_deck, "the owned fifteen-card support deck saves as active")

	# Use a deterministic real-rule sequence: opening defense, rival pass, then an
	# ordinary basic attack. The low target HP keeps this composed smoke concise.
	var battle: BattleState = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
	battle.active_unit(1).hp = 1
	var opening_defend: Dictionary = BattleRules.apply_intent(battle, 0, {"type":"defend"})
	var rival_pass: Dictionary = BattleRules.apply_intent(battle, 1, {"type":"end_turn"})
	var winning_attack: Dictionary = BattleRules.apply_intent(battle, 0, {"type":"attack"})
	require(bool(opening_defend.ok) and bool(rival_pass.ok) and bool(winning_attack.ok) and battle.finished and battle.winner == 0, "legal deterministic battle intents resolve a player victory")
	var coins_before_reward: int = int(GameManager.profile.coins)
	var xp_before_reward: int = int(GameManager.profile.xp)
	var revision_before_reward: int = int(GameManager.profile.revision)
	var first_reward: bool = GameManager.claim_battle_reward(battle)
	var second_reward: bool = GameManager.claim_battle_reward(battle)
	require(first_reward and not second_reward and int(GameManager.profile.coins) == coins_before_reward + 20 and int(GameManager.profile.xp) == xp_before_reward + 30 and int(GameManager.profile.revision) == revision_before_reward + 1, "battle reward is persisted exactly once")

	var expected_profile: Dictionary = GameManager.profile.duplicate(true)
	var journal_before_reload: Array = SaveService.pending_events()
	var reloaded: Dictionary = SaveService.load_profile()
	var reloaded_deck: Array = ProgressionRules.active_deck(reloaded)
	var saved_fields_match: bool = int(reloaded.get("coins", -1)) == int(expected_profile.coins) and int(reloaded.get("xp", -1)) == int(expected_profile.xp) and int(reloaded.get("revision", -1)) == int(expected_profile.revision) and reloaded.team == [starter_instance_id, printed_instance_id] and reloaded_deck == starter_deck and reloaded.creatures.size() == 2 and "cinderpaw" in reloaded.blueprints and "mossmunk" in reloaded.blueprints
	require(saved_fields_match, "snapshot reload preserves inventory, team, deck, reward, and revision")
	require(journal_before_reload.size() >= 6 and _journal_has_kind(journal_before_reload, "battle_reward") and SaveService.pending_events().size() == journal_before_reload.size(), "journal reload retains the reward event without duplication")

	if failures.is_empty():
		print("PASS: checkpoint7 composed credential-free alpha loop")
	call_deferred("finish")

func _journal_has_kind(rows: Array, wanted_kind: String) -> bool:
	for row in rows:
		if row is Dictionary and str(row.get("kind", "")) == wanted_kind:
			return true
	return false

func _clean_test_files() -> void:
	for filename: String in TEST_FILES:
		var path: String = TEST_ROOT.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func finish() -> void:
	_clean_test_files()
	SaveService.reset_paths()
	GameManager.profile = original_profile
	get_tree().quit(0 if failures.is_empty() else 1)
