extends Node

const OPTIONAL_PATHS := [
	"res://scripts/core/opponent_rules.gd",
	"res://scripts/ui/battle_screen_component.gd",
	"res://scripts/ui/arcane_forge_screen_component.gd",
	"res://scripts/ui/equipment_workbench_view.gd",
	"res://scripts/ui/tiered_armor_palette_preview.gd",
	"res://scripts/ui/battle_sprite_stage.gd"
]
const RULES := preload("res://scripts/core/unified_rules.gd")
const WORKSHOP_HOTSPOTS := [
	"WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive",
	"WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"
]

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	# The current launch boundary reaches physical Title first.  Keep a completed
	# profile so the real primary action is truthful CONTINUE, not New Maker.
	for path in OPTIONAL_PATHS:
		require(not ResourceLoader.has_cached(path), "optional startup resource is not cached before Main: " + path)
	var shell_source := FileAccess.get_file_as_string("res://scripts/ui/main.gd")
	require(not shell_source.contains("preload(\"res://scripts/ui/battle_screen_component.gd\")") and not shell_source.contains("preload(\"res://scripts/ui/arcane_forge_screen_component.gd\")") and not shell_source.contains("preload(\"res://scripts/ui/equipment_workbench_view.gd\")") and not shell_source.contains("BattleSpriteStage.new()"), "Main has no eager Battle, Forge, Equipment Workbench, or Local Battle stage dependency")
	var packed = ResourceLoader.load("res://scenes/main.tscn")
	require(packed != null, "Main scene is available after the pre-load cache gate")
	if packed == null:
		call_deferred("finish")
		return
	var completed: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	completed = RULES.print_starter(completed).profile
	GameManager.profile = completed
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	var main = packed.instantiate()
	add_child(main)
	await get_tree().process_frame
	var title_continue := main.find_child("TitleContinue", true, false) as Button
	require(main.screen == "title" and title_continue != null and title_continue.text == "CONTINUE", "real Main first renders physical Title with truthful Continue for a completed profile")
	require(main._unified_battle_screen_component == null and main._forge_screen_component == null, "physical Title does not instantiate Battle or Forge screen components")
	for path in OPTIONAL_PATHS:
		require(not ResourceLoader.has_cached(path), "optional startup resource is not cached by the physical Title frame: " + path)
	if title_continue != null:
		title_continue.emit_signal("pressed")
		await get_tree().process_frame
	var workshop_buttons: Array = []
	for node_name in WORKSHOP_HOTSPOTS:
		var hotspot := main.find_child(node_name, true, false) as Button
		require(hotspot != null, "%s is a real physical Workshop hotspot after Continue." % node_name)
		if hotspot != null: workshop_buttons.append(hotspot)
	var all_hotspots: Array = main.find_children("WorkshopHotspot*", "Button", true, false)
	require(main.screen == "workshop" and workshop_buttons.size() == 6 and all_hotspots.size() == 6, "real Continue callback opens the redesigned Workshop hub with exactly six canonical physical Button hotspots")
	require(main._unified_battle_screen_component == null and main._forge_screen_component == null, "Workshop hub still does not instantiate Battle or Forge screen components")
	for path in OPTIONAL_PATHS:
		require(not ResourceLoader.has_cached(path), "optional startup resource is not cached by Title→Workshop navigation: " + path)
	# Opening the Proving Door is the intended lazy boundary for daily opponents.
	main.navigate_to("proving")
	await get_tree().process_frame
	require(ResourceLoader.has_cached("res://scripts/core/opponent_rules.gd"), "Proving Door lazily loads the daily-opponent module")
	main.navigate_to("armor")
	await get_tree().process_frame
	# The public Armor route now resolves to the unified Library rather than the
	# retired Equipment Workbench; it must therefore remain absent from this cache.
	require(not ResourceLoader.has_cached("res://scripts/ui/equipment_workbench_view.gd"), "Unified Armor Library does not load the retired Equipment Workbench")
	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: workshop first frame isolates optional Android-risk modules until their screens are requested")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
