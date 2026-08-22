extends Node
## Small deterministic authority gate suitable for local and CI headless runs.

const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const MANIFEST := preload("res://scripts/core/runtime_asset_manifest.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var completed := RULES.print_starter(RULES.choose_starter(RULES.new_profile(), "cinderpaw").get("profile", {}))
	var profile: Dictionary = completed.get("profile", {})
	var deck: Array = RULES.active_deck(profile)
	require(deck.size() == 40 and RULES.deck_reason(profile, deck).is_empty(), "starter deck is a legal 40-card v3 deck")

	var ring_deck: Array = []
	var rival_deck: Array = []
	for _copy in 40:
		ring_deck.append("filament_ring")
		rival_deck.append("cinderpaw")
	var state := STATE.create(ring_deck, rival_deck, 20260822)
	# Use a fixed seat here so the test directly exercises the Ring owner rather
	# than whichever seat the authoritative opening-seed selected.
	state.starting_seat = 0
	state.active_seat = 0
	var seat := 0
	require(state.player(seat).get("hand", []).has("filament_ring"), "opening hand contains a known Ring card: %s" % str(state.player(seat).get("hand", [])))
	var draw := BATTLE.apply_intent(state, seat, {"type":"advance_phase"})
	require(bool(draw.get("ok", false)) and state.phase == "main", "opening Draw advances to Main deterministically")
	var played := BATTLE.apply_intent(state, seat, {"type":"play_card","card_id":"filament_ring"})
	require(bool(played.get("ok", false)), "Filament Ring is playable in Main: %s" % str(played.get("error", "unknown")))
	require(bool(state.player(seat).get("filament_ring_active", false)), "Filament Ring creates a player battle effect")
	require((state.player(seat).get("queue", []) as Array).is_empty(), "Filament Ring does not use the print queue")
	for unit in state.player(seat).get("slots", []):
		if unit != null: require((unit.get("equipment", {}) as Dictionary).get("battle_effect", {}).is_empty(), "Filament Ring does not consume a creature equipment slot")
	var redacted := state.public_snapshot(0)
	require(not (redacted.players[1] as Dictionary).has("hand") and int((redacted.players[1] as Dictionary).get("hand_count", -1)) >= 0, "opponent hand remains redacted")
	for error in MANIFEST.validation_errors(): require(false, error)
	if failures.is_empty(): print("PASS: v3 starter, Ring effect, redaction, and dynamic asset manifest")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
