class_name V3Catalog
extends RefCounted
## Shared v3 non-creature card contract. Godot consumes this JSON directly and
## the TypeScript authority validates the same file in its test/runtime seam.

const PATH := "res://data/v3/catalog.json"
const TYPES := ["creature", "equipment", "filament", "spell", "trap", "upgrade"]
const ELEMENTS := ["Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane"]
const EFFECT_TARGETS := ["self", "foe", "field", "printer", "forge", "team", "any"]
static var _document_cache: Dictionary = {}
static var _cards_cache: Array = []
static var _index_cache: Dictionary = {}

static func document() -> Dictionary:
	if _document_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_document_cache = parsed if parsed is Dictionary else {}
	return _document_cache.duplicate(true)

static func validation_errors() -> Array[String]:
	var failures: Array[String] = []
	var source := document()
	if str(source.get("schema", "")) != "printforge.v3.catalog" or int(source.get("version", 0)) != 1:
		failures.append("v3 catalog schema/version is invalid.")
	var defaults: Dictionary = source.get("defaults", {}) if source.get("defaults", {}) is Dictionary else {}
	for key in ["print_turns", "creature_filament_cost", "equipment_filament_cost"]:
		if not defaults.get(key, {}) is Dictionary or (defaults.get(key, {}) as Dictionary).size() != 8: failures.append("v3 catalog defaults are invalid: %s" % key)
	var ids := {}
	var cards: Array = source.get("cards", []) if source.get("cards", []) is Array else []
	if cards.is_empty(): failures.append("v3 catalog has no cards.")
	for raw in cards:
		if not raw is Dictionary:
			failures.append("v3 catalog card is not an object.")
			continue
		var card: Dictionary = raw
		var id := str(card.get("id", ""))
		if id.is_empty() or ids.has(id): failures.append("v3 catalog ID is missing or duplicated: %s" % id)
		ids[id] = true
		if str(card.get("type", "")) not in TYPES: failures.append("v3 catalog has invalid type: %s" % id)
		if str(card.get("rarity", "")).is_empty() or int(card.get("filament_cost", -1)) < 0 or int(card.get("print_turns", -1)) < 0:
			failures.append("v3 catalog numeric fields are invalid: %s" % id)
		var kind := str(card.get("type", ""))
		if kind == "creature":
			if int(card.get("bend_score", 0)) <= 0 or int(card.get("hp", 0)) <= 0 or str(card.get("element", "")) not in ELEMENTS or int(card.get("ability_cooldown", -1)) < 0 or not card.has("ability_damage_bonus"):
				failures.append("v3 creature fields are invalid: %s" % id)
			if str(card.get("ability_trigger", "")) not in ["attack", "main", ""]: failures.append("v3 ability trigger is invalid: %s" % id)
			if not card.get("presentation", {}) is Dictionary: failures.append("v3 creature presentation is missing: %s" % id)
		if kind == "equipment" and str(card.get("equipment_slot", "")) not in ["armor", "gem", "battle_effect"]:
			failures.append("v3 equipment slot is invalid: %s" % id)
		var effects: Variant = card.get("effects", [])
		if effects is Array:
			for effect in effects:
				if not effect is Dictionary or str(effect.get("target", "")) not in EFFECT_TARGETS:
					failures.append("v3 effect target is invalid: %s" % id)
	return failures

static func cards() -> Array:
	if not _cards_cache.is_empty(): return _cards_cache.duplicate(true)
	var failures := validation_errors()
	if not failures.is_empty():
		push_error("; ".join(failures))
		return []
	var result: Array = []
	for raw in _document_cache.get("cards", []):
		var card: Dictionary = (raw as Dictionary).duplicate(true)
		card["cost"] = int(card.get("filament_cost", 0))
		card["print_ticks"] = int(card.get("print_turns", 0))
		if str(card.get("type", "")) == "creature":
			card["bend"] = int(card.get("bend_score", 0))
			card["ability_effects"] = card.get("effects", []).duplicate(true)
		result.append(card)
	_cards_cache = result.duplicate(true)
	for card in _cards_cache: _index_cache[str(card.get("id", ""))] = card.duplicate(true)
	return _cards_cache.duplicate(true)

static func card(id: String) -> Dictionary:
	if _index_cache.is_empty(): cards()
	return (_index_cache.get(id, {}) as Dictionary).duplicate(true)

static func non_creature_cards() -> Array:
	return cards().filter(func(card): return str(card.get("type", "")) != "creature")
