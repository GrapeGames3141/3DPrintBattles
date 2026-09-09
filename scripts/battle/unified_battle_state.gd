class_name UnifiedBattleState
extends RefCounted
## PrintForge Legends v3.2 immutable-snapshot battle state.

const RULES := preload("res://scripts/core/unified_rules.gd")
const PHASES := ["draw", "main", "print", "attack", "collect"]
const SNAPSHOT_SCHEMA := "v3.2"
const LEGACY_SCHEMA := "v3.1"
var schema := SNAPSHOT_SCHEMA
var revision := 0
var seed := 0
var starting_seat := 0
var active_seat := 0
var turn := 1
var phase := "draw"
var finished := false
var winner := -1
var pending: Dictionary = {}
var players: Array = []
var log: Array[String] = []
## Stable authority identities for print work; presentation serials remain separate.
var print_job_serial := 0

static func create(player_deck: Array, rival_deck: Array, match_seed: int = 7, player_upgrades: Array = [], rival_upgrades: Array = [], player_preprints: Array = [], rival_preprints: Array = [], player_workshop: Dictionary = {}, rival_workshop: Dictionary = {}) -> UnifiedBattleState:
	var state := UnifiedBattleState.new()
	state.seed = match_seed
	state.starting_seat = _next(match_seed) & 1
	state.active_seat = state.starting_seat
	state.players = [_player(player_deck, _next(match_seed + 11), player_upgrades, player_preprints, player_workshop), _player(rival_deck, _next(match_seed + 29), rival_upgrades, rival_preprints, rival_workshop)]
	state.log.append("Draw phase: %s begins." % ("Player 1" if state.active_seat == 0 else "Player 2"))
	return state

static func _player(deck_source: Array, seed_value: int, installed: Array, preprints: Array, workshop: Dictionary) -> Dictionary:
	var deck: Array = []
	for card_id in deck_source:
		if not RULES.card(str(card_id)).is_empty(): deck.append(str(card_id))
	_shuffle(deck, seed_value)
	var field: Array = [null, null, null]
	for index in mini(3, preprints.size()):
		var card_id := str(preprints[index])
		if not deck.has(card_id): continue
		var card := RULES.card(card_id)
		if str(card.get("type", "")) != "creature": continue
		deck.erase(card_id)
		field[index] = _unit(card, true)
	var hand: Array = []
	for _i in mini(5, deck.size()): hand.append(deck.pop_front())
	var workshop_upgrades: Array = workshop.get("workshop_upgrades", []) if workshop.get("workshop_upgrades", []) is Array else []
	var capacity := 400
	if "spool_capacity_i" in workshop_upgrades: capacity = 500
	if "spool_capacity_ii" in workshop_upgrades: capacity = 700
	return {"printer":{"hp":200,"max_hp":200}, "slots":field, "queue":[], "staging":[], "holding":[], "filament_ring_active":false, "filament":200, "filament_max":capacity, "trap":{}, "deck":deck, "hand":hand, "graveyard":[], "scrap":[], "installed_upgrades":installed.duplicate(), "upgrade_plays":0, "emergency_reprints":installed.count("emergency_reprint_upgrade"), "preprints":preprints.duplicate(), "draw_count":0, "played":[]}

static func _unit(card: Dictionary, preprinted := false) -> Dictionary:
	return {"card_id":str(card.get("id", "")), "name":str(card.get("name", "Print")), "rarity":str(card.get("rarity", "common")), "element":str(card.get("element", "Arcane")), "bend":int(card.get("bend_score", card.get("bend", 0))), "base_hp":int(card.get("hp", 1)), "hp":int(card.get("hp", 1)), "armor_hp":0, "mode":"defense" if preprinted else "attack", "ready":not preprinted, "preprinted":preprinted, "mode_changed":false, "attacked":false, "equipment":{"armor":{},"gem":{}}, "statuses":{}, "ability_cooldown":0, "equipment_cost":0}

static func _next(value: int) -> int:
	return int((value * 1103515245 + 12345) & 0x7fffffff)
static func _shuffle(values: Array, seed_value: int) -> void:
	var value := seed_value
	for index in range(values.size() - 1, 0, -1):
		value = _next(value); var other := value % (index + 1); var item = values[index]; values[index] = values[other]; values[other] = item
