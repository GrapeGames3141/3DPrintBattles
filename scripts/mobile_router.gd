extends Node


func _ready() -> void:
	var combat_scene := "res://combat_main.tscn"
	var inspector_scene := "res://main.tscn"
	var has_combat := ResourceLoader.exists(combat_scene)
	var has_inspector := ResourceLoader.exists(inspector_scene)
	var target := ""
	if has_combat and not has_inspector:
		target = combat_scene
	elif has_inspector and not has_combat:
		target = inspector_scene
	elif OS.has_feature("combat_android") and has_combat:
		target = combat_scene
	elif has_inspector:
		target = inspector_scene
	elif has_combat:
		target = combat_scene
	if target == "":
		push_error("Mobile router found no packaged application scene.")
		return
	print("MOBILE_ROUTER_TARGET=%s" % target)
	get_tree().change_scene_to_file(target)
