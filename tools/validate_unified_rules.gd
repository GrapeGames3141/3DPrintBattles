extends SceneTree
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
func _init() -> void:
	var profile := RULES.ensure({"schema_version":Catalog.SCHEMA_VERSION,"catalog_version":Catalog.CATALOG_VERSION,"coins":180,"xp":0,"creatures":[],"support_cards":{},"decks":[],"onboarding":{"state":"choose_starter","starter_id":"","starter_instance_id":""}})
	var chosen := RULES.choose_starter(profile, "cinderpaw")
	if not bool(chosen.get("ok", false)): _fail("starter")
	var printed := RULES.print_starter(chosen.profile)
	var cards: Array = printed.profile.decks[0].cards
	if not RULES.deck_reason(printed.profile, cards).is_empty(): _fail("deck")
	var xp_profile: Dictionary = printed.profile.duplicate(true)
	xp_profile.forge_xp = 500
	var nodes := RULES.apply_printer_nodes(xp_profile, ["spool_5", "spool_7"])
	if int(RULES.respec_printer(nodes.profile).profile.forge_xp) != 500: _fail("printer refund")
	var state := STATE.create(cards, cards, 1)
	state.players[0].hand = ["swiftweave_suit"]
	var before := state.serialize()
	if bool(BATTLE.apply_intent(state, 0, {"type":"play_card","card_id":"swiftweave_suit","target":-1}).get("ok", false)) or state.serialize() != before: _fail("atomic equipment")
	print("PASS: deterministic unified authority validation")
	quit(0)
func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
