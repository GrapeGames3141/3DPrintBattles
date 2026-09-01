extends Node

const RULES := preload("res://scripts/core/unified_rules.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message); push_error(message)
func _ready() -> void:
	var before := var_to_str(GameManager.profile)
	var manifest := IMPRINT.runtime_manifest_snapshot()
	require(manifest.size() == 24, "Central M7 runtime resolver accepts exactly 24 approved entries.")
	require(IMPRINT.runtime_texture_cache_count() == 0, "Manifest structure validates without eagerly loading or decoding creature textures.")
	var approved_paths := {}
	for source in Catalog.CREATURES:
		var id := str((source as Dictionary).get("id", ""))
		var catalog_card := Catalog.creature(id)
		var unified_card := RULES.card(id)
		var texture := IMPRINT.blueprint_texture(catalog_card)
		var expected_path := "res://assets/creatures/2d/blueprints/v2/%s_blueprint_ink_v2.png" % id
		approved_paths[expected_path] = true
		require(IMPRINT.blueprint_path_for(catalog_card) == expected_path and texture != null and not IMPRINT.is_neutral_placeholder(texture) and not IMPRINT.is_neutral_placeholder(CARD_VIEW.art_for_definition(unified_card)), "Catalog and V3 card resolve unique approved M7 texture for %s." % id)
	require(approved_paths.size() == 24 and IMPRINT.runtime_texture_cache_count() == 24, "Each requested creature resolves one distinct approved M7 path and only requested entries are cached.")
	var resolver_source := FileAccess.get_file_as_string("res://scripts/ui/physical_catalog_imprint.gd")
	require(resolver_source.contains("ResourceLoader.exists(expected) or FileAccess.file_exists(expected)") and resolver_source.find("ResourceLoader.exists(path)") < resolver_source.find("FileAccess.file_exists(path)"), "Resolver is export-safe and ResourceLoader-first, with raw FileAccess only as headless/pre-import fallback.")
	var rejected := {"id":"cinderpaw", "type":"creature", "blueprint_art":"res://assets/creatures/2d/blueprints/cinderpaw_blueprint_card_v1.png"}
	require(IMPRINT.blueprint_path_for(rejected).is_empty() and IMPRINT.is_neutral_placeholder(IMPRINT.blueprint_texture(rejected)), "Legacy explicit blueprint injection is rejected to neutral placeholder.")
	var support := RULES.card("raw_filament")
	require(IMPRINT.blueprint_texture(support) == null and CARD_VIEW.art_for_definition(support) != null and not IMPRINT.is_neutral_placeholder(CARD_VIEW.art_for_definition(support)), "Support-card artwork remains outside creature resolver.")
	require(var_to_str(GameManager.profile) == before, "M7 texture resolution is presentation-only and zero-mutation.")
	if failures.is_empty(): print("PASS: M7 runtime manifest mapping resolves approved creature art centrally")
	get_tree().quit(0 if failures.is_empty() else 1)
