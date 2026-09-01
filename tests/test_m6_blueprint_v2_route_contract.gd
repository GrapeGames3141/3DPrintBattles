extends Node

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
	var profile_before := var_to_str(GameManager.profile)
	var placeholder := IMPRINT.neutral_placeholder_texture()
	var placeholder_image := placeholder.get_image()
	require(placeholder != null and placeholder_image != null and placeholder_image.get_pixel(0, 0).a == 0.0 and placeholder_image.get_pixel(95, 95).a == 0.0, "M6 placeholder is one cached text-free transparent diagnostic mark with no card matte.")
	for creature in Catalog.CREATURES:
		var id := str((creature as Dictionary).get("id", ""))
		var catalog_card := Catalog.creature(id)
		var unified_card := RULES.card(id)
		require(str(catalog_card.get("blueprint_art", "")).is_empty() and IMPRINT.blueprint_texture(catalog_card) == placeholder and IMPRINT.blueprint_texture(unified_card) == placeholder, "Catalog and unified pre-print route inputs use the same approval-gated placeholder for %s." % id)
	for rejected in [
		"res://assets/creatures/2d/blueprints/cinderpaw_blueprint_card_v1.png",
		"res://assets/creatures/2d/blueprints/cinderpaw_blueprint_card_v3.png",
		"res://assets/creatures/2d/blueprints/unknown_blueprint_card_v1.png",
		"res://assets/creatures/2d/raw/cinderpaw_raw_print.png",
		"res://assets/creatures/2d/cinderpaw_sprite_sheet.png"
	]:
		var injected := {"id":"cinderpaw","type":"creature","blueprint_art":rejected}
		require(IMPRINT.blueprint_path_for(injected).is_empty() and IMPRINT.blueprint_texture(injected) == placeholder, "Rejected pre-print path is identity-neutral: %s" % rejected)
	var future_v2 := {"id":"future_creature","type":"creature","blueprint_art":"res://assets/creatures/2d/blueprints/v2/future_creature_blueprint_ink_v2.png"}
	require(IMPRINT.blueprint_path_for(future_v2).is_empty() and IMPRINT.blueprint_texture(future_v2) == placeholder, "Missing future v2 art remains a neutral placeholder rather than a substitute creature.")
	var creature_view := CARD_VIEW.new(); creature_view.configure(RULES.card("cinderpaw"), 1); add_child(creature_view); await get_tree().process_frame
	var creature_art := creature_view.find_child("UnifiedCardArt", true, false) as TextureRect
	require(creature_art != null and creature_art.texture == placeholder and creature_view.accessibility_name.contains("blueprint illustration unavailable"), "UnifiedCardView uses central placeholder art and native unavailable accessibility copy.")
	var support := RULES.card("raw_filament")
	var support_view := CARD_VIEW.new(); support_view.configure(support, 1); add_child(support_view); await get_tree().process_frame
	var support_art := support_view.find_child("UnifiedCardArt", true, false) as TextureRect
	require(support_art != null and support_art.texture != null and support_art.texture != placeholder, "Support art remains unchanged and bypasses the creature placeholder resolver.")
	var stage := BATTLE_STAGE.new(); stage.size = Vector2(576, 1024); add_child(stage); await get_tree().process_frame
	var concealed := stage.find_child("RivalConcealedCard0", true, false) as TextureRect
	require(stage.find_child("BattlePrinterSolidRaw0", true, false) is TextureRect and stage.find_child("BattlePrinterSchematic0", true, false) is TextureRect and stage.find_child("LivingPrintSlot0", true, false) is TextureRect and concealed != null and concealed.texture != null and not IMPRINT.is_neutral_placeholder(concealed.texture), "Raw/wireframe/living/concealed battle representations remain distinct from the pre-print resolver.")
	for path in ["scripts/ui/main.gd", "scripts/ui/blueprint_tray_view.gd", "scripts/ui/physical_archive_workbench_component.gd", "scripts/ui/unified_battle_screen_component.gd", "scripts/ui/physical_supply_reward_component.gd"]:
		var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://" + path))
		require(source.contains("blueprint_texture") or source.contains("add_catalog_art"), "Known pre-print presentation seam routes through PhysicalCatalogImprint: %s." % path)
	require(var_to_str(GameManager.profile) == profile_before, "Blueprint resolution/inspection is presentation-only and does not mutate profile state.")
	if failures.is_empty(): print("PASS: M6 blueprint v2 route contract and rejection guardrail")
	get_tree().quit(0 if failures.is_empty() else 1)
