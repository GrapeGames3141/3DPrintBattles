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
	var title_v2: Dictionary = m1.get("title_backplate_v2", {}) if m1.get("title_backplate_v2", {}) is Dictionary else {}
	for field in ["runtime_path", "source_path", "dimensions", "bytes", "sha256", "alpha_expected", "runtime_role", "provenance"]:
		if not title_v2.has(field): failures.append("M1 title v2 manifest is missing %s." % field)
	if not title_v2.is_empty():
		var title_dimensions: Array = title_v2.get("dimensions", []) if title_v2.get("dimensions", []) is Array else []
		var title_provenance: Dictionary = title_v2.get("provenance", {}) if title_v2.get("provenance", {}) is Dictionary else {}
		if not FileAccess.file_exists(str(title_v2.get("runtime_path", ""))) or not FileAccess.file_exists(str(title_v2.get("source_path", ""))): failures.append("Missing promoted M1 title v2 backplate.")
		if title_dimensions.size() != 2 or int(title_dimensions[0]) != 941 or int(title_dimensions[1]) != 1672 or int(title_v2.get("bytes", 0)) != 2135203 or str(title_v2.get("sha256", "")) != "394BE19B67CBDF54125C1700BDEB5FB9CCB94C926E976D6CBA371BD88E7C0282": failures.append("M1 title v2 identity is invalid.")
		if str(title_provenance.get("generator", "")) != "OpenAI ImageGen" or str(title_provenance.get("generation_execution", "")) != "exec-fba7b5b6-69eb-48db-8a92-9baabf98e2b3": failures.append("M1 title v2 provenance is invalid.")
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
	var m11: Dictionary = manifest.get("m11_living_battle", {}) if manifest.get("m11_living_battle", {}) is Dictionary else {}
	var m11_identity := {
		"continuous_floor":[2059907,"0E5A00D26A2EF3D01425EF812B49BD9B3EB43CCCFAAF1FD8535C165E5D7B2259",false],
		"iron_gem_completed":[1663942,"A9505932FC06C0C0A50C32EC3ED6E84279FC2A86595988FDFD9F0FE8AE16915C",true],
		"iron_gem_raw":[2499720,"DE06034FE1B80AE866334840E730608B4F4419FD15F54BE7D5B82DA6075BCBE6",true],
		"iron_gem_blueprint":[1132632,"B977A9E15626161E9AAAE36B823EDD388565521BE73F8ACD07B99FAB1950140F",true]
	}
	for key in m11_identity:
		var entry: Dictionary = m11.get(str(key), {}) if m11.get(str(key), {}) is Dictionary else {}
		if entry.is_empty():
			failures.append("M11 manifest is missing %s." % str(key))
			continue
		for field in ["runtime_path", "source_path", "dimensions", "bytes", "sha256", "alpha_expected", "runtime_role", "provenance"]:
			if not entry.has(field): failures.append("M11 %s is missing %s." % [str(key), field])
		var expected: Array = m11_identity[key]
		var dimensions: Array = entry.get("dimensions", []) if entry.get("dimensions", []) is Array else []
		var expected_dimensions := Vector2i(941, 1672) if str(key) == "continuous_floor" else Vector2i(1254, 1254) if str(key) == "iron_gem_completed" else Vector2i(1600, 1600)
		if not FileAccess.file_exists(str(entry.get("runtime_path", ""))) or not FileAccess.file_exists(str(entry.get("source_path", ""))): failures.append("Missing promoted M11 asset: %s" % str(key))
		if dimensions.size() != 2 or int(dimensions[0]) != expected_dimensions.x or int(dimensions[1]) != expected_dimensions.y or int(entry.get("bytes", 0)) != int(expected[0]) or str(entry.get("sha256", "")) != str(expected[1]) or bool(entry.get("alpha_expected", false)) != bool(expected[2]): failures.append("M11 %s identity is invalid." % str(key))
	var m3: Dictionary = manifest.get("m3_physical_ui", {}) if manifest.get("m3_physical_ui", {}) is Dictionary else {}
	var m3_identity := {
		"archive_grid":[2534630,"CB86C63DAB77D6F6CF028426CC0A98F6B74B01ED926A98A35A4C1EBD301D2B16"],
		"archive_detail":[2492522,"F89CB8F9CAF84B292BE12E2422A66F0464A3CEC1EE2A0E7A9A7B12786D3E2CBC"],
		"deck_workbench":[2370308,"886F548F6CDF87FEA7BBCFC38FDAAF80A216430D7AF7345B50DD6FF6005B27CD"],
		"supply_cabinet":[2286953,"FCD4B0A045DEEF2C701C5EF07D5E376E47CB570A9F9CB9A96735EC5D4E15D8B2"],
		"pack_machine":[2294573,"88100CB06C41E3E9C7996757EC118A4BAE56CF35DD65E633EDCD3FB42F103C25"],
		"result_receipt":[2524092,"9E436AAF7780EE93EFD62F9B142793BD169E340E02D3F8B4D8789A8EEEDB9D4F"],
		"settings":[2335660,"AA10B51A1DF930BC8032EA4D2A4AF3766E1EF0FDDF55926D61C16AD25CACFE2B"],
		"recovery":[2293126,"9D3673D3D8328B40A7746E9EA5C746E9B25FC30BFEF6D366A0CEECC2ED724F0E"]
	}
	for key in m3_identity:
		var entry: Dictionary = m3.get(str(key), {}) if m3.get(str(key), {}) is Dictionary else {}
		if entry.is_empty(): failures.append("M3 manifest is missing %s." % str(key)); continue
		for field in ["runtime_path", "source_path", "dimensions", "bytes", "sha256", "alpha_expected", "runtime_role", "provenance"]:
			if not entry.has(field): failures.append("M3 %s is missing %s." % [str(key), field])
		# Masters are opaque source PNGs. File identity is the package contract;
		# ResourceLoader availability follows Godot's import cache and is checked
		# by the normal runtime presenter once the project has been imported.
		if not FileAccess.file_exists(str(entry.get("runtime_path", ""))): failures.append("Missing promoted M3 master: %s" % str(entry.get("runtime_path", "")))
		if not FileAccess.file_exists(str(entry.get("source_path", ""))): failures.append("Missing approved M3 master source: %s" % str(entry.get("source_path", "")))
		var dimensions: Array = entry.get("dimensions", []) if entry.get("dimensions", []) is Array else []
		var expected: Array = m3_identity[key]
		if dimensions.size() != 2 or int(dimensions[0]) != 941 or int(dimensions[1]) != 1672 or int(entry.get("bytes", 0)) != int(expected[0]) or str(entry.get("sha256", "")) != str(expected[1]): failures.append("M3 %s identity is invalid." % str(key))
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
