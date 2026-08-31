class_name RuntimeAssetManifest
extends RefCounted
## Explicit allow-list for resources loaded from constructed paths.  Static
## analysis can use this instead of mistaking dynamic v3 artwork for dead art.

const PATH := "res://assets/runtime_asset_manifest.json"
const V3_CATALOG := preload("res://scripts/core/v3_catalog.gd")

static func load_manifest() -> Dictionary:
	var text := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

static func validation_errors() -> Array[String]:
	var failures: Array[String] = []
	var manifest := load_manifest()
	if int(manifest.get("version", 0)) != 1:
		failures.append("Runtime asset manifest is missing version 1.")
		return failures
	var groups: Dictionary = manifest.get("groups", {}) if manifest.get("groups", {}) is Dictionary else {}
	var m1: Dictionary = manifest.get("m1_physical_ui", {}) if manifest.get("m1_physical_ui", {}) is Dictionary else {}
	var cartridge: Dictionary = m1.get("blueprint_cartridge", {}) if m1.get("blueprint_cartridge", {}) is Dictionary else {}
	for field in ["runtime_path", "source_path", "dimensions", "bytes", "sha256", "alpha_expected", "approved_crop", "runtime_role", "provenance", "rejected_alternatives"]:
		if not cartridge.has(field): failures.append("M1 blueprint cartridge manifest is missing %s." % field)
	if not cartridge.is_empty():
		var runtime_path := str(cartridge.get("runtime_path", ""))
		var source_path := str(cartridge.get("source_path", ""))
		if not ResourceLoader.exists(runtime_path): failures.append("Missing promoted M1 blueprint cartridge: %s" % runtime_path)
		if not FileAccess.file_exists(source_path): failures.append("Missing approved M1 blueprint cartridge source: %s" % source_path)
		var dimensions: Array = cartridge.get("dimensions", []) if cartridge.get("dimensions", []) is Array else []
		var crop: Array = cartridge.get("approved_crop", []) if cartridge.get("approved_crop", []) is Array else []
		var provenance: Dictionary = cartridge.get("provenance", {}) if cartridge.get("provenance", {}) is Dictionary else {}
		var dimensions_match := dimensions.size() == 2 and int(dimensions[0]) == 724 and int(dimensions[1]) == 2172
		var crop_match := crop.size() == 4 and int(crop[0]) == 96 and int(crop[1]) == 0 and int(crop[2]) == 584 and int(crop[3]) == 2172
		if not dimensions_match or not crop_match or int(cartridge.get("bytes", 0)) != 2161030: failures.append("M1 blueprint cartridge dimensions, crop, or byte identity is invalid.")
		if str(cartridge.get("sha256", "")) != "66F50A5B85B45762C602556FF32A847D2BE72D03D59443845460C0DEA5AF4367": failures.append("M1 blueprint cartridge SHA-256 identity is invalid.")
		if str(provenance.get("prompt_status", "")) != "reconstructed-from-approved-brief": failures.append("M1 cartridge provenance must disclose reconstructed prompt status.")
	for key in ["battle_backgrounds", "printer_frames", "card_atlases", "card_fronts"]:
		var paths: Array = groups.get(key, []) if groups.get(key, []) is Array else []
		if paths.is_empty(): failures.append("Manifest group %s is empty." % key)
		for path in paths:
			var asset_path := str(path)
			if (key == "card_fronts" and not FileAccess.file_exists(asset_path)) or (key != "card_fronts" and not ResourceLoader.exists(asset_path)): failures.append("Missing runtime asset: %s" % asset_path)
	var armor: Dictionary = groups.get("tiered_armor", {}) if groups.get("tiered_armor", {}) is Dictionary else {}
	for creature_id in armor.get("required_creatures", []):
		var id := str(creature_id)
		var master := str(armor.get("directory", "")).path_join("%s_tiered_armor_signature_green_alpha_v1.png" % id)
		if id == "cinderpaw": master = str(armor.get("directory", "")).path_join("cinderpaw_tiered_armor_signature_green_alpha_v3.png")
		var mask := str(armor.get("mask_directory", "")).path_join("%s_armor_plate_mask_v1.png" % id)
		if not ResourceLoader.exists(master): failures.append("Missing tiered armor master: %s" % master)
		if not ResourceLoader.exists(mask): failures.append("Missing tiered armor mask: %s" % mask)
	for card in V3_CATALOG.cards():
		if str(card.get("type", "")) != "creature": continue
		var presentation: Dictionary = card.get("presentation", {})
		for key in ["sprite_sheet", "raw_print"]:
			var path := str(presentation.get(key, ""))
			if path.is_empty() or not ResourceLoader.exists(path): failures.append("Missing catalog creature %s: %s" % [key, path])
	for suit in Catalog.SUITS:
		var suit_raw := str((suit as Dictionary).get("raw_print", ""))
		if suit_raw.is_empty() or not ResourceLoader.exists(suit_raw): failures.append("Missing retained Workshop full-suit raw: %s" % suit_raw)
	for core in Catalog.CORE_BLUEPRINTS:
		var core_raw := str((core as Dictionary).get("raw_print", ""))
		if core_raw.is_empty() or not ResourceLoader.exists(core_raw): failures.append("Missing retained Workshop Core raw: %s" % core_raw)
	return failures
