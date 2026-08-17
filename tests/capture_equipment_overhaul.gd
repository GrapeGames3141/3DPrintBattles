extends Node
## Deterministic UI capture fixture for the Equipment Workbench at both review sizes.

func _ready() -> void:
	var p := ProfileRules.new_profile(); p["coins"] = 9999
	for tier_id in ArmorCoreDefinitions.ARMOR_TIERS:
		p = EquipmentRules.learn_suit(p, tier_id).get("profile", p)
		p = EquipmentRules.print_suit(p, tier_id).get("profile", p)
	for core_id in ArmorCoreDefinitions.core_ids():
		p = EquipmentRules.learn_core(p, core_id).get("profile", p)
		p = EquipmentRules.print_core(p, core_id).get("profile", p)
	p = ProfileRules.choose_starter(p, "cinderpaw").get("profile", p)
	var cinder_id := str(p.get("onboarding", {}).get("starter_instance_id", ""))
	p = ProgressionRules.purchase_creature_blueprint(p, "aquafin").get("profile", p)
	p = ProgressionRules.print_creature(p, "aquafin").get("profile", p)
	var aquafin_id := str(p.get("creatures", [])[-1].get("instance_id", ""))
	var suit_id := str(p.get("suits", [])[4].get("suit_instance_id", ""))
	var core_id := str(p.get("cores", [])[4].get("core_instance_id", ""))
	p = EquipmentRules.equip_suit(p, cinder_id, suit_id).get("profile", p)
	p = EquipmentRules.socket_core(p, suit_id, core_id).get("profile", p)
	var aquafin_suit_id := str(p.get("suits", [])[3].get("suit_instance_id", ""))
	p = EquipmentRules.equip_suit(p, aquafin_id, aquafin_suit_id).get("profile", p)
	GameManager.profile = p
	for dimensions in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		await _capture(p, dimensions, "suits", "standard", "equipment_workbench")
		await _capture(p, dimensions, "cores", "arcane", "equipment_workbench_cores_socketed")
		await _capture(p, dimensions, "suits", "legendary", "equipment_workbench_aquafin", aquafin_id)
		var no_core: Dictionary = EquipmentRules.remove_core(p, suit_id).get("profile", p)
		await _capture(no_core, dimensions, "cores", "", "equipment_workbench_cores_empty")
	print("CAPTURED Workbench Cinderpaw and Aquafin suit previews, socketed Core, and no-Core states")
	get_tree().quit()

func _capture(profile: Dictionary, dimensions: Vector2i, mode: String, selection: String, tag: String, selected_creature_id := "") -> void:
	GameManager.profile = profile.duplicate(true)
	get_window().size = dimensions
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main); main.set("screen", "armor"); main.set("equipment_mode", mode); main.set("equipment_selected_id", selection); main.set("equipment_selected_creature_id", selected_creature_id); main.call("render")
	await get_tree().process_frame; await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Viewport capture requires a non-dummy renderer."); get_tree().quit(1); return
	image.save_png("user://%s_%dx%d.png" % [tag, dimensions.x, dimensions.y])
	main.queue_free(); await get_tree().process_frame
