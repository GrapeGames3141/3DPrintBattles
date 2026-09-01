extends Node
## Historical entry point: proves the superseded blueprint family is unreachable
## while M6 holds the full reviewed v2 promotion gate.

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
		require(str(definition.get("blueprint_art", "")).is_empty() and IMPRINT.blueprint_path_for(definition).is_empty(), "Superseded creature blueprint mapping is unreachable for %s." % id)
		require(IMPRINT.blueprint_texture(definition) == neutral and CARD_VIEW.art_for_definition(RULES.card(id)) == neutral, "Creature pre-print art resolves the common neutral approval-gate placeholder for %s." % id)
	require(ids.size() == 24, "All 24 stable creature definitions remain catalog-visible during the art gate.")
	var legacy := {"id":"cinderpaw","type":"creature","blueprint_art":"res://assets/creatures/2d/blueprints/cinderpaw_blueprint_card_v1.png"}
	require(IMPRINT.blueprint_path_for(legacy).is_empty() and IMPRINT.blueprint_texture(legacy) == neutral, "Injected legacy artwork is rejected instead of becoming a creature fallback.")
	var support := RULES.card("raw_filament")
	require(IMPRINT.blueprint_texture(support) == null and CARD_VIEW.art_for_definition(support) != null and not IMPRINT.is_neutral_placeholder(CARD_VIEW.art_for_definition(support)), "Support-card art bypasses the creature placeholder resolver.")
	var stage := BATTLE_STAGE.new(); stage.size = Vector2(576, 1024); add_child(stage); await get_tree().process_frame
	require(stage.find_child("BattlePrinterSolidRaw0", true, false) is TextureRect and stage.find_child("BattlePrinterSchematic0", true, false) is TextureRect and stage.find_child("LivingPrintSlot0", true, false) is TextureRect, "Raw, schematic, and living battlefield representations remain separate from the pre-print placeholder.")
	var concealed := stage.find_child("RivalConcealedCard0", true, false) as TextureRect
	require(concealed != null and concealed.texture != null and not IMPRINT.is_neutral_placeholder(concealed.texture), "Rival concealed hand retains its exact card-back presentation.")
	if failures.is_empty(): print("PASS: historical blueprint family remains unreachable behind M6 v2 gate")
	get_tree().quit(0 if failures.is_empty() else 1)
