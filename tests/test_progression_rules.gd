extends Node
## Regression coverage for pure offline progression; the final assertion exercises GameManager's journal seam.

var failures: Array[String] = []
var original_profile: Dictionary = {}

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	var legacy := {"schema_version":2,"coins":333,"xp":4,"spool_level":5,"blueprints":["cinderpaw"],"creatures":[{"instance_id":"starter-cinder-1","creature_id":"cinderpaw","bound":true,"tradable":false,"suit_instance_id":""}],"team":["starter-cinder-1"],"suits":[],"cores":[],"discovered":["cinderpaw"],"onboarding":{"state":"complete","starter_id":"cinderpaw","starter_instance_id":"starter-cinder-1"},"revision":7,"next_instance_nonce":2}
	var migrated := ProfileRules.migrate(legacy)
	var again := ProfileRules.migrate(migrated)
	require(int(migrated.coins) == 333 and int(migrated.xp) == 4 and migrated.creatures.size() == 1, "schema migration preserves existing profile values")
	require(migrated.has("suit_blueprints") and migrated.has("core_blueprints") and migrated.has("support_cards") and migrated.has("decks") and migrated.has("active_deck_id") and migrated.has("shop"), "schema migration adds equipment progression fields")
	require(ProgressionRules.active_deck(migrated).size() == 15 and migrated == again, "migration gives one legal starter deck and is idempotent")
	var rotation_a := ProgressionRules.daily_shop(migrated, "2026-08-14")
	var rotation_b := ProgressionRules.daily_shop(migrated, "2026-08-14")
	require(bool(rotation_a.ok) and rotation_a.offers == rotation_b.offers and rotation_a.offers.size() == 9, "daily shop is explicit-day deterministic")
	require(not bool(ProgressionRules.daily_shop(migrated, "2026-02-30").ok), "shop rejects impossible calendar days")
	var offer_slots := {}
	for index in rotation_a.offers.size(): offer_slots["%d:%s" % [index, str(rotation_a.offers[index].get("type", ""))]] = true
	require(offer_slots.size() == rotation_a.offers.size(), "daily shop offer slots are stable")
	var poor := migrated.duplicate(true); poor.coins = 0
	var denied := ProgressionRules.purchase_creature_blueprint(poor, "mossmunk")
	require(not bool(denied.ok) and int(denied.profile.coins) == 0 and not "mossmunk" in denied.profile.blueprints, "insufficient purchase is atomic")
	var p := migrated.duplicate(true); p.coins = 500
	var blueprint := ProgressionRules.purchase_creature_blueprint(p, "mossmunk")
	require(bool(blueprint.ok) and int(blueprint.profile.coins) == 450 and "mossmunk" in blueprint.profile.blueprints, "blueprint purchase deducts listed catalog price once")
	var printed := ProgressionRules.print_creature(blueprint.profile, "mossmunk")
	require(bool(printed.ok) and printed.profile.creatures.size() == 2 and int(printed.profile.coins) == 430, "printing creates a catalog-valid creature atomically")
	var bad_team := ProgressionRules.save_team(printed.profile, ["starter-cinder-1","starter-cinder-1"])
	var good_team := ProgressionRules.save_team(printed.profile, ["starter-cinder-1", str(printed.payload.instance_id)])
	require(not bool(bad_team.ok) and bool(good_team.ok) and good_team.profile.team.size() == 2, "team validation enforces owned unique one-to-three instances")
	var suit_blueprint := EquipmentRules.learn_suit(good_team.profile, "standard")
	var suit_print := EquipmentRules.print_suit(suit_blueprint.profile, "standard")
	var equipped := EquipmentRules.equip_suit(suit_print.profile, "starter-cinder-1", str(suit_print.payload.suit_instance_id))
	var move_suit := EquipmentRules.equip_suit(equipped.profile, str(printed.payload.instance_id), str(suit_print.payload.suit_instance_id))
	require(bool(equipped.ok) and bool(move_suit.ok) and str(move_suit.profile.creatures[0].suit_instance_id).is_empty(), "a full suit moves atomically between one owner and another")
	var illegal_deck := ProgressionRules.save_deck(equipped.profile, ["raw_filament"])
	var legal_deck := ProgressionRules.save_deck(equipped.profile, ProgressionRules.STARTER_DECK)
	require(not bool(illegal_deck.ok) and bool(legal_deck.ok) and ProgressionRules.active_deck(legal_deck.profile).size() == 15, "deck saving requires exactly fifteen owned catalog cards")
	var battle := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2, ProgressionRules.active_deck(legal_deck.profile))
	require(battle.players[0].hand == ProgressionRules.STARTER_DECK.slice(0, 4), "battle consumes the saved active deck")
	var invalid_cards: Array = []
	for _i in 15: invalid_cards.append("not-a-card")
	var bad_battle := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2, invalid_cards)
	require(bad_battle.players[0].hand == BattleState.STARTER_LOADOUT.slice(0, 4), "battle safely falls back when a supplied deck is not legal")
	GameManager.profile = blueprint.profile.duplicate(true)
	var revision_before: int = int(GameManager.profile.get("revision", 0))
	var coins_before: int = int(GameManager.profile.coins)
	var events_before: int = SaveService.pending_events().size()
	var game_printed := GameManager.print_creature("mossmunk")
	require(game_printed and int(GameManager.profile.revision) == revision_before + 1 and int(GameManager.profile.coins) == coins_before - 20 and GameManager.profile.creatures.size() == blueprint.profile.creatures.size() + 1 and SaveService.pending_events().size() == events_before + 1, "accepted GameManager print commits one complete transition and journal event")
	if failures.is_empty(): print("PASS: progression migration, daily shop, atomic purchases, team, suits, deck, and battle deck")
	call_deferred("_finish")

func _finish() -> void:
	GameManager.profile = original_profile
	get_tree().quit(0 if failures.is_empty() else 1)