func player(seat: int) -> Dictionary:
	return players[seat] if seat >= 0 and seat < players.size() else {}
func serialize() -> Dictionary:
	return {"schema":schema,"revision":revision,"seed":seed,"starting_seat":starting_seat,"active_seat":active_seat,"turn":turn,"phase":phase,"finished":finished,"winner":winner,"pending":pending.duplicate(true),"players":players.duplicate(true),"log":log.duplicate(),"print_job_serial":print_job_serial}

static func recover_snapshot(snapshot: Dictionary) -> Dictionary:
	## Work only on a deep candidate: failed validation leaves persisted bytes intact.
	if snapshot.is_empty(): return {"ok":false, "error":"Battle snapshot is empty."}
	var candidate := snapshot.duplicate(true)
	var source_schema := str(candidate.get("schema", ""))
	if source_schema not in [LEGACY_SCHEMA, SNAPSHOT_SCHEMA]: return {"ok":false, "error":"Unsupported battle snapshot schema."}
	if str(candidate.get("phase", "")) not in PHASES or not _integer(candidate.get("revision", null)) or int(candidate.get("revision", -1)) < 0 or not _integer(candidate.get("seed", null)) or not _seat(candidate.get("starting_seat", null)) or not _seat(candidate.get("active_seat", null)) or not _integer(candidate.get("turn", null)) or int(candidate.get("turn", 0)) < 1 or not _integer(candidate.get("winner", null)) or int(candidate.get("winner", -2)) < -1 or int(candidate.get("winner", 2)) > 1: return {"ok":false, "error":"Battle snapshot header is malformed."}
	var pending = candidate.get("pending", {})
	if not (pending is Dictionary): return {"ok":false, "error":"Battle snapshot pending decision is malformed."}
	if not pending.is_empty() and str(pending.get("kind", "")) not in ["place", "attach"]: return {"ok":false, "error":"Battle snapshot pending decision is unsupported."}
	if source_schema == SNAPSHOT_SCHEMA and str(pending.get("kind", "")) == "place": return {"ok":false, "error":"Legacy placement decisions cannot appear in a v3.2 snapshot."}
	var source_players = candidate.get("players", null)
	if not (source_players is Array) or source_players.size() != 2: return {"ok":false, "error":"Battle snapshot players are malformed."}
	var source_log = candidate.get("log", null)
	if not (source_log is Array): return {"ok":false, "error":"Battle snapshot log is malformed."}
	for entry in source_log:
		if not (entry is String): return {"ok":false, "error":"Battle snapshot log entry is malformed."}
	if not _integer(candidate.get("print_job_serial", 0)) or int(candidate.get("print_job_serial", 0)) < 0: return {"ok":false, "error":"Battle snapshot print serial is malformed."}
	var adapted := source_schema == LEGACY_SCHEMA
	var seen_jobs := {}
	var maximum_job_serial := 0
	for seat in 2:
		var player = source_players[seat]
		if not (player is Dictionary): return {"ok":false, "error":"Battle snapshot player is malformed."}
		var printer = player.get("printer", null)
		var installed = player.get("installed_upgrades", [])
		var slots = player.get("slots", [])
		var staging = player.get("staging", [])
		var queue = player.get("queue", [])
		var holding = player.get("holding", [])
		var trap = player.get("trap", {})
		if not (printer is Dictionary) or not (installed is Array) or not (slots is Array) or slots.size() != 3 or not (staging is Array) or not (queue is Array) or not (holding is Array) or not (trap is Dictionary) or not _card_array(player.get("hand", null)) or not _card_array(player.get("deck", null)) or not _card_array(player.get("graveyard", null)) or not _card_array(player.get("played", null)) or not (player.get("scrap", null) is Array) or not (player.get("preprints", null) is Array): return {"ok":false, "error":"Battle snapshot player containers are malformed."}
		for installed_id in installed:
			if not (installed_id is String) or RULES.card(str(installed_id)).is_empty(): return {"ok":false, "error":"Battle snapshot upgrade is malformed."}
		if not trap.is_empty() and (str(RULES.card(str(trap.get("card_id", ""))).get("type", "")) != "trap"): return {"ok":false, "error":"Battle snapshot trap is malformed."}
		for scrap in player.get("scrap", []):
			if not (scrap is Dictionary) or not _integer((scrap as Dictionary).get("cost", null)) or int((scrap as Dictionary).get("cost", -1)) < 0: return {"ok":false, "error":"Battle snapshot scrap is malformed."}
		for unit in slots:
			if unit == null: continue
			if not _unit_valid(unit): return {"ok":false, "error":"Battle snapshot field unit is malformed."}
			var field_job_id := str((unit as Dictionary).get("job_id", ""))
			if not field_job_id.is_empty():
				if not _register_job(seen_jobs, field_job_id): return {"ok":false, "error":"Battle snapshot print job identity is duplicated."}
				maximum_job_serial = maxi(maximum_job_serial, _job_sequence(field_job_id))
		for key in ["filament", "filament_max", "upgrade_plays", "emergency_reprints", "draw_count"]:
			if not _integer(player.get(key, null)) or int(player.get(key, -1)) < 0: return {"ok":false, "error":"Battle snapshot player numeric value is malformed."}
		var chassis_count: int = installed.count("reinforced_chassis")
		if chassis_count > 5: return {"ok":false, "error":"Battle snapshot chassis count is malformed."}
		if not _integer(printer.get("max_hp", null)) or not _integer(printer.get("hp", null)): return {"ok":false, "error":"Battle snapshot printer health is malformed."}
		var old_max: int = int(printer.get("max_hp", -1))
		var old_hp: int = int(printer.get("hp", -1))
		if old_max <= 0 or old_hp < 0 or old_hp > old_max: return {"ok":false, "error":"Battle snapshot printer health is malformed."}
		if source_schema == LEGACY_SCHEMA:
			if old_max != 2000 + 500 * chassis_count: return {"ok":false, "error":"Unsupported legacy printer scale."}
			printer["max_hp"] = ceili(float(old_max) / 10.0)
			printer["hp"] = 0 if old_hp == 0 else clampi(ceili(float(old_hp) / 10.0), 1, int(printer["max_hp"]))
		elif old_max != 200 + 50 * chassis_count: return {"ok":false, "error":"Unsupported printer scale."}
		for index in queue.size():
			var job = queue[index]
			if not (job is Dictionary) or str(job.get("card_id", "")).is_empty() or not _integer(job.get("remaining", null)) or int(job.get("remaining", -1)) < 0 or not _integer(job.get("cost", null)) or int(job.get("cost", -1)) < 0: return {"ok":false, "error":"Battle snapshot queued print is malformed."}
			var card := RULES.card(str(job.get("card_id", "")))
			if card.is_empty(): return {"ok":false, "error":"Battle snapshot queued print is unknown."}
			if source_schema == LEGACY_SCHEMA and str(card.get("type", "")) == "equipment" and str(card.get("equipment_slot", "")) != "battle_effect": job["target"] = -1
			if str(job.get("job_id", "")).is_empty(): job["job_id"] = "legacy-%d-%d" % [seat, index]
			if not _register_job(seen_jobs, str(job.get("job_id", ""))): return {"ok":false, "error":"Battle snapshot print job identity is duplicated."}
			maximum_job_serial = maxi(maximum_job_serial, _job_sequence(str(job.get("job_id", ""))))
		for index in holding.size():
			var held = holding[index]
			if not (held is Dictionary) or str(held.get("card_id", "")).is_empty(): return {"ok":false, "error":"Battle snapshot held print is malformed."}
			var held_card := RULES.card(str(held.get("card_id", "")))
			if held_card.is_empty() or str(held_card.get("type", "")) != "equipment": return {"ok":false, "error":"Battle snapshot held print is unknown."}
			if source_schema == LEGACY_SCHEMA: held["target"] = -1
			if str(held.get("job_id", "")).is_empty(): held["job_id"] = "legacy-held-%d-%d" % [seat, index]
			if not _register_job(seen_jobs, str(held.get("job_id", ""))): return {"ok":false, "error":"Battle snapshot print job identity is duplicated."}
			maximum_job_serial = maxi(maximum_job_serial, _job_sequence(str(held.get("job_id", ""))))
		for index in staging.size():
			var staged = staging[index]
			if not (staged is Dictionary): return {"ok":false, "error":"Battle snapshot staged print is malformed."}
			var staged_unit: Dictionary = staged.get("unit", {}) if staged.has("unit") and staged.get("unit", {}) is Dictionary else staged
			if not _unit_valid(staged_unit): return {"ok":false, "error":"Battle snapshot staged print is malformed."}
			var staged_job_id := str(staged.get("job_id", staged_unit.get("job_id", "")))
			if staged_job_id.is_empty(): staged_job_id = "legacy-staged-%d-%d" % [seat, index]
			staged_unit["job_id"] = staged_job_id
			if staged.has("unit"): staged["job_id"] = staged_job_id
			if not _register_job(seen_jobs, staged_job_id): return {"ok":false, "error":"Battle snapshot print job identity is duplicated."}
			maximum_job_serial = maxi(maximum_job_serial, _job_sequence(staged_job_id))
	if source_schema == LEGACY_SCHEMA and str(pending.get("kind", "")) == "place":
		var pending_seat := int(pending.get("seat", -1))
		var pending_unit = pending.get("unit", null)
		if pending_seat < 0 or pending_seat > 1 or not _unit_valid(pending_unit): return {"ok":false, "error":"Legacy placement decision is malformed."}
		var pending_player: Dictionary = source_players[pending_seat]
		var staged_source: Dictionary = {}
		if bool(pending.get("from_staging", false)):
			if pending_player.get("staging", []).is_empty() or not _same_staged_unit(pending_player.get("staging", [])[0], pending_unit): return {"ok":false, "error":"Legacy placement staging source is malformed."}
			var source_wrapper: Dictionary = pending_player.get("staging", [])[0]
			staged_source = source_wrapper.get("unit", source_wrapper) if source_wrapper.get("unit", source_wrapper) is Dictionary else {}
		var open_slot := _first_open_slot(pending_player.get("slots", []))
		# The staged object owns the job identity. Pending place was merely an old
		# UI choice, so migration must not replace it with a second copy.
		var placement_source: Dictionary = staged_source if not staged_source.is_empty() else pending_unit as Dictionary
		var placed_unit: Dictionary = placement_source.duplicate(true)
		if bool(pending.get("from_staging", false)) and not pending_player.get("staging", []).is_empty(): pending_player["staging"].pop_front()
		placed_unit["mode"] = "attack"; placed_unit["ready"] = true
		if str(placed_unit.get("job_id", "")).is_empty(): placed_unit["job_id"] = "legacy-pending-%d" % pending_seat
		if open_slot >= 0: pending_player["slots"][open_slot] = placed_unit
		else: pending_player["staging"].append({"unit":placed_unit, "job_id":str(placed_unit.get("job_id", ""))})
		candidate["pending"] = {}
	elif str(pending.get("kind", "")) == "attach":
		var attach_seat := int(pending.get("seat", -1))
		var holding_index := int(pending.get("holding_index", -1))
		if not _seat(pending.get("seat", null)) or not _integer(pending.get("holding_index", null)) or attach_seat < 0 or attach_seat > 1 or holding_index < 0 or holding_index >= (source_players[attach_seat] as Dictionary).get("holding", []).size(): return {"ok":false, "error":"Battle snapshot fitting decision is malformed."}
		var pending_held: Dictionary = (source_players[attach_seat] as Dictionary).get("holding", [])[holding_index]
		if str(pending.get("card_id", "")) != str(pending_held.get("card_id", "")): return {"ok":false, "error":"Battle snapshot fitting card does not match held work."}
		pending["job_id"] = str(pending_held.get("job_id", ""))
	if source_schema == SNAPSHOT_SCHEMA and int(candidate.get("print_job_serial", 0)) < maximum_job_serial: return {"ok":false, "error":"Battle snapshot print serial would reuse a job identity."}
	candidate["schema"] = SNAPSHOT_SCHEMA
	candidate["print_job_serial"] = maxi(int(candidate.get("print_job_serial", 0)), maximum_job_serial)
	return {"ok":true, "snapshot":candidate, "adapted":adapted}

