class_name TeamMatchLedger
extends RefCounted

## Strict in-memory M2 envelope.  File I/O intentionally lives outside this slice.

const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const CollectionProjection := preload("res://scripts/team_collection/team_collection_projection.gd")

const VERSION := 1
const KEYS := ["version", "next_match_sequence", "current", "starts", "rewards", "coins", "xp"]
const START_KEYS := ["request_id", "expected_sequence", "collection_revision", "fingerprint", "seed", "match_id", "sequence", "tutorial_opening", "player_priority", "player_kit", "rival_priority", "rival_kit"]
const REWARD_KEYS := ["match_id", "result", "receipt_id", "revision", "cycle", "coins", "xp"]
const REWARDS := {
	"Win": {"coins": 30, "xp": 40},
	"Loss": {"coins": 10, "xp": 20},
	"Draw": {"coins": 20, "xp": 30},
}


static func empty() -> Dictionary:
	return {
		"version": VERSION,
		"next_match_sequence": 1,
		"current": {},
		"starts": {},
		"rewards": {},
		"coins": 0,
		"xp": 0,
	}


static func normalize(value: Variant, exists: bool) -> Dictionary:
	if not exists:
		return {"ok": true, "ledger": empty()}
	var canonical := _canonical(value)
	if not bool(canonical.get("ok", false)) or not canonical.value is Dictionary:
		return _failure("Team-match ledger is not canonical JSON.")
	var ledger: Dictionary = canonical.value
	if not _has_exact_keys(ledger, KEYS) or not _safe_integer(ledger.get("version", null)) or int(ledger.version) != VERSION:
		return _failure("Team-match ledger schema is invalid.")
	for key in ["next_match_sequence", "coins", "xp"]:
		if not _safe_integer(ledger[key]) or int(ledger[key]) < 0:
			return _failure("Team-match ledger numeric field is invalid.")
	if not ledger.current is Dictionary or not ledger.starts is Dictionary or not ledger.rewards is Dictionary:
		return _failure("Team-match ledger containers are invalid.")
	var starts_by_sequence := {}
	var starts_by_match := {}
	for request_id in ledger.starts.keys():
		if not _valid_id(request_id) or not ledger.starts[request_id] is Dictionary:
			return _failure("Team-match Start history identity is invalid.")
		var start: Dictionary = ledger.starts[request_id]
		if not _has_exact_keys(start, START_KEYS) or str(start.request_id) != request_id:
			return _failure("Team-match Start history schema is invalid.")
		if not _valid_start(start) or starts_by_sequence.has(int(start.sequence)) or starts_by_match.has(str(start.match_id)):
			return _failure("Team-match Start history is invalid.")
		starts_by_sequence[int(start.sequence)] = start
		starts_by_match[str(start.match_id)] = start
	if int(ledger.next_match_sequence) != ledger.starts.size() + 1:
		return _failure("Team-match sequence is not contiguous.")
	if ledger.current.is_empty() and (not ledger.starts.is_empty() or not ledger.rewards.is_empty()):
		return _failure("Historical team matches require a current match reference.")
	for sequence in range(1, int(ledger.next_match_sequence)):
		if not starts_by_sequence.has(sequence):
			return _failure("Team-match Start sequence has a gap.")
	if not ledger.current.is_empty():
		if ledger.starts.is_empty() or not starts_by_sequence.has(int(ledger.next_match_sequence) - 1):
			return _failure("Current match requires a latest Start record.")
		if str(ledger.current.get("match_id", "")) != str(starts_by_sequence[int(ledger.next_match_sequence) - 1].match_id):
			return _failure("Current match must be the latest Start sequence.")
	var coin_total := 0
	var xp_total := 0
	for match_id in ledger.rewards.keys():
		if not ledger.rewards[match_id] is Dictionary:
			return _failure("Team-match reward record is invalid.")
		var reward: Dictionary = ledger.rewards[match_id]
		if not _has_exact_keys(reward, REWARD_KEYS) or str(reward.match_id) != match_id or not _valid_reward(reward):
			return _failure("Team-match reward schema is invalid.")
		if not starts_by_match.has(match_id):
			return _failure("Team-match reward refers to an unknown match.")
		var start: Dictionary = starts_by_match[match_id]
		if str(reward.receipt_id) != "terminal:%d:%d" % [int(start.seed), int(reward.cycle)] or int(reward.revision) <= 0 or int(reward.cycle) != int(reward.revision):
			return _failure("Team-match reward does not bind its terminal receipt.")
		coin_total += int(reward.coins)
		xp_total += int(reward.xp)
	if coin_total != int(ledger.coins) or xp_total != int(ledger.xp):
		return _failure("Team-match wallet totals do not match rewards.")
	for sequence in range(1, int(ledger.next_match_sequence) - 1):
		var prior: Dictionary = starts_by_sequence[sequence]
		if not ledger.rewards.has(str(prior.match_id)):
			return _failure("Earlier match is missing its settled reward.")
	if not ledger.current.is_empty():
		if not ledger.current.has("match_id") or not _valid_id(str(ledger.current.match_id)):
			return _failure("Current Coordinator snapshot identity is invalid.")
		var current_id := str(ledger.current.get("match_id", ""))
		if not starts_by_match.has(current_id):
			return _failure("Current match is not in Start history.")
	return {"ok": true, "ledger": ledger.duplicate(true)}


