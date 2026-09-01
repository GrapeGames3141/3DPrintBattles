extends Node
## Historical entry point: proves legacy family assets stay unreachable while the
## approved M7 v2 runtime manifest supplies the stable pre-print artwork.

const RULES := preload("res://scripts/core/unified_rules.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const BATTLE_STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var neutral := IMPRINT.neutral_placeholder_texture()
	var ids := {}
	for source in Catalog.CREATURES:
		var id := str((source as Dictionary).get("id", ""))
		ids[id] = true
		var definition := Catalog.creature(id)
		var resolved := IMPRINT.blueprint_texture(definition)
		require(str(definition.get("blueprint_art", "")).is_empty() and IMPRINT.blueprint_path_for(definition).ends_with("/%s_blueprint_ink_v2.png" % id), "M7 runtime manifest resolves the approved v2 path for %s." % id)
		require(resolved != null and resolved != neutral and CARD_VIEW.art_for_definition(RULES.card(id)) != neutral, "Creature pre-print art resolves approved M7 v2 artwork for %s." % id)
	require(ids.size() == 24 and IMPRINT.runtime_manifest_snapshot().size() == 24, "All 24 stable creature definitions resolve through the M7 runtime manifest.")
	var legacy := {"id":"cinderpaw","type":"creature","blueprint_art":"res://assets/creatures/2d/blueprints/cinderpaw_blueprint_card_v1.png"}
	require(IMPRINT.blueprint_path_for(legacy).is_empty() and IMPRINT.blueprint_texture(legacy) == neutral, "Injected legacy artwork is rejected instead of becoming a creature fallback.")
	var support := RULES.card("raw_filament")
	require(IMPRINT.blueprint_texture(support) == null and CARD_VIEW.art_for_definition(support) != null and not IMPRINT.is_neutral_placeholder(CARD_VIEW.art_for_definition(support)), "Support-card art bypasses the creature placeholder resolver.")
	var stage := BATTLE_STAGE.new(); stage.size = Vector2(576, 1024); add_child(stage); await get_tree().process_frame
	require(stage.find_child("BattlePrinterSolidRaw0", true, false) is TextureRect and stage.find_child("BattlePrinterSchematic0", true, false) is TextureRect and stage.find_child("LivingPrintSlot0", true, false) is TextureRect, "Raw, schematic, and living battlefield representations remain separate from the pre-print placeholder.")
	var concealed := stage.find_child("RivalConcealedCard0", true, false) as TextureRect
	require(concealed != null and concealed.texture != null and not IMPRINT.is_neutral_placeholder(concealed.texture), "Rival concealed hand retains its exact card-back presentation.")
	if failures.is_empty(): print("PASS: legacy blueprint family remains unreachable while approved M7 v2 art is active")
	get_tree().quit(0 if failures.is_empty() else 1)