static func _first_open_slot(slots: Array) -> int:
	for slot in slots.size():
		if slots[slot] == null: return slot
	return -1

static func _integer(value) -> bool:
	if typeof(value) == TYPE_INT: return true
	if typeof(value) != TYPE_FLOAT or not is_finite(float(value)): return false
	return float(int(value)) == float(value)

static func _seat(value) -> bool:
	return _integer(value) and int(value) >= 0 and int(value) <= 1

static func _card_array(values) -> bool:
	if not (values is Array): return false
	for card_id in values:
		if not (card_id is String) or RULES.card(str(card_id)).is_empty(): return false
	return true

static func _unit_valid(value) -> bool:
	if not (value is Dictionary): return false
	var unit: Dictionary = value
	if str(RULES.card(str(unit.get("card_id", ""))).get("type", "")) != "creature" or not (unit.get("equipment", null) is Dictionary) or not (unit.get("statuses", null) is Dictionary): return false
	for key in ["bend", "base_hp", "hp", "armor_hp", "ability_cooldown", "equipment_cost"]:
		if not _integer(unit.get(key, null)) or int(unit.get(key, -1)) < 0: return false
	if str(unit.get("mode", "")) not in ["attack", "defense"] or typeof(unit.get("ready", null)) != TYPE_BOOL: return false
	if unit.has("job_id") and not (unit.get("job_id") is String): return false
	for slot in (unit.get("equipment", {}) as Dictionary):
		var equipped = (unit.get("equipment", {}) as Dictionary).get(slot, {})
		if not (slot is String) or not (equipped is Dictionary): return false
		if equipped.is_empty(): continue
		var equipment_card := RULES.card(str(equipped.get("card_id", "")))
		if str(equipment_card.get("type", "")) != "equipment" or not _integer(equipped.get("attack_bonus", null)) or not _integer(equipped.get("super_effective_bps", null)) or typeof(equipped.get("used", null)) != TYPE_BOOL: return false
	for status in (unit.get("statuses", {}) as Dictionary):
		var duration = (unit.get("statuses", {}) as Dictionary).get(status)
		if not (status is String) or not _integer(duration) or int(duration) < 0: return false
	return true

