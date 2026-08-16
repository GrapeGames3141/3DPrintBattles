extends Node

const FACTORY := preload("res://scripts/core/solo_battle_factory.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var selected: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").get("profile", {})
	selected["active_deck_id"] = "missing-deck"
	selected["decks"] = []
	# The Team Builder loadout wins over fallback ordering even when profile
	# creatures are in another order.
	var printed := ProgressionRules.purchase_creature_blueprint(selected, "mossmunk")
	printed = ProgressionRules.print_creature(printed.get("profile", {}), "mossmunk")
	var authored: Dictionary = printed.get("profile", {})
	var starter_instance: String = str(authored.get("creatures", [])[0].get("instance_id", ""))
	var moss_instance: String = str(authored.get("creatures", [])[1].get("instance_id", ""))
	authored["team"] = [moss_instance, starter_instance]
	var authored_before: Dictionary = authored.duplicate(true)
	var current := FACTORY.player_loadout(authored)
	require(current.get("team", []) == ProfileRules.team_loadout(authored) and not bool(current.get("temporary_repair", true)), "authoritative Team Builder loadout is returned unchanged before fallback ordering")
	require(authored == authored_before, "authoritative team lookup does not mutate profile input")
	# Phone-like raw records can retain a catalog species alias but no instance ID.
	var legacy: Dictionary = selected.duplicate(true)
	legacy["creatures"] = [{"id":"cinderpaw"}]
	legacy["team"] = [{"species":"cinderpaw"}]
	var before: Dictionary = legacy.duplicate(true)
	var repaired := FACTORY.create(legacy, ["mossmunk"], 99, 99, 42)
	require(bool(repaired.get("ok", false)), "legacy raw id/species records launch a solo match from deterministic owned fallback")
	require(bool(repaired.get("temporary_repair", false)), "legacy raw team reference reports a temporary repair instead of silently persisting one")
	var state := repaired.get("battle", null) as BattleState
	require(state != null and str(state.active_unit(0).get("id", "")) == "cinderpaw", "fallback unit is catalog-valid Cinderpaw")
	require(state != null and state.players[0].hand.size() == 4 and state.players[0].deck.size() == 11, "invalid saved deck uses canonical legal starter loadout")
	require(legacy == before, "solo setup does not persist or mutate a repaired temporary lineup")
	var invalid := legacy.duplicate(true)
	invalid["creatures"] = []
	invalid["team"] = ["missing-print"]
	var rejected := FACTORY.create(invalid, ["mossmunk"], 3, 3, 42)
	require(not bool(rejected.get("ok", false)) and str(rejected.get("error", "")).contains("No catalog-valid owned print"), "no-owned profile receives exact actionable solo setup error")
	require(invalid.get("team", []) == ["missing-print"], "invalid setup refusal has no profile mutation")
	if failures.is_empty(): print("PASS: Solo battle factory temporary repair, deck fallback, and no-owned refusal")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
