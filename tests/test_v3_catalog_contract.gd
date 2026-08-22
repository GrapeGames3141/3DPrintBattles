extends Node

const CATALOG := preload("res://scripts/core/v3_catalog.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const LEGACY_CATALOG := preload("res://scripts/core/catalog.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	require(CATALOG.validation_errors().is_empty(), "Shared v3 JSON catalog validates in Godot.")
	var document := CATALOG.document()
	require(str(document.get("schema", "")) == "printforge.v3.catalog", "Catalog schema is v3.")
	var source_cards: Array = document.get("cards", [])
	require(source_cards.size() == 57, "Shared v3 catalog contains all 57 authored cards.")
	require(source_cards.filter(func(card): return str(card.get("type", "")) == "creature").size() == 24, "Shared v3 catalog contains all 24 creatures.")
	for raw in source_cards:
		var source: Dictionary = raw
		var runtime := RULES.card(str(source.id))
		require(not runtime.is_empty(), "Godot runtime loads %s from shared catalog." % source.id)
		require(str(runtime.get("type", "")) == str(source.type), "%s type matches JSON." % source.id)
		require(str(runtime.get("rarity", "")) == str(source.rarity), "%s rarity matches JSON." % source.id)
		require(int(runtime.get("filament_cost", -1)) == int(source.filament_cost), "%s filament cost matches JSON." % source.id)
		require(int(runtime.get("print_turns", -1)) == int(source.print_turns), "%s print turns match JSON." % source.id)
	var ring := RULES.card("filament_ring")
	require(str(ring.get("equipment_slot", "")) == "battle_effect" and int(ring.get("print_turns", -1)) == 0, "Ring remains a slotless immediate battle effect.")
	var cinderpaw := RULES.card("cinderpaw")
	require(int(cinderpaw.get("bend_score", 0)) == 18 and int(cinderpaw.get("hp", 0)) == 34 and str(cinderpaw.get("element", "")) == "Fire", "Creature combat fields come from the shared v3 catalog.")
	cinderpaw["hp"] = 1
	require(int(RULES.card("cinderpaw").get("hp", 0)) == 34, "Catalog lookup returns a defensive duplicate.")
	for legacy in LEGACY_CATALOG.CREATURES:
		var migrated := RULES.card(str(legacy.id))
		var signature: Dictionary = legacy.get("signature", {})
		require(int(migrated.get("ability_damage_bonus", -1)) == int(signature.get("damage_bonus", -2)), "%s ability damage bonus matches prior catalog." % legacy.id)
		var migrated_effects: Array = migrated.get("ability_effects", [])
		var legacy_effects: Array = signature.get("effects", [])
		require(migrated_effects.size() == legacy_effects.size(), "%s keeps the same ability effect count." % legacy.id)
		for index in mini(migrated_effects.size(), legacy_effects.size()):
			var actual: Dictionary = migrated_effects[index]
			var expected: Dictionary = legacy_effects[index]
			require(str(actual.get("effect", "")) == str(expected.get("effect", "")) and str(actual.get("target", "")) == str(expected.get("target", "")) and int(actual.get("amount", -1)) == int(expected.get("amount", -2)), "%s ability effect %d matches prior catalog." % [legacy.id, index])
	var stoneback := RULES.card("stoneback")
	var miragefox := RULES.card("miragefox")
	require(stoneback.ability_effects.size() == 2 and str(stoneback.ability_effects[1].effect) == "cleanse", "Stoneback keeps its secondary cleanse.")
	require(miragefox.ability_effects.size() == 2 and str(miragefox.ability_effects[1].effect) == "shield", "Miragefox keeps its secondary shield.")
	if failures.is_empty(): print("PASS: Godot consumes the shared v3 catalog contract")
	get_tree().quit(0 if failures.is_empty() else 1)