static func reward_for_terminal(match_id: String, authority: Dictionary) -> Dictionary:
	if not authority is Dictionary or not authority.terminal_receipt is Dictionary:
		return _failure("Terminal authority is invalid.")
	var result := str(authority.get("result", ""))
	if not REWARDS.has(result):
		return _failure("Terminal result is invalid.")
	var receipt: Dictionary = authority.terminal_receipt
	if str(receipt.get("result", "")) != result or not _valid_terminal_receipt_id(str(receipt.get("id", ""))):
		return _failure("Terminal receipt is invalid.")
	var delta: Dictionary = REWARDS[result]
	return {"ok": true, "reward": {
		"match_id": match_id,
		"result": result,
		"receipt_id": str(receipt.id),
		"revision": int(authority.revision),
		"cycle": int(authority.cycle),
		"coins": int(delta.coins),
		"xp": int(delta.xp),
	}}


static func _valid_start(value: Dictionary) -> bool:
	if not value.request_id is String or not value.match_id is String or not value.fingerprint is String or not _valid_id(str(value.request_id)) or not _valid_id(str(value.match_id)):
		return false
	for key in ["expected_sequence", "collection_revision", "seed", "sequence"]:
		if not _safe_integer(value[key]) or int(value[key]) < 0:
			return false
	if int(value.sequence) < 1 or int(value.expected_sequence) != int(value.sequence) or str(value.match_id) != "tp-match-%d" % int(value.sequence):
		return false
	if int(value.seed) > State.MAX_SEED or not _valid_hash(str(value.fingerprint)) or not value.tutorial_opening is bool or bool(value.tutorial_opening) != (int(value.sequence) == 1):
		return false
	for key in ["player_priority", "rival_priority", "player_kit", "rival_kit"]:
		if not value[key] is Array:
			return false
	var rival_starter: String = CollectionProjection.STARTERS[int(value.seed) % 3]
	if value.rival_priority != [rival_starter] + CollectionProjection.GUARANTEES[rival_starter] or value.rival_kit != Data.recommended_kit():
		return false
	return bool(State.create_production(value.player_priority, value.rival_priority, value.player_kit, value.rival_kit, int(value.seed), bool(value.tutorial_opening)).get("ok", false))


static func _valid_reward(value: Dictionary) -> bool:
	if not _valid_id(str(value.match_id)) or not _valid_terminal_receipt_id(str(value.receipt_id)) or not REWARDS.has(str(value.result)):
		return false
	for key in ["revision", "cycle", "coins", "xp"]:
		if not _safe_integer(value[key]) or int(value[key]) < 0:
			return false
	var expected: Dictionary = REWARDS[str(value.result)]
	return int(value.coins) == int(expected.coins) and int(value.xp) == int(expected.xp)


static func _canonical(value: Variant) -> Dictionary:
	if value == null or value is bool or value is String:
		return {"ok": true, "value": value}
	if _safe_integer(value):
		return {"ok": true, "value": int(value)}
	if value is Array:
		var output := []
		for item in value:
			var item_result := _canonical(item)
			if not bool(item_result.get("ok", false)):
				return item_result
			output.append(item_result.value)
		return {"ok": true, "value": output}
	if value is Dictionary:
		for key in value.keys():
			if not key is String:
				return _failure("Team-match JSON key is invalid.")
		var keys: Array = value.keys()
		keys.sort()
		var output := {}
		for key in keys:
			var item_result := _canonical(value[key])
			if not bool(item_result.get("ok", false)):
				return item_result
			output[key] = item_result.value
		return {"ok": true, "value": output}
	return _failure("Team-match value is not JSON-compatible.")


static func _safe_integer(value: Variant) -> bool:
	if value is bool:
		return false
	if value is int:
		return value >= -State.MAX_SAFE_JSON_INTEGER and value <= State.MAX_SAFE_JSON_INTEGER
	return value is float and is_finite(value) and floor(value) == value and value >= -State.MAX_SAFE_JSON_INTEGER and value <= State.MAX_SAFE_JSON_INTEGER


static func _valid_hash(value: String) -> bool:
	return value.length() == 64 and value.is_valid_hex_number()


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 96:
		return false
	for index in value.length():
		var character := value.substr(index, 1)
		if not (character.to_lower() >= "a" and character.to_lower() <= "z") and not (character >= "0" and character <= "9") and character not in ["_", "-"]:
			return false
	return true


static func _valid_terminal_receipt_id(value: String) -> bool:
	var parts := value.split(":", false)
	if parts.size() != 3 or parts[0] != "terminal":
		return false
	for index in [1, 2]:
		if not parts[index].is_valid_int() or int(parts[index]) < 0:
			return false
	return true


static func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in value.keys():
		if key not in expected:
			return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
