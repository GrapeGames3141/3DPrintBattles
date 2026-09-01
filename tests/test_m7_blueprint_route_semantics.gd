extends Node

const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message); push_error(message)
func _ready() -> void:
	var before := var_to_str(GameManager.profile)
	for path in ["scripts/ui/main.gd", "scripts/ui/blueprint_tray_view.gd", "scripts/ui/physical_archive_workbench_component.gd", "scripts/ui/unified_battle_screen_component.gd", "scripts/ui/physical_supply_reward_component.gd"]:
		var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://" + path))
		require(source.contains("blueprint_texture") or source.contains("add_catalog_art"), "Pre-print route seam uses central resolver: %s." % path)
	var stage := STAGE.new(); stage.size = Vector2(576, 1024); add_child(stage); await get_tree().process_frame
	var concealed := stage.find_child("RivalConcealedCard0", true, false) as TextureRect
	require(stage.find_child("BattlePrinterSolidRaw0", true, false) is TextureRect and stage.find_child("BattlePrinterSchematic0", true, false) is TextureRect and stage.find_child("LivingPrintSlot0", true, false) is TextureRect and concealed != null and concealed.texture != null and not IMPRINT.is_neutral_placeholder(concealed.texture), "Raw/wireframe/living sprites and rival card back stay distinct from M7 blueprint cards.")
	require(var_to_str(GameManager.profile) == before, "Route seam inspection is zero-mutation.")
	if failures.is_empty(): print("PASS: M7 pre-print seams preserve raw/wireframe/living/card-back semantics")
	get_tree().quit(0 if failures.is_empty() else 1)