static func _register_job(seen: Dictionary, job_id: String) -> bool:
	if job_id.is_empty() or seen.has(job_id): return false
	seen[job_id] = true
	return true

static func _job_sequence(job_id: String) -> int:
	if not job_id.begins_with("job-"): return 0
	var tail := job_id.trim_prefix("job-")
	if not tail.is_valid_int(): return 0
	return maxi(0, int(tail))

static func _same_staged_unit(staged, pending_unit) -> bool:
	if not (staged is Dictionary) or not (pending_unit is Dictionary): return false
	var staged_unit: Dictionary = staged.get("unit", staged) if (staged as Dictionary).get("unit", staged) is Dictionary else {}
	if str(staged_unit.get("card_id", "")) != str((pending_unit as Dictionary).get("card_id", "")) or int(staged_unit.get("hp", -1)) != int((pending_unit as Dictionary).get("hp", -2)): return false
	var pending_job := str((pending_unit as Dictionary).get("job_id", ""))
	return pending_job.is_empty() or pending_job == str(staged_unit.get("job_id", (staged as Dictionary).get("job_id", "")))

static func from_snapshot(snapshot: Dictionary) -> UnifiedBattleState:
	var recovery := recover_snapshot(snapshot)
	if not bool(recovery.get("ok", false)): return null
	var source: Dictionary = recovery.get("snapshot", {})
	var state := UnifiedBattleState.new()
	state.schema = str(source.get("schema", state.schema))
	state.revision = int(source.get("revision", 0))
	state.seed = int(source.get("seed", 0))
	state.starting_seat = int(source.get("starting_seat", 0))
	state.active_seat = int(source.get("active_seat", 0))
	state.turn = int(source.get("turn", 1))
	state.phase = str(source.get("phase", "draw"))
	state.finished = bool(source.get("finished", false))
	state.winner = int(source.get("winner", -1))
	state.pending = (source.get("pending", {}) as Dictionary).duplicate(true)
	state.players = (source.get("players", []) as Array).duplicate(true)
	state.log = (source.get("log", []) as Array).duplicate()
	state.print_job_serial = int(source.get("print_job_serial", 0))
	return state
func public_snapshot(viewer_seat: int = -1) -> Dictionary:
	var snapshot := serialize()
	for seat in 2:
		if seat != viewer_seat:
			(snapshot.players[seat] as Dictionary).erase("hand")
			(snapshot.players[seat] as Dictionary).erase("deck")
			(snapshot.players[seat] as Dictionary)["hand_count"] = int(player(seat).hand.size())
			if not (snapshot.players[seat] as Dictionary).get("trap", {}).is_empty(): (snapshot.players[seat] as Dictionary)["trap"] = {"set":true}
	return snapshot
