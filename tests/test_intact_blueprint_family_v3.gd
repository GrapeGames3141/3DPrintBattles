extends Node
## Deterministic presentation-only gate for the approved 24-card v3 family.

const RULES := preload("res://scripts/core/unified_rules.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const BATTLE_STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
const ROOT := "res://assets/creatures/2d/blueprints/"

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var ids: Array[String] = []
	var seen := {}
	for source in Catalog.CREATURES:
		var id := str((source as Dictionary).get("id", ""))
		ids.append(id)
		seen[id] = true
		var definition := Catalog.creature(id)
		var path := str(definition.get("blueprint_art", ""))
		require(not path.is_empty() and path == "%s%s_blueprint_card_v1.png" % [ROOT, id], "Catalog blueprint mapping must be stable for %s." % id)
		require(FileAccess.file_exists(path), "Runtime blueprint asset is missing for %s." % id)
		var texture := IMPRINT.blueprint_texture(definition)
		require(texture != null, "Catalog blueprint must load for %s." % id)
		if texture != null:
			require(texture.get_size() == Vector2(512, 512), "Runtime blueprint must be 512x512 for %s." % id)
		var unified := RULES.card(id)
		require(IMPRINT.blueprint_path_for(unified) == path, "UnifiedRules creature must resolve approved presentation path for %s." % id)
		var unified_texture := IMPRINT.blueprint_texture(unified)
		require(unified_texture != null and unified_texture.get_size() == Vector2(512, 512), "UnifiedRules creature must not fall back for %s." % id)
	require(ids.size() == 24 and seen.size() == 24, "Blueprint family must cover exactly 24 stable creature IDs.")
	var future := {"id":"future_creature","type":"creature","raw_print":"res://assets/creatures/2d/raw/cinderpaw_raw_print.png"}
	require(IMPRINT.blueprint_path_for(future).is_empty(), "Unknown creature must not substitute a known blueprint path.")
	var fallback := IMPRINT.blueprint_texture(future)
	require(fallback != null and fallback.get_size() == Vector2(512, 512), "Unknown creature needs generic intact-card fallback.")
	var support := RULES.card("raw_filament")
	require(IMPRINT.blueprint_path_for(support).is_empty() and IMPRINT.blueprint_texture(support) == null, "Support card must bypass creature blueprint resolver.")
	require(CARD_VIEW.art_for_definition(support) != null, "Support card retains its existing art fallback.")
	var archive_source := _source("res://scripts/ui/physical_archive_workbench_component.gd")
	var tray_source := _source("res://scripts/ui/blueprint_tray_view.gd")
	var battle_source := _source("res://scripts/ui/unified_battle_screen_component.gd")
	require(archive_source.contains("add_blueprint_card") and archive_source.contains("add_catalog_art"), "Archive/Deck creature seats must use complete blueprint cards.")
	require(tray_source.contains("PhysicalCatalogImprint.blueprint_texture") and not tray_source.contains('"raw_print"'), "Forge cartridge must be blueprint-only before extrusion.")
	var stage := BATTLE_STAGE.new(); stage.size = Vector2(576, 1024); add_child(stage); await get_tree().process_frame
	require(stage.find_child("BattlePrinterSolidRaw0", true, false) is TextureRect and stage.find_child("BattlePrinterSchematic0", true, false) is TextureRect and stage.find_child("LivingPrintSlot0", true, false) is TextureRect, "Battlefield retains separate raw/wireframe printer and living-sprite stage nodes.")
	var concealed := stage.find_child("RivalConcealedCard0", true, false) as TextureRect
	require(is_instance_valid(concealed) and concealed.texture != null, "Concealed rival hand retains the exact passive card-back representation.")
	stage.queue_free()
	require(battle_source.contains("UnifiedSelectedCreatureBlueprintCard"), "Selected player battle creature must use a blueprint card before queueing.")
	var provenance := JSON.parse_string(FileAccess.get_file_as_string(ROOT + "provenance-v1.json")) as Dictionary
	require(int(provenance.get("source_total_bytes", 0)) > int(provenance.get("runtime_total_bytes", 0)), "Runtime derivatives must materially reduce source bytes.")
	require((provenance.get("cards", []) as Array).size() == 24, "Runtime provenance must list all promoted cards.")
	if failures.is_empty(): print("PASS: intact blueprint family v3")
	get_tree().quit(0 if failures.is_empty() else 1)

func _source(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
