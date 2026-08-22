extends Node

const MANIFEST := preload("res://scripts/core/runtime_asset_manifest.gd")
const RING_ART := "res://assets/cards/v3/filament_ring_art_v1.png"

func _ready() -> void:
	var failures := MANIFEST.validation_errors()
	for path in ["res://assets/cards/support_cards_resources_landscape_v2.png", "res://assets/cards/support_cards_defense_landscape_v2.png", "res://assets/cards/support_cards_offense_landscape_v2.png", "res://assets/cards/support_cards_utility_landscape_v2.png", "res://assets/cards/support_card_back_source_v1.png"]:
		if not ResourceLoader.exists(path): failures.append("SupportCardView hard-coded art path is missing: %s" % path)
	var fronts: Array = MANIFEST.load_manifest().get("groups", {}).get("card_fronts", [])
	if not fronts.has(RING_ART) or not FileAccess.file_exists(RING_ART): failures.append("Filament Ring direct front art is missing from the runtime manifest.")
	for message in failures: push_error(message)
	if failures.is_empty(): print("PASS: runtime asset manifest resolves every dynamic v3 resource")
	call_deferred("finish", failures.is_empty())

func finish(ok: bool) -> void:
	get_tree().quit(0 if ok else 1)
